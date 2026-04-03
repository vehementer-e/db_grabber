-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <11.11.2020>
-- Description:	<Для целей сверки>
-- =============================================
CREATE PROCEDURE [dbo].[MMonitoring_CRM_UMFO] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- reserve
Declare
@last_date_reserve date
  
select @last_date_reserve = max(cdate) from [Reports].[dbo].[dm_UMFO_reserve] 

-- Reserve
drop table if exists #reserve
  select 
    external_id as [НомерДоговора]
  ,	rserve_sum as [СуммаЗайма Reserve]

  into #reserve
  from [Reports].[dbo].[dm_UMFO_reserve] 
  where cdate  = @last_date_reserve
  --select * from #reserve

-- CMR
drop table if exists #crm
SELECT 
      d.[Код] as [НомерДоговора]
      ,cast(d.[Дата] as date) as [ДатаДоговора CMR]
	  --,cast(d.[ДатаНачалаОбслуживанияВЦМР] as date) [ДатаНачалаОбслуживанияВЦМР]     
      ,d.[Сумма] as [СуммаЗайма CMR]
	  , cast(vd.[ДатаВыдачи]  as date) as [ДатаВыдачи CMR]
	  , null as ФинансовыйПродукт
  into #crm   
  FROM stg._1cCMR.[Справочник_Договоры] d
  left join stg._1cCMR.[Документ_ВыдачаДенежныхСредств] vd
  on d.Ссылка = vd.[Договор]
 where d.ПометкаУдаления =0x00

  -- УМФО
  drop table if exists #umfo
  SELECT  
      -- z.[Ссылка]      
       [НомерДоговора]
      ,cast([ДатаДоговора] as date) as [ДатаДоговора УМФО]
     -- ,[Проведен]
      ,z.[СуммаЗайма] as [СуммаЗайма УМФО]
      ,cast([ДатаНачала] as date) as [ДатаВыдачи УМФО] 
	  --, iif(ФинансовыйПродукт = 0x810800155D01C00511E86A20C903A3AE OR ФинансовыйПродукт = 0x810800155D01C00511E86A217C416000, 'Бизнес-займ','Автозайм')  ФинансовыйПродукт
	  ,f.Наименование as ФинансовыйПродукт

	  into #umfo
  FROM [C2-VSR-SQL04].[umfo].[dbo].[Документ_АЭ_ЗаймПредоставленный] z
  left join [C2-VSR-SQL04].[umfo].[dbo].[Справочник_АЭ_ФинансовыеПродукты] f on f.Ссылка = z.ФинансовыйПродукт
  --left join [C2-VSR-SQL04].[UMFO_NIGHT00].[dbo].[Документ_АЭ_ВыдачаПоЗаймамПредоставленным_Займы] vz
  --on vz.Займ = z.Ссылка
  where   z.Проведен = 0x01
  --and (ФинансовыйПродукт = 0x810800155D01C00511E86A20C903A3AE OR ФинансовыйПродукт = 0x810800155D01C00511E86A217C416000)
  --cast([ДатаНачала] as date) <> cast([ДатаДоговора] as date)
  --and 
  --[НомерДоговора] = '20093000681001'
  ----z.[СуммаЗайма] <> Сумма
  --and

  --Select ФинансовыйПродукт, Count(*) from #umfo group by ФинансовыйПродукт
  
    drop table if exists #loan
	select [НомерДоговора] 
	into #loan
	from #umfo
	
	union

	select [НомерДоговора] 
	from #crm

	union

	select [НомерДоговора] 
	from #reserve

  --select  umfo.[НомерДоговора],  crm.[НомерДоговора] from #crm crm
  --full outer join #umfo umfo on crm.НомерДоговора = umfo.[НомерДоговора]
  --full outer join #reserve r_umfo on crm.НомерДоговора = umfo.[НомерДоговора]
  --where umfo.[НомерДоговора] is null or  crm.[НомерДоговора] is null

  select 'Не совпадают суммы' as Checked
		, l.НомерДоговора
		, crm.[ДатаВыдачи CMR]
		, crm.[ДатаДоговора CMR]
		, crm.[СуммаЗайма CMR]
		, umfo.[ДатаВыдачи УМФО]
		, umfo.[ДатаДоговора УМФО]
		, umfo.[СуммаЗайма УМФО]
		, umfo.ФинансовыйПродукт
		
		from #loan l
  left join #crm crm on l.НомерДоговора = crm.[НомерДоговора]
  left join #umfo umfo on l.НомерДоговора = umfo.[НомерДоговора]
  left join #reserve reserve on l.НомерДоговора = reserve.[НомерДоговора]
  --left join ( select d, b.external_id as [НомерДоговора], b.[Расчетный остаток всего]  from reports.dbo.dm_CMRStatBalance_2 b where d = cast(getdate()-1 as date)) balance on l.НомерДоговора = balance.[НомерДоговора] 
  where 
  --crm.ДатаВыдачи is null 
  ----and reserve.[НомерДоговора] is not null
  --and 
  crm.[СуммаЗайма CMR]<> umfo.[СуммаЗайма УМФО]
  --and 
  --balance.d is not null
  --order by umfo.[ДатаВыдачи УМФО] desc
     
  union all

  select 'Не совпадают даты договора' as Checked
		, l.НомерДоговора
		, crm.[ДатаВыдачи CMR]
		, crm.[ДатаДоговора CMR]
		, crm.[СуммаЗайма CMR]
		, umfo.[ДатаВыдачи УМФО]
		, umfo.[ДатаДоговора УМФО]
		, umfo.[СуммаЗайма УМФО]
		, umfo.ФинансовыйПродукт
		
		from #loan l
  left join #crm crm on l.НомерДоговора = crm.[НомерДоговора]
  left join #umfo umfo on l.НомерДоговора = umfo.[НомерДоговора]
  left join #reserve reserve on l.НомерДоговора = reserve.[НомерДоговора]
  --left join ( select d, b.external_id as [НомерДоговора], b.[Расчетный остаток всего]  from reports.dbo.dm_CMRStatBalance_2 b where d = cast(getdate()-1 as date)) balance on l.НомерДоговора = balance.[НомерДоговора] 
  where 
  --crm.ДатаВыдачи is null 
  ----and reserve.[НомерДоговора] is not null
  --and 
  crm.[ДатаДоговора CMR]<> umfo.[ДатаДоговора УМФО]
  --and 
  --balance.d is not null
  --order by umfo.[ДатаВыдачи УМФО]desc

   union all

  select 'Не совпадают даты выдачи' as Checked
		, l.НомерДоговора
		, crm.[ДатаВыдачи CMR]
		, crm.[ДатаДоговора CMR]
		, crm.[СуммаЗайма CMR]
		, umfo.[ДатаВыдачи УМФО]
		, umfo.[ДатаДоговора УМФО]
		, umfo.[СуммаЗайма УМФО]
		, umfo.ФинансовыйПродукт
		
		from #loan l
  left join #crm crm on l.НомерДоговора = crm.[НомерДоговора]
  left join #umfo umfo on l.НомерДоговора = umfo.[НомерДоговора]
  left join #reserve reserve on l.НомерДоговора = reserve.[НомерДоговора]
  --left join ( select d, b.external_id as [НомерДоговора], b.[Расчетный остаток всего]  from reports.dbo.dm_CMRStatBalance_2 b where d = cast(getdate()-1 as date)) balance on l.НомерДоговора = balance.[НомерДоговора] 
  where 
  --crm.ДатаВыдачи is null 
  ----and reserve.[НомерДоговора] is not null
  --and 
 crm.[ДатаВыдачи CMR] <> umfo.[ДатаВыдачи УМФО]
  --and 
  --balance.d is not null
  --order by umfo.[ДатаВыдачи УМФО]desc

  union all

  select 'Есть резервы, но нет в CMR' as Checked
		, l.НомерДоговора
		, crm.[ДатаВыдачи CMR]
		, crm.[ДатаДоговора CMR]
		, crm.[СуммаЗайма CMR]
		, umfo.[ДатаВыдачи УМФО]
		, umfo.[ДатаДоговора УМФО]
		, umfo.[СуммаЗайма УМФО]
		, umfo.ФинансовыйПродукт
		
		from #loan l
  left join #crm crm on l.НомерДоговора = crm.[НомерДоговора]
  left join #umfo umfo on l.НомерДоговора = umfo.[НомерДоговора]
  left join #reserve reserve on l.НомерДоговора = reserve.[НомерДоговора]
  --left join ( select d, b.external_id as [НомерДоговора], b.[Расчетный остаток всего]  from reports.dbo.dm_CMRStatBalance_2 b where d = cast(getdate()-1 as date)) balance on l.НомерДоговора = balance.[НомерДоговора] 
  where 
  crm.[ДатаВыдачи CMR]is null 
  and umfo.ФинансовыйПродукт <> 'Займы сотрудникам'
  and
  reserve.[НомерДоговора] is not null

  --and 
  --balance.d is not null
  --order by umfo.[ДатаВыдачи УМФО]desc

END
