#
# This test simulates a "banking" workload whereby data is moved from one row
# to another or from one column to another but the expectation is that
# the invariants about the data will continue to hold throughout the test.
#
# The invariants are checked by the queries in the "check" rule. To run this file,
# use --validator=QueryProperties,RepeatableRead
#
# The tables live in conf/mz/banking.sql. Every DML alternative must
# preserve both invariants under any interleaving with the other workers:
#   sum100row:   val1 + val2 = 100 holds for every row
#   avg100table: AVG(val1) = 100, or the table is empty
#

query_init:
    set_transaction_isolation
;

set_transaction_isolation:
    SET transaction_isolation=serializable
;

query:
	query_sum100row | query_avg100table | check
;

check:
	BEGIN ; select_list ; COMMIT
;

select_list:
	select |
	select ; select_list
;

select:
	SELECT * FROM sum100row_avg100table |
	/* RESULTSET_HAS_NO_ROWS */ SELECT * FROM sum100row WHERE val1 + val2 != 100 |
	/* RESULTSET_IS_SINGLE_BOOLEAN_TRUE */ SELECT AVG(val1) IS NULL OR AVG(val1) = 100 FROM avg100table |
	# The invariants as seen through the incrementally maintained views.
	/* RESULTSET_IS_SINGLE_BOOLEAN_TRUE */ SELECT total IS NULL OR total = 100 * cnt FROM maintained_totals |
	# A direct one-shot aggregation must agree with the maintained view at
	# the same timestamp.
	/* RESULTSET_IS_SINGLE_BOOLEAN_TRUE */ SELECT ( SELECT COALESCE ( SUM ( val1 + val2 ) , -1 ) FROM sum100row ) = ( SELECT COALESCE ( total , -1 ) FROM sum100row_maintained ) |
	/* RESULTSET_IS_SINGLE_BOOLEAN_TRUE */ SELECT ( SELECT COALESCE ( SUM ( val1 ) , -1 ) FROM avg100table ) = ( SELECT COALESCE ( total , -1 ) FROM avg100table_maintained )
;

sum100row_avg100table:
	sum100row | avg100table | maintained_totals
;

maintained_totals:
	sum100row_maintained | avg100table_maintained
;

sum100row_maintained:
	sum100row_totals | sum100row_totals_v
;

avg100table_maintained:
	avg100table_totals | avg100table_totals_v
;

query_sum100row:
	insert_sum100row_transaction | insert_sum100row_transaction | insert_sum100row_transaction | insert_sum100row_select |
	update_sum100row | update_sum100row | delete_sum100row
;

insert_sum100row_transaction:
	BEGIN ; insert_sum100row_list ; COMMIT
;

insert_sum100row_list:
	insert_sum100row ; insert_sum100row |
	insert_sum100row ; insert_sum100row_list
;

insert_sum100row:
	INSERT INTO sum100row VALUES (50, 50) |
        INSERT INTO sum100row VALUES (0, 100) |
        INSERT INTO sum100row VALUES (50, 50) |
        INSERT INTO sum100row VALUES (100, 0) |
        INSERT INTO sum100row VALUES (0, 100), (50, 50), (100, 0)
;

insert_sum100row_select:
	INSERT INTO sum100row SELECT * FROM sum100row LIMIT _digit
;

update_sum100row:
	UPDATE sum100row SET val1 = val1 - { $val = $prng->int(-100, 100) ; } , val2 = val2 + { $val } optional_where |
	UPDATE sum100row SET val1 = val2 , val2 = val1 optional_where |
	# Reflecting both columns around 50 keeps the row sum: (100 - val1) + (100 - val2) = 100.
	UPDATE sum100row SET val1 = 100 - val1 , val2 = 100 - val2 optional_where
;

delete_sum100row:
	DELETE FROM sum100row where
;

query_avg100table:
	insert_avg100table_transaction | insert_avg100table_transaction | insert_avg100table_transaction |
	insert_avg100table_select |
	update_avg100table | delete_avg100table
;

insert_avg100table_transaction:
	BEGIN ; insert_avg100table_list ; COMMIT;
;

insert_avg100table_list:
	insert_avg100table ; insert_avg100table |
	insert_avg100table ; insert_avg100table_list
;

insert_avg100table:
        INSERT INTO avg100table (val1) VALUES ( 100 ) |
        INSERT INTO avg100table (val1) VALUES ( 0 ) , ( 200 )
;

insert_avg100table_select:
	# Duplicating every row keeps the average. Only a full copy is safe: an
	# arbitrary subset need not average 100. The count guard bounds the
	# otherwise exponential growth.
	INSERT INTO avg100table SELECT * FROM avg100table WHERE ( SELECT COUNT(*) FROM avg100table ) < 1000
;

update_avg100table:
	UPDATE avg100table SET val1 = 100 |
	# Reflecting every value around the mean keeps the mean: AVG(200 - val1) = 200 - AVG(val1) = 100.
	UPDATE avg100table SET val1 = 200 - val1 |
	# Moving value from a row in ids 1-5 to one in ids 6-10. This preserves the
	# sum only while both id ranges hold the same number of rows: the CASE
	# arms fire once per matching row, so an uneven split leaves the two
	# adjustments uncancelled. The dataset gives ids 1-10 one row each, nothing
	# deletes an ided row, and insert_avg100table_select copies all of them
	# together, which keeps the two counts equal. ELSE keeps val1 non-NULL: a
	# NULL would break the maintained views' total = 100 * cnt check, which
	# counts with COUNT(*), while leaving AVG(val1) = 100 intact.
	UPDATE avg100table
	SET val1 = CASE
		WHEN id = { $id2 = $prng->int(1,5) }
		THEN val1 - { $val = $prng->int(-100, 100) }
		WHEN id = { $id1 = $prng->int(6,10) }
		THEN val1 + { $val }
		ELSE val1
        END
        WHERE id = { $id1 } OR id = { $id2 };
;

delete_avg100table:
	# Removing rows that sit exactly at the mean keeps the mean (or empties the
	# table, which the invariant allows). Only the id-less rows may go. Deleting
	# by val1 alone would thin the two id ranges out unevenly and break the
	# precondition of the transfer in update_avg100table.
	DELETE FROM avg100table WHERE id IS NULL AND val1 = 100
;

optional_where:
	| where
;

where:
	WHERE val1 cmp_op _smallint_unsigned
;

cmp_op:
	= | = | > | <
;
