
-- 1. Reporte de Ruta Histórica Dinámica
-- Objetivo: Reconstruir el trayecto encadenando puntos cronológicamente.
CREATE OR REPLACE VIEW vw_ruta_historica AS
SELECT 
    id_viaje,
    ROW_NUMBER() OVER (PARTITION BY id_viaje ORDER BY timestamp) AS orden_secuencia,
    timestamp,
    ST_AsText(coordenadas) AS coordenadas_txt,
    velocidad,
    -- Calcula la distancia en metros con el punto anterior y lo pasa a KM (Casteado a NUMERIC)
    COALESCE((ST_DistanceSphere(coordenadas, LAG(coordenadas) OVER (PARTITION BY id_viaje ORDER BY timestamp)) / 1000.0)::NUMERIC, 0) AS distancia_km_tramo
FROM telemetria;


-- 2. Reporte de Detección de Anomalías de Combustible
-- Objetivo: Identificar caídas > 10% en menos de 5 minutos (posible robo o pérdida).
CREATE OR REPLACE VIEW vw_anomalias_combustible AS
WITH lecturas AS (
    SELECT 
        c.patente,
        t.timestamp AS fecha_y_hora,
        t.nivel_combustible AS nivel_actual,
        LAG(t.nivel_combustible) OVER (PARTITION BY c.id_camion ORDER BY t.timestamp) AS nivel_anterior,
        LAG(t.timestamp) OVER (PARTITION BY c.id_camion ORDER BY t.timestamp) AS tiempo_anterior
    FROM telemetria t
    JOIN viaje v ON t.id_viaje = v.id_viaje
    JOIN camion c ON v.id_camion = c.id_camion
)
SELECT 
    patente,
    fecha_y_hora,
    nivel_actual,
    nivel_anterior,
    (nivel_anterior - nivel_actual) AS diferencia_litros
FROM lecturas
WHERE nivel_anterior IS NOT NULL 
  AND (nivel_anterior - nivel_actual) > (nivel_anterior * 0.10) 
  AND EXTRACT(EPOCH FROM (fecha_y_hora - tiempo_anterior))/60 <= 5; 


-- 3. Reporte de Productividad y Kilometraje
-- Objetivo: KM con carga vs KM vacío basado en el sensor JSONB.
CREATE OR REPLACE VIEW vw_productividad_km AS
WITH tramos AS (
    SELECT 
        v.id_camion,
        COALESCE((ST_DistanceSphere(t.coordenadas, LAG(t.coordenadas) OVER(PARTITION BY t.id_viaje ORDER BY t.timestamp)) / 1000.0)::NUMERIC, 0) AS dist_tramo,
        COALESCE((t.datos_sensor->>'peso_carga_kg')::NUMERIC, 0) AS peso
    FROM telemetria t
    JOIN viaje v ON t.id_viaje = v.id_viaje
)
SELECT 
    id_camion,
    ROUND(SUM(dist_tramo), 2) AS total_km,
    ROUND(SUM(CASE WHEN peso > 0 THEN dist_tramo ELSE 0 END), 2) AS km_cargado,
    ROUND(SUM(CASE WHEN peso = 0 THEN dist_tramo ELSE 0 END), 2) AS km_vacio,
    CASE 
        WHEN SUM(dist_tramo) > 0 THEN ROUND((SUM(CASE WHEN peso > 0 THEN dist_tramo ELSE 0 END) / SUM(dist_tramo)) * 100, 2) 
        ELSE 0 
    END AS porcentaje_eficiencia
FROM tramos
GROUP BY id_camion;


-- 4. Reporte de Geofencing (Control de Zona)
-- Objetivo: Detectar ingresos a zonas restringidas con la última posición.
CREATE OR REPLACE VIEW vw_geofencing_alertas AS
WITH ultima_posicion AS (
    SELECT DISTINCT ON (v.id_viaje)
        c.patente,
        v.id_viaje,
        t.timestamp AS fecha_hora,
        t.coordenadas AS ultima_posicion
    FROM viaje v
    JOIN camion c ON v.id_camion = c.id_camion
    JOIN telemetria t ON v.id_viaje = t.id_viaje
    WHERE v.estado_viaje = 'Activo'
    ORDER BY v.id_viaje, t.timestamp DESC
)
SELECT 
    up.patente,
    up.id_viaje,
    z.nombre_zona AS nombre_zona_violada,
    up.fecha_hora,
    ST_AsText(up.ultima_posicion) AS ultima_posicion
FROM ultima_posicion up
JOIN zona_logistica z ON z.tipo_zona = 'Restringida' 
AND ST_Within(up.ultima_posicion, z.perimetro);


-- 5. Reporte de Estado de Sensores IoT
-- Objetivo: Monitorear variables críticas desde el JSONB.
CREATE OR REPLACE VIEW vw_estado_sensores AS
SELECT 
    v.id_camion,
    t.timestamp,
    'Temperatura Termografo (C)' AS sensor_nombre,
    (t.datos_sensor->>'temp_termografo_c')::NUMERIC AS valor_sensor
FROM telemetria t
JOIN viaje v ON t.id_viaje = v.id_viaje
WHERE t.datos_sensor ? 'temp_termografo_c'
UNION ALL
SELECT 
    v.id_camion,
    t.timestamp,
    'Presión Aceite (PSI)' AS sensor_nombre,
    (t.datos_sensor->>'presion_aceite_psi')::NUMERIC AS valor_sensor
FROM telemetria t
JOIN viaje v ON t.id_viaje = v.id_viaje
WHERE t.datos_sensor ? 'presion_aceite_psi';