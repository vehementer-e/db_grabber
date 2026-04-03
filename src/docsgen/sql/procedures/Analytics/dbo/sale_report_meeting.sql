create     proc sales_meeting

@now_date_ssrs date = null

as
begin



declare @now_date date = cast(@now_date_ssrs as date);





with kd as 
(
select distinct [Заявка] from  [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] with(nolock) where Статус= 0xA81400155D94190011E80784923C609A)

,
 meetings_w_rn_2 as (
SELECT
             m.[Ссылка]
      ,dateadd(year, -2000, cast(format(m.Дата, 'yyyy-MM-ddTHH:mm:00') as datetime)) ДатаВстречи
      ,dateadd(year, -2000, cast(format(m.ДатаПоВремениКлиента, 'yyyy-MM-ddTHH:mm:00') as datetime)) ДатаВстречиПоВРемениКлиента
	  ,z.МобильныйТелефон Телефон
	  ,z.Номер НомерЗаявки
	  ,z.Фамилия+' '+z.Имя+' '+z.Отчество ФИО
	  ,stcurrent.Наименование [Текущий статус]
	  ,z.Сумма [Сумма заявки]
      ,m.[Номер]
	  ,m.место
	  ,year(z.ГодВыпуска)-2000 Год
	  ,tr.наименование Модель
	  ,ma.наименование Марка
	  ,kd.Заявка ЗаявкаСКД
	  ,office.Наименование ПартнерИзЗаявки
	  ,dateadd(year, -2000, z.Дата) ДатаЗаявки
	  ,ROW_NUMBER() over(partition by z.Номер order by ДатаМодификации desc) rn
	  ,max(m.DWHInsertedDate) over() [Дата обновления отчета] 
        FROM [Stg].[_1cCRM].[Документ_CRM_Мероприятие] m (nolock)
		left join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие]  v (nolock) on  m.[ВзаимодействиеОснование]=v.[Ссылка]  
		left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z (nolock) on  v.[Заявка_Ссылка]=z.[Ссылка] 
		left join stg._1cCRM.Справочник_МоделиАвтомобилей tr with(nolock) on z.Модель=tr.Ссылка
		left join stg._1cCRM.Справочник_МаркиАвтомобилей ma with(nolock) on z.МаркаМашины=ma.Ссылка
	    left join kd on kd.Заявка=v.Заявка_Ссылка
		left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] stcurrent with (nolock) on stcurrent.Ссылка = z.Статус
		left join stg._1cCRM.Справочник_Офисы office with(nolock) on office.Ссылка=z.офис

		where m.ПометкаУдаления=0 and year(m.ДатаПоВремениКлиента)>4000
		) 

		select  
		ТочнаяДатаВстречи               = ДатаВстречи, 
		ДатаВстречиЧасы                 = format(ДатаВстречи, 'HH:00:00'), 
		ДатаВстречиПоВРемениКлиента     = format(ДатаВстречиПоВРемениКлиента, 'HH:mm:ss'),
		Офис                            = ПартнерИзЗаявки ,
		КолвоВстреч                     = 1 , 
		ВстречСостоялось                = case when ЗаявкаСКД is not null then 1 else 0 end, 
		ТекущийСтатус                   = [Текущий статус] , 
		НомерЗаявки                     = НомерЗаявки, 
		Телефон                         = Телефон, 
		ФИО                             = ФИО,
		[СуммаЗаявки]                   = [Сумма заявки],
		Год                             = Год,
		Марка                           = Марка,
		Модель                          = Модель,
		[Дата обновления отчета]                          = [Дата обновления отчета]

		
		from meetings_w_rn_2

where 
		cast(ДатаВстречи as date)=@now_date and rn=1

end