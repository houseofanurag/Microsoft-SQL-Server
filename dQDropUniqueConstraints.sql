-- Generate DROP CONSTRAINT statements
WITH Constraints AS (
    SELECT
        SCHEMA_NAME(t.schema_id) AS SchemaName,
        t.name AS TableName,
        ic.name AS ConstraintName
    FROM sys.indexes i
    INNER JOIN sys.objects t ON i.object_id = t.object_id
    INNER JOIN sys.key_constraints ic ON i.object_id = ic.parent_object_id AND i.index_id = ic.unique_index_id
    WHERE i.index_id > 0
      AND ic.type_desc IN ('UNIQUE_CONSTRAINT')
)
SELECT 
    'ALTER TABLE ' + QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) +
    ' DROP CONSTRAINT ' + QUOTENAME(ConstraintName) + ';' AS DropConstraintSQL
FROM Constraints
ORDER BY SchemaName, TableName, ConstraintName;
