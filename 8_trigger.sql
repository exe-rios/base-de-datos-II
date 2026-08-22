-- trigger 1: Alerta por Exceso de Velocidad (> 90 km/h)
-- Se dispara DESPUÉS de cada insert en la tabla telemetria.

-- Creamos la función del disparador
CREATE OR REPLACE FUNCTION trg_func_alerta_velocidad()
RETURNS TRIGGER AS $$
BEGIN
    -- Evaluar si la nueva velocidad registrada supera el límite legal
    IF NEW.velocidad > 90.00 THEN
        -- Insertar automáticamente la alerta en la tabla de incidencias
        INSERT INTO incidencias (id_viaje, id_telemetria, tipo_alerta, descripcion)
        VALUES (
            NEW.id_viaje, 
            NEW.id_telemetria, 
            'Exceso de Velocidad', 
            'El camión superó el límite permitido registrando ' || NEW.velocidad || ' km/h.'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Vincular la función a la tabla telemetria
CREATE TRIGGER trg_alerta_velocidad
AFTER INSERT ON telemetria
FOR EACH ROW
EXECUTE FUNCTION trg_func_alerta_velocidad();

-- trigger 2: Impedir el borrado de registros de Viajes.
-- Se dispara antes de cualquier intento de DELETE en la tabla viaje.

-- Creamos la función que bloquea la acción
CREATE OR REPLACE FUNCTION trg_func_impedir_borrado_viaje()
RETURNS TRIGGER AS $$
BEGIN
    -- Lanzar una excepción (error) para abortar la transacción de borrado
    RAISE EXCEPTION 'Operación crítica denegada: Está prohibido borrar viajes del sistema por cuestiones de auditoría. Por favor, actualice el estado_viaje a "Cancelado" o "Anulado".';
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Vincular la función a la tabla viaje
CREATE TRIGGER trg_impedir_borrado_viaje
BEFORE DELETE ON viaje
FOR EACH ROW
EXECUTE FUNCTION trg_func_impedir_borrado_viaje();