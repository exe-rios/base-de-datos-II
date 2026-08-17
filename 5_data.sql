-- Inserción de datos (10 filas en maestras, 100 en telemetría).

-- 1. Insertar 10 Camiones
INSERT INTO camion (patente, marca, modelo, capacidad_tanque, estado_actual) VALUES 
('AB123CD', 'Scania', 'R500', 900.00, 'En Ruta'),
('EF456GH', 'Volvo', 'FH460', 850.00, 'En Ruta'),
('IJ789KL', 'Mercedes', 'Actros', 1000.00, 'En Ruta'),
('MN012OP', 'Iveco', 'Stralis', 800.00, 'Disponible'),
('QR345ST', 'Scania', 'G410', 900.00, 'En Ruta'),
('UV678WX', 'Ford', 'Cargo', 600.00, 'Service'),
('YZ901AB', 'Volvo', 'FM380', 800.00, 'En Ruta'),
('CD234EF', 'Mercedes', 'Atego', 500.00, 'Disponible'),
('GH567IJ', 'Scania', 'R450', 950.00, 'En Ruta'),
('KL890MN', 'Iveco', 'Tector', 450.00, 'En Ruta');

-- 2. Insertar 10 Choferes
INSERT INTO chofer (nombre, apellido, dni, licencia) VALUES 
('Juan', 'Perez', '11111111', 'L-001'), ('Pedro', 'Gomez', '22222222', 'L-002'),
('Luis', 'Ramirez', '33333333', 'L-003'), ('Carlos', 'Lopez', '44444444', 'L-004'),
('Miguel', 'Diaz', '55555555', 'L-005'), ('Jorge', 'Fernandez', '66666666', 'L-006'),
('Roberto', 'Ruiz', '77777777', 'L-007'), ('Raul', 'Alvarez', '88888888', 'L-008'),
('Mario', 'Romero', '99999999', 'L-009'), ('Diego', 'Torres', '10101010', 'L-010');

-- 3. Insertar 10 Zonas Logísticas (Incluyendo Restringidas para probar el Geofencing)
INSERT INTO zona_logistica (nombre_zona, tipo_zona, perimetro) VALUES 
('Depósito Norte', 'Almacenamiento', ST_MakeEnvelope(-60.7, -31.6, -60.6, -31.5, 4326)),
('Centro Histórico Peatonal', 'Restringida', ST_MakeEnvelope(-61.0, -32.0, -60.0, -31.0, 4326)), -- Zona amplia para hacer caer a los camiones
('Planta Sur', 'Punto de Entrega', ST_MakeEnvelope(-60.8, -31.8, -60.7, -31.7, 4326)),
('Zona Descarga B', 'Punto de Entrega', ST_MakeEnvelope(-60.5, -31.5, -60.4, -31.4, 4326)),
('Reserva Ecológica', 'Restringida', ST_MakeEnvelope(-60.3, -31.3, -60.2, -31.2, 4326)),
('Depósito Este', 'Almacenamiento', ST_MakeEnvelope(-60.9, -31.9, -60.8, -31.8, 4326)),
('Puerto', 'Carga', ST_MakeEnvelope(-60.1, -31.1, -60.0, -31.0, 4326)),
('Aduana', 'Control', ST_MakeEnvelope(-60.2, -31.2, -60.1, -31.1, 4326)),
('Ruta Peligrosa', 'Restringida', ST_MakeEnvelope(-60.6, -31.6, -60.5, -31.5, 4326)),
('Estación Servicio', 'Parada', ST_MakeEnvelope(-60.4, -31.4, -60.3, -31.3, 4326));

-- 4. Insertar 10 Viajes
INSERT INTO viaje (id_camion, id_chofer, estado_viaje, origen_destino_json) VALUES 
(1, 1, 'Activo', '{"origen": "Santa Fe", "destino": "Rosario"}'),
(2, 2, 'Activo', '{"origen": "Cordoba", "destino": "Buenos Aires"}'),
(3, 3, 'Activo', '{"origen": "Mendoza", "destino": "San Luis"}'),
(4, 4, 'Finalizado', '{"origen": "Rosario", "destino": "Parana"}'),
(5, 5, 'Activo', '{"origen": "Salta", "destino": "Tucuman"}'),
(7, 7, 'Activo', '{"origen": "Neuquen", "destino": "Bariloche"}'),
(8, 8, 'Finalizado', '{"origen": "Santa Rosa", "destino": "Bahia Blanca"}'),
(9, 9, 'Activo', '{"origen": "Corrientes", "destino": "Posadas"}'),
(10, 10, 'Activo', '{"origen": "Formosa", "destino": "Resistencia"}'),
(1, 2, 'Cancelado', '{"origen": "Rosario", "destino": "Santa Fe"}');

-- 5. Insertar 100 Registros de Telemetría (10 viajes * 10 puntos c/u)
-- Usamos CROSS JOIN con generate_series para generar exactamente 100 puntos espaciales progresivos
INSERT INTO telemetria (id_viaje, timestamp, coordenadas, velocidad, nivel_combustible, datos_sensor)
SELECT 
    v.id_viaje,
    CURRENT_TIMESTAMP - ((100 - (v.id_viaje * 10 + i)) || ' minutes')::interval,
    -- Generamos un punto que se va moviendo levemente
    ST_SetSRID(ST_MakePoint(-60.70 - (v.id_viaje * 0.01) + (i * 0.005), -31.65 + (i * 0.002)), 4326),
    80.00 + (i * 1.5), -- Velocidad fluctuando
    900.00 - (i * 2.5), -- Combustible bajando normal
    -- JSON de sensores intercalando camiones vacíos y cargados
    CASE 
        WHEN v.id_viaje % 2 = 0 THEN '{"peso_carga_kg": 0, "temp_termografo_c": 4, "presion_aceite_psi": 40}'::jsonb
        ELSE '{"peso_carga_kg": 25000, "temp_termografo_c": -18, "presion_aceite_psi": 45}'::jsonb
    END
FROM viaje v
CROSS JOIN generate_series(1, 10) AS i
WHERE v.id_viaje <= 10;

-- PREPARACIÓN DE CASOS DE PRUEBA (ANOMALÍAS PARA LAS VISTAS)

-- Forzar "Caída brusca de combustible" en el Viaje 1 para el Reporte 2
UPDATE telemetria 
SET nivel_combustible = nivel_combustible - 150 
WHERE id_viaje = 1 
  AND timestamp = (SELECT timestamp FROM telemetria WHERE id_viaje = 1 ORDER BY timestamp DESC LIMIT 1 OFFSET 3);

-- Forzar "Temperatura Crítica en Termógrafo" en el Viaje 3 para el Reporte 5
UPDATE telemetria 
SET datos_sensor = '{"peso_carga_kg": 15000, "temp_termografo_c": 12, "presion_aceite_psi": 35}'::jsonb 
WHERE id_viaje = 3;

-- 1. Plan de ejecución Reporte 1 (Ruta Histórica)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_ruta_historica;

-- 2. Plan de ejecución Reporte 2 (Anomalías de Combustible)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_anomalias_combustible;

-- 3. Plan de ejecución Reporte 3 (Productividad y KM)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_productividad_km;

-- 4. Plan de ejecución Reporte 4 (Geofencing / Control de Zona)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_geofencing_alertas;

-- 5. Plan de ejecución Reporte 5 (Sensores IoT)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_estado_sensores;