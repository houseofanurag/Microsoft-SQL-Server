
-- Query to get missing Foreign keys

SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS Where COLUMN_NAME like '%id' AND  COLUMN_NAME <> 'Id' AND DATA_TYPE = 'int'
    AND TABLE_NAME + COLUMN_NAME NOT IN (SELECT OBJECT_NAME(fk.parent_object_id) + cpa.name
                                        FROM   sys.foreign_keys fk
                                        INNER JOIN sys.foreign_key_columns fkc ON  fkc.constraint_object_id = fk.object_id
                                        INNER JOIN sys.columns cpa ON  fkc.parent_object_id = cpa.object_id AND fkc.parent_column_id = cpa.column_id 
                                        INNER JOIN sys.columns cref ON  fkc.referenced_object_id = cref.object_id AND fkc.referenced_column_id = cref.column_id)
    order by TABLE_NAME, COLUMN_NAME;
	
-- Get missing Foreign Keys
WITH ForeignKeyColumns AS (
    SELECT 
        OBJECT_NAME(fk.parent_object_id) AS TableName,
        cpa.name AS ColumnName
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc 
        ON fkc.constraint_object_id = fk.object_id
    INNER JOIN sys.columns cpa 
        ON fkc.parent_object_id = cpa.object_id 
        AND fkc.parent_column_id = cpa.column_id 
    INNER JOIN sys.columns cref 
        ON fkc.referenced_object_id = cref.object_id 
        AND fkc.referenced_column_id = cref.column_id
)
SELECT 
    c.TABLE_NAME, 
    c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME
WHERE 
    c.COLUMN_NAME LIKE '%id' 
    AND c.COLUMN_NAME <> 'Id' 
    AND c.DATA_TYPE = 'int'
    AND c.TABLE_NAME + '.' + c.COLUMN_NAME NOT IN (
        SELECT TableName + '.' + ColumnName
        FROM ForeignKeyColumns
    )
    AND c.COLUMN_NAME IN ('SERVICE_ID','APPLICATION_ID','APPLICANT_ID','ENTITY_ID')
    AND t.TABLE_TYPE = 'BASE TABLE' -- Excludes views
    AND t.TABLE_NAME NOT LIKE '%_backup%' -- Excludes backup tables if they follow this naming convention
    AND t.TABLE_NAME NOT LIKE '%_bkp%' -- Excludes backup tables if they follow this naming convention
ORDER BY 
    c.TABLE_NAME, 
    c.COLUMN_NAME;



-- Identify existing foreign key relationships including both source and target information
SELECT 
    src_table.name AS SourceTableName,
    src_column.name AS SourceColumnName,
    tgt_table.name AS TargetTableName,
    tgt_column.name AS TargetColumnName
FROM sys.foreign_key_columns fk_columns
INNER JOIN sys.columns src_column
    ON fk_columns.parent_object_id = src_column.object_id
    AND fk_columns.parent_column_id = src_column.column_id
INNER JOIN sys.tables src_table
    ON src_column.object_id = src_table.object_id
INNER JOIN sys.columns tgt_column
    ON fk_columns.referenced_object_id = tgt_column.object_id
    AND fk_columns.referenced_column_id = tgt_column.column_id
INNER JOIN sys.tables tgt_table
    ON tgt_column.object_id = tgt_table.object_id
WHERE 
    src_column.name LIKE '%id'
    AND src_column.name <> 'Id'
    AND src_column.system_type_id = 56 -- int data type
    AND src_column.name IN ('SERVICE_ID', 'APPLICATION_ID', 'APPLICANT_ID', 'ENTITY_ID')
ORDER BY 
    src_table.name,
    src_column.name;



-- Suggest potential target columns for missing foreign keys, ensuring uniqueness
SELECT DISTINCT
    mf.SourceTableName,
    mf.SourceColumnName,
    efk.TargetTableName,
    efk.TargetColumnName
FROM (
    SELECT 
        src_table.name AS SourceTableName,
        src_column.name AS SourceColumnName
    FROM sys.columns src_column
    INNER JOIN sys.tables src_table
        ON src_column.object_id = src_table.object_id
    LEFT JOIN sys.foreign_key_columns fk_columns
        ON src_column.object_id = fk_columns.parent_object_id
        AND src_column.column_id = fk_columns.parent_column_id
    WHERE 
        src_column.name LIKE '%id'
        AND src_column.name <> 'Id'
        AND src_column.system_type_id = 56 -- int data type
        AND src_column.name IN ('SERVICE_ID', 'APPLICATION_ID', 'APPLICANT_ID', 'ENTITY_ID')
        AND src_table.name NOT LIKE '%_backup%' 
        AND src_table.name NOT LIKE '%_bkp%'
        AND fk_columns.parent_object_id IS NULL
) AS mf
INNER JOIN (
    SELECT 
        src_column.name AS SourceColumnName,
        tgt_table.name AS TargetTableName,
        tgt_column.name AS TargetColumnName
    FROM sys.foreign_key_columns fk_columns
    INNER JOIN sys.columns src_column
        ON fk_columns.parent_object_id = src_column.object_id
        AND fk_columns.parent_column_id = src_column.column_id
    INNER JOIN sys.tables tgt_table
        ON fk_columns.referenced_object_id = tgt_table.object_id
    INNER JOIN sys.columns tgt_column
        ON fk_columns.referenced_object_id = tgt_column.object_id
        AND fk_columns.referenced_column_id = tgt_column.column_id
) AS efk
    ON mf.SourceColumnName LIKE '%' + efk.SourceColumnName -- Assuming naming convention similarity
    AND mf.SourceTableName <> efk.TargetTableName -- Exclude columns from the same table
ORDER BY 
    mf.SourceTableName,
    mf.SourceColumnName,
    efk.TargetTableName,
    efk.TargetColumnName;
