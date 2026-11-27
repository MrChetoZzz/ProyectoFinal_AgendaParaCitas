-- ============================================================================
-- PROCEDIMIENTOS Y FUNCIONES CRUD: PSICÓLOGAS, HORARIOS BASE Y BLOQUEOS
-- Motor: PostgreSQL 14+ (Supabase / pgAdmin 4)
-- ============================================================================

-- 1. CONSULTAR PERFIL PÚBLICO DE LA PSICÓLOGA (Omite password_hash por seguridad)
CREATE OR REPLACE FUNCTION usp_psicologas_get_by_id(
    p_id INT
)
RETURNS TABLE (
    id                    INT,
    nombre_completo       VARCHAR,
    especialidad          VARCHAR,
    cedula_profesional    VARCHAR,
    biografia             TEXT,
    telefono_contacto     VARCHAR,
    direccion_consultorio VARCHAR,
    foto_url              VARCHAR,
    duracion_sesion_min   INT,
    email_login           VARCHAR,
    creado_en             TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ps.id,
        ps.nombre_completo,
        ps.especialidad,
        ps.cedula_profesional,
        ps.biografia,
        ps.telefono_contacto,
        ps.direccion_consultorio,
        ps.foto_url,
        ps.duracion_sesion_min,
        ps.email_login,
        ps.creado_en
    FROM psicologas AS ps
    WHERE ps.id = p_id;
END;
$$;

-- 2. CONSULTAR CREDENCIALES PARA LOGIN (Uso exclusivo del endpoint de autenticación)
CREATE OR REPLACE FUNCTION usp_psicologas_get_login(
    p_email_login VARCHAR
)
RETURNS TABLE (
    id              INT,
    nombre_completo VARCHAR,
    email_login     VARCHAR,
    password_hash   VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_email_login := NULLIF(LOWER(TRIM(p_email_login)), '');

    RETURN QUERY
    SELECT
        ps.id,
        ps.nombre_completo,
        ps.email_login,
        ps.password_hash
    FROM psicologas AS ps
    WHERE LOWER(ps.email_login) = p_email_login;
END;
$$;

-- 3. ACTUALIZAR PERFIL DE LA PSICÓLOGA
CREATE OR REPLACE PROCEDURE usp_psicologas_update(
    p_id                    INT,
    p_nombre_completo       VARCHAR,
    p_especialidad          VARCHAR,
    p_cedula_profesional    VARCHAR,
    p_biografia             TEXT,
    p_telefono_contacto     VARCHAR,
    p_direccion_consultorio VARCHAR,
    p_foto_url              VARCHAR,
    p_duracion_sesion_min   INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_nombre_completo       := NULLIF(TRIM(p_nombre_completo), '');
    p_especialidad          := NULLIF(TRIM(p_especialidad), '');
    p_cedula_profesional    := NULLIF(TRIM(p_cedula_profesional), '');
    p_biografia             := NULLIF(TRIM(p_biografia), '');
    p_telefono_contacto     := NULLIF(TRIM(p_telefono_contacto), '');
    p_direccion_consultorio := NULLIF(TRIM(p_direccion_consultorio), '');
    p_foto_url              := NULLIF(TRIM(p_foto_url), '');

    IF p_nombre_completo IS NULL OR p_especialidad IS NULL
       OR p_cedula_profesional IS NULL OR p_telefono_contacto IS NULL
       OR p_direccion_consultorio IS NULL THEN
        RAISE EXCEPTION 'Los datos principales del perfil de la psicóloga son obligatorios.'
            USING ERRCODE = 'P0010';
    END IF;

    IF p_duracion_sesion_min IS NULL OR p_duracion_sesion_min <= 0 THEN
        RAISE EXCEPTION 'La duración de la sesión debe ser mayor a 0 minutos.'
            USING ERRCODE = 'P0011';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM psicologas WHERE id = p_id) THEN
        RAISE EXCEPTION 'Psicóloga no encontrada.'
            USING ERRCODE = 'P0012';
    END IF;

    IF EXISTS (
        SELECT 1 FROM psicologas
        WHERE cedula_profesional = p_cedula_profesional AND id <> p_id
    ) THEN
        RAISE EXCEPTION 'Ya existe otra psicóloga registrada con esa cédula profesional.'
            USING ERRCODE = 'P0013';
    END IF;

    UPDATE psicologas
    SET
        nombre_completo       = p_nombre_completo,
        especialidad          = p_especialidad,
        cedula_profesional    = p_cedula_profesional,
        biografia             = p_biografia,
        telefono_contacto     = p_telefono_contacto,
        direccion_consultorio = p_direccion_consultorio,
        foto_url              = p_foto_url,
        duracion_sesion_min   = p_duracion_sesion_min
    WHERE id = p_id;
END;
$$;

-- 4. CREAR BLOQUE DE HORARIO BASE SEMANAL
CREATE OR REPLACE PROCEDURE usp_horarios_base_create(
    p_psicologa_id INT,
    p_dia_semana   SMALLINT,
    p_hora_inicio  TIME,
    p_hora_fin     TIME,
    p_activo       BOOLEAN DEFAULT TRUE,
    INOUT p_id     INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM psicologas WHERE id = p_psicologa_id) THEN
        RAISE EXCEPTION 'Psicóloga no encontrada.' USING ERRCODE = 'P0012';
    END IF;

    IF p_dia_semana < 0 OR p_dia_semana > 6 THEN
        RAISE EXCEPTION 'El día de la semana debe estar entre 0 (Domingo) y 6 (Sábado).'
            USING ERRCODE = 'P0014';
    END IF;

    IF p_hora_fin <= p_hora_inicio THEN
        RAISE EXCEPTION 'La hora de fin debe ser posterior a la hora de inicio.'
            USING ERRCODE = 'P0015';
    END IF;

    IF EXISTS (
        SELECT 1 FROM horarios_base
        WHERE psicologa_id = p_psicologa_id
          AND dia_semana = p_dia_semana
          AND activo = TRUE
          AND p_hora_inicio < hora_fin
          AND p_hora_fin > hora_inicio
    ) THEN
        RAISE EXCEPTION 'El rango horario se traslapa con otro horario activo en ese mismo día.'
            USING ERRCODE = 'P0016';
    END IF;

    INSERT INTO horarios_base (psicologa_id, dia_semana, hora_inicio, hora_fin, activo)
    VALUES (p_psicologa_id, p_dia_semana, p_hora_inicio, p_hora_fin, COALESCE(p_activo, TRUE))
    RETURNING id INTO p_id;
END;
$$;

-- 5. CONSULTAR HORARIOS BASE DE UNA PSICÓLOGA
CREATE OR REPLACE FUNCTION usp_horarios_base_get_by_psicologa(
    p_psicologa_id INT
)
RETURNS TABLE (
    id           INT,
    psicologa_id INT,
    dia_semana   SMALLINT,
    hora_inicio  TIME,
    hora_fin     TIME,
    activo       BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        hb.id,
        hb.psicologa_id,
        hb.dia_semana,
        hb.hora_inicio,
        hb.hora_fin,
        hb.activo
    FROM horarios_base AS hb
    WHERE hb.psicologa_id = p_psicologa_id
    ORDER BY hb.dia_semana ASC, hb.hora_inicio ASC;
END;
$$;

-- 6. ELIMINAR BLOQUE DE HORARIO BASE
CREATE OR REPLACE PROCEDURE usp_horarios_base_delete(
    p_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM horarios_base WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Horario base no encontrado.' USING ERRCODE = 'P0017';
    END IF;
END;
$$;

-- 7. CREAR BLOQUEO DE AGENDA (Vacaciones, días festivos, ausencias)
CREATE OR REPLACE PROCEDURE usp_bloqueos_agenda_create(
    p_psicologa_id INT,
    p_fecha_inicio TIMESTAMP,
    p_fecha_fin    TIMESTAMP,
    p_motivo       VARCHAR DEFAULT NULL,
    INOUT p_id     INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_motivo := NULLIF(TRIM(p_motivo), '');

    IF NOT EXISTS (SELECT 1 FROM psicologas WHERE id = p_psicologa_id) THEN
        RAISE EXCEPTION 'Psicóloga no encontrada.' USING ERRCODE = 'P0012';
    END IF;

    IF p_fecha_fin <= p_fecha_inicio THEN
        RAISE EXCEPTION 'La fecha/hora de fin del bloqueo debe ser posterior al inicio.'
            USING ERRCODE = 'P0018';
    END IF;

    INSERT INTO bloqueos_agenda (psicologa_id, fecha_inicio, fecha_fin, motivo)
    VALUES (p_psicologa_id, p_fecha_inicio, p_fecha_fin, p_motivo)
    RETURNING id INTO p_id;
END;
$$;

-- 8. CONSULTAR BLOQUEOS DE AGENDA
CREATE OR REPLACE FUNCTION usp_bloqueos_agenda_get_by_psicologa(
    p_psicologa_id INT
)
RETURNS TABLE (
    id           INT,
    psicologa_id INT,
    fecha_inicio TIMESTAMP,
    fecha_fin    TIMESTAMP,
    motivo       VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ba.id,
        ba.psicologa_id,
        ba.fecha_inicio,
        ba.fecha_fin,
        ba.motivo
    FROM bloqueos_agenda AS ba
    WHERE ba.psicologa_id = p_psicologa_id
    ORDER BY ba.fecha_inicio ASC;
END;
$$;

-- 9. ELIMINAR BLOQUEO DE AGENDA
CREATE OR REPLACE PROCEDURE usp_bloqueos_agenda_delete(
    p_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM bloqueos_agenda WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bloqueo de agenda no encontrado.' USING ERRCODE = 'P0019';
    END IF;
END;
$$;