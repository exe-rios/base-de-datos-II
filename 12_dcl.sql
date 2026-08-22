-- Primero borramos los usuarios, grupos y roles por la dudas si ya existen 
DROP ROLE IF EXISTS usr_admin1, usr_admin2;
DROP ROLE IF EXISTS usr_operador_juan, usr_operador_maria, usr_operador_lucas;
DROP ROLE IF EXISTS usr_chofer_pedro, usr_chofer_luis, usr_chofer_carlos;
DROP ROLE IF EXISTS usr_auditor_ext;
DROP ROLE IF EXISTS usr_mecanico_jefe;
DROP ROLE IF EXISTS rol_administrador;
DROP ROLE IF EXISTS rol_operador;
DROP ROLE IF EXISTS rol_chofer;
DROP ROLE IF EXISTS rol_auditor;
DROP ROLE IF EXISTS rol_mantenimiento;

-- creamos 5 roles en el sistema
CREATE ROLE rol_administrador;
CREATE ROLE rol_operador;
CREATE ROLE rol_chofer;
CREATE ROLE rol_auditor;
CREATE ROLE rol_mantenimiento;

-- asignamos perimos limitados a cada rol
-- administrador: Tiene control total sobre todas las tablas y secuencias.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_administrador;

-- operador (Despachante): Gestiona la logística diaria. 
-- Puede leer, insertar y modificar viajes, camiones y hojas de ruta, pero NO borrar.
GRANT SELECT, INSERT, UPDATE ON camion, chofer, telefono_chofer, viaje, hoja_de_ruta, zona_logistica, incidencias TO rol_operador;
-- Necesita uso de secuencias para los INSERTs (Identity columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_operador;

-- Chofer: Acceso hiper limitado. Solo puede ver (SELECT) información de viajes y rutas.
GRANT SELECT ON viaje, hoja_de_ruta, zona_logistica TO rol_chofer;

-- Auditor / Gerente: Solo lectura. Puede ver todas las tablas y vistas, pero no puede tocar ni un dato.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;

-- Mantenimiento (Mecánicos): Ven los camiones y las alertas, y solo pueden modificar el estado del camión.
GRANT SELECT ON camion, incidencias TO rol_mantenimiento;
GRANT UPDATE (estado_actual, odometro_total) ON camion TO rol_mantenimiento;
GRANT UPDATE (descripcion) ON incidencias TO rol_mantenimiento;

-- 3. creamos 10 usuarios (Con contraseñas faciles para el TP)

-- Usuarios de Administración
CREATE USER usr_admin1 WITH PASSWORD 'LogiTrackAdmin2025';
CREATE USER usr_admin2 WITH PASSWORD 'LogiTrackAdmin2026';

-- Usuarios Operadores / Despachantes
CREATE USER usr_operador_juan WITH PASSWORD 'Operador122';
CREATE USER usr_operador_maria WITH PASSWORD 'Operador123';
CREATE USER usr_operador_lucas WITH PASSWORD 'Operador124';

-- Usuarios Choferes
CREATE USER usr_chofer_pedro WITH PASSWORD 'Ruta455';
CREATE USER usr_chofer_luis WITH PASSWORD 'Ruta456';
CREATE USER usr_chofer_carlos WITH PASSWORD 'Ruta457';

-- Usuario Auditor
CREATE USER usr_auditor_ext WITH PASSWORD 'Auditoria789';

-- Usuario Mantenimiento
CREATE USER usr_mecanico_jefe WITH PASSWORD 'Taller123';

-- 4. asignamos usuarios a sus roles
GRANT rol_administrador TO usr_admin1, usr_admin2;
GRANT rol_operador TO usr_operador_juan, usr_operador_maria, usr_operador_lucas;
GRANT rol_chofer TO usr_chofer_pedro, usr_chofer_luis, usr_chofer_carlos;
GRANT rol_auditor TO usr_auditor_ext;
GRANT rol_mantenimiento TO usr_mecanico_jefe;