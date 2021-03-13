DROP SCHEMA public CASCADE;

CREATE SCHEMA public;

CREATE TABLE t1 (f1 DOUBLE PRECISION, f2 DOUBLE PRECISION NOT NULL);
CREATE INDEX t1i1 ON t1(f1);
CREATE INDEX t1i2 ON t1(f2, f1);

INSERT INTO t1 VALUES (NULL, 0);

INSERT INTO t1 VALUES (1, 1);
INSERT INTO t1 VALUES (2, 2);
INSERT INTO t1 VALUES (3, 3);
INSERT INTO t1 VALUES (4, 4);
INSERT INTO t1 VALUES (5, 5);
INSERT INTO t1 VALUES (6, 6);
INSERT INTO t1 VALUES (7, 7);
INSERT INTO t1 VALUES (8, 8);
INSERT INTO t1 VALUES (9, 9);

CREATE TABLE t2 (f1 DOUBLE PRECISION, f2 DOUBLE PRECISION NOT NULL);
CREATE INDEX t2i1 ON t2(f1);
CREATE INDEX i2i2 ON t2(f2, f1);

INSERT INTO t2 VALUES (NULL, 0);

INSERT INTO t2 VALUES (1, 1);
INSERT INTO t2 VALUES (2, 2);
INSERT INTO t2 VALUES (3, 3);
INSERT INTO t2 VALUES (4, 4);
INSERT INTO t2 VALUES (5, 5);
INSERT INTO t2 VALUES (6, 6);
INSERT INTO t2 VALUES (7, 7);
INSERT INTO t2 VALUES (8, 8);
INSERT INTO t2 VALUES (9, 9);