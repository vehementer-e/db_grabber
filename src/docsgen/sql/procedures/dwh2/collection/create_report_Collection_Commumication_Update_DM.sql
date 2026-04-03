


-- exec [dbo].[report_Collection_Commumication_Update_DM]
create  PROCEDURE  [collection].[create_report_Collection_Commumication_Update_DM]
 
AS
BEGIN
	SET NOCOUNT ON;
	  -- Task dwh-615
  begin tran

  delete from reports.dbo.dm_report_Collection_Commumication where CommunicationDate>=dateadd(day,-3,cast(getdate() as date))
  insert into reports.dbo.dm_report_Collection_Commumication
  select * 
  from stg.[_Collection].[v_Communications_no_double_stage]
  where CommunicationDate>=dateadd(day,-3,cast(getdate() as date))

  commit tran


  --drop table if exists reports.dbo.report_Colection_CustomerHistoryStage
  --DWH-1764 
  TRUNCATE TABLE Reports.dbo.report_Colection_CustomerHistoryStage
INSERT Reports.dbo.report_Colection_CustomerHistoryStage
(
    ObjectId,
    ChangeDate,
    ChangeDate_old,
    NewValue,
    stage,
    rn,
    rn_last
)
SELECT [ObjectId]
      ,[ChangeDate] = cast([ChangeDate] as date)
	  ,[ChangeDate_old] = cast(LAG([ChangeDate]) over(partition by [ObjectId] order by [ChangeDate]) as date)
      --,[EmployeeId]
      --,[Field]
      --,[OldValue]
      ,[NewValue]
	  , cst.Name stage
      --,[ObjectId]
      --,[Metadata]
	  , rn = ROW_NUMBER() over(partition by [ObjectId], cast([ChangeDate] as date) order by [ChangeDate] )
	  , rn_last = ROW_NUMBER() over(partition by [ObjectId] order by [ChangeDate] desc)
	  --into reports.dbo.report_Colection_CustomerHistoryStage
  FROM [Stg].[_Collection].[CustomerHistory] ch
  left join [Stg].[_Collection].collectingStage cst on cst.Id =  ch.NewValue
  where Field = 'Стадия коллектинга'
 

 --select * from #stage  order by objectid, changedate desc  where rn = 1
 delete from reports.dbo.report_Colection_CustomerHistoryStage where rn>1

END

