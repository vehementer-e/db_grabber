--exec dbo.check_UMFO_Reserve

CREATE   procedure [dbo].[check_UMFO_Reserve]
as
begin


set nocount on

-- найдем последню дату предыдущего месяца
Declare @last_month as date
select @last_month = DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1) --Last Day of previous month
select @last_month

-- Новая витрина	[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]

drop table if exists #stg_umfo_new;
select 
a.ОтчетнаяДата as r_date
, a.номердоговора as external_id
, cast(a.днейпросрочки as float) as overdue_days_new
, cast(a.ОстатокОДвсего as float)+cast(a.ОстатокПроцентовВсего as float) as princ_perc_rest_new -- поле с ОД+%% для сравнения с витриной от расчётного модуля БУ
, cast(a.ОстатокОДвсего as float)+cast(a.ОстатокПроцентовВсего as float)+cast(a.ОстатокПени as float) as gross_new -- все остатки
, cast(a.ОстатокРезерв as float) as prov_bu_new --Объем резерва БУ
, case when (cast(a.ОстатокОДвсего as float)+cast(a.ОстатокПроцентовВсего as float)+cast(a.ОстатокПени as float)) > 0 then  
cast(a.ОстатокРезерв as float)/(cast(a.ОстатокОДвсего as float)+cast(a.ОстатокПроцентовВсего as float)+cast(a.ОстатокПени as float)) end as rate_bu_new --ставка резерва БУ
into #stg_umfo_new
from 
[Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных] as a
where 
a.ОтчетнаяДата = @last_month --'2021-04-30' 
--and cast(a.днейпросрочки as float)  = 0 
--and (cast(a.ОстатокОДвсего as float)+cast(a.ОстатокПроцентовВсего as float)+cast(a.ОстатокПени as float))>0 -- GROSS>0
--and a.номердоговора in ('20091300033067','19081900000125','20021810000167','18041622380001','18041916260001') -- примеры косячных договоров на всякий случай

;

-- То что сейчас в расчётном модуле Резервов БУ УМФО  
drop table if exists #stg_umfo_clc;
select cast(dateadd(yy,-2000,r_date) as date) as r_date,
			[НомерДоговора] as external_id,
		   cast([ДнейПросрочки] as float) as overdue_days_clc,
          sum(cast(isnull([СуммаОД],0) as float)+cast(isnull([СуммаПроценты],0) as float))         as princ_perc_rest_clc, -- поле с ОД+%%
          sum(cast(isnull([РезервОстатокОДПо],0) as float)+cast(isnull([РезервОстатокПроцентыПо],0) as float))        as prov_bu_clc, -- Резерв БУ по ОД и %% ВАЖНО! без резерва Пеней так что напрямую сравнивать с [prov_bu_new] нельзя
          case when sum(cast(isnull([СуммаОД],0) as float) +cast(isnull([СуммаПроценты],0)  as float)) > 0 then
			sum(cast(isnull([РезервОстатокОДПо],0) as float)+ cast(isnull([РезервОстатокПроцентыПо],0) as float)) /
			sum(cast(isnull([СуммаОД],0) as float) +cast(isnull([СуммаПроценты],0)  as float)) end  as rate_bu_clc -- Ставка резерва БУ
		  into #stg_umfo_clc
from (select dr.дата as r_date,dr.Комментарий,dr.типклиентов,d.НомерДоговора,d.Дата,d.суммазайма,r.*
      from [Stg].[_1cUMFO].[Документ_СЗД_ФормированиеРезервовБУ] dr 
      join [Stg].[_1cUMFO].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r on r.ссылка=dr.ссылка 
			and cast(dateadd(yy,-2000,dr.дата)as date) = @last_month
      join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный]  d on r.Займ=d.ссылка
	  ) a
	  /*where номердоговора in ('20091300033067','19081900000125','20021810000167','18041622380001','18041916260001')
	  --and [ДнейПросрочки] = 0*/
	  group by 
	  cast(dateadd(yy,-2000,r_date) as date) ,
			[НомерДоговора] ,
		 [ДнейПросрочки]
		--having sum(cast(isnull([СуммаОД],0) as float) + cast(isnull([СуммаПроценты],0) as float)) >0 --GROSS >0
		;


drop table if exists #t;
-- 1. самое простое сравнение ставок резерввов (до 90 дней просрочки таким способом сравнивать можно) -- можно даже такую DQ процедуру сделать
with t_new as ( 
select a.r_date
		, case when a.overdue_days_new between 61 and 90 then '61-90'
				when a.overdue_days_new between 31 and 60 then '31-60'
				when a.overdue_days_new between 1 and 30 then '1-30'
				when a.overdue_days_new = 0 then '0' end bucket_new
				, round(sum(a.prov_bu_new)/sum(a.gross_new),4) rate_bu_new_rnd
		from #stg_umfo_new a
		where a.overdue_days_new between 0 and 90
		group by a.r_date
		,case when a.overdue_days_new between 61 and 90 then '61-90'
				when a.overdue_days_new between 31 and 60 then '31-60'
				when a.overdue_days_new between 1 and 30 then '1-30'
				when a.overdue_days_new = 0 then '0' end 
				)

, t_clc as ( 
		select a.r_date
		, case when a.overdue_days_clc between 61 and 90 then '61-90'
				when a.overdue_days_clc between 31 and 60 then '31-60'
				when a.overdue_days_clc between 1 and 30 then '1-30'
				when a.overdue_days_clc = 0 then '0' end bucket_clc
				, round(sum(a.prov_bu_clc)/sum(a.princ_perc_rest_clc),4) rate_bu_rnd
		from #stg_umfo_clc a
		where a.overdue_days_clc between 0 and 90
		group by a.r_date
		,case when a.overdue_days_clc between 61 and 90 then '61-90'
				when a.overdue_days_clc between 31 and 60 then '31-60'
				when a.overdue_days_clc between 1 and 30 then '1-30'
				when a.overdue_days_clc = 0 then '0' end 
			)

		
select 
a.*
, b.rate_bu_new_rnd 
, round(a.rate_bu_rnd-b.rate_bu_new_rnd,4) as delta 
into #t
from
t_clc a left join t_new b on a.r_date = b.r_date and a.bucket_clc = b.bucket_new

DECLARE @tableHTML  NVARCHAR(MAX) = N'' ;  
  

    Declare @delta_sum float = 0


  Select @delta_sum = isnull(sum(delta),1) from #t

  select @delta_sum

  if @delta_sum <> 0
  begin
SET @tableHTML =  
    N'<H1>Расхождения УМФО по резервам на дату: ' + format(@last_month, 'yyyy-MM-dd') + N'</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>r_date</th><th>bucket_clc</th>' +  
    N'<th>rate_bu_rnd</th><th>rate_bu_new_rnd</th><th>delta</th>' +  
    N'</tr>' +  
    CAST ( ( SELECT td = r_date,       '',  
                    td = bucket_clc, '',  
                    td = format(rate_bu_rnd,'0.000000') , '',  
                    td =  format(rate_bu_new_rnd,'0.000000') , '',                      
                    td = format(delta,'0.000000') 
              from #t

order by bucket_clc
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML
  end
  --select format(rate_bu_rnd,'0.000000') from #t




  --- вторая проверка на дату на сегодня по количеству договоров на вчера

  Declare @cnt_b as float = 0
  Declare @cnt_a as float = 0

  select @cnt_b = isnull(count(*),1) from dbo.dm_CMRStatBalance_2 b where b.d = cast(dateadd(day,-1,Getdate()) as date) and dpd <> 0

  select @cnt_a = isnull(count(*),1) from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных] as a
where 
a.ОтчетнаяДата = cast(dateadd(day,-1,Getdate()) as date) and ДнейПросрочки <> 0

select @cnt_b, @cnt_a

if  100*abs((@cnt_b-@cnt_a)/(@cnt_b+@cnt_a)) > 1.0
Set  @tableHTML = @tableHTML + N'<BR><BR><b>Количество договоров без просрочки в УМФО и CMR на дату ' + format(cast(dateadd(day,-1,Getdate()) as date), 'yyyy-MM-dd') +  ' отличаются более чем на 1.0%. Количество договоров CMR и УМФО:' +  format(@cnt_b,'0') + '  ' + format(@cnt_a,'0') + N'</b>'



--

--drop table if exists #b
--drop table if exists #a

--  select * into #b from dbo.dm_CMRStatBalance_2 b where b.d = '2021-04-30' and dpd <>0

--  select * into #a from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных] as a
--where 
--DATEADD(YEAR,-2000,a.ДатаОтчета) = '2021-04-30'  and ДнейПросрочки <> 0

--select sum(ОстатокРезерв) from #b b full outer join  #a as a
--on b.external_id  = a.НомерДоговора 
--where  
--a.НомерДоговора is null or b.external_id is null
--end

select @tableHTML

  if @delta_sum <> 0  or  100*abs((@cnt_b-@cnt_a)/(@cnt_b+@cnt_a)) > 1.0
  begin
		EXEC msdb.dbo.sp_send_dbmail @recipients='kostenko@carmoney.ru; a.borisov@carmoney.ru; dwh112@carmoney.ru',  --; Krivotulov@carmoney.ru
			@profile_name = 'Default',  
			@subject = 'Расхождения УМФО по резервам',  
			@body = @tableHTML,  
			@body_format = 'HTML' ;  

  end

end
