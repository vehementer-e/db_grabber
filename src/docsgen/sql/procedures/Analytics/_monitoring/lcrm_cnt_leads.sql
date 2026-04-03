CREATE   proc [_monitoring].[lcrm_cnt_leads]


as
begin


drop table if exists 	#tmp_table_lcrm_leads_full

SELECT 'stg._LCRM.lcrm_leads_full' [Имя таблицы]
      ,cast(UF_REGISTERED_AT as date) [Дата лида]
      ,count(ID) [Кол-во строк за вчера]
	  ,count(distinct ID) [Кол-во уникальных id]
	  ,count(case when  [UF_PHONE] is null then ID end ) [Кол-во строк с пустым phonenumber/uf_phone]
	  --,(select count(ID) from stg._LCRM.lcrm_leads_full where [UF_PHONE] is null and cast(UF_REGISTERED_AT as date) = cast(getdate()-1 as date)) [Кол-во строк с пустым phonenumber/uf_phone]
	  ,cast(getdate() as date) [Дата вставки]
  
  into #tmp_table_lcrm_leads_full
  FROM stg._LCRM.lcrm_leads_full
  (NOLOCK)
  WHERE cast(UF_REGISTERED_AT as date) = cast(getdate()-1 as date)
  GROUP BY cast(UF_REGISTERED_AT as date)



drop table if exists 	 #tmp_table_lcrm_leads_full_cnt

SELECT 'stg._LCRM.lcrm_leads_full_calculated' [Имя таблицы]
      ,cast(UF_REGISTERED_AT as date) [Дата лида]
      ,count(ID) [Кол-во строк за вчера]
	  ,count(distinct ID) [Кол-во уникальных id]
	  	  ,count(case when  phonenumber is null then ID end ) [Кол-во строк с пустым phonenumber/uf_phone]

	  ,cast(getdate() as date) [Дата вставки]
  
  into  #tmp_table_lcrm_leads_full_cnt 
  FROM stg._LCRM.lcrm_leads_full_calculated
  (NOLOCK)
  WHERE cast(UF_REGISTERED_AT as date) = cast(getdate()-1 as date)
  GROUP BY cast(UF_REGISTERED_AT as date)



drop table if exists 	#tmp_table_dm_lcrm_leads_for_report

SELECT '[Analytics].[dbo].[dm_lcrm_leads_for_report]' [Имя таблицы]
      ,cast(UF_REGISTERED_AT_date as date) [Дата лида]
      ,count(ID) [Кол-во строк за вчера]
	  ,count(distinct ID) [Кол-во уникальных id]
		  ,count(case when  phonenumber is null then ID end ) [Кол-во строк с пустым phonenumber/uf_phone]

	  ,cast(getdate() as date) [Дата вставки]
	
  into #tmp_table_dm_lcrm_leads_for_report 
  FROM [Analytics].[dbo].[dm_lcrm_leads_for_report]
  (NOLOCK)
  WHERE cast(UF_REGISTERED_AT_date as date) = cast(getdate()-1 as date)
  GROUP BY cast(UF_REGISTERED_AT_date as date)



drop table if exists #lcrm_cnt_leads_log_

select * into #lcrm_cnt_leads_log_ from #tmp_table_lcrm_leads_full
union all
select * from #tmp_table_lcrm_leads_full_cnt
union all
select * from #tmp_table_dm_lcrm_leads_for_report

insert into _monitoring.lcrm_cnt_leads_log	    
select *  from #lcrm_cnt_leads_log_


declare @a1 nvarchar(max) = 'Не уникальные ID'
declare @message1 nvarchar(max) = (select STRING_AGG ([Имя таблицы] + '-' + @a1 + '-' + CONVERT (varchar (10), [Кол-во строк за вчера] - [Кол-во уникальных id]), ', ') from #lcrm_cnt_leads_log_ where [Кол-во строк за вчера] != [Кол-во уникальных id])

if @message1 is not null
exec log_email 'DQ. Lcrm leads defect', 'p.ilin@techmoney.ru', @message1

declare @a2 nvarchar(max) = 'Пустой номер'
declare @message2 nvarchar(max) = (select STRING_AGG ([Имя таблицы] + '-' + @a2 + '-' + CONVERT (varchar (10), [Кол-во строк с пустым phonenumber/uf_phone]), ', ') from #lcrm_cnt_leads_log_ where [Кол-во строк с пустым phonenumber/uf_phone] > 0)

if @message2 is not null
exec log_email 'DQ. Lcrm leads defect', 'p.ilin@techmoney.ru', @message2

end