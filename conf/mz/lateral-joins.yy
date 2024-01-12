
explain:
    EXPLAIN query
;

query:
    select
;

select:
    SELECT left_right_object . col_name AS f1 , left_right_object . col_name AS f2 FROM (left_select) AS left_object
    before_join
    left_or_inner_join LATERAL (SELECT col_name AS f1, col_name AS f2 FROM table_name right_where_clause ORDER BY total_order LIMIT ABS(left_ref_expr))
    AS right_object ON ( on_clause )
    after_join
;

before_join:
    left_or_right_join table_name AS before ON ( left_object . alias = before . col_name )
;

after_join:
    left_or_right_join table_name AS after ON ( right_object . alias = after . col_name )
;

col_name:
    f1 | f2
;

left_or_inner_join:
    INNER JOIN | LEFT JOIN
;

left_or_right_join:
    LEFT JOIN | RIGHT JOIN
;

table_name:
    t1 | t2 | t3 | pk1 | pk2 | pk3
;

left_right_object:
    left_object | right_object
;

left_ref_expr:
    ( SELECT col_name FROM ( select ) AS limit_subquery ORDER BY 1 asc_desc LIMIT 1 ) |
    func ( left_ref_expr ) |
    left_object . alias |
    left_ref_expr plus_minus left_ref_expr |
    _digit
;

func:
    ABS | -
;

left_select:
    select |
    SELECT distinct left_select_list FROM table_name left_where_clause |
    SELECT distinct f1, left_select_list_group_by FROM table_name left_where_clause GROUP BY f1
;

left_where_clause:
    WHERE left_where_list
;

left_where_list:
    left_where_cond |
    left_where_cond and_or left_where_cond
;

and_or:
    AND | OR
;

left_where_cond:
    col_name IS not NULL |
    col_name cmp_op col_name 
;

right_where_clause:
    WHERE right_where_list
;

right_where_list:
    right_where_cond |
    right_where_cond and_or right_where_cond
;

right_where_cond:
    left_right_col_name IS not NULL |
    left_right_col_name cmp_op left_right_col_name
;

left_right_col_name:
    left_object . alias |
    col_name
;

not:
    | NOT
;

cmp_op:
    > | < | =
;

distinct:
    | DISTINCT
;

left_select_list:
    left_select_item AS f1 , left_select_item AS f2
;

left_select_item:
    col_name
;

left_select_list_group_by:
    left_select_aggregate AS f2
;

left_select_aggregate:
    aggregate ( distinct col_name )
;

aggegate:
    MIN | MAX | COUNT | SUM
;

alias:
    f1 | f2
;

plus_minus:
    + | -
;

aggregate:
    MIN | MAX | COUNT | SUM | AVG
;

total_order:
    1 asc_desc , 2 asc_desc |
    2 asc_desc , 1 asc_desc;

asc_desc:
    ASC | DESC
;

on_clause:
   left_object . alias = right_object . alias

