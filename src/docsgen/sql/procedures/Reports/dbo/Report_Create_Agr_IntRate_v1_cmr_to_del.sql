
--exec Report_Create_Agr_IntRate_v1_1
--drop table #t1
--select * into #T1 from [dbo].[report_Agreement_InterestRate] 
--exec Report_Create_Agr_IntRate_v1
--drop table #t2
--select * into #T2 from [dbo].[report_Agreement_InterestRate] 
/*
select * from #t1 t1 full join #t2 t2 on t1.договорНомер=  t2.договорНомер
where t1.договорНомер is null or t2.договорНомер is null

  */
CREATE PROC dbo.Report_Create_Agr_IntRate_v1_cmr_to_del
 AS
BEGIN

	SET NOCOUNT ON;

  declare @GetDate2000 datetime

  set @GetDate2000=dateadd(year,2000,getdate());


drop table if exists #P2P
select cast(r.[updated_at] as date) ДатаВыдачи
, r.[updated_at] ДатаВремя
, r.[number]
, N'P2P займ' as [КредитныйПродукт]
, r.[sum_contract] as [СуммаЗайма]
, r.[interest_rate] as [ПроцентнаяСтавка]
, r.[loan_period] as [СрокЗайма]
, (r.[sum_contract] * r.[interest_rate]) [СтавкаНаСумму]
, created=getdate()
, ishistory=0
, updated=getdate()
into #P2P
from [Stg].[_p2p].[requests] r
left join [Stg].[_p2p].[request_statuses] s on r.[request_status_guid]=s.[guid]
where r.[request_status_guid] = '81079828-9834-4614-9825-84b646938758' -- статус заем выдан
and r.[updated_at]>=cast(getdate() as date)

--select * from #P2P


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
         SumEnsur    =sum(case when ДопПродукт=0xB81300155D03491F11E958A5C7DB6817 then spdd.сумма else 0 end),
         SumRat      =sum(case when ДопПродукт=0xB81600155D4D0B5211E9968E54A9F742 then spdd.сумма else 0 end),
         SumKasko    =sum(case when ДопПродукт=0xB81600155D4D0B5211E9968E6C835BF9 then spdd.сумма else 0 end),
		     SumPositiveMood =sum(case when ДопПродукт=0xB81700155D4D0B5211E9F19852274C9E or ДопПродукт=0xB81700155D4D0B5211E9F198668D9373 then spdd.сумма else 0 end),
		   --SumWLStand    =sum(case when ДопПродукт=0xB81700155D4D0B5211E9F198668D9373 then spdd.сумма else 0 end)
		     SumHelpBusiness	=sum(case when ДопПродукт=0xB80D00155D6A0B0011EA045E61D90E5C then spdd.сумма else 0 end)
    into #d1
    FROM [Stg].[_1cCMR].[Справочник_Договоры_ДополнительныеПродукты] (nolock) spdd
    left join [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s  with (nolock) on s.ссылка=spdd.[ДоговорДопПродукта]
    left join [Stg].[_1cCMR].[Справочник_Договоры] sd  with (nolock) on sd.ссылка=s.[Договор]
   group by  s.[Договор]


drop table if exists #ssdp
  select  sd.ссылка
       , SumEnsur    
       , SumRat      
       , SumKasko 
	     , SumPositiveMood
		 , SumHelpBusiness 
       , EnsurКод = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81300155D03491F11E958A5C7DB6817)
       , RatКод   = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock)  where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81600155D4D0B5211E9968E54A9F742)
       , KaskoКод = (select top 1 s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81600155D4D0B5211E9968E6C835BF9)
	     , PositiveMoodКод = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) 
										  where s1.[Договор]=sd.ссылка and  (ДопПродукт=0xB81700155D4D0B5211E9F19852274C9E or ДопПродукт=0xB81700155D4D0B5211E9F198668D9373))
	   --, SumWLStand = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  
		 , HelpBusinessКод = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB80D00155D6A0B0011EA045E61D90E5C)

    into #ssdp
    from #d1  d1
    left join [Stg].[_1cCMR].[Справочник_Договоры] sd with (nolock) on sd.ссылка=d1.[Договор]


drop table if exists #pg00
  select [_Period] 
       , [_Fld27] as [ДоговорНомер]
	     , case 
			        when [_Fld29_RTRef]=0x0000000A then N'Wallet One'
			        when [_Fld29_RTRef]=0x00000043 then N'Contact'
			        when [_Fld29_RTRef]=0x00000090 then N'Cloud payments'
	       end as [ID_ПлатежнойСистемы]
       , [_Fld62] as [ID_Операции]
       , [_Fld38] as [Статус]
	     , [_Fld39] as [Комментарий]
	     , rank() over (partition by [_Fld27] order by [_Period] desc) as [rank_pg0]
    into #pg00
    from [Stg].[_1cPG].[PGPayments] (nolock) pg0
   where [_Fld92]>0 and exists (select [Код] 
			                            from [Stg].[_1cCMR].[Справочник_Договоры] sd 
			                           where pg0.[_Fld27]=sd.[Код] and dateadd(year,-2000,sd.[Дата])>=dateadd(day,datediff(day,0,dateadd(day,-60,Getdate())),0)) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-4,Getdate())),0))




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
    join r on r.Договор=pd. Договор and r.max_p=pd.Период


drop table if exists #t_end
;
  with 
	t_end as
(
select distinct d.[Номер] as [ДоговорНомер]
	   , cast(dateadd(year,-2000,ad.[Период]) as date) as [ДатаВыдачи]
	   , 1 as [КолвоЗаймов]	  
	   , d.[Сумма] as [СуммаВыдачи]
     , case when cast(max_r.[ПроцентнаяСтавка] as int)=0 then max_r.[НачисляемыеПроценты]
			      else max_r.[ПроцентнаяСтавка]	
	     end as [ПроцСтавкаКредит]
     , case when cast(max_r.[ПроцентнаяСтавка] as int)=0 then cast((d.[Сумма]*max_r.[НачисляемыеПроценты]) as decimal(15,2)) 
			      else cast((d.[Сумма]*max_r.[ПроцентнаяСтавка]) as decimal(15,2))  
	     end as [СтавкаНаСумму]
	   , d.[СуммаДополнительныхУслуг] as [СуммаДопУслуг]
     
     
     , [ПризнакКП] =case when isnull(SumEnsur,0)<>0 or isnull(SumKasko,0)<>0 or isnull(SumRat,0) <>0  
								or isnull(SumPositiveMood,0)<>0 or isnull(SumHelpBusiness,0)<>0 then 1 else 0 end 
     , [ПризнакСтраховка] =case when isnull(SumEnsur,0)<>0   or isnull(SumKasko,0)<>0 then 1 else 0 end 
     
     , [ПризнакКаско] =case when  isnull(SumKasko,0)<>0  then 1 else 0 end 
     , [ПризнакСтрахованиеЖизни]  =case when isnull(SumEnsur,0)<>0   then 1 else 0 end 
     
     , [ПризнакРАТ]       =case when isnull(SumRat,0) <>0 then 1 else 0 end 

	 --, [ПризнакПозитивНастр]       =case when isnull(SumPositiveMood,0) <>0 then 1 else 0 end 
	 --, [ПризнакWLStand]       =case when isnull(SumWLStand,0) <>0 then 1 else 0 end 

	   , tv.[ТочкаВходаЗаявкиНаим] as [ТочкаВходаЗаявки]
	   , tv.[МестоСозданияЗаявкиНаим] as [МестоСоздЗаявки]
	   , tv.[СпособВыдачиЗаймаНаим] as [СпособВыдачиЗайма]
	   , tvk.[Имя] as [ТочкаВхКл]
	   , tv2k.[Имя] as [ТочкаВхПовторКл]
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
       , SumEnsur 
       , SumRat   
       , SumKasko 
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
		   , case when cast(dateadd(year,-2000,ad.[Период]) as date)>='2019-09-03' 
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
		    , cast(dateadd(year,-2000,ad.[Период]) as smalldatetime) as [ДатаВыдачиПолн]

		,case when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 and cast(dateadd(year,-2000,ad.[Период]) as date) >= '2019-08-11' then N'Да' 
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

		, [ПризнакПозитивНастр]       =case when isnull(SumPositiveMood,0) <>0 then 1 else 0 end 
		, SumPositiveMood
		, PositiveMoodКод

		, ch.[Канал от источника]
		, ch.[Группа каналов]

		, SumHelpBusiness
		, HelpBusinessКод
		, [ПризнакПомощьБизнесу]       =case when isnull(SumHelpBusiness,0)<>0 then 1 else 0 end 

    FROM [Stg].[_1cMFO].[Документ_ГП_Договор] d with (nolock)
    left join #ssdp ssdp on ssdp.ссылка=d.ссылка
	  left join ( SELECT min([Период]) as [Период],[Договор]
				          FROM [Stg].[_1cCMR].[РегистрНакопления_АктивныеДоговоры] with (nolock)
				         where [Активен]=1 and [ВидДвижения]=0 -- Вид движения = Расход (выдача ДС)
               --  and   [Период] >= dateadd(year,2000,dateadd(day,datediff(day,0,dateadd(day,-25,Getdate())),0)) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
				         group by [Договор] 
				       ) ad
		  on d.[Ссылка]=ad.[Договор]
	  left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				         from #MainTable mt0
					       left join #MainTable mt1 on mt0.[ПроРодитель]=mt1.[Подчиненный]
				        where mt0.[ПодчНаим] like N'Партнер%' or mt0.[ПодчНаим] like N'ВМ%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр'
				      ) tch -- Точка-РП-РО
		  on d.[Точка]=tch.[ТочкаСсылка]
	  left join ( SELECT z.[Ссылка],z.[Дата],z.[Номер],z.[Фамилия],z.[Имя],z.[Отчество],svz.[Имя] as [СпособВыдачиЗаймаНаим]
					           , dzsvz.[Имя] as [дз_СпособВыдачиЗаймаНаим],dkr.[Имя] as [ДокредитованиеНаим]
					           , kp.[Наименование] as [КредитныйПродуктНаим],ms.[Имя] as [МестоСозданияЗаявкиНаим]
					           , ttvz.[ТочкаВхода],ttvz.[ТочкаВходаНаим] as [ТочкаВходаЗаявкиНаим] ,o.[Наименование] as [ТочкаНаим]
				          FROM [Stg].[_1cMFO].[Документ_ГП_Заявка] z  with (nolock)
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
						      left join ( SELECT tvz.[ПредварительнаяЗаявка],pz.[Номер] as [НомерПредвЗаявки],pz.[Дата] as [ДатаПредвЗаявки],tvz.[ТочкаВхода],tv.[Наименование] as [ТочкаВходаНаим]
									              FROM [Stg].[_1cMFO].[РегистрСведений_ТочкиВходаЗаявок] tvz with (nolock)
										            left join [Stg].[_1cMFO].[Справочник_НастройкиПринадлежностиКРекламнымКомпаниям] tv with (nolock) --точка входа (справочник)
										              on tvz.[ТочкаВхода]=tv.[Ссылка]
										            left join [Stg].[_1cMFO].[Документ_DZ_ПредварительнаяЗаявка] pz with (nolock) -- предварительная заявка
										              on tvz.[ПредварительнаяЗаявка]=pz.[Ссылка]
									           ) ttvz
					          on z.[ПредварительнаяЗаявка]=ttvz.[ПредварительнаяЗаявка]
		                --		 where z.[ПометкаУдаления]=0x00 and cast(z.[Дата] as date)>='4019-04-30'
			        ) tv
		       on d.[Номер]=tv.[Номер]
    left join [Stg].[_1cMFO].[Перечисление_ТочкиВходаКлиентов] tvk with (nolock) on d.[ТочкаВходаКлиента]=tvk.[Ссылка]
    left join [Stg].[_1cMFO].[Перечисление_ТочкиВходаКлиентов] tv2k with (nolock) on d.[ТочкаВходаПовторногоКлиента]=tv2k.[Ссылка]
    left join [Stg].[_1cMFO].[Справочник_НастройкиПринадлежностиКРекламнымКомпаниям] rek with (nolock) on tv.[ТочкаВхода]=rek.[Ссылка]
    left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o with (nolock) on d.[Точка]=o.[Ссылка]
    left join [Stg].[_1cMFO].[Справочник_Контрагенты] cl with (nolock) on o.[Партнер]=cl.[Ссылка]
    left join #ClientLoanPoint8999 cl8999 on d.[Контрагент]=cl8999.[Контрагент]
    left join #max_r max_r on isnull(max_r.договор,0x00000000000000000000000000000000 )=d.[Ссылка]
	left join (select * from #pg00 where [rank_pg0]=1) pg on d.[Номер]=pg.[ДоговорНомер]
	left join [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] pep with (nolock) on d.[Номер]=pep.[ЗаявкаНомер]

	--DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
	--left join [Stg].[dbo].[lcrm_tbl_full_w_chanals2] ch with (nolock) on d.[Номер]=ch.[UF_ROW_ID]
	left join Stg._LCRM.lcrm_leads_full_channel_request AS ch (nolock) on d.[Номер]=ch.[UF_ROW_ID]

   where  --ad.[Период] >= dateadd(year,2000,dateadd(day,datediff(day,0,dateadd(day,-25,cast(Getdate() as date))),0)) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
            dateadd(year,-2000,ad.[Период]) >= dateadd(day,datediff(day,0,dateadd(day,-60,Getdate())),0) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
		 and  d.ссылка not in ( select [Договор]  from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock)  where [Статус]=0x80E400155D64100111E7C5361FF4393D  -- статус аннулирован
								         )
)
 select distinct  * into #t_end from t_end


 begin tran

delete from [dbo].[report_Agreement_InterestRate] 
where [ДатаВыдачи] >= dateadd(day,-60,dateadd(day,datediff(day,0,getdate()),0));

insert into [dbo].[report_Agreement_InterestRate] (
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


						  ,[ТочкаВходаЗаявки],[МестоСоздЗаявки],[СпособВыдачиЗайма]
                          ,[ТочкаВхКл],[ТочкаВхПовторКл],[КаналМФО_ТочкаВх]
													,[ДоговорТочкаКод]
                          ,[ДоговорТочкаНаим]
                          ,[АгентПартнер]
                          ,[РО_Регион]
                          ,[ПризнакПЭП]
                           
                        
                          ,SumEnsur
                          ,SumRat
                          ,SumKasko
                          ,EnsurКод
                          ,RatКод  
                          ,KaskoКод

						  ,[РО_Регион_фин]

						  ,[ДопПродукт_IDПлатСистемы]
						  ,[ДопПродукт_ID_Операции]
						  ,[ДопПродукт_СтатусСписанияСтраховки]
						  ,[КомментКСтатусуСписСтраховки]
						  ,[ДатаВыдачиПолн]

						  ,[ПЭП2_3пакет]
						  ,[АктПТСзабрали]

						  --,[ПЭП1_ДогМП_8999]
						  --,[ПЭП2_ПризнакЭДО]
						  --,[Партнер]
						  --,[ВМ]
						  ,[СпособОформленияЗайма]
						  , [ПризнакПозитивНастр]
						  , SumPositiveMood
						  , PositiveMoodКод
						  , [Канал от источника]
						  , [Группа каналов]

						  , SumHelpBusiness
						  , HelpBusinessКод
						  , [ПризнакПомощьБизнесу] 
                          )
                          

select distinct * from #t_end t_end 
where [ДатаВыдачи] >= dateadd(day,-60,dateadd(day,datediff(day,0,getdate()),0)) and  [ДоговорТочкаКод] not in (N'9949' ,N'9948' ,N'9984' ,N'9945')
--order by [ДатаВыдачи]  desc

commit tran

END
--go
--exec [dbo].[Report_Create_Agr_IntRate_v1_1] 
