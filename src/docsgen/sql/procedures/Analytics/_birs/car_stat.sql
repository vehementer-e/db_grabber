--664e43e10338
CREATE    proc [_birs].[car_stat]
as
begin

 ;
 with v as (

 select *  
 , case 
 when  a.Аннулировано <a.[Заем аннулирован] then  a.Аннулировано  
 when  a.[Заем аннулирован] <a.Аннулировано then  a.[Заем аннулирован]  
 else isnull(  a.[Заем аннулирован] , a.Аннулировано) end Аннулировано2
 
 
  
 from v_fa a 

 )

select a.call1 вкц, a.number номер
, a.channel_group [Группа каналов]
, a.channel [канал от источника]
, a.source источник
, a.origin [место создания]
, a.product
, a.status	Статус	 
, a.status2	   СтатусРасширенный
, a.loan_type3 	 ВидЗайма
, b.забираемПТС
, decline ПричинаОтказа
,	case
  when a.Отказано> a.[Контроль данных] then 'Отказ после КД'
 when  a.Отказано> a.[Верификация КЦ] then 'Отказ до КД'	  
 when  a.Отказано is not null  then 'Отказ ??'	  
 end Период_Отказа
, case 																					 
when  a.decline like '%(по клиенту)%'	 then 'Отказ по клиенту'
when  a.decline='Автоматический отказ (по авто) '	 then'Отказ по авто'
when  a.decline='UW. Залог не соответствует требованиям по продукту'	 then'Отказ по авто'
when  a.decline	 in 
 ('CH. Авто не подходит под условия займа'
,'CH. Клиент не собственник авто'
,'UW. Авто было в тотале'
,'UW. Фото авто - залог не соответствует требованиям по продукту '
,'UW. Фото авто - залог прочий негатив'
,'CH. Некорректный VIN, номер кузова в ПТС'
,'CH. ПТС взамен утраченного/утерянного менее 45 дней назад'
,'CH. ТС категории А, прицеп'
,'UW. Залог не соответствует требованиям по продуктам'
,'UW. Залог не соответствует требованиям по продукту'		  )  then'Отказ по авто'

when a.declined is not null and  a.decline like '%авто%'   		 then 'Отказ по авто'
when a.declined is not null	  then  'Отказ по клиенту'
   else ''
end   	 [тип отказа]	 
, case 
when a.approved is not null then 'Одобрено'
when a.отказано is not null and a.[контроль данных] is not null then 'Отказано После КД'
when a.отказано is not null and a.[контроль данных] is   null then 'Отказано до КД'
when a.[контроль данных] is not null    then 'Застрял'
when a.[контроль данных] is   null    then 'Недоезд'
end [тип клиента]


, b.VIN
, b.[ВозрастНаДатуЗаявки] Возраст
, a.Аннулировано2 Аннулировано
, isCarVerified
, sp.Наименование фио_лицо_аннул 

, pa.Наименование  ПричинаАннуляции
, pr.next_request_other_product_after_annul ВКЦ_по_другому_продукту_номер
, pr.next_request_other_product_after_annul_dt ВКЦ_по_другому_продукту_дата
, case when pr.next_request_other_product_after_annul_dt between a.Аннулировано2 and dateadd(hour, 24, a.Аннулировано2 ) and an.Заявка is not null then 'ВКЦ по другому продукту день после аннуляции'else '' end результат_аннуляции
, case when a.Отказано is not null then 1 else 0 end [признак отказанао]
, case when a.Одобрено is not null then 1 else 0 end [признак одобрено]



, b. vin 
, b.ГодТС													    		 
,  trim(b.МаркаТС)  МаркаТС
,  trim(b.МодельТС)МодельТС
, nullif(b1.[РыночнаяОценкаСтоимости], 0) market_price
, avg(nullif(b1.[РыночнаяОценкаСтоимости], 0 )) over(partition by   b.МаркаТС+' ' + b.МодельТС +format(b.ГодТС, '0') ) model_avg_market_price
, trim(b.МаркаТС)+' ' +  trim(b.МодельТС)   МаркаМодельТС


, a.issuedSum sum
, a.isLoan is_loan

--, c.type check_list
--, c.status cobalt_status
from v	  a
left join v_request b on a.number=b.number
left join v_request_crm b1 on a.number=b1.number
left join crm_РегистрСведений_РезультатыАннуляцииЗаявок an on  an.заявка=b.ссылка 
left join crm_Справочник_ПричиныАннуляции pa on  pa.Ссылка = an.ПричинаАннуляции
left join stg._1cCRM.СПравочник_пользователи sp on  sp.ссылка = an.Пользователь
left join _birs.product_report_request pr on pr.num_1c=a.number
--left join v_checklist c on a.number=c.number	 and c.is_cobalt=1

where a.created2>='20240301'					 and a.isPts=1
--and a.[Предварительное одобрение] is not null
and a.Дубль=0
--and a.number='24080802307961'
 

order by 1  
return 
--order by dbo.to_md5( vin, 1) desc, 1 


select a.status_order
, a.status
, count(case when  b.ОценочнаяСтоимостьТС >0 then 1 end) has_price
, count( a.created  ) price
,count(case when  b.ОценочнаяСтоимостьТС >0 then 1 end) / (0.0+ count( a.created  )) percent_has_price


from v_fa	  a
left join v_request b on a.number=b.number
where a.created2>='20240301'					 and a.isPts=1
and a.[Предварительное одобрение] is not null
and a.Дубль=0
group by  a.status_order
, a.status
order by 1 desc
--order by dbo.to_md5( vin, 1) desc, 1 

  end
