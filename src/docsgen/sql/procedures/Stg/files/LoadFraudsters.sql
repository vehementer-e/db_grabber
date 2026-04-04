
-- Usage: запуск процедуры с параметрами
-- EXEC files.LoadFraudsters;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE    procedure files.LoadFraudsters
as
begin

 set nocount on
-- select * from dwh_new.dbo.fraudsters
  
  
  delete f
    from [files].[fraudsters_buffer] b  
         inner join dwh_new.dbo.fraudsters f on try_cast(f.external_id as decimal(38,0))=try_cast(b.external_id as decimal(38,0))

insert into dwh_new.dbo.fraudsters ([external_id],[created])
SELECT distinct try_cast([external_id]  as decimal(38,0))
      ,[created]
  FROM [files].[fraudsters_buffer] where external_id is not null


  select 0
end
