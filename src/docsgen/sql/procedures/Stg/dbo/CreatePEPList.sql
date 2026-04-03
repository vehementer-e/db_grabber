


-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[CreatePEPList] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE procedure [dbo].[CreatePEPList]
as
begin
return
  set nocount on

  if object_id('stg.dbo.[ClientPEPVersion]') is not null drop table stg.dbo.[ClientPEPVersion]

  ;
  with m_dates as (
       select s.Ссылка,max(d.Дата) max_dt 
         from [c1-vsr-sql05].CRM_NIGHT00.dbo.[Справочник_Партнеры] s
         join [c1-vsr-sql05].CRM_NIGHT00.dbo.Документ_ЗаявкаНаЗаймПодПТС  d on s.Ссылка=d.Партнер
        where s.ПометкаУдаления=0x00 and d.ПометкаУдаления=0x00 
     group by s.Ссылка
 )
  select ClientCRMGUID=cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(s.Ссылка)  as nvarchar(100))
       , [RequestNo] =cast(Номер as nvarchar(100))
       , [RequestMFOGUID] =cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(d.Ссылка)  as nvarchar(100))
       , [RequestDate] =format(dateadd(year,-2000,isnull(d.Дата,'20010101')),'yyyy-MM-ddTHH:mm:ss')
       , [clentPEPVersion] =cast(
                                case when d.Дата<'40180420' then  0
                                     else case when d.Дата>='40180420' and  d.Дата<='40190228' then 1
                                               else case when d.Дата>'40190228'  then 2 end
                                          end
                                end
                                as nvarchar(100))
       , [clentPEPDateTime] =format(dateadd(year,-2000,isnull(d.Дата,'20010101')),'yyyy-MM-ddTHH:mm:ss')
       , [clientFirstName] =cast(s.CRM_Имя as nvarchar(100))
       , [clientLastName] =cast(s.CRM_Фамилия as nvarchar(100))
       , [clientMiddleName] =cast(s.CRM_Отчество as nvarchar(100))
       , [clientBirthDate] =format(dateadd(year,-2000,isnull(s.ДатаРождения,'20010101')),'yyyy-MM-dd')
       , [clientPASSPNO] =cast(НомерПаспорта as nvarchar(100))
       , [clientPASSPSeries] =cast(СерияПаспорта as nvarchar(100))
       , [clientPasspIssueDate] =format(isnull(ДатаВыдачи_Паспорта,'20010101') ,'yyyy-MM-dd')
       , [clientPasspIssueCode] =cast(КодПодразделения_Паспорта as nvarchar(100))
       , [clientBirthPlace] =cast(МестоРождения as nvarchar(100))
  into stg.dbo.[ClientPEPVersion]
  from [c1-vsr-sql05].CRM_NIGHT00.dbo.[Справочник_Партнеры] s
  join [c1-vsr-sql05].CRM_NIGHT00.dbo.Документ_ЗаявкаНаЗаймПодПТС  d on s.Ссылка=d.Партнер
  join [c1-vsr-sql05].CRM_NIGHT00.dbo.[Справочник_СтатусыЗаявокПодЗалогПТС] st on st.Ссылка=d. Статус
  join m_dates md on md.max_dt=d.Дата and md.Ссылка=s.Ссылка
 where s.ПометкаУдаления=0x00 and d.ПометкаУдаления=0x00 and st.ПометкаУдаления=0x00
       and st.Наименование='Заем выдан'
end

