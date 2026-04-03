
--select * from report_Agreement_InterestRate
/*
select
*
--ДоговорНомер, СуммаДопУслуг, СуммаДопУслугЗаВычетомПартнерскойКомиссии 
from  dbo.report_Agreement_InterestRate_to_del
where ДоговорНомер='20012310000167'
select * from dbo.dm_sales where Код='20012310000167'

*/
CREATE     PROCEDURE [dbo].[Report_Create_Agr_IntRate_v2_1] 
-- v2_1 07-06-2021 добавлен продукт фарм страхование
AS
BEGIN

	SET NOCOUNT ON;

  declare @GetDate2000 datetime,
		  @DateStart2000_2 datetime

  set @GetDate2000 = dateadd(year,2000,getdate());
  set @DateStart2000_2 =  dateadd(month,datediff(month,0,dateadd(month,-1,@GetDate2000)),0) --dateadd(day,datediff(day,0,dateadd(day,-90,@GetDate2000)),0) 


----------заявки CRM и номер в МФО
drop table if exists #tmp_AgrIntRate_prev
select *
into #tmp_AgrIntRate_prev
from [dbo].[report_Agreement_InterestRate]
where [ДатаВыдачи] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) 


----------заявки CRM и номер в МФО
drop table if exists #crm_request_mfo_loan
select
	  [MFOContractNumber]
      ,[CRMRequestNumber]
      ,[CMRContractNumber]

into #crm_request_mfo_loan
from [dwh_new].[staging].[CRMClient_references]


drop table if exists #cmr_credproduct
select distinct 
		d.[Код] 
		,d.[Срок] 
		,cp.[Наименование] as [КредитныйПродукт] 
into #cmr_credproduct
from stg._1cCMR.[Справочник_Договоры] d with (nolock)
left join stg._1cCMR.[Справочник_КредитныеПродукты] cp on d.[КредитныйПродукт] = cp.[Ссылка]


drop table if exists #cmr_loans_state_noncancelled
 select [Договор] 
 into #cmr_loans_state_noncancelled
 from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock)  
 where [Статус]<>0x80E400155D64100111E7C5361FF4393D 


-------------------- Бизнес Займы
drop table if exists #BusinessLoans
select [ДатаВыдачи]
, cast([ДатаВыдачи] as datetime) [ДатаВремя]
, [НомерДоговора] as [number]

, [КредитныйПродукт]
, [СуммаЗайма]
, [ПроцентнаяСтавка]
, [СрокЗайма]
, [СтавкаНаСумму]

, created
, ishistory
, updated
into #BusinessLoans
from dbo.dm_SalesBusiness r with (nolock)
--left join [Stg].[_p2p].[request_statuses] s on r.[request_status_guid]=s.[guid]
--left join select * from [Stg].[dbo].[lcrm_tbl_full_w_chanals2] where [UF_ROW_ID] in ()) ch with (nolock) on r.[number]=ch.[UF_ROW_ID]
where ishistory=0
and r.[updated]>=cast(dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) as date)

-------------------- Займы p2p
drop table if exists #P2P
select ДатаВыдачи
, ДатаВремя
, [number]
, [СрокЗайма]
, [КредитныйПродукт]
, [СуммаЗайма]
, [ПроцентнаяСтавка]
, [СтавкаНаСумму]

, created
, ishistory
, updated
into #P2P
from dbo.dm_SalesP2P r with (nolock)
--left join [Stg].[_p2p].[request_statuses] s on r.[request_status_guid]=s.[guid]
--left join select * from [Stg].[dbo].[lcrm_tbl_full_w_chanals2] where [UF_ROW_ID] in ()) ch with (nolock) on r.[number]=ch.[UF_ROW_ID]
where
1=0
/*
ishistory=0
and r.[updated]>=cast(dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) as date)
*/
-------------------- Займы ПТС

drop table if exists #PTS
select [ДатаВыдачи] = cast([ДатаВыдачи] as date)
      --,[Дата]
      ,[ДатаВремя]
      ,[CMRДоговор]
      ,[number] = s.[Код]
	  --,cp.[Срок] [СрокЗайма]  
	  --,cp.[КредитныйПродукт]
    
	  ,[СуммаЗайма] = [Сумма]
      ,[ПроцентнаяСтавка]
      ,[СтавкаНаСумму]

      ,[Помощь бизнесу]
      ,[Страхование жизни]
      ,[РАТ]
      ,[КАСКО]
      ,[От потери работы. «Максимум»]
      ,[От потери работы. «Стандарт»]
	  ,[Телемедицина]
	  ,[Защита от потери работы]
    ,[Фарм страхование]
    ,[Фарм страхование_without_partner_bounty]

	  ,[СуммаКП] = (isnull([Помощь бизнесу],0)
					+ isnull([Страхование жизни] ,0)
					+ isnull([РАТ],0) 
					+ isnull([КАСКО],0)
					+ isnull([От потери работы. «Максимум»],0)
					+ isnull([От потери работы. «Стандарт»],0)
					+ isnull([Телемедицина],0)
					+ isnull([Защита от потери работы],0)
          + isnull([Фарм страхование],0))
      ,[СпособОформления]
      ,[lastStatus]
      ,[Вид заполнения]
      ,[channel_B]
      ,[created]
      ,[ishistory]
      ,[updated]
	  ,[СуммаКП_without_partner_bounty] = (
			ISNULL([Помощь бизнесу_without_partner_bounty]				,0.0)
			+ISNULL([Страхование жизни_without_partner_bounty]				,0.0)
			+ISNULL([РАТ_without_partner_bounty]							,0.0)
			+ISNULL([КАСКО_without_partner_bounty]							,0.0)
			+ISNULL([От потери работы. «Максимум»_without_partner_bounty]	,0.0)
			+ISNULL([От потери работы. «Стандарт»_without_partner_bounty]	,0.0)
			+ISNULL([Телемедицина_without_partner_bounty]					,0.0)
			+ISNULL([Защита от потери работы_without_partner_bounty]		,0.0)
      +isnull([Фарм страхование_without_partner_bounty],0.0)
	  )
into #PTS

from [dbo].[dm_Sales] s with (nolock)
left join #cmr_credproduct cp on s.[Код] = cp.[Код]
where ishistory = 0 --and cast([ДатаВыдачи] as date) = '2020-03-06'
and cast(s.[updated] as date) >= cast(dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) as date)
---------------------------------
--select count(*) from #PTS  where cast([ДатаВыдачи] as date) = '2020-03-19'

drop table if exists #mfo_doc_dog
select *
into #mfo_doc_dog
from [Stg].[_1cMFO].[Документ_ГП_Договор] with (nolock)
where [Номер] in (select [number] from #PTS)


drop table if exists #active_loans_cmr
SELECT 
	  min(dateadd(year,-2000,cast([Период] as datetime2))) as [Период] 
	  ,[Договор] 
	  ,d.[Код] external_id
into #active_loans_cmr
FROM [Stg].[_1cCMR].[РегистрНакопления_АктивныеДоговоры] a with (nolock)
left join stg.[_1cCMR].[Справочник_Договоры] d on a.[Договор]=d.[Ссылка]
where [Активен]=1 and [ВидДвижения]=0 and [Период] >=dateadd(year,2000, dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0))
group by [Договор] ,d.[Код]



drop table if exists #dcmnt_pep_request
select *
into #dcmnt_pep_request
from [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] with (nolock)
where [ЗаявкаНомер] in (select [number] from #PTS)

/*
----------- test2
drop table if exists #test2
select t.* ,r.*  into #test2 from #dcmnt_pep_request r
right join (select external_id ,[Период] from #active_loans_cmr) t on r.[ЗаявкаНомер]=t.external_id

select 
		case when [ДатаПодписанияПЭП]=1 and [ПЭП2]=0 and cast([Период] as date) >= '2019-08-11' then N'Да' 
			  else N'' 
		end as [ПЭП2_3пакет]
		,cast([Период] as date) [Период2]
		,*
from #test2
where cast([Период] as date) between '20200701' and '20200731' 
		and (case when [ДатаПодписанияПЭП]=1 and [ПЭП2]=0 and cast([Период] as date) >= '2019-08-11' then N'Да' else N'' end) = 'Да'

----------- end test2
*/

-------------------- Займы обычные

  drop table if exists #MainTable
  select distinct * into #MainTable from [Stg].[dbo].[aux_OfficeMFO_1c] with (nolock)

  drop table if exists #ClientLoanPoint8999
  select t2.[Контрагент] -- t2.[Ссылка] ,t2.[Дата] ,t2.[rank] ,t2.[Точка] ,o.[Код] ,o.[Наименование] 
	     , tch.Точка 
       , tch.[РП_Регион]
       , tch.[РО_Регион]
    into #ClientLoanPoint8999
    from (select d2.[Ссылка] 
               , d2.[Дата] 
               , d2.[Контрагент] 
               , d2.[Точка] --,o.[Код] 
			         , rank() over(partition by d2.[Контрагент] order by d2.[Дата] desc) as [rank]
	          from [Stg].[_1cMFO].[Документ_ГП_Договор] (nolock) d2
		       where d2.[Точка]<>0x813521A3DABA1B0047111F5BDB98FE88
			       and d2.[Контрагент] in (select [Контрагент] from [Stg].[_1cMFO].[Документ_ГП_Договор] where [Точка]=0x813521A3DABA1B0047111F5BDB98FE88) 
		     ) t2
    left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o on t2.[Точка]=o.[Ссылка]
    left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				         from #MainTable mt0
					       left join #MainTable mt1 on mt0.[ПроРодитель]=mt1.[Подчиненный]
				        where mt0.[ПодчНаим] like N'Партнер%' or mt0.[ПодчНаим] like N'ВМ%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр'
 		          ) tch -- Точка-РП-РО
	         on t2.[Точка]=tch.[ТочкаСсылка]
   where t2.[rank]=1


drop table if exists #d1
  SELECT s.[Договор],
         SumEnsur    =sum(case 
							when ДопПродукт in (0xB81300155D03491F11E958A5C7DB6817 ,0xB81B00155D4D086C11EA4C1978656E84) 
								then spdd.сумма 
							else 0 
						   end),
         SumRat      =sum(case when ДопПродукт=0xB81600155D4D0B5211E9968E54A9F742 then spdd.сумма else 0 end),
         SumKasko    =sum(case 
							when ДопПродукт in (0xB81600155D4D0B5211E9968E6C835BF9 ,0xB81B00155D4D086C11EA4C19666AF72B)
								then spdd.сумма
							else 0 
						   end),
		     SumPositiveMood =sum(case when ДопПродукт=0xB81700155D4D0B5211E9F19852274C9E or ДопПродукт=0xB81700155D4D0B5211E9F198668D9373 then spdd.сумма else 0 end),
		   --SumWLStand    =sum(case when ДопПродукт=0xB81700155D4D0B5211E9F198668D9373 then spdd.сумма else 0 end)
		     SumHelpBusiness	=sum(case when ДопПродукт=0xB80D00155D6A0B0011EA045E61D90E5C then spdd.сумма else 0 end)

		,SumCushion	=sum(case when ДопПродукт=0xA2C7005056839FE911EA968404C28E69 then spdd.сумма else 0 end)
    , sumFarmStr= sum( case when sdp.Наименование='Фарм страхование' then spdd.сумма else 0 end)
		 ,sd.[Код] as external_id
    into #d1

    from
    [Stg].[_1cCMR].[Справочник_Договоры_ДополнительныеПродукты] (nolock) spdd
    join [Stg].[_1cCMR].[Справочник_ДополнительныеПродукты] sdp on sdp.ссылка=spdd.ДополнительныйПродукт
    left join [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s  with (nolock) on s.ссылка=spdd.[ДоговорДопПродукта]
    left join [Stg].[_1cCMR].[Справочник_Договоры] sd  with (nolock) on sd.ссылка=s.[Договор]

   group by  s.[Договор] ,sd.[Код]

--select * from #d1 where external_id = '20021810000011' in (select distinct number from #P2P)
--     select * from [Stg].[_1cCMR].[Справочник_ДополнительныеПродукты] (nolock) spdd
-- select * from [Stg].[_1cCMR].[Справочник_Договоры_ДополнительныеПродукты]


drop table if exists #ssdp
  select  sd.ссылка
       , sd.[Код] as [НомерДоговора]
	   , SumEnsur    
       , SumRat      
       , SumKasko 
	     , SumPositiveMood
		 , SumHelpBusiness 
       , EnsurКод = (select top 1 s1.Код 
					 from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) 
					 where s1.[Договор] = sd.ссылка	and  ДопПродукт in (0xB81300155D03491F11E958A5C7DB6817 ,0xB81B00155D4D086C11EA4C1978656E84) )
       , RatКод   = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock)  where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81600155D4D0B5211E9968E54A9F742)
       , KaskoКод = (select top 1 s1.Код 
					 from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) 
					 where s1.[Договор]=sd.ссылка  and  ДопПродукт in (0xB81600155D4D0B5211E9968E6C835BF9 ,0xB81B00155D4D086C11EA4C19666AF72B))
	     , PositiveMoodКод = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) 
										  where s1.[Договор]=sd.ссылка and  (ДопПродукт=0xB81700155D4D0B5211E9F19852274C9E or ДопПродукт=0xB81700155D4D0B5211E9F198668D9373))
	   --, SumWLStand = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  
		 , HelpBusinessКод = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB80D00155D6A0B0011EA045E61D90E5C)

		 , [TeleMedicKod] = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81B00155D4D086C11EA69F84A182561)

		 , [CushionKod] = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xA2C7005056839FE911EA968404C28E69)
     , farmStrKod = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xA2CC005056839FE911EBC2253F4FFC8F)
     , sumFarmStr
    into #ssdp
    from #d1  d1
    left join [Stg].[_1cCMR].[Справочник_Договоры] sd with (nolock) on sd.ссылка=d1.[Договор]
--  select * /*s1.Код*/ from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1

drop table if exists #pg00
  select [_Period] 
       , [_Fld27] as [ДоговорНомер]
	   , n.[Имя] as [ID_ПлатежнойСистемы]
       , [_Fld62] as [ID_Операции]
       , [_Fld38] as [Статус]
	     , [_Fld39] as [Комментарий]
	     , rank() over (partition by [_Fld27] order by [_Period] desc) as [rank_pg0]
    into #pg00		--select n.* ,pg0.*
    from [Stg].[_1cPG].[PGPayments] (nolock) pg0
	left join [Stg].[_1cPG].[Перечисление_ПлатежныеСистемы] n on pg0.[_Fld26RRef]=n.[Ссылка]
   where [_Fld92]>0 and exists (select [Код] 
			                    from [Stg].[_1cCMR].[Справочник_Договоры] sd 
			                    where pg0.[_Fld27]=sd.[Код] and dateadd(year,-2000,sd.[Дата])>= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0)
								) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-4,Getdate())),0))


drop table if exists #max_r
;
with r as (select Договор 
                , max(Период) max_p
             from [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] (nolock) pd
            group by  Договор
          )
  select pd.договор
       , НачисляемыеПроценты
       , ПроцентнаяСтавка
    into #max_r
    from [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] (nolock) pd
    join r on r.Договор=pd.Договор and r.max_p=pd.Период
-- select * from #max_r

-- DWH-1052
drop table if exists #max_r_14_day;
with r
as
(
	select Договор    
	,      max(Период) max_p
	from      [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] (nolock) pd
	join [Stg].[_1cCMR].[Справочник_Договоры]                        sd on pd.Договор=sd.Ссылка
			and cast(pd.Период as date) between cast(sd.Дата as date) and dateadd(day, 13,cast( sd.Дата as date))
	group by Договор
)
select pd.договор
,      НачисляемыеПроценты
,      ПроцентнаяСтавка
	into #max_r_14_day
from [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] (nolock) pd
join r                                                              on r.Договор=pd.Договор
		and r.max_p=pd.Период
 --select count(*) from #max_r_14_day
 --select count(*) from #max_r

drop table if exists #lcrm_tbl_full_w_chanals2_end
 select distinct  
			[UF_ROW_ID]
			,[Канал от источника]
			,[Группа каналов] 
 into #lcrm_tbl_full_w_chanals2_end 
 from stg._LCRM.lcrm_leads_full_channel_request   ch with (nolock)
 --from [Stg].[_LCRM].[lcrm_tbl_short_w_channel] ch with (nolock)
 where [UF_ROW_ID] in (select distinct [number] 
					   from #PTS 					   
					   union all 
					   select distinct [number] 
					   from #P2P					   
					   union all 
					   select distinct [number] 
					   from #BusinessLoans)

--;

drop table if exists #mfo_entering_point
select z.[Ссылка],z.[Дата],z.[Номер],z.[Фамилия],z.[Имя],z.[Отчество],svz.[Имя] as [СпособВыдачиЗаймаНаим]
					           , dzsvz.[Имя] as [дз_СпособВыдачиЗаймаНаим],dkr.[Имя] as [ДокредитованиеНаим]
					           , kp.[Наименование] as [КредитныйПродуктНаим],ms.[Имя] as [МестоСозданияЗаявкиНаим]
					           , ttvz.[ТочкаВхода],ttvz.[ТочкаВходаНаим] as [ТочкаВходаЗаявкиНаим] ,o.[Наименование] as [ТочкаНаим]
into #mfo_entering_point
from [Stg].[_1cMFO].[Документ_ГП_Заявка] z  with (nolock)
	left join [Stg].[_1cMFO].[Перечисление_СпособыВыдачиЗаймов] svz with (nolock) --y
		on z.[СпособВыдачиЗайма]=svz.[Ссылка]
	left join [Stg].[_1cMFO].[Перечисление_дз_СпособыВыдачиЗайма] dzsvz with (nolock) --y
		on z.[дз_СпособВыдачиЗайма]=dzsvz.[Ссылка]
	left join [Stg].[_1cMFO].[Перечисление_ВидыДокредитования] dkr with (nolock) --y
		on z.[Докредитование]=dkr.[Ссылка]
	left join [Stg].[_1cMFO].[Перечисление_ГП_МестаСозданияЗаявки] ms with (nolock) --y
		on z.[МестоСозданияЗаявки]=ms.[Ссылка]
	left join [Stg].[_1cMFO].[Справочник_ГП_КредитныеПродукты] kp with (nolock) --y
		on z.[КредитныйПродукт]=kp.[Ссылка]
	left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o with (nolock) --y
		on z.[Точка]=o.[Ссылка]
	left join ( select tvz.[ПредварительнаяЗаявка],pz.[Номер] as [НомерПредвЗаявки],pz.[Дата] as [ДатаПредвЗаявки],tvz.[ТочкаВхода],tv.[Наименование] as [ТочкаВходаНаим]
				from [Stg].[_1cMFO].[РегистрСведений_ТочкиВходаЗаявок] tvz with (nolock)
					left join [Stg].[_1cMFO].[Справочник_НастройкиПринадлежностиКРекламнымКомпаниям] tv with (nolock) --точка входа (справочник)
						on tvz.[ТочкаВхода]=tv.[Ссылка]
					left join [Stg].[_1cMFO].[Документ_DZ_ПредварительнаяЗаявка] pz with (nolock) -- предварительная заявка
						on tvz.[ПредварительнаяЗаявка]=pz.[Ссылка]
			  ) ttvz
					          on z.[ПредварительнаяЗаявка]=ttvz.[ПредварительнаяЗаявка]
		                --		 where z.[ПометкаУдаления]=0x00 and cast(z.[Дата] as date)>='4019-04-30'
where z.[Номер] in (select distinct [number] 
					   from #PTS 					   
					   union all 
					   select distinct [number] 
					   from #P2P					   
					   union all 
					   select distinct [number] 
					   from #BusinessLoans)

--  with 
--	t_end as
--(

drop table if exists #max_r_main

select mr.*, isnull(mr14.ПроцентнаяСтавка, mr.ПроцентнаяСтавка) as ПоследняяПроцСтавкаДо14Дней 
into  #max_r_main
from #max_r mr left join #max_r_14_day mr14 on mr14.Договор = mr.Договор
--where mr14.ПроцентнаяСтавка is null

drop table if exists #t_end0
select distinct --d.[Номер] as [ДоговорНомер]
	    pts.[number] as [ДоговорНомер]
	   , pts.[ДатаВыдачи]
	   , 1 as [КолвоЗаймов]	  
	   , pts.[СуммаЗайма] [СуммаВыдачи]
     , case when cast(max_r.[ПроцентнаяСтавка] as int)=0 then max_r.[НачисляемыеПроценты]
			      else max_r.[ПроцентнаяСтавка]	
	     end as [ПроцСтавкаКредит]
     , case when cast(max_r.[ПроцентнаяСтавка] as int)=0 then cast((d.[Сумма]*max_r.[НачисляемыеПроценты]) as decimal(15,2)) 
			      else cast((d.[Сумма]*max_r.[ПроцентнаяСтавка]) as decimal(15,2))  
	     end as [СтавкаНаСумму]
	   , pts.[СуммаКП] as [СуммаДопУслуг]	--d.[СуммаДополнительныхУслуг] as [СуммаДопУслуг]
     ,pts.СуммаКП_without_partner_bounty as [СуммаДопУслугЗаВычетомПартнерскойКомиссии]
     ,cast(pts.СуммаКП_without_partner_bounty/VAT as money) СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net
     , [ПризнакКП]					= case when pts.[СуммаКП]>0 then 1 else 0 end 

     , [ПризнакСтраховка]			= case when pts.[Страхование жизни]>0 or pts.[КАСКО]>0 then 1 else 0 end 
     
     , [ПризнакКаско]				= case when pts.[КАСКО] >0  then 1 else 0 end 

     , [ПризнакСтрахованиеЖизни]	= case when pts.[Страхование жизни]>0   then 1 else 0 end 
     
     , [ПризнакРАТ]					= case when pts.[РАТ]>0 then 1 else 0 end 

	 --, [ПризнакПозитивНастр]       =case when isnull(SumPositiveMood,0) <>0 then 1 else 0 end 
	 --, [ПризнакWLStand]       =case when isnull(SumWLStand,0) <>0 then 1 else 0 end 

	 , [ТочкаВходаЗаявки]			= tv.[ТочкаВходаЗаявкиНаим]
	 , [МестоСоздЗаявки]			= tv.[МестоСозданияЗаявкиНаим]
	 , [СпособВыдачиЗайма]			= tv.[СпособВыдачиЗаймаНаим]
	 , [ТочкаВхКл]					= tvk.[Имя]
	 , [ТочкаВхПовторКл]			= tv2k.[Имя]
	   , case  when tvk.[Имя]=N'ПовторныйЗайм' then 
									case  when not tv2k.[Имя] is null then 
														 case  when tv2k.[Имя]=N'Другое' then  N'Прочее'
																	 when tv2k.[Имя]=N'ЛКПартнера' then  N'Партнер'
																	 else tv2k.[Имя] 
														 end
										  else rek.[Наименование] 
									end
			   when tvk.[Имя] is null then rek.[Наименование] 
			   else  case  when tvk.[Имя]=N'Другое' then  N'Прочее'
					       when tvk.[Имя]=N'ЛКПартнера' then  N'Партнер'
					       else tvk.[Имя] 
				      end 
	       end as [КаналМФО_ТочкаВх]
	     , o.[Код]  as [ДоговорТочкаКод]
	     , o.[Наименование] as [ДоговорТочкаНаим]
	     , cl.[Наименование] as [АгентПартнер]
	     , case  when o.[Код]=N'8999' then 
									  case when not cl8999.[РО_Регион] is null then cl8999.[РО_Регион] else N'Микрофинансирование' end
			         when not tch.[РО_Регион] is null then tch.[РО_Регион] 
               else N'Микрофинансирование' 
	       end as [РО_Регион]
	     , case when cl.[ПризнакПЭП]=0x01 then N'Да' end as [ПризнакПЭП]
       , SumEnsur	= pts.[Страхование жизни] 
       , SumRat		= pts.[РАТ]  
       , SumKasko	= pts.[КАСКО]
       , EnsurКод
	   , RatКод  
       , KaskoКод

	     , case when o.[Код]=N'8999' then N'ПЭП'
			        else case when not tch.[РО_Регион] is null then tch.[РО_Регион] 
					         else N'Микрофинансирование'
				           end
		     end as [РО_Регион_фин]
		   , pg.[ID_ПлатежнойСистемы] as [ДопПродукт_IDПлатСистемы]
		   , pg.[ID_Операции] as [ДопПродукт_ID_Операции]
		   , case when cast(ad.[Период] as date)>='2019-09-03' 
              then case when d.[СуммаДополнительныхУслуг]<>0 then N'SUCCEEDED' else N'' end 
			        else  case when d.[СуммаДополнительныхУслуг]<>0 then case when pg.[Статус]<>N'' then pg.[Статус]  else N'Отсутствует'  end
					               else N'' 
                    end
			   end as [ДопПродукт_СтатусСписанияСтраховки]
			--when d.[СуммаДополнительныхУслуг]<>0 then case when  pg.[Статус]<>N'' then pg.[Статус] else  N'SUCCEEDED' end
			--when d.[СуммаДополнительныхУслуг]<>0 or d.[СуммаДополнительныхУслуг]=0 then N''	
			--when pg.[Статус]=N'' then N'Отсутствует' 
			--else pg.[Статус] 
		--end as [ДопПродукт_СтатусСписанияСтраховки]
		    , pg.[Комментарий] as [КомментКСтатусуСписСтраховки]

			-- для исправления ошибок ручных правок 2021-03-12 
		    , iif(cast(pts.[ДатаВыдачи] as date) <> cast(ad.[Период] as date) ,   cast(pts.[ДатаВыдачи] as smalldatetime),   cast(ad.[Период] as smalldatetime)) as [ДатаВыдачиПолн]

		,case when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 and cast(ad.[Период] as date) >= '2019-08-11' then N'Да' 
			  else N'' 
		end as [ПЭП2_3пакет] --and pep.[ПЭП_0]=1 then N'Да' else N'' end as [ПЭП2_3пакет]

		,null as [АктПТСзабрали]
		--,case when o.[Код]=N'8999' then N'Да' else N'' end as [ПЭП1_ДогМП_8999]
		--,case when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 then N'Да' else N'' end as [ПЭП2_ПризнакЭДО]
		--,case when o.[Наименование] like '%Партнер №%' then N'Да' else N'' end as [Партнер]
		--,case when pep.[ВМ]=1 then N'Да' else N'' end as [ВМ]  -- o.[Наименование] like '%ВМ №%' then N'Да' else N'' end as [ВМ]
		,case
			when o.[Код]=N'8999' then N'ПЭП1'
			when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 then N'ПЭП2'	--pep.[ПЭП2]=1 then N'ПЭП2'
			when o.[Наименование] like '%Партнер №%' then N'Партнер'
			when pep.[ВМ]=1 then N'ВМ'
		end as [СпособОформленияЗайма]

		, [ПризнакПозитивНастр]			 = case when isnull(pts.[От потери работы. «Максимум»],0) <>0 or isnull(pts.[От потери работы. «Стандарт»],0) <>0 then 1 else 0 end 
		, SumPositiveMood				 = isnull(pts.[От потери работы. «Максимум»],0) + isnull(pts.[От потери работы. «Стандарт»],0)
		, PositiveMoodКод

		, ch.[Канал от источника]
		, ch.[Группа каналов]

		, SumHelpBusiness				= pts.[Помощь бизнесу]
		, HelpBusinessКод
		, [ПризнакПомощьБизнесу]		= case when pts.[Помощь бизнесу]>0 then 1 else 0 end 

		,[ЗаявкаНомер_CRM]				= rr.[CRMRequestNumber]

		, SumTeleMedic					= [телемедицина]
		, [TeleMedicKod]
		, [ПризнакТелемедицина]			= case when pts.[телемедицина] >0  then 1 else 0 end

		, SumCushion					= [Защита от потери работы]
		, [CushionKod]
		, [Признак Защита от потери работы]		= case when pts.[Защита от потери работы] >0  then 1 else 0 end
		, (case when cast(max_r.[ПоследняяПроцСтавкаДо14Дней] as int)=0 then max_r.[НачисляемыеПроценты]
			      else max_r.[ПоследняяПроцСтавкаДо14Дней]	
	     end
		 ) as [ПоследняяПроцСтавкаДо14Дней]
     --, case when cast(max_r_14_day.[ПроцентнаяСтавка] as int)=0 then cast((d.[Сумма]*max_r_14_day.[НачисляемыеПроценты]) as decimal(15,2)) 
			  --    else cast((d.[Сумма]*max_r_14_day.[ПроцентнаяСтавка]) as decimal(15,2))  
	    -- end as [СтавкаНаСуммуПоследняяПроцСтавкаДо14Дней]
     , farmStrKod
     , sumFarmStr
     , [ПризнакФармСтрахование]			= case when pts.[Фарм страхование] >0  then 1 else 0 end
into #t_end0 

--select * 
from #PTS pts
	left join #mfo_doc_dog/*[Stg].[_1cMFO].[Документ_ГП_Договор]*/ d with (nolock) on pts.[number]=d.[Номер]
 --   FROM [Stg].[_1cMFO].[Документ_ГП_Договор] d with (nolock)
	--left join #PTS pts on pts.[number]=d.[Номер]
    left join #ssdp ssdp on ssdp.[НомерДоговора]=pts.[number]					-- select * from #ssdp  select * from #PTS
	
	left join #active_loans_cmr
					  /*(SELECT min([Период]) as [Период],[Договор]
				         FROM [Stg].[_1cCMR].[РегистрНакопления_АктивныеДоговоры] with (nolock)
						 where [Активен]=1 and [ВидДвижения]=0 -- Вид движения = Расход (выдача ДС)
								--  and   [Период] >= dateadd(year,2000,dateadd(day,datediff(day,0,dateadd(day,-25,Getdate())),0)) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
								and [Период] >=dateadd(year,2000, dateadd(month,datediff(month,0,dateadd(month,-3,Getdate())),0) /*dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)*/)
				         group by [Договор] 
				       )*/ 
					   ad  on d.[Ссылка]=ad.[Договор] 
	
	left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				         from #MainTable mt0
					       left join #MainTable mt1 on mt0.[ПроРодитель]=mt1.[Подчиненный]
				        where mt0.[ПодчНаим] like N'Партнер%' or mt0.[ПодчНаим] like N'ВМ%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр'
				      ) tch -- Точка-РП-РО
		  on d.[Точка]=tch.[ТочкаСсылка]
	left join #mfo_entering_point tv on pts.[number]=tv.[Номер]

    left join [Stg].[_1cMFO].[Перечисление_ТочкиВходаКлиентов] tvk with (nolock) on d.[ТочкаВходаКлиента]=tvk.[Ссылка]

    left join [Stg].[_1cMFO].[Перечисление_ТочкиВходаКлиентов] tv2k with (nolock) on d.[ТочкаВходаПовторногоКлиента]=tv2k.[Ссылка]

    left join [Stg].[_1cMFO].[Справочник_НастройкиПринадлежностиКРекламнымКомпаниям] rek with (nolock) on tv.[ТочкаВхода]=rek.[Ссылка]

    left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o with (nolock) on d.[Точка]=o.[Ссылка]

    left join [Stg].[_1cMFO].[Справочник_Контрагенты] cl with (nolock) on o.[Партнер]=cl.[Ссылка]

    left join #ClientLoanPoint8999 cl8999 on d.[Контрагент]=cl8999.[Контрагент]
	
	left join #max_r_main max_r on isnull(max_r.договор,0x00000000000000000000000000000000 ) = pts.[CMRДоговор]
    --left join #max_r max_r on isnull(max_r.договор,0x00000000000000000000000000000000 )=d.[Ссылка]
	--left join #max_r max_r_14_day on isnull(max_r.договор,0x00000000000000000000000000000000 ) = pts.[CMRДоговор]
   

	left join (select * from #pg00 where [rank_pg0]=1) pg on pts.[number]=pg.[ДоговорНомер]

	left join #dcmnt_pep_request pep on pts.[number]=pep.[ЗаявкаНомер]
	--left join [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] pep with (nolock) on pts.[number]=pep.[ЗаявкаНомер]

	--left join #lcrm_tbl_full_w_chanals2_end ch with (nolock) on d.[Номер]=ch.[UF_ROW_ID]
	--left join #lcrm_tbl_short_w_channel ch with (nolock) on pts.[number]=ch.[UF_ROW_ID]
	left join #lcrm_tbl_full_w_chanals2_end ch with (nolock) on pts.[number]=ch.[UF_ROW_ID]

	left join #crm_request_mfo_loan rr on pts.[number]=rr.[MFOContractNumber]

	join #cmr_loans_state_noncancelled lsc on pts.[CMRДоговор] = lsc.[Договор]
	outer apply (select 1+dbo.GetVATOnDate(pts.[ДатаВыдачи])/100 as VAT) vat
 /*  where  --ad.[Период] >= dateadd(year,2000,dateadd(day,datediff(day,0,dateadd(day,-25,cast(Getdate() as date))),0)) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
            --dateadd(year,-2000,ad.[Период]) >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
		 --and  d.ссылка 
		 --and 
      pts.[CMRДоговор] in ( select [Договор]  from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock)  where [Статус]=0x80E400155D64100111E7C5361FF4393D  -- статус аннулирован
								         )*/
--)

--select * from #PTS pts where  ДатаВыдачи='20200319'
--select * from #t_end0 where  ДатаВыдачи='20200319'

drop table if exists #t_end
 select distinct  * into #t_end from #t_end0


drop table if exists #tmp_new
 
select distinct * 
into #tmp_new
from #t_end t_end
where [ДатаВыдачи] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) and  [ДоговорТочкаКод] not in (N'9949' ,N'9948' ,N'9984' ,N'9945')
--order by [ДатаВыдачи]  desc
--select * from #tmp_new
--alter table [dbo].[report_Agreement_InterestRate] add SumTeleMedic decimal(38,2) null, [TeleMedicKod] nvarchar(255) null ,[ПризнакТелемедицина] int null
--alter table [dbo].[report_Agreement_InterestRate] add SumCushion decimal(38,2) null, [CushionKod] nvarchar(255) null ,[Признак Защита от потери работы] int null
--alter table [dbo].[report_Agreement_InterestRate] add SumFarmStr decimal(38,2) null,  farmStrKod nvarchar(255) null , [ПризнакФармСтрахование] int null
--alter table dbo.report_Agreement_InterestRate_stg add SumFarmStr decimal(38,2) null,  farmStrKod nvarchar(255) null , [ПризнакФармСтрахование] int null



union all
select 
		[ДоговорНомер] 							= [number]
       ,[ДатаВыдачи]							= [ДатаВыдачи]
       ,[КолвоЗаймов]							= 1
       ,[СуммаВыдачи]							= [СуммаЗайма]
       ,[ПроцСтавкаКредит]						= [ПроцентнаяСтавка]
       ,[СтавкаНаСумму]							= [СтавкаНаСумму]
       ,[СуммаДопУслуг]							= 0.00
	   , [СуммаДопУслугЗаВычетомПартнерскойКомиссии] = 0.0		
	   ,СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net = 0.0
       ,[ПризнакКП] 							= 0
       ,[ПризнакСтраховка]						= 0
       ,[ПризнакКаско]							= 0
       ,[ПризнакСтрахованиеЖизни] 				= 0
       ,[ПризнакРАТ] 							= 0
												
	   ,[ТочкаВходаЗаявки]						= 'p2p'
	   ,[МестоСоздЗаявки]						= 'p2p'
	   ,[СпособВыдачиЗайма]						= 'p2p'
       ,[ТочкаВхКл]								= 'p2p'
	   ,[ТочкаВхПовторКл]						= ''
	   ,[КаналМФО_ТочкаВх]						= ''
	   ,[ДоговорТочкаКод]						= 'p2p'
	   ,[ДоговорТочкаНаим]						= 'p2p'
	   ,[АгентПартнер]							= ''
	   ,[РО_Регион]								= 'p2p'
	   ,[ПризнакПЭП]							= null
	   											
	   ,SumEnsur								= 0.00
	   ,SumRat									= 0.00
	   ,SumKasko								= 0.00
	   ,EnsurКод								= null
	   ,RatКод									= null
	   ,KaskoКод								= null
	   ,[РО_Регион_фин]							= 'p2p'
	   											
	   ,[ДопПродукт_IDПлатСистемы]				= null
	   ,[ДопПродукт_ID_Операции]				= null
	   ,[ДопПродукт_СтатусСписанияСтраховки]	= ''
	   ,[КомментКСтатусуСписСтраховки]			= ''
	   ,[ДатаВыдачиПолн]						= ДатаВремя
	   											
	   ,[ПЭП2_3пакет]							= ''
	   ,[АктПТСзабрали]							= null
												
		--,[ПЭП1_ДогМП_8999]					
		--,[ПЭП2_ПризнакЭДО]					
		--,[Партнер]							
		--,[ВМ]									
												
		,[СпособОформленияЗайма]				= 'p2p'
		, [ПризнакПозитивНастр]					= 0
		, SumPositiveMood						= 0.00
		, PositiveMoodКод						= ''
		, [Канал от источника]					= ch.[Канал от источника]
		, [Группа каналов]						= ch.[Группа каналов]
												
		, SumHelpBusiness						= null
		, HelpBusinessКод						= null
		, [ПризнакПомощьБизнесу] 				= 0
		, [ЗаявкаНомер_CRM]						= [number]

		, SumTeleMedic							= null
		, TeleMedicKod							= null
		, [ПризнакТелемедицина] 				= 0

		, SumCushion							      = null
		, [CushionKod]							    = null
		, [ПризнакПодушкаБезопасн]			= 0
		, [ПоследняяПроцСтавкаДо14Дней] = [ПроцентнаяСтавка]

		 , farmStrKod                   = null
     , sumFarmStr                   = null
     , [ПризнакФармСтрахование]			= null
--select *
from #P2P p
left join #lcrm_tbl_full_w_chanals2_end ch with (nolock) on p.[number]=ch.[UF_ROW_ID]
where [ДатаВыдачи] >= cast(dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) as date)

union all
select 
		[ДоговорНомер] 							= [number]
       ,[ДатаВыдачи]							= [ДатаВыдачи]
       ,[КолвоЗаймов]							= 1
       ,[СуммаВыдачи]							= [СуммаЗайма]
       ,[ПроцСтавкаКредит]						= [ПроцентнаяСтавка]
       ,[СтавкаНаСумму]							= [СтавкаНаСумму]
       ,[СуммаДопУслуг]							= 0.00
	   , [СуммаДопУслугЗаВычетомПартнерскойКомиссии] = 0.0				
	   ,СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net = 0.0
       ,[ПризнакКП] 							= 0
       ,[ПризнакСтраховка]						= 0
       ,[ПризнакКаско]							= 0
       ,[ПризнакСтрахованиеЖизни] 				= 0
       ,[ПризнакРАТ] 							= 0
												
	   ,[ТочкаВходаЗаявки]						= 'business'
	   ,[МестоСоздЗаявки]						= 'business'
	   ,[СпособВыдачиЗайма]						= 'business'
       ,[ТочкаВхКл]								= 'business'
	   ,[ТочкаВхПовторКл]						= ''
	   ,[КаналМФО_ТочкаВх]						= ''
	   ,[ДоговорТочкаКод]						= 'business'
	   ,[ДоговорТочкаНаим]						= 'business'
	   ,[АгентПартнер]							= ''
	   ,[РО_Регион]								= 'business'
	   ,[ПризнакПЭП]							= null
	   											
	   ,SumEnsur								= 0.00
	   ,SumRat									= 0.00
	   ,SumKasko								= 0.00
	   ,EnsurКод								= null
	   ,RatКод									= null
	   ,KaskoКод								= null
	   ,[РО_Регион_фин]							= 'business'
	   											
	   ,[ДопПродукт_IDПлатСистемы]				= null
	   ,[ДопПродукт_ID_Операции]				= null
	   ,[ДопПродукт_СтатусСписанияСтраховки]	= ''
	   ,[КомментКСтатусуСписСтраховки]			= ''
	   -- для исправления ошибок ручных правок 2021-03-12 
	   , iif(cast([ДатаВыдачи] as date) <> cast(updated as date) ,   cast([ДатаВыдачи] as smalldatetime),   cast(updated as smalldatetime)) as [ДатаВыдачиПолн]
	   --,[ДатаВыдачиПолн]						= updated
	   											
	   ,[ПЭП2_3пакет]							= ''
	   ,[АктПТСзабрали]							= null
												
		--,[ПЭП1_ДогМП_8999]					
		--,[ПЭП2_ПризнакЭДО]					
		--,[Партнер]							
		--,[ВМ]									
												
		,[СпособОформленияЗайма]				= 'business'
		, [ПризнакПозитивНастр]					= 0
		, SumPositiveMood						= 0.00
		, PositiveMoodКод						= ''
		, [Канал от источника]					= ch.[Канал от источника]
		, [Группа каналов]						= ch.[Группа каналов]
												
		, SumHelpBusiness						= null
		, HelpBusinessКод						= null
		, [ПризнакПомощьБизнесу] 				= 0
		,[ЗаявкаНомер_CRM]						= [number]

		, SumTeleMedic							= null
		, TeleMedicKod							= null
		, [ПризнакТелемедицина] 				= 0

		, SumCushion							= null
		, [CushionKod]							= null
		, [ПризнакПодушкаБезопасн]			= 0
		, [ПоследняяПроцСтавкаДо14Дней] = [ПроцентнаяСтавка]
		, farmStrKod                    = null
    , sumFarmStr                    = null
    , [ПризнакФармСтрахование]			= null
--select *
from #BusinessLoans b
left join #lcrm_tbl_full_w_chanals2_end ch with (nolock) on b.[number]=ch.[UF_ROW_ID]
where [ДатаВыдачи] >= cast(dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) as date)


create clustered index ix on #tmp_new([ДоговорНомер])
delete t from #tmp_AgrIntRate_prev t where exists(select top(1) 1 from #tmp_new s where s.[ДоговорНомер]  = t.ДоговорНомер)


/*
таблица report_Agreement_InterestRate_stg была создана ранее как
select top(0)* 
into dbo.report_Agreement_InterestRate_stg
from dbo.report_Agreement_InterestRate
*/
--clear table dbo.report_Agreement_InterestRate_stg



--- DWH-1052 - добавим поле [ПоследняяПроцСтавкаДо14Дней] 
begin tran
	--По идеи данных тут не должно быть..
	truncate table dbo.report_Agreement_InterestRate_stg 

	--перемещаем данные в report_Agreement_InterestRate_stg
	insert into report_Agreement_InterestRate_stg with(tablockx)
	select * from report_Agreement_InterestRate with(nolock)
	where [ДатаВыдачи] < dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0);
	/*
	delete from [dbo].[report_Agreement_InterestRate] 
	where [ДатаВыдачи] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0);
	*/
	insert into dbo.report_Agreement_InterestRate_stg with(tablockx)
	(
		[ДоговорНомер]
      ,[ДатаВыдачи]
      ,[КолвоЗаймов]
      ,[СуммаВыдачи]
      ,[ПроцСтавкаКредит]
      ,[СтавкаНаСумму]
      ,[СуммаДопУслуг]
      ,[ПризнакКП]
      ,[ПризнакСтраховка]
      ,[ПризнакКаско]
      ,[ПризнакСтрахованиеЖизни]
      ,[ПризнакРАТ]
      ,[ТочкаВходаЗаявки]
      ,[МестоСоздЗаявки]
      ,[СпособВыдачиЗайма]
      ,[ТочкаВхКл]
      ,[ТочкаВхПовторКл]
      ,[КаналМФО_ТочкаВх]
      ,[ДоговорТочкаКод]
      ,[ДоговорТочкаНаим]
      ,[АгентПартнер]
      ,[РО_Регион]
      ,[ПризнакПЭП]
      ,[SumEnsur]
      ,[SumRat]
      ,[SumKasko]
      ,[EnsurКод]
      ,[RatКод]
      ,[KaskoКод]
      ,[РО_Регион_фин]
      ,[ДопПродукт_IDПлатСистемы]
      ,[ДопПродукт_ID_Операции]
      ,[ДопПродукт_СтатусСписанияСтраховки]
      ,[КомментКСтатусуСписСтраховки]
      ,[ДатаВыдачиПолн]
      ,[ПЭП2_3пакет]
      ,[АктПТСзабрали]
      ,[СпособОформленияЗайма]
      ,[ПризнакПозитивНастр]
      ,[SumPositiveMood]
      ,[PositiveMoodКод]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[SumHelpBusiness]
      ,[HelpBusinessКод]
      ,[ПризнакПомощьБизнесу]
      ,[ЗаявкаНомер_CRM]
      ,[SumTeleMedic]
      ,[TeleMedicKod]
      ,[ПризнакТелемедицина]
      ,[SumCushion]
      ,[CushionKod]
      ,[Признак Защита от потери работы]
      ,[ПоследняяПроцСтавкаДо14Дней]
      ,[СуммаДопУслугЗаВычетомПартнерскойКомиссии]
	  ,СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net
     , farmStrKod                   
     , sumFarmStr                  
     , [ПризнакФармСтрахование]			
	)
	select distinct 
	[ДоговорНомер]
      ,[ДатаВыдачи]
      ,[КолвоЗаймов]
      ,[СуммаВыдачи]
      ,[ПроцСтавкаКредит]
      ,[СтавкаНаСумму]
      ,[СуммаДопУслуг]
      ,[ПризнакКП]
      ,[ПризнакСтраховка]
      ,[ПризнакКаско]
      ,[ПризнакСтрахованиеЖизни]
      ,[ПризнакРАТ]
      ,[ТочкаВходаЗаявки]
      ,[МестоСоздЗаявки]
      ,[СпособВыдачиЗайма]
      ,[ТочкаВхКл]
      ,[ТочкаВхПовторКл]
      ,[КаналМФО_ТочкаВх]
      ,[ДоговорТочкаКод]
      ,[ДоговорТочкаНаим]
      ,[АгентПартнер]
      ,[РО_Регион]
      ,[ПризнакПЭП]
      ,[SumEnsur]
      ,[SumRat]
      ,[SumKasko]
      ,[EnsurКод]
      ,[RatКод]
      ,[KaskoКод]
      ,[РО_Регион_фин]
      ,[ДопПродукт_IDПлатСистемы]
      ,[ДопПродукт_ID_Операции]
      ,[ДопПродукт_СтатусСписанияСтраховки]
      ,[КомментКСтатусуСписСтраховки]
      ,[ДатаВыдачиПолн]
      ,[ПЭП2_3пакет]
      ,[АктПТСзабрали]
      ,[СпособОформленияЗайма]
      ,[ПризнакПозитивНастр]
      ,[SumPositiveMood]
      ,[PositiveMoodКод]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[SumHelpBusiness]
      ,[HelpBusinessКод]
      ,[ПризнакПомощьБизнесу]
      ,[ЗаявкаНомер_CRM]
      ,[SumTeleMedic]
      ,[TeleMedicKod]
      ,[ПризнакТелемедицина]
      ,[SumCushion]
      ,[CushionKod]
      ,[Признак Защита от потери работы]
      ,[ПоследняяПроцСтавкаДо14Дней]
      ,[СуммаДопУслугЗаВычетомПартнерскойКомиссии]
	  ,СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net
	  , farmStrKod                   
     , sumFarmStr                  
     , [ПризнакФармСтрахование]		
	from #tmp_AgrIntRate_prev

	union all

	select distinct [ДоговорНомер]
      ,[ДатаВыдачи]
      ,[КолвоЗаймов]
      ,[СуммаВыдачи]
      ,[ПроцСтавкаКредит]
      ,[СтавкаНаСумму]
      ,[СуммаДопУслуг]
      ,[ПризнакКП]
      ,[ПризнакСтраховка]
      ,[ПризнакКаско]
      ,[ПризнакСтрахованиеЖизни]
      ,[ПризнакРАТ]
      ,[ТочкаВходаЗаявки]
      ,[МестоСоздЗаявки]
      ,[СпособВыдачиЗайма]
      ,[ТочкаВхКл]
      ,[ТочкаВхПовторКл]
      ,[КаналМФО_ТочкаВх]
      ,[ДоговорТочкаКод]
      ,[ДоговорТочкаНаим]
      ,[АгентПартнер]
      ,[РО_Регион]
      ,[ПризнакПЭП]
      ,[SumEnsur]
      ,[SumRat]
      ,[SumKasko]
      ,[EnsurКод]
      ,[RatКод]
      ,[KaskoКод]
      ,[РО_Регион_фин]
      ,[ДопПродукт_IDПлатСистемы]
      ,[ДопПродукт_ID_Операции]
      ,[ДопПродукт_СтатусСписанияСтраховки]
      ,[КомментКСтатусуСписСтраховки]
      ,[ДатаВыдачиПолн]
      ,[ПЭП2_3пакет]
      ,[АктПТСзабрали]
      ,[СпособОформленияЗайма]
      ,[ПризнакПозитивНастр]
      ,[SumPositiveMood]
      ,[PositiveMoodКод]
      ,[Канал от источника]
      ,[Группа каналов]
      ,[SumHelpBusiness]
      ,[HelpBusinessКод]
      ,[ПризнакПомощьБизнесу]
      ,[ЗаявкаНомер_CRM]
      ,[SumTeleMedic]
      ,[TeleMedicKod]
      ,[ПризнакТелемедицина]
      ,[SumCushion]
      ,[CushionKod]
      ,[Признак Защита от потери работы]
      ,[ПоследняяПроцСтавкаДо14Дней]
      ,[СуммаДопУслугЗаВычетомПартнерскойКомиссии]
	    ,СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net
        , farmStrKod                   
     , sumFarmStr                  
     , [ПризнакФармСтрахование]		
	  from #tmp_new

	commit tran
	if object_id('dbo.report_Agreement_InterestRate_to_del') is null
	begin
		select top(0) *
		into dbo.report_Agreement_InterestRate_to_del
		from  dbo.report_Agreement_InterestRate_stg
	end
	truncate table  dbo.report_Agreement_InterestRate_to_del
	--после перемещаем данные из report_Agreement_InterestRate_stg в [report_Agreement_InterestRate]
	if exists(select top(1) 1 from report_Agreement_InterestRate_stg)
	begin
	 begin tran
	  alter table dbo.report_Agreement_InterestRate switch  to dbo.report_Agreement_InterestRate_to_del
		with (WAIT_AT_LOW_PRIORITY  ( MAX_DURATION = 1 minutes, ABORT_AFTER_WAIT = SELF ))

	  alter table dbo.report_Agreement_InterestRate_stg switch  to dbo.report_Agreement_InterestRate
		with (WAIT_AT_LOW_PRIORITY  ( MAX_DURATION = 1 minutes, ABORT_AFTER_WAIT = SELF  ))
	  commit tran
	 end 
 


END
--go
