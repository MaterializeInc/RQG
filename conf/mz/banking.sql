-- Dataset for the banking grammar. The grammar's DML preserves two
-- invariants that its check queries assert:
--   sum100row:   val1 + val2 = 100 for every row
--   avg100table: AVG(val1) = 100, or the table is empty
--
-- Loaded into Materialize only (the workload has no reference
-- implementation), so Materialize-specific syntax is fine.

DROP TABLE IF EXISTS sum100row CASCADE;
DROP TABLE IF EXISTS avg100table CASCADE;

CREATE TABLE sum100row (val1 INTEGER, val2 INTEGER);
CREATE DEFAULT INDEX ON sum100row;

CREATE TABLE avg100table (id INTEGER, val1 INTEGER);
CREATE DEFAULT INDEX ON avg100table;

-- Maintained aggregates over both tables, once as a materialized view and
-- once as an indexed view, so the grammar's invariant checks also exercise
-- incremental maintenance through both the persist-backed and the
-- arrangement-backed path. Both invariants are equivalent to
-- total = 100 * cnt (NULL total means the table is empty).

CREATE MATERIALIZED VIEW sum100row_totals AS SELECT SUM(val1 + val2) AS total, COUNT(*) AS cnt FROM sum100row;
CREATE MATERIALIZED VIEW avg100table_totals AS SELECT SUM(val1) AS total, COUNT(*) AS cnt FROM avg100table;

CREATE VIEW sum100row_totals_v AS SELECT SUM(val1 + val2) AS total, COUNT(*) AS cnt FROM sum100row;
CREATE DEFAULT INDEX ON sum100row_totals_v;
CREATE VIEW avg100table_totals_v AS SELECT SUM(val1) AS total, COUNT(*) AS cnt FROM avg100table;
CREATE DEFAULT INDEX ON avg100table_totals_v;

INSERT INTO avg100table (id, val1) VALUES (1, 0), (2, 0), (3, 0), (4, 100), (5, 100), (6, 100), (7, 100), (8, 200), (9, 200), (10, 200);
