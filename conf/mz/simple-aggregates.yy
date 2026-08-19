# Aggregations, GROUP BY / HAVING, set operations and simple joins over the
# conf/mz/simple.sql tables, compared against Postgres.
#
# Determinism constraints, so that result comparison stays false-positive
# free: the data holds only integer-valued doubles, which sum exactly in any
# order, so SUM/AVG are safe. STRING_AGG orders by the aggregated expression
# itself, so ties are identical strings. FULL JOIN only appears with USING,
# because Postgres rejects FULL JOIN on conditions that are neither merge-
# nor hash-joinable.

explain:
	EXPLAIN query
;

query:
	select
;

value:
	_digit | _digit | _digit | _digit | NULL
;

# The text- and boolean-typed aggregates only appear at the top level of a
# query (single_select_extended): as a set-operation arm or inside a subquery
# their output type would clash with the numeric aggregates of the other arm
# or with the numeric column they are compared against, and both servers
# would reject the query.

select:
	select_numeric | select_numeric | select_numeric |
	single_select_extended
;

select_numeric:
	single_select |
	single_select union_except_intersect all_distinct single_select |
	single_select union_except_intersect all_distinct single_select union_except_intersect all_distinct single_select
;

union_except_intersect:
	UNION | EXCEPT
	# | INTERSECT # https://github.com/MaterializeInc/database-issues/issues/7284
;

all_distinct:
	ALL | DISTINCT
;

single_select:
	SELECT distinct select_item_list, aggregate_list FROM source AS a1 left_right JOIN source AS a2 ON ( cond_no_subquery ) WHERE cond_list GROUP BY group_by_list having |
	SELECT distinct select_item_list, aggregate_list FROM source AS a1 left_right_full JOIN source AS a2 USING ( col_list ) WHERE cond_list GROUP BY group_by_list having
;

single_select_extended:
	SELECT distinct select_item_list, aggregate_list_extended FROM source AS a1 left_right JOIN source AS a2 ON ( cond_no_subquery ) WHERE cond_list GROUP BY group_by_list having |
	SELECT distinct select_item_list, aggregate_list_extended FROM source AS a1 left_right_full JOIN source AS a2 USING ( col_list ) WHERE cond_list GROUP BY group_by_list having
;

having:
	| | | HAVING aggregate_cond
;

source:
	table_name | table_name | table_name | values_source |
	( SELECT select_item AS f1 , select_item AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 ON ( cond ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT select_item AS f1 , select_item AS f2 FROM table_name AS a1 left_right_full JOIN table_name AS a2 USING ( col_list ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT aggregate_item_no_window AS f1 , aggregate_item_no_window AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 ON ( cond ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT aggregate_item_no_window AS f1 , aggregate_item_no_window AS f2 FROM table_name AS a1 left_right_full JOIN table_name AS a2 USING ( col_list ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT select_item AS f1 , aggregate_item_no_window AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 ON ( cond ) WHERE cond_list GROUP BY 1 order_by_2_limit_subquery ) |
	distinct_on_source
;

# DISTINCT ON is deterministic here because the trailing ORDER BY totally
# orders every group, and Postgres requires the DISTINCT ON expression to be
# the leftmost ORDER BY expression.

distinct_on_source:
	( SELECT DISTINCT ON ( f1 ) f1 , f2 FROM table_name where_table ORDER BY f1 asc_desc , f2 asc_desc )
;

where_table:
	| | WHERE f1 cmp_op _digit | WHERE f2 IS not NULL
;

asc_desc:
	ASC | DESC
;

cond_list:
	cond and_or cond |
	cond and_or cond_list
;

and_or:
	AND | AND | AND | OR
;

cond:
	cond_no_subquery | cond_no_subquery | cond_no_subquery | cond_no_subquery | cond_no_subquery |
	cond_no_subquery | cond_no_subquery | cond_no_subquery | cond_no_subquery | cond_no_subquery |
	cond_no_subquery | cond_no_subquery | cond_no_subquery | cond_no_subquery | cond_subquery
;

cond_no_subquery:
	select_item not IN ( in_list ) |
	select_item cmp_op select_item |
	select_item IS not NULL |
	NOT ( cond_no_subquery )
;

cond_subquery:
	select_item cmp_op ( SELECT distinct col_or_aggregate_alias FROM ( select_numeric ) AS dt ORDER BY 1 LIMIT 1 OFFSET _digit ) |
	select_item cmp_op any_all ( SELECT distinct col_or_aggregate_alias FROM ( select_numeric ) AS dt order_by_limit_subquery ) |
	select_item not IN ( SELECT distinct col_or_aggregate_alias AS x1 FROM ( select_numeric ) AS dt order_by_limit_subquery ) |
	not EXISTS ( select_numeric )
;

order_by_limit_subquery:
	ORDER BY 1 asc_desc_nulls |
	ORDER BY 1 asc_desc_nulls LIMIT limit_value offset
;

order_by_2_limit_subquery:
	ORDER BY 1 asc_desc_nulls , 2 asc_desc_nulls |
	ORDER BY 1 asc_desc_nulls , 2 asc_desc_nulls LIMIT limit_value offset
;

asc_desc_nulls:
	| ASC | DESC | asc_desc NULLS FIRST | asc_desc NULLS LAST
;

limit_value:
	0 | 1 | _digit
;

any_all:
	ANY | ALL
;

aggregate_cond:
	aggregate_item_no_window cmp_op _digit |
	aggregate_item_no_window IS not NULL |
	NOT ( aggregate_cond )
;

not:
	| NOT
;

cmp_op:
	= | = | > | <
;

left_right:
	| | LEFT | RIGHT
;

left_right_full:
	| | LEFT | RIGHT | FULL
;

aggregate_list:
	(aggregate_item_no_window) AS agg1 , (aggregate_item_no_window) AS agg2
;

aggregate_list_extended:
	(aggregate_item_extended) AS agg1 , (aggregate_item_extended) AS agg2
;

aggregate_item_extended:
	aggregate_item_no_window | aggregate_item_no_window | aggregate_item_no_window |
	aggregate_item_no_window | aggregate_item_no_window | aggregate_item_no_window |
	bool_aggregate_func ( select_item cmp_op value ) |
	string_agg_item
;

# The parentheses in (select_item)::TEXT matter: without them the cast binds
# to the last column of a multi-column expression, casting text into float
# arithmetic, which both servers reject.

aggregate_item_no_window:
    SUM(LENGTH((select_item)::TEXT)) |
	ARRAY_LENGTH ( array_generating_aggregate_func ( select_item ), 1 ) |
	COUNT( * ) |
	aggregate_func ( select_item ) FILTER ( WHERE cond_no_subquery ) |
	aggregate_func ( distinct select_item ) |
	aggregate_func ( distinct select_item ) |
	aggregate_func ( distinct select_item ) |
	aggregate_func ( select_item )
;

aggregate_func:
	MIN | MAX | COUNT | AVG
;

bool_aggregate_func:
	BOOL_AND | BOOL_OR
;

# STRING_AGG stays deterministic by ordering on the aggregated expression
# itself: ties can only occur between identical strings.

string_agg_item:
	STRING_AGG ( a1.f1::TEXT , ',' ORDER BY a1.f1 ) |
	STRING_AGG ( a1.f2::TEXT , ',' ORDER BY a1.f2 ) |
	STRING_AGG ( a2.f1::TEXT , ',' ORDER BY a2.f1 ) |
	STRING_AGG ( a2.f2::TEXT , ',' ORDER BY a2.f2 )
;

array_generating_aggregate_func:
	ARRAY_AGG
;


select_item_list:
	(a1.f1) AS c1, (a2.f1) AS c2, (a1.f2) AS c3 |
	(select_item) AS c1, (select_item) AS c2, (select_item) AS c3
;

select_item_in_list:
	select_item , select_item |
	select_item , select_item_in_list
;

in_list:
	in_item , in_item |
	in_item , in_list
;

# A NULL in a NOT IN list is a classic three-valued-logic trap: the
# predicate can then never be true, only false or NULL.

in_item:
	_digit | _digit | _digit | _digit | _digit | NULL
;

# Multiplication only ever combines two raw columns, keeping magnitudes
# small: unbounded products of sums could leave the integer-exact range of
# doubles, whose text rendering differs between the servers.

select_item:
	col_reference |
	col_reference |
	col_reference + select_item |
	col_reference + col_reference |
	col_reference - col_reference |
	col_reference * col_reference |
	CASE WHEN cond_no_subquery THEN select_item ELSE select_item END |
	COALESCE ( col_reference , col_reference ) |
	greatest_least ( select_item , select_item ) |
    NULLIF ( col_reference , col_reference )
;

greatest_least:
	GREATEST | LEAST
;

order_by_limit:
	order_by_full limit
;

offset:
	| OFFSET _digit
;

order_by:
	ORDER BY order_by_list
;

order_by_full:
	ORDER BY 1 , 2 , 3 , 4 , 5
;

order_by_list:
	order_by_item |
	order_by_item , order_by_list
;

order_by_item:
	1 | 2 | 3 | select_item
;

limit:
	LIMIT _digit OFFSET _digit
;

col_reference:
	alias . col_name
;

alias:
	a1 | a2
;

col_list:
	f1 | f2 |
	f2 , f1 | f1 , f2
;

# Give preference to the NOT NULL column, to reflect for the fact that
# most columns/datasets are NOT NULL, e.g. DBT/TPC

col_name:
	f1 | f2 | f2
;

col_alias:
	c1 | c2 | c3;
;

aggregate_alias:
	agg1 | agg2
;

col_or_aggregate_alias:
	col_alias | aggregate_alias
;

group_by_list:
	1 , 2 , 3
;

group_by_item:
	1 | 2 | 3
;

distinct:
	| | | | DISTINCT
;

table_name:
	t1 | t2 | pk1 | pk2
;

values_source:
	(SELECT * FROM ( VALUES (1,2) ) table_name (f1,f2)) |
	(SELECT * FROM ( VALUES (1,2), (NULL,0), (2,2), (9,9) ) table_name (f1,f2)) |
	(SELECT * FROM ( VALUES (0,0), (NULL,3), (NULL,3), (8,8) ) table_name (f1,f2))
;
