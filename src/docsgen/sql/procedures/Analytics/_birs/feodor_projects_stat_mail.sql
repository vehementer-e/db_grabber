CREATE proc _birs.feodor_projects_stat_mail
as
begin




drop table if exists #dm_feodor_projects
select  Name, max(new_name) new_name into #dm_feodor_projects from feodor.dbo.dm_feodor_projects
where new_name is not null
group by Name

  drop table if exists #t1
SELECT 
      [creationdate день],
	  [CompanyNaumen]
	  , sum([creationdate]) [Поступило]
	  , sum([creationdate_day_in_day]) [Обработано]
,case when     [creationdate день] = cast(getdate()-1  as date) then 1 else 0 end as report_day
into #t1

  FROM [Feodor].[dbo].[dm_leads_history_cube_by_ДатаЛидаЛСРМ]
  where [creationdate день] between cast(getdate()-7  as date) and cast(getdate()-1  as date)
  group by  [creationdate день],
	  [CompanyNaumen]

	  select 
    a.[creationdate день] 
,   isnull(b.new_Name,  a.[companynaumen] )    [Кампания обзвона]
,   a.[Поступило] 
,   a.[Обработано] 
,   a.[report_day] 

from 
#t1 a
left join #dm_feodor_projects b on a.[companynaumen]=b.Name



end