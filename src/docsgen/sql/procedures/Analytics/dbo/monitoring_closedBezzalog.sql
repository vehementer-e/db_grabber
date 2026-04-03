

--exec  [_monitoring].[closed_inst]

create proc  [monitoring_closedBezzalog]
 
as

begin

declare @datet___ datetime    =  getdate()  

if   (datepart(hour, @datet___) = 21 and datepart(minute, @datet___) >=5 ) or datepart(hour, @datet___)>21
return	   

DROP TABLE	IF EXISTS #t   

SELECT top 100
	     a.Код		
		,a.Сумма
		,case when try_cast(a.[Телефон договор CMR] as bigint) is not null then  a.[Телефон договор CMR] else  '' end [Телефон договор CMR]
		,a.Погашен
		,getdate() dt

		into #t
	FROM v_Справочник_Договоры		a
	left join _monitoring.[closed_inst_log] b on a.Код=b.Код
	WHERE cast(a.Погашен as date) = cast(@datet___  as date)
		AND a.isInstallment = 1
		AND b.Код is null
		and datediff(minute, a.Погашен, @datet___  )>60
		and datepart(hour, a.Погашен   )<20


		  --select * from #t
		  --order by 4



if (select count(*) from #t) = 0 return


--delete from _monitoring.[closed_inst_log] 

 
drop table if exists  #bl
 
select distinct cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 

drop table if exists  #t1
select a.*, [Текст] = cast(Код as nvarchar(max))+' - '+	 format(try_cast(a.[Телефон договор CMR] as bigint) ,'0') +case when b.UF_PHONE is not null then '(в чс)' else '' end  + ' '+ format(Погашен, 'dd-MMM HH:mm')
, format(Погашен, 'yyyy-MM-dd HH:mm') [Дата погашения]
,format(try_cast(a.[Телефон договор CMR] as bigint) ,'0') + case when b.UF_PHONE is not null then '(в чс)' else '' end [Телефон]
,cast(Код as nvarchar(max))  [Номер договора]
into  #t1
from 
#t a left join 	#bl b on a.[Телефон договор CMR] =b.UF_PHONE
 

--drop table if exists _monitoring.[closed_inst_log]
--select * into _monitoring.[closed_inst_log] from #t where 1=0

--declare @text  nvarchar(max) = ( select  
--  STRING_AGG( [Текст], char(10))	  within group(order by 	Погашен)
--  from 	 #t1	   ) 
--declare @python_command  nvarchar(max) = 'rocket.send_message_to_rocket(rocket.TEST_ROOM_ID, message="""'+@text +'""")'
--  exec exec_python @python_command, 1

 DECLARE @tableHTML NVARCHAR(MAX)

 EXEC spQueryToHtmlTable 'select [Номер договора], [Телефон], [Дата погашения] from #t1'
	,'order by [Дата погашения]'
	,@tableHTML OUTPUT
--	select 	 @tableHTML


if @tableHTML is  null	
begin
RAISERROR ('spQueryToHtmlTable error @tableHTML is null', -- Message text.
               16, -- Severity.
               1 -- State.
			   ,
			   50000
               );
return
end


 
EXEC msdb.dbo.sp_send_dbmail 
@profile_name = 'Default',  
@recipients= 'p.ilin@techmoney.ru; rgkc@carmoney.ru',
@subject = 'Закрытые клиенты инстоллмент за сегодня',  
@body = @tableHTML,  
@body_format = 'HTML' 

insert into _monitoring.[closed_inst_log]
select Код		
,Сумма
,[Телефон договор CMR]
,Погашен
, dt 
from #t


; 
	 

--if (select count(*) from #t) = 20 exec [_monitoring].[closed_inst]


end



 