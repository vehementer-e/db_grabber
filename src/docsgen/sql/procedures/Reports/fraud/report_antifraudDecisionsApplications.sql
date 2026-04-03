/*
BP-738
*/
CREATE   procedure [fraud].[report_antifraudDecisionsApplications]
	@dtFrom  date = null
	,@dtTo date	  = null
	with recompile
as
declare @dtFrom2 datetime2(0), @dtTo2 datetime2(0)
select  @dtFrom2= isnull(@dtFrom,  dateadd(dd,1, eomonth(getdate(), -2)))
	, @dtTo2 = dateadd(dd,1,isnull(@dtTo, cast(getdate() as date)))

select
	 t.GuidЗаявки
	,[дата заявки]			= t.ДатаЗаявки
	,[номер заявки]			= t.НомерЗаявки 
	,[Продукт]				= t.ТипКредитногоПродукта
	,[запрошенная сумма]	= t.СуммаЗаявки
	,[одобренная сумма]		= nullif(t.ОдобреннаяСумма,0)
	,[сумма займа]			= nullif(t.ВыданнаяСумма, 0)
	,[Статус Заявки]		= t.СтатусЗаявки
	,[Дата Статуса]			= t.ДатаСтатуса
	,[причина отказа]		= t.ПричинаОтказа
	,Кодификатор			= nullif(ПричиныОтказов_Заявка.Кодификатор,'')
	,loginomClassificationReason4Refusal
	,loginomClassificationReason4RefusalLeve2 = loginom_reason.[Classification level 2]
	into #t_result
	from dwh2.dm.ЗаявкаНаЗаймПодПТС t with(index = [ix_ДатаЗаявки])
	left join dwh2.[link].[v_ПричиныОтказов_Заявка] ПричиныОтказов_Заявка
		on ПричиныОтказов_Заявка.GuidЗаявки = t.GuidЗаявки
	left join (
			select 
				r.reasonCode,
				r.[Classification level 1],
				r.[Classification level 2],
				rn = row_number() over (
					partition by r.reasonCode
					order by r.row_ver desc
				)
			from Stg._loginom.Origination_dict_reason_codes as r
			where r.reasonCode is not null
				and r.[Classification level 1] is not null
		) as loginom_reason
		on loginom_reason.reasonCode = ПричиныОтказов_Заявка.Кодификатор
		and loginom_reason.rn = 1
	where t.ДатаЗаявки between @dtFrom2 and @dtTo2
	--	 and t.НомерЗаявки   = '25102303811710'


create clustered index  cix on  #t_result(GuidЗаявки)
create index ix_Кодификатор on 	  #t_result(Кодификатор)  include([номер заявки])
;with cte as (
select 
	t.[номер заявки]
	, finsert_passport_fl
	, finsert_mobile_number_fl
	, finsert_inn_fl
	, finsert_fastpay_number_fl 
	, finsert_card_fl 
	,rn = row_number() over (
					partition by ol.Number
					order by ol.rowver desc
				)
	from #t_result t
	inner join  stg._loginom.originationlog ol
		on ol.Number = t.[номер заявки]
			and ol.Decision_Code = t.Кодификатор
where  t.Кодификатор = '100.0071.002'
	) 
select 
	 t.[номер заявки]
	,finsert_Refusal = CONCAT_WS('; '
		,iif(t.finsert_passport_fl = 1, 'Паспорт', null)
		,iif(t.finsert_mobile_number_fl = 1, 'Телефон', null)
		,iif(t.finsert_inn_fl = 1, 'ИНН', null)
		,iif(t.finsert_fastpay_number_fl = 1, 'СБП', null)
		,iif(t.finsert_card_fl = 1, 'Карта', null)
	)
into #t_originationlog
from cte t
where t.rn = 1
create clustered index cix on #t_originationlog ([номер заявки])
 select 
	    t.GuidЗаявки
	   ,t.[дата заявки]			
	   ,t.[номер заявки]			
	   ,t.[Продукт]				
	   ,t.[запрошенная сумма]	
	   ,t.[одобренная сумма]		
	   ,t.[сумма займа]			
	   ,t.[Статус Заявки]		
	   ,t.[Дата Статуса]			
	   ,t.[причина отказа]		
	   ,t.Кодификатор		
	   ,t.loginomClassificationReason4Refusal
	   ,loginomClassificationReason4RefusalLeve2 
		= loginomClassificationReason4RefusalLeve2 + isnull('-' + finsert_Refusal, '')
		

from #t_result	  t
left join #t_originationlog	originationlog
	on originationlog.[номер заявки] = t.[номер заявки]
	order by [дата заявки]

	