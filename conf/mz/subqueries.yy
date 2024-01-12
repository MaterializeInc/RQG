explain:
	EXPLAIN select
;

query:
    select
;

select:
	SELECT select_list FROM outer_join_list WHERE outer_condition_list
;

select_list:
	select_item , select_item |
	select_item , select_list
;

select_item:
	return_one_one
;

outer_join_list:
	outer_join_item AS outer1 , outer_join_item AS outer2 |
	outer_join_item AS outer1 left_right JOIN outer_join_item AS outer2 ON ( outer_condition )
;

left_right:
	| | LEFT | RIGHT
;

outer_join_item:
	table_name | table_name | derived_table
;

outer_condition_list:	
	outer_condition |
	outer_condition and_or outer_condition
;

inner_join_list:
	table_name AS inner1 , table_name AS inner2 |
	t1 AS inner1 left_right JOIN t2 AS inner2 ON ( inner_condition )
;

inner_join_item:
	table_name
;

inner_condition_list:
	inner_condition |
	inner_condition and_or inner_condition
;

inner_outer_condition_list:
	inner_outer_condition |
	inner_outer_condition and_or inner_outer_condition
;

outer_condition_list:
	outer_condition |
	outer_condition and_or outer_condition_list
;

inner_condition:
	inner_column comparison_op inner_value |
	inner_column BETWEEN inner_value AND inner_value |
	inner_column IS not NULL
;

outer_condition:
	outer_column comparison_op outer_value |
	outer_column BETWEEN outer_value AND outer_value |
	outer_column IS not NULL |
	outer_column = return_one_one |
	outer_column not IN return_one_many |
	not EXISTS return_one_many 
;

outer_value:
	outer_column | outer_column | value | return_one_one
;

inner_outer_condition:
	inner_outer_column comparison_op inner_outer_value |
	inner_outer_column BETWEEN inner_outer_value AND inner_outer_value |
	inner_outer_column IS not NULL
;

inner_outer_column:
	inner_column | outer_column
;

return_one_one:
	( SELECT inner_column FROM inner_join_list WHERE inner_outer_condition_list ORDER BY 1 LIMIT one_zero ) |
	( SELECT inner1 . f1 additional_expression FROM inner_join_list WHERE inner_outer_condition_list ORDER BY 1 LIMIT one_zero )
;

one_zero:
	1 | 1 | 1 | 1 | 0
;

return_one_many:
	( SELECT distinct inner_column FROM inner_join_list WHERE inner_outer_condition_list )
;

return_two_many:
	( SELECT distinct inner_column AS f1 , inner_column AS f2 FROM inner_join_list WHERE inner_outer_condition_list )
;

derived_table:
	( SELECT distinct inner_column AS f1 , inner_column AS f2 FROM inner_join_list WHERE inner_condition_list )
;

inner_value:
	value | inner_column
;

outer_value:
	value | outer_column
;

inner_outer_value:
	value | inner_outer_column
;

and_or:
	AND | AND | AND | AND | OR
;

comparison_op:
	= | = | = | = | > | <
;

value:
	1 | 0 | _digit
;

not:
	| NOT
;

outer_column:
	outer_relation . column_name additional_expression
;

inner_column:
	inner_relation . column_name additional_expression
;

additional_expression:
	| | + 1
;

any_column:
	any_relation . column_name additional_expression
;

outer_relation:
	outer1 | outer2
;

inner_relation:
	inner1 | inner2
;

any_relation:
	inner_relation | outer_relation
;

table_name:
	t1 | t2 | pk1 | pk2
;

column_name:
	f1 | f2
;

distinct:
	DISTINCT
;
