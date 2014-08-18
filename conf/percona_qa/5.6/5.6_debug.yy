query:
        select | select | insert | insert | delete | delete | replace | update | transaction |
        alter | views | set | flush | proc_func | outfile_infile | update_multi | kill_idle | query_cache |
        ext_slow_query_log | user_stats | drop_create_table | table_comp | table_comp | optimize_table | 
        bitmap | bitmap | archive_logs | thread_pool | max_stmt_time | locking | prio_shed |
        cleaner | preflush | toku_clustering_key | toku_clustering_key | i_s_toku | audit_plugin | binlog_event | i_s_buffer_pool_stats | prio_shed_dbg | 
        innodb_prio_dbg ;

prio_shed_dbg:
        SELECT @@GLOBAL.innodb_sched_priority_io |
        SET GLOBAL innodb_sched_priority_io = zero_to_forty |
        SELECT @@GLOBAL.innodb_sched_priority_master |
        SET GLOBAL innodb_sched_priority_master = zero_to_forty |
        SELECT @@GLOBAL.innodb_sched_priority_purge |
        SET GLOBAL innodb_sched_priority_purge = zero_to_forty ;

innodb_prio_dbg:
        SET GLOBAL innodb_prio_set = moreoff |
        SHOW scope VARIABLES LIKE 'INNODB_PRIORITY_PURGE' |
        SHOW scope VARIABLES LIKE 'INNODB_PRIORITY_IO' |
        SHOW scope VARIABLES LIKE 'INNODB_PRIORITY_CLEANER' |
        SHOW scope VARIABLES LIKE 'INNODB_PRIORITY_MASTER' ;

innodb_prio_set:
        INNODB_PRIORITY_PURGE | INNODB_PRIORITY_IO | INNODB_PRIORITY_CLEANER | INNODB_PRIORITY_MASTER ;

moreoff:
        0 | 0 | 0 | 0 | 1 ;
