
CREATE   proc [dbo].[подготовка витрины с одобренными заявками и комментариями рарус]
as

begin



declare @created datetime = (select top 1 created from reports.dbo.dm_Factor_Analysis)
declare @num int = 30


if (select max(created) from reports.dbo.dm_Factor_Analysis)  = (select  max(created) from  dbo.[витрина с одобренными заявками и комментариями рарус]) 
begin
	
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'CBD04081-199B-40C2-A2BE-96FCE099A04A'
select 1 d
return

end

drop table if exists #t1
select Номер,  [заем выдан],   дубль,  [Группа каналов], [Канал от источника], Одобрено, [Сумма одобренная], product, ТекущийСтатус,Место_создания_2, isInstallment, ФИО, [Место cоздания], РекомендованнаяСтавка,  created
, case when  аннулировано is not null or [заем аннулирован]  is not null then 1 else 0 end [Признак аннулирован]

into #t1 from reports.dbo.dm_Factor_Analysis
where cast(Одобрено as date) >=cast(getdate()-@num as date)

drop table if exists #comm_stg

select  a.НомерЗаявки,ДатаВзаимодействия,	ВремяВзаимодействия ,	Описание into #comm_stg
from reports.dbo.dm_Все_коммуникации_На_основе_отчета_из_crm a join #t1 b on a.НомерЗаявки=b.Номер
where Описание <>''


drop table if exists #comm

select a.НомерЗаявки, STRING_AGG('"'+Описание+'"', '
') within group (order by ДатаВзаимодействия desc,	ВремяВзаимодействия desc) комментарии into #comm from #comm_stg a

group by a.НомерЗаявки
order by 1


--SELECT TOP 100 * FROM reports.dbo.dm_Все_коммуникации_На_основе_отчета_из_crm 

drop table if exists #f

select a.*, b.комментарии into #f from #t1 a
left join #comm b on a.Номер=b.НомерЗаявки


begin tran
--drop table if exists dbo.[витрина с одобренными заявками и комментариями рарус]
--select * into dbo.[витрина с одобренными заявками и комментариями рарус] from #f

delete from dbo.[витрина с одобренными заявками и комментариями рарус] where Одобрено >=cast(getdate()-@num as date)
insert into dbo.[витрина с одобренными заявками и комментариями рарус]
select * from #f
commit tran
	
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'CBD04081-199B-40C2-A2BE-96FCE099A04A'
--select * from #comm
/*

declare @appr_at_since date = @appr_at_since_ssrs

SELECT   [Номер]
      ,[Одобрено]
      ,[Сумма одобренная]
      ,[product]
      ,[ТекущийСтатус]
      ,[isInstallment]
      ,[ФИО]
      ,[Место cоздания]
      ,[РекомендованнаяСтавка]
      ,[created]
      ,[комментарии]

  FROM [Analytics].[dbo].[витрина с одобренными заявками и комментариями рарус]
  where [Одобрено]>=@appr_at_since

  declare @num nvarchar(255) = @num_ssrs
  declare @reason nvarchar(255) = @reason_ssrs
  declare @comment nvarchar(max) = @comment_ssrs
  declare @author nvarchar(255) = @author_ssrs

--select '19012110380001' номер, cast('' as nvarchar(255)) Причина, cast('' as nvarchar(255))  Комментарий, cast('' as nvarchar(255)) Автор, getdate() as created into dbo.[Прчины отказов по заявкам]
--delete from dbo.[Прчины отказов по заявкам]
  
if @num <> '' 

begin
begin tran
--drop table dbo.[Прчины отказов по заявкам]


  insert into analytics.dbo.[Прчины отказов по заявкам]
  select 
  @num,
  @reason,
  @comment,
  @author,
  getdate()


select 'проведено добавление заявки
'+@num result

commit tran
end

if @num = '' 
begin
select 'обновление заявки не проведено' result
end



grant insert  on analytics.dbo.[Прчины отказов по заявкам] to reportviewer
*/

--select * from (
--select *, ROW_NUMBER() over(partition by Номер order by created desc) rn from analytics.dbo.[Прчины отказов по заявкам]
--)x where rn=1


end