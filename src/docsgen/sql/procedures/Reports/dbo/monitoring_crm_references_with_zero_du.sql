--exec monitoring_crm_references_with_zero_du
CREATE   procedure [dbo].[monitoring_crm_references_with_zero_du]
as
begin
--dwh-539


 -- последний статус
  if object_id('tempdb.dbo.#last_status') is not null drop table #last_status
 
  select distinct case when r.НомерЗаявки <>'' then r.НомерЗаявки else concat(r.Фамилия,' ',r.Имя,' ',r.Отчество,' ',r.СерияПаспорта,' ',r.НомерПаспорта) end   external_id
       , statusName =first_value(st.Наименование) over (partition by  r.НомерЗаявки order by Период desc)
    into #last_status
    FROM [C3-VSR-SQL02].crm.dbo.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС s 
    join [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС r  on r.Ссылка=s.Заявка --and cast(Период as date)=cast(Дата as date)
    join [C3-VSR-SQL02].crm.dbo.[Справочник_СтатусыЗаявокПодЗалогПТС] st on st.Ссылка=s. Статус 
   where Период>dateadd(day,-5,dateadd(year,2000,cast(getdate() as date)      )   )

   drop table if exists #du
  select r.Номер
       , sdu.Наименование ДопУслуга
      -- , du.Включена
       , du.СуммаДопУслуги
       , ls.statusName СтатусЗаявки 
       into #du
    from [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС_ДопУслуги du
    join [C3-VSR-SQL02].crm.dbo.Документ_ЗаявкаНаЗаймПодПТС r on du. ссылка=r.ссылка
    join [C3-VSR-SQL02].[crm].[dbo].[Справочник_ДополнительныеУслуги] sdu on sdu.ссылка= du.ДопУслуга
    join (select * 
            from #last_status 
           where statusName not in ('P2P','Аннулировано','Заем аннулирован','Заем выдан','Заем погашен','Отказ документов клиента','Отказано','Платеж опаздывает','Проблемный','Просрочен','ТС продано'
                 ,'Клиент передумал','Забраковано','Черновик','Верификация КЦ', 'Заполнение анкеты птс' )
         ) ls on ls.external_id=r.Номер
   where СуммаДопУслуги=0 and Включена=0x01
  and  r.Номер not in ('24042502003659')
--   order by 1
   
   --select * from #du



   declare @tableHTML1 nvarchar(max)
   
   if not isnull((select count(*) 
				from #du 
		),0)=0 
begin   
  
SET @tableHTML1 =  
    N'<H1>Заявки CRM с нулевыми суммами допуслуг </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Номер</th>' +  
    N'<th>ДопУслуга</th>' +  
    N'<th>Сумма ДопУслуги</th>' +  
    N'<th>Последний статус</th></tr>' +  
    CAST ( ( SELECT 
                    td = Номер, '',  
                    td = ДопУслуга, '',  
                  
                    td = СуммаДопУслуги, '',  
                  
                    td = СтатусЗаявки 
              from #du 

order by Номер
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML1


EXEC msdb.dbo.sp_send_dbmail @recipients='2nd-line-monitoring@carmoney.ru; dwh112@carmoney.ru;',
--; Krivotulov@carmoney.ru
    @profile_name = 'Default',  
    @subject = 'Заявки CRM с нулевыми суммами допуслуг  ',  
    @body = @tableHTML1,  
    @body_format = 'HTML' ;  

end

end