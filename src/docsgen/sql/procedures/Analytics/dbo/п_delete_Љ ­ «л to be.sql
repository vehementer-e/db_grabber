

create   proc dbo.[Каналы to be]

as

begin

drop table if exists #Документ_ЗаявкаНаЗаймПодПТС
select * into #Документ_ЗаявкаНаЗаймПодПТС
from
stg.[_1cCRM].Документ_ЗаявкаНаЗаймПодПТС    
drop table if exists #Перечисление_СпособыОформленияЗаявок
select * into #Перечисление_СпособыОформленияЗаявок
from
stg.[_1cCRM].Перечисление_СпособыОформленияЗаявок
drop table if exists #leadRef2_buffer
select * into #leadRef2_buffer
from
stg.files.leadRef2_buffer                      
drop table if exists #ChannelRequestExceptions_prod
select * into #ChannelRequestExceptions_prod
from
stg._mds.ChannelRequestExceptions_prod 


exec message 'Шаг 1'


drop table if exists #t

select id 
, UF_ROW_ID
, UF_APPMECA_TRACKER
	,      r2.[Тип-Источник]                                                                                                                                                                                                                                                      
	,     CPA= case 
			--BP-1884
			when nullif(crq.Канал_от_источника,'') is not null then crq.Канал_от_источника
			when uf_name like N'%тест%'
				or uf_name like N'%test%'
				or uf_source like N'%test%' then N'Тест'
	           --	when UF_TYPE like N'%investicii%' then N'Инвестиции'
						else r2.[Канал от источника] --end 
			end                                                                                                                                                               
	
	,      cpc=
	analytics.dbo.CalculateCPC (UF_STAT_CAMPAIGN,UF_APPMECA_TRACKER,UF_STAT_SOURCE,UF_STAT_AD_TYPE )                                                                                                                                                                                      

	,  Партнеры = analytics.dbo.[CalculatePartner] (UF_STAT_AD_TYPE, UF_TYPE)

	,      Органика = analytics.dbo.CalculateOrganic(UF_APPMECA_TRACKER, UF_STAT_CLIENT_ID_YA, UF_STAT_CLIENT_ID_GA, UF_TYPE)

	,      CASE when isnull( cast(f.UF_ROW_ID as nvarchar(1024)),'')<>'' then case when Spr.Представление in (N'Ввод операторами FEDOR', N'Ввод операторами LCRM',N'Ввод операторами стороннего КЦ',N'Ввод операторами КЦ') then N'Канал привлечения не определен - КЦ'
		                                                                                                                                                                                                                    else case when Spr.Представление in (N'Оформление на клиентском сайте',N'Оформление в мобильном приложении') then N'Канал привлечения не определен - МП'
			                                                                                                                                                                                                                                                                                                                             else case when Spr.Представление in (N'Оформление на партнерском сайте') then N'Оформление на партнерском сайте'
				                                                                                                                                                                                                                                                                                                                                                                                                  ELSE CASE WHEN cast( UF_TYPE as nvarchar(68)) in (N'registry_mobile_app',N'registry_lkk',N'mobile_register',N'mfo_mobile_app') then N'Канал привлечения не определен - МП'
					                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           else N'Канал привлечения не определен - КЦ' end end end end
	                                                                     else case when isnull( cast(f.UF_ROW_ID as nvarchar(1024)),'')='' then CASE WHEN cast( UF_TYPE as nvarchar(68)) in (N'registry_mobile_app',N'registry_lkk',N'mobile_register',N'mfo_mobile_app') then N'Канал привлечения не определен - МП'
			                                                                                                                                                                                                                                            else N'Канал привлечения не определен - КЦ' end end end Остальные1

	,      Spr.Представление                                                                                                                                                                                                                                                      
		into #t
	from      v_leads                           f  
	LEFT JOIN #Документ_ЗаявкаНаЗаймПодПТС          Z   ON cast(f.UF_ROW_ID as nvarchar(28))=Z.Номер
	LEFT JOIN #Перечисление_СпособыОформленияЗаявок Spr ON Z.СпособОформления=Spr.Ссылка
	left join #leadRef2_buffer                             r2  on r2.[Тип-Источник] = case 
			when isnull( cast(f.UF_TYPE as nvarchar(1024)),'')='' 
				then cast(f.UF_SOURCE as nvarchar(1024))
				else cast(f.UF_TYPE as nvarchar(1024))+' - '+ cast(f.UF_SOURCE as nvarchar(1024)) 
			end
	left join #ChannelRequestExceptions_prod  crq on crq.external_id = cast(f.UF_ROW_ID as nvarchar(28))


exec message 'Шаг 2'


	drop table if exists #t1

	select *                                                                                                                        
	,      [Канал от источника]=case when CPA is not null then CPA
	                                 when CPC is not null then CPC
		                             when Партнеры is not null then Партнеры
			                         when UF_APPMECA_TRACKER like N'CPA_Mobishark%'  or UF_APPMECA_TRACKER like N'AutocreatedAppleSearchCampaign%'  or UF_APPMECA_TRACKER = N'CPA_Admitad_CarMoney'
									                                                           then 'CPA целевой'
					                 when Органика is not null then Органика
					                 when Остальные1 is not null then Остальные1
                                     else N'Канал привлечения не определен - КЦ' end

		into #t1
	from #t


	drop table if exists #result

	select  f.id, f.UF_ROW_ID                
	,               r1.[Канал от источника]
	,               r1.[Группа каналов]
		into #result
	from      #t1 f 
	left join stg.files.leadRef1_buffer    r1 on f.[Канал от источника]=r1.[Канал от источника]


exec message 'Шаг 3'

	drop table if exists #final


	select 
      a.[Канал от источника] [Канал от источника_to_be]
	, a.[Группа каналов] [Группа каналов_to_be] 
	, a.id
	, a.UF_ROW_ID
	
	into #final 
	
	from #result a 
	left join v_leads b on a.id=b.id

	where a.[Канал от источника]<>b.[Канал от источника]

exec message 'Шаг 4'


		drop table if exists Analytics.dbo.[Каналы ЛСРМ по новой методологии]
	select *  into Analytics.dbo.[Каналы ЛСРМ по новой методологии] from (
	select *, ROW_NUMBER() over( partition by UF_ROW_ID order by (select 1))  rn 
	from #final
	) x

	where rn=1
	select * from Analytics.dbo.[Каналы ЛСРМ по новой методологии]

	select * from Analytics.dbo.[Каналы ЛСРМ по новой методологии]


end


