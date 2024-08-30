select   m.definition
from     sys.sql_modules   m
join     sys.objects       o  on o.object_id = m.object_id
join     sys.schemas       s  on s.schema_id = o.schema_id
where    o.type = 'P';