
create   proc  --exec dbo.[bp поиск категории процедура] 0
dbo.[bp поиск категории процедура]
@full_update int = 0
as

begin


declare @request_date date = case when @full_update = 0 then getdate()-10 else '20160101' end
declare @dip_date date = dateadd(day, -10, @request_date)


select * into #dip_union 
from (
select '8'+ТелефонМобильный mobile, category, cdate, 'Докреды' as type , main_limit, external_id 
from dwh_new.[dbo].[docredy_history]
union all
select '8'+ТелефонМобильный mobile, category, cdate, 'Повторники' as type , main_limit , external_id
from dwh_new.[dbo].povt_history

) x
where cdate>=@dip_date

drop table if exists #Справочник_Договоры
select Код,  dwh_new.dbo.getGUIDFrom1C_IDRREF( b.Клиент ) [guid клиента] into  #Справочник_Договоры from stg._1cCMR.Справочник_Договоры b

select a.*, b.[guid клиента] into #history from #dip_union a left join #Справочник_Договоры b on a.external_id=b.Код					
					
create nonclustered index t on #history					
(					
[guid клиента], mobile, type, cdate
)					
		
drop table if exists #req
select 
  dateadd(year, -2000, Дата) [Дата заявки]
, cast(dateadd(year, -2000, Дата) as date) [Дата заявки день]
, Номер
, Ссылка 
, dwh_new.dbo.getGUIDFrom1C_IDRREF( Партнер ) [guid клиента]
, '8'+МобильныйТелефон Телефон

into #req
from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС
where cast(dateadd(year, -2000, Дата) as date)>=@request_date
		
drop table if exists #req_category					
select 					
					
a.* 					

	  , isnull(d.category	 , d1.category	  ) category_docredy	
	  , isnull(p.category	 , p1.category	  ) category_povt	
	, getdate() as created
into #req_category from #req a 					
outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Докреды'    and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) d					
outer apply (select top 1 * from #history b where (b.mobile=a.Телефон                ) and b.type = 'Докреды'    and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) d1	
outer apply (select top 1 * from #history b where (b.[guid клиента]=a.[guid клиента] ) and b.type = 'Повторники' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) p					
outer apply (select top 1 * from #history b where (b.mobile=a.Телефон                ) and b.type = 'Повторники' and b.cdate between dateadd(day, -10, a.[Дата заявки день] )  and a.[Дата заявки день] order by cdate desc ) p1	


--drop table if exists  analytics.dbo.[bp поиск категории] 
--select * into  analytics.dbo.[bp поиск категории] 
--from #req_category


delete from analytics.dbo.[bp поиск категории] 
where [Дата заявки день]>=@request_date
insert into analytics.dbo.[bp поиск категории]
select * from #req_category


end