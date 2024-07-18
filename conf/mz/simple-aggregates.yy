explain:
	EXPLAIN query
;

query:
	select
;

value:
	_digit | _digit | _digit | _digit | NULL
;

select:
	single_select |
	single_select union_except_intersect all_distinct single_select
;

union_except_intersect:
	UNION | EXCEPT
	# | INTERSECT # https://github.com/MaterializeInc/materialize/issues/24358
;

all_distinct:
	ALL | DISTINCT
;

single_select:
	SELECT distinct select_item_list, aggregate_list FROM source AS a1 left_right JOIN source AS a2 ON ( cond_no_subquery ) WHERE cond_list GROUP BY group_by_list |
	SELECT distinct select_item_list, aggregate_list FROM source AS a1 left_right JOIN source AS a2 USING ( col_list ) WHERE cond_list GROUP BY group_by_list
;

source:
	table_name | table_name | table_name | values_source |
	( SELECT select_item AS f1 , select_item AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 ON ( cond ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT select_item AS f1 , select_item AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 USING ( col_list ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT aggregate_item_no_window AS f1 , aggregate_item_no_window AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 ON ( cond ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT aggregate_item_no_window AS f1 , aggregate_item_no_window AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 USING ( col_list ) WHERE cond_list order_by_2_limit_subquery ) |
	( SELECT select_item AS f1 , aggregate_item_no_window AS f2 FROM table_name AS a1 left_right JOIN table_name AS a2 ON ( cond ) WHERE cond_list GROUP BY 1 order_by_2_limit_subquery )
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
	select_item cmp_op ( SELECT distinct col_or_aggregate_alias FROM ( select ) AS dt ORDER BY 1 LIMIT 1 OFFSET _digit ) |
	select_item cmp_op any_all ( SELECT distinct col_or_aggregate_alias FROM ( select ) AS dt order_by_limit_subquery ) | 
	select_item not IN ( SELECT distinct col_or_aggregate_alias AS x1 FROM ( select ) AS dt order_by_limit_subquery ) |
	not EXISTS ( select ) 
;

order_by_limit_subquery:
	ORDER BY 1 |
	ORDER BY 1 LIMIT limit_value offset
;

order_by_2_limit_subquery:
	ORDER BY 1 , 2 |
	ORDER BY 1 , 2 LIMIT limit_value offset
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

aggregate_list:
	(aggregate_item_no_window) AS agg1 , (aggregate_item_no_window) AS agg2
;

aggregate_item_no_window:
	ARRAY_LENGTH ( array_generating_aggregate_func ( select_item ), 1 ) |
	aggregate_func ( distinct select_item ) |
	aggregate_func ( distinct select_item ) |
	aggregate_func ( distinct select_item ) |
	aggregate_func ( select_item )
;

aggregate_func:
	MIN | MAX | COUNT | AVG
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

in_item:
	_digit
;

select_item:
	col_reference |
	col_reference |
	col_reference + select_item |
	col_reference + col_reference |
    NULLIF ( col_reference , col_reference )
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
	(SELECT * FROM ( VALUES (1,2) ) table_name (f1,f2))
;
