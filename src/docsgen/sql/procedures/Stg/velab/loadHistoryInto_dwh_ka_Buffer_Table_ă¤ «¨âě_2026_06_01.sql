-- Usage: запуск процедуры с параметрами
-- EXEC [velab].[loadHistoryInto_dwh_ka_Buffer_Table] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [velab].[loadHistoryInto_dwh_ka_Buffer_Table]
as
begin
	set nocount on 

	EXECUTE AS LOGIN = 'sa';
	drop table if exists #t_v_ka
	select * 
		into #t_v_ka
	from stg._Collection.v_ka
	if exists (select top(1) 1 from #t_v_ka)
	begin
	
		delete from  OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
		   'SELECT *
	  FROM collection.dbo.dwh_ka_buffer') 

	  insert into OPENROWSET('SQLNCLI', 'Server=C2-VSR-CL-SQL.cm.carmoney.ru;Trusted_Connection=yes;',  
		   'SELECT *
	  FROM collection.dbo.dwh_ka_buffer') 
	  select * from #t_v_ka
  end
end