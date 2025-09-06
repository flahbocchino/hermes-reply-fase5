-- ==========================================================
-- Industrial Sensors - Relational Schema (DER → Tabelas)
-- ==========================================================
-- Entidades: SITE, MACHINE, SENSOR_TYPE, SENSOR, SENSOR_READING, MAINTENANCE_EVENT
-- Regras:
--  - UNIQUE(sensor_id, ts) em SENSOR_READING para evitar duplicatas temporais
--  - UNIQUE(serial_number) em SENSOR
--  - Índice (sensor_id, ts) para acelerar janelas temporais
--  - status/quality_score ajudam a filtrar leituras ruins em ML
-- ----------------------------------------------------------

-- Apagar (opcional, conforme SGBD)
-- DROP TABLE maintenance_event;
-- DROP TABLE sensor_reading;
-- DROP TABLE sensor;
-- DROP TABLE sensor_type;
-- DROP TABLE machine;
-- DROP TABLE site;

-- ======================
-- Tabela: SITE (planta)
-- ======================
CREATE TABLE site (
  site_id        INTEGER      PRIMARY KEY,
  name           VARCHAR(100) NOT NULL,
  city           VARCHAR(80),
  state          VARCHAR(80),
  country        VARCHAR(80)  DEFAULT 'Brazil'
);

-- ===========================
-- Tabela: MACHINE (máquina)
-- ===========================
CREATE TABLE machine (
  machine_id     INTEGER      PRIMARY KEY,
  site_id        INTEGER      NOT NULL,
  name           VARCHAR(100) NOT NULL,
  model          VARCHAR(80),
  installed_at   DATE,
  status         VARCHAR(30)  DEFAULT 'ACTIVE',
  CONSTRAINT fk_machine_site FOREIGN KEY (site_id) REFERENCES site(site_id)
);

-- ==================================
-- Tabela: SENSOR_TYPE (catálogo)
-- ==================================
CREATE TABLE sensor_type (
  sensor_type_id INTEGER      PRIMARY KEY,
  name           VARCHAR(60)  NOT NULL,   -- ex.: Temperature, Vibration, Pressure
  unit           VARCHAR(20)  NOT NULL,   -- ex.: C, mm_s, bar
  min_value      NUMERIC(12,4) DEFAULT -1000,
  max_value      NUMERIC(12,4) DEFAULT  1000000
);

-- =========================================
-- Tabela: SENSOR (instância instalada)
-- =========================================
CREATE TABLE sensor (
  sensor_id        INTEGER       PRIMARY KEY,
  machine_id       INTEGER       NOT NULL,
  sensor_type_id   INTEGER       NOT NULL,
  serial_number    VARCHAR(60)   NOT NULL UNIQUE,
  installed_at     DATE,
  is_active        VARCHAR(1)    DEFAULT 'Y',    -- Oracle-friendly ('Y'/'N'); em Postgres use BOOLEAN
  sample_rate_hz   NUMERIC(12,4) DEFAULT 1,      -- amostras por segundo
  CONSTRAINT fk_sensor_machine   FOREIGN KEY (machine_id)     REFERENCES machine(machine_id),
  CONSTRAINT fk_sensor_type      FOREIGN KEY (sensor_type_id)  REFERENCES sensor_type(sensor_type_id)
);

-- ========================================
-- Tabela: SENSOR_READING (leituras)
-- ========================================
CREATE TABLE sensor_reading (
  reading_id      BIGINT        PRIMARY KEY,
  sensor_id       INTEGER       NOT NULL,
  ts              TIMESTAMP     NOT NULL,
  value           NUMERIC(14,6) NOT NULL,
  is_anomaly      VARCHAR(1)    DEFAULT 'N',     -- 'Y'/'N' (ou BOOLEAN em Postgres)
  anomaly_source  VARCHAR(30),                   -- 'rule','ml','manual','simulated'
  quality_score   NUMERIC(6,3)  DEFAULT 1.0,     -- 0..1
  status          VARCHAR(20)   DEFAULT 'OK',    -- 'OK','MISSING','CORRUPTED'
  CONSTRAINT fk_reading_sensor FOREIGN KEY (sensor_id) REFERENCES sensor(sensor_id),
  CONSTRAINT uq_sensor_ts UNIQUE (sensor_id, ts)
);

-- Índice composto para janelas temporais
CREATE INDEX idx_reading_sensor_ts ON sensor_reading(sensor_id, ts);

-- ============================================
-- Tabela: MAINTENANCE_EVENT (manutenção)
-- ============================================
CREATE TABLE maintenance_event (
  event_id      INTEGER      PRIMARY KEY,
  machine_id    INTEGER      NOT NULL,
  started_at    TIMESTAMP    NOT NULL,
  ended_at      TIMESTAMP,
  event_type    VARCHAR(40)  NOT NULL,          -- 'PREVENTIVE','CORRECTIVE','CALIBRATION'
  description   VARCHAR(4000),
  CONSTRAINT fk_event_machine FOREIGN KEY (machine_id) REFERENCES machine(machine_id)
);

-- ============================
-- Sementes de exemplo (opcional)
-- ============================
INSERT INTO site(site_id, name, city, state, country) VALUES
  (1, 'São Paulo Plant', 'São Paulo', 'SP', 'Brazil');

INSERT INTO machine(machine_id, site_id, name, model, installed_at, status) VALUES
  (10, 1, 'Compressor A', 'CMP-500', DATE '2022-05-12', 'ACTIVE'),
  (20, 1, 'Lathe B',      'LTH-220', DATE '2023-01-20', 'ACTIVE');

INSERT INTO sensor_type(sensor_type_id, name, unit, min_value, max_value) VALUES
  (100, 'Temperature', 'C', -40, 200),
  (200, 'Vibration',   'mm_s', 0, 300),
  (300, 'Pressure',    'bar', 0, 50);

INSERT INTO sensor(sensor_id, machine_id, sensor_type_id, serial_number, installed_at, is_active, sample_rate_hz) VALUES
  (1000, 10, 100, 'TMP-10-A-001', DATE '2023-02-01', 'Y', 1),
  (2000, 10, 300, 'PRS-10-A-001', DATE '2023-02-01', 'Y', 0.2),
  (3000, 20, 200, 'VIB-20-B-001', DATE '2023-03-15', 'Y', 5);

-- ==========================================================
-- Notas de dialeto rápido (use a que você precisar):
-- ----------------------------------------------------------
-- ORACLE 12c+:
--   * Troque NUMERIC por NUMBER(p,s) e VARCHAR por VARCHAR2.
--   * BOOLEAN não existe → use CHAR(1) ('Y'/'N').
--   * Opcional: IDs automáticos com GENERATED AS IDENTITY, por ex.:
--       site_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY
--   * DATE vs TIMESTAMP: mantenha TIMESTAMP para 'ts' e eventos.
--
-- POSTGRES:
--   * Pode usar BOOLEAN em is_active/is_anomaly e BIGSERIAL/SERIAL se quiser autoincremento.
--
-- SQLITE (para testes rápidos/Colab):
--   * Aceita tipos flexíveis; mantenha conforme acima.
-- ==========================================================
