
--exec Proc_CreatTable_Agr_IntRate_v1
CREATE PROCEDURE [dbo].[Report_Create_Agr_IntRate_vExclusive] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @GetDate2000 datetime

set @GetDate2000=dateadd(year,2000,getdate());

  --if OBJECT_ID('[dbo].[report_Agreement_InterestRate]') is not null 
  --drop table [dbo].[report_Agreement_InterestRate];

truncate table [dbo].[report_Agreement_InterestRate_vExclusive];

--delete from [dbo].[report_Agreement_InterestRate] 
--where [ДатаВыдачи]>=dateadd(day,-10,dateadd(day,datediff(day,0,getdate()),0));

--  create table [dbo].[report_Agreement_InterestRate_vExclusive]
--          (
--           [ДоговорНомер] nvarchar(20) null
--          ,[ДатаВыдачи] date null
--          ,[КолвоЗаймов] int null
--          ,[СуммаВыдачи] decimal(15,2) null
--          ,[ПроцСтавкаКредит] decimal(15,2) null
--          ,[СтавкаНаСумму] decimal(15,2) null 
--          ,[СуммаДопУслуг] decimal(15,2) null

--          ,[ПризнакКП] int null

--          ,[ПризнакСтраховка] int null
--          ,[ПризнакКаско] int null
--          ,[ПризнакСтрахованиеЖизни] int null
--          ,[ПризнакРАТ] int null

--          ,[ТочкаВходаЗаявки] nvarchar(255) null
--          ,[МестоСоздЗаявки] nvarchar(255) null
--          ,[СпособВыдачиЗайма] nvarchar(255) null
--          ,[ТочкаВхКл] nvarchar(255) null
--          ,[ТочкаВхПовторКл] nvarchar(255) null
--          ,[КаналМФО_ТочкаВх] nvarchar(255) null
--          ,[ДоговорТочкаКод] nvarchar(255) null
--          ,[ДоговорТочкаНаим] nvarchar(255) null
--          ,[АгентПартнер] nvarchar(255) null
--          ,[РО_Регион] nvarchar(255) null
--          ,[ПризнакПЭП] nvarchar(5) null

--           ,SumEnsur  decimal (38,2)
--           ,SumRat    decimal (38,2)
--           ,SumKasko  decimal (38,2)
--           ,EnsurКод  nvarchar(255) null
--           ,RatКод    nvarchar(255) null
--           ,KaskoКод  nvarchar(255) null

--		   ,[РО_Регион_фин] nvarchar(255) null

--		   ,[ДопПродукт_IDПлатСистемы] nvarchar(255) null
--		   ,[ДопПродукт_ID_Операции] nvarchar(255) null
--		   ,[ДопПродукт_СтатусСписанияСтраховки] nvarchar(255) null
--		   ,[КомментКСтатусуСписСтраховки] nvarchar(max) null
--		   ,[ДатаВыдачиПолн] smalldatetime null
--           )
--;
  with MainTable as
  (select distinct * from [Stg].[dbo].[aux_OfficeMFO_1c] with (nolock)
  --SELECT distinct [Этаж_L1] as [Этаж],[Род_L1] as [ПроРодитель],[Ссылка_L1] as [Родитель],[Код_L1] as [РодительКод],[Наим_L1] as [РодительНаим]
		--	 , [Этаж_L2] as [ЭтажНиже],[Ссылка_L2] as [Подчиненный],[Код_L2] as [ПодчКод],[Наим_L2] as [ПодчНаим]
  --  FROM [dbo].[OfficeStructure_1cMFO]
  -- WHERE not [Род_L1] is null or not [Ссылка_L2] is null

  -- union all

  --SELECT distinct [Этаж_L2] ,[Род_L2] ,[Ссылка_L2] ,[Код_L2] ,[Наим_L2] ,[Этаж_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3]
  --  FROM [dbo].[OfficeStructure_1cMFO]
  -- where not [Род_L2] is null or not [Ссылка_L3] is null

  -- union all

  --SELECT distinct [Этаж_L3] ,[Род_L3] ,[Ссылка_L3] ,[Код_L3] ,[Наим_L3] ,[Этаж_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4]
  --  FROM [dbo].[OfficeStructure_1cMFO]
  -- where not [Род_L3] is null or not [Ссылка_L4] is null

  -- union all

  --SELECT distinct [Этаж_L4] ,[Род_L4] ,[Ссылка_L4] ,[Код_L4] ,[Наим_L4] ,[Этаж_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5]
  --  FROM [dbo].[OfficeStructure_1cMFO]
  -- where not [Род_L4] is null or not [Ссылка_L5] is null

  --  union all

  --SELECT distinct [Этаж_L5] ,[Род_L5] ,[Ссылка_L5] ,[Код_L5] ,[Наим_L5] ,[Этаж_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6]
  --  FROM [dbo].[OfficeStructure_1cMFO]
  -- where not [Род_L5] is null or not [Ссылка_L6] is null

  -- union all

  --SELECT distinct [Этаж_L6] ,[Род_L6] ,[Ссылка_L6] ,[Код_L6] ,[Наим_L6] ,[Этаж_L7] ,[Ссылка_L7] ,[Код_L7] ,[Наим_L7]
  --  FROM [dbo].[OfficeStructure_1cMFO]
  -- where not [Род_L6] is null or not [Ссылка_L7] is null
)
,	ClientLoanPoint8999 as
(
  select t2.[Контрагент] -- t2.[Ссылка] ,t2.[Дата] ,t2.[rank] ,t2.[Точка] ,o.[Код] ,o.[Наименование] 
	     , tch.Точка ,tch.[РП_Регион], tch.[РО_Регион]
    from (select d2.[Ссылка] ,d2.[Дата] ,d2.[Контрагент] ,d2.[Точка] --,o.[Код] 
			         , rank() over(partition by d2.[Контрагент] order by d2.[Дата] desc) as [rank]
	          from [Stg].[_1cMFO].[Документ_ГП_Договор] (nolock) d2
		       where d2.[Точка]<>0x813521A3DABA1B0047111F5BDB98FE88
			       and d2.[Контрагент] in (select [Контрагент] from [Stg].[_1cMFO].[Документ_ГП_Договор] where [Точка]=0x813521A3DABA1B0047111F5BDB98FE88) 
		     )t2
    left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o on t2.[Точка]=o.[Ссылка]
    left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				         from MainTable mt0
					       left join(select * from MainTable) mt1 on mt0.[ПроРодитель]=mt1.[Подчиненный]
				        where mt0.[ПодчНаим] like N'Партнер%' or mt0.[ПодчНаим] like N'ВМ%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр'
 		          ) tch -- Точка-РП-РО
	         on t2.[Точка]=tch.[ТочкаСсылка]
   where t2.[rank]=1
)
, d1 as (
  SELECT s.[Договор],
         SumEnsur    =sum(case when ДопПродукт=0xB81300155D03491F11E958A5C7DB6817 then spdd.сумма else 0 end),
         SumRat      =sum(case when ДопПродукт=0xB81600155D4D0B5211E9968E54A9F742 then spdd.сумма else 0 end),
         SumKasko    =sum(case when ДопПродукт=0xB81600155D4D0B5211E9968E6C835BF9 then spdd.сумма else 0 end),
		 SumPositiveMood =sum(case when ДопПродукт=0xB81700155D4D0B5211E9F19852274C9E or ДопПродукт=0xB81700155D4D0B5211E9F198668D9373 then spdd.сумма else 0 end)

  FROM [Stg].[_1cCMR].[Справочник_Договоры_ДополнительныеПродукты] (nolock) spdd
    left join [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s  with (nolock) on s.ссылка=spdd.[ДоговорДопПродукта]
    left join [Stg].[_1cCMR].[Справочник_Договоры] sd  with (nolock) on sd.ссылка=s.[Договор]
   group by  s.[Договор]

) 
,ssdp as (
  select  sd.ссылка
       , SumEnsur    
       , SumRat      
       , SumKasko    
	     , SumPositiveMood  
       , EnsurКод = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81300155D03491F11E958A5C7DB6817)
       , RatКод   = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock)  where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81600155D4D0B5211E9968E54A9F742)
       , KaskoКод = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) where s1.[Договор]=sd.ссылка  and  ДопПродукт=0xB81600155D4D0B5211E9968E6C835BF9)
	     , PositiveMoodКод = (select s1.Код from [Stg].[_1cCMR].[Справочник_ДоговораПоДопПродуктам] s1 with (nolock) 
										  where s1.[Договор]=sd.ссылка and  (ДопПродукт=0xB81700155D4D0B5211E9F19852274C9E or ДопПродукт=0xB81700155D4D0B5211E9F198668D9373))
  from d1 
  left join [Stg].[_1cCMR].[Справочник_Договоры] sd with (nolock) on sd.ссылка=d1.[Договор]
)  
,r as (
  select Договор ,max(Период) max_p
    from [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] (nolock) pd
   group by  Договор
)
,max_r as (
  select pd.договор
        ,НачисляемыеПроценты
        ,ПроцентнаяСтавка
    from [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] (nolock) pd
    join r on r.Договор=pd. Договор and r.max_p=pd.Период
)
,	pg00 as -- таблица платежного шлюза
(
select [_Period] ,[_Fld27] as [ДоговорНомер]
	  ,case 
			when [_Fld29_RTRef]=0x0000000A then N'Wallet One'
			when [_Fld29_RTRef]=0x00000043 then N'Contact'
			when [_Fld29_RTRef]=0x00000090 then N'Cloud payments'
	  end as [ID_ПлатежнойСистемы]
      ,[_Fld62] as [ID_Операции]
      ,[_Fld38] as [Статус]
	  ,[_Fld39] as [Комментарий]
	  ,rank() over (partition by [_Fld27] order by [_Period] desc) as [rank_pg0]
from [Stg].[_1cPG].[PGPayments] (nolock) pg0
where [_Fld92]>0 and 
	  exists (select [Код] 
			  from [Stg].[_1cCMR].[Справочник_Договоры] sd 
			  where pg0.[_Fld27]=sd.[Код] and cast(dateadd(year,-2000,sd.[Дата]) as date)>= '2019-01-01')--dateadd(day,datediff(day,0,dateadd(day,-15,Getdate())),0)) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-4,Getdate())),0))
)
,	t_end as
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
     
     
     , [ПризнакКП] =case when isnull(SumEnsur,0)<>0   or isnull(SumKasko,0)<>0 or isnull(SumRat,0) <>0  or isnull(SumPositiveMood,0)<>0 then 1 else 0 end 
     , [ПризнакСтраховка] =case when isnull(SumEnsur,0)<>0   or isnull(SumKasko,0)<>0 then 1 else 0 end 
     
       ,[ПризнакКаско] =case when  isnull(SumKasko,0)<>0  then 1 else 0 end 
       ,[ПризнакСтрахованиеЖизни]  =case when isnull(SumEnsur,0)<>0   then 1 else 0 end 
     
     , [ПризнакРАТ]       =case when isnull(SumRat,0) <>0 then 1 else 0 end 
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

	   ,case  
			when o.[Код]=N'8999' then N'ПЭП'
			else case 
					when not tch.[РО_Регион] is null then tch.[РО_Регион] 
					else N'Микрофинансирование'
				 end
		end as [РО_Регион_фин]
		,pg.[ID_ПлатежнойСистемы] as [ДопПродукт_IDПлатСистемы]
		,pg.[ID_Операции] as [ДопПродукт_ID_Операции]
		,case 
			when cast(dateadd(year,-2000,ad.[Период]) as date)>='2019-01-01' then case when d.[СуммаДополнительныхУслуг]<>0 then N'SUCCEEDED' else N'' end
			else 
				case when d.[СуммаДополнительныхУслуг]<>0 then case when pg.[Статус]<>N'' then pg.[Статус] 
																	 else N'Отсутствует' 
																 end
					  else N'' end
			end as [ДопПродукт_СтатусСписанияСтраховки]
			--when d.[СуммаДополнительныхУслуг]<>0 then case when  pg.[Статус]<>N'' then pg.[Статус] else  N'SUCCEEDED' end
			--when d.[СуммаДополнительныхУслуг]<>0 or d.[СуммаДополнительныхУслуг]=0 then N''	
			--when pg.[Статус]=N'' then N'Отсутствует' 
			--else pg.[Статус] 
		--end as [ДопПродукт_СтатусСписанияСтраховки]
		,pg.[Комментарий] as [КомментКСтатусуСписСтраховки]
		, cast(dateadd(year,-2000,ad.[Период]) as smalldatetime) as [ДатаВыдачиПолн]

		,case when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 then N'Да' else N'' end as [ПЭП2_3пакет] --and pep.[ПЭП_0]=1 then N'Да' else N'' end as [ПЭП2_3пакет]
		,null as [АктПТСзабрали]



		,case when o.[Код]=N'8999' then N'Да' else N'' end as [ПЭП1_ДогМП_8999]
		,case when pep.[ПЭП2]=1 then N'Да' else N'' end as [ПЭП2_ПризнакЭДО]
		,case when o.[Наименование] like '%Партнер №%' then N'Да' else N'' end as [Партнер]
		,case when pep.[ВМ]=1 then N'Да' else N'' end as [ВМ]  -- o.[Наименование] like '%ВМ №%' then N'Да' else N'' end as [ВМ]
		--,case
		--	when o.[Код]=N'8999' then N'ПЭП1'
		--	when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП_0]=1 then N'ПЭП2'	--pep.[ПЭП2]=1 then N'ПЭП2'
		--	when o.[Наименование] like '%Партнер №%' then N'Партнер'
		--	when pep.[ВМ]=1 then N'ВМ'
		--end as [СпособВыдачиЗайма]

		,case
			when o.[Код]=N'8999' then N'ПЭП1'
			when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 then N'ПЭП2'	--pep.[ПЭП2]=1 then N'ПЭП2'
			when o.[Наименование] like '%Партнер №%' then N'Партнер'
			when pep.[ВМ]=1 then N'ВМ'
		end as [СпособОформленияЗайма]

		, [ПризнакПозитивНастр] =case when isnull(SumPositiveMood,0) <>0 then 1 else 0 end 
		, SumPositiveMood
		, PositiveMoodКод

		, ch.[Канал от источника]
		, ch.[Группа каналов]


    FROM [Stg].[_1cMFO].[Документ_ГП_Договор] d with (nolock)
    left join ssdp on ssdp.ссылка=d.ссылка
	  left join ( SELECT min([Период]) as [Период],[Договор]
				          FROM [Stg].[_1cCMR].[РегистрНакопления_АктивныеДоговоры] with (nolock)
				         where [Активен]=1 and [ВидДвижения]=0 -- Вид движения = Расход (выдача ДС)
				         group by [Договор]
				       ) ad
		  on d.[Ссылка]=ad.[Договор]
	  left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				         from MainTable mt0
					       left join(select * from MainTable) mt1 on mt0.[ПроРодитель]=mt1.[Подчиненный]
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
    left join ClientLoanPoint8999 cl8999 on d.[Контрагент]=cl8999.[Контрагент]
    left join max_r on isnull(max_r.договор,0x00000000000000000000000000000000 )=d.[Ссылка]
	left join (select * from pg00 where [rank_pg0]=1) pg on d.[Номер]=pg.[ДоговорНомер]
	left join [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] pep with (nolock) on d.[Номер]=pep.[ЗаявкаНомер]

	--DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
	--left join [Stg].[dbo].[lcrm_tbl_full_w_chanals2] ch with (nolock) on d.[Номер]=ch.[UF_ROW_ID]
	left join Stg._LCRM.lcrm_leads_full_channel_request AS ch (nolock) on d.[Номер]=ch.[UF_ROW_ID]

   where cast(dateadd(year,-2000,ad.[Период]) as date)>= '2019-01-01' --dateadd(day,datediff(day,0,dateadd(day,-15,Getdate())),0) --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-3,Getdate())),0)
		 and not d.ссылка in ( select [Договор]  from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock)  where [Статус]=0x80E400155D64100111E7C5361FF4393D  -- статус аннулирован
								         )
)



insert into [dbo].[report_Agreement_InterestRate_vExclusive] (
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

						  ,[ПЭП1_ДогМП_8999]
						  ,[ПЭП2_ПризнакЭДО]
						  ,[Партнер]
						  ,[ВМ]

						  , [СпособОформленияЗайма]
						  , [ПризнакПозитивНастр]
						  , SumPositiveMood 
						  , PositiveMoodКод
						  , [Канал от источника]
						  , [Группа каналов]
                          )
                          

select distinct * from t_end 
where not [ДоговорТочкаКод] in (N'9949' ,N'9948' ,N'9984' ,N'9945')
		-- and [ДатаВыдачи]>=dateadd(day,-10,dateadd(day,datediff(day,0,getdate()),0))
order by [ДатаВыдачи]  desc
END
