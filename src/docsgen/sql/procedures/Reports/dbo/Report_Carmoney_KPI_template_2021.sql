-- =============================================
-- Author:		Sabanin_a_a
-- calendar
-- =============================================

--exec [dbo].[Report_Carmoney_KPI_template_2021]
CREATE  PROCEDURE [dbo].[Report_Carmoney_KPI_template_2021]
	-- Add the parameters for the stored procedure here


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



---- Создаем структуру отчета (Строки отчета)
if object_id('tempdb.dbo.#Tstruct_group1') is not null drop table #Tstruct_group1;
create table #Tstruct_group1(rws int null ,ind nvarchar(255) null, ind_plan nvarchar(255) null);

insert into #Tstruct_group1 (rws ,ind, ind_plan)
values 	
(0,N'ПОКАЗАТЕЛИ ПРОДАЖ', N'test')
,(1,N'Кол-во заявок', N'Заявок') 
,(2,N'Кол-во займов', N'Займов, шт') 
,(3,N'Сумма займов', N'Займов, руб') 
,(4,N'Сумма займов накопительно', N'test') 
,(5,N'Средний размер займа', N'test')
,(6,N'Конвертация', N'test') 
,(7,N'Approval Rate', N'test') 
,(8,N'Take Rate', N'test') 
,(9,N'Кол-во займов со страховкой', N'КП шт') 
,(10,N'Сумма страховки по Договору', N'КП, руб gross') 
,(11,N'Сумма страховки Полученная в ДОХОД', N'КП, руб net')


,(30,N'ПОРТФЕЛЬНЫЕ ПОКАЗАТЕЛИ', N'test')
,(31,N'Портфель всего (КП)', N'Портфель всего, в т#ч#')
,(32,N'без просрочки (КП)', N'без просрочки')
,(33,N'просрочка 1-90 дней (КП)', N'просрочка 1-90 дней')
,(34,N'просрочка 90+ дней (КП)', N'просрочка 90+ дней')
,(35,N'в т.ч. просрочка 360+ дней (КП)', N'в т#ч# просрочка 360+ дней')

,(41,N'Портфель всего (КП), шт.', N'Активные займы всего, в т#ч#') 
,(42,N'без просрочки (КП), шт.', N'без просрочки1')
,(43,N'просрочка 1-90 дней (КП), шт.', N'просрочка 1-90 дней1')
,(44,N'просрочка 90+ дней (КП), шт.', N'просрочка 90+ дней1')
,(45,N'в т.ч. просрочка 360+ дней (КП), шт.', N'в т#ч# просрочка 360+ дней1')
	
,(60,N'ПОСТУПЛЕНИЕ ВЫРУЧКИ', N'test')
,(61,N'ВЫРУЧКА ПО ОПЛАТЕ', N'ВЫРУЧКА ПО ОПЛАТЕ') 
,(62,N'НАЧИСЛЕННАЯ ВЫРУЧКА', N'НАЧИСЛЕННАЯ ВЫРУЧКА') 
,(63,N'РЕЗЕРВ на ОД (на дату отчета)', N'РЕЗЕРВ на ОД (на дату отчета)')  
,(64,N'РЕЗЕРВ на % (на дату отчета)', N'РЕЗЕРВ на % (на дату отчета)')  
,(65,N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)', N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)') 
,(66,N'Доля РЕЗЕРВА от КП', N'Доля РЕЗЕРВА от КП') 

---------
---- Создаем структуру отчета (Колонки отчета)
if object_id('tempdb.dbo.#Tcolumn') is not null drop table #Tcolumn;
create table #Tcolumn (col int null ,st nvarchar(255) null);

insert into #Tcolumn (col ,st)
values 	(1,N'План') ,(2,N'Факт') ,(3,N'Прогноз') ,(4,N'% выполнения')


----- Соединяем колонки со строками
drop table if exists #rws_col
select r.rws ,c.col , r.ind , r.ind_plan, c.st
into #rws_col
from #Tstruct_group1 r
cross join (select * from #Tcolumn where [st] in (N'План' ,N'Факт' ,N'Прогноз' ,N'% выполнения')) c 


drop table if exists [dbo].[dm_Report_KPI_template_2021]

select * 
into [dbo].[dm_Report_KPI_template_2021]
from #rws_col

END
