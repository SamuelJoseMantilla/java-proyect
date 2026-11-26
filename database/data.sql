-- =====================================================================
--  SICA - Sistema Integrado de Control de Acceso (Zona Acme)
--  data.sql : datos iniciales y de prueba
--  Ejecutar DESPUES de schema.sql
-- =====================================================================

USE sica_db;


-- =====================================================================
--  1. CATALOGOS
--  ¡OJO! Los procedimientos buscan estos nombres exactos.
-- =====================================================================

INSERT INTO tipos_persona (nombre, descripcion) VALUES
    ('Trabajador', 'Empleado de una empresa del complejo'),
    ('Invitado',   'Persona externa que visita el complejo');

INSERT INTO persona_estados_acceso (nombre_estado, descripcion) VALUES
    ('Activo',                     'Puede ingresar al complejo'),
    ('Con Prohibicion de Ingreso', 'Bloqueada: se le niega el acceso en todos los puntos de entrada');

INSERT INTO visita_estados (nombre_estado, descripcion) VALUES
    ('Pendiente de Aprobacion',               'Invitado no anunciado esperando respuesta del funcionario'),
    ('Pendiente por Olvido',                  'Trabajador sin carnet esperando aprobacion de un pase temporal'),
    ('Aprobado',                              'Autorizado para ingresar, aun sin check-in'),
    ('Rechazado',                             'El funcionario nego el ingreso'),
    ('Dentro',                                'La persona esta dentro del complejo'),
    ('Fuera',                                 'Visita finalizada con check-out'),
    ('Expirado',                              'Visita pre-registrada o solicitud que no se uso a tiempo'),
    ('Cerrada por Sistema (Salida Olvidada)', 'Cerrada automaticamente porque la persona no registro su salida');

INSERT INTO tipos_ingreso (nombre, descripcion) VALUES
    ('Ingreso regular',  'Trabajador que ingresa con su carnet'),
    ('Pre-registrado',   'Visita registrada con anticipacion por un funcionario'),
    ('No anunciado',     'Invitado que llega sin registro previo'),
    ('Olvido de carnet', 'Trabajador que llega sin documento: pase temporal del dia');

INSERT INTO motivos_visita (nombre, descripcion) VALUES
    ('Reunion',               'Reunion de trabajo con un funcionario'),
    ('Entrevista de trabajo', 'Candidato a un proceso de seleccion'),
    ('Proveedor / Entrega',   'Entrega de mercancia, documentos o paquetes'),
    ('Mantenimiento tecnico', 'Reparaciones, soporte tecnico o instalaciones'),
    ('Capacitacion',          'Formacion, taller o charla'),
    ('Personal',              'Visita de caracter personal'),
    ('Otro',                  'Especificar en el detalle del motivo');


-- =====================================================================
--  2. RBAC: ROLES, PERMISOS Y ASIGNACION
-- =====================================================================

INSERT INTO roles (nombre_rol, descripcion) VALUES
    ('Superusuario',            'Administra todo el sistema'),
    ('Supervisor de Seguridad', 'Gestiona personas, incidentes, bloqueos y reportes'),
    ('Guarda de Seguridad',     'Controla los ingresos y salidas en porteria'),
    ('Funcionario de Empresa',  'Pre-registra invitados y aprueba ingresos de su empresa');

INSERT INTO permisos (nombre_permiso, descripcion) VALUES
    ('gestionar_usuarios',             'Crear, editar y desactivar usuarios'),
    ('gestionar_roles_permisos',       'Asignar o quitar permisos a los roles'),
    ('gestionar_empresas',             'Crear, editar y desactivar empresas'),
    ('gestionar_personas',             'Crear, editar y desactivar trabajadores e invitados'),
    ('buscar_persona',                 'Buscar personas por documento o nombre'),
    ('registrar_checkin',              'Registrar el ingreso de una persona'),
    ('registrar_checkout',             'Registrar la salida de una persona'),
    ('registrar_ingreso_no_anunciado', 'Registrar un invitado que llega sin registro previo'),
    ('registrar_pase_temporal',        'Registrar a un trabajador que olvido su carnet'),
    ('preregistrar_visita',            'Registrar con anticipacion la visita de un invitado'),
    ('aprobar_visita',                 'Aprobar o rechazar ingresos pendientes'),
    ('registrar_incidente',            'Registrar un incidente de seguridad'),
    ('bloquear_persona',               'Cambiar el estado de acceso de una persona'),
    ('ver_reportes',                   'Consultar reportes (quien esta dentro, visitas, incidentes)'),
    ('ver_auditoria',                  'Consultar la bitacora de auditoria');

-- Se asignan por NOMBRE (no por id) para que el script sea facil de leer

-- Superusuario: todos los permisos
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT r.id, p.id
  FROM roles r CROSS JOIN permisos p
 WHERE r.nombre_rol = 'Superusuario';

-- Supervisor de Seguridad
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT r.id, p.id
  FROM roles r JOIN permisos p
    ON p.nombre_permiso IN ('gestionar_personas', 'buscar_persona', 'registrar_incidente',
                            'bloquear_persona', 'ver_reportes', 'ver_auditoria')
 WHERE r.nombre_rol = 'Supervisor de Seguridad';

-- Guarda de Seguridad
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT r.id, p.id
  FROM roles r JOIN permisos p
    ON p.nombre_permiso IN ('buscar_persona', 'registrar_checkin', 'registrar_checkout',
                            'registrar_ingreso_no_anunciado', 'registrar_pase_temporal')
 WHERE r.nombre_rol = 'Guarda de Seguridad';

-- Funcionario de Empresa
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT r.id, p.id
  FROM roles r JOIN permisos p
    ON p.nombre_permiso IN ('buscar_persona', 'preregistrar_visita', 'aprobar_visita')
 WHERE r.nombre_rol = 'Funcionario de Empresa';


-- =====================================================================
--  3. EMPRESAS
-- =====================================================================

INSERT INTO empresas (nombre, contacto_principal, telefono, ubicacion) VALUES
    ('TechSoft S.A.S.',         'Laura Gomez',    '6015550101', 'Torre A - Piso 3'),
    ('Andina Logistica',        'Jorge Ramirez',  '6015550102', 'Torre A - Piso 5'),
    ('BioSalud Laboratorios',   'Marcela Rios',   '6015550103', 'Torre B - Piso 2'),
    ('Consultores Acme',        'Felipe Herrera', '6015550104', 'Torre B - Piso 7'),
    ('Innova Energia',          'Paula Castro',   '6015550105', 'Torre C - Piso 1');

SET @emp_techsoft = (SELECT id FROM empresas WHERE nombre = 'TechSoft S.A.S.');
SET @emp_andina   = (SELECT id FROM empresas WHERE nombre = 'Andina Logistica');
SET @emp_biosalud = (SELECT id FROM empresas WHERE nombre = 'BioSalud Laboratorios');


-- =====================================================================
--  4. USUARIOS DE PRUEBA (uno o mas por rol)
--  Contrasena: hash = SHA-256( salt + contrasena ) en hexadecimal.
--  Java debe calcularlo EXACTAMENTE igual al validar el login.
--  Las credenciales de prueba se documentan en el README (Guia de Uso).
-- =====================================================================

-- Superusuario
SET @salt = SHA2(UUID(), 256);
INSERT INTO usuarios (nombre, email, password_hash, salt, rol_id)
VALUES ('Administrador SICA', 'admin@zonaacme.com', SHA2(CONCAT(@salt, 'Admin123*'), 256), @salt,
        (SELECT id FROM roles WHERE nombre_rol = 'Superusuario'));
SET @u_admin = LAST_INSERT_ID();

-- Supervisor de Seguridad
SET @salt = SHA2(UUID(), 256);
INSERT INTO usuarios (nombre, email, password_hash, salt, rol_id)
VALUES ('Sofia Mendoza', 'supervisor@zonaacme.com', SHA2(CONCAT(@salt, 'Super123*'), 256), @salt,
        (SELECT id FROM roles WHERE nombre_rol = 'Supervisor de Seguridad'));
SET @u_supervisor = LAST_INSERT_ID();

-- Guardas de Seguridad
SET @salt = SHA2(UUID(), 256);
INSERT INTO usuarios (nombre, email, password_hash, salt, rol_id)
VALUES ('Pedro Torres', 'guarda1@zonaacme.com', SHA2(CONCAT(@salt, 'Guarda123*'), 256), @salt,
        (SELECT id FROM roles WHERE nombre_rol = 'Guarda de Seguridad'));
SET @u_guarda1 = LAST_INSERT_ID();

SET @salt = SHA2(UUID(), 256);
INSERT INTO usuarios (nombre, email, password_hash, salt, rol_id)
VALUES ('Andres Rojas', 'guarda2@zonaacme.com', SHA2(CONCAT(@salt, 'Guarda123*'), 256), @salt,
        (SELECT id FROM roles WHERE nombre_rol = 'Guarda de Seguridad'));

-- Funcionarios de Empresa (con el procedimiento: usuario + funcionario en una transaccion)
SET @salt = SHA2(UUID(), 256);
SET @hash = SHA2(CONCAT(@salt, 'Func123*'), 256);
CALL sp_crear_funcionario('Laura Gomez', 'laura@techsoft.com', @hash, @salt,
                          @emp_techsoft, 'Gerente de Recursos Humanos', @u_laura);

SET @salt = SHA2(UUID(), 256);
SET @hash = SHA2(CONCAT(@salt, 'Func123*'), 256);
CALL sp_crear_funcionario('Jorge Ramirez', 'jorge@andina.com', @hash, @salt,
                          @emp_andina, 'Director de Operaciones', @u_jorge);

SET @salt = SHA2(UUID(), 256);
SET @hash = SHA2(CONCAT(@salt, 'Func123*'), 256);
CALL sp_crear_funcionario('Marcela Rios', 'marcela@biosalud.com', @hash, @salt,
                          @emp_biosalud, 'Jefe de Laboratorio', @u_marcela);


-- =====================================================================
--  5. PERSONAS (con procedimientos: persona + especializacion + historial)
-- =====================================================================

-- Trabajadores
CALL sp_crear_trabajador('Ana Martinez',    '1010101010', 'https://i.pravatar.cc/150?img=1',  '3001110001', @emp_techsoft, 'Desarrolladora',     @u_admin, @p_ana);
CALL sp_crear_trabajador('Luis Fernandez',  '1020202020', 'https://i.pravatar.cc/150?img=12', '3001110002', @emp_techsoft, 'Analista QA',        @u_admin, @p_luis);
CALL sp_crear_trabajador('Diana Lopez',     '1030303030', 'https://i.pravatar.cc/150?img=5',  '3001110003', @emp_andina,   'Coordinadora',       @u_admin, @p_diana);
CALL sp_crear_trabajador('Camilo Suarez',   '1040404040', 'https://i.pravatar.cc/150?img=15', '3001110004', @emp_biosalud, 'Quimico',            @u_admin, @p_camilo);

-- Invitados
CALL sp_crear_invitado('Carlos Perez',      '2010101010', 'https://i.pravatar.cc/150?img=8',  '3102220001', 'Coca-Cola FEMSA',    @u_admin, @p_carlos);
CALL sp_crear_invitado('Valentina Diaz',    '2020202020', 'https://i.pravatar.cc/150?img=9',  '3102220002', NULL,                 @u_admin, @p_valentina);
CALL sp_crear_invitado('Ricardo Mora',      '2030303030', 'https://i.pravatar.cc/150?img=11', '3102220003', 'Servientrega',       @u_admin, @p_ricardo);
CALL sp_crear_invitado('Mario Castillo',    '2040404040', 'https://i.pravatar.cc/150?img=13', '3102220004', NULL,                 @u_admin, @p_mario);

-- Persona bloqueada (cambio de estado + historial)
UPDATE personas
   SET estado_acceso_id = (SELECT id FROM persona_estados_acceso WHERE nombre_estado = 'Con Prohibicion de Ingreso')
 WHERE id = @p_mario;

INSERT INTO historial_estado_persona (persona_id, estado_anterior_id, estado_nuevo_id, motivo, usuario_id)
VALUES (@p_mario,
        (SELECT id FROM persona_estados_acceso WHERE nombre_estado = 'Activo'),
        (SELECT id FROM persona_estados_acceso WHERE nombre_estado = 'Con Prohibicion de Ingreso'),
        'Agresion verbal a personal de seguridad', @u_supervisor);


-- =====================================================================
--  6. VISITAS DE EJEMPLO (fechas relativas a HOY para que la demo
--     siempre funcione)
-- =====================================================================

SET @est_pendiente = (SELECT id FROM visita_estados WHERE nombre_estado = 'Pendiente de Aprobacion');
SET @est_aprobado  = (SELECT id FROM visita_estados WHERE nombre_estado = 'Aprobado');
SET @est_dentro    = (SELECT id FROM visita_estados WHERE nombre_estado = 'Dentro');
SET @est_fuera     = (SELECT id FROM visita_estados WHERE nombre_estado = 'Fuera');
SET @est_expirado  = (SELECT id FROM visita_estados WHERE nombre_estado = 'Expirado');

SET @ti_regular    = (SELECT id FROM tipos_ingreso WHERE nombre = 'Ingreso regular');
SET @ti_prereg     = (SELECT id FROM tipos_ingreso WHERE nombre = 'Pre-registrado');
SET @ti_noanun     = (SELECT id FROM tipos_ingreso WHERE nombre = 'No anunciado');

SET @mot_reunion   = (SELECT id FROM motivos_visita WHERE nombre = 'Reunion');
SET @mot_entrega   = (SELECT id FROM motivos_visita WHERE nombre = 'Proveedor / Entrega');
SET @mot_entrev    = (SELECT id FROM motivos_visita WHERE nombre = 'Entrevista de trabajo');

-- a) Flujo ideal: Carlos pre-registrado por Laura para HOY (listo para check-in)
INSERT INTO visitas (persona_id, anfitrion_id, tipo_ingreso_id, motivo_id, detalle_motivo,
                     fecha_programada, estado_visita_id, registrado_por)
VALUES (@p_carlos, @u_laura, @ti_prereg, @mot_reunion, 'Presentacion de propuesta comercial',
        CURDATE(), @est_aprobado, @u_laura);

-- b) Flujo en tiempo real: Ricardo llego sin anunciarse, esperando a Jorge
INSERT INTO visitas (persona_id, anfitrion_id, tipo_ingreso_id, motivo_id, detalle_motivo,
                     estado_visita_id, vehiculo_placa, registrado_por)
VALUES (@p_ricardo, @u_jorge, @ti_noanun, @mot_entrega, 'Entrega de 3 cajas de documentos',
        @est_pendiente, 'XYZ789', @u_guarda1);

-- c) Salida olvidada: Ana entro AYER y nunca registro su salida
INSERT INTO visitas (persona_id, tipo_ingreso_id, fecha_entrada, estado_visita_id,
                     registrado_por, checkin_por)
VALUES (@p_ana, @ti_regular, NOW() - INTERVAL 1 DAY, @est_dentro, @u_guarda1, @u_guarda1);

-- d) Personas dentro ahora mismo (reporte de evacuacion)
INSERT INTO visitas (persona_id, tipo_ingreso_id, fecha_entrada, estado_visita_id,
                     registrado_por, checkin_por)
VALUES (@p_diana,  @ti_regular, NOW() - INTERVAL 2 HOUR, @est_dentro, @u_guarda1, @u_guarda1),
       (@p_camilo, @ti_regular, NOW() - INTERVAL 1 HOUR, @est_dentro, @u_guarda1, @u_guarda1);

-- e) Visita finalizada ayer (historico para reportes) + incidente
INSERT INTO visitas (persona_id, anfitrion_id, tipo_ingreso_id, motivo_id, fecha_programada,
                     fecha_entrada, fecha_salida, estado_visita_id,
                     registrado_por, visita_aprobada_por, fecha_respuesta, checkin_por, checkout_por)
VALUES (@p_valentina, @u_marcela, @ti_prereg, @mot_entrev, CURDATE() - INTERVAL 1 DAY,
        NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY + INTERVAL 2 HOUR, @est_fuera,
        @u_marcela, @u_marcela, NOW() - INTERVAL 2 DAY, @u_guarda1, @u_guarda1);
SET @v_valentina = LAST_INSERT_ID();

INSERT INTO incidentes (visita_id, reportado_por_id, descripcion)
VALUES (@v_valentina, @u_supervisor, 'Intento ingresar a una zona restringida del laboratorio sin acompanamiento');

-- f) Visita pre-registrada que nunca se uso (expirada)
INSERT INTO visitas (persona_id, anfitrion_id, tipo_ingreso_id, motivo_id, fecha_programada,
                     estado_visita_id, registrado_por)
VALUES (@p_valentina, @u_laura, @ti_prereg, @mot_reunion, CURDATE() - INTERVAL 3 DAY,
        @est_expirado, @u_laura);
