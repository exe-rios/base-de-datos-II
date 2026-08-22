
-- Habilitar extensión espacial para coordenadas y perímetros
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Tabla Camion
CREATE TABLE camion (
    id_camion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patente VARCHAR(20) UNIQUE NOT NULL,
    marca VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    capacidad_tanque NUMERIC(8,2) NOT NULL,
    estado_actual VARCHAR(50) DEFAULT 'Disponible',
    odometro_total NUMERIC(12,2) DEFAULT 0
);

-- 2. Tabla Chofer
CREATE TABLE chofer (
    id_chofer INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE NOT NULL,
    licencia VARCHAR(50) NOT NULL
);

-- 3. Tabla Telefono_Chofer
CREATE TABLE telefono_chofer (
    tel_fijo VARCHAR(50) PRIMARY KEY,
    tel_movil VARCHAR(50),
    id_chofer INT NOT NULL,
    CONSTRAINT fk_chofer_telefono FOREIGN KEY (id_chofer) REFERENCES chofer(id_chofer) ON DELETE CASCADE
);

-- 4. Tabla Zona_logistica
CREATE TABLE zona_logistica (
    id_zona INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_zona VARCHAR(100) NOT NULL,
    tipo_zona VARCHAR(50) NOT NULL,
    perimetro GEOMETRY(Polygon, 4326) NOT NULL
);

-- 5. Tabla Viaje
CREATE TABLE viaje (
    id_viaje INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_camion INT NOT NULL,
    id_chofer INT NOT NULL,
    fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP,
    origen_destino JSONB,
    estado_viaje VARCHAR(50) DEFAULT 'Activo',
    ruta GEOMETRY(LineString, 4326),
    CONSTRAINT fk_viaje_camion FOREIGN KEY (id_camion) REFERENCES camion(id_camion),
    CONSTRAINT fk_viaje_chofer FOREIGN KEY (id_chofer) REFERENCES chofer(id_chofer)
);

-- Tabla intermedia para la relación (Hoja de Ruta) entre Viaje y Zona
CREATE TABLE hoja_de_ruta (
    id_hoja_ruta INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_viaje INT NOT NULL,
    id_zona INT NOT NULL,
    orden INT NOT NULL, 
    CONSTRAINT fk_hoja_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON DELETE CASCADE,
    CONSTRAINT fk_hoja_zona FOREIGN KEY (id_zona) REFERENCES zona_logistica(id_zona) ON DELETE CASCADE,
    CONSTRAINT uq_viaje_orden UNIQUE (id_viaje, orden) -- Evita que haya dos paradas con el mismo número de orden en el mismo viaje
);

-- 6. Tabla Telemetria
CREATE TABLE telemetria (
    id_telemetria INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_viaje INT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    coordenadas GEOMETRY(Point, 4326) NOT NULL,
    velocidad NUMERIC(5,2) NOT NULL,
    nivel_combustible NUMERIC(8,2) NOT NULL,
    datos_sensor JSONB,
    CONSTRAINT fk_telemetria_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON DELETE RESTRICT
);

-- 7. Tabla Incidencias
CREATE TABLE incidencias (
    id_incidencia INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_viaje INT NOT NULL,
    id_telemetria BIGINT,
    tipo_alerta VARCHAR(100) NOT NULL,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    hora TIME NOT NULL DEFAULT CURRENT_TIME,
    descripcion TEXT,
    CONSTRAINT fk_incidencia_viaje FOREIGN KEY (id_viaje) REFERENCES viaje(id_viaje) ON DELETE CASCADE,
    CONSTRAINT fk_incidencia_telemetria FOREIGN KEY (id_telemetria) REFERENCES telemetria(id_telemetria) ON DELETE SET NULL
);

-- indices para optimizar

CREATE INDEX idx_viaje_camion ON viaje(id_camion);
CREATE INDEX idx_viaje_chofer ON viaje(id_chofer);
CREATE INDEX idx_telemetria_viaje ON telemetria(id_viaje);
CREATE INDEX idx_incidencias_viaje ON incidencias(id_viaje);
CREATE INDEX idx_telemetria_timestamp ON telemetria(timestamp);

CREATE INDEX idx_hoja_viaje ON hoja_de_ruta(id_viaje);
CREATE INDEX idx_hoja_zona ON hoja_de_ruta(id_zona);

CREATE INDEX idx_zona_perimetro ON zona_logistica USING GIST (perimetro);
CREATE INDEX idx_telemetria_coordenadas ON telemetria USING GIST (coordenadas);
CREATE INDEX idx_viaje_ruta ON viaje USING GIST (ruta);

CREATE INDEX idx_telemetria_datos_sensor ON telemetria USING GIN (datos_sensor);
CREATE INDEX idx_viaje_origen_destino ON viaje USING GIN (origen_destino);
