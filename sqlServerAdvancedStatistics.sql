-- Query to find currently running queries and their execution times
SELECT 
    r.session_id,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.blocking_session_id,
    st.text AS QueryText
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.database_id = DB_ID() -- Current database
ORDER BY r.total_elapsed_time DESC;


SELECT TOP 25
    dm_mid.database_id AS DatabaseID,
    dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
    dm_migs.last_user_seek AS Last_User_Seek,
    OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
    'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + '_'
    + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''),', ','_'),'[',''),']','') 
    + CASE
    WHEN dm_mid.equality_columns IS NOT NULL
    AND dm_mid.inequality_columns IS NOT NULL THEN '_'
    ELSE ''
    END
    + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''),', ','_'),'[',''),']','')
    + ']'
    + ' ON ' + dm_mid.statement
    + ' (' + ISNULL (dm_mid.equality_columns,'')
    + CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns 
    IS NOT NULL THEN ',' ELSE
    '' END
    + ISNULL (dm_mid.inequality_columns, '')
    + ')'
    + ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
    FROM sys.dm_db_missing_index_groups dm_mig
    INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
    ON dm_migs.group_handle = dm_mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details dm_mid
    ON dm_mig.index_handle = dm_mid.index_handle
    WHERE dm_mid.database_ID = DB_ID()
    ORDER BY Avg_Estimated_Impact DESC;
	
SELECT r.session_id,
       st.TEXT AS batch_text,
       qp.query_plan AS 'XML Plan',
       r.start_time,
       r.status,
       r.total_elapsed_time
FROM sys.dm_exec_requests AS r
     CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
     CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
WHERE r.database_id = DB_ID()
ORDER BY cpu_time DESC;