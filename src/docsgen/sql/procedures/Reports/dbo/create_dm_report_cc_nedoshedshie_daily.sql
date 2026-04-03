
-- =============================================
-- Author:		Petr Ilin
-- Create date: 20200514
-- Description:	Мониторинг заявок день в день
-- =============================================

CREATE PROCEDURE [dbo].[create_dm_report_cc_nedoshedshie_daily]
	-- Add the parameters for the stored procedure here
--	@DateBegin datetime
--	@DateEnd datetime
AS
BEGIN
	SET NOCOUNT ON;
	
declare @now_dt datetime = getdate()



drop table if exists #t1
 
 select cast(@now_dt as date) ДатаЗ, 
         @now_dt as ДатаОбновленияСтроки,
         count(Номер) ЧислоЗаявок, 
		 count(case when [Вид займа]='Первичный' then номер end) ЧислоНовыхЗаявок,
		 count(case when  [Отказ документов клиента] is not null or [Отказано] is not null then номер end) ЧислоОтказов,
		 count(case when fa.Отказано is  null and
		                 fa.[Отказ документов клиента]  is  null and
						 fa.[Заем выдан] is  null and
						 fa.[Заем погашен] is  null and
						 fa.Аннулировано is  null and
						 fa.[Заем аннулирован] is  null and
						 fa.[Отказ клиента] is  null                  then номер end) ЧилоВРаботе,
		 count(case when [Текущий статус]='встреча назначена' and [Контроль данных] is null then номер end) НазначениеВстречи,
		 count(case when [Отказ клиента] is not null  then номер end) ОтказКлиента,
		 count(case when [Заем выдан] is not null   then номер end) ВыданоЗаймов,
		 count(case when Одобрено is not null  then номер end) Одобрено,
		 count(case when Одобрено is not null and [Заем выдан] is null then номер end) ОдобреноНоНЕВыданоДеньВДень,
		 max(ДатаЗаявкиПолная) as ДатаПоследнейУчтеннойЗаявки,
		 min(ДатаЗаявкиПолная) as ДатаПервойУчтеннойЗаявки
		into #t1
		 from dbo.dm_Factor_Analysis_001 fa
		 where Дубль_ClientGuidОдинДень<>1 and [Верификация КЦ] is not null
		 and cast(ДатаЗаявкиПолная as date)=cast(@now_dt as date)

begin tran
		 delete from [dbo].dm_report_cc_nedoshedshie_daily
		 where ДатаЗ in (select ДатаЗ from #t1)
		 
insert into [dbo].dm_report_cc_nedoshedshie_daily
select * from #t1

commit tran


END
