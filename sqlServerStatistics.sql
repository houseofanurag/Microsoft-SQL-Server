-- Get index usage statistics
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.avg_fragmentation_in_percent AS Fragmentation,
    s.page_count AS PageCount
FROM sys.indexes AS i
INNER JOIN sys.tables AS t ON i.object_id = t.object_id
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), i.object_id, i.index_id, NULL, 'LIMITED') AS s
WHERE i.type > 0
ORDER BY s.avg_fragmentation_in_percent DESC;


-- Query to get statistics information, including the last updated date
SELECT 
    t.name AS TableName,
    s.name AS StatisticName,
    st.last_updated AS LastUpdated
FROM sys.stats AS s
INNER JOIN sys.tables AS t
    ON s.object_id = t.object_id
CROSS APPLY sys.dm_db_stats_properties(t.object_id, s.stats_id) AS st
ORDER BY st.last_updated DESC;


-- Query to get view definitions and their complexity
SELECT 
    v.name AS ViewName,
    OBJECT_DEFINITION(v.object_id) AS ViewDefinition,
    LEN(OBJECT_DEFINITION(v.object_id)) AS DefinitionLength
FROM sys.views AS v
WHERE LEN(OBJECT_DEFINITION(v.object_id)) > 1000 -- Length threshold for complexity
ORDER BY LEN(OBJECT_DEFINITION(v.object_id)) DESC;


-- Query to get general index information
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique_constraint AS IsUniqueConstraint
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
ORDER BY t.name, i.name;

