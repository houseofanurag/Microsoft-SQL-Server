SELECT OBJECT_SCHEMA_NAME(T.[object_id],DB_ID()) AS [Schema],  
  T.[name] AS [table_name], I.[name] AS [index_name], AC.[name] AS [column_name],  
  I.[type_desc], I.[is_unique], I.[data_space_id], I.[ignore_dup_key], I.[is_primary_key], 
  I.[is_unique_constraint], I.[fill_factor],    I.[is_padded], I.[is_disabled], I.[is_hypothetical], 
  I.[allow_row_locks], I.[allow_page_locks], IC.[is_descending_key], IC.[is_included_column] 
FROM sys.[tables] AS T  
  INNER JOIN sys.[indexes] I ON T.[object_id] = I.[object_id]  
  INNER JOIN sys.[index_columns] IC ON I.[object_id] = IC.[object_id] 
  INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id] 
WHERE T.[is_ms_shipped] = 0 AND I.[type_desc] <> 'HEAP' 
ORDER BY T.[name], I.[index_id], IC.[key_ordinal] 