-- CTE to get table columns and their details
WITH TableColumns AS (
    SELECT 
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName,
        ty.name AS DataType,
        c.max_length,
        c.precision,
        c.scale,
        c.is_nullable,
        c.column_id
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.columns c ON t.object_id = c.object_id
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE t.is_ms_shipped = 0
),
-- CTE to get primary key details
PrimaryKeys AS (
    SELECT 
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName
    FROM sys.key_constraints k
    INNER JOIN sys.index_columns ic ON k.parent_object_id = ic.object_id AND k.unique_index_id = ic.index_id
    INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    INNER JOIN sys.tables t ON k.parent_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE k.type = 'PK'
),
-- CTE to get foreign key details
ForeignKeys AS (
    SELECT 
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName,
        fk.name AS FKName,
        ref.name AS RefTableName,
        refc.name AS RefColumnName
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
    INNER JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.columns refc ON fkc.referenced_object_id = refc.object_id AND fkc.referenced_column_id = refc.column_id
    INNER JOIN sys.tables ref ON refc.object_id = ref.object_id
),
-- CTE to get default constraints details
DefaultConstraints AS (
    SELECT 
        s.name AS SchemaName,
        t.name AS TableName,
        c.name AS ColumnName,
        dc.definition AS DefaultDefinition
    FROM sys.default_constraints dc
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
),
-- Aggregated column definitions
ColumnDefinitions AS (
    SELECT 
        tc.SchemaName,
        tc.TableName,
        STRING_AGG(
            '    ' + QUOTENAME(tc.ColumnName) + ' ' + 
            tc.DataType +
            CASE 
                WHEN tc.DataType IN ('varchar', 'char', 'nvarchar', 'nchar') THEN '(' + CAST(tc.max_length / CASE tc.DataType WHEN 'varchar' THEN 1 WHEN 'nvarchar' THEN 2 ELSE 1 END AS VARCHAR(10)) + ')'
                WHEN tc.DataType IN ('decimal', 'numeric') THEN '(' + CAST(tc.precision AS VARCHAR(10)) + ',' + CAST(tc.scale AS VARCHAR(10)) + ')'
                ELSE ''
            END +
            CASE WHEN tc.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
            COALESCE(' ' + dc.DefaultDefinition, '') + -- Default constraints
            CASE 
                WHEN pk.ColumnName IS NOT NULL THEN ' PRIMARY KEY' 
                ELSE ''
            END,
            CHAR(10)
        ) WITHIN GROUP (ORDER BY tc.column_id) AS DDL
    FROM TableColumns tc
    LEFT JOIN PrimaryKeys pk ON tc.SchemaName = pk.SchemaName AND tc.TableName = pk.TableName AND tc.ColumnName = pk.ColumnName
    LEFT JOIN DefaultConstraints dc ON tc.SchemaName = dc.SchemaName AND tc.TableName = dc.TableName AND tc.ColumnName = dc.ColumnName
    GROUP BY tc.SchemaName, tc.TableName
),
-- Aggregated foreign key constraints
ForeignKeyDefinitions AS (
    SELECT 
        fk.SchemaName,
        fk.TableName,
        STRING_AGG(
            CHAR(10) + '    FOREIGN KEY (' + QUOTENAME(fk.ColumnName) + ') REFERENCES ' + QUOTENAME(fk.RefTableName) + '(' + QUOTENAME(fk.RefColumnName) + ')',
            CHAR(10)
        ) WITHIN GROUP (ORDER BY fk.ColumnName) AS DDL
    FROM ForeignKeys fk
    GROUP BY fk.SchemaName, fk.TableName
)
-- Final select to combine all parts and generate the CREATE TABLE DDL
SELECT 
    'CREATE TABLE ' + QUOTENAME(tc.SchemaName) + '.' + QUOTENAME(tc.TableName) + ' (' + CHAR(10) +
    cd.DDL +
    COALESCE(fk.DDL, '') +
    ');' AS CreateTableDDL
FROM TableColumns tc
-- Join with aggregated column definitions and foreign key definitions
LEFT JOIN ColumnDefinitions cd ON tc.SchemaName = cd.SchemaName AND tc.TableName = cd.TableName
LEFT JOIN ForeignKeyDefinitions fk ON tc.SchemaName = fk.SchemaName AND tc.TableName = fk.TableName
GROUP BY tc.SchemaName, tc.TableName, cd.DDL, fk.DDL
ORDER BY tc.SchemaName, tc.TableName;
