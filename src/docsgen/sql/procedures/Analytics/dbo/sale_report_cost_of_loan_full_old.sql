CREATE proc [dbo].[sale_report_sms_distribution] as
begin


drop table if exists #lh

--select cast(id as nvarchar(36)) id , UF_PHONE Телефон, is_inst_lead is_inst, UF_REGISTERED_AT Дата into #lh from Feodor.dbo.dm_leads_history_light
--where [Канал от источника]<>'CPA нецелевой'	 and is_inst_lead =1


   --insert into #lh
select id, UF_PHONE Телефон, is_inst_lead is_inst, UF_REGISTERED_AT Дата  into #lh   from Feodor.dbo.lead 
where [Канал от источника]<>'CPA нецелевой'	 and is_inst_lead =1
drop table if exists #fl


select id, Телефон Телефон, IsInstallment is_inst, [Дата лида] Дата into #fl from v_feodor_leads
where IsInstallment=1

drop table if exists #fa

select Номер, Телефон Телефон, IsInstallment is_inst, [Верификация КЦ]  Дата into #fa from v_fa
where ispts=0


		drop table if exists #a


SELECT  
       a.[ДатаSMS]
	   ,cast(format( ДатаSMS   , 'yyyy-MM-01') as date) МесяцСМС
    --  ,a.[Наличие в системах]
      ,a.[Частей]
    --  ,a.[Длина]
    --  ,a.[body]
    --  ,a.[Способ связи]
    --  ,a.[Имя шаблона]
      ,a.[Текст шаблона]   [Текст шаблона]
     -- ,a.[Дата коммуникации]
     -- ,a.[communication_id]
      ,a.[Источник коммуникации]   [Источник коммуникации]
     -- ,a.[guid]
     -- ,a.[Дата]
     -- ,a.[ТекстСообщения]
     -- ,a.[id]
	  ,case when 	 a.[Имя шаблона] = 'Предложение оформить займ в ЛКК' then 1  end isInstallment_Шаблон
	  ,lead.is_inst is_inst_lead
	  ,operator_call.is_inst is_inst_operator_call
	  ,request.is_inst is_inst_request
	  into #a
  FROM [Analytics].[_birs].[sms_details]  a
  outer apply (SELECT top 1 is_inst
FROM #lh b
WHERE b.Телефон = a.[Способ связи]
	AND b.Дата BETWEEN dateadd(day, - 1, cast(a.[Дата коммуникации] AS DATE))
		AND a.[Дата коммуникации]

		) lead
outer apply (SELECT top 1 is_inst

FROM #fl b
WHERE b.Телефон = a.[Способ связи]
	AND b.Дата BETWEEN dateadd(day, - 1, cast(a.[Дата коммуникации] AS DATE))
		AND a.[Дата коммуникации]

		) operator_call	 			 
outer apply (SELECT top 1 is_inst
FROM #fa b
WHERE b.Телефон = a.[Способ связи]
	AND b.Дата BETWEEN dateadd(day, - 1, cast(a.[Дата коммуникации] AS DATE))
		AND a.[Дата коммуникации]

		) request

		where a.ДатаSMS >='20250301'

		--select * into sms_pts_bz_old from sms_pts_bz

		drop table if exists sms_pts_bz


  --where cast(format( ДатаSMS   , 'yyyy-MM-01') as date)   = '20230601'
	 ;
   with v as (
  select *
  ,case when  isnull(is_inst_lead, 0) 	    +
  isnull(is_inst_operator_call, 0)+
  isnull(is_inst_request, 0) 	    +
  isnull(isInstallment_Шаблон, 0) >0 then 1 else 0 end is_inst	     
  
  from #a
  )

  select    МесяцСМС,  [Источник коммуникации], is_inst, [Текст шаблона], sum(isnull(Частей, 1) ) Частей, count(*) cnt  into sms_pts_bz from v 
  group by 	МесяцСМС,	[Источник коммуникации],  is_inst , [Текст шаблона]
  order by 	МесяцСМС,	[Источник коммуникации],  is_inst , [Текст шаблона]



 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации], Частей, is_inst   ) select '2022.11.01' , 'CRM' , 	123302, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2022.12.01' , 'CRM' , 	126778, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.01.01' , 'CRM' , 	129210, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.02.01' , 'CRM' , 	131115, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.03.01' , 'CRM' , 	157929, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.04.01' , 'CRM' , 	175233, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.05.01' , 'CRM' , 	189251, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.06.01' , 'CRM' , 	194706, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.07.01' , 'CRM' , 	205180, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.08.01' , 'CRM' , 	284425, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.09.01' , 'CRM' , 	253220, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.10.01' , 'CRM' , 	283903, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.11.01' , 'CRM' , 	211275, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.12.01' , 'CRM' , 	480598, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.01.01' , 'CRM' , 	223500, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.02.01' , 'CRM' , 	223115, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.03.01' , 'CRM' , 	225635, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.04.01' , 'CRM' , 	197652, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.05.01' , 'CRM' , 	152674, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.06.01' , 'CRM' , 	169119, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.07.01' , 'CRM' , 	175846, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.08.01' , 'CRM' , 	205116, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.09.01' , 'CRM' , 	162018, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.10.01' , 'CRM' , 	171448, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.11.01' , 'CRM' , 	169964, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.12.01' , 'CRM' , 	177145, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2025.01.01' , 'CRM' , 	206645, 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2025.02.01' , 'CRM' , 	26001,  0


 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2022.11.01' , 'CRM',   73809 , 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2022.12.01' , 'CRM',   98270 , 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.01.01' , 'CRM',   145442, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.02.01' , 'CRM',   179803, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.03.01' , 'CRM',   233050, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.04.01' , 'CRM',   156486, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.05.01' , 'CRM',   183552, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.06.01' , 'CRM',   174253, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.07.01' , 'CRM',   189073, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.08.01' , 'CRM',   212445, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.09.01' , 'CRM',   223937, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.10.01' , 'CRM',   290828, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.11.01' , 'CRM',   263914, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2023.12.01' , 'CRM',   257086, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.01.01' , 'CRM',   168316, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.02.01' , 'CRM',   169713, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.03.01' , 'CRM',   165478, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.04.01' , 'CRM',   173625, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.05.01' , 'CRM',   136765, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.06.01' , 'CRM',   118573, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.07.01' , 'CRM',   140855, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.08.01' , 'CRM',   184378, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.09.01' , 'CRM',   188072, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.10.01' , 'CRM',   169095, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.11.01' , 'CRM',   155690, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2024.12.01' , 'CRM',   135767, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2025.01.01' , 'CRM',   147051, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst    ) select '2025.02.01' , 'CRM',   17754,  1  



 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2022.11.01' ,'Space' , 	106174	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2022.12.01' , 'Space' , 	104866	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.01.01' , 'Space' , 	103321	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.02.01' , 'Space' , 	109759	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.03.01' , 'Space' , 	155745	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.04.01' , 'Space' , 	174094	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.05.01' , 'Space' , 	142305	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.06.01' , 'Space' , 	130011	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.07.01' , 'Space' , 	127488	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.08.01' , 'Space' , 	132103	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.09.01' , 'Space' , 	128823	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.10.01' , 'Space' , 	134799	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.11.01' , 'Space' , 	148683	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.12.01' , 'Space' , 	191268	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.01.01' , 'Space' , 	141473	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.02.01' , 'Space' , 	108252	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.03.01' , 'Space' , 	113744	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.04.01' , 'Space' , 	142815	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.05.01' , 'Space' , 	224976	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.06.01' , 'Space' , 	124214	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.07.01' , 'Space' , 	158812	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.08.01' , 'Space' , 	129016	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.09.01' , 'Space' , 	137415	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.10.01' , 'Space' , 	178226	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.11.01' , 'Space' , 	141206	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.12.01' , 'Space' , 	159930	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2025.01.01' , 'Space' , 	155335	  , 0
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2025.02.01' , 'Space' , 	22299	  ,  0


 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2022.11.01' , 'Space',   267, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2022.12.01' , 'Space',   359, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.01.01' , 'Space',   317, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.02.01' , 'Space',   377, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.03.01' , 'Space',   722, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.04.01' , 'Space',   550, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.05.01' , 'Space',   656, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.06.01' , 'Space',   478, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.07.01' , 'Space',   561, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.08.01' , 'Space',   680, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.09.01' , 'Space',   875, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.10.01' , 'Space',   1438, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.11.01' , 'Space',   2419, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2023.12.01' , 'Space',   1291, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.01.01' , 'Space',   700, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.02.01' , 'Space',   685, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.03.01' , 'Space',   718, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.04.01' , 'Space',   997, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.05.01' , 'Space',   601, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.06.01' , 'Space',   478, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.07.01' , 'Space',   443, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.08.01' , 'Space',   474, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.09.01' , 'Space',   518, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.10.01' , 'Space',   547, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.11.01' , 'Space',   386, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2024.12.01' , 'Space',   341, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2025.01.01' , 'Space',   570, 1
 insert into sms_pts_bz (МесяцСМС, [Источник коммуникации],  Частей, is_inst   ) select '2025.02.01' , 'Space',   68,  1  




exec python 'sql2gs("""
select a.*, b.ptsIssued, b.bezzalogIssued from (
 select   a.[МесяцСМС] month
 , sum(case when a.is_inst = 0 and isnull(a.[Источник коммуникации], '''') <>''Space'' then  a.[Частей] end ) salePtsSmsPart
 , sum(case when a.is_inst = 1 and isnull(a.[Источник коммуникации], '''') <>''Space'' then  a.[Частей] end ) saleBezzalogSmsPart
 , sum(case when a.is_inst = 0 and isnull(a.[Источник коммуникации], '''') =''Space'' then  a.[Частей] end )  spacePtsSmsPart
 , sum(case when a.is_inst = 1 and isnull(a.[Источник коммуникации], '''') =''Space'' then  a.[Частей] end )  spaceBezzalogSmsPart

 
 from sms_pts_bz a
where a.[МесяцСМС] >=''20221101''
group by  a.[МесяцСМС]
) a
left join (select issuedMonth month
, count(case  when ispts=1 then issuedSum end ) ptsIssued
, count(case  when ispts=0 then issuedSum end )  bezzalogIssued
from v_fa group by issuedMonth


) b on a.month=b.month
order by  a.month
""", "1BYM_J4tJLjiSBpvydcvBLZI1sMk-HA4KR3w_fvqQgBs", sheet_name = "распределение смс по продуктам DWH" )', 1



exec python 'sql2gs("""
;
with v as (
select cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, ДатаЛидаЛСРМ), 0) as date) month
, case
when [канал от источника]=''cpa нецелевой'' then 1
when is_inst_lead = 0 then 1
when is_inst_lead = 1 then 0 end is_pts2 , seconds_to_pay
from Feodor.dbo.lead_cube  
)

select month
, replace( format( sum(case when is_pts2=1 then seconds_to_pay end ) / (sum(seconds_to_pay )+0.0), ''0.000%'') , ''.'', '','') percPts
, replace( format( sum(case when is_pts2=0 then seconds_to_pay end ) / (sum(seconds_to_pay )+0.0), ''0.000%'') , ''.'', '','') percBezzalog
from v
where month>=''20250301''
group by month
order by 1
""", "1BYM_J4tJLjiSBpvydcvBLZI1sMk-HA4KR3w_fvqQgBs", sheet_name = "распределение связи по продуктам DWH" )', 1



  end