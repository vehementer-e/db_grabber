-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 24.12.2019
-- Description:	Таблица договоров, наличие коммиссионных продуктов и отказов по ним
-- exec [dbo].[dm_Refusal_CommissionProducts] 
-- =============================================
CREATE    PROCEDURE [dbo].[dm_Refusal_CommissionProducts] 

 AS
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


-- перезапишем результат
  

drop table if exists #t


SELECT   a1.Код as 'Номер договора КП' , dateadd(year, -2000, a1.Дата) 'ДатаНачалаКП', dateadd(year, -2000, a1.ДатаОкончания) 'ДатаОкончанияКП',  a1.Наименование 'Описание', a3.Наименование 'Название КП', a3.Наименование2 'Название КП дополнительно',   dateadd(year, -2000, a2.ДатаРасторжения) as 'ДатаРасторженияКП', a1.Сумма 'Сумма КП',a0.Код as 'Номер договора займа', a0.Сумма 'СуммаДоговораЗайма', a0.СуммаДопПродуктов 'СуммаВсехКПДоговораЗайма', iif(a1.ВключатьВСуммуЗайма=0x01,1,0) ВключатьВСуммуЗайма, a3.ПрефиксНумерации   ПрефиксНумерации
into #t
from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] a1
left join [Stg].[_1cCMR].[Справочник_Договоры] a0
on a0.ссылка = a1.Договор
left join [Stg].[_1cCMR].[Справочник_ДополнительныеПродукты] a3
on a1.ДопПродукт = a3.Ссылка
left join  [Stg].[_1cCMR].[РегистрСведений_ОбработкаОтказниковПоСтраховке] a2
on a1.ссылка=a2.Договор
--where a1.Договор is not null


--drop table [dbo].[dm_RefusalCommissionProducts]

begin tran

	delete from [dbo].[dm_RefusalCommissionProducts];
	insert into [dbo].[dm_RefusalCommissionProducts]
	select * from #t  

commit tran



 END
