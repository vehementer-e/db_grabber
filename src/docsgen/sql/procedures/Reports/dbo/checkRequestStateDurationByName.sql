--exec dbo.checkRequestStateDurationByName   120,'Верификация КЦ','blagoveschenskaya@carmoney.ru; Gustyakov_B_V@carmoney.ru; E.Tigunov@carmoney.ru;V.Shadzhe@carmoney.ru;  a.baykov@carmoney.ru; prometov@carmoney.ru; ilina_e_v@carmoney.ru; shubkin_a_n@carmoney.ru; kurdin@carmoney.ru ;Vasilev@carmoney.ru; Krivotulov@carmoney.ru','Заявки в статусе "Верификация КЦ" больше 2 минут','Верификация КЦ'
--exec dbo.checkRequestStateDurationByName   600,'Контроль данных','Выполнение контроля данных','E.Mogilevskaya@carmoney.ru; shubkin_a_n@carmoney.ru','Заявки в статусе "Верификация КД" больше 10 минут','Контроль данных','Выполнение контроля данных'
--exec dbo.checkRequestStateDurationByName   1200,'Верификация документов клиента','Контроль верификация документов клиента','E.Mogilevskaya@carmoney.ru; shubkin_a_n@carmoney.ru','Заявки в статусе "Верификация ВДК" больше 20 минут','Верификация документов клиента','Контроль верификация документов клиента'
--exec dbo.checkRequestStateDurationByName   600,'Верификация документов','Контроль верификации документов','E.Mogilevskaya@carmoney.ru; shubkin_a_n@carmoney.ru','Заявки в статусе "Верификация ВД" больше 10 минут','Верификация документов','Контроль верификации документов'

CREATE    procedure [dbo].[checkRequestStateDurationByName]

  @limit int=120
          , @statusName nvarchar(1024)='Верификация КЦ'
          , @statusName1 nvarchar(1024)='Контроль верификации документов'
          , @recipients nvarchar(4000) ='blagoveschenskaya@carmoney.ru; Gustyakov_B_V@carmoney.ru; 
										E.Tigunov@carmoney.ru;V.Shadzhe@carmoney.ru; prometov@carmoney.ru; 
										ilina_e_v@carmoney.ru; shubkin_a_n@carmoney.ru; kurdin@carmoney.ru 
										;Vasilev@carmoney.ru	-- ; Krivotulov@carmoney.ru
										;D.Polozov@carmoney.ru'
   ,  @subject  nvarchar(4000) ='Заявки в статусе "Верификация КЦ" больше 2 минут'
           
          ,  @fieldName nvarchar(255)='Верификация КЦ'
          ,  @fieldname1 nvarchar(255)='Контроль верификации документов'
as
begin


set nocount on


if object_id('tempdb.dbo.#t1') is not null drop table #t1
CREATE TABLE #t1(
 
    requestSource [nvarchar](128)  NULL
  ,  RequestStatus [nvarchar](128)  NULL
  , КодОфиса int
  , Employee [nvarchar](128)  NULL
  , дата datetime
  , fio [nvarchar](128)  NULL
  , Номер  [nvarchar](128)  NULL

  , Сумма float
  , СуммаВыданная float
	--[External_id] [nvarchar](28)  NULL,
  ,
	[Черновик из ЛК] [int] NULL,
	
	[Клиент прикрепляет фото в МП] [int] NULL,
	[Клиент зарегистрировался в МП] [int] NULL,
	[Просрочен] [int] NULL,
	[Платеж опаздывает] [int] NULL,
	[Проблемный] [int] NULL,
	[ТС продано] [int] NULL,
	[Черновик] [int] NULL,
	[Предварительная] [int] NULL,
	[Верификация КЦ] [int] NULL,
	[Предварительное одобрение] [int] NULL,
	[Контроль авторизации] [int] NULL,
	[Контроль ПЭП] [int] NULL,
	[Контроль заполнения ЛКК] [int] NULL,
	[Контроль фото ЛКК] [int] NULL,
	[Назначение встречи] [int] NULL,
	[Встреча назначена] [int] NULL,
	[Ожидание контроля данных] [int] NULL,
	[Контроль данных] [int] NULL,
	[Выполнение контроля данных] [int] NULL,
	[Верификация документов клиента] [int] NULL,
	[Контроль верификация документов клиента] [int] NULL,
	[Одобрены документы клиента] [int] NULL,
	[Контроль одобрения документов клиента] [int] NULL,
	[Верификация документов] [int] NULL,
	[Контроль верификации документов] [int] NULL,
	[Одобрено] [int] NULL,
	[Договор зарегистрирован] [int] NULL,
	[Проверка ПЭП и ПТС] [int] NULL,
	[Контроль подписания договора] [int] NULL,
	[Договор подписан] [int] NULL,
	[Контроль получения ДС] [int] NULL,
	[Заем выдан] [int] NULL,
	[Оценка качества] [int] NULL,
	[Заем погашен] [int] NULL,
	[Заем аннулирован] [int] NULL,
	[Аннулировано] [int] NULL,
	[Отказ документов клиента] [int] NULL,
	[Отказано] [int] NULL,
	[Отказ клиента] [int] NULL,
	[Клиент передумал] [int] NULL,
	[Забраковано] [int] NULL,
  lastStatusName [nvarchar](128)  NULL
)

insert into #t1 
exec  [dbo].[reportRequestStatuses]
    
    
   

    ---- Верификация КЦ
    declare @tsql nvarchar(max)=''

   

set @tsql='
if  not isnull((select count(*) from #t1 where (isnull(['+@fieldName+'],0)+isnull(['+@fieldName1+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''','''+@statusName1+''')),0)=0 

begin 
    select 
           [Источник заявки]=requestSource
         , дата
         , Номер
         , Сумма
         , [В статусе "'+@statusName+'", с]=['+@fieldname+']
         , [Последний статус]=lastStatusName
    from #t1
    where (isnull(['+@fieldName+'],0)+isnull(['+@fieldName1+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''','''+@statusName1+''')
    order by дата

    DECLARE @tableHTML  NVARCHAR(MAX) ;  
  
    SET @tableHTML =  
        N''<H1>'+@subject+'</H1>'' +  
        N''<table border="1">'' +  
        N''<tr><th>Источник заявки</th><th>дата</th>'' +  
        N''<th>Номер</th><th>Сумма</th><th>В статусе "'+@statusName+'", с</th>'' +  
        N''<th>Последний статус</th></tr>'' +  
        CAST ( ( SELECT td = requestSource,       '''',  
                        td = дата, '''',  
                        td = Номер, '''',  
                        td =  format(Сумма,''0''), '''',  
                        td = ['+@fieldname+'], '''',  
                        td = lastStatusName 
                  from #t1
    where (isnull(['+@fieldName+'],0)+isnull(['+@fieldName1+'],0))>='+format(@limit,'0')+' and lastStatusName in ('''+@statusName+''','''+@statusName1+''')
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


  
end
