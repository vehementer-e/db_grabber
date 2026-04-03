





CREATE PROCEDURE [finAnalytics].[PBI_Cessia]

	
AS
BEGIN


select
a.*
,b.[Вид займа]
,b.[Группа каналов]
,b.Канал
,b.Направление
,b.[Продукт от первичного]
,b.Продукт
from dwh2.[finAnalytics].[ReestrCession] a
left join (
select
dogNum
,[Продукт] = dwh2.[finAnalytics].[nomenk2prod](nomenkGroup)
,[Вид займа] = case when [isnew] is null then 'Нет маркировки' else [isnew] end
,[Группа каналов] = case when [finChannelGroup] is null then 'Нет маркировки' else [finChannelGroup] end
,[Канал] = case when [finChannel] is null then 'Нет маркировки' else [finChannel] end
,[Продукт от первичного] = case when [prodFirst] is null then 'Нет маркировки' else [prodFirst] end
,[Направление] = case when [finBusinessLine] is null then 'Нет маркировки' else [finBusinessLine] end
,rn = ROW_NUMBER() over (Partition by dogNum order by repmonth desc)
from dwh2.finAnalytics.PBR_MONTHLY
) b on a.dogClient = b.dogNum and rn=1


END
