-- Dataset for the WITH MUTUALLY RECURSIVE grammar. Loading this before the
-- test starts (instead of a thread1_init DDL rule in the grammar) is what
-- allows the workload to run multithreaded: an init rule executes while the
-- other workers are already issuing queries, and that race produced spurious
-- result differences (database-issues#9439).
--
-- Loaded into Materialize instances only, so Materialize-specific syntax is
-- fine. PRIMARY KEY is an unenforced key hint (unsafe_enable_table_keys is on
-- in mzcompose) that gives the optimizer a unique key on f1.

DROP TABLE IF EXISTS t1 CASCADE;

CREATE TABLE t1 (f1 INTEGER PRIMARY KEY, f2 INTEGER NOT NULL, f3 INTEGER);

CREATE INDEX i1 ON t1 (f1);
CREATE INDEX i2 ON t1 (f1, f2);
CREATE INDEX i3 ON t1 (f1, f2, f3);

INSERT INTO t1 VALUES (0, 0, 0);
