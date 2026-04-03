

-- exec [dbo].[report_Collection_CommumicationByParameter] null,null,'Система,Зайцева Фаина Николаевна',null,null,null,null,null
--exec [dbo].[report_Collection_CommumicationByParameter] '2020-11-01','2020-11-20', 'Система,Комардина Татьяна Михайловна', 'Исходящий звонок,Смс', 'Closed,Legal,Soft,Current,Middle,NULL,Hard,СБ,HardFraud,ИП,Prelegal,Skip,Predelinquency', 'NULL,Клиент,Нет контакта,Третье лицо', 'СМЫСЛОВ ДЕНИС НИКОЛАЕВИЧ', null
CREATE  PROCEDURE  [dbo].[report_Collection_CommumicationByParameter_test]

--declare
@dtfrom date
, @dtto date
, @manager nvarchar(max)
, @communicationtype nvarchar(max)
, @ReportParameterStage nvarchar(max)
, @ReportParameterContactType nvarchar(max)
, @FIO nvarchar(max)
, @NumberDeal  nvarchar(max)
 
AS
BEGIN
	SET NOCOUNT ON;
	--
--	declare @manager nvarchar(max)
--	,@dtfrom date,
--@dtto date,
-- @communicationtype nvarchar(max)
--, @ReportParameterStage nvarchar(max)
--, @ReportParameterContactType nvarchar(max)
--, @FIO nvarchar(max)
--, @NumberDeal  nvarchar(max)

	if @manager is null 
	begin
	Set @manager = 'Система,Зайцева Фаина Николаевна'
	end

	if @communicationtype is null 
	begin
	Set @communicationtype = 'Система,Исходящий звонок'
	end

	if @dtfrom is null 
	begin
	Set @dtfrom = GetDate()
	end

	if @dtto is null 
	begin
	Set @dtto = GetDate()
	end

	if isnull(@ReportParameterStage,'') = '' 
	begin
	Set @ReportParameterStage = 'Soft,Middle'
	end

	if isnull(@ReportParameterContactType,'') = ''
	begin
	Set @ReportParameterContactType = 'Клиент,Тест'
	end

	if isnull(@FIO,'') = ''
	begin
	Set @FIO = '%'
	end

	if isnull(@NumberDeal,'') = ''
	begin
	Set @NumberDeal = '%'
	end

	print @ReportParameterStage;

--	drop table if exists devdb.dbo.rpt1
--Select value, GetDate() as datedt
--into devdb.dbo.rpt1
--from string_split(@ReportParameterContactType,',')
----select * from devdb.dbo.rpt1

--insert into devdb.dbo.rpt1
--Select value, GetDate() as datedt
--from string_split(@ReportParameterStage,',')


---- получим переходы
drop table if exists #stage;
with stage as
(
SELECT [Идентификатор перехода]
      ,[CustomerId]
	  ,[TransitionDate_future] = isnull(LEAD([TransitionDate]) over(partition by [CustomerId] order by [TransitionDate]), '2030-11-12 13:03:16') 
      ,[TransitionDate]
	  ,[TransitionDate_old] = LAG([TransitionDate]) over(partition by [CustomerId] order by [TransitionDate]) 
      ,[dpd]
      ,[Старая стадия клиента]
      ,[Новая стадия клиента]
      ,[Отв. взыскатель на старой стадии]
      ,[Отв. взыскатель на новой стадии]
      ,[Причина перехода на новую стадию]
  FROM [Stg].[_Collection].[v_CollectingStageTransition_with_Reason]
  )
  
  select * 
  into #stage
  from (
  select 
  --[Идентификатор перехода]
  --    ,
	  [CustomerId]
	  ,[TransitionDate_future] 
      ,[TransitionDate]
	  --,[TransitionDate_old]
      ,[dpd]
      --,[Старая стадия клиента]
      ,[Новая стадия клиента]
	  ,stage = [Новая стадия клиента]
       --,[Отв. взыскатель на старой стадии]
      ,[Отв. взыскатель на новой стадии] = [Отв. взыскатель на старой стадии]
      ,[Причина перехода на новую стадию]
	  from stage   --where CustomerId =13920  --order by CustomerId 
  union all
 select 
	   --[Идентификатор перехода]
    --  ,
	  [CustomerId]
	  ,[TransitionDate_future]  = [TransitionDate]
      ,[TransitionDate] = cast('1920-10-08 00:00:00' as datetime)
	  --,[TransitionDate_old]
      ,[dpd]
      --,[Старая стадия клиента]
      ,[Новая стадия клиента] = [Старая стадия клиента]
	  ,stage = [Старая стадия клиента]
      --,[Отв. взыскатель на старой стадии]
      ,[Отв. взыскатель на новой стадии] = [Отв. взыскатель на старой стадии]
      ,[Причина перехода на новую стадию]
	  from stage   where [TransitionDate_old] is null --order by CustomerId
	  ) ff
	  --order by [TransitionDate_future] desc
--
select [Новая стадия клиента] from #stage group by [Новая стадия клиента]

drop table if exists #t 
select top 900000 
* 
into #t
from dbo.dm_report_Collection_Commumication with(nolock)
where 
case when @manager is null then '1' else manager end in (case when @manager is null then '1' else (Select value from string_split(@manager,',')) end)
--manager in (Select value from string_split(@manager,','))
and CommunicationType in (Select value from string_split(@communicationtype,',')) 
and CommunicationDate between @dtfrom and @dtto
--and case when @ReportParameterContactType is null then '1' else   PersonType end  in (
--  case when @ReportParameterContactType is null then '1' else (Select value from string_split(@ReportParameterContactType,',')) end) 
and PersonType in (Select value from string_split(@ReportParameterContactType,',')) 
and fio like  @FIO 
and Number like  @NumberDeal 


--drop table if exists #stage 
--SELECT [ObjectId]
--      ,[ChangeDate] = cast([ChangeDate] as date)
--	  ,[ChangeDate_old] = cast(LAG([ChangeDate]) over(partition by [ObjectId] order by [ChangeDate]) as date)
--      --,[EmployeeId]
--      --,[Field]
--      --,[OldValue]
--      ,[NewValue]
--	  , cst.Name stage
--      --,[ObjectId]
--      --,[Metadata]
--	  , rn = ROW_NUMBER() over(partition by [ObjectId], cast([ChangeDate] as date) order by [ChangeDate] )
--	  , rn_last = ROW_NUMBER() over(partition by [ObjectId] order by [ChangeDate] desc)
--	  into #stage
--  FROM [Stg].[_Collection].[CustomerHistory] ch
--  left join [Stg].[_Collection].collectingStage cst on cst.Id =  ch.NewValue
--  where Field = 'Стадия коллектинга'
 

-- --select * from #stage  order by objectid, changedate desc  where rn = 1
-- delete from #stage where rn>1

 --drop table if exists devdb.dbo.rpt2  --dbo.dm_report_Collection_Commumication --devdb.dbo.rpt2

select comm.CommunicationType,
	comm.CommunicationDate,
	comm.CommunicationDateTime,
	comm.Number,
	comm.Manager,
	comm.PersonType,
	comm.CommunicationResult,
	comm.fio,	
	isnull(st.stage,cst.Name) as stage

from #t comm
--left join dbo.report_Colection_CustomerHistoryStage st on st.ObjectId = comm.CustomerId and ((comm.CommunicationDate between st.ChangeDate_old and st.ChangeDate) or (comm.CommunicationDate>st.ChangeDate and st.rn_last=1))
left join #stage st on st.CustomerId = comm.CustomerId  and comm.CommunicationDateTime between st.TransitionDate and st.TransitionDate_future

left join [Stg].[_Collection].[customers] c on c.id = comm.CustomerId
  left join [Stg].[_Collection].collectingStage cst on cst.Id =  c.IdCollectingStage
where 
isnull(st.stage,cst.Name) in (Select value from string_split(@ReportParameterStage,','))
order by comm.CommunicationDateTime

--select  
--	CommunicationType,
--	CommunicationDate,
--	Number,
--	Manager,
--	PersonType,
--	CommunicationResult,
--	fio,
--	stage 
--from devdb.dbo.rpt2  --dbo.dm_report_Collection_Commumication
--where 
--stage in (Select value from string_split(@ReportParameterStage,','))
--and rn_stage = 1
--case when @ReportParameterStage is null then '1' else   stage end  in (
--case when @ReportParameterStage is null then '1' else (Select value from string_split(@ReportParameterStage,',')) end) 

  /*
 CommunicationType,
CommunicationDate,
Number,
Manager,
PersonType,
CommunicationResult,
fio,
stage

  */


END
