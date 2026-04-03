-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl   process_credits_history_sql
--
--  exec etl.base_etl_process_credits_history_sql
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
 FROM [C1-VSR-SQL05].[MFO_NIGHT01].[dbo].[Документ_ГП_Договор] dog
 left join [C1-VSR-SQL05].[MFO_NIGHT01].[dbo].[Справочник_ГП_КредитныеПродукты] pro on pro.ссылка=dog.[КредитныйПродукт]
 where Дата>='4016-03-01 00:00:00.000'

*/
-- =============================================
CREATE procedure [etl].[base_etl_process_credits_history_sql] @start_date datetime
,                                                            @end_date datetime
as
begin

	SET NOCOUNT ON;
	--log
	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	set @params= N' start_date='+cast(FORMAT (@start_date, 'dd.MM.yyyy HH:mm:ss ')
	as nvarchar(32))+'<br />'
	+N' end_date='+cast(FORMAT (@end_date, 'dd.MM.yyyy HH:mm:ss ')
	as nvarchar(32))
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      @params
	begin try
	
	declare @insertedRows int=0
	declare @result nvarchar(max)=''


  
/*
select * into dwh_new_dev.dbo.credit_statuses from dwh_new.dbo.credit_statuses
select * into dwh_new_dev.dbo.credits_history from dwh_new.dbo.credits_history
select *  from dbo.credits_history where created >'20190301' order by external_link,created

*/

	insert into dbo.credits_history ( external_link, credit_id, stage_time, stage_time_num, verifier, status, created )
	select r.external_link                              
	,      r.id                                          as credit_id
	,      creation_date                                 as stage_time
	,      cast(format(creation_date,'yyyyMMdd') as int)    stage_time_num
	,      v.id                                          as verifier
	,      s.id                                          as status
	,      CURRENT_TIMESTAMP                                created
	from      staging.credits_history rh
	join      credits                 r  on r.external_link = rh.external_link
	left join credit_statuses         s  on Lower(s.name) = Lower(rh.status)
	left join verifiers               v  on Lower(v.name) = Lower(rh.verifier)
	where creation_date between @start_date and @end_date
		and rh.external_link<>0x0000000000000000000000000000000000000000000000000000000000000000
	set @insertedRows=@@ROWCOUNT


	set @result=N' Results:<br /><br />'

	set @result=@result+'<br />Inserted: '+format(@insertedRows,'0')+'<br />'


--	select @result



	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	,                                      @result
	end try
	begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch
end





