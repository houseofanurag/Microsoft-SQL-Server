-- Query to get the DDL for all tables
WITH TableInfo AS (
    SELECT
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName,
        ty.name AS DataType,
        c.max_length,
        c.precision,
        c.scale,
        c.is_nullable,
        c.column_id,
        CASE 
            WHEN pk.column_id IS NOT NULL THEN 'PRIMARY KEY'
            ELSE ''
        END AS ConstraintType
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.columns c ON t.object_id = c.object_id
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    LEFT JOIN sys.index_columns pk ON t.object_id = pk.object_id AND c.column_id = pk.column_id AND pk.index_id = 1 -- Assuming primary key index
    WHERE t.is_ms_shipped = 0
)
SELECT 
    'CREATE TABLE ' + QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ' (' + CHAR(10) +
    STRING_AGG(
        '    ' + QUOTENAME(ColumnName) + ' ' + 
        DataType + 
        CASE 
            WHEN DataType IN ('varchar', 'char', 'nvarchar', 'nchar') THEN '(' + CAST(max_length / CASE DataType WHEN 'varchar' THEN 1 WHEN 'nvarchar' THEN 2 ELSE 1 END AS VARCHAR(10)) + ')'
            WHEN DataType IN ('decimal', 'numeric') THEN '(' + CAST(precision AS VARCHAR(10)) + ',' + CAST(scale AS VARCHAR(10)) + ')'
            ELSE ''
        END +
        CASE WHEN is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
        CASE WHEN ConstraintType = 'PRIMARY KEY' THEN ' PRIMARY KEY' ELSE '' END
        , CHAR(10)
    ) WITHIN GROUP (ORDER BY column_id) + 
    ')' AS CreateTableDDL
FROM TableInfo
GROUP BY SchemaName, TableName
ORDER BY SchemaName, TableName;
