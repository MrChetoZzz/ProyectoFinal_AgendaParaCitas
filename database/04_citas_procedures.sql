-- ============================================================================
-- PROCEDIMIENTOS Y FUNCIONES CRUD: ENTIDAD CITAS (CON VALIDACIONES DE AGENDA)
-- Motor: PostgreSQL 14+ (Supabase / pgAdmin 4)
-- ============================================================================

-- 1. AGENDAR NUEVA CITA (Valida jornada laboral, bloqueos y cero empalmes)
CREATE OR REPLACE PROCEDURE usp_citas_create(
    p_psicologa_id    INT,
    p_paciente_id     INT,
    p_fecha_cita      DATE,
    p_hora_inicio     TIME,
    p_hora_fin        TIME DEFAULT NULL,
    p_estado          VARCHAR DEFAULT 'Pendiente',
    p_motivo_consulta VARCHAR DEFAULT NULL,
    p_notas_psicologa TEXT DEFAULT NULL,
    INOUT p_id        INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_duracion_min INT;
    v_dia_semana   SMALLINT;
    v_inicio_ts    TIMESTAMP;
    v_fin_ts       TIMESTAMP;
BEGIN
    p_estado          := COALESCE(NULLIF(TRIM(p_estado), ''), 'Pendiente');
    p_motivo_consulta := NULLIF(TRIM(p_motivo_consulta), '');
    p_notas_psicologa := NULLIF(TRIM(p_notas_psicologa), '');

    IF p_psicologa_id IS NULL OR p_paciente_id IS NULL
       OR p_fecha_cita IS NULL OR p_hora_inicio IS NULL THEN
        RAISE EXCEPTION 'La psicóloga, el paciente, la fecha y la hora de inicio son obligatorios.'
            USING ERRCODE = 'P0020';
    END IF;

    IF p_estado NOT IN ('Pendiente', 'Confirmada', 'Completada', 'Cancelada') THEN
        RAISE EXCEPTION 'El estado de la cita no es válido.'
            USING ERRCODE = 'P0021';
    END IF;

    -- Verificar psicóloga y obtener duración estándar de sesión
    SELECT duracion_sesion_min INTO v_duracion_min
    FROM psicologas
    WHERE id = p_psicologa_id;

    IF v_duracion_min IS NULL THEN
        RAISE EXCEPTION 'La psicóloga especificada no existe.'
            USING ERRCODE = 'P0022';
    END IF;

    -- Calcular hora_fin automáticamente si no se envió desde el backend
    IF p_hora_fin IS NULL THEN
        p_hora_fin := p_hora_inicio + (v_duracion_min || ' minutes')::INTERVAL;
    END IF;

    IF p_hora_fin <= p_hora_inicio THEN
        RAISE EXCEPTION 'La hora de finalización debe ser mayor a la hora de inicio.'
            USING ERRCODE = 'P0023';
    END IF;

    -- Verificar paciente
    IF NOT EXISTS (SELECT 1 FROM pacientes WHERE id = p_paciente_id) THEN
        RAISE EXCEPTION 'El paciente especificado no existe.'
            USING ERRCODE = 'P0024';
    END IF;

    -- Validar que la cita esté dentro de algún bloque activo de horarios_base
    v_dia_semana := EXTRACT(DOW FROM p_fecha_cita)::SMALLINT;

    IF NOT EXISTS (
        SELECT 1 FROM horarios_base
        WHERE psicologa_id = p_psicologa_id
          AND dia_semana = v_dia_semana
          AND activo = TRUE
          AND p_hora_inicio >= hora_inicio
          AND p_hora_fin <= hora_fin
    ) THEN
        RAISE EXCEPTION 'El horario seleccionado está fuera de la jornada laboral de la psicóloga.'
            USING ERRCODE = 'P0025';
    END IF;

    -- Validar que no exista un bloqueo de agenda (vacaciones/ausencia)
    v_inicio_ts := p_fecha_cita + p_hora_inicio;
    v_fin_ts    := p_fecha_cita + p_hora_fin;

    IF EXISTS (
        SELECT 1 FROM bloqueos_agenda
        WHERE psicologa_id = p_psicologa_id
          AND v_inicio_ts < fecha_fin
          AND v_fin_ts > fecha_inicio
    ) THEN
        RAISE EXCEPTION 'La psicóloga no atiende en ese horario debido a un bloqueo en su agenda.'
            USING ERRCODE = 'P0026';
    END IF;

    -- Validar que no se empalme con otra cita activa (no cancelada)
    IF p_estado <> 'Cancelada' AND EXISTS (
        SELECT 1 FROM citas
        WHERE psicologa_id = p_psicologa_id
          AND fecha_cita = p_fecha_cita
          AND estado <> 'Cancelada'
          AND p_hora_inicio < hora_fin
          AND p_hora_fin > hora_inicio
    ) THEN
        RAISE EXCEPTION 'El horario seleccionado ya se encuentra ocupado por otra cita.'
            USING ERRCODE = 'P0027';
    END IF;

    INSERT INTO citas (
        psicologa_id,
        paciente_id,
        fecha_cita,
        hora_inicio,
        hora_fin,
        estado,
        motivo_consulta,
        notas_psicologa
    )
    VALUES (
        p_psicologa_id,
        p_paciente_id,
        p_fecha_cita,
        p_hora_inicio,
        p_hora_fin,
        p_estado,
        p_motivo_consulta,
        p_notas_psicologa
    )
    RETURNING id INTO p_id;
END;
$$;

-- 2. CONSULTAR CITA POR ID (Con JOIN a pacientes y psicologas)
CREATE OR REPLACE FUNCTION usp_citas_get_by_id(
    p_id INT
)
RETURNS TABLE (
    id                     INT,
    psicologa_id           INT,
    psicologa_nombre       VARCHAR,
    psicologa_especialidad VARCHAR,
    paciente_id            INT,
    paciente_nombre        VARCHAR,
    paciente_telefono      VARCHAR,
    paciente_email         VARCHAR,
    fecha_cita             DATE,
    hora_inicio            TIME,
    hora_fin               TIME,
    estado                 VARCHAR,
    motivo_consulta        VARCHAR,
    notas_psicologa        TEXT,
    creado_en              TIMESTAMP,
    actualizado_en         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.psicologa_id,
        ps.nombre_completo AS psicologa_nombre,
        ps.especialidad    AS psicologa_especialidad,
        c.paciente_id,
        p.nombre_completo  AS paciente_nombre,
        p.telefono         AS paciente_telefono,
        p.email            AS paciente_email,
        c.fecha_cita,
        c.hora_inicio,
        c.hora_fin,
        c.estado,
        c.motivo_consulta,
        c.notas_psicologa,
        c.creado_en,
        c.actualizado_en
    FROM citas AS c
    INNER JOIN psicologas AS ps ON ps.id = c.psicologa_id
    INNER JOIN pacientes AS p   ON p.id = c.paciente_id
    WHERE c.id = p_id;
END;
$$;

-- 3. CONSULTAR TODAS LAS CITAS (Filtros opcionales para dashboard y calendario)
CREATE OR REPLACE FUNCTION usp_citas_get_all(
    p_psicologa_id INT     DEFAULT NULL,
    p_fecha_cita   DATE    DEFAULT NULL,
    p_estado       VARCHAR DEFAULT NULL,
    p_paciente_id  INT     DEFAULT NULL
)
RETURNS TABLE (
    id                     INT,
    psicologa_id           INT,
    psicologa_nombre       VARCHAR,
    paciente_id            INT,
    paciente_nombre        VARCHAR,
    paciente_telefono      VARCHAR,
    paciente_email         VARCHAR,
    fecha_cita             DATE,
    hora_inicio            TIME,
    hora_fin               TIME,
    estado                 VARCHAR,
    motivo_consulta        VARCHAR,
    notas_psicologa        TEXT,
    creado_en              TIMESTAMP,
    actualizado_en         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_estado := NULLIF(TRIM(p_estado), '');

    RETURN QUERY
    SELECT
        c.id,
        c.psicologa_id,
        ps.nombre_completo AS psicologa_nombre,
        c.paciente_id,
        p.nombre_completo  AS paciente_nombre,
        p.telefono         AS paciente_telefono,
        p.email            AS paciente_email,
        c.fecha_cita,
        c.hora_inicio,
        c.hora_fin,
        c.estado,
        c.motivo_consulta,
        c.notas_psicologa,
        c.creado_en,
        c.actualizado_en
    FROM citas AS c
    INNER JOIN psicologas AS ps ON ps.id = c.psicologa_id
    INNER JOIN pacientes AS p   ON p.id = c.paciente_id
    WHERE (p_psicologa_id IS NULL OR c.psicologa_id = p_psicologa_id)
      AND (p_fecha_cita   IS NULL OR c.fecha_cita   = p_fecha_cita)
      AND (p_estado       IS NULL OR c.estado       = p_estado)
      AND (p_paciente_id  IS NULL OR c.paciente_id  = p_paciente_id)
    ORDER BY c.fecha_cita DESC, c.hora_inicio ASC;
END;
$$;

-- 4. ACTUALIZAR CITA COMPLETA (Reagendar fecha/hora, cambiar estado o notas)
CREATE OR REPLACE PROCEDURE usp_citas_update(
    p_id              INT,
    p_psicologa_id    INT,
    p_paciente_id     INT,
    p_fecha_cita      DATE,
    p_hora_inicio     TIME,
    p_hora_fin        TIME,
    p_estado          VARCHAR,
    p_motivo_consulta VARCHAR DEFAULT NULL,
    p_notas_psicologa TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_dia_semana SMALLINT;
    v_inicio_ts  TIMESTAMP;
    v_fin_ts     TIMESTAMP;
BEGIN
    p_estado          := NULLIF(TRIM(p_estado), '');
    p_motivo_consulta := NULLIF(TRIM(p_motivo_consulta), '');
    p_notas_psicologa := NULLIF(TRIM(p_notas_psicologa), '');

    IF NOT EXISTS (SELECT 1 FROM citas WHERE id = p_id) THEN
        RAISE EXCEPTION 'La cita especificada no existe.'
            USING ERRCODE = 'P0030';
    END IF;

    IF p_psicologa_id IS NULL OR p_paciente_id IS NULL
       OR p_fecha_cita IS NULL OR p_hora_inicio IS NULL
       OR p_hora_fin IS NULL OR p_estado IS NULL THEN
        RAISE EXCEPTION 'Todos los campos principales de la cita son obligatorios.'
            USING ERRCODE = 'P0020';
    END IF;

    IF p_estado NOT IN ('Pendiente', 'Confirmada', 'Completada', 'Cancelada') THEN
        RAISE EXCEPTION 'El estado de la cita no es válido.'
            USING ERRCODE = 'P0021';
    END IF;

    IF p_hora_fin <= p_hora_inicio THEN
        RAISE EXCEPTION 'La hora de finalización debe ser mayor a la hora de inicio.'
            USING ERRCODE = 'P0023';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM psicologas WHERE id = p_psicologa_id) THEN
        RAISE EXCEPTION 'La psicóloga especificada no existe.'
            USING ERRCODE = 'P0022';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pacientes WHERE id = p_paciente_id) THEN
        RAISE EXCEPTION 'El paciente especificado no existe.'
            USING ERRCODE = 'P0024';
    END IF;

    -- Validar jornada laboral y bloqueos si la cita no está cancelada
    IF p_estado <> 'Cancelada' THEN
        v_dia_semana := EXTRACT(DOW FROM p_fecha_cita)::SMALLINT;

        IF NOT EXISTS (
            SELECT 1 FROM horarios_base
            WHERE psicologa_id = p_psicologa_id
              AND dia_semana = v_dia_semana
              AND activo = TRUE
              AND p_hora_inicio >= hora_inicio
              AND p_hora_fin <= hora_fin
        ) THEN
            RAISE EXCEPTION 'El horario seleccionado está fuera de la jornada laboral.'
                USING ERRCODE = 'P0025';
        END IF;

        v_inicio_ts := p_fecha_cita + p_hora_inicio;
        v_fin_ts    := p_fecha_cita + p_hora_fin;

        IF EXISTS (
            SELECT 1 FROM bloqueos_agenda
            WHERE psicologa_id = p_psicologa_id
              AND v_inicio_ts < fecha_fin
              AND v_fin_ts > fecha_inicio
        ) THEN
            RAISE EXCEPTION 'El horario choca con un bloqueo en la agenda.'
                USING ERRCODE = 'P0026';
        END IF;

        IF EXISTS (
            SELECT 1 FROM citas
            WHERE psicologa_id = p_psicologa_id
              AND fecha_cita = p_fecha_cita
              AND estado <> 'Cancelada'
              AND id <> p_id
              AND p_hora_inicio < hora_fin
              AND p_hora_fin > hora_inicio
        ) THEN
            RAISE EXCEPTION 'El horario seleccionado ya está ocupado por otra cita.'
                USING ERRCODE = 'P0027';
        END IF;
    END IF;

    UPDATE citas
    SET
        psicologa_id    = p_psicologa_id,
        paciente_id     = p_paciente_id,
        fecha_cita      = p_fecha_cita,
        hora_inicio     = p_hora_inicio,
        hora_fin        = p_hora_fin,
        estado          = p_estado,
        motivo_consulta = p_motivo_consulta,
        notas_psicologa = p_notas_psicologa
    WHERE id = p_id;
END;
$$;

-- 5. ACTUALIZAR SOLO EL ESTADO Y NOTAS DE LA CITA (Para el Dashboard de la Psicóloga)
CREATE OR REPLACE PROCEDURE usp_citas_update_estado(
    p_id              INT,
    p_estado          VARCHAR,
    p_notas_psicologa TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_estado := NULLIF(TRIM(p_estado), '');

    IF p_estado NOT IN ('Pendiente', 'Confirmada', 'Completada', 'Cancelada') THEN
        RAISE EXCEPTION 'El estado de la cita no es válido.'
            USING ERRCODE = 'P0021';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM citas WHERE id = p_id) THEN
        RAISE EXCEPTION 'La cita especificada no existe.'
            USING ERRCODE = 'P0030';
    END IF;

    UPDATE citas
    SET
        estado          = p_estado,
        notas_psicologa = COALESCE(NULLIF(TRIM(p_notas_psicologa), ''), notas_psicologa)
    WHERE id = p_id;
END;
$$;

-- 6. ELIMINAR CITA (Con bloqueo de fila)
CREATE OR REPLACE PROCEDURE usp_citas_delete(
    p_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1 FROM citas WHERE id = p_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La cita especificada no existe.'
            USING ERRCODE = 'P0030';
    END IF;

    DELETE FROM citas WHERE id = p_id;
END;
$$;