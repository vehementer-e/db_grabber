-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05.02.2020
-- Description:	Sales Dashboard
-- truncate table dbo.dm_Sales
-- exec dbo.CalculateOnlineDashBoard '20180101','20220718'
-- select * from dbo.dm_Sales order by датавремя, ishistory
-- select * from dbo.dm_SalesBusiness order by 1
-- select * from dbo.dm_SalesP2P
--DELETE FROM dbo.dm_Sales WHERE ISHISTORY=1
-- select * from dbo.dm_SalesDashboard
-- =============================================
-- Modyfied:	09.09.2022, А.Никитин
-- Description:	DWH-1724 Добавить продукт РАТ2_0 в витрину и бота
-- =============================================
-- Modyfied:	02.12.2022, А.Никитин
-- Description:	DWH-1817 Внести информацию о новом продукте "РАТ Юр. услуги"
-- =============================================
CREATE PROC [dbo].[CalculateOnlineDashBoard]
--declare 
 @saleDateFrom  date = null
,@saleDateTo  date = null
AS
BEGIN
  set XACT_ABORT ON ;
  SET NOCOUNT ON;
  SET DEADLOCK_PRIORITY HIGH;
begin try
  --declare @saleDate  date=cast(getdate() as date)
  -- declare  @saleDateFrom date;  declare @saleDateTo date

  set @saleDateFrom = isnull(@saleDateFrom, dateadd(dd,1,eomonth(getdate(), -2)))
  set @saleDateTo   = dateadd(day,1, isnull(@saleDateTo,cast(getdate() as date)))

  --set @saleDateFrom = '20200201'
  --set @saleDateTo   = '20200331'

  declare @dFrom date=dateadd(year,2000,@saledateFrom)
        , @dTo   date=dateadd(year,2000,@saledateTo)
  
declare @koef_5_6 float = 0.83333333333
declare @koef_1_6 float = 0.16666666666

declare @partitionFromId int = $partition.[pfn_range_right_date_part_dm_Sales](@saleDateFrom)
	,@partitionToId int = $partition.[pfn_range_right_date_part_dm_Sales](@saleDateTo)
	
	drop table if exists #partitions
	;with cte as
	(
		select partitionId = @partitionFromId 
		union all
		select partitionId+1  from cte
		where partitionId <@partitionToId
	)
	select  partitionId 
	into #partitions
	from cte
	option (maxrecursion 0)
	
 if OBJECT_ID('dbo.dm_Sales_stage') is null
 BEGIN
	create table [dbo].[dm_Sales_stage](
		[ДатаВыдачи] [date] NULL,
		[Дата] [date] NULL,
		[ДатаВремя] [datetime2](0) NULL,
		[CMRДоговор] [binary](16) NULL,
		[Код] [nvarchar](14) NULL,
		[Сумма] [numeric](10, 2) NULL,
		[ПроцентнаяСтавка] [numeric](18, 8) NULL,
		[СтавкаНаСумму] [numeric](29, 10) NULL,
		[Помощь бизнесу] [numeric](38, 2) NULL,
		[Страхование жизни] [numeric](38, 2) NULL,
		[РАТ] [numeric](38, 2) NULL,
		[КАСКО] [numeric](38, 2) NULL,
		[От потери работы. «Максимум»] [numeric](38, 2) NULL,
		[От потери работы. «Стандарт»] [numeric](38, 2) NULL,
		[телемедицина] [numeric](38, 2) NULL,
		[СпособОформления] [varchar](33) NULL,
		[lastStatus] [nvarchar](25) NULL,
		[Вид заполнения] [nvarchar](100) NULL,
		[channel_B] [varchar](14) NOT NULL,
		[created] [datetime] NOT NULL,
		[ishistory] [int] NOT NULL,
		[updated] [datetime] NOT NULL,
		[Защита от потери работы] [numeric](38, 2) NULL,
		[Помощь бизнесу_without_partner_bounty] [money] NULL,
		[Страхование жизни_without_partner_bounty] [money] NULL,
		[РАТ_without_partner_bounty] [money] NULL,
		[КАСКО_without_partner_bounty] [money] NULL,
		[От потери работы. «Максимум»_without_partner_bounty] [money] NULL,
		[От потери работы. «Стандарт»_without_partner_bounty] [money] NULL,
		[Телемедицина_without_partner_bounty] [money] NULL,
		[Защита от потери работы_without_partner_bounty] [money] NULL,
		[Фарм страхование] [money] NULL,
		[Фарм страхование_without_partner_bounty] [money] NULL,
		[Спокойная жизнь] [money] NULL,
		[Спокойная жизнь_without_partner_bounty] [money] NULL,
		[Помощь бизнесу NET] [money] NULL,
		[Страхование жизни NET] [money] NULL,
		[РАТ NET] [money] NULL,
		[КАСКО NET] [money] NULL,
		[От потери работы. «Максимум» NET] [money] NULL,
		[От потери работы. «Стандарт» NET] [money] NULL,
		[Телемедицина NET] [money] NULL,
		[Защита от потери работы NET] [money] NULL,
		[Фарм страхование NET] [money] NULL,
		[Спокойная жизнь NET] [money] NULL,
		[Канал] [nvarchar](255) NULL,
		[IsInstallment] [bit] NOT NULL,
		[Вид займа] [nvarchar](100) NULL,
		[РАТ 2.0] [numeric](38, 2) NULL,
		[РАТ 2.0_without_partner_bounty] [money] NULL,
		[РАТ 2.0 NET] [money] NULL,
		[РАТ Юр. услуги] [numeric](38, 2) NULL,
		[РАТ Юр. услуги_without_partner_bounty] [money] NULL,
		[РАТ Юр. услуги NET] [money] NULL,

		[ЗАЩИТА ЗДОРОВЬЯ] numeric(38, 2) NULL,
		[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty] money NULL,
		[ЗАЩИТА ЗДОРОВЬЯ NET] money NULL,

		[ФАРМА-помощь] numeric(38, 2) NULL,
		[ФАРМА-помощь_without_partner_bounty] money NULL,
		[ФАРМА-помощь NET] money NULL,

		[Автоспор] numeric(38, 2) NULL,
		[Автоспор_without_partner_bounty] money NULL,
		[Автоспор NET] money NULL,
		[Безопасность семьи] money,
		[Безопасность семьи_without_partner_bounty] money,
		[Безопасность семьи NET]	money,
		
		ТипПродукта		nvarchar(255),
		ТипПродукта_Код	nvarchar(255),
		[Защита жизни и здоровья] money,
		[Защита жизни и здоровья_without_partner_bounty] money,
		[Защита жизни и здоровья NET]	money,
		[СуммаДопУслуг] AS 
		convert(money,
				isnull([КАСКО],0)
				+ isnull([Страхование жизни],0)
				+ isnull([РАТ],0)
				+ isnull([РАТ 2.0],0)
				+ isnull([Помощь бизнесу],0)
				+ isnull([телемедицина],0)
				+ isnull([Защита от потери работы],0)
				+ isnull([От потери работы. «Максимум»],0)
				+ isnull([От потери работы. «Стандарт»],0)
				+ isnull([Фарм страхование],0)
				+ isnull([Спокойная жизнь],0)
				+ isnull([РАТ Юр. услуги],0)
				+ isnull([ЗАЩИТА ЗДОРОВЬЯ],0)
				+ isnull([ФАРМА-помощь],0)
				+ isnull([Автоспор],0)
				+ isnull([Безопасность семьи],0) 
				+ isnull([Защита жизни и здоровья],0)

		),
		[СуммаДопУслуг_without_partner_bounty] AS 
		convert(money,
			+ isnull([КАСКО_without_partner_bounty],0)
			+ isnull([Страхование жизни_without_partner_bounty],0)
			+ isnull([РАТ_without_partner_bounty],0)
			+ isnull([РАТ 2.0_without_partner_bounty],0)
			+ isnull([Помощь бизнесу_without_partner_bounty],0)
			+ isnull([Телемедицина_without_partner_bounty],0)
			+ isnull([Защита от потери работы_without_partner_bounty],0)
			+ isnull([От потери работы. «Максимум»_without_partner_bounty],0)
			+ isnull([От потери работы. «Стандарт»_without_partner_bounty],0)
			+ isnull([Фарм страхование_without_partner_bounty],0)
			+ isnull([Спокойная жизнь_without_partner_bounty],0)
			+ isnull([РАТ Юр. услуги_without_partner_bounty],0)
			+ isnull([ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty],0)
			+ isnull([ФАРМА-помощь_without_partner_bounty],0)
			+ isnull([Автоспор_without_partner_bounty],0)
			+ isnull([Безопасность семьи_without_partner_bounty],0)
			+ isnull([Защита жизни и здоровья_without_partner_bounty],0)
		),
		[СуммаДопУслуг_without_partner_bounty_net] AS 
		convert(money,
			isnull([КАСКО NET],0)
			+isnull([Страхование жизни NET],0)
			+isnull([РАТ NET],0)
			+isnull([РАТ 2.0 NET],0)
			+isnull([Помощь бизнесу NET],0)
			+isnull([Телемедицина NET],0)
			+isnull([Защита от потери работы NET],0)
			+isnull([От потери работы. «Максимум» NET],0)
			+isnull([От потери работы. «Стандарт» NET],0)
			+isnull([Фарм страхование NET],0)
			+isnull([Спокойная жизнь NET],0)
			+isnull([РАТ Юр. услуги NET],0)
			+isnull([ЗАЩИТА ЗДОРОВЬЯ NET],0)
			+isnull([ФАРМА-помощь NET],0)
			+isnull([Автоспор NET],0)
			+isnull([Безопасность семьи NET],0)
			+isnull([Защита жизни и здоровья NET],0)
	),

) ON [PRIMARY]
	

	ALTER TABLE [dbo].dm_Sales_stage ADD  DEFAULT ((0)) FOR [IsInstallment]


	CREATE CLUSTERED INDEX [Cl_Idx_ДатаВыдачи] ON [dbo].dm_Sales_stage
	(
		[ДатаВыдачи] ASC
	) on [pschema_pfn_range_right_date_part_dm_Sales]([ДатаВыдачи])
  END
  



	truncate table dbo.dm_Sales_stage
	insert into dbo.dm_Sales_stage
	(
		[ДатаВыдачи],
		[Дата],
		[ДатаВремя],
		[CMRДоговор],
		[Код],
		[Сумма],
		[ПроцентнаяСтавка],
		[СтавкаНаСумму],
		[Помощь бизнесу],
		[Страхование жизни],
		[РАТ],
		[КАСКО],
		[От потери работы. «Максимум»],
		[От потери работы. «Стандарт»],
		[телемедицина],
		[СпособОформления],
		[lastStatus],
		[Вид заполнения],
		[channel_B],
		[created],
		[ishistory],
		[updated],
		[Защита от потери работы],
		[Помощь бизнесу_without_partner_bounty],
		[Страхование жизни_without_partner_bounty],
		[РАТ_without_partner_bounty],
		[КАСКО_without_partner_bounty],
		[От потери работы. «Максимум»_without_partner_bounty],
		[От потери работы. «Стандарт»_without_partner_bounty],
		[Телемедицина_without_partner_bounty],
		[Защита от потери работы_without_partner_bounty],
		[Фарм страхование],
		[Фарм страхование_without_partner_bounty],
		[Спокойная жизнь],
		[Спокойная жизнь_without_partner_bounty],
		[Помощь бизнесу NET],
		[Страхование жизни NET],
		[РАТ NET],
		[КАСКО NET],
		[От потери работы. «Максимум» NET],
		[От потери работы. «Стандарт» NET],
		[Телемедицина NET],
		[Защита от потери работы NET],
		[Фарм страхование NET],
		[Спокойная жизнь NET],
		[Канал],
		[IsInstallment],
		[Вид займа],
		[РАТ 2.0],
		[РАТ 2.0_without_partner_bounty],
		[РАТ 2.0 NET],
		[РАТ Юр. услуги],
		[РАТ Юр. услуги_without_partner_bounty],
		[РАТ Юр. услуги NET],
		[ЗАЩИТА ЗДОРОВЬЯ],
		[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty],
		[ЗАЩИТА ЗДОРОВЬЯ NET],
		[ФАРМА-помощь],
		[ФАРМА-помощь_without_partner_bounty],
		[ФАРМА-помощь NET],
		[Автоспор],
		[Автоспор_without_partner_bounty],
		[Автоспор NET],
		[Безопасность семьи],
		[Безопасность семьи_without_partner_bounty],
		[Безопасность семьи NET],
		ТипПродукта,
		ТипПродукта_Код,
		[Защита жизни и здоровья],							
		[Защита жизни и здоровья_without_partner_bounty],	
		[Защита жизни и здоровья NET]		
	)
	select 
		[ДатаВыдачи],
		[Дата],
		[ДатаВремя],
		[CMRДоговор],
		[Код],
		[Сумма],
		[ПроцентнаяСтавка],
		[СтавкаНаСумму],
		[Помощь бизнесу],
		[Страхование жизни],
		[РАТ],
		[КАСКО],
		[От потери работы. «Максимум»],
		[От потери работы. «Стандарт»],
		[телемедицина],
		[СпособОформления],
		[lastStatus],
		[Вид заполнения],
		[channel_B],
		[created],
		[ishistory],
		[updated],
		[Защита от потери работы],
		[Помощь бизнесу_without_partner_bounty],
		[Страхование жизни_without_partner_bounty],
		[РАТ_without_partner_bounty],
		[КАСКО_without_partner_bounty],
		[От потери работы. «Максимум»_without_partner_bounty],
		[От потери работы. «Стандарт»_without_partner_bounty],
		[Телемедицина_without_partner_bounty],
		[Защита от потери работы_without_partner_bounty],
		[Фарм страхование],
		[Фарм страхование_without_partner_bounty],
		[Спокойная жизнь],
		[Спокойная жизнь_without_partner_bounty],
		[Помощь бизнесу NET],
		[Страхование жизни NET],
		[РАТ NET],
		[КАСКО NET],
		[От потери работы. «Максимум» NET],
		[От потери работы. «Стандарт» NET],
		[Телемедицина NET],
		[Защита от потери работы NET],
		[Фарм страхование NET],
		[Спокойная жизнь NET],
		[Канал],
		[IsInstallment],
		[Вид займа],
		[РАТ 2.0],
		[РАТ 2.0_without_partner_bounty],
		[РАТ 2.0 NET],
		[РАТ Юр. услуги],
		[РАТ Юр. услуги_without_partner_bounty],
		[РАТ Юр. услуги NET],
		[ЗАЩИТА ЗДОРОВЬЯ],
		[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty],
		[ЗАЩИТА ЗДОРОВЬЯ NET],
		[ФАРМА-помощь],
		[ФАРМА-помощь_without_partner_bounty],
		[ФАРМА-помощь NET],
		[Автоспор],
		[Автоспор_without_partner_bounty],
		[Автоспор NET],
		[Безопасность семьи],
		[Безопасность семьи_without_partner_bounty],
		[Безопасность семьи NET],
		ТипПродукта,
		ТипПродукта_Код,
		[Защита жизни и здоровья],							
		[Защита жизни и здоровья_without_partner_bounty],	
		[Защита жизни и здоровья NET]						
	from dbo.dm_Sales
	where $partition.[pfn_range_right_date_part_dm_Sales]([ДатаВыдачи]) in (Select partitionId from #partitions)

  
  
 drop table if exists #CmrStatuses
 SELECT distinct d.код external_id
       ,Договор = d.Ссылка
	   ,Период = dateadd(year,-2000, sd.Период)
	   ,lastStatus = st.Наименование
    into #CmrStatuses
		from stg._1cCMR.[Справочник_Договоры] d  
	inner join (
		select  
			Период = max(Период), Договор
		from stg._1cCMR.[РегистрСведений_СтатусыДоговоров]     sd
		group by Договор
	) t_last  on t_last.Договор = d.Ссылка
	inner join stg._1cCMR.[РегистрСведений_СтатусыДоговоров] sd
		on sd.Договор = t_last.Договор
			and sd.Период = t_last.Период
	join stg._1cCMR.[Справочник_СтатусыДоговоров] st on st.Ссылка=sd.Статус
	where exists(select top(1) 1 from stg._1cCMR.[Документ_выдачаДенежныхСредств] dvds 
	where ДатаВыдачи>=@dFrom and ДатаВыдачи<@dTo and dvds.Договор=d.Ссылка
		and dvds.Проведен = 0x01
		and dvds.ПометкаУдаления = 0x00
		)
		and d.Тестовый = 0x00
		and (d.Фамилия not like '%ТЕСТ%' or  d.код = '24050302025421')
	


   

--  select * from #CmrStatuses

-- CRM Заявки
  drop table if exists #CRMRequests
  select r.Номер external_id
       , p.Представление СпособОформления
    into #CRMRequests
    from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС    r
    join stg._1cCRM.Перечисление_СпособыОформленияЗаявок p on p.Ссылка=r.   СпособОформления
  
   where r.ДатаВыдачи>=@dFrom and r.ДатаВыдачи<@dTo

--select * from #CRMRequests r full join #CmrStatuses s on r.external_id=s.external_id

  drop table if exists #RequestFilling
 

   SELECT [Номер заявки]
        , [Вид заполнения]
     into #RequestFilling
     FROM
          (
            SELECT *
                 , ROW_NUMBER () over (partition by [Номер заявки] order by [Дата изменения] DESC) as RN
              FROM
                  (
                   SELECT [Номер заявки]
                        , iif (Статус='Контроль данных' or DATEDIFF (mi,dateadd(year,-2000,[Дата изменения]),[Контроль данных])>=0 or [Контроль данных] is null,1,null) 'Флаг'
                        , [Вид заполнения]
                        , [Дата изменения]
                        , [Контроль данных]
                        , DATEDIFF (mi,dateadd(year,-2000,[Дата изменения]),[Контроль данных]) RN1
                        , Статус
                     FROM [Reports].[dbo].[dm_FillingTypeChangesInRequests] s1 with(nolock)
                      join #CRMRequests r on r.external_id=s1.[Номер заявки]
                     left join [Reports].[dbo].[dm_Factor_Analysis_001] s2 on s1.[Номер заявки]=s2.Номер
                  ) s3
             where Флаг=1
          ) s4
    where RN = 1


--select * from #RequestFilling

-- Проценты по договорам

  drop table if exists #max_r
  --declare @d date=dateadd(year,2000,cast(getdate() as date))
  ;
  with r as (select pd.Договор 
                  , max(Период) max_p
               from stg._1cCMR.[РегистрСведений_ПараметрыДоговора]  pd
               where exists(select top(1) 1 from stg._1cCMR.[Документ_выдачаДенежныхСредств] dvds 
				where dvds.Договор=pd.Договор
				and ДатаВыдачи>=@dFrom and ДатаВыдачи<@dTo 
				and dvds.Проведен = 0x01  
				)
              group by  pd.Договор--,Код
            )
    select pd.договор
         , НачисляемыеПроценты
         , ПроцентнаяСтавка
      into #max_r
      from stg._1cCMR.[РегистрСведений_ПараметрыДоговора]  pd
      join r on r.Договор=pd. Договор and r.max_p=pd.Период

  
  

  -- выдачи
  drop table if exists #v
  ;
  with remote_query as (
  select d.Дата
       , d.Код
       , d.Сумма
       , ДопПродукт         = case 
				when spdd.Наименование = 'ЗАЩИТА ЗДОРОВЬЯ' and spdd.Наименование2 = 'Право на медицинскую помощь'  
						then	spdd.Наименование2
				else spdd.Наименование end
	   , ДополнительныйПродуктId = dd.ДополнительныйПродукт
       , ДопПродуктСумма    =dd.Сумма 
       , Договор=d.Ссылка
	   , ДатаДоговора = dateadd(year,-2000,cast(d.Дата as date))
       , ДатаВыдачи=dateadd(year,-2000,cast(sd.Период as date))
	   , IsInstallment  = IIF(d.IsInstallment = 0x01, 1, 0)
	   , ТипПродукта_Код = cmr_типыПродуктов.ИдентификаторMDS
	   , ТипПродукта = cmr_типыПродуктов.Наименование
    from stg._1cCMR.[Справочник_Договоры] d  
    left join stg._1cCMR.[Справочник_Договоры_ДополнительныеПродукты] dd on dd.ссылка=d.ссылка
    left join stg._1cCMR.[Справочник_ДополнительныеПродукты] spdd on spdd.ссылка=dd.ДополнительныйПродукт
	LEFT JOIN Stg._1cCMR.Справочник_Заявка AS cmr_Заявка
			on cmr_Заявка.Ссылка = d.Заявка
	LEFT JOIN Stg._1cCMR.Справочник_типыПродуктов AS cmr_типыПродуктов
		on cmr_Заявка.ТипПродукта = cmr_типыПродуктов.ссылка	
	inner join 
	(
		select Договор, Период = min(Период) from stg._1cCMR.[РегистрСведений_СтатусыДоговоров]     sd
        inner join stg._1cCMR.[Справочник_СтатусыДоговоров] st 
		on st.Ссылка=sd.Статус
		and st.Наименование = 'Действует'
		where Период>=@dFrom and Период<@dTo
		group by Договор
	) sd on sd.Договор = d.Ссылка
	
	
	and exists(select top(1) 1 from stg._1cCMR.[Документ_выдачаДенежныхСредств]  vds
	where Проведен = 0x01  and vds.Договор=d.Ссылка
		)
    )
    select rq.*
         , ПроцентнаяСтавка   = iif (cast(r.[ПроцентнаяСтавка] as int)=0,r.[НачисляемыеПроценты],r.[ПроцентнаяСтавка])
         , СтавкаНаСумму   = iif (cast(r.[ПроцентнаяСтавка] as int)=0,r.[НачисляемыеПроценты],r.[ПроцентнаяСтавка])*rq.Сумма
      into #v
      from remote_query rq
      left join #max_r r on r.договор=rq.Договор
     order by rq.Дата,rq.код
	 drop table if exists #t_return_type
;with cte_log as 
(
	select Number
		,Call_date = cast(Call_date as date)
		,isnull(client_type_2, client_type_1) as client_type   
		,ROW_NUMBER() over(partition by Number order by call_date desc )nRow
	from stg.[_loginom].[Originationlog]
			where Stage in ('Call 1', 'Call 2')
			and Call_date>='2019-12-01'
			and cast(Call_date as date) between @saleDateFrom and @saleDateTo
)
	select код = cast(l.Number as nvarchar(100)),
		Call_date,
		return_type = case 
		when l.client_type in ('docred', 'active') then 'Докредитование'
		when l.client_type in ('parallel') then 'Параллельный'
		when l.client_type in ('repeated', 'repeat') then 'Повторный'
		else 'Первичный' end
into #t_return_type
		from cte_log l
	where nRow = 1


    -- select distinct  допПродукт from #v
   -- select * from stg._1cCMR.[Справочник_ДополнительныеПродукты]
  --  select * from #v order by ДатаВыдачи
  --select * from stg._mds.hdbkPartnerFeeCP 
  /*Собираем информацию по доп продуктам и  коммиссю партенров за это и складываем в одну таблицу*/
   /*Собираем информацию по доп продуктам и  коммиссю партенров за это и складываем в одну таблицу*/
  drop table if exists #ensurance
  ;with cte_допПродукт as 
  (
	  select Договор,
			Код,
			[Помощь бизнесу]				= sum(isnull(pvt_допПродукт.[Помощь бизнесу],0.00)),
			[Страхование жизни]				= sum(isnull(pvt_допПродукт.[Страхование жизни],0.00)), 
			[РАТ]							= sum(isnull(pvt_допПродукт.[РАТ],0.00)), 
			[РАТ 2.0]						= sum(isnull(pvt_допПродукт.[РАТ 2.0],0.00)), 
			[КАСКО]							= sum(isnull(pvt_допПродукт.[КАСКО],0.00)), 
			[От потери работы. «Максимум»]	= sum(isnull(pvt_допПродукт.[От потери работы. «Максимум»],0.00)), 
			[От потери работы. «Стандарт»]	= sum(isnull(pvt_допПродукт.[От потери работы. «Стандарт»],0.00)), 
			[Телемедицина]					= sum(isnull(pvt_допПродукт.[Телемедицина],0.00)), 
			[Защита от потери работы]		= sum(isnull(pvt_допПродукт.[Защита от потери работы],0.00)),
			[Фарм страхование]				= sum(isnull(pvt_допПродукт.[Фарм страхование],0.00)),
			[Спокойная жизнь]				= sum(isnull(pvt_допПродукт.[Спокойная жизнь],0.00)),
			[РАТ Юр. услуги]				= sum(isnull(pvt_допПродукт.[РАТ Юр. услуги],0.00)),
			[Право на медицинскую помощь]	= sum(isnull(pvt_допПродукт.[Право на медицинскую помощь],0.00)),
			[ФАРМА-помощь]					= sum(isnull(pvt_допПродукт.[ФАРМА-помощь],0.00)),
			[Автоспор]						= sum(isnull(pvt_допПродукт.[Автоспор],0.00)),
			[Безопасность семьи]			= sum(isnull(pvt_допПродукт.[Безопасность семьи],0.00)),
			[Защита жизни и здоровья]		= sum(isnull(pvt_допПродукт.[Защита жизни и здоровья], 0.00))
		   --,pfCp.*
 
		from #v v
		PIVOT (
			SUM(v.ДопПродуктСумма)
			FOR v.ДопПродукт IN (
				[Спокойная жизнь], 
				[Помощь бизнесу], 
				[Страхование жизни], 
				[РАТ], 
				[РАТ 2.0],
				[КАСКО], 
				[От потери работы. «Максимум»], 
				[От потери работы. «Стандарт»], 
				[Телемедицина], 
				[Защита от потери работы],
				[Фарм страхование],
				[РАТ Юр. услуги],
				[Право на медицинскую помощь],
				[ФАРМА-помощь],
				[Автоспор],
				[Безопасность семьи],
				[Защита жизни и здоровья]
			)  
		) pvt_допПродукт
		group by Договор,		Код
	), cte_PartnerFeeCP as (
		 select Договор,
			Код,
			[Помощь бизнесу Commission]				= SUM(isnull(pvt_PartnerFeeCP.[Помощь бизнесу], 0.00)),
			[Помощь бизнесу VAT]					= cast(min(iif(ДатаВыдачи between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Помощь бизнесу]>0, 20, null)) as money), 
			[Страхование жизни Commission]			= SUM(isnull(pvt_PartnerFeeCP.[Страхование жизни], 0.00)), 
			[Страхование жизни VAT]					= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Страхование жизни]>0, 20, null)) as money), 
			[РАТ Commission]						= SUM(isnull(pvt_PartnerFeeCP.[РАТ], 0.00)), 
			[РАТ VAT]								= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[РАТ]>0, 20, null)) as money), 

			[РАТ 2.0 Commission]					= SUM(isnull(pvt_PartnerFeeCP.[РАТ 2.0], 0.00)), 
			[РАТ 2.0 VAT]							= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[РАТ 2.0]>0, 20, null)) as money), 

			[КАСКО Commission]						= SUM(isnull(pvt_PartnerFeeCP.[КАСКО], 0.00)), 
			[КАСКО VAT]								= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[КАСКО]>0, 20, null)) as money), 
			[От потери работы. «Максимум» Commission]	= SUM(isnull(pvt_PartnerFeeCP.[От потери работы. «Максимум»], 0.00)), 
			[От потери работы. «Максимум» VAT]		= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[От потери работы. «Максимум»]>0, 20, null)) as money), 
			[От потери работы. «Стандарт» Commission]	= SUM(isnull(pvt_PartnerFeeCP.[От потери работы. «Стандарт»], 0.00)), 
			[От потери работы. «Стандарт» VAT]		= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[От потери работы. «Стандарт»]>0, 20, null)) as money), 
			[Телемедицина Commission]				= SUM(isnull(pvt_PartnerFeeCP.[Телемедицина], 0.00)), 
			[Телемедицина VAT]						= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Телемедицина]>0, 20, null)) as money), 
			[Защита от потери работы Commission]	= SUM(isnull(pvt_PartnerFeeCP.[Защита от потери работы], 0.00)),
			[Защита от потери работы VAT]			= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Защита от потери работы]>0, 20, null)) as money), 
			[Фарм страхование Commission]			= SUM(isnull(pvt_PartnerFeeCP.[Фарм страхование], 0.00)),
			[Фарм страхование VAT]					= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Фарм страхование]>0, 20, null)) as money), 
			[Спокойная жизнь Commission]			= SUM(isnull(pvt_PartnerFeeCP.[Спокойная жизнь], 0.00)),
			[Спокойная жизнь VAT]					= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Спокойная жизнь]>0, 20, null)) as money),

			[РАТ Юр. услуги Commission]				= SUM(isnull(pvt_PartnerFeeCP.[РАТ Юр. услуги], 0.00)), 
			[РАТ Юр. услуги VAT]					= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[РАТ Юр. услуги]>0, 20, null)) as money),

			[Право на медицинскую помощь Commission]= SUM(isnull(pvt_PartnerFeeCP.[Право на медицинскую помощь], 0.00)), 
			[Право на медицинскую помощь VAT]		= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Право на медицинскую помощь]>0, 20, null)) as money), 

			[ФАРМА-помощь Commission]				= SUM(isnull(pvt_PartnerFeeCP.[ФАРМА-помощь], 0.00)), 
			[ФАРМА-помощь VAT]						= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[ФАРМА-помощь]>0, 20, null)) as money), 

			[Автоспор Commission]					= SUM(isnull(pvt_PartnerFeeCP.[Автоспор], 0.00)), 
			[Автоспор VAT]							= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Автоспор]>0, 20, null)) as money),
			
			[Безопасность семьи Commission]			= SUM(isnull(pvt_PartnerFeeCP.[Безопасность семьи], 0.00)), 
			[Безопасность семьи VAT]				= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Безопасность семьи]>0, 20, null)) as money),

			[Защита жизни и здоровья Commission]	= SUM(isnull(pvt_PartnerFeeCP.[Безопасность семьи], 0.00)), 
			[Защита жизни и здоровья VAT]				= cast(min(iif(ДатаДоговора between VATAccountingFrom and VATAccountingTo
				and pvt_PartnerFeeCP.[Защита жизни и здоровья]>0, 20, null)) as money)

	   --,pfCp.*
	   
 
    from #v v
		left join (select  
			cp.ProductId,
			ProductName = cp.ProductName,
			Commission = isnull(cp.Commission,  cp.FixedСommission), 
			DateStart =  cast(cp.DateStart as date), 
			DateEnd  = cast(isnull(cp.DateEnd, getdate()) as date),
			VATAccountingFrom,
			VATAccountingTo	
			from stg._mds.hdbkPartnerFeeCP cp) cp on 
			--cp.ProductName = v.ДопПродукт
				cp.ProductId =stg.dbo.getGUIDFrom1C_IDRREF(v.ДополнительныйПродуктId)
			and v.ДатаДоговора between cp.DateStart and cp.DateEnd
	PIVOT (
		min(cp.Commission)
		FOR ProductName IN (
			[Спокойная жизнь],
			[Помощь бизнесу], 
			[Страхование жизни], 
			[РАТ], 
			[РАТ 2.0],
			[КАСКО], 
			[От потери работы. «Максимум»], 
			[От потери работы. «Стандарт»], 
			[Телемедицина], 
			[Защита от потери работы],
			[Фарм страхование],
			[РАТ Юр. услуги],
			[Право на медицинскую помощь],
			[ФАРМА-помощь],
			[Автоспор],
			[Безопасность семьи],
			[Защита жизни и здоровья]
		)
	) pvt_PartnerFeeCP
	group by Договор, Код  --ндс
	)
	--Расчет NET согласно BP-1478
	select 
		Договор
		,[Помощь бизнесу]		
		,[Помощь бизнесу_without_partner_bounty] 
		,[Помощь бизнесу VAT]
		,[Помощь бизнесу NET] = round(iif([Помощь бизнесу VAT] is not null,
			[Помощь бизнесу_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Помощь бизнесу_without_partner_bounty]  - ([Помощь бизнесу] - [Помощь бизнесу_without_partner_bounty] )*@koef_1_6)
			,2)

		,[Страхование жизни]		
		,[Страхование жизни_without_partner_bounty]
		,[Страхование жизни VAT]
		,[Страхование жизни NET]= round(iif([Страхование жизни VAT] is not null,
			[Страхование жизни_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Страхование жизни_without_partner_bounty] - ([Страхование жизни] - [Страхование жизни_without_partner_bounty])*@koef_1_6),2)
		,[РАТ]			
		,[РАТ_without_partner_bounty]
		,[РАТ VAT]
		,[РАТ NET] = round(iif([РАТ VAT] is not null,	
			[РАТ_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[РАТ_without_partner_bounty] - ([РАТ] - [РАТ_without_partner_bounty])*@koef_1_6),2)

		,[РАТ 2.0]
		,[РАТ 2.0_without_partner_bounty]
		,[РАТ 2.0 VAT]
		,[РАТ 2.0 NET] = round(iif([РАТ 2.0 VAT] is not null,	
			[РАТ 2.0_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[РАТ 2.0_without_partner_bounty] - ([РАТ 2.0] - [РАТ 2.0_without_partner_bounty])*@koef_1_6),2)

		,[КАСКО]			
		,[КАСКО_without_partner_bounty]
		,[КАСКО VAT]
		,[КАСКО NET] = round(iif([КАСКО VAT] is not null, 
			[КАСКО_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[КАСКО_without_partner_bounty] - ([КАСКО] - [КАСКО_without_partner_bounty])*@koef_1_6),2)
		,[От потери работы. «Максимум»]	
		,[От потери работы. «Максимум»_without_partner_bounty]
		,[От потери работы. «Максимум» VAT]
		,[От потери работы. «Максимум» NET] =  round(iif([От потери работы. «Максимум» VAT] is not null,
			[От потери работы. «Максимум»_without_partner_bounty] *@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[От потери работы. «Максимум»_without_partner_bounty] - ([От потери работы. «Максимум»] - [От потери работы. «Максимум»_without_partner_bounty])*@koef_1_6),2)
		,[От потери работы. «Стандарт»]	
		,[От потери работы. «Стандарт»_without_partner_bounty]
		,[От потери работы. «Стандарт» VAT]
		,[От потери работы. «Стандарт» NET] = round(iif([От потери работы. «Стандарт» VAT] is not null,
			[От потери работы. «Стандарт»_without_partner_bounty] * @koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[От потери работы. «Стандарт»_without_partner_bounty] - ([От потери работы. «Стандарт»] - [От потери работы. «Стандарт»_without_partner_bounty])*@koef_1_6),2)
		,[Телемедицина]			
		,Телемедицина_without_partner_bounty
		,[Телемедицина VAT]
		,[Телемедицина NET] = round(iif([Телемедицина VAT] is not null,
			Телемедицина_without_partner_bounty*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			Телемедицина_without_partner_bounty - ([Телемедицина] - Телемедицина_without_partner_bounty)*@koef_1_6),2)
		,[Защита от потери работы]	
		,[Защита от потери работы_without_partner_bounty]
		,[Защита от потери работы VAT] 
		,[Защита от потери работы NET] = round(iif([Защита от потери работы VAT] is not null,
			[Защита от потери работы_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Защита от потери работы_without_partner_bounty] - ([Защита от потери работы] - [Защита от потери работы_without_partner_bounty])*@koef_1_6),2)
		,[Фарм страхование]	
		,[Фарм страхование_without_partner_bounty]
		,[Фарм страхование VAT]
		,[Фарм страхование NET] = round(iif([Фарм страхование VAT] is not null,
			[Фарм страхование_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Фарм страхование_without_partner_bounty] - ([Фарм страхование] - [Фарм страхование_without_partner_bounty])*@koef_1_6),2)
		,[Спокойная жизнь]
		,[Спокойная жизнь_without_partner_bounty]
		,[Спокойная жизнь VAT]
		,[Спокойная жизнь NET] = round(iif([Спокойная жизнь VAT] is not null,
			[Спокойная жизнь_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Спокойная жизнь_without_partner_bounty] - ([Спокойная жизнь] - [Спокойная жизнь_without_partner_bounty])*@koef_1_6),2)

		,[РАТ Юр. услуги]
		,[РАТ Юр. услуги_without_partner_bounty]
		,[РАТ Юр. услуги VAT]
		,[РАТ Юр. услуги NET] = round(iif([РАТ Юр. услуги VAT] is not null,	
			[РАТ Юр. услуги_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[РАТ Юр. услуги_without_partner_bounty] - ([РАТ Юр. услуги] - [РАТ Юр. услуги_without_partner_bounty])*@koef_1_6),2)

		,[ЗАЩИТА ЗДОРОВЬЯ] = [ЗАЩИТА ЗДОРОВЬЯ]
		,[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty]
		,[ЗАЩИТА ЗДОРОВЬЯ VAT]
		,[ЗАЩИТА ЗДОРОВЬЯ NET] = round(iif([ЗАЩИТА ЗДОРОВЬЯ VAT] is not null,
			[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty] - ([ЗАЩИТА ЗДОРОВЬЯ] - [ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty])*@koef_1_6),2)

		,[ФАРМА-помощь]
		,[ФАРМА-помощь_without_partner_bounty]
		,[ФАРМА-помощь VAT]
		,[ФАРМА-помощь NET] = round(iif([ФАРМА-помощь VAT] is not null,
			[ФАРМА-помощь_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[ФАРМА-помощь_without_partner_bounty] - ([ФАРМА-помощь] - [ФАРМА-помощь_without_partner_bounty])*@koef_1_6),2)

		,[Автоспор]
		,[Автоспор_without_partner_bounty]
		,[Автоспор VAT]
		,[Автоспор NET] = round(iif([Автоспор VAT] is not null,
			[Автоспор_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Автоспор_without_partner_bounty] - ([Автоспор] - [Автоспор_without_partner_bounty])*@koef_1_6),2)

		,[Безопасность семьи]
		,[Безопасность семьи_without_partner_bounty]
		,[Безопасность семьи VAT]
		,[Безопасность семьи NET] = round(iif([Безопасность семьи VAT] is not null,
			[Безопасность семьи_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Безопасность семьи_without_partner_bounty] - ([Безопасность семьи] - [Безопасность семьи_without_partner_bounty])*@koef_1_6),2) 

		,[Защита жизни и здоровья]
		,[Защита жизни и здоровья_without_partner_bounty]
		,[Защита жизни и здоровья VAT]
		,[Защита жизни и здоровья NET] = round(iif([Защита жизни и здоровья VAT] is not null,
			[Защита жизни и здоровья_without_partner_bounty]*@koef_5_6, -- (1.0-20.0/(100.0 + 20.0)),
			[Защита жизни и здоровья_without_partner_bounty] - ([Защита жизни и здоровья] - [Защита жизни и здоровья_without_partner_bounty])*@koef_1_6),2)


	into #ensurance
	from (
	select
		допПродукт.Договор
		,допПродукт.[Помощь бизнесу]		
		,[Помощь бизнесу_without_partner_bounty] = cast (допПродукт.[Помощь бизнесу] * (1.0-PartnerFeeCP.[Помощь бизнесу Commission]/100.0) as money)
		,[Помощь бизнесу VAT]
		,допПродукт.[Страхование жизни]		
		,[Страхование жизни_without_partner_bounty] = cast(допПродукт.[Страхование жизни] * (1.0- PartnerFeeCP.[Страхование жизни Commission]/100.0) as money) 
		,[Страхование жизни VAT]
		,допПродукт.[РАТ]			
		,[РАТ_without_partner_bounty] = cast(допПродукт.[РАТ] * (1.0-PartnerFeeCP.[РАТ Commission]/100.0) as money)
		,[РАТ VAT]

		,допПродукт.[РАТ 2.0]
		,[РАТ 2.0_without_partner_bounty] = cast(допПродукт.[РАТ 2.0] * (1.0-PartnerFeeCP.[РАТ 2.0 Commission]/100.0) as money)
		,[РАТ 2.0 VAT]

		,допПродукт.[КАСКО]			
		,[КАСКО_without_partner_bounty] = cast(допПродукт.[КАСКО] * (1.0-PartnerFeeCP.[КАСКО Commission]/100.0) as money) 
		,[КАСКО VAT]
		,допПродукт.[От потери работы. «Максимум»]	
		,[От потери работы. «Максимум»_without_partner_bounty] = cast(допПродукт.[От потери работы. «Максимум»] * (1.0-PartnerFeeCP.[От потери работы. «Максимум» Commission]/100.0) as money) 
		,[От потери работы. «Максимум» VAT]

		,допПродукт.[От потери работы. «Стандарт»]	
		,[От потери работы. «Стандарт»_without_partner_bounty] = cast(допПродукт.[От потери работы. «Стандарт»]	* (1.0-PartnerFeeCP.[От потери работы. «Стандарт» Commission]/100.0) as money) 
		,[От потери работы. «Стандарт» VAT]

		,допПродукт.[Телемедицина]			
		,Телемедицина_without_partner_bounty = cast(допПродукт.[Телемедицина] * (1.0 - PartnerFeeCP.[Телемедицина Commission]/100.0) as money) 
		,[Телемедицина VAT]

		,допПродукт.[Защита от потери работы]	
		,[Защита от потери работы_without_partner_bounty]= cast(допПродукт.[Защита от потери работы] * (1.0-PartnerFeeCP.[Защита от потери работы Commission]/100.0) as money) 
		,[Защита от потери работы VAT]
		
		,допПродукт.[Фарм страхование]	
		,[Фарм страхование_without_partner_bounty] =cast(допПродукт.[Фарм страхование] * (1.0-PartnerFeeCP.[Фарм страхование Commission]/100.0) as money)
		,[Фарм страхование VAT]
		
		,допПродукт.[Спокойная жизнь]
		,[Спокойная жизнь_without_partner_bounty] =допПродукт.[Спокойная жизнь] - PartnerFeeCP.[Спокойная жизнь Commission]
		,[Спокойная жизнь VAT]
	
		,допПродукт.[РАТ Юр. услуги]
		,[РАТ Юр. услуги_without_partner_bounty] = cast(допПродукт.[РАТ Юр. услуги] * (1.0-PartnerFeeCP.[РАТ Юр. услуги Commission]/100.0) as money)
		,[РАТ Юр. услуги VAT]

		,[ЗАЩИТА ЗДОРОВЬЯ] = допПродукт.[Право на медицинскую помощь]
		,[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty] = cast(допПродукт.[Право на медицинскую помощь] * (1.0- PartnerFeeCP.[Право на медицинскую помощь Commission]/100.0) as money) 
		,[ЗАЩИТА ЗДОРОВЬЯ VAT] = PartnerFeeCP.[Право на медицинскую помощь VAT]

		,допПродукт.[ФАРМА-помощь]
		,[ФАРМА-помощь_without_partner_bounty] = cast(допПродукт.[ФАРМА-помощь] * (1.0- PartnerFeeCP.[ФАРМА-помощь Commission]/100.0) as money) 
		,[ФАРМА-помощь VAT]

		,допПродукт.[Автоспор]
		,[Автоспор_without_partner_bounty] = cast(допПродукт.[Автоспор] * (1.0- PartnerFeeCP.[Автоспор Commission]/100.0) as money) 
		,[Автоспор VAT]

		,допПродукт.[Безопасность семьи]
		,[Безопасность семьи_without_partner_bounty] = cast(допПродукт.[Безопасность семьи] * (1.0- PartnerFeeCP.[Безопасность семьи Commission]/100.0) as money) 
		,[Безопасность семьи VAT]

		,допПродукт.[Защита жизни и здоровья]
		,[Защита жизни и здоровья_without_partner_bounty] = cast(допПродукт.[Защита жизни и здоровья] * (1.0- PartnerFeeCP.[Защита жизни и здоровья Commission]/100.0) as money) 
		,[Защита жизни и здоровья VAT]

	from cte_допПродукт  допПродукт
	inner join 	cte_PartnerFeeCP PartnerFeeCP on PartnerFeeCP.Договор = допПродукт.Договор
	) t


   drop table if exists #result
   ;
   with d as ( 
    select distinct ДатаВыдачи
         , Дата=dateadd(year,-2000,Дата)
         , Код
         , Сумма
         , Договор
         , ПроцентнаяСтавка
         , СтавкаНаСумму
		 , IsInstallment
		 , ТипПродукта	
		 , ТипПродукта_Код
      from #v 
   )
   select ДатаВыдачи
        , d.Дата
        , d.Код
        , d.Сумма
        , d.Договор
        , d.ПроцентнаяСтавка 
        , d.СтавкаНаСумму
        , e.[Помощь бизнесу]
		, e.[Помощь бизнесу_without_partner_bounty]
		, e.[Помощь бизнесу NET]
        , e.[Страхование жизни]
		, e.[Страхование жизни_without_partner_bounty]
		, e.[Страхование жизни NET]
        , e.РАТ
		, e.РАТ_without_partner_bounty
		, e.[РАТ NET]

        , e.[РАТ 2.0]
		, e.[РАТ 2.0_without_partner_bounty]
		, e.[РАТ 2.0 NET]

        , e.КАСКО
		, e.КАСКО_without_partner_bounty
		, e.[КАСКО NET]
        , e.[От потери работы. «Максимум»]
		, e.[От потери работы. «Максимум»_without_partner_bounty]
		, e.[От потери работы. «Максимум» NET]
        , e.[От потери работы. «Стандарт»]
		, e.[От потери работы. «Стандарт»_without_partner_bounty]
		, e.[От потери работы. «Стандарт» NET]
        , e.Телемедицина
		, e.Телемедицина_without_partner_bounty
		, e.[Телемедицина NET]
        , [Защита от потери работы] = isnull(e.[Защита от потери работы],0) 
		, [Защита от потери работы_without_partner_bounty] = isnull(e.[Защита от потери работы_without_partner_bounty],0) 
		, e.[Защита от потери работы NET]
        , [Фарм страхование] = isnull(e.[Фарм страхование],0) 
    	, [Фарм страхование_without_partner_bounty] = isnull(e.[Фарм страхование_without_partner_bounty],0) 
		, [Фарм страхование NET]
		, [Спокойная жизнь]	= isnull(e.[Спокойная жизнь], 0)
		, [Спокойная жизнь_without_partner_bounty] = isnull(e.[Спокойная жизнь_without_partner_bounty],0)
		, e.[Спокойная жизнь NET]
    
		, [РАТ Юр. услуги]	= isnull(e.[РАТ Юр. услуги], 0)
		, [РАТ Юр. услуги_without_partner_bounty] = isnull(e.[РАТ Юр. услуги_without_partner_bounty],0)
		, e.[РАТ Юр. услуги NET]

        , e.[ЗАЩИТА ЗДОРОВЬЯ]
		, e.[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty]
		, e.[ЗАЩИТА ЗДОРОВЬЯ NET]

        , e.[ФАРМА-помощь]
		, e.[ФАРМА-помощь_without_partner_bounty]
		, e.[ФАРМА-помощь NET]

        , e.[Автоспор]
		, e.[Автоспор_without_partner_bounty]
		, e.[Автоспор NET]
		, e.[Безопасность семьи]
		, e.[Безопасность семьи_without_partner_bounty]
		, e.[Безопасность семьи NET]

		, e.[Защита жизни и здоровья]
		, e.[Защита жизни и здоровья_without_partner_bounty]
		, e.[Защита жизни и здоровья NET]



        , r.СпособОформления
        , s.lastStatus
        , f.[Вид заполнения]
        , channel_B=case when  [Вид заполнения]='Заполняется в мобильном приложении' then 'Дистанс'
                         else case when r.СпособОформления='Оформление на партнерском сайте' then 'Партнеры' 
                                   else 'Прямые продажи'
                               end
                    end
		,Канал  = isnull(case 
				when r.СпособОформления = 'Оформление на партнерском сайте' 
					then 'Партнеры'      
				when st.[Группа каналов] = 'cpa' 
					then st.[Канал от источника] 
				else st.[Группа каналов] end      , 'unknown' ) 
		,d.IsInstallment
		,[Вид займа] = isnull(rt.return_type, 'Первичный')
		,d.ТипПродукта	
		,d.ТипПродукта_Код
        --, getdate() created
     into #result
     from #ensurance e
     join d on d.Договор=e.Договор
  
  left join #CRMRequests r on r.external_id =d.Код 
  left join #CmrStatuses s on s.external_id=d.Код
  left join #RequestFilling f on f.[Номер заявки]=d.Код
  --BP-1541
  left join (
	select uf_row_id, max(id) as lead_id 
		from stg.[_LCRM].lcrm_leads_full_channel_request
		st  
	group by uf_row_id
  ) last_lead on last_lead.UF_ROW_ID = d.Код
  left join stg.[_LCRM].lcrm_leads_full_channel_request st  
	on st.ID = last_lead.lead_id
	and st.UF_ROW_ID = d.Код
--BP-2147
  left join #t_return_type rt on rt.код = d.Код 


  delete from dbo.dm_Sales_stage where код='20032210000015'
 

 if exists (select top(1) 1 from #result)
 begin
	--1 tran. delete/insert dbo.dm_Sales_stage
	begin  tran
		delete  dbo.dm_Sales_stage 
		where ДатаВыдачи>=@saleDateFrom and датаВыдачи<@saleDateTo
		insert into  dbo.dm_Sales_stage
		  (
		  [ДатаВыдачи]
			  ,[Дата]
			  ,[ДатаВремя]
			  ,[CMRДоговор]
			  ,[Код]
			  ,[Сумма]
			  ,[ПроцентнаяСтавка]
			  ,[СтавкаНаСумму]
			  ,[Помощь бизнесу]
			  ,[Страхование жизни]
			  ,[РАТ]
			  ,[КАСКО]
			  ,[От потери работы. «Максимум»]
			  ,[От потери работы. «Стандарт»]
			  ,[телемедицина]
			  ,[СпособОформления]
			  ,[lastStatus]
			  ,[Вид заполнения]
			  ,[channel_B]
			  ,[created]
			  ,[ishistory]
			  ,[updated]
			  ,[Защита от потери работы]
			  ,[Помощь бизнесу_without_partner_bounty]
			  ,[Страхование жизни_without_partner_bounty]
			  ,[РАТ_without_partner_bounty]
			  ,[КАСКО_without_partner_bounty]
			  ,[От потери работы. «Максимум»_without_partner_bounty]
			  ,[От потери работы. «Стандарт»_without_partner_bounty]
			  ,[Телемедицина_without_partner_bounty]
			  ,[Защита от потери работы_without_partner_bounty]
			  ,[Фарм страхование]
			  ,[Фарм страхование_without_partner_bounty]
			  ,[Спокойная жизнь]
			  ,[Спокойная жизнь_without_partner_bounty]
			  ,[Помощь бизнесу NET]				
			  ,[Страхование жизни NET] 			
			  ,[РАТ NET]							
			  ,[КАСКО NET]							
			  ,[От потери работы. «Максимум» NET]	
			  ,[От потери работы. «Стандарт» NET]	
			  ,[Телемедицина NET]					
			  ,[Защита от потери работы NET]		
			  ,[Фарм страхование NET]				
			  ,[Спокойная жизнь NET]				
			  ,[Канал]
			  ,IsInstallment
			  ,[Вид займа]
			  --
			  ,[РАТ 2.0]
			  ,[РАТ 2.0_without_partner_bounty]
			  ,[РАТ 2.0 NET]

			  ,[РАТ Юр. услуги]
			  ,[РАТ Юр. услуги_without_partner_bounty]
			  ,[РАТ Юр. услуги NET]

				,[ЗАЩИТА ЗДОРОВЬЯ]
				,[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty]
				,[ЗАЩИТА ЗДОРОВЬЯ NET]

				,[ФАРМА-помощь]
				,[ФАРМА-помощь_without_partner_bounty]
				,[ФАРМА-помощь NET]

				,[Автоспор]
				,[Автоспор_without_partner_bounty]
				,[Автоспор NET]
				,[Безопасность семьи]
				,[Безопасность семьи_without_partner_bounty]
				,[Безопасность семьи NET]
				,ТипПродукта	
				,ТипПродукта_Код
				,[Защита жизни и здоровья]
				,[Защита жизни и здоровья_without_partner_bounty]
				,[Защита жизни и здоровья NET]
				
		  )
	  select distinct ДатаВыдачи
			, Дата=cast(r.Дата as date)
			, r.Дата ДатаВремя
			, r.Договор CMRДоговор
			, r.Код
			, Сумма												= isnull(r.Сумма,0.0)
			, ПроцентнаяСтавка									=isnull(r.ПроцентнаяСтавка              ,0.0)
			, СтавкаНаСумму										=isnull(r.СтавкаНаСумму                 ,0.0)
			, [Помощь бизнесу]									=isnull(r.[Помощь бизнесу]              ,0.0)
			, [Страхование жизни]								=isnull(r.[Страхование жизни]           ,0.0)
			, РАТ												=isnull(r.РАТ                           ,0.0)
			, КАСКО												=isnull(r.КАСКО                         ,0.0)
			, [От потери работы. «Максимум»]					=isnull(r.[От потери работы. «Максимум»],0.0)
			, [От потери работы. «Стандарт»]					=isnull(r.[От потери работы. «Стандарт»],0.0)
			, телемедицина										=isnull(r.телемедицина                  ,0.0)
			, r.СпособОформления
			, r.lastStatus
			, r.[Вид заполнения]
			, r.channel_B
			, created=getdate() 
			, ishistory=0
			, updated=getdate()
			, [Защита от потери работы]							= isnull(r.[Защита от потери работы],0)
			, [Помощь бизнесу_without_partner_bounty]			= isnull(r.[Помощь бизнесу_without_partner_bounty],0)
			, [Страхование жизни_without_partner_bounty]		= isnull(r.[Страхование жизни_without_partner_bounty],0)
			, [РАТ_without_partner_bounty]						= isnull(r.[РАТ_without_partner_bounty],0)
			, [КАСКО_without_partner_bounty]					= isnull(r.[КАСКО_without_partner_bounty],0)
			, [От потери работы. «Максимум»_without_partner_bounty] = isnull(r.[От потери работы. «Максимум»_without_partner_bounty],0)
			, [От потери работы. «Стандарт»_without_partner_bounty] = isnull(r.[От потери работы. «Стандарт»_without_partner_bounty],0)
			, [Телемедицина_without_partner_bounty]				= isnull(r.[Телемедицина_without_partner_bounty],0)
			, [Защита от потери работы_without_partner_bounty]	= isnull(r.[Защита от потери работы_without_partner_bounty],0)
			, [Фарм страхование]								= isnull(r.[Фарм страхование]               ,0.0)
			, [Фарм страхование_without_partner_bounty]			= isnull(r.[Фарм страхование_without_partner_bounty],0)
			, [Спокойная жизнь]									= isnull(r.[Спокойная жизнь],0)
			, [Спокойная жизнь_without_partner_bounty]			= isnull(r.[Спокойная жизнь_without_partner_bounty],0)
			, [Помощь бизнесу NET]								= isnull(r.[Помощь бизнесу NET]					,0)
			, [Страхование жизни NET]							= isnull(r.[Страхование жизни NET] 				,0)
			, [РАТ NET]											= isnull(r.[РАТ NET]							,0)
			, [КАСКО NET]										= isnull(r.[КАСКО NET]							,0)
			, [От потери работы. «Максимум» NET]				= isnull(r.[От потери работы. «Максимум» NET]	,0)
			, [От потери работы. «Стандарт» NET]				= isnull(r.[От потери работы. «Стандарт» NET]	,0)
			, [Телемедицина NET]								= isnull(r.[Телемедицина NET]					,0)
			, [Защита от потери работы NET]						= isnull(r.[Защита от потери работы NET]		,0)
			, [Фарм страхование NET]							= isnull(r.[Фарм страхование NET]				,0)
			, [Спокойная жизнь NET]								= isnull(r.[Спокойная жизнь NET]				,0)
			, Канал = isnull(r.Канал, 'unknown')
			, r.IsInstallment
			, r.[Вид займа]
			,[РАТ 2.0]											= isnull(r.[РАТ 2.0], 0.0)
			,[РАТ 2.0_without_partner_bounty]					= isnull(r.[РАТ 2.0_without_partner_bounty], 0)
			,[РАТ 2.0 NET]										= isnull(r.[РАТ 2.0 NET], 0)

			,[РАТ Юр. услуги]									= isnull(r.[РАТ Юр. услуги], 0.0)
			,[РАТ Юр. услуги_without_partner_bounty]			= isnull(r.[РАТ Юр. услуги_without_partner_bounty], 0)
			,[РАТ Юр. услуги NET]								= isnull(r.[РАТ Юр. услуги NET], 0)

			,[ЗАЩИТА ЗДОРОВЬЯ]									= isnull(r.[ЗАЩИТА ЗДОРОВЬЯ], 0.0)
			,[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty]			= isnull(r.[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty], 0.0)
			,[ЗАЩИТА ЗДОРОВЬЯ NET]								= isnull(r.[ЗАЩИТА ЗДОРОВЬЯ NET], 0.0)

			,[ФАРМА-помощь]										= isnull(r.[ФАРМА-помощь], 0.0)
			,[ФАРМА-помощь_without_partner_bounty]				= isnull(r.[ФАРМА-помощь_without_partner_bounty], 0.0)
			,[ФАРМА-помощь NET]									= isnull(r.[ФАРМА-помощь NET], 0.0)

			,[Автоспор]											= isnull(r.[Автоспор], 0.0)
			,[Автоспор_without_partner_bounty]					= isnull(r.[Автоспор_without_partner_bounty], 0.0)
			,[Автоспор NET]										= isnull(r.[Автоспор NET], 0.0)
			,[Безопасность семьи]								= isnull([Безопасность семьи],0)
			,[Безопасность семьи_without_partner_bounty]		= isnull([Безопасность семьи_without_partner_bounty],0)
			,[Безопасность семьи NET]							= isnull([Безопасность семьи NET],0)
			,ТипПродукта	
			,ТипПродукта_Код
			,[Защита жизни и здоровья]							= isnull([Защита жизни и здоровья]							,0)				
			,[Защита жизни и здоровья_without_partner_bounty]	= isnull([Защита жизни и здоровья_without_partner_bounty]	,0)
			,[Защита жизни и здоровья NET]						= isnull([Защита жизни и здоровья NET]						,0)
	   -- ito dbo.dm_Sales
		from #result r 
		where lastStatus<>'Аннулирован'
	commit tran


		declare @partitionId int

		declare cur_partition cursor for select partitionID from #partitions
		
		OPEN cur_partition  

		FETCH NEXT FROM cur_partition   
		INTO @partitionId

	--2 tran. SWITCH PARTITION @partitionId TO dbo.dm_Sales
	begin  tran

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			if exists(select top(1) 1 from dbo.dm_Sales_stage
			where  $partition.[pfn_range_right_date_part_dm_Sales]([ДатаВыдачи]) = @partitionId)
			begin
				
				truncate table dbo.dm_Sales  WITH (PARTITIONS(@partitionId))
				alter table dbo.dm_Sales_stage
					SWITCH PARTITION @partitionId TO dbo.dm_Sales  PARTITION @partitionId
					WITH (WAIT_AT_LOW_PRIORITY ( MAX_DURATION = 1,
					ABORT_AFTER_WAIT = BLOCKERS))
			end
			else
			begin
				print concat('not exists data in dm_Sales_stage for partition:', @partitionId)
			end

			FETCH NEXT FROM cur_partition   
			INTO @partitionId
		END

		CLOSE cur_partition;  
		DEALLOCATE cur_partition; 
	
	commit tran
end
  -------- Добавим Бизнес займы
  drop table if exists #BusinessLoan_UMFO
  select cast(dateadd(year,-2000,dd.[Дата]) as date) ДатаВыдачи
	     , dd.НомерДоговора
	     , dd.ФинансовыйПродукт
	     , fp.[Наименование] as [КредитныйПродукт]
	     , dd.СуммаЗайма
	     , dd.ПроцентнаяСтавка
	     , dd.СрокЗайма
	     , (dd.[СуммаЗайма] * dd.[ПроцентнаяСтавка]) СтавкаНаСумму
       , created=getdate() 
       , ishistory=0
       , updated=getdate()
    into #BusinessLoan_UMFO
    from stg._1cUMFO.[Документ_АЭ_ЗаймПредоставленный] dd  with (nolock)--y
    left join stg._1cUMFO.[Справочник_АЭ_ФинансовыеПродукты] fp  with (nolock) on dd.[ФинансовыйПродукт]=fp.[Ссылка]
   where dd.Дата>=@dFrom and dd.Дата<@dTo and  
   dd.[ПометкаУдаления]=0x00 AND dd.[Проведен]=0x01 and fp.[Родитель] = 0x810800155D01C00511E86A1E934E0BAE 
  	AND dd.[ДополнительноеСоглашение]=0x00 --DWH-1693
	begin tran
  delete from dbo.dm_SalesBusiness
	where ДатаВыдачи>=@saleDateFrom and датаВыдачи<@saleDateTo
  
  insert into dbo.dm_SalesBusiness
  select * from #BusinessLoan_UMFO where len(НомерДоговора)>8 
  commit tran 
-------- P2P
  drop table if exists #P2P

  select cast(t.created_at as date) ДатаВыдачи
       , t.created_at as ДатаВремя
       , r.number 
       , N'P2P займ' as [КредитныйПродукт]
       , t.sum  as [СуммаЗайма]
       , r.interest_rate as [ПроцентнаяСтавка]
       , r.loan_period  as [СрокЗайма] 
        , (r.[sum_contract] * r.[interest_rate]) [СтавкаНаСумму]
       , created=getdate() 
       , ishistory=0
       , updated=getdate()
    into #P2P
    from [stg].[_p2p].[transactions]  t
    join [stg].[_p2p].requests r on  t.request_guid = r.guid
   where t.provider_transaction_type_guid = '3b3a814c-7f7a-4b60-97d9-30000cc86142' and t.transaction_status_guid = 'a6ff88d0-2bc5-11ea-adb8-0242ac130004'
  -- order by t.created_at ASC

 begin tran
	  delete from dbo.dm_SalesP2P 
		where ДатаВыдачи>=@saleDateFrom and датаВыдачи<@saleDateTo
  

	 insert into dbo.dm_SalesP2P
	  select * 
	--    into dbo.dm_SalesP2P 
		from #P2P where ДатаВыдачи>=@saleDateFrom and датаВыдачи<@saleDateTo
	commit tran
 -- Строим дашборды
 --

 -- Дашбод для SSRS

 -- Планы c начала текущего месяца
  drop table if exists #plans
    select * 
      into #plans
	    from [Stg].[files].[CC_DailyPlans]
     where дата>=cast(format(cast(getdate() as date),'yyyyMM01') as date)


  declare @kp money
  select  @kp=sum([План КП]) from #plans
  --select  @kp

  --2020_09_07 найдем за день КП сумму плана для этого посчитаем количество дней в месяце
  declare @days_month int  
  declare @mydate datetime = getdate()
  select @days_month =  DAY(DATEADD(day, -1, DATEADD(month, DATEDIFF(month,
	'20000101', @mydate)+1, '20000101')))

  set datefirst 1;
  drop table if exists #periods
  create table #periods (name nvarchar(100),pFrom date,pTo date)
  insert into #periods
  select periodName, dateBegin, dateEnd  from dbo.tvf_GetPeriod(getdate())

  

-- 2020_09_07
-- найдем с пэп3
-- для ПЭП3
drop table if exists #tpep3
select 
z.Код as КодПЭП3, count(1) cnt, Период = cast(dateadd(year,-2000, Период) as date)
into #tpep3 
from [Stg].[_1cCRM].[РегистрСведений_СогласияНаЭлектронноеВзаимодействие] e
left join [Stg].[_1cCMR].[Справочник_Заявка] z on z.[Ссылка]=e.[ЗаявкаОснование]
left join [Stg].[_1cCRM].[Справочник_ВидыСогласий] s on s.[Ссылка] = e.[ВидСогласия]
left join [Stg].[_1cCRM].[Справочник_Офисы] o on z.Точка = o.Ссылка
where o.Код=2991 and s.Наименование = N'Полная'
group by z.Код, cast(dateadd(year,-2000, Период) as date)


--
-- bp-1385
--
  drop table if exists #pts31

  SELECT d.Код  as КодПТС31
    into #pts31
    FROM [Stg].[_1cCMR].[Справочник_Договоры] d 
    join [Stg].[_1cCMR].[Справочник_Заявка] z on d.Заявка=z.Ссылка
   where z.ИспытательныйСрок<>0x0




--select * from #tpep3

--select * from #periods


	drop table if exists #t_result
	select top(0)
	* 
	into #t_result
	from dbo.dm_SalesDashboard
	

declare @name nvarchar(100),@pFrom date,@pTo date

while (select count(*) from #periods)>0
begin
select  @name=name,@pFrom =pFrom,@pTo=pTo From #periods
	;with dashboard as (
-- продажи с начала месяца
	select [period]=@name
       , channel_B
      -- , ДатаВыдачи
    
       , [Количество выдач]=count(*)
       , [Сумма выдач] = sum(сумма) 
       , [Средний чек]= case when count(*)>0 then sum(сумма) /count(*) else 0.0 end
       , [Доля КП]=100*case 
							when sum(сумма)<>0 
								then  sum(
										[Помощь бизнесу] + 
										[Страхование жизни] + 
										РАТ + 
										[РАТ 2.0] + 
										КАСКО + 
										[От потери работы. «Максимум»] + 
										[От потери работы. «Стандарт»]+
										[Телемедицина]+
										[Защита от потери работы] +
										[Фарм страхование] + 
										[Спокойная жизнь] +
										[РАТ Юр. услуги] +
										[ЗАЩИТА ЗДОРОВЬЯ] +
										[ФАРМА-помощь] +
										[Автоспор]
									) / sum(сумма)  
							else 0.0 
					   end
       , СредневзвешеннаяСтавка = case when sum(сумма)<>0 then sum(СтавкаНаСумму)/sum(сумма) else 0.0 end

       , [ВСЕГО КП] = sum(case 
							when [Помощь бизнесу]=0.0 and [Страхование жизни]=0.0 and РАТ=0.0 and [РАТ 2.0]=0.0 AND КАСКО=0.0 
									and [От потери работы. «Максимум»]=0.0 and [От потери работы. «Стандарт»] =0.0 
									and [Телемедицина]=0.0 and [Защита от потери работы]=0.0 and [Фарм страхование]=0.0
									and [Спокойная жизнь] = 0.0
									AND [РАТ Юр. услуги] = 0.0
									AND [ЗАЩИТА ЗДОРОВЬЯ] = 0.0
									AND [ФАРМА-помощь] = 0.0
									AND [Автоспор] = 0.0
								then 0 
							else 1 
						  end
						  )
       , [СУММА КП] = sum(
				isnull([Помощь бизнесу]					,0)
				+ isnull([Страхование жизни]			,0)
				+ isnull(РАТ							,0)
				+ isnull([РАТ 2.0]						,0)
				+ isnull(КАСКО							,0)
				+ isnull([От потери работы. «Максимум»] ,0)
				+ isnull([От потери работы. «Стандарт»] ,0)
				+ isnull([Телемедицина]					,0)
				+ isnull([Защита от потери работы]		,0)
				+ isnull([Фарм страхование]				,0)
				+ isnull([Спокойная жизнь]				,0)
				+ isnull([РАТ Юр. услуги]				,0)
				+ isnull([ЗАЩИТА ЗДОРОВЬЯ]				,0)
				+ isnull([ФАРМА-помощь]					,0)
				+ isnull([Автоспор]						,0)
			)
	   , [СУММА КП_without_partner_bounty] = sum(
			 isnull(s.[Помощь бизнесу_without_partner_bounty]				,0)
			+isnull(s.[Страхование жизни_without_partner_bounty]			,0)
			+isnull(s.[РАТ_without_partner_bounty]							,0)
			+isnull(s.[РАТ 2.0_without_partner_bounty]						,0)
			+isnull(s.[КАСКО_without_partner_bounty]						,0)
			+isnull(s.[От потери работы. «Максимум»_without_partner_bounty]	,0)
			+isnull(s.[От потери работы. «Стандарт»_without_partner_bounty]	,0)
			+isnull(s.[Телемедицина_without_partner_bounty]					,0)
			+isnull(s.[Защита от потери работы_without_partner_bounty]		,0)
			+isnull(s.[Фарм страхование_without_partner_bounty]				,0)
			+isnull(s.[Спокойная жизнь_without_partner_bounty]				,0)
			+isnull(s.[РАТ Юр. услуги_without_partner_bounty]				,0)

			+isnull(s.[ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty]				,0)
			+isnull(s.[ФАРМА-помощь_without_partner_bounty]					,0)
			+isnull(s.[Автоспор_without_partner_bounty]						,0)
		)
		, [СУММА КП_without_partner_bounty_net] = SUM(
			+isnull(s.[Помощь бизнесу NET]				,0)
			+isnull(s.[Страхование жизни NET]			,0)
			+isnull(s.[РАТ NET]							,0)
			+isnull(s.[РАТ 2.0 NET]						,0)
			+isnull(s.[КАСКО NET]						,0)
			+isnull(s.[От потери работы. «Максимум» NET],0)
			+isnull(s.[От потери работы. «Стандарт» NET],0)
			+isnull(s.[Телемедицина NET]				,0)
			+isnull(s.[Защита от потери работы NET]		,0)
			+isnull(s.[Фарм страхование NET]			,0)
			+isnull(s.[Спокойная жизнь NET]				,0)
			+isnull(s.[РАТ Юр. услуги NET]				,0)

			+isnull(s.[ЗАЩИТА ЗДОРОВЬЯ NET]				,0)
			+isnull(s.[ФАРМА-помощь NET]				,0)
			+isnull(s.[Автоспор NET]					,0)
			)

 
       , [КОЛИЧЕСТВО РАТ]					=sum(case when  РАТ=0.0  then 0 else 1 end)
       , [СУММА РАТ]						= sum(РАТ)

       , [КОЛИЧЕСТВО РАТ 2.0]				=sum(case when  [РАТ 2.0]=0.0  then 0 else 1 end)
       , [СУММА РАТ 2.0]					= sum([РАТ 2.0])

       , [Количество Помощь бизнесу]		= sum(case when [Помощь бизнесу]=0.0  then 0 else 1 end)
       , [Сумма Помощь бизнесу]				= sum([Помощь бизнесу])
       
       , [Количество Страхование жизни]		= sum(case when [Страхование жизни]=0.0  then 0 else 1 end)
       , [Сумма Страхование жизни]			= sum([Страхование жизни])
     
       , [Количество КАСКО]					= sum(case when [КАСКО]=0.0  then 0 else 1 end)
       , [Сумма КАСКО]						= sum([КАСКО])
       
       , [Количество От потери работы]		= sum(case when [От потери работы. «Максимум»]=0.0 and [От потери работы. «Стандарт»] =0.0   then 0 else 1 end)
       , [Сумма От потери работы]			= sum([От потери работы. «Максимум»] + [От потери работы. «Стандарт»])

       , [Количество Телемедицина]			= sum(case when [Телемедицина]=0.0  then 0 else 1 end)
       , [Сумма Телемедицина]				= sum([Телемедицина])

       , [Количество Защита от потери работы] = sum(case when isnull([Защита от потери работы],0)=0.0  then 0 else 1 end)
       , [Сумма Защита от потери работы]	= sum(isnull([Защита от потери работы],0))       
       , [Количество Фарм страхование]		= sum(case when isnull([Фарм страхование],0)=0.0  then 0 else 1 end)
       , [Сумма Фарм страхование]			= sum(isnull([Фарм страхование],0))       
	   , [Количество ПЭП3]					= sum(iif(КодПЭП3 is not null, 1,0))
	   , [Сумма ПЭП3]						= sum(iif(КодПЭП3 is not null, сумма,0.0))

	   , [Количество ПТС31]					= sum(iif(КодПТС31 is not null, 1,0))
	   , [Сумма ПТС31]						= sum(iif(КодПТС31 is not null, сумма,0.0))
	   , [Количество Спокойная жизнь]		= sum(case when isnull([Спокойная жизнь],0)=0.0  then 0 else 1 end)
       , [Сумма Спокойная жизнь]			= sum(isnull([Спокойная жизнь],0))    
	   , [Помощь бизнесу NET]				= sum(isnull([Помощь бизнесу NET]				 ,0))	
	   , [Страхование жизни NET]			= sum(isnull([Страхование жизни NET]			 ,0))
	   , [РАТ NET]							= sum(isnull([РАТ NET]							 ,0))
	   , [РАТ 2.0 NET]						= sum(isnull([РАТ 2.0 NET]						 ,0))
	   , [КАСКО NET]						= sum(isnull([КАСКО NET]						 ,0))
	   , [От потери работы. «Максимум» NET] = sum(isnull([От потери работы. «Максимум» NET]  ,0))
	   , [От потери работы. «Стандарт» NET]	= sum(isnull([От потери работы. «Стандарт» NET]	 ,0))
	   , [Телемедицина NET]					= sum(isnull([Телемедицина NET]					 ,0))
	   , [Защита от потери работы NET]		= sum(isnull([Защита от потери работы NET]		 ,0))
	   , [Фарм страхование NET]				= sum(isnull([Фарм страхование NET]				 ,0))
	   , [Спокойная жизнь NET]				= sum(isnull([Спокойная жизнь NET]				 ,0))

       , [КОЛИЧЕСТВО РАТ Юр. услуги]		=sum(case when [РАТ Юр. услуги]=0.0  then 0 else 1 end)
       , [СУММА РАТ Юр. услуги]				= sum([РАТ Юр. услуги])
	   , [РАТ Юр. услуги NET]				= sum(isnull([РАТ Юр. услуги NET]				 ,0))

       , [Количество ЗАЩИТА ЗДОРОВЬЯ]		= sum(case when [ЗАЩИТА ЗДОРОВЬЯ]=0.0  then 0 else 1 end)
       , [Сумма ЗАЩИТА ЗДОРОВЬЯ]			= sum([ЗАЩИТА ЗДОРОВЬЯ])
	   , [ЗАЩИТА ЗДОРОВЬЯ NET]				= sum(isnull([ЗАЩИТА ЗДОРОВЬЯ NET]					 ,0))

       , [Количество ФАРМА-помощь]			= sum(case when [ФАРМА-помощь]=0.0  then 0 else 1 end)
       , [Сумма ФАРМА-помощь]				= sum([ФАРМА-помощь])
	   , [ФАРМА-помощь NET]					= sum(isnull([ФАРМА-помощь NET]					 ,0))

       , [Количество Автоспор]				= sum(case when [Автоспор]=0.0  then 0 else 1 end)
       , [Сумма Автоспор]					= sum([Автоспор])
	   , [Автоспор NET]						= sum(isnull([Автоспор NET]					 ,0))

	   , ProductType = IIF(s.IsInstallment = 1, 'Инстоллмент', 'ПТС'	)

    --select * 
    from dbo.dm_Sales  s
		-- ПЭП3 07-09-2020
	 left join (
		select КодПЭП3, Период, cnt = count(1) 
		from #tpep3 
		group by КодПЭП3, Период
	) t_pep3 on t_pep3.КодПЭП3 = s.Код
	--and t_pep3.Период >=@pFrom aND датаВыдачи<@pTo 
	and t_pep3.Период between @pFrom aND @pTo 
    -- bp-1385
    left join #pts31 pts31 on pts31.КодПТС31 = s.Код
   where  s.ishistory=0
    -- and датаВыдачи>=@pFrom aND датаВыдачи<@pTo
	 and датаВыдачи between @pFrom aND @pTo 
	 and s.IsInstallment = 0
  --   and lastStatus<>'Аннулирован' 
   group by channel_B, IIF(s.IsInstallment = 1, 'Инстоллмент', 'ПТС'	)

union all 


select @name
		,'Total'
      
       , [Количество выдач]=count(*)
       , [Сумма выдач] = sum(сумма) 
       , [Средний чек]= case when count(*)>0 then sum(сумма) /count(*) else 0.0 end
       , [Доля КП]=100*case when sum(сумма)<>0
						THEN sum(
							[Помощь бизнесу] + 
							[Страхование жизни] + 
							РАТ + 
							[РАТ 2.0] + 
							КАСКО + 
							[От потери работы. «Максимум»] + 
							[От потери работы. «Стандарт»] +
							[Телемедицина]+
							[Фарм страхование]+
							[Спокойная жизнь] +
							[РАТ Юр. услуги] +
							[ЗАЩИТА ЗДОРОВЬЯ] +
							[ФАРМА-помощь] +
							[Автоспор]
						) / sum(сумма)  else 0.0 end
       , СредневзвешеннаяСтавка = case when sum(сумма)<>0 then sum(СтавкаНаСумму)/sum(сумма) else 0.0 end

       , [ВСЕГО КП] = sum(case 
							WHEN [Помощь бизнесу]=0.0 
								AND [Страхование жизни]=0.0 
								AND РАТ=0.0 
								AND [РАТ 2.0]=0.0 
								AND КАСКО=0.0 
								AND [От потери работы. «Максимум»]=0.0 
								AND [От потери работы. «Стандарт»] =0.0 
								AND [Телемедицина]=0.0 
								AND [Фарм страхование]=0.0 
								AND [Спокойная жизнь] = 0.0 
								AND [РАТ Юр. услуги] = 0.0 
								AND [ЗАЩИТА ЗДОРОВЬЯ] = 0.0 
								AND [ФАРМА-помощь] = 0.0 
								AND [Автоспор] = 0.0 
							THEN 0 else 1 END
						)
       , [СУММА КП] = sum(
			  isnull([Помощь бизнесу] ,0)
			+ isnull([Страхование жизни] ,0)
			+ isnull(РАТ ,0)
			+ isnull([РАТ 2.0] ,0)
			+ isnull(КАСКО ,0)
			+ isnull([От потери работы. «Максимум»] ,0)
			+ isnull([От потери работы. «Стандарт»] ,0)
			+ isnull([Телемедицина], 0)
			+ isnull([Защита от потери работы], 0)
			+ isnull([Фарм страхование], 0)
			+ isnull([Спокойная жизнь], 0)
			+ isnull([РАТ Юр. услуги], 0)
			+ isnull([ЗАЩИТА ЗДОРОВЬЯ], 0)
			+ isnull([ФАРМА-помощь], 0)
			+ isnull([Автоспор], 0)
			)
	   , [СУММА КП_without_partner_bounty] = sum(
			isnull([Помощь бизнесу_without_partner_bounty],0)
			+isnull([Страхование жизни_without_partner_bounty],0)
			+isnull([РАТ_without_partner_bounty],0)
			+isnull([РАТ 2.0_without_partner_bounty],0)
			+isnull([КАСКО_without_partner_bounty],0)
			+isnull([От потери работы. «Максимум»_without_partner_bounty],0)
			+isnull([От потери работы. «Стандарт»_without_partner_bounty],0)
			+isnull([Телемедицина_without_partner_bounty],0)
			+isnull([Защита от потери работы_without_partner_bounty],0)
			+isnull([Фарм страхование_without_partner_bounty],0)
			+isnull([Спокойная жизнь_without_partner_bounty],0)
			+isnull([РАТ Юр. услуги_without_partner_bounty],0)
			+isnull([ЗАЩИТА ЗДОРОВЬЯ_without_partner_bounty],0)
			+isnull([ФАРМА-помощь_without_partner_bounty],0)
			+isnull([Автоспор_without_partner_bounty],0)
	   )
	   , [СУММА КП_without_partner_bounty_net] = SUM(
			+isnull(s.[Помощь бизнесу NET]				,0)
			+isnull(s.[Страхование жизни NET]				,0)
			+isnull(s.[РАТ NET]							,0)
			+isnull(s.[РАТ 2.0 NET]						,0)
			+isnull(s.[КАСКО NET]							,0)
			+isnull(s.[От потери работы. «Максимум» NET]	,0)
			+isnull(s.[От потери работы. «Стандарт» NET]	,0)
			+isnull(s.[Телемедицина NET]					,0)
			+isnull(s.[Защита от потери работы NET]		,0)
			+isnull(s.[Фарм страхование NET]				,0)
			+isnull(s.[Спокойная жизнь NET]				,0)
			+isnull(s.[РАТ Юр. услуги NET]				,0)
			+isnull(s.[ЗАЩИТА ЗДОРОВЬЯ NET]					,0)
			+isnull(s.[ФАРМА-помощь NET]					,0)
			+isnull(s.[Автоспор NET]					,0)
		)
       
       , [КОЛИЧЕСТВО РАТ] =sum(case when  РАТ=0.0  then 0 else 1 end)
       , [СУММА РАТ] = sum(РАТ)

	   , [КОЛИЧЕСТВО РАТ 2.0] =sum(case when  [РАТ 2.0]=0.0  then 0 else 1 end)
       , [СУММА РАТ 2.0] = sum([РАТ 2.0])

       , [Количество Помощь бизнесу] = sum(case when [Помощь бизнесу]=0.0  then 0 else 1 end)
       , [Сумма Помощь бизнесу] = sum([Помощь бизнесу])
       
       , [Количество Страхование жизни] = sum(case when [Страхование жизни]=0.0  then 0 else 1 end)
       , [Сумма Страхование жизни] = sum([Страхование жизни])
     
       , [Количество КАСКО] = sum(case when [КАСКО]=0.0  then 0 else 1 end)
       , [Сумма КАСКО] = sum([КАСКО])
       
       , [Количество От потери работы] = sum(case when [От потери работы. «Максимум»]=0.0 and [От потери работы. «Стандарт»] =0.0   then 0 else 1 end)
       , [Сумма От потери работы] = sum([От потери работы. «Максимум»] + [От потери работы. «Стандарт»])
        
       , [Количество Телемедицина] = sum(case when [Телемедицина]=0.0  then 0 else 1 end)
       , [Сумма Телемедицина] = sum([Телемедицина])

       , [Количество Защита от потери работы] = sum(case when isnull([Защита от потери работы],0)=0.0  then 0 else 1 end)
       , [Сумма Защита от потери работы] = sum(isnull([Защита от потери работы],0))

       , [Количество Фарм страхование] = sum(case when isnull([Фарм страхование],0)=0.0  then 0 else 1 end)
       , [Сумма Фарм страхование] = sum(isnull([Фарм страхование],0))       
	   , [Количество ПЭП3] = sum(iif(КодПЭП3 is not null, 1,0))
	   , [Сумма ПЭП3] = sum(iif(КодПЭП3 is not null, сумма,0.0))
       , [Количество ПТС31] = sum(iif(КодПТС31 is not null, 1,0))
	   , [Сумма ПТС31] = sum(iif(КодПТС31 is not null, сумма,0.0))
	   , [Количество Спокойная жизнь] = sum(case when isnull([Спокойная жизнь],0)=0.0  then 0 else 1 end)
       , [Сумма Спокойная жизнь] = sum(isnull([Спокойная жизнь],0))     
	   , [Помощь бизнесу NET]				= sum(isnull([Помощь бизнесу NET]				 ,0))
	   , [Страхование жизни NET]			= sum(isnull([Страхование жизни NET]			 ,0))
	   , [РАТ NET]							= sum(isnull([РАТ NET]							 ,0))
	   , [РАТ 2.0 NET]						= sum(isnull([РАТ 2.0 NET]						 ,0))
	   , [КАСКО NET]						= sum(isnull([КАСКО NET]						 ,0))
	   , [От потери работы. «Максимум» NET] = sum(isnull([От потери работы. «Максимум» NET]  ,0))
	   , [От потери работы. «Стандарт» NET]	= sum(isnull([От потери работы. «Стандарт» NET]	 ,0))
	   , [Телемедицина NET]					= sum(isnull([Телемедицина NET]					 ,0))
	   , [Защита от потери работы NET]		= sum(isnull([Защита от потери работы NET]		 ,0))
	   , [Фарм страхование NET]				= sum(isnull([Фарм страхование NET]				 ,0))
	   , [Спокойная жизнь NET]				= sum(isnull([Спокойная жизнь NET]				 ,0))

	   , [КОЛИЧЕСТВО РАТ Юр. услуги] =sum(case when  [РАТ Юр. услуги]=0.0  then 0 else 1 end)
       , [СУММА РАТ Юр. услуги] = sum([РАТ Юр. услуги])
	   , [РАТ Юр. услуги NET]				= sum(isnull([РАТ Юр. услуги NET]				 ,0))

       , [Количество ЗАЩИТА ЗДОРОВЬЯ] = sum(case when [ЗАЩИТА ЗДОРОВЬЯ]=0.0  then 0 else 1 end)
       , [Сумма ЗАЩИТА ЗДОРОВЬЯ] = sum([ЗАЩИТА ЗДОРОВЬЯ])
	   , [ЗАЩИТА ЗДОРОВЬЯ NET]					= sum(isnull([ЗАЩИТА ЗДОРОВЬЯ NET]			 ,0))

       , [Количество ФАРМА-помощь] = sum(case when [ФАРМА-помощь]=0.0  then 0 else 1 end)
       , [Сумма ФАРМА-помощь] = sum([ФАРМА-помощь])
	   , [ФАРМА-помощь NET]					= sum(isnull([ФАРМА-помощь NET]			 ,0))

       , [Количество Автоспор] = sum(case when [Автоспор]=0.0  then 0 else 1 end)
       , [Сумма Автоспор] = sum([Автоспор])
	   , [Автоспор NET]					= sum(isnull([Автоспор NET]			 ,0))

	   , ProductType = IIF(s.IsInstallment = 1, 'Инстоллмент', 'ПТС'	)
    from dbo.dm_Sales  s
    -- ПЭП3 07-09-2020
    left join (
		select КодПЭП3, Период, cnt = count(1) 
		from #tpep3 
		group by КодПЭП3, Период
	) t_pep3 on t_pep3.КодПЭП3 = s.Код
	--and t_pep3.Период >=@pFrom aND t_pep3.Период<@pTo 
	and t_pep3.Период between @pFrom and @pTo 
    -- bp-1385
    left join #pts31 pts31 on pts31.КодПТС31 = s.Код
    where  ishistory=0
    --and датаВыдачи>=@pFrom aND датаВыдачи<@pTo
	and датаВыдачи between @pFrom and @pTo
	group by IIF(s.IsInstallment = 1, 'Инстоллмент', 'ПТС'	)
  --
    -- and lastStatus<>'Аннулирован' 
 )

 --select * from dashboard
  ,plans as (select period=@name,
	суммаПТС=sum(p.[Займы руб])
	,[Сумма займов инстоллмент план] = sum(p.[Сумма займов инстоллмент план])
	,СуммаКП = Sum(p.[План КП аналитический по дням])
 --,plans as (select period=@name,сумма=sum(p.[Займы руб])  
 from #plans p where 
     --дата>=@pFrom aND дата<@pTo
	 дата between @pFrom and @pTo
  --
 ),plans_to_cur_day as 
 (
	select 
	 суммаПТС=sum(p.[Займы руб])
	 ,[Сумма займов инстоллмент план] = sum(p.[Сумма займов инстоллмент план])
	 ,СуммаКП = Sum(p.[План КП аналитический по дням])
	from #plans p
	--C Начала месяца по вчера включительно
	where Дата between dateadd(dd,1, EOMONTH(getdate(), -1)) 
	and cast(dateadd(dd, -1, getdate()) as date)
 ), sales_to_cur_day as
 (
	select 
		сумма = sum(сумма), 
		ProductType = IIF(s.IsInstallment = 1, 'Инстоллмент', 'ПТС'	)
	from dbo.dm_Sales s
	where ishistory = 0 
	--C Начала месяца по вчера включительно
	and датаВыдачи between dateadd(dd,1, EOMONTH(getdate(), -1)) 
	and cast(dateadd(dd, -1, getdate()) as date)
	group by IIF(s.IsInstallment = 1, 'Инстоллмент', 'ПТС'	)
 )
 insert into #t_result
 (
	[period], 
	pFrom,
	pTo,
	[channel_B], 
	[Количество выдач], 
	[Сумма выдач], 
	[Средний чек], 
	[Доля КП], 
	[СредневзвешеннаяСтавка], 
	[ВСЕГО КП], 
	[СУММА КП], 
	[КОЛИЧЕСТВО РАТ], 
	[СУММА РАТ], 
	[Количество Помощь бизнесу], 
	[Сумма Помощь бизнесу], 
	[Количество Страхование жизни], 
	[Сумма Страхование жизни], 
	[Количество КАСКО], 
	[Сумма КАСКО], 
	[Количество От потери работы], 
	[Сумма От потери работы], 
	[Количество Телемедицина], 
	[Сумма Телемедицина], 
	[Количество Защита от потери работы], 
	[Сумма Защита от потери работы], 
	[ПланСуммаВыдач], 
	[Количество ПЭП3], 
	[Сумма ПЭП3], 
	[ПланЗаПериодСуммаКП], 
	[СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ], 
	[СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ БЕЗ НДС],
    [Количество Фарм страхование],
	[Сумма Фарм страхование],
    [Количество ПТС31], 
    [Сумма ПТС31],
	[Количество Спокойная жизнь],
	[Сумма Спокойная жизнь],
	[Помощь бизнесу NET],					
	[Страхование жизни NET],				
	[РАТ NET],								
	[КАСКО NET],							
	[От потери работы. «Максимум» NET], 	
	[От потери работы. «Стандарт» NET],		
	[Телемедицина NET],						
	[Защита от потери работы NET],			
	[Фарм страхование NET],					
	[Спокойная жизнь NET],
	ProductType,
	ПланСуммаВыдачПоТекущДен,
	СуммаВыдачПоТекущДен,
	--
	[КОЛИЧЕСТВО РАТ 2.0],
	[СУММА РАТ 2.0],
	[РАТ 2.0 NET],
	--
	[КОЛИЧЕСТВО РАТ Юр. услуги],
	[СУММА РАТ Юр. услуги],
	[РАТ Юр. услуги NET],

	[Количество ЗАЩИТА ЗДОРОВЬЯ],
	[Сумма ЗАЩИТА ЗДОРОВЬЯ],
	[ЗАЩИТА ЗДОРОВЬЯ NET],

	[Количество ФАРМА-помощь],
	[Сумма ФАРМА-помощь],
	[ФАРМА-помощь NET],

	[Количество Автоспор],
	[Сумма Автоспор],
	[Автоспор NET]
 )

 select d.[period]
	  , pFrom	= @pFrom	
	  , pTo		= @pTo	
      , d.[channel_B]
      , d.[Количество выдач]
      , d.[Сумма выдач]
      , d.[Средний чек]
      , d.[Доля КП]
      , d.[СредневзвешеннаяСтавка]
      , d.[ВСЕГО КП]
      , d.[СУММА КП]
      , d.[КОЛИЧЕСТВО РАТ]
      , d.[СУММА РАТ]
      , d.[Количество Помощь бизнесу]
      , d.[Сумма Помощь бизнесу]
      , d.[Количество Страхование жизни]
      , d.[Сумма Страхование жизни]
      , d.[Количество КАСКО]
      , d.[Сумма КАСКО]
      , d.[Количество От потери работы]
      , d.[Сумма От потери работы]
      , d.[Количество Телемедицина]
      , d.[Сумма Телемедицина]
      , d.[Количество Защита от потери работы]
      , d.[Сумма Защита от потери работы]
	  , ПланСуммаВыдач  = case d.ProductType 
		when 'Инстоллмент' then p.[Сумма займов инстоллмент план]
		when 'ПТС' then p.суммаПТС 
		else p.суммаПТС  end
 --2020-09-07
	 , d.[Количество ПЭП3] 
	 , d.[Сумма ПЭП3] 
	 , p.СуммаКП as ПланЗаПериодСуммаКП
	 , [СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ] = d.[СУММА КП_without_partner_bounty] 
	 , [СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ БЕЗ НДС]  = d.[СУММА КП_without_partner_bounty_net]
	 --, d.[СУММА КП_without_partner_bounty]/1.2 as [СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ БЕЗ НДС] --Ставка НДС 20%
	 , d.[Количество Фарм страхование]
	 , d.[Сумма Фарм страхование]
	 , d.[Количество ПТС31] 
	 , d.[Сумма ПТС31]
	 , d.[Количество Спокойная жизнь]
	 , d.[Сумма Спокойная жизнь]
	 , d.[Помощь бизнесу NET]					
	 , d.[Страхование жизни NET]			
	 , d.[РАТ NET]								
	 , d.[КАСКО NET]							
	 , d.[От потери работы. «Максимум» NET] 	
	 , d.[От потери работы. «Стандарт» NET]		
	 , d.[Телемедицина NET]						
	 , d.[Защита от потери работы NET]			
	 , d.[Фарм страхование NET]					
	 , d.[Спокойная жизнь NET]		
	 , d.ProductType
	 , ПланСуммаВыдачПоТекущДен = 
		 case d.ProductType 
			when 'Инстоллмент' then p_to_cur_day.[Сумма займов инстоллмент план]
			when 'ПТС' then p_to_cur_day.суммаПТС 
		else p.суммаПТС  end
	, СуммаВыдачПоТекущДен = s_to_cru_day.сумма 
	, d.[КОЛИЧЕСТВО РАТ 2.0]
	, d.[СУММА РАТ 2.0]
	, d.[РАТ 2.0 NET]
	, d.[КОЛИЧЕСТВО РАТ Юр. услуги]
	, d.[СУММА РАТ Юр. услуги]
	, d.[РАТ Юр. услуги NET]

	, d.[Количество ЗАЩИТА ЗДОРОВЬЯ]
	, d.[Сумма ЗАЩИТА ЗДОРОВЬЯ]
	, d.[ЗАЩИТА ЗДОРОВЬЯ NET]

	, d.[Количество ФАРМА-помощь]
	, d.[Сумма ФАРМА-помощь]
	, d.[ФАРМА-помощь NET]

	, d.[Количество Автоспор]
	, d.[Сумма Автоспор]
	, d.[Автоспор NET]

 from dashboard d join plans p on p.period=d.period
 left join plans_to_cur_day p_to_cur_day on 1=1
 left join sales_to_cur_day s_to_cru_day on s_to_cru_day.ProductType = d.ProductType
	
 --

 /*
	alter table dbo.dm_SalesDashboard add ProductType nvarchar(255)
	alter table dbo.dm_SalesDashboard add pFrom date
	alter table dbo.dm_SalesDashboard add pTo date
	alter table dbo.dm_SalesDashboard add ПланСуммаВыдачПоТекущДен money
	alter table dbo.dm_SalesDashboard add СуммаВыдачПоТекущДен money
 */

 delete from #periods where   @name=name and @pFrom =pFrom and @pTo=pTo

 --drop table dbo.dm_SalesDashboard
end
	begin tran
		/*
	
		*/
		delete from dbo.dm_SalesDashboard

		insert into dbo.dm_SalesDashboard
	 (
		[period], 
		pFrom	,
		pTo		,
		[channel_B], 
		[Количество выдач], 
		[Сумма выдач], 
		[Средний чек], 
		[Доля КП], 
		[СредневзвешеннаяСтавка], 
		[ВСЕГО КП], 
		[СУММА КП], 
		[КОЛИЧЕСТВО РАТ], 
		[СУММА РАТ], 
		[Количество Помощь бизнесу], 
		[Сумма Помощь бизнесу], 
		[Количество Страхование жизни], 
		[Сумма Страхование жизни], 
		[Количество КАСКО], 
		[Сумма КАСКО], 
		[Количество От потери работы], 
		[Сумма От потери работы], 
		[Количество Телемедицина], 
		[Сумма Телемедицина], 
		[Количество Защита от потери работы], 
		[Сумма Защита от потери работы], 
		[ПланСуммаВыдач], 
		[Количество ПЭП3], 
		[Сумма ПЭП3], 
		[ПланЗаПериодСуммаКП], 
		[СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ], 
		[СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ БЕЗ НДС],
		[Количество Фарм страхование],
		[Сумма Фарм страхование],
		[Количество ПТС31], 
		[Сумма ПТС31],
		[Количество Спокойная жизнь],
		[Сумма Спокойная жизнь],
		[Помощь бизнесу NET],					
		[Страхование жизни NET],				
		[РАТ NET],								
		[КАСКО NET],							
		[От потери работы. «Максимум» NET], 	
		[От потери работы. «Стандарт» NET],		
		[Телемедицина NET],						
		[Защита от потери работы NET],			
		[Фарм страхование NET],					
		[Спокойная жизнь NET],
		ProductType,
		ПланСуммаВыдачПоТекущДен,
		СуммаВыдачПоТекущДен,
		--
		[КОЛИЧЕСТВО РАТ 2.0],
		[СУММА РАТ 2.0],
		[РАТ 2.0 NET],
		--
		[КОЛИЧЕСТВО РАТ Юр. услуги],
		[СУММА РАТ Юр. услуги],
		[РАТ Юр. услуги NET],

		[Количество ЗАЩИТА ЗДОРОВЬЯ], 
		[Сумма ЗАЩИТА ЗДОРОВЬЯ], 
		[ЗАЩИТА ЗДОРОВЬЯ NET],						

		[Количество ФАРМА-помощь], 
		[Сумма ФАРМА-помощь], 
		[ФАРМА-помощь NET],						

		[Количество Автоспор],
		[Сумма Автоспор],
		[Автоспор NET]
	 )
	 select 
		 [period], 
		 pFrom	,
		 pTo	,
		 [channel_B], 
		[Количество выдач], 
		[Сумма выдач], 
		[Средний чек], 
		[Доля КП], 
		[СредневзвешеннаяСтавка], 
		[ВСЕГО КП], 
		[СУММА КП], 
		[КОЛИЧЕСТВО РАТ], 
		[СУММА РАТ], 
		[Количество Помощь бизнесу], 
		[Сумма Помощь бизнесу], 
		[Количество Страхование жизни], 
		[Сумма Страхование жизни], 
		[Количество КАСКО], 
		[Сумма КАСКО], 
		[Количество От потери работы], 
		[Сумма От потери работы], 
		[Количество Телемедицина], 
		[Сумма Телемедицина], 
		[Количество Защита от потери работы], 
		[Сумма Защита от потери работы], 
		[ПланСуммаВыдач], 
		[Количество ПЭП3], 
		[Сумма ПЭП3], 
		[ПланЗаПериодСуммаКП], 
		[СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ], 
		[СУММА КП ЗА ВЫЧЕТОМ ПАРТНЕРСКОЙ КОММИСИИ БЕЗ НДС],
		[Количество Фарм страхование],
		[Сумма Фарм страхование],
		[Количество ПТС31], 
		[Сумма ПТС31],
		[Количество Спокойная жизнь],
		[Сумма Спокойная жизнь],
		[Помощь бизнесу NET],					
		[Страхование жизни NET],				
		[РАТ NET],								
		[КАСКО NET],							
		[От потери работы. «Максимум» NET], 	
		[От потери работы. «Стандарт» NET],		
		[Телемедицина NET],						
		[Защита от потери работы NET],			
		[Фарм страхование NET],					
		[Спокойная жизнь NET],
		ProductType,
		ПланСуммаВыдачПоТекущДен,
		СуммаВыдачПоТекущДен,
		--
		[КОЛИЧЕСТВО РАТ 2.0],
		[СУММА РАТ 2.0],
		[РАТ 2.0 NET],
		--
		[КОЛИЧЕСТВО РАТ Юр. услуги],
		[СУММА РАТ Юр. услуги],
		[РАТ Юр. услуги NET],

		[Количество ЗАЩИТА ЗДОРОВЬЯ], 
		[Сумма ЗАЩИТА ЗДОРОВЬЯ], 
		[ЗАЩИТА ЗДОРОВЬЯ NET],						

		[Количество ФАРМА-помощь], 
		[Сумма ФАРМА-помощь], 
		[ФАРМА-помощь NET],						

		[Количество Автоспор],
		[Сумма Автоспор],
		[Автоспор NET]
	 from #t_result

	commit tran


	  select    ПланСуммаВыдач=sum(p.[Займы руб]) from #plans p
	begin tran
	  delete from dbo.dm_dashboard_CallCentr_actual
  
	  insert into dbo.dm_dashboard_CallCentr_actual
	  select ТекДата=getdate()
		   , ТекВремя = format(getdate() ,'HH:mm')
		   , СуммаПланДн =isnull((select cast(round(ПланСуммаВыдач,0) as int) from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , СуммаФактДн =isnull((select cast(round([Сумма Выдач],0) as int) from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , ПроцВыполнДн= case when (select top 1 cast(round(ПланСуммаВыдач,0) as int) from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total')<>0 
								then round((select round([Сумма Выдач],0) from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total')
									 /(select round(ПланСуммаВыдач,0)  from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total')*100
									 ,2
									 )
						   end

		   , Встречи =0
		   , СуммаФактМес	=isnull((select cast(round([Сумма Выдач],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , ПроцВыполнМес = case when ((select cast(round(ПланСуммаВыдач,0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'))<>0 
								  then round ((select round([Сумма Выдач],0) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')
								  /(select round(ПланСуммаВыдач,0)  from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')*100
								  ,2)
								  else 0.0 end

			, ОстДоЦели	=isnull((select cast(round(ПланСуммаВыдач,0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')-(select cast(round([Сумма Выдач],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
			, ПериодУчетаДн	=cast(getdate() as date)
			, Ф_СтавкаНаСуммуМес=null

		--   , Ф_СтавкаНаСуммуМес= (select cast(round([Сумма Выдач],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and channel_B='Total')
		   , СрВзвешСтавкаМес =isnull((select СредневзвешеннаяСтавка from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , ПланКПМес =cast(@kp	as int)
		   , СуммаКПМес	=isnull((select cast(round([Сумма КП],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , ВыполнКППроц  = CAST(round (case when @kp	<>0 
										 then (select cast(round([Сумма КП],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')
										 /@kp *100
										 else 0.0 end
								 ,2)
								 AS decimal(38,2)
								 )
		   , Ф_КолвоЗаймовМес =isnull((select cast(round([Количество выдач],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , ДоляПроникнСтрахПроц	 = round( case when  (select cast(round([Количество выдач],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')<>0
									  then  1.0*(select round([ВСЕГО КП],0)  from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')
											/
											(select round([Количество выдач],0) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')*100.0
											else 0.0 end
									  ,2)
		   , Ф_СуммаДопУслугБезАкцМес	=isnull((select cast(round([Сумма КП],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , ДоляСтрахПроц	=case when (select cast(round([Сумма Выдач],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total')<>0 then
							  round ((select round([Сумма КП],0)  from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total')/
							 (select round([Сумма Выдач],0) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total')*100
							 ,2)
							 else 0.0
							 end
		   , ВсегоКПМес	= isnull((select cast(round([ВСЕГО КП],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total'),0)
		   , КолвоРАТ	= isnull((select cast(round([КОЛИЧЕСТВО РАТ],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total'),0)
		   , СуммаРАТ	= isnull((select cast(round([СУММА РАТ],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total'),0)
		   , СуммаСтрахЖизни	= isnull((select cast(round([Сумма Страхование жизни],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total'),0)
		   , СуммаКаско	= isnull((select cast(round([Сумма КАСКО],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС' and channel_B='Total'),0)
		   , СуммаНС	= isnull((select cast(round([Сумма КАСКО]+[Сумма Страхование жизни],0) as int) from dbo.dm_SalesDashboard where period='Месяц' and ProductType = 'ПТС'  and channel_B='Total'),0)
		   , ДоляПроникнСтрахПроцДн =case when (select round([Количество выдач],0)  from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total')<>0 
										  then round(1.0*(select cast(round([Количество Страхование жизни],0) as int) from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС'  and channel_B='Total')
													 /
													  (select round([Количество выдач],0)  from dbo.dm_SalesDashboard where period='Сегодня' and ProductType = 'ПТС' and channel_B='Total')
													  *100.0
													  ,2)
										  else 0.0
										  end
	commit tran
       
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	
	;throw
end catch
END