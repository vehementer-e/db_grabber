
--exec dbo.checkRequestStateDurationByNameAndNotSource 540,'Предварительное одобрение',' korolev@carmoney.ru; shubkin_a_n@carmoney.ru; ','Заявки в статусе "Предварительное одобрение" больше 9 минут','Предварительное одобрение','8999'

CREATE PROC dbo.checkRequestStateDurationByNameAndNotSource @limit int                      = 540
,                                                                   @statusName nvarchar(1024)      = 'Предварительное одобрение'
,                                                                   @recipients nvarchar(4000)      = 'blagoveschenskaya@carmoney.ru;  teplyakov@carmoney.ru; korolev@carmoney.ru; bityugin@carmoney.ru; 
										dwh112carmone@carmoney.ru;'
,                                                                   @subject nvarchar(4000)         = 'Заявки в статусе "Предварительное одобрение" больше 9 минут'
,                                                                   @fieldName nvarchar(255)        = 'Предварительное одобрение'
,                                                                   @requestNotSource nvarchar(255)=  '8999'

as
begin
	declare @recipients1 nvarchar(4000) ='Demkina_A_M@carmoney.ru; blagoveschenskaya@carmoney.ru; 
							  teplyakov@carmoney.ru; korolev@carmoney.ru; bityugin@carmoney.ru; 
							 dwh112carmone@carmoney.ru;
							  ;D.Polozov@carmoney.ru'
	set nocount on


	if object_id('tempdb.dbo.#t0') is not null
		drop table #t0
	CREATE TABLE #t0 ( requestSource                             [nvarchar](128) NULL
	,                  RequestStatus                             [nvarchar](128) NULL
	,                  КодОфиса                                  int
	,                  Employee                                  [nvarchar](128) NULL
	,                  дата                                      datetime
	,                  fio                                       [nvarchar](128) NULL
	,                  Номер                                     [nvarchar](128) NULL

	,                  Сумма                                     float
	,                  СуммаВыданная                             float
	--[External_id] [nvarchar](28)  NULL,
	,                  [Черновик из ЛК]                          [int] NULL
	,                  [Клиент прикрепляет фото в МП]            [int] NULL
	,                  [Клиент зарегистрировался в МП]           [int] NULL
	,                  [Просрочен]                               [int] NULL
	,                  [Платеж опаздывает]                       [int] NULL
	,                  [Проблемный]                              [int] NULL
	,                  [ТС продано]                              [int] NULL
	,                  [Черновик]                                [int] NULL
	,                  [Предварительная]                         [int] NULL
	,                  [Верификация КЦ]                          [int] NULL
	,                  [Предварительное одобрение]               [int] NULL
	,                  [Контроль авторизации]                    [int] NULL
	,                  [Контроль ПЭП]                            [int] NULL
	,                  [Контроль заполнения ЛКК]                 [int] NULL
	,                  [Контроль фото ЛКК]                       [int] NULL
	,                  [Назначение встречи]                      [int] NULL
	,                  [Встреча назначена]                       [int] NULL
	,                  [Ожидание контроля данных]                [int] NULL
	,                  [Контроль данных]                         [int] NULL
	,                  [Выполнение контроля данных]              [int] NULL
	,                  [Верификация документов клиента]          [int] NULL
	,                  [Контроль верификация документов клиента] [int] NULL
	,                  [Одобрены документы клиента]              [int] NULL
	,                  [Контроль одобрения документов клиента]   [int] NULL
	,                  [Верификация документов]                  [int] NULL
	,                  [Контроль верификации документов]         [int] NULL
	,                  [Одобрено]                                [int] NULL
	,                  [Договор зарегистрирован]                 [int] NULL
	,                  [Проверка ПЭП и ПТС]                      [int] NULL
	,                  [Контроль подписания договора]            [int] NULL
	,                  [Договор подписан]                        [int] NULL
	,                  [Контроль получения ДС]                   [int] NULL
	,                  [Заем выдан]                              [int] NULL
	,                  [Оценка качества]                         [int] NULL
	,                  [Заем погашен]                            [int] NULL
	,                  [Заем аннулирован]                        [int] NULL
	,                  [Аннулировано]                            [int] NULL
	,                  [Отказ документов клиента]                [int] NULL
	,                  [Отказано]                                [int] NULL
	,                  [Отказ клиента]                           [int] NULL
	,                  [Клиент передумал]                        [int] NULL
	,                  [Забраковано]                             [int] NULL
	,                  lastStatusName                            [nvarchar](128) NULL )

	insert into #t0
	exec [dbo].[reportRequestStatuses]


/*
select * from #t1 where  requestSource='Ввод операторами FEDOR' and  lastStatusName ='Предварительное одобрение'
 and RequestStatus ='Предварительное одобрение'
  */


	drop table if exists #t_mv_call_case
	select uuid
	,      creationdate
	,      lastcall
	,      timezone
	,      phonenumbers
	,      casecomment
	,      statetitle
	,      projecttitle
	,      projectuuid
		into #t_mv_call_case
	from NaumenDbReport.dbo.mv_call_case cc
	where cc.creationdate>cast(cast(getdate() as date) as datetime2(7))
		and cc.projectuuid in ('corebo00000000000mqi35tcal14edv4','corebo00000000000mqpsrh9u28s16g8')
	create clustered index ix on #t_mv_call_case(uuid)

	drop table if exists #feodor_dm_call_history
	SELECT distinct cc.uuid
	,               cc.creationdate
	,               timezone
	,               phonenumbers
	,               casecomment
	,               statetitle
	,               projecttitle
	,               cc.projectuuid
	--,               q.title
	--,               channel
	--,               lcrm_id
					--DWH-1871
	,               title = cf.lcrm_title
	,               channel = cf.lcrm_channel
	,               lcrm_id = cf.lcrm_id
	,               attempt_start
	,               attempt_end
	,               number_type
	,               pickup_time
	,               queue_time
	,               operator_pickup_time
	,               speaking_time
	,               wrapup_time
	,               login
	,               attempt_result
	,               hangup_initiator
	,               attempt_number
	,               pc.calldispositiontitle
		into #feodor_dm_call_history
	FROM        #t_mv_call_case                                   cc 
	left join   [NaumenDbReport].[dbo].[detail_outbound_sessions] dos on dos.case_uuid=cc.uuid
	left join   [NaumenDbReport].[dbo].[mv_custom_form]           cf  on cc.uuid=cf.owneruuid
	left join   [NaumenDbReport].[dbo].mv_phone_call              pc  on pc.uuid=cc.lastcall
	--DWH-1871
	--cross apply openjson(jsondata,'$.group001')
	--	with(
	--	title nvarchar(50) '$.Title',
	--	channel nvarchar(50) '$.channel',
	--	lcrm_id bigint '$.lcrm_id'
	--	) q                                                          
	where cc.creationdate>cast(getdate() as date)
		and cc.projectuuid in ('corebo00000000000mqi35tcal14edv4','corebo00000000000mqpsrh9u28s16g8')
	option ( maxdop 1)


	drop table if exists #f_calls
	select *                                                                                                      
	,      last_attempt_result=first_value(attempt_result) over (partition by lcrm_id order by attempt_start desc)
		into #f_calls
	from #feodor_dm_call_history


	if object_id('tempdb.dbo.#t1') is not null
		drop table #t1
	select --r.Номер,
		distinct l.Метка_LeadId
	,            t.*
	--,r.*
	,            f.lcrm_id
	,            f.last_attempt_result
	,            f.calldispositiontitle
		into #t1
	from      stg._1cCRM.Документ_CRM_Заявка         l
	join      stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС r on r. лид=l.Ссылка
	join      #t0                                    t on r.Номер=t.Номер
	--left join #f_calls f on f.lcrm_id=Метка_LeadId
	left join #f_calls                               f on f.lcrm_id=try_cast(Метка_LeadId as bigint)
	--select * from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
	where l.Дата>dateadd(year,2000,cast(getdate() as date))



	declare @tsql nvarchar(max)=''

	set @tsql='
if  not isnull((select count(*) from #t1  where (isnull(['+@fieldName+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''')     and RequestStatus='''+@statusName+
	'''  and  (КодОфиса <>'''+@requestNotSource+''' or isnull(КодОфиса,'''')='''')    and requestSource=''Ввод операторами FEDOR''     
    and Номер<>''19111900000756'' and Номер<>''19112700001736''  and Номер<>''19112700001749''      
                 and isnull(last_attempt_result,'''') not in (''recallRequest'' ,''Thinking'',''refuseClient'',''CallDisconnect'',''MP'',''nonTarget'',''consultation'','''',''busy'',''no_answer'',''connected'',''abandoned'')
                 and isnull(calldispositiontitle,'''') not in (''Отказ клиента'')


),0)=0 

begin 
    
    DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
    SET @tableHTML =  
        N''<H1>'+@subject+'</H1>'' +  
        N''<table border="1">'' +  
        N''<tr><th>Источник заявки</th><th>дата</th>'' +  
        N''<th>Номер</th><th>Сумма</th><th>В статусе "'+@statusName+'", с</th>'' +  
        N''<th>Последний статус</th><th>Сотрудник</th><th>Результат Наумен</th></tr>'' +  
        CAST ( ( SELECT td = requestSource,       '''',  
                        td = дата, '''',  
                        td = Номер, '''',  
                        td =  format(Сумма,''0''), '''',  
                        td = ['+@fieldname+'], '''',  
                        td = lastStatusName, '''',   
                        td = Employee, '''',   
                        td=last_attempt_result
                  from #t1
    where (isnull(['+@fieldName+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''')   and RequestStatus='''+@statusName+
	''' and  (КодОфиса <>'''+@requestNotSource+''' or isnull(КодОфиса,'''')='''')   and requestSource=''Ввод операторами FEDOR''  
	and Номер<>''19111900000756'' and Номер<>''19112700001736''  and Номер<>''19112700001749''   
     and isnull(last_attempt_result,'''') not in (''recallRequest'' ,''Thinking'',''refuseClient'',''CallDisconnect'',''MP'',''nonTarget'',''consultation'','''',''busy'',''no_answer'',''connected'',''abandoned'')
      and isnull(calldispositiontitle,'''') not in (''Отказ клиента'')
    order by дата
 
                  FOR XML PATH(''tr''), TYPE   
        ) AS NVARCHAR(MAX) ) +  
        N''</table>'' ;  
  
  

  
    EXEC msdb.dbo.sp_send_dbmail @recipients='''+@recipients+''',
		@profile_name = ''Default'',  
        @subject = '''+@subject+''' ,
        @body = @tableHTML,  
        @body_format = ''HTML'' ;  
   
end
'


	--select @tsql
	exec (@tsql)





	set @tsql='
if   isnull((select count(*) from #t1  where (isnull(['+@fieldName+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''')     and RequestStatus='''+@statusName+'''  and  (КодОфиса <>'''+@requestNotSource+''' or isnull(КодОфиса,'''')='''')    and requestSource=''Ввод операторами FEDOR''     and Номер<>''19111900000756''     



),0)<>0 

begin 

    DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
    SET @tableHTML =  
        N''<H1>'+@subject+'</H1>'' +  
        N''<table border="1">'' +  
        N''<tr><th>Источник заявки</th><th>дата</th>'' +  
        N''<th>Номер</th><th>Сумма</th><th>В статусе "'+@statusName+'", с</th>'' +  
        N''<th>Последний статус</th><th>Сотрудник</th><th>Результат Наумен</th></tr>'' +  
        CAST ( ( SELECT td = requestSource,       '''',  
                        td = дата, '''',  
                        td = Номер, '''',  
                        td =  format(Сумма,''0''), '''',  
                        td = ['+@fieldname+'], '''',  
                        td = lastStatusName, '''',   
                        td = Employee, '''',   
                        td=last_attempt_result
                  from #t1
    where (isnull(['+@fieldName+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''')   and RequestStatus='''+@statusName+''' and  (КодОфиса <>'''+@requestNotSource+''' or isnull(КодОфиса,'''')='''')
     and requestSource=''Ввод операторами FEDOR''
	 
    order by дата
 
                  FOR XML PATH(''tr''), TYPE   
        ) AS NVARCHAR(MAX) ) +  
        N''</table>'' ;  
  
  
    EXEC msdb.dbo.sp_send_dbmail @recipients='''+@recipients1+''',
        @profile_name = ''Default'',  
		@subject = '''+@subject+''' ,
        @body = @tableHTML,  
        @body_format = ''HTML'' ;  
   
end
'


	--select @tsql
	exec (@tsql)


end


--go

--exec [dbo].[checkRequestStateDurationByNameAndNotSource]
