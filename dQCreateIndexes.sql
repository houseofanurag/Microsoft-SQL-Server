-- Generate DDL for creating indexes
WITH Indexes AS (
    SELECT
        SCHEMA_NAME(t.schema_id) AS SchemaName,
        t.name AS TableName,
        i.name AS IndexName,
        CASE 
            WHEN i.is_unique = 1 THEN 'UNIQUE ' 
            ELSE '' 
        END AS UniquePart,
        CASE 
            WHEN i.type = 1 THEN 'CLUSTERED ' 
            ELSE 'NONCLUSTERED ' 
        END AS ClusteredPart,
        STRING_AGG(
            QUOTENAME(c.name) + 
            CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END,
            ', '
        ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
    FROM sys.indexes AS i
    INNER JOIN sys.tables AS t ON i.object_id = t.object_id
    INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN sys.columns AS c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE i.index_id > 0 -- Exclude heaps
      AND i.is_primary_key = 0 -- Exclude primary key indexes
      AND OBJECTPROPERTY(t.object_id, 'IsMsShipped') = 0 -- Exclude system tables
      AND NOT (SCHEMA_NAME(t.schema_id) = 'dbo' AND t.name = 'sysdiagrams')
    GROUP BY SCHEMA_NAME(t.schema_id), t.name, i.name, i.is_unique, i.type
)
SELECT 
    'IF EXISTS (SELECT 1 FROM sys.tables WHERE SCHEMA_NAME(schema_id) = ''' 
    + SchemaName + ''' AND name = ''' + TableName + ''') 
    AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('''
    + SchemaName + '.' + TableName + ''') AND name = ''' + IndexName + ''')
BEGIN
    CREATE ' + UniquePart + ClusteredPart + 'INDEX ' + QUOTENAME(IndexName) + 
    ' ON ' + QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) + ' (' + Columns + ')
END;'
AS DynamicSQL
FROM Indexes
ORDER BY SchemaName, TableName, IndexName;
