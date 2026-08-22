-- inserts 

-- Alta de una nueva unidad en la flota
INSERT INTO camion (patente, marca, modelo, capacidad_tanque, estado_actual, odometro_total)
VALUES ('AF123YZ', 'Scania', 'R500', 900.00, 'Disponible', 12500.50);

-- Alta de un nuevo conductor
INSERT INTO chofer (nombre, apellido, dni, licencia)
VALUES ('Roberto', 'Gomez', '32111222', 'LINTI-9988');

-- Asignación de teléfonos de contacto al chofer
INSERT INTO telefono_chofer (tel_fijo, tel_movil, id_chofer)
VALUES ('03496420000', '349615555555', 1);

-- Registro de un polígono de zona logística (Depósito / Geocerca)
INSERT INTO zona_logistica (nombre_zona, tipo_zona, perimetro)
VALUES ('Depósito Central Santa Fe', 'Almacenamiento', ST_GeomFromText('POLYGON((-60.72 -31.65, -60.70 -31.65, -60.70 -31.63, -60.72 -31.63, -60.72 -31.65))', 4326));

-- Creación de un nuevo viaje operativo con origen/destino en JSONB
INSERT INTO viaje (id_camion, id_chofer, origen_destino, estado_viaje)
VALUES (1, 1, '{"origen": "Santa Fe", "destino": "Rosario", "distancia_estimada_km": 160}', 'Activo');

-- Asignación de parada/zona dentro de la hoja de ruta del viaje
INSERT INTO hoja_de_ruta  (id_viaje, id_zona, orden)
VALUES (1, 1, 1);

-- Registro de lectura de telemetría (GPS, velocidad, combustible y sensores IoT)
INSERT INTO telemetria (id_viaje, coordenadas, velocidad, nivel_combustible, datos_sensor)
VALUES (1, ST_SetSRID(ST_MakePoint(-60.7050, -31.6420), 4326), 78.50, 840.00, '{"peso_carga_kg": 18500, "temp_termografo_c": 4.2, "presion_aceite_psi": 45}');

-- update idempotentes

-- Actualizar estado operativo del camión a 'En Ruta'
UPDATE camion
SET estado_actual = 'En Ruta'
WHERE id_camion = 1 AND estado_actual <> 'En Ruta';

-- Actualizar odómetro acumulado del camión a un valor fijo verificado
UPDATE camion
SET odometro_total = 12660.50
WHERE id_camion = 1 AND odometro_total < 12660.50;

-- Actualizar número de licencia por renovación formal del chofer
UPDATE chofer
SET licencia = 'LINTI-RENOV-2026'
WHERE id_chofer = 1 AND licencia <> 'LINTI-RENOV-2026';

-- Actualizar teléfono móvil de guardia del chofer
UPDATE telefono_chofer
SET tel_movil = '349615444333'
WHERE tel_fijo = '03496420000' AND tel_movil <> '349615444333';

-- Modificar el estado/tipo de una zona logística por obras o mantenimiento
UPDATE zona_logistica
SET tipo_zona = 'Mantenimiento'
WHERE id_zona = 1 AND tipo_zona <> 'Mantenimiento';

-- Actualizar la carga útil en JSONB del viaje ante un cambio de destino planificado
UPDATE viaje
SET origen_destino = '{"origen": "Santa Fe", "destino": "San Lorenzo", "distancia_estimada_km": 135}'
WHERE id_viaje = 1 AND (origen_destino->>'destino') <> 'San Lorenzo';

-- Finalizar viaje y fijar fecha/hora de cierre
UPDATE viaje
SET estado_viaje = 'Finalizado', fecha_fin = '2026-08-17 18:00:00'
WHERE id_viaje = 1 AND estado_viaje <> 'Finalizado';

-- Deletes (6 Operaciones de Baja y Depuración)

-- Descartar alertas e incidencias clasificadas como 'Falsa Alarma'
DELETE FROM incidencias
WHERE tipo_alerta = 'Falsa Alarma';

-- Depurar lecturas de telemetría anómalas o corruptas (velocidad fuera de rango físico)
DELETE FROM telemetria
WHERE velocidad < 0.00 OR velocidad > 200.00;

-- Quitar una zona o parada de la hoja de ruta de un viaje cancelado
DELETE FROM hoja_de_ruta
WHERE id_viaje = 1 AND id_zona = 1;

-- Eliminar un número de teléfono fijo obsoleto o fuera de servicio
DELETE FROM telefono_chofer
WHERE tel_fijo = '03496420000';

-- Dar de baja zonas logísticas temporales o marcadas como obsoletas
DELETE FROM zona_logistica
WHERE tipo_zona = 'Obsoleta' OR nombre_zona = 'Zona Temporal';

-- Dar de baja registros de camiones dados de baja definitiva que no posean viajes
DELETE FROM camion
WHERE estado_actual = 'Baja Definitiva';