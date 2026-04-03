create   proc dbo.[Трафик МТС]		
as
begin
		
drop table if exists ##t11		
		
DECLARE @ReturnCode int, @ReturnMessage varchar(8000)		
EXEC Stg.dbo.ExecLoadExcel		
	@PathName = '\\10.196.41.14\DWHFiles\Analytics\AdHoc\',	
	@FileName = 'Базы МТС с датой загрузки.xlsx',	
	@SheetName = 'Детали$',	
	@TableName = '##t11', --'files.TestFile1',	
	@isMoveFile = 0,	
	@ReturnCode = @ReturnCode OUTPUT,	
	@ReturnMessage = @ReturnMessage OUTPUT	
SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage		
		
		
;		
with v as (		
		
select distinct getdate() dt,  cast(База as date) База , cast(cast(Мобильный as bigint) as nvarchar(10)) Мобильный from ##t11 ф		
)		
		
  select distinct dt , 'Выдачи',  Мобильный, b.Номер ,b.isinstallment ,b.[Канал от источника], b.[Верификация КЦ], b.[Заем выдан], b.[Выданная сумма], b.[Вид займа] from v 		
  join	reports.dbo.dm_factor_analysis_001 b on v.Мобильный=b.Телефон  and b.[Заем выдан]>=v.База	and b.[Вид займа]='Первичный'
  order by 	b.[Заем выдан]	
--#ИМЯ?		
--

;		
with v as (		
		
select distinct getdate() dt,  cast(База as date) База , cast(cast(Мобильный as bigint) as nvarchar(10)) Мобильный from ##t11 ф		
)	
select distinct dt,  'Заявки',  Мобильный, b.Номер,b.[Канал от источника], b.[Верификация КЦ], b.[Заем выдан], b.[Вид займа] from v 		
join	reports.dbo.dm_factor_analysis_001 b on v.Мобильный=b.Телефон  and b.[Верификация КЦ]>=v.База	--and b.[Вид займа]='Первичный' 
order by 2, 4, 3		
		
		
		
		
	end
		
		