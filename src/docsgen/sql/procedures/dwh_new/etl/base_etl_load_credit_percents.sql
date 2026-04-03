-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl   load_credit_percents  
--
--  etl.base_etl_load_credit_percents   
/*
drop table dwh_new.dbo.credit_percents;
SELECT
      external_id=dog.[Номер]
     ,credit_product=dog.[КредитныйПродукт]
     ,[percent_year]= pro.[ПроцентыВГод]
      ,[percent]= case when dog.[Процентнаяставка]=0 
                    then pro.[ТекущаяСсуда] 
                    else dog.[Процентнаяставка] 
                    end  
      into dwh_new.dbo.credit_percents
 FROM [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] dog
 left join [prodsql02].[mfo].[dbo].[Справочник_ГП_КредитныеПродукты] pro on pro.ссылка=dog.[КредитныйПродукт]
 where Дата>='4016-03-01 00:00:00.000'

*/
-- =============================================
CREATE procedure   [etl].[base_etl_load_credit_percents]  

as
begin
	
	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128)	= ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure started',''
    begin try


	declare @insertedRows int=0
	declare @result nvarchar(max)=''

--drop table dbo.credit_percents;
--DWH-1764
TRUNCATE TABLE dbo.credit_percents

INSERT dbo.credit_percents
(
    external_id,
    credit_product,
    percent_year,
    [percent]
)
SELECT
      external_id=dog.[Номер]
     ,credit_product=dog.[КредитныйПродукт]
     ,[percent_year]= pro.[ПроцентыВГод]
      ,[percent]= case when dog.[Процентнаяставка]=0 
                    then pro.[ТекущаяСсуда] 
                    else dog.[Процентнаяставка] 
                    end  
      --into dbo.credit_percents
 FROM [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] dog
 left join [prodsql02].[mfo].[dbo].[Справочник_ГП_КредитныеПродукты] pro on pro.ссылка=dog.[КредитныйПродукт]
 where Дата>='4016-03-01 00:00:00.000'

set @insertedRows=@@ROWCOUNT


 set @result=N' Results:<br /><br />'
  
set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'


--select @result



exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Info','procedure finished',@result
end try
begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

    exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name,'Error','Error',@error_description
	;throw 51000, @error_description, 1
end catch
end





