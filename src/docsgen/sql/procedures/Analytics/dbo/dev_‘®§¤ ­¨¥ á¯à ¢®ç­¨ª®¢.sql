CREATE proc [dbo].[Создание справочников]
as
begin
 /*
create table dbo.calendar (date date)
declare @a date = '20100101' 
while @a<= '20400101' 
begin
insert into  dbo.calendar
select @a
set @a = dateadd(day, 1, @a)
end

--select * from dbo.calendar




--drop table if exists analytics.dbo.[Учтенные заявки с превышением ПСК бэкап]
--select * into analytics.dbo.[Учтенные заявки с превышением ПСК бэкап] from analytics.dbo.[Учтенные заявки с превышением ПСК]
drop table if exists analytics.dbo.[Учтенные заявки с превышением ПСК]
select * into analytics.dbo.[Учтенные заявки с превышением ПСК]
from (
select cast('21111600152004' as nvarchar(max)) num union all
select cast('21111500151894' as nvarchar(max)) num --union all
) z


*/

 /*
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

select * from ##t11

--drop table if exists [Трафик МТС таблица]
--select база, format(мобильный, '0') мобильный  into [Трафик МТС таблица] from ##t11

	   */

 /*
   drop table if exists ##t11		
		
DECLARE @ReturnCode int, @ReturnMessage varchar(8000)		
EXEC Stg.dbo.ExecLoadExcel		
	@PathName = '\\10.196.41.14\DWHFiles\Analytics\AdHoc\',	
	@FileName = 'Базы Союз с датой загрузки.xlsx',	
	@SheetName = 'Детали$',	
	@TableName = '##t11', --'files.TestFile1',	
	@isMoveFile = 0,	
	@ReturnCode = @ReturnCode OUTPUT,	
	@ReturnMessage = @ReturnMessage OUTPUT	
SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage		

										   --select * from ##t11
--drop table if exists [Трафик Союз таблица]
--select база, format(мобильный, '0') мобильный  into [Трафик Союз таблица] from ##t11

	   */


 return

end