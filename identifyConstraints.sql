-- Identify constraints associated with indexes
SELECT 
    i.name AS IndexName,
    t.name AS TableName,
    s.name AS SchemaName,
    ic.name AS ConstraintName,
    ic.type_desc AS ConstraintType
FROM sys.indexes i
INNER JOIN sys.objects t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.indexes i2 ON i.object_id = i2.object_id AND i.index_id = i2.index_id
LEFT JOIN sys.key_constraints ic ON i.object_id = ic.parent_object_id AND i.index_id = ic.unique_index_id
WHERE i.index_id > 0
  AND ic.type_desc IN ('PRIMARY_KEY_CONSTRAINT', 'UNIQUE_CONSTRAINT');
