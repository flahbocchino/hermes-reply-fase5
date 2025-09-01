# Hermes Reply – Fase 5 (BD + ML)

Repositório da **Fase 5** do desafio em parceria com a **Hermes Reply**.  
Nesta etapa modelamos um **banco de dados relacional** para dados de sensores e desenvolvemos um **modelo de Machine Learning** (classificação) para apoiar manutenção preditiva.

---

## 🧭 Visão Geral

- **Objetivo**: estruturar e persistir leituras de sensores (temperatura, vibração, corrente, etc.) em um **BD relacional** e treinar um modelo de **classificação** simples que indique necessidade de manutenção (`needs_maintenance`).
- **Tecnologias**: SQLite, Python (Pandas, NumPy, scikit-learn, Matplotlib), Google Colab.
- **Entregáveis**: DER, DDL (script SQL), base de dados (`sensors.db`), notebook, script `.py` de ML e gráficos de resultados.

---

## 🗂 Estrutura do Repositório

hermes-reply-fase5/
data/ # CSVs (se usados para ingestão)
ddl/ # DDL SQL (ex.: schema.sql)
images/ # gráficos exportados (DER, matriz de confusão, etc.)
notebooks/ # notebooks do Colab
src/ # código-fonte (.py) - pipeline de ML
sensors.db # banco SQLite com as tabelas e dados
README.md

**Arquivos importantes**
- `ddl/schema.sql` → criação das tabelas e índices.
- `src/train_ml.py` → pipeline de ML em script Python (executável sem notebook).
- `images/confusion_matrix_from_script.png` → matriz de confusão do modelo.
- `images/leituras_por_tipo.png` → barras com nº de leituras por tipo de sensor.
- `images/er_diagram.png` → DER exportado (se gerado).
- `images/serie_sensor_XX.png` → série temporal de um sensor (exemplo).

---

## 🧩 Modelagem do Banco de Dados

**Entidades principais**
- `sites(site_id, name, ...)`
- `assets(asset_id, site_id, name, ...)`
- `sensor_types(sensor_type_id, name, ...)`
- `units(unit_id, symbol, ...)`
- `sensors(sensor_id, asset_id, sensor_type_id, unit_id, ...)`
- `thresholds(sensor_id, min_value, max_value, ...)`
- `readings(sensor_id, ts, value)`

**Relacionamentos / Integridade**
- `assets.site_id → sites.site_id`
- `sensors.asset_id → assets.asset_id`
- `sensors.sensor_type_id → sensor_types.sensor_type_id`
- `sensors.unit_id → units.unit_id`
- `thresholds.sensor_id → sensors.sensor_id`
- `readings.sensor_id → sensors.sensor_id`
- Índice temporal sugerido: `CREATE INDEX idx_readings_sensor_ts ON readings(sensor_id, ts DESC);`

---

## ⚙️ Como Reproduzir

### 1) Ambiente Python
```bash
pip install -q pandas numpy scikit-learn matplotlib
2) Banco de Dados (opções)

Usar pronto: o arquivo sensors.db já acompanha o repositório.

Recriar do zero:

Crie um SQLite vazio:
python - <<'PY'
import sqlite3
con = sqlite3.connect("sensors.db"); con.close()
PY
sqlite3 sensors.db < ddl/schema.sql
(Opcional) Ingestão por CSVs (se houver em data/), via notebook ou pandas.to_sql.

Requisito do desafio: pelo menos 500 leituras por sensor. Caso tenha sido utilizada simulação, isso é documentado no notebook.

3) Treinar o Modelo (script .py)
python src/train_ml.py

O que o script faz

Lê sensors.db (tabelas readings, sensors, sensor_types).

Gera um dataset “wide” (colunas temperature, vibration, current + lags).

Cria um rótulo simples needs_maintenance a partir de regras limiares.

Separa treino/teste, treina RandomForestClassifier e salva:

images/confusion_matrix_from_script.png

4) Notebook

O notebook em notebooks/ demonstra o passo a passo (ETL, consultas, gráficos, treino).

Dica: no Colab, Arquivo → Salvar uma cópia no GitHub para manter a versão final aqui.

📊 Resultados e Visualizações

1) Matriz de Confusão (modelo de classificação)
Justificativa: é uma visualização direta de verdadeiros/ falsos positivos e negativos, essencial para diagnóstico de classificadores binários.


2) Leituras por Tipo de Sensor (barras)
Justificativa: garante equilíbrio e cobertura de dados por tipo, evidenciando se há desbalanceamento de coleta.


3) Série Temporal de um Sensor (exemplo)
Justificativa: auxilia na análise exploratória de tendências e sazonalidades que impactam o comportamento do modelo.


Métricas impressas pelo script: relatório de classificação do scikit-learn (precision, recall, f1-score e accuracy).
🔎 Consultas Úteis (validação rápida)
-- Quantos registros (site, ativo, sensor, leitura)?
SELECT
  (SELECT COUNT(*) FROM sites)    AS n_sites,
  (SELECT COUNT(*) FROM assets)   AS n_assets,
  (SELECT COUNT(*) FROM sensors)  AS n_sensors,
  (SELECT COUNT(*) FROM readings) AS n_readings;

-- Leituras por sensor (top 5)
SELECT r.sensor_id, COUNT(*) AS n
FROM readings r
GROUP BY r.sensor_id
ORDER BY n DESC
LIMIT 5;

-- Leituras por tipo de sensor
SELECT st.name AS sensor_type, COUNT(r.ts) AS n
FROM readings r
JOIN sensors s ON s.sensor_id = r.sensor_id
JOIN sensor_types st ON st.sensor_type_id = s.sensor_type_id
GROUP BY st.name
ORDER BY n DESC;

✅ Checklist da Entrega

 DER exportado em images/.

 Script DDL (ddl/schema.sql) com tabelas, FKs e índices.

 Base de dados (sensors.db) populada (≥ 500 leituras/sensor).

 Notebook com o passo a passo (ETL, análises, ML).

 Script Python (src/train_ml.py) reproduzindo o treino sem notebook.

 Gráficos: matriz de confusão, barras por tipo, série temporal.

 README explicando como rodar e justificando escolhas.

📌 Observações

Thresholds e rótulos de manutenção foram simplificados para fins didáticos; em um cenário real, a definição deve ser suportada por engenharia de manutenção e/ou especialistas de domínio.

O SQLite foi escolhido pela simplicidade e por atender bem ao fluxo do desafio; bancos relacionais “full” (PostgreSQL, Oracle) são facilmente suportados com o mesmo modelo lógico.

---

👩‍💻 Autoria
- Flavia Bocchino (RM564213)  
- Pedro Zani (RM564956)
