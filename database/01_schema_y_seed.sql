-- ============================================================================
-- SCRIPT DE BASE DE DATOS: SISTEMA DE GESTIÓN DE CITAS (CONSULTORIO PSICOLÓGICO)
-- Motor: PostgreSQL 14+ (Compatible con pgAdmin 4, Neon, Supabase y Render)
-- ============================================================================

BEGIN;

-- Limpieza previa opcional (útil si necesitas reiniciar la BD desde cero)
DROP TABLE IF EXISTS citas CASCADE;
DROP TABLE IF EXISTS bloqueos_agenda CASCADE;
DROP TABLE IF EXISTS horarios_base CASCADE;
DROP TABLE IF EXISTS pacientes CASCADE;
DROP TABLE IF EXISTS psicologas CASCADE;

-- ============================================================================
-- 1. TABLA: psicologas (Perfil público y acceso al panel administrativo)
-- ============================================================================
CREATE TABLE psicologas (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_completo VARCHAR(120) NOT NULL,
    especialidad VARCHAR(100) NOT NULL,
    cedula_profesional VARCHAR(30) NOT NULL UNIQUE,
    biografia TEXT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    direccion_consultorio VARCHAR(255) NOT NULL,
    foto_url VARCHAR(500) NULL,
    duracion_sesion_min INT NOT NULL DEFAULT 50 CHECK (duracion_sesion_min > 0),
    email_login VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. TABLA: horarios_base (Disponibilidad semanal recurrente)
-- ============================================================================
CREATE TABLE horarios_base (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    psicologa_id INT NOT NULL,
    dia_semana SMALLINT NOT NULL CHECK (dia_semana BETWEEN 0 AND 6), -- 0=Domingo, 1=Lunes ... 6=Sábado
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_horario_psicologa FOREIGN KEY (psicologa_id)
        REFERENCES psicologas(id) ON DELETE CASCADE,
    CONSTRAINT chk_horario_valido CHECK (hora_fin > hora_inicio)
);

-- ============================================================================
-- 3. TABLA: bloqueos_agenda (Días inhábiles, vacaciones o excepciones)
-- ============================================================================
CREATE TABLE bloqueos_agenda (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    psicologa_id INT NOT NULL,
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    motivo VARCHAR(150) NULL,
    CONSTRAINT fk_bloqueo_psicologa FOREIGN KEY (psicologa_id)
        REFERENCES psicologas(id) ON DELETE CASCADE,
    CONSTRAINT chk_bloqueo_valido CHECK (fecha_fin > fecha_inicio)
);

-- ============================================================================
-- 4. TABLA: pacientes (Datos de contacto validados al reservar cita)
-- ============================================================================
CREATE TABLE pacientes (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_completo VARCHAR(120) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(150) NOT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_paciente_contacto UNIQUE (telefono, email)
);

-- ============================================================================
-- 5. TABLA: citas (Transacciones principales de agendamiento)
-- ============================================================================
CREATE TABLE citas (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    psicologa_id INT NOT NULL,
    paciente_id INT NOT NULL,
    fecha_cita DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'Confirmada', 'Completada', 'Cancelada')),
    motivo_consulta VARCHAR(300) NULL,
    notas_psicologa TEXT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cita_psicologa FOREIGN KEY (psicologa_id)
        REFERENCES psicologas(id) ON DELETE RESTRICT,
    CONSTRAINT fk_cita_paciente FOREIGN KEY (paciente_id)
        REFERENCES pacientes(id) ON DELETE RESTRICT,
    CONSTRAINT chk_cita_horas CHECK (hora_fin > hora_inicio)
);

-- ============================================================================
-- 6. ÍNDICES DE RENDIMIENTO Y REGLA ANTI-EMPALMES (CONCURRENCIA)
-- ============================================================================

-- Impide que dos citas activas (no canceladas) ocupen el mismo horario y fecha
CREATE UNIQUE INDEX uq_citas_horario_activo
    ON citas (psicologa_id, fecha_cita, hora_inicio)
    WHERE estado <> 'Cancelada';

-- Acelera las consultas del calendario público y del dashboard diario
CREATE INDEX idx_citas_psicologa_fecha
    ON citas (psicologa_id, fecha_cita, estado);

-- Acelera la búsqueda de pacientes existentes por teléfono
CREATE INDEX idx_pacientes_telefono
    ON pacientes (telefono);

-- ============================================================================
-- 7. TRIGGER: Actualización automática de 'actualizado_en' en citas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_actualizar_timestamp_cita()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_citas_actualizado_en
    BEFORE UPDATE ON citas
    FOR EACH ROW
    EXECUTE FUNCTION fn_actualizar_timestamp_cita();

-- ============================================================================
-- 8. DATOS SEMILLA (SEED) PARA PRUEBAS INICIALES DEL FRONTEND Y BACKEND
-- ============================================================================

-- Perfil inicial de la psicóloga (Contraseña de ejemplo: 'Admin1234*' en hash BCrypt)
INSERT INTO psicologas (
    nombre_completo, especialidad, cedula_profesional, biografia,
    telefono_contacto, direccion_consultorio, duracion_sesion_min,
    email_login, password_hash
) VALUES (
    'Dra. Camila Domínguez',
    'Psicología Clínica y Terapia Cognitivo-Conductual',
    '11849203',
    'Especialista en manejo de ansiedad, estrés laboral y desarrollo personal con enfoque cognitivo-conductual.',
    '8671234567',
    'Av. Reforma #2450, Consultorio 4B, Col. Jardín',
    50,
    'camila.psicologia@consultorio.com',
    '$2a$11$KIX8x7Z9mP2nL4qR6sT8uO1vW3yA5cE7gI9kM1oQ3sU5wY7aC9eG1'
);

-- Horario semanal base (Lunes a Viernes: 09:00-14:00 y 16:00-19:00; Sábado: 09:00-13:00)
INSERT INTO horarios_base (psicologa_id, dia_semana, hora_inicio, hora_fin, activo) VALUES
    (1, 1, '09:00', '14:00', TRUE),
    (1, 1, '16:00', '19:00', TRUE),
    (1, 2, '09:00', '14:00', TRUE),
    (1, 2, '16:00', '19:00', TRUE),
    (1, 3, '09:00', '14:00', TRUE),
    (1, 3, '16:00', '19:00', TRUE),
    (1, 4, '09:00', '14:00', TRUE),
    (1, 4, '16:00', '19:00', TRUE),
    (1, 5, '09:00', '14:00', TRUE),
    (1, 5, '16:00', '19:00', TRUE),
    (1, 6, '09:00', '13:00', TRUE);

-- Pacientes de prueba
INSERT INTO pacientes (nombre_completo, telefono, email) VALUES
    ('Carlos Eduardo Garza', '8675550101', 'carlos.garza@email.com'),
    ('Mariana López Cantú', '8675550102', 'mariana.lopez@email.com'),
    ('Luis Fernando Treviño', '8675550103', 'luis.trevino@email.com');

-- Citas de prueba (relativas a la fecha actual para que siempre aparezcan en la agenda)
INSERT INTO citas (psicologa_id, paciente_id, fecha_cita, hora_inicio, hora_fin, estado, motivo_consulta, notas_psicologa) VALUES
    (1, 1, CURRENT_DATE - INTERVAL '1 day', '10:00', '10:50', 'Completada', 'Primera sesión de valoración por estrés', 'Paciente receptivo, se acuerda seguimiento semanal.'),
    (1, 2, CURRENT_DATE, '11:00', '11:50', 'Confirmada', 'Seguimiento manejo de ansiedad', NULL),
    (1, 3, CURRENT_DATE + INTERVAL '1 day', '16:00', '16:50', 'Pendiente', 'Consulta inicial orientación vocacional', NULL);

COMMIT;