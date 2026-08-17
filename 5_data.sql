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