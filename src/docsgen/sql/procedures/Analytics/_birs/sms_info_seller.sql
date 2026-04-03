CREATE     proc [_birs].[sms_info_seller]
as
begin

drop table if exists #call
select НомерЗаявки, ФИО_оператора, ДатаВремяВзаимодействия , Результат into #call from v_communication_crm
where ( ПоддеталиОбращения in ('SMS информирование - Жалоба/обращение', 'SMS информирование - Консультация' , 'SMS информирование - Отключение')
or типобращения= 'Продажа комиссии' )
and   ФИО_оператора<>'<Не указан>'
and   Результат<>'Недозвон'


drop table if exists #report

select
v.[Код договора "Комиссии"] [Код займа],
format(v.[дата оплаты],'yyyy-MM-dd HH:mm:ss') [Дата оплаты СМС информирования],
v.[cумма услуги] [Сумма оплаты],
ДатаВремяВзаимодействия ДатаВремяВзаимодействия,
ФИО_оператора [Сотрудник],
e.Направление Направление,
format(c.ДатаВремяВзаимодействия, 'yyyy-MM-dd HH:mm')+' -> '+ФИО_оператора+ case when e.Направление is not null then  ' ('+e.Направление+')' else '' end+' -> '+Результат seller_info,
row_number() over(partition BY [Код договора "Комиссии"] ORDER BY ДатаВремяВзаимодействия desc) num		  ,
max(case when datediff(second, ДатаВремяВзаимодействия, [дата оплаты]     ) <=3*24*60*60 then 1 else 0 end) over(partition BY [Код договора "Комиссии"]) [Оплата в течение 3 дней]
into #report
from v_comissions_sales v
left join #call c on v.[Код договора "Комиссии"] = c.НомерЗаявки and v.[дата оплаты]>=ДатаВремяВзаимодействия
left join employees e on e.Сотрудник=c.ФИО_оператора
where оплачено = 'СМС информирование' 
and DATEDIFF(ss, ДатаВремяВзаимодействия,v.[дата оплаты])<2592000


select a.[Код займа], a.[Дата оплаты СМС информирования], a.[Сумма оплаты] , a.Сотрудник , a.[Оплата в течение 3 дней] , b.sellers_info from #report	a
left join (

 select  [Код займа], STRING_AGG(seller_info, '
') within group(order by ДатаВремяВзаимодействия desc)   sellers_info from #report

   group by [Код займа]
) b on a.[Код займа]=b.[Код займа]
where a.num = 1
order by a.[Дата оплаты СМС информирования] desc

end