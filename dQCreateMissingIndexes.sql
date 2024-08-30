with fcc as
(
    select 
            sch1.name                                as parent_schema_name,
            object_name(fkc.parent_object_id)        as parent_table_name,
            object_name(fkc.constraint_object_id)    as constraint_name,
            sch2.name                                as referenced_schema,
            object_name(fkc.referenced_object_id)    as referenced_table_name,
            substring(
                        (    select ',' 
                                + rtrim(col_name(fc.parent_object_id,parent_column_id)) as [data()]
                            from sys.foreign_key_columns as fc with (nolock)
                            inner join sys.foreign_keys as fk with (nolock) on fc.constraint_object_id = fk.[object_id]
                            and fc.constraint_object_id = fkc.constraint_object_id
                            order by fc.constraint_column_id
                            for xml path('')
                        ), 2, 8000)                    as parent_columns,
            substring(
                        (    select ',' 
                                + rtrim(col_name(fc.referenced_object_id,referenced_column_id)) as [data()]
                            from sys.foreign_key_columns as fc with (nolock)
                            inner join sys.foreign_keys as fk with (nolock) on fc.constraint_object_id = fk.[object_id]
                            and fc.constraint_object_id = fkc.constraint_object_id
                            order by constraint_column_id
                            for xml path('')
                        ), 2, 8000)                    as referenced_columns
    from        sys.foreign_key_columns        as fkc    with (nolock)
    inner join    sys.objects                    as obj1 with (nolock) on fkc.parent_object_id        =    obj1.[object_id]
    inner join    sys.tables                    as tbl1 with (nolock) on tbl1.[object_id]            =    obj1.[object_id]
    inner join    sys.schemas                    as sch1 with (nolock) on sch1.[schema_id]            =    tbl1.[schema_id]
    inner join    sys.objects                    as obj2 with (nolock) on fkc.referenced_object_id    =    obj2.[object_id]
    inner join    sys.tables                    as tbl2    with (nolock) on tbl2.[object_id]            =    obj2.[object_id]
    inner join    sys.schemas                    as sch2 with (nolock) on sch2.[schema_id]            =    tbl2.[schema_id]
    where        obj1.type = 'U' 
                and 
                obj2.type = 'U'
    group by    obj1.[schema_id],
                obj2.[schema_id],
                fkc.parent_object_id,
                constraint_object_id,
                referenced_object_id,
                sch1.name,
                sch2.name
),
idxcols as
(
    select 
            s.name                        as schemaname,
            object_name(t.[object_id])    as objectname,
            substring(
                        ( 
                            select ',' 
                                + rtrim(ac.name) 
                            from sys.tables                    as st
                            inner join sys.indexes            as ix on st.[object_id] = ix.[object_id]
                            inner join sys.index_columns    as ic on ix.[object_id] = ic.[object_id] and ix.[index_id]    = ic.[index_id] 
                            inner join sys.all_columns        as ac on st.[object_id] = ac.[object_id] and ic.[column_id] = ac.[column_id]
                            where    i.[object_id] = ix.[object_id] 
                                    and 
                                    i.index_id = ix.index_id 
                                    and 
                                    ic.is_included_column = 0
                            order by ac.column_id
                            for xml path('')
                        ), 2, 8000 ) as keycols
    from        sys.indexes        as i
    inner join    sys.tables        as t    on    t.[object_id]    =    i.[object_id]
    inner join    sys.schemas        as s    on    s.[schema_id]    =    t.[schema_id]
    where    i.[type] in (1,2,5,6) 
            and 
            i.is_unique_constraint = 0
            and 
            t.is_ms_shipped = 0
)
select    fcc.constraint_name,
        fcc.parent_schema_name +'.' + fcc.parent_table_name as parent_table,
        fcc.referenced_schema + '.' + fcc.referenced_table_name as reference_table,
        fcc.parent_columns,
        fcc.referenced_columns,
        N'CREATE NONCLUSTERED INDEX idx_'    +
            fcc.referenced_table_name        +    
            '_'                                +
            fcc.constraint_name                +
            N' ON '                            +
            fcc.parent_schema_name            +
            '.'                                + 
            fcc.parent_table_name            +
            N'('                            +
            fcc.referenced_columns            +
            N');'    as ddl_create
from fcc
where not exists ( SELECT 1 FROM idxcols 
                    WHERE fcc.parent_schema_name = idxcols.schemaName
                        AND fcc.parent_table_name = idxcols.objectName 
                        AND REPLACE(fcc.parent_columns,'' ,'') = idxcols.KeyCols)