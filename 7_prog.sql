-- Función para calcular la distancia entre dos puntos GPS

CREATE OR REPLACE FUNCTION calcular_distancia_gps(
    lon1 NUMERIC, lat1 NUMERIC, 
    lon2 NUMERIC, lat2 NUMERIC
) RETURNS NUMERIC AS $$
DECLARE
    punto1 GEOMETRY;
    punto2 GEOMETRY;
    distancia_km NUMERIC;
BEGIN
    -- Crear los puntos espaciales con el SRID 4326 (WGS 84)
    punto1 := ST_SetSRID(ST_MakePoint(lon1, lat1), 4326);
    punto2 := ST_SetSRID(ST_MakePoint(lon2, lat2), 4326);
    
    -- Calcular en metros usando función de PostGIS y convertir a KM
    distancia_km := (ST_DistanceSphere(punto1, punto2) / 1000.0)::NUMERIC;
    
    RETURN ROUND(distancia_km, 2);
END;
$$ LANGUAGE plpgsql;



-- Registro telemetría con captura de errores
-- Valida que el camión exista y tenga viaje activo.Si falla, captura la excepción y no detiene el motor de base de datos.

CREATE OR REPLACE PROCEDURE registrar_telemetria_segura(
    p_id_camion INT, 
    p_lon NUMERIC, 
    p_lat NUMERIC, 
    p_vel NUMERIC, 
    p_comb NUMERIC, 
    p_sensor JSONB
) AS $$
DECLARE
    v_viaje_activo INT;
    v_camion_existe BOOLEAN;
BEGIN
    -- Validar si el camión existe físicamente en la flota
    SELECT EXISTS(SELECT 1 FROM camion WHERE id_camion = p_id_camion) INTO v_camion_existe;
    
    IF NOT v_camion_existe THEN
        RAISE EXCEPTION 'El camión con ID % no existe en la base de datos.', p_id_camion;
    END IF;

    -- Buscar si ese camión tiene un viaje activo en este momento
    SELECT id_viaje INTO v_viaje_activo 
    FROM viaje 
    WHERE id_camion = p_id_camion AND estado_viaje = 'Activo' 
    LIMIT 1;

    IF v_viaje_activo IS NULL THEN
        RAISE EXCEPTION 'El camión % no tiene ningún viaje activo para registrar telemetría.', p_id_camion;
    END IF;

    -- Si todo está OK, insertar el registro de telemetría
    INSERT INTO telemetria (id_viaje, coordenadas, velocidad, nivel_combustible, datos_sensor)
    VALUES (v_viaje_activo, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326), p_vel, p_comb, p_sensor);
    
    RAISE NOTICE 'Telemetría registrada correctamente para el viaje %', v_viaje_activo;

EXCEPTION
    -- Bloque para capturar el error (EXCEPTION) y que el proceso no haga crash
    WHEN OTHERS THEN
        RAISE NOTICE 'Error capturado (No bloqueante): %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- Procedimiento con CURSOR para cerrar viajes inactivos (> 24hs)

CREATE OR REPLACE PROCEDURE cerrar_viajes_inactivos() AS $$
DECLARE
    v_id_viaje INT;
    v_ultima_conexion TIMESTAMP;
    -- Declaración del cursor que apunta solo a viajes activos
    c_viajes CURSOR FOR
        SELECT id_viaje
        FROM viaje
        WHERE estado_viaje = 'Activo';
BEGIN
    OPEN c_viajes;
    
    LOOP
        -- Extraer fila a fila
        FETCH c_viajes INTO v_id_viaje;
        EXIT WHEN NOT FOUND;

        -- Obtener la hora de la última señal de este viaje
        SELECT MAX(timestamp) INTO v_ultima_conexion
        FROM telemetria
        WHERE id_viaje = v_id_viaje;

        -- Lógica: Si jamás emitió señal (NULL) o pasaron más de 24 hs
        IF v_ultima_conexion IS NULL OR v_ultima_conexion < (CURRENT_TIMESTAMP - INTERVAL '24 hours') THEN
            UPDATE viaje
            SET estado_viaje = 'Finalizado', 
                fecha_fin = CURRENT_TIMESTAMP
            WHERE id_viaje = v_id_viaje;
            
            RAISE NOTICE 'Viaje % cerrado automáticamente por inactividad.', v_id_viaje;
        END IF;
    END LOOP;
    
    CLOSE c_viajes;
END;
$$ LANGUAGE plpgsql;