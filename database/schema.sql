-- =====================================================================
--  SICA - Sistema Integrado de Control de Acceso (Zona Acme)
--  schema.sql : creacion de la base de datos y sus tablas
--  Motor: MySQL 8.x
-- =====================================================================

-- ¡OJO! Borra la base completa si ya existe (solo para desarrollo)
DROP DATABASE IF EXISTS sica_db;

CREATE DATABASE sica_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sica_db;


-- =====================================================================
--  BLOQUE 1: AUTORIZACION (RBAC)
-- =====================================================================

-- Roles del sistema: agrupaciones de permisos
CREATE TABLE roles (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol  VARCHAR(50)  NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT uk_roles_nombre UNIQUE (nombre_rol)
) ENGINE = InnoDB;

-- Cada accion granular que se puede realizar (ej. 'registrar_checkin')
CREATE TABLE permisos (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    nombre_permiso VARCHAR(100) NOT NULL,
    descripcion    VARCHAR(255),
    CONSTRAINT uk_permisos_nombre UNIQUE (nombre_permiso)
) ENGINE = InnoDB;

-- Tabla intermedia (muchos a muchos) entre roles y permisos.
-- Permite el RBAC simetrico: rol -> permisos y permiso -> roles
CREATE TABLE rol_permisos (
    rol_id     INT NOT NULL,
    permiso_id INT NOT NULL,
    PRIMARY KEY (rol_id, permiso_id),
    CONSTRAINT fk_rolperm_rol
        FOREIGN KEY (rol_id) REFERENCES roles (id)
        ON DELETE CASCADE,
    CONSTRAINT fk_rolperm_permiso
        FOREIGN KEY (permiso_id) REFERENCES permisos (id)
        ON DELETE CASCADE
) ENGINE = InnoDB;

-- Indice para la consulta inversa: "¿que roles tienen este permiso?"
CREATE INDEX idx_rolperm_permiso ON rol_permisos (permiso_id);


-- =====================================================================
--  BLOQUE 2: TABLAS DE CONSULTA (CATALOGOS)
--  Valores fijos que se configuran en la BD y no en el codigo.
--  Sus filas se insertan en data.sql
-- =====================================================================

-- Tipos de persona: 'Trabajador', 'Invitado'
CREATE TABLE tipos_persona (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT uk_tipos_persona_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- Estados de acceso de una persona: 'Activo', 'Con Prohibicion de Ingreso'
CREATE TABLE persona_estados_acceso (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL,
    descripcion   VARCHAR(255),
    CONSTRAINT uk_persona_estados_nombre UNIQUE (nombre_estado)
) ENGINE = InnoDB;

-- Estados de una visita: 'Pendiente de Aprobacion', 'Aprobado', 'Dentro', 'Fuera', ...
CREATE TABLE visita_estados (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL,
    descripcion   VARCHAR(255),
    CONSTRAINT uk_visita_estados_nombre UNIQUE (nombre_estado)
) ENGINE = InnoDB;

-- Como se origino el ingreso: 'Pre-registrado', 'No anunciado', 'Olvido de carnet'
CREATE TABLE tipos_ingreso (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT uk_tipos_ingreso_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- Para que viene la persona: 'Reunion', 'Entrevista de trabajo', 'Proveedor / Entrega', ...
CREATE TABLE motivos_visita (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT uk_motivos_visita_nombre UNIQUE (nombre)
) ENGINE = InnoDB;


-- =====================================================================
--  BLOQUE 3: EMPRESAS, USUARIOS Y FUNCIONARIOS
-- =====================================================================

-- Empresas que funcionan dentro del complejo
CREATE TABLE empresas (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    nombre             VARCHAR(100) NOT NULL,
    contacto_principal VARCHAR(100),
    telefono           VARCHAR(20),
    ubicacion          VARCHAR(100),            -- piso / oficina dentro del complejo
    esta_activa        BOOLEAN  NOT NULL DEFAULT TRUE,
    fecha_creacion     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_empresas_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- Usuarios que inician sesion en el sistema (un solo rol por usuario)
CREATE TABLE usuarios (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    email             VARCHAR(100) NOT NULL,
    password_hash     CHAR(64)     NOT NULL,     -- SHA-256 en hexadecimal
    salt              CHAR(64)     NOT NULL,     -- 32 bytes aleatorios en hexadecimal
    rol_id            INT          NOT NULL,
    esta_activo       BOOLEAN      NOT NULL DEFAULT TRUE,
    intentos_fallidos INT          NOT NULL DEFAULT 0,
    bloqueado_hasta   DATETIME     NULL,         -- NULL = no esta bloqueado
    fecha_creacion    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_usuarios_email UNIQUE (email),
    CONSTRAINT ck_usuarios_intentos CHECK (intentos_fallidos >= 0),
    CONSTRAINT fk_usuarios_rol
        FOREIGN KEY (rol_id) REFERENCES roles (id)
) ENGINE = InnoDB;

-- Especializacion de usuarios: solo los Funcionarios de Empresa tienen empresa.
-- Comparte la llave primaria con usuarios (relacion 1 a 1)
CREATE TABLE funcionarios (
    usuario_id INT PRIMARY KEY,
    empresa_id INT NOT NULL,
    cargo      VARCHAR(100),
    CONSTRAINT fk_funcionarios_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
    CONSTRAINT fk_funcionarios_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas (id)
) ENGINE = InnoDB;


-- =====================================================================
--  BLOQUE 4: PERSONAS (TRABAJADORES E INVITADOS)
-- =====================================================================

-- Datos comunes a todas las personas que entran al complejo
CREATE TABLE personas (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    nombre              VARCHAR(100) NOT NULL,
    documento_identidad VARCHAR(20)  NOT NULL,
    tipo_persona_id     INT          NOT NULL,
    estado_acceso_id    INT          NOT NULL,   -- estado ACTUAL (el historial guarda los cambios)
    url_foto            VARCHAR(255),
    telefono            VARCHAR(20),
    esta_activa         BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_registro      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_personas_documento UNIQUE (documento_identidad),
    CONSTRAINT fk_personas_tipo
        FOREIGN KEY (tipo_persona_id) REFERENCES tipos_persona (id),
    CONSTRAINT fk_personas_estado
        FOREIGN KEY (estado_acceso_id) REFERENCES persona_estados_acceso (id)
) ENGINE = InnoDB;

-- El guarda busca por nombre en el flujo de "carnet olvidado"
CREATE INDEX idx_personas_nombre ON personas (nombre);

-- Especializacion: solo los trabajadores pertenecen a una empresa del complejo
CREATE TABLE trabajadores (
    persona_id INT PRIMARY KEY,
    empresa_id INT NOT NULL,
    cargo      VARCHAR(100),
    CONSTRAINT fk_trabajadores_persona
        FOREIGN KEY (persona_id) REFERENCES personas (id),
    CONSTRAINT fk_trabajadores_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas (id)
) ENGINE = InnoDB;

-- Especializacion: los invitados pueden venir de una empresa externa
CREATE TABLE invitados (
    persona_id          INT PRIMARY KEY,
    empresa_procedencia VARCHAR(100),           -- ej. 'Coca-Cola' (texto libre, opcional)
    CONSTRAINT fk_invitados_persona
        FOREIGN KEY (persona_id) REFERENCES personas (id)
) ENGINE = InnoDB;

-- Historial de cambios de estado de acceso (bloqueos / desbloqueos)
CREATE TABLE historial_estado_persona (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    persona_id         INT          NOT NULL,
    estado_anterior_id INT          NULL,        -- NULL en el primer registro de la persona
    estado_nuevo_id    INT          NOT NULL,
    motivo             VARCHAR(500) NOT NULL,
    usuario_id         INT          NOT NULL,    -- quien hizo el cambio
    fecha              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_persona
        FOREIGN KEY (persona_id) REFERENCES personas (id),
    CONSTRAINT fk_historial_estado_anterior
        FOREIGN KEY (estado_anterior_id) REFERENCES persona_estados_acceso (id),
    CONSTRAINT fk_historial_estado_nuevo
        FOREIGN KEY (estado_nuevo_id) REFERENCES persona_estados_acceso (id),
    CONSTRAINT fk_historial_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE = InnoDB;

-- Consultar el historial de una persona ordenado por fecha
CREATE INDEX idx_historial_persona_fecha ON historial_estado_persona (persona_id, fecha);


-- =====================================================================
--  BLOQUE 4.1: PROCEDIMIENTOS DE CREACION (TODO O NADA)
--  Crear una entidad especializada requiere 2 o mas INSERT. Estos
--  procedimientos los ejecutan dentro de una transaccion: si uno falla,
--  se deshace todo (ROLLBACK) y el error se devuelve a Java (RESIGNAL).
-- =====================================================================

DELIMITER $$

-- Crea persona + trabajador + historial inicial ('Activo')
CREATE PROCEDURE sp_crear_trabajador(
    IN  p_nombre     VARCHAR(100),
    IN  p_documento  VARCHAR(20),
    IN  p_url_foto   VARCHAR(255),
    IN  p_telefono   VARCHAR(20),
    IN  p_empresa_id INT,
    IN  p_cargo      VARCHAR(100),
    IN  p_usuario_id INT,             -- usuario que registra
    OUT p_persona_id INT
)
BEGIN
    DECLARE v_tipo_id   INT;
    DECLARE v_estado_id INT;

    -- Si cualquier sentencia falla: deshacer y devolver el error original
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT id INTO v_tipo_id   FROM tipos_persona          WHERE nombre = 'Trabajador';
    SELECT id INTO v_estado_id FROM persona_estados_acceso WHERE nombre_estado = 'Activo';

    IF v_tipo_id IS NULL OR v_estado_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Faltan catalogos: tipo Trabajador o estado Activo';
    END IF;

    START TRANSACTION;
        INSERT INTO personas (nombre, documento_identidad, tipo_persona_id,
                              estado_acceso_id, url_foto, telefono)
        VALUES (p_nombre, p_documento, v_tipo_id, v_estado_id, p_url_foto, p_telefono);

        SET p_persona_id = LAST_INSERT_ID();

        INSERT INTO trabajadores (persona_id, empresa_id, cargo)
        VALUES (p_persona_id, p_empresa_id, p_cargo);

        INSERT INTO historial_estado_persona (persona_id, estado_anterior_id,
                                              estado_nuevo_id, motivo, usuario_id)
        VALUES (p_persona_id, NULL, v_estado_id, 'Registro inicial', p_usuario_id);
    COMMIT;
END$$

-- Crea persona + invitado + historial inicial ('Activo')
CREATE PROCEDURE sp_crear_invitado(
    IN  p_nombre              VARCHAR(100),
    IN  p_documento           VARCHAR(20),
    IN  p_url_foto            VARCHAR(255),
    IN  p_telefono            VARCHAR(20),
    IN  p_empresa_procedencia VARCHAR(100),
    IN  p_usuario_id          INT,
    OUT p_persona_id          INT
)
BEGIN
    DECLARE v_tipo_id   INT;
    DECLARE v_estado_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT id INTO v_tipo_id   FROM tipos_persona          WHERE nombre = 'Invitado';
    SELECT id INTO v_estado_id FROM persona_estados_acceso WHERE nombre_estado = 'Activo';

    IF v_tipo_id IS NULL OR v_estado_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Faltan catalogos: tipo Invitado o estado Activo';
    END IF;

    START TRANSACTION;
        INSERT INTO personas (nombre, documento_identidad, tipo_persona_id,
                              estado_acceso_id, url_foto, telefono)
        VALUES (p_nombre, p_documento, v_tipo_id, v_estado_id, p_url_foto, p_telefono);

        SET p_persona_id = LAST_INSERT_ID();

        INSERT INTO invitados (persona_id, empresa_procedencia)
        VALUES (p_persona_id, p_empresa_procedencia);

        INSERT INTO historial_estado_persona (persona_id, estado_anterior_id,
                                              estado_nuevo_id, motivo, usuario_id)
        VALUES (p_persona_id, NULL, v_estado_id, 'Registro inicial', p_usuario_id);
    COMMIT;
END$$

-- Crea usuario (con rol 'Funcionario de Empresa') + funcionario.
-- El rol lo pone el procedimiento: asi un Guarda nunca puede quedar como funcionario
CREATE PROCEDURE sp_crear_funcionario(
    IN  p_nombre        VARCHAR(100),
    IN  p_email         VARCHAR(100),
    IN  p_password_hash CHAR(64),
    IN  p_salt          CHAR(64),
    IN  p_empresa_id    INT,
    IN  p_cargo         VARCHAR(100),
    OUT p_usuario_id    INT
)
BEGIN
    DECLARE v_rol_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT id INTO v_rol_id FROM roles WHERE nombre_rol = 'Funcionario de Empresa';

    IF v_rol_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Falta el rol Funcionario de Empresa';
    END IF;

    START TRANSACTION;
        INSERT INTO usuarios (nombre, email, password_hash, salt, rol_id)
        VALUES (p_nombre, p_email, p_password_hash, p_salt, v_rol_id);

        SET p_usuario_id = LAST_INSERT_ID();

        INSERT INTO funcionarios (usuario_id, empresa_id, cargo)
        VALUES (p_usuario_id, p_empresa_id, p_cargo);
    COMMIT;
END$$

DELIMITER ;


-- =====================================================================
--  BLOQUE 5: OPERACION (VISITAS E INCIDENTES)
-- =====================================================================

-- Cada ingreso/salida (o solicitud de ingreso) de una persona.
-- La empresa destino NO se guarda: se obtiene del anfitrion (3FN)
CREATE TABLE visitas (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    persona_id          INT          NOT NULL,
    anfitrion_id        INT          NULL,      -- funcionario visitado (NULL para trabajadores)
    tipo_ingreso_id     INT          NOT NULL,
    motivo_id           INT          NULL,      -- NULL para trabajadores
    detalle_motivo      VARCHAR(255),
    fecha_programada    DATE         NULL,      -- solo visitas pre-registradas
    fecha_entrada       DATETIME     NULL,      -- NULL mientras no haya check-in
    fecha_salida        DATETIME     NULL,      -- NULL mientras siga dentro
    estado_visita_id    INT          NOT NULL,
    vehiculo_placa      VARCHAR(10),
    registrado_por      INT          NOT NULL,  -- usuario que creo el registro
    visita_aprobada_por INT          NULL,      -- usuario que aprobo / rechazo
    fecha_respuesta     DATETIME     NULL,
    checkin_por         INT          NULL,      -- guarda que hizo el check-in
    checkout_por        INT          NULL,      -- guarda que hizo el check-out
    fecha_creacion      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_visitas_fechas
        CHECK (fecha_salida IS NULL OR fecha_entrada IS NULL OR fecha_salida >= fecha_entrada),

    CONSTRAINT fk_visitas_persona
        FOREIGN KEY (persona_id) REFERENCES personas (id),
    CONSTRAINT fk_visitas_anfitrion                -- apunta a funcionarios, no a usuarios:
        FOREIGN KEY (anfitrion_id) REFERENCES funcionarios (usuario_id),  -- solo un funcionario puede ser anfitrion
    CONSTRAINT fk_visitas_tipo_ingreso
        FOREIGN KEY (tipo_ingreso_id) REFERENCES tipos_ingreso (id),
    CONSTRAINT fk_visitas_motivo
        FOREIGN KEY (motivo_id) REFERENCES motivos_visita (id),
    CONSTRAINT fk_visitas_estado
        FOREIGN KEY (estado_visita_id) REFERENCES visita_estados (id),
    CONSTRAINT fk_visitas_registrado_por
        FOREIGN KEY (registrado_por) REFERENCES usuarios (id),
    CONSTRAINT fk_visitas_aprobada_por
        FOREIGN KEY (visita_aprobada_por) REFERENCES usuarios (id),
    CONSTRAINT fk_visitas_checkin_por
        FOREIGN KEY (checkin_por) REFERENCES usuarios (id),
    CONSTRAINT fk_visitas_checkout_por
        FOREIGN KEY (checkout_por) REFERENCES usuarios (id)
) ENGINE = InnoDB;

-- "¿Esta persona tiene una visita abierta?" (flujo de salida olvidada)
CREATE INDEX idx_visitas_persona_estado   ON visitas (persona_id, estado_visita_id);
-- Solicitudes pendientes del funcionario (pantalla en tiempo real)
CREATE INDEX idx_visitas_anfitrion_estado ON visitas (anfitrion_id, estado_visita_id);
-- "¿Quien esta dentro ahora?" y listados por estado
CREATE INDEX idx_visitas_estado           ON visitas (estado_visita_id);
-- Reportes por rango de fechas
CREATE INDEX idx_visitas_fecha_entrada    ON visitas (fecha_entrada);
-- Expiracion automatica de visitas pre-registradas
CREATE INDEX idx_visitas_fecha_programada ON visitas (fecha_programada);

-- Incidentes de seguridad: siempre ocurren durante una visita
CREATE TABLE incidentes (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    visita_id        INT      NOT NULL,
    reportado_por_id INT      NOT NULL,         -- supervisor que reporta
    fecha            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion      TEXT     NOT NULL,
    CONSTRAINT fk_incidentes_visita
        FOREIGN KEY (visita_id) REFERENCES visitas (id),
    CONSTRAINT fk_incidentes_reportado_por
        FOREIGN KEY (reportado_por_id) REFERENCES usuarios (id)
) ENGINE = InnoDB;

CREATE INDEX idx_incidentes_fecha ON incidentes (fecha);


-- =====================================================================
--  BLOQUE 5.1: PROCEDIMIENTO DE INGRESO (CHECK-IN)
--  Cubre dos casos:
--    a) p_visita_id con valor -> check-in de una visita ya 'Aprobado'
--       (pre-registrada, no anunciada aprobada u olvido de carnet aprobado)
--    b) p_visita_id = NULL    -> ingreso regular de un trabajador con carnet
--  En ambos casos, si la persona tenia una visita 'Dentro' (salida olvidada),
--  se cierra como 'Cerrada por Sistema (Salida Olvidada)' en la MISMA transaccion.
-- =====================================================================

DELIMITER $$

CREATE PROCEDURE sp_registrar_ingreso(
    IN  p_persona_id       INT,
    IN  p_visita_id        INT,           -- NULL = ingreso regular de trabajador
    IN  p_guarda_id        INT,           -- usuario que hace el check-in
    IN  p_vehiculo_placa   VARCHAR(10),
    OUT p_visita_resultado INT,           -- visita que queda 'Dentro'
    OUT p_salidas_cerradas INT            -- cuantas salidas olvidadas se cerraron
)
BEGIN
    DECLARE v_estado_persona   VARCHAR(50);
    DECLARE v_persona_activa   BOOLEAN;
    DECLARE v_tipo_persona     VARCHAR(50);
    DECLARE v_visita_persona   INT;
    DECLARE v_visita_estado    INT;
    DECLARE v_visita_fecha     DATE;
    DECLARE v_id_dentro        INT;
    DECLARE v_id_aprobado      INT;
    DECLARE v_id_cerrada       INT;
    DECLARE v_id_tipo_regular  INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Catalogos necesarios
    SELECT id INTO v_id_dentro   FROM visita_estados WHERE nombre_estado = 'Dentro';
    SELECT id INTO v_id_aprobado FROM visita_estados WHERE nombre_estado = 'Aprobado';
    SELECT id INTO v_id_cerrada  FROM visita_estados
     WHERE nombre_estado = 'Cerrada por Sistema (Salida Olvidada)';
    SELECT id INTO v_id_tipo_regular FROM tipos_ingreso WHERE nombre = 'Ingreso regular';

    IF v_id_dentro IS NULL OR v_id_aprobado IS NULL
       OR v_id_cerrada IS NULL OR v_id_tipo_regular IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Faltan catalogos de estados de visita o tipos de ingreso';
    END IF;

    START TRANSACTION;

        -- 1. Bloquear la fila de la persona (FOR UPDATE): si dos guardas
        --    registran a la misma persona a la vez, el segundo espera.
        SELECT pe.nombre_estado, p.esta_activa, tp.nombre
          INTO v_estado_persona, v_persona_activa, v_tipo_persona
          FROM personas p
          JOIN persona_estados_acceso pe ON pe.id = p.estado_acceso_id
          JOIN tipos_persona tp          ON tp.id = p.tipo_persona_id
         WHERE p.id = p_persona_id
           FOR UPDATE;

        IF v_estado_persona IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La persona no existe';
        END IF;
        IF NOT v_persona_activa THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La persona esta desactivada';
        END IF;
        IF v_estado_persona = 'Con Prohibicion de Ingreso' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ACCESO DENEGADO: persona con prohibicion de ingreso';
        END IF;

        -- 2. Validar la visita (caso a) o que sea trabajador (caso b)
        IF p_visita_id IS NOT NULL THEN
            SELECT persona_id, estado_visita_id, fecha_programada
              INTO v_visita_persona, v_visita_estado, v_visita_fecha
              FROM visitas
             WHERE id = p_visita_id
               FOR UPDATE;

            IF v_visita_persona IS NULL OR v_visita_persona <> p_persona_id THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La visita no existe o no pertenece a la persona';
            END IF;
            IF v_visita_estado <> v_id_aprobado THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La visita no esta aprobada';
            END IF;
            IF v_visita_fecha IS NOT NULL AND v_visita_fecha <> CURDATE() THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La visita no esta programada para hoy';
            END IF;
        ELSEIF v_tipo_persona <> 'Trabajador' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un invitado necesita una visita aprobada';
        END IF;

        -- 3. Salida olvidada: cerrar visitas que quedaron 'Dentro'
        --    (fecha_salida queda NULL: la hora real de salida es desconocida)
        UPDATE visitas
           SET estado_visita_id = v_id_cerrada
         WHERE persona_id = p_persona_id
           AND estado_visita_id = v_id_dentro;

        SET p_salidas_cerradas = ROW_COUNT();

        -- 4. Registrar el ingreso
        IF p_visita_id IS NOT NULL THEN
            UPDATE visitas
               SET estado_visita_id = v_id_dentro,
                   fecha_entrada    = NOW(),
                   checkin_por      = p_guarda_id,
                   vehiculo_placa   = COALESCE(p_vehiculo_placa, vehiculo_placa)
             WHERE id = p_visita_id;

            SET p_visita_resultado = p_visita_id;
        ELSE
            INSERT INTO visitas (persona_id, tipo_ingreso_id, fecha_entrada,
                                 estado_visita_id, vehiculo_placa,
                                 registrado_por, checkin_por)
            VALUES (p_persona_id, v_id_tipo_regular, NOW(),
                    v_id_dentro, p_vehiculo_placa,
                    p_guarda_id, p_guarda_id);

            SET p_visita_resultado = LAST_INSERT_ID();
        END IF;

    COMMIT;
END$$

DELIMITER ;


-- =====================================================================
--  BLOQUE 6: AUDITORIA (BITACORA INMUTABLE)
--  Java inserta aqui un registro despues de cada operacion critica.
--  Los triggers impiden modificar o borrar registros: solo se puede INSERTAR.
-- =====================================================================

CREATE TABLE bitacora_auditoria (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id           INT          NULL,     -- NULL: ej. login fallido con email inexistente
    fecha_hora           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accion_realizada     VARCHAR(100) NOT NULL, -- ej. 'LOGIN_EXITOSO', 'CHECK_IN', 'BLOQUEO_PERSONA'
    tabla_afectada       VARCHAR(100),
    registro_id_afectado INT,
    detalles             TEXT,                  -- resumen del cambio (texto o JSON)
    CONSTRAINT fk_bitacora_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE = InnoDB;

-- Filtros del reporte de auditoria
CREATE INDEX idx_bitacora_fecha    ON bitacora_auditoria (fecha_hora);
CREATE INDEX idx_bitacora_usuario  ON bitacora_auditoria (usuario_id, fecha_hora);
CREATE INDEX idx_bitacora_accion   ON bitacora_auditoria (accion_realizada, fecha_hora);
CREATE INDEX idx_bitacora_registro ON bitacora_auditoria (tabla_afectada, registro_id_afectado);

DELIMITER $$

-- La fecha la pone SIEMPRE el servidor: nadie puede registrar una accion "en el pasado"
CREATE TRIGGER trg_bitacora_fecha
BEFORE INSERT ON bitacora_auditoria
FOR EACH ROW
BEGIN
    SET NEW.fecha_hora = NOW();
END$$

CREATE TRIGGER trg_bitacora_no_update
BEFORE UPDATE ON bitacora_auditoria
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable: no se permite UPDATE';
END$$

CREATE TRIGGER trg_bitacora_no_delete
BEFORE DELETE ON bitacora_auditoria
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La bitacora de auditoria es inmutable: no se permite DELETE';
END$$

-- El historial de bloqueos tambien es un registro historico: se protege igual
CREATE TRIGGER trg_historial_no_update
BEFORE UPDATE ON historial_estado_persona
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El historial de estados es inmutable: no se permite UPDATE';
END$$

CREATE TRIGGER trg_historial_no_delete
BEFORE DELETE ON historial_estado_persona
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El historial de estados es inmutable: no se permite DELETE';
END$$

DELIMITER ;
