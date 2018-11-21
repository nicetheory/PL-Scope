select * from v$version;

drop table mytable purge;
create table MyTable(
    id number, 
	column1 varchar2(50)
);

-- create procedure
drop procedure myprocedure;

select --s.signature,
 s.type,
 s.object_name,
 s.object_type,
 --s.usage_id,
 s.line,
 s.sql_id,
 s.has_into_record,
 s.text
from   user_statements s
order by object_name, line;

select * from user_identifiers
where object_name = 'PROC1'
and type = 'COLUMN'
;

with MyColumn as (
  select signature
  from all_identifiers i
  where name = 'COLUMN1'
  and type = 'COLUMN'
  and object_name = 'MYTABLE'
  and object_type = 'TABLE'
)
select * 
from user_identifiers i
join MyColumn on (i.signature = MyColumn.signature)
where i.name = 'COLUMN1'
and i.type = 'COLUMN'
and i.object_name = 'PROC1'
order by line
;
