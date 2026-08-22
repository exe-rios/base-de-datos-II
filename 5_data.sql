-- inserción masiva de datos.

-- insertar 10 Camiones
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

-- insertar 10 Choferes
INSERT INTO chofer (nombre, apellido, dni, licencia) VALUES 
('Juan', 'Perez', '11111111', 'L-001'), ('Pedro', 'Gomez', '22222222', 'L-002'),
('Luis', 'Ramirez', '33333333', 'L-003'), ('Carlos', 'Lopez', '44444444', 'L-004'),
('Miguel', 'Diaz', '55555555', 'L-005'), ('Jorge', 'Fernandez', '66666666', 'L-006'),
('Roberto', 'Ruiz', '77777777', 'L-007'), ('Raul', 'Alvarez', '88888888', 'L-008'),
('Mario', 'Romero', '99999999', 'L-009'), ('Diego', 'Torres', '10101010', 'L-010');

-- insertar 10 Teléfonos de Choferes
INSERT INTO telefono_chofer (tel_fijo, tel_movil, id_chofer) VALUES 
('03424000001', '34215500001', 1), ('03424000002', '34215500002', 2),
('03424000003', '34215500003', 3), ('03424000004', '34215500004', 4),
('03424000005', '34215500005', 5), ('03424000006', '34215500006', 6),
('03424000007', '34215500007', 7), ('03424000008', '34215500008', 8),
('03424000009', '34215500009', 9), ('03424000010', '34215500010', 10);

-- insertar 10 Zonas Logísticas (Incluyendo "Restringidas" para el Geofencing)
INSERT INTO zona_logistica (nombre_zona, tipo_zona, perimetro) VALUES 
('Depósito Norte', 'Almacenamiento', ST_MakeEnvelope(-60.7, -31.6, -60.6, -31.5, 4326)),
('Centro Histórico Peatonal', 'Restringida', ST_MakeEnvelope(-61.0, -32.0, -60.0, -31.0, 4326)), 
('Planta Sur', 'Punto de Entrega', ST_MakeEnvelope(-60.8, -31.8, -60.7, -31.7, 4326)),
('Zona Descarga B', 'Punto de Entrega', ST_MakeEnvelope(-60.5, -31.5, -60.4, -31.4, 4326)),
('Reserva Ecológica', 'Restringida', ST_MakeEnvelope(-60.3, -31.3, -60.2, -31.2, 4326)),
('Depósito Este', 'Almacenamiento', ST_MakeEnvelope(-60.9, -31.9, -60.8, -31.8, 4326)),
('Puerto', 'Carga', ST_MakeEnvelope(-60.1, -31.1, -60.0, -31.0, 4326)),
('Aduana', 'Control', ST_MakeEnvelope(-60.2, -31.2, -60.1, -31.1, 4326)),
('Ruta Peligrosa', 'Restringida', ST_MakeEnvelope(-60.6, -31.6, -60.5, -31.5, 4326)),
('Estación Servicio', 'Parada', ST_MakeEnvelope(-60.4, -31.4, -60.3, -31.3, 4326));

-- insertar 10 Viajes
INSERT INTO viaje (id_camion, id_chofer, estado_viaje, origen_destino) VALUES 
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

--insertar 10 paradas en la Hoja de Ruta
INSERT INTO hoja_de_ruta (id_viaje, id_zona, orden) VALUES 
(1, 1, 1), (1, 3, 2), (2, 4, 1), (3, 6, 1), 
(4, 7, 1), (5, 8, 1), (7, 10, 1), (8, 1, 1), 
(9, 3, 1), (10, 4, 1);

-- insertar 100 Registros de Telemetría (10 viajes * 10 puntos c/u)
INSERT INTO telemetria (id_viaje, timestamp, coordenadas, velocidad, nivel_combustible, datos_sensor)
SELECT 
    v.id_viaje,
    CURRENT_TIMESTAMP - ((100 - (v.id_viaje * 10 + i)) || ' minutes')::interval,
    ST_SetSRID(ST_MakePoint(-60.70 - (v.id_viaje * 0.01) + (i * 0.005), -31.65 + (i * 0.002)), 4326),
    80.00 + (i * 1.5), 
    900.00 - (i * 2.5), 
    CASE 
        WHEN v.id_viaje % 2 = 0 THEN '{"peso_carga_kg": 0, "temp_termografo_c": 4, "presion_aceite_psi": 40}'::jsonb
        ELSE '{"peso_carga_kg": 25000, "temp_termografo_c": -18, "presion_aceite_psi": 45}'::jsonb
    END
FROM viaje v
CROSS JOIN generate_series(1, 10) AS i
WHERE v.id_viaje <= 10;

-- insertar 10 Incidencias.
INSERT INTO incidencias (id_viaje, id_telemetria, tipo_alerta, descripcion) VALUES 
(1, 15, 'Exceso de Velocidad', 'El camión superó los 90 km/h en zona urbana.'),
(2, 22, 'Falla Mecánica', 'Alerta de alta temperatura en el motor.'),
(3, 31, 'Desvío de Ruta', 'El camión abandonó el corredor seguro.'),
(4, NULL, 'Parada no autorizada', 'Detención de más de 30 minutos sin justificación.'),
(5, 55, 'Pérdida de Señal', 'Se perdió conexión GPS por más de 10 minutos.'),
(6, NULL, 'Exceso de Velocidad', 'Velocidad registrada de 105 km/h en autopista.'),
(7, 72, 'Botón de Pánico', 'Activación manual por parte del chofer.'),
(8, NULL, 'Falla de Sensor', 'Falla en lectura del termógrafo de carga.'),
(9, 90, 'Caída de Combustible', 'Posible robo o pérdida masiva en el tanque.'),
(10, 95, 'Ingreso a Zona Restringida', 'El camión entró a una zona prohibida.');


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

-- Plan de ejecución Reporte 1 (Ruta Histórica)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_ruta_historica;

-- Plan de ejecución Reporte 2 (Anomalías de Combustible)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_anomalias_combustible;

-- Plan de ejecución Reporte 3 (Productividad y KM)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_productividad_km;

-- Plan de ejecución Reporte 4 (Geofencing / Control de Zona)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_geofencing_alertas;

-- Plan de ejecución Reporte 5 (Sensores IoT)
EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT * FROM vw_estado_sensores;