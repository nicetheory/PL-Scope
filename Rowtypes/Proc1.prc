create or replace procedure Proc1 is
	lrMyRecord MyTable%rowtype;
begin
	lrMyRecord.Id := 1;

	insert into MyTable (Id, Column1)
	values (lrMyRecord.Id, lrMyRecord.Column1);

	select t.Id, t.Column1
	into lrMyRecord
	from MyTable t
	where rownum = 1;

	lrMyRecord.Column1 := 'My text';

	update MyTable t
	set t.column1 = lrMyRecord.Column1
	where t.Id = lrMyRecord.Id;

	commit;

end Proc1;
/
