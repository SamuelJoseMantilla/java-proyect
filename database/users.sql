-- =====================================================================
--  SICA - Sistema Integrado de Control de Acceso (Zona Acme)
--  users.sql : usuario de MySQL para la aplicacion Java (PLANTILLA)
--  Ejecutar como root DESPUES de schema.sql y data.sql
--
--  ¡ESTE ARCHIVO ES UNA PLANTILLA! No contiene la contrasena real.
--    1. Copielo como  database/users.local.sql  (Git lo ignora)
--    2. Cambie CAMBIAR_ESTA_CLAVE por una contrasena segura
--    3. Ejecute users.local.sql
--    4. Ponga la misma contrasena en src/main/resources/config.properties
--
--  Principio del menor privilegio: la aplicacion NO se conecta como root.
--  sica_app solo puede hacer lo que el sistema necesita:
--    - Tablas de negocio : SELECT, INSERT, UPDATE (no se borra: se desactiva)
--    - rol_permisos      : ademas DELETE (quitar un permiso a un rol)
--    - Bitacora/historial: solo SELECT e INSERT (inmutables)
--    - Procedimientos    : EXECUTE
--    - Sin DROP, TRUNCATE, ALTER ni CREATE
-- =====================================================================

-- '%' = puede conectarse desde cualquier host (Java corre fuera del contenedor)
DROP USER IF EXISTS 'sica_app'@'%';
CREATE USER 'sica_app'@'%' IDENTIFIED BY 'CAMBIAR_ESTA_CLAVE';


-- ---------- Catalogos y RBAC ----------
GRANT SELECT, INSERT, UPDATE         ON sica_db.roles                  TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.permisos               TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON sica_db.rol_permisos           TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.tipos_persona          TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.persona_estados_acceso TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.visita_estados         TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.tipos_ingreso          TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.motivos_visita         TO 'sica_app'@'%';

-- ---------- Empresas, usuarios y personas ----------
GRANT SELECT, INSERT, UPDATE         ON sica_db.empresas               TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.usuarios               TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.funcionarios           TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.personas               TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.trabajadores           TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.invitados              TO 'sica_app'@'%';

-- ---------- Operacion ----------
GRANT SELECT, INSERT, UPDATE         ON sica_db.visitas                TO 'sica_app'@'%';
GRANT SELECT, INSERT, UPDATE         ON sica_db.incidentes             TO 'sica_app'@'%';

-- ---------- Registros inmutables: solo leer y agregar ----------
GRANT SELECT, INSERT                 ON sica_db.historial_estado_persona TO 'sica_app'@'%';
GRANT SELECT, INSERT                 ON sica_db.bitacora_auditoria       TO 'sica_app'@'%';

-- ---------- Procedimientos almacenados ----------
GRANT EXECUTE ON PROCEDURE sica_db.sp_crear_trabajador  TO 'sica_app'@'%';
GRANT EXECUTE ON PROCEDURE sica_db.sp_crear_invitado    TO 'sica_app'@'%';
GRANT EXECUTE ON PROCEDURE sica_db.sp_crear_funcionario TO 'sica_app'@'%';
GRANT EXECUTE ON PROCEDURE sica_db.sp_registrar_ingreso TO 'sica_app'@'%';

FLUSH PRIVILEGES;
