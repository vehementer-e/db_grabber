



-- exec [dbo].[report_Collection_Commumication_for_Cube]
create  PROCEDURE  [collection].[create_report_Collection_Commumication_for_Cube]
 
AS
BEGIN
	SET NOCOUNT ON;
/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
drop table if exists reports.dbo.dm_Collection_vc_mv_Communications
SELECT *
into reports.dbo.dm_Collection_vc_mv_Communications
  FROM [dwh2].[cubes].[vc_mv_Communications]
  where CommunicationDate > '2023-01-01'

  drop table if exists reports.dbo.dm_Collection_vc_mv_Communications_w_Orders
SELECT *, [порядок записи] =row_number() over(partition by fio, CommunicationDateTime order by Number)
, iif(row_number() over(partition by fio, CommunicationDateTime order by Number) = 1,1,0) isComm

into reports.dbo.dm_Collection_vc_mv_Communications_w_Orders
  FROM reports.dbo.dm_Collection_vc_mv_Communications

  END

