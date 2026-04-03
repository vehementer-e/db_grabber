 
create      proc  [partner_lead_]
@mode nvarchar(max) = 'update'
as
begin

if @mode= 'update' 
begin

DROP TABLE IF EXISTS #partner_id


select
	cast(l.id as nvarchar(36))	   id

into #partner_id
from
	Stg._LCRM.lcrm_leads_full l(nolock)
where
	l.UF_STAT_AD_TYPE='partner'	   and 1=0
	insert into   #partner_id
select
	l.id

--into #partner_id
from
	Stg._LCRM.lcrm_leads_full l(nolock)
where
	l.uf_type='site3_installment_lk'	 and 1=0


	;with v  as (select *, row_number() over(partition by id order by (select null)) rn from #partner_id ) delete from v where rn>1


DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	  id nvarchar(50)  ,
	  UF_REGISTERED_AT datetime2,
	  [PhoneNumber] nvarchar(128),
	  [UF_STAT_SOURCE]  nvarchar(4000),
	  [UF_STAT_AD_TYPE] nvarchar(4000),
	  [UF_STAT_CAMPAIGN] nvarchar(4000),
	  [UF_STAT_SYSTEM] nvarchar(4000),
	  uf_row_id nvarchar(4000)	,
	  UF_TYPE nvarchar(4000)


)


DECLARE @start_id numeric(10, 0), @depth_id numeric(10, 0)
DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)



--название таблицы со списком ID
SELECT @ID_Table_Name = '#partner_id'
--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'

TRUNCATE TABLE #TMP_leads

EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

    

insert into    #TMP_leads

select  a.id,  a.created,  a.phone,  a.stat_source,  a.stat_type,  a.[STAT_CAMPAIGN],  a.[STAT_SYSTEM],   b.number, a.type  from v_lead	  a
left join v_request_lf b on a.id=b.marketing 
where a.type in ('partner', 'partner-installment')	  


insert into    #TMP_leads

select  a.id,  a.created,  a.phone,  a.stat_source,  a.stat_type,  a.[STAT_CAMPAIGN],  a.[STAT_SYSTEM],   b.number, a.type  from v_lead	  a
left join v_request_lf b on a.id=b.marketing 
where a.type not  in ('partner', 'partner-installment')	 and 
	a.stat_type='partner'

insert into    #partner_id
select id from 	#TMP_leads a
 


DROP TABLE IF EXISTS [#Отчет по лидам парнеров с сайта]
 
   CREATE TABLE  [#Отчет по лидам парнеров с сайта]
(
      [ID лида] [NVARCHAR](36)
    , [UF_TYPE] [NVARCHAR](4000)
    , [Офис форма ЛК] [NVARCHAR](4000)
    , [Телефон] [NVARCHAR](128)
    , [Дата создания лида] [DATETIME2](7)
    , [Номер заявки] [NVARCHAR](4000)
    , [UF_STAT_SOURCE] [NVARCHAR](4000)
    , [UF_STAT_AD_TYPE] [NVARCHAR](4000)
    , [UF_STAT_CAMPAIGN] [NVARCHAR](4000)
    , [UF_STAT_SYSTEM] [NVARCHAR](4000)
    , [Дата выдачи] [DATETIME]
    , [Выданная сумма] [NUMERIC]
    , [Номер партнера] [NVARCHAR](255)
    , [РП] [NVARCHAR](255)
    , [РО_регион] [NVARCHAR](255)
    , [Юрлицо] [NVARCHAR](255)
    , [promo_code] [NVARCHAR](255)
    , [Канал от источника] [NVARCHAR](255)
);

	insert into [#Отчет по лидам парнеров с сайта]

select
	p.id as [ID лида],
	l.UF_TYPE as UF_TYPE,
	 o.Наименование [Офис форма ЛК]	  ,
	l.[PhoneNumber] as [Телефон],
	l.UF_REGISTERED_AT as [Дата создания лида],
	l.uf_row_id as [Номер заявки],
	l.[UF_STAT_SOURCE],
	l.[UF_STAT_AD_TYPE],
	l.[UF_STAT_CAMPAIGN],
	l.[UF_STAT_SYSTEM],
	fa.[Заем выдан] as [Дата выдачи],
	fa.[Выданная сумма] as [Выданная сумма],
	fa.[Номер партнера] as [Номер партнера],
	fa.[РП] as [РП],
	fa.[РО_регион] as [РО_регион],
	fa.Юрлицо as Юрлицо,
	null promo_code,
	[Канал от источника]
 
from
	#partner_id p
	inner join #TMP_leads l(nolock)on p.id = l.id
	left join Reports.dbo.dm_Factor_Analysis_001 fa (nolock) on fa.Номер = l.UF_ROW_ID
	--left join stg._LK.requests lk_r (nolock) on lk_r.num_1c=fa.Номер
	left join stg._1cCRM.СПравочник_Офисы o on o.Код=l.[UF_STAT_CAMPAIGN]  and l.UF_TYPE in ('site3_installment_lk' , 'partner', 'partner-installment')	
	
	insert into [#Отчет по лидам парнеров с сайта]


select
	l.id as [ID лида],
	null as UF_TYPE,
	null [Офис форма ЛК]	  ,
	l.[PhoneNumber] as [Телефон],
	l.UF_REGISTERED_AT as [Дата создания лида],
	l.uf_row_id as [Номер заявки],
	l.[UF_STAT_SOURCE],
	l.[UF_STAT_AD_TYPE],
	l.[UF_STAT_CAMPAIGN],
	l.[UF_STAT_SYSTEM],
	fa.[Заем выдан] as [Дата выдачи],
	fa.[Выданная сумма] as [Выданная сумма],
	fa.[Номер партнера] as [Номер партнера],
	fa.[РП] as [РП],
	fa.[РО_регион] as [РО_регион],
	fa.Юрлицо as Юрлицо,
	lk_r.promo_code,
	fa.[Канал от источника]
	--into #f
from
	stg._LCRM.lcrm_leads_full_channel_request l
	join Reports.dbo.dm_Factor_Analysis_001 fa (nolock) on fa.Номер = l.UF_ROW_ID
	join stg._LK.requests lk_r (nolock) on lk_r.num_1c=fa.Номер
	join stg._1cCRM.Справочник_Офисы o on o.Код=lk_r.promo_code
	 where 1=0


   	insert into [#Отчет по лидам парнеров с сайта]


select
	fa.Номер as [ID лида],
	null as UF_TYPE,
	null [Офис форма ЛК]	  ,
	fa.Телефон as [Телефон],
	fa.ДатаЗаявкиПолная as [Дата создания лида],
	fa.Номер as [Номер заявки],
	null [UF_STAT_SOURCE],
	null [UF_STAT_AD_TYPE],
	null [UF_STAT_CAMPAIGN],
	null [UF_STAT_SYSTEM],
	fa.[Заем выдан] as [Дата выдачи],
	fa.[Выданная сумма] as [Выданная сумма],
	fa.[Номер партнера] as [Номер партнера],
	fa.[РП] as [РП],
	fa.[РО_регион] as [РО_регион],
	fa.Юрлицо as Юрлицо,
	lk_r.promo_code,
	fa.[Канал от источника]
	--into #f
from
	  Reports.dbo.dm_Factor_Analysis_001 fa (nolock)  
	join stg._LK.requests lk_r (nolock) on lk_r.num_1c=fa.Номер
	join stg._1cCRM.Справочник_Офисы o on o.Код=lk_r.promo_code
where 	fa.ДатаЗаявкиПолная>='20240427'

	;

	with v as (
	select * , ROW_NUMBER() over(partition by [ID лида]+isnull( [Номер заявки], '') order by (select null)) rn  from [#Отчет по лидам парнеров с сайта])
	delete from v where rn>1

	update a
	set a.[Телефон] = '(***)***-'+right([Телефон], 4)

	from [#Отчет по лидам парнеров с сайта] a

--	select *  from #f
--order by [Дата создания лида] desc

--order by
	--UF_REGISTERED_AT desc

begin tran

--DROP TABLE IF EXISTS dbo.[Отчет по лидам парнеров с сайта]
--select * into dbo.[Отчет по лидам парнеров с сайта] from [#Отчет по лидам парнеров с сайта]
--select * into dbo.[Отчет по лидам парнеров с сайта_retro] from [Отчет по лидам парнеров с сайта]

delete from dbo.partner_lead 
insert into dbo.partner_lead
select *  from [#Отчет по лидам парнеров с сайта]
--order by [Дата создания лида] desc


commit tran
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'AC858B3B-2DD0-4F99-A53B-F44B5EDE1554'

--select * from dbo.[Отчет по лидам парнеров с сайта]
 --alter table [Отчет по лидам парнеров с сайта]  alter column [ID лида] nvarchar(36)
 --alter table [Отчет по лидам парнеров с сайта_retro]  alter column [ID лида] nvarchar(36)
end


if @mode= 'select' 
begin

select * from dbo.partner_lead
where  [Дата создания лида]>=getdate()-365
union all

select * from dbo.partner_lead_old
where  [Дата создания лида]>=getdate()-365

   end
   end

