


-- Usage: запуск процедуры с параметрами
-- EXEC [_yandexmetrica].[CustomReport_postloader]
--      @ReportName = <value>,
--      @ReportDateFrom = <value>,
--      @ReportDateTo = <value>;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure  [_yandexmetrica].[CustomReport_postloader]
 @ReportName nvarchar(255)
,@ReportDateFrom date
,@ReportDateTo date

as
begin
-- dwh-543
  set nocount on
/*
  declare @reportName nvarchar(255)='CustomReport1'
        , @ReportDateFrom date=cast(getdate() as date)
        , @ReportDateTo date=dateadd(day,1,cast(getdate() as date))
*/
  drop table if exists #ya

  --select count(*) FROM [_yandexmetrica].[reports]
  --select * FROM [_yandexmetrica].[reports]
  declare @created datetime

  select @created=max(created) from [_yandexmetrica].[reports]  where ReportName=@ReportName and ReportDateFrom=@ReportDateFrom and ReportDateTo=@ReportDateTo


  select * into #ya FROM [_yandexmetrica].[reports] where ReportName=@ReportName and ReportDateFrom=@ReportDateFrom and ReportDateTo=@ReportDateTo and created=@created


  drop table if exists #rows

  SELECT rn= row_number() over (order by (select null)),
         format(row_number() over (order by (select null)),'0')+char(9)+s.value line
    into #rows
    FROM #ya
    cross apply string_split([ReportData],char(10)) s


  drop table if exists #t
  create table #t ( rn	bigint
                  , fn	bigint
                  , value	nvarchar(2048)
                  )

  declare @n bigint
  set @n=(select max(rn) from #rows)

  --select @n

  declare @i bigint=2

  while @i<@n
  begin
        insert into #t
        select rn,fn= row_number() over (partition by rn order by (select null))
             , f.value
          from #rows 
         cross apply string_split(line,char(9)) f
         where rn>@i and rn<=(@i+100)
        
         set @i=@i+100
  end 


 --select * from #t order by rn,fn
 DROP TABLE IF EXISTS #REPORT
  select rn
    --   , [1]  as rn1
       , [2]  as AdFormat
       , [3]  as AdGroupId
       , [4]  as AdGroupName
       , [5]  as AdId
       , [6]  as AdNetworkType
       , [7]  as Age
       , [8]  as AvgClickPosition
       , [9]  as AvgCpc
       , [10] as AvgPageviews
       , [11] as BounceRate
       , [12] as Bounces
       , [13] as CampaignId
       , [14] as CampaignName
       , [15] as CampaignType
       , [16] as CarrierType
       , [17] as Clicks
       , [18] as ClickType
       , [19] as ConversionRate
       , [20] as Conversions
       , [21] as Cost
       , [22] as CostPerConversion
       , [23] as Criterion
       , [24] as CriterionId
       , [25] as CriterionType
       , [26] as Date
       , [27] as Device
       , [28] as ExternalNetworkName
       , [29] as Gender
       , [30] as GoalsRoi
       , [31] as LocationOfPresenceId
       , [32] as LocationOfPresenceName
       , [33] as MatchType
       , [34] as MobilePlatform
       , [35] as Placement
       , [36] as Profit
       , [37] as Revenue
       , [38] as RlAdjustmentId
       , [39] as Sessions
       , [40] as Slot
       , [41] as TargetingLocationId
       , [42] as TargetingLocationName
    into #report
    FROM (SELECT fn
               , rn
               , value   
            FROM #t
         ) AS ST  
          PIVOT ( max(value)  
          FOR fn IN ( [1], [2], [3], [4] ,[5], [6], [7], [8], [9], [10],[11], [12], [13], [14] ,[15], [16], [17], [18], [19], [20], [21], [22], [23], [24] ,[25], [26], [27], [28], [29], [30],[31], [32], [33], [34] ,[35], [36], [37], [38], [39], [40],[41],[42])  
          ) AS PivotTable
          order by 1


--drop table if exists [_yandexmetrica].CustomReport

  delete 
  from [_yandexmetrica].CustomReport 
  where ReportName      = @ReportName
    and ReportDateFrom  = @ReportDateFrom
    and ReportDateTo    = @ReportDateTo
     
  insert into [_yandexmetrica].CustomReport

  select r.*
       , getdate() Created
       , getdate() Updated 
       , @ReportName      ReportName
       , @ReportDateFrom  ReportDateFrom
       , @ReportDateTo    ReportDateTo
       
    --into [_yandexmetrica].CustomReport
    from #report r
   where AdGroupId is not NULL


  --select * from [_yandexmetrica].CustomReport where ReportDateFrom ='2020-06-19' order by 1

  drop table if exists #dm
  ;
  with last_report as (
  select Date,ReportName,max(created) max_created from [_yandexmetrica].CustomReport
  where ReportDateFrom=@ReportDateFrom and @ReportDateTo=ReportDateTo and ReportName=@ReportName
  group by Date,ReportName
  )

  select cr.* into #dm from  [_yandexmetrica].CustomReport cr join last_report lr on lr.max_created=cr.Created and lr.ReportName=cr.ReportName and lr.Date=cr.date
  
 --select top 10 * from [_yandexmetrica].CustomReport
 --select max(len(CarrierType)) from [_yandexmetrica].CustomReport
 
 --drop table if exists  reports.dbo.dm_yandexCustomReport
 begin tran
  delete from reports.dbo.dm_yandexCustomReport where ReportName=@ReportName and date in (select distinct date from #dm)
  insert into reports.dbo.dm_yandexCustomReport
  select AdFormat                         = cast(AdFormat                       as nvarchar(10))
       , AdGroupId                        = cast(AdGroupId                      as bigint)
       , AdGroupName                      = cast(AdGroupName                    as nvarchar(255))
       , AdId                             = cast(AdId                           as bigint)
       , AdNetworkType                    = cast(AdNetworkType                  as nvarchar(20))
       , Age                              = cast(Age                            as nvarchar(18))
       , AvgClickPosition                 = cast(AvgClickPosition               as nvarchar(10))
       , AvgCpc                           = cast(AvgCpc                         as nvarchar(10))
       , AvgPageviews                     = cast(AvgPageviews                   as nvarchar(10))
       , BounceRate                       = cast(BounceRate                     as nvarchar(12))
       , Bounces                          = cast(Bounces                        as bigint)
       , CampaignId                       = cast(CampaignId                     as bigint)
       , CampaignName                     = cast(CampaignName                   as nvarchar(255))
       , CampaignType                     = cast(CampaignType                   as nvarchar(40))
       , CarrierType                      = cast(CarrierType                    as nvarchar(20))
       , Clicks                           = cast(Clicks                         as bigint)
       , ClickType                        = cast(ClickType                      as nvarchar(16))
       , ConversionRate                   = cast(ConversionRate                 as nvarchar(20))
       , Conversions                      = cast(Conversions                    as nvarchar(20))
       , Cost                             = cast(Cost                           as float)
       , CostPerConversion                = cast(CostPerConversion              as nvarchar(20))
       , Criterion                        = cast(Criterion                      as nvarchar(255))
       , CriterionId                      = cast(CriterionId                    as nvarchar(30))
       , CriterionType                    = cast(CriterionType                  as nvarchar(40))
       , Date                             = cast(Date                           as date)
       , Device                           = cast(Device                         as nvarchar(50))
       , ExternalNetworkName              = cast(ExternalNetworkName            as nvarchar(24))
       , Gender                           = cast(Gender                         as nvarchar(20))
       , GoalsRoi                         = cast(GoalsRoi                       as nvarchar(20))
       , LocationOfPresenceId             = cast(LocationOfPresenceId           as bigint)
       , LocationOfPresenceName           = cast(LocationOfPresenceName         as nvarchar(80))
       , MatchType                        = cast(MatchType                      as nvarchar(30))
       , MobilePlatform                   = cast(MobilePlatform                 as nvarchar(20))
       , Placement                        = cast(Placement                      as nvarchar(100))
       , Profit                           = cast(Profit                         as float)
       , Revenue                          = cast(Revenue                        as float)
       , RlAdjustmentId                   = cast(RlAdjustmentId                 as nvarchar(4))
       , Sessions                         = cast(Sessions                       as bigint)
       , Slot                             = cast(Slot                           as nvarchar(24))
       , TargetingLocationId              = cast(TargetingLocationId            as bigint)
       , TargetingLocationName            = cast(TargetingLocationName          as nvarchar(80))
       , Created                          
       , Updated                          
       , ReportName                       = cast(ReportName                     as nvarchar(255))
       , ReportDateFrom                   
       , ReportDateTo                     
  --into reports.dbo.dm_yandexCustomReport
  from #dm
  commit tran


end
