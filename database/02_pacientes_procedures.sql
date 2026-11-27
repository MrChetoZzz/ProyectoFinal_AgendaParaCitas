-- ============================================================================
-- PROCEDIMIENTOS Y FUNCIONES CRUD: ENTIDAD PACIENTES
-- Motor: PostgreSQL 14+ (Supabase / pgAdmin 4)
-- ============================================================================

-- 1. CREAR PACIENTE (Equivalente a usp_Customers_Create con parámetro de salida)
CREATE OR REPLACE PROCEDURE usp_pacientes_create(
    p_nombre_completo VARCHAR,
    p_telefono        VARCHAR,
    p_email           VARCHAR,
    INOUT p_id        INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_nombre_completo := NULLIF(TRIM(p_nombre_completo), '');
    p_telefono        := NULLIF(TRIM(p_telefono), '');
    p_email           := NULLIF(LOWER(TRIM(p_email)), '');

    IF p_nombre_completo IS NULL OR p_telefono IS NULL OR p_email IS NULL THEN
        RAISE EXCEPTION 'El nombre completo, teléfono y correo electrónico son obligatorios.'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_email NOT LIKE '%_@_%._%' THEN
        RAISE EXCEPTION 'El correo electrónico del paciente no es válido.'
            USING ERRCODE = 'P0002';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pacientes
        WHERE telefono = p_telefono AND email = p_email
    ) THEN
        RAISE EXCEPTION 'Ya existe un paciente registrado con ese teléfono y correo electrónico.'
            USING ERRCODE = 'P0003';
    END IF;

    INSERT INTO pacientes (nombre_completo, telefono, email)
    VALUES (p_nombre_completo, p_telefono, p_email)
    RETURNING id INTO p_id;
END;
$$;

-- 2. OBTENER O REGISTRAR PACIENTE AL AGENDAR (Útil para el formulario público)
CREATE OR REPLACE PROCEDURE usp_pacientes_obtener_o_crear(
    p_nombre_completo VARCHAR,
    p_telefono        VARCHAR,
    p_email           VARCHAR,
    INOUT p_id        INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_nombre_completo := NULLIF(TRIM(p_nombre_completo), '');
    p_telefono        := NULLIF(TRIM(p_telefono), '');
    p_email           := NULLIF(LOWER(TRIM(p_email)), '');

    IF p_nombre_completo IS NULL OR p_telefono IS NULL OR p_email IS NULL THEN
        RAISE EXCEPTION 'El nombre completo, teléfono y correo electrónico son obligatorios.'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_email NOT LIKE '%_@_%._%' THEN
        RAISE EXCEPTION 'El correo electrónico del paciente no es válido.'
            USING ERRCODE = 'P0002';
    END IF;

    SELECT id INTO p_id
    FROM pacientes
    WHERE telefono = p_telefono AND email = p_email;

    IF p_id IS NULL THEN
        INSERT INTO pacientes (nombre_completo, telefono, email)
        VALUES (p_nombre_completo, p_telefono, p_email)
        RETURNING id INTO p_id;
    ELSE
        UPDATE pacientes
        SET nombre_completo = p_nombre_completo
        WHERE id = p_id;
    END IF;
END;
$$;

-- 3. CONSULTAR PACIENTE POR ID
CREATE OR REPLACE FUNCTION usp_pacientes_get_by_id(
    p_id INT
)
RETURNS TABLE (
    id              INT,
    nombre_completo VARCHAR,
    telefono        VARCHAR,
    email           VARCHAR,
    creado_en       TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.nombre_completo,
        p.telefono,
        p.email,
        p.creado_en
    FROM pacientes AS p
    WHERE p.id = p_id;
END;
$$;

-- 4. CONSULTAR TODOS LOS PACIENTES (Con filtro opcional por nombre, teléfono o correo)
CREATE OR REPLACE FUNCTION usp_pacientes_get_all(
    p_busqueda VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id              INT,
    nombre_completo VARCHAR,
    telefono        VARCHAR,
    email           VARCHAR,
    creado_en       TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_busqueda := NULLIF(TRIM(p_busqueda), '');

    RETURN QUERY
    SELECT
        p.id,
        p.nombre_completo,
        p.telefono,
        p.email,
        p.creado_en
    FROM pacientes AS p
    WHERE p_busqueda IS NULL
       OR p.nombre_completo ILIKE '%' || p_busqueda || '%'
       OR p.telefono ILIKE '%' || p_busqueda || '%'
       OR p.email ILIKE '%' || p_busqueda || '%'
    ORDER BY p.nombre_completo ASC;
END;
$$;

-- 5. ACTUALIZAR PACIENTE
CREATE OR REPLACE PROCEDURE usp_pacientes_update(
    p_id              INT,
    p_nombre_completo VARCHAR,
    p_telefono        VARCHAR,
    p_email           VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_nombre_completo := NULLIF(TRIM(p_nombre_completo), '');
    p_telefono        := NULLIF(TRIM(p_telefono), '');
    p_email           := NULLIF(LOWER(TRIM(p_email)), '');

    IF p_nombre_completo IS NULL OR p_telefono IS NULL OR p_email IS NULL THEN
        RAISE EXCEPTION 'El nombre completo, teléfono y correo electrónico son obligatorios.'
            USING ERRCODE = 'P0001';
    END IF;

    IF p_email NOT LIKE '%_@_%._%' THEN
        RAISE EXCEPTION 'El correo electrónico del paciente no es válido.'
            USING ERRCODE = 'P0002';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pacientes WHERE id = p_id) THEN
        RAISE EXCEPTION 'Paciente no encontrado.'
            USING ERRCODE = 'P0005';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pacientes
        WHERE telefono = p_telefono
          AND email = p_email
          AND id <> p_id
    ) THEN
        RAISE EXCEPTION 'Otro paciente ya está registrado con ese teléfono y correo.'
            USING ERRCODE = 'P0003';
    END IF;

    UPDATE pacientes
    SET
        nombre_completo = p_nombre_completo,
        telefono        = p_telefono,
        email           = p_email
    WHERE id = p_id;
END;
$$;

-- 6. ELIMINAR PACIENTE (Bloquea fila y valida que no tenga citas)
CREATE OR REPLACE PROCEDURE usp_pacientes_delete(
    p_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1 FROM pacientes WHERE id = p_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Paciente no encontrado.'
            USING ERRCODE = 'P0005';
    END IF;

    IF EXISTS (SELECT 1 FROM citas WHERE paciente_id = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar un paciente que tiene citas registradas.'
            USING ERRCODE = 'P0006';
    END IF;

    DELETE FROM pacientes WHERE id = p_id;
END;
$$;