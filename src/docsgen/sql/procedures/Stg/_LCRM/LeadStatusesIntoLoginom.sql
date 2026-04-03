
--exec _lcrm.LeadStatusesIntoLoginom
-- Usage: запуск процедуры с параметрами
-- EXEC _LCRM.LeadStatusesIntoLoginom @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC _LCRM.LeadStatusesIntoLoginom
as
begin

set nocount on


--select * from #t order by Телефон, номер, имя,Период

--DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
/*
drop table if exists #lcrm

select distinct [lcrm id]= id 
     , UF_PHONE
     , UF_PHONE_ADD
     , UF_REGISTERED_AT
     , UF_ACTUALIZE_AT
     , LastLeadStatus=UF_RC_REJECT_CM
     into #lcrm
  from dbo.lcrm_tbl_full_w_chanals2 c
 where UF_ACTUALIZE_AT >dateadd(day,-30,cast(getdate() as date))
   and not (uf_row_id is not null and  [Канал от источника]   in ( 'Канал не определен - КЦ', 'Канал не определен - МП' , 'Оформление на партнерском сайте'))
*/

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	ID numeric(10,0),
	UF_PHONE varchar(128),
	UF_PHONE_ADD varchar(128),
	UF_REGISTERED_AT datetime2(7),
	UF_ACTUALIZE_AT datetime2(7),
	UF_RC_REJECT_CM varchar(512),
	UF_ROW_ID varchar(128),
	[Канал от источника] nvarchar(255)
)
-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = dateadd(day,-30,cast(getdate() as date)), @End_Registered = cast(getdate() as date)

EXEC _LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

--test
--SELECT @Return_Number, @Return_Message

drop table if exists #lcrm
select distinct 
	[lcrm id] = c.ID 
     , c.UF_PHONE
     , c.UF_PHONE_ADD
     , c.UF_REGISTERED_AT
     , c.UF_ACTUALIZE_AT
     , LastLeadStatus = c.UF_RC_REJECT_CM
into #lcrm
from #TMP_leads c
where 1=1
	AND NOT (c.UF_ROW_ID IS NOT NULL AND c.[Канал от источника] IN ('Канал не определен - КЦ', 'Канал не определен - МП' , 'Оформление на партнерском сайте'))
--// end DWH-1567


    begin tran
      --delete from  _loginom.LeadStatusesLast30Days
      TRUNCATE TABLE _loginom.LeadStatusesLast30Days
      
      insert into _loginom.LeadStatusesLast30Days
        select * from #lcrm
    commit tran 
  

  



end


 
--select count(*) from loginomdb.dbo.LeadStatusesLast30Days where   LastLeadStatus is not null
