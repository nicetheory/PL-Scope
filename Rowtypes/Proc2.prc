create or replace procedure Proc2 is
	lrMyRecord MyTable%rowtype;
begin
	lrMyRecord.Id := 1;

	insert into MyTable
	values lrMyRecord;

	select *
	into lrMyRecord
	from MyTable
	where rownum = 1;

	lrMyRecord.Column1 := 'My text';

	update MyTable
	set row = lrMyRecord
	where MyTable.Id = lrMyRecord.Id;

	commit;

end Proc2;
/
