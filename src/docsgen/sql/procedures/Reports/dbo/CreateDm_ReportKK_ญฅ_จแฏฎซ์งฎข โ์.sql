

CREATE   procedure [dbo].[CreateDm_ReportKK_не_использовать]
as

begin

set nocount on

--dwh-598


 drop table if exists #t1
 select a.Ссылка as СсылкаНаПараметрЗаявления, 
        b.Наименование  ПараметрЗаявления, 
		Значение_Строка ЗначениеПараметраЗаявления,  
		Значение_Дата ДатаПараметраЗаявления, 
		[Значение_Ссылка] СсылкаНаДетальныйПарметр, 
		c.Наименование as НаименованияЗначенияПараметраДетальное 
 into #t1
 from stg.[_1cDCMNT].[Справочник_ВнутренниеДокументы_ДополнительныеРеквизиты] a  join  stg.[_1cDCMNT].[ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения] b on a.Свойство=b.ссылка
 left join stg.[_1cDCMNT].[Справочник_ЗначенияСвойствОбъектов] c on a.[Значение_Ссылка]=c.ссылка


 --select * from #t1

 drop table if exists #kk2

 select 
 count(nomer_dogovora.ЗначениеПараметраЗаявления) over (partition by nomer_dogovora.ЗначениеПараметраЗаявления) counts,  
 dogovor.ПараметрЗаявления,
 nomer_dogovora.ЗначениеПараметраЗаявления as НомерДоговора, 
 data_zayav.ДатаПараметраЗаявления ДатаЗаявки, 
 status_zayav.НаименованияЗначенияПараметраДетальное as  СтатусЗаявки,
 data_nach_kk.ДатаПараметраЗаявления as ДатаНачалаКК,
 zapr_tip_kk.НаименованияЗначенияПараметраДетальное as ЗапрашиваемыйТипКК,
 srok_kk.НаименованияЗначенияПараметраДетальное as СрокКК,
 sogl_tip_kk.НаименованияЗначенияПараметраДетальное as СогласованныйТипКК,
 prich_otk_kk.НаименованияЗначенияПараметраДетальное as ПричинаОтказаПоКК,
 zapr_doc_kk.СсылкаНаДетальныйПарметр as ЗапрашиватьДокументы,
 zayav_kk.СсылкаНаДетальныйПарметр as ЗаявлениеНаКК,
 birja_kk.СсылкаНаДетальныйПарметр as СправкаСБиржиТруда,
 ndfl_kk.СсылкаНаДетальныйПарметр as [2_НДФЛ],
 boln_list_kk.СсылкаНаДетальныйПарметр as БольничныйЛист,
 vipiska_po_sch_kk.СсылкаНаДетальныйПарметр as ВыпискаПоСчету,
 inoe_kk.СсылкаНаДетальныйПарметр ПризнакНаличияИногоПараметра,
 inoe_kk.НаименованияЗначенияПараметраДетальное ЗначениеИногоПараметра
 -------------------могут быть дубли по номеру заявки, оставляем ту что не в статусе на рассмотрение)
 into #kk2

 from #t1 dogovor
 left join #t1 nomer_dogovora on dogovor.СсылкаНаДетальныйПарметр=nomer_dogovora.СсылкаНаПараметрЗаявления and nomer_dogovora.ПараметрЗаявления='Номер заявки (Заем)'
 left join #t1 data_zayav on dogovor.СсылкаНаПараметрЗаявления=data_zayav.СсылкаНаПараметрЗаявления and data_zayav.ПараметрЗаявления='Дата заявления (Заявление на кредитные каникулы)'
 left join #t1 status_zayav on dogovor.СсылкаНаПараметрЗаявления=status_zayav.СсылкаНаПараметрЗаявления and status_zayav.ПараметрЗаявления='Статус заявления (Заявление на кредитные каникулы)'
 left join #t1 data_nach_kk on dogovor.СсылкаНаПараметрЗаявления=data_nach_kk.СсылкаНаПараметрЗаявления and data_nach_kk.ПараметрЗаявления='Дата начала кредитных каникул (Заявление на кредитные каникулы)'
 left join #t1 zapr_tip_kk on dogovor.СсылкаНаПараметрЗаявления=zapr_tip_kk.СсылкаНаПараметрЗаявления and zapr_tip_kk.ПараметрЗаявления='Запрашиваемый тип кредитных каникул (Заявление на кредитные каникулы)'
 left join #t1 srok_kk on dogovor.СсылкаНаПараметрЗаявления=srok_kk.СсылкаНаПараметрЗаявления and srok_kk.ПараметрЗаявления='Срок кредитных каникул (Заявление на кредитные каникулы)'
 left join #t1 sogl_tip_kk on dogovor.СсылкаНаПараметрЗаявления=sogl_tip_kk.СсылкаНаПараметрЗаявления and sogl_tip_kk.ПараметрЗаявления='Согласованный тип кредитных каникул (Заявление на кредитные каникулы)'
 left join #t1 prich_otk_kk on dogovor.СсылкаНаПараметрЗаявления=prich_otk_kk.СсылкаНаПараметрЗаявления and prich_otk_kk.ПараметрЗаявления='Причины отказа (Заявление на кредитные каникулы)'
 left join #t1 zapr_doc_kk on dogovor.СсылкаНаПараметрЗаявления=zapr_doc_kk.СсылкаНаПараметрЗаявления and zapr_doc_kk.ПараметрЗаявления='Запрашивать документы: (Заявление на кредитные каникулы)'
 left join #t1 zayav_kk on dogovor.СсылкаНаПараметрЗаявления=zayav_kk.СсылкаНаПараметрЗаявления and zayav_kk.ПараметрЗаявления='Заявление (Заявление на кредитные каникулы)'
 left join #t1 birja_kk on dogovor.СсылкаНаПараметрЗаявления=birja_kk.СсылкаНаПараметрЗаявления and birja_kk.ПараметрЗаявления='Справка с биржи труда (Заявление на кредитные каникулы)'
 left join #t1 ndfl_kk on dogovor.СсылкаНаПараметрЗаявления=ndfl_kk.СсылкаНаПараметрЗаявления and ndfl_kk.ПараметрЗаявления='2 НДФЛ (Заявление на кредитные каникулы)'
 left join #t1 boln_list_kk on dogovor.СсылкаНаПараметрЗаявления=boln_list_kk.СсылкаНаПараметрЗаявления and boln_list_kk.ПараметрЗаявления='Больничный лист (Заявление на кредитные каникулы)'
 left join #t1 vipiska_po_sch_kk on dogovor.СсылкаНаПараметрЗаявления=vipiska_po_sch_kk.СсылкаНаПараметрЗаявления and vipiska_po_sch_kk.ПараметрЗаявления='Выписка по счету (Заявление на кредитные каникулы)'
 left join #t1 inoe_kk on dogovor.СсылкаНаПараметрЗаявления=inoe_kk.СсылкаНаПараметрЗаявления and inoe_kk.ПараметрЗаявления='Иное (Заявление на кредитные каникулы)'

 where dogovor.ПараметрЗаявления='Договор клиента (Заявление на кредитные каникулы)'
--select * from #kk2

--select * from stg._1ccmr.РегистрСведений_ПараметрыДоговора 


  drop table if exists #max_dpd

  select Договор
       , max(КоличествоПолныхДнейПросрочкиУМФО) dpd
    into #max_dpd
    from stg._1ccmr.РегистрСведений_АналитическиеПоказателиМФО r
   group by Договор

--select * from stg._1ccmr.РегистрСведений_ПараметрыДоговора

--- первая запись в параметрах договора 
  drop table if exists #ContractsParametersFirstRecord

  ;
  with t as (
  select Договор
       , min(Период) mp 
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора rspd
    join stg._1ccmr.Справочник_Договоры d on d.Ссылка=rspd.Договор
   where case when isnull(rspd.ПроцентнаяСтавка,'0.0')=0.0 then НачисляемыеПроценты else rspd.ПроцентнаяСтавка end>0
   group by Договор
  ) 
  select pd.Договор
       , dateadd(year,-2000,ДатаОкончания) ДатаОкончания
       , case when isnull(ПроцентнаяСтавка,'0.0')=0.0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПроцентнаяСтавка
    into #ContractsParametersFirstRecord
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора pd join t on t.Договор=pd.Договор and t.mp=pd.Период

--select * from #ContractsParametersFirstRecord


-- первая запись в параметрах договора после кредитных каникул
  drop table if exists #ContractsParametersAfterKK

  ;
  with t as (
  select Договор
       , min(Период) mp 
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора rspd
    join stg._1ccmr.Справочник_Договоры d on d.Ссылка=rspd.Договор
    join #kk2 kk on kk.НомерДоговора=d.Код
   where Период>=kk.ДатаНачалаКК
   group by Договор
  ) 
  select pd.Договор
       , dateadd(year,-2000,ДатаОкончания) ДатаОкончания, case when isnull(ПроцентнаяСтавка,'0.0')=0.0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПроцентнаяСтавка
    into #ContractsParametersAfterKK
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора pd join t on t.Договор=pd.Договор and t.mp=pd.Период

--select * from #ContractsParametersAfterKK

-- последняя запись в параметрах перед датой кредитных каникул
  drop table if exists #ContractsParametersBeforeKK

  ;
  with t as (
  select Договор
       , max(Период) mp 
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора rspd
    join stg._1ccmr.Справочник_Договоры d on d.Ссылка=rspd.Договор
    join #kk2 kk on kk.НомерДоговора=d.Код
   where Период<kk.ДатаНачалаКК
   group by Договор
  ) 
  select pd.Договор
       , dateadd(year,-2000,ДатаОкончания) ДатаОкончания, case when isnull(ПроцентнаяСтавка,'0.0')=0.0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПроцентнаяСтавка
    into #ContractsParametersBeforeKK
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора pd join t on t.Договор=pd.Договор and t.mp=pd.Период

--select * from #ContractsParametersBeforeKK

-- поледняя запись в параметрах договора
  drop table if exists #ContractEndDates

  ;
  with t as(
  select Договор
       , max(Период) mp 
    from stg._1ccmr.РегистрСведений_ПараметрыДоговора
   group by Договор
   )
   select pd.Договор
        , dateadd(year,-2000,ДатаОкончания) ДатаОкончания, case when isnull(ПроцентнаяСтавка,'0.0')=0.0 then НачисляемыеПроценты else ПроцентнаяСтавка end ПроцентнаяСтавка
     into #ContractEndDates
     from stg._1ccmr.РегистрСведений_ПараметрыДоговора pd join t on t.Договор=pd.Договор and t.mp=pd.Период


    drop table if exists #payments
    
    select d.Код Number
         , p.Сумма summ
         , dateadd(year,-2000,p.Дата) Дата
    into #payments
    from stg._1cCMR.[документ_платеж] p
    join stg._1cCMR.Справочник_Договоры d on d.ссылка= p.Договор


     -- регистр целиком
  drop table if exists #payment_scheldue
  ;
  with max_registrator as ( 
  select g.Договор
       , max(dd.Дата) max_p
    FROM [stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей] g
    join stg._1cCMR.Документ_графикПлатежей dd on dd.ссылка=g.регистратор
   group by g.Договор
  )
 select g.Договор
      , d.Код
      , g.ДатаПлатежа
      , g.СуммаПлатежа
      , dd.Дата 
      , регистратор
      , НомерСтроки
   into #payment_scheldue
   FROM stg._1cCMR.[РегистрСведений_ДанныеГрафикаПлатежей] g
   join stg._1cCMR.Документ_графикПлатежей dd on dd.ссылка=g.регистратор
   join stg._1cCMR.Справочник_Договоры d on g.Договор=d.Ссылка
   join max_registrator mr on mr.ДОГОВОР=g.ДОГОВОР and dd.Дата =mr.max_p
  where d.ПометкаУдаления <>0x01
  
  
  drop table if exists  #next_payment_date
   SELECT Договор
        , min(ДатаПлатежа) mn_dt
        , min_p=max(Дата)
       
        into  #next_payment_date
     FROM #payment_scheldue
    where ДатаПлатежа>=dateadd(year,2000,cast(getdate() as date)) and СуммаПлатежа<>0.00
    --and Код='19051410260002'
    group by Договор

    
  drop table if exists #nearest_payment
  
  SELECT Код
       , ДатаПлатежа
       , СуммаПлатежа
       , ps.регистратор
       , ps.НомерСтроки
    into #nearest_payment
    FROM #payment_scheldue ps
    join #next_payment_date npd on npd.Договор=ps.Договор and npd.mn_dt=ps.ДатаПлатежа

drop table if exists #c_end_date
select distinct external_id, max(contractenddate) contractenddate into #c_end_date
from [dbo].[dm_CMRStatBalance_2] cmr
group by external_id
  
  --drop table if exists dbo.Dm_ReportKK
  --DWH-1764 
  TRUNCATE TABLE dbo.Dm_ReportKK
 -- select * from dbo.Dm_ReportKK

 INSERT dbo.Dm_ReportKK
 (
     [Договор номер],
     [Номер заявки],
     [Ссылка на договор],
     [Гуид клиента],
     [_LK client_id],
     [Space customer id],
     [Дата начала договора],
     [Срок договора],
     [Сумма договора],
     [Дата закрытия договора],
     #c_end_date,
     [Ближайшая дата платежа],
     [Сумма поступлений по договору на сегодня],
     [Ссылка на последнйи график платежа],
     [Ссылка на платеж в рамках графика платежей],
     [Сумма ближайшего платежа],
     max_dpd,
     [dpd на сегодня],
     [бакет на сегодня],
     [Остаток ОД на сегодня],
     [Остаток % на сегодня],
     [dpd на дату заявления по КК],
     [Остаток ОД на дату заявления по КК],
     [Остаток % на дату заявления по КК],
     [Сумма выплат от даты старта КК до сегодня],
     [Сумма выплат от сегодня-30дней до сегодня],
     [Сумма выплат от сегодня-60дней до сегодня],
     [Сумма выплат от сегодня-90дней до сегодня],
     [Дата завления на КК],
     [Статус заявления на КК],
     [Причина отказа по КК],
     [Подключенная услуга по договору],
     [Дата начала КК],
     [Дата окончания КК],
     [Ссылка на перенос даты платежа],
     [Флаг был перенос даты платежа],
     [Дата переноса платежа],
     [Старая дата платежа],
     [Новая дата платежа],
     [дата окончания договора - до начала кредитных каникул],
     [дата окончания договора - после старта кредитных каникул],
     [дата окончания договора - самая первая],
     [Проц ставка - до начала кредитных каникул],
     [Проц ставка - после старта кредитных каникул],
     [Проц ставка - самая первая],
     [Планируемая дата окончания договора],
     [самая первая дата окончания договора],
     [Проц ставка открытия],
     [Проц ставка текущая],
     [Флаг снижение процентной ставки по КК],
     [Дельта проц ставки],
     created
 )
  select [Договор номер]                                                                = cmr_d.Код
       , [Номер заявки]                                                                 = cr.CRMRequestNumber
       , [Ссылка на договор]                                                            = cmr_d.Ссылка
       , [Гуид клиента]                                                                 = cr.CRMClientGUID
       , [_LK client_id]                                                                = lk_c.user_id
       , [Space customer id]                                                            = coll_cust.id
       , [Дата начала договора]                                                         = dateadd(year,-2000,cmr_d.Дата)
       , [Срок договора]                                                                = cmr_d.Срок
       , [Сумма договора]                                                               = cmr_d.сумма
       , [Дата закрытия договора]                                                       = case when ced.ДатаОкончания < cast(getdate() as date) then ced.ДатаОкончания end
       , [#c_end_date]                                                                  = c_e_d.contractenddate
       , [Ближайшая дата платежа]                                                       = np.ДатаПлатежа
       , [Сумма поступлений по договору на сегодня]                                     = b_today.[сумма поступлений  нарастающим итогом]
                                                                                          
       , [Ссылка на последнйи график платежа]                                           = np.Регистратор
       , [Ссылка на платеж в рамках графика платежей]                                   = np.НомерСтроки
       , [Сумма ближайшего платежа]                                                     = np.СуммаПлатежа
       , [max_dpd]                                                                      = maxdpd.dpd
                                                                                          
       , [dpd на сегодня]                                                               = b_today.dpd
       , [бакет на сегодня]                                                             = b_today.bucket
       , [Остаток ОД на сегодня]                                                        = b_today.[остаток од]
       , [Остаток % на сегодня]                                                         = b_today.[остаток %]
                                                                                          
       , [dpd на дату заявления по КК]                                                  = (select dpd from dwh2.dbo.v_balance where date=dateadd(year,-2000,kk.ДатаЗаявки) and Number=cmr_d.Код)
       , [Остаток ОД на дату заявления по КК]                                           = (select principal_rest from dwh2.dbo.v_balance where date=dateadd(year,-2000,kk.ДатаЗаявки) and Number=cmr_d.Код)
       , [Остаток % на дату заявления по КК]                                            = (select interests_rest from dwh2.dbo.v_balance where date=dateadd(year,-2000,kk.ДатаЗаявки) and Number=cmr_d.Код)
       , [Сумма выплат от даты старта КК до сегодня]                                    = (select sum(summ) from #payments p where p.Number=cmr_d.код and p.Дата>=dateadd(year,-2000,kk.ДатаНачалаКК)  )
       , [Сумма выплат от сегодня-30дней до сегодня]                                    = (select sum(summ) from #payments p where p.Number=cmr_d.код and p.Дата>=dateadd(day,-30,dateadd(year,-2000,kk.ДатаНачалаКК) ) )
       , [Сумма выплат от сегодня-60дней до сегодня]                                    = (select sum(summ) from #payments p where p.Number=cmr_d.код and p.Дата>=dateadd(day,-60,dateadd(year,-2000,kk.ДатаНачалаКК) ) )
       , [Сумма выплат от сегодня-90дней до сегодня]                                    = (select sum(summ) from #payments p where p.Number=cmr_d.код and p.Дата>=dateadd(day,-90,dateadd(year,-2000,kk.ДатаНачалаКК) ) )
       , [Дата завления на КК]                                                          = dateadd(year,-2000,kk.ДатаЗаявки)
       , [Статус заявления на КК]                                                       = kk.СтатусЗаявки
       , [Причина отказа по КК]                                                         = kk.ПричинаОтказаПоКК
       , [Подключенная услуга по договору]                                              = kk.СогласованныйТипКК
       , [Дата начала КК]                                                               = dateadd(year,-2000,kk.ДатаНачалаКК)
       , [Дата окончания КК]                                                            = dateadd(year,-2000,dateadd(month,cast(substring(kk.СрокКК,1,1)as int),kk.ДатаНачалаКК))
       , [Ссылка на перенос даты платежа]                                               =  dopd.Ссылка
       , [Флаг был перенос даты платежа]                                                = case when dopd.Ссылка is not null then 1 else 0 end
       , [Дата переноса платежа]                                                        = dopd.Дата
       , [Старая дата платежа]                                                          = dopd.СледующаяДатаПлатежа
       , [Новая дата платежа]                                                           = dopd.НоваяДатаПлатежа
                                                                                          
       , [дата окончания договора - до начала кредитных каникул]                        = cpbkk.ДатаОкончания
       , [дата окончания договора - после старта кредитных каникул]                     = cpakk.ДатаОкончания
       , [дата окончания договора - самая первая]                                       = cpfr.ДатаОкончания
                                                                                          
       , [Проц ставка - до начала кредитных каникул]                                    = cpbkk.ПроцентнаяСтавка
       , [Проц ставка - после старта кредитных каникул]                                 = cpakk.ПроцентнаяСтавка
       , [Проц ставка - самая первая]                                                   = cpfr.ПроцентнаяСтавка
                                                                                          
                                                                                          
       , [Планируемая дата окончания договора]                                          = ced.ДатаОкончания--параметры договора
       , [самая первая дата окончания договора]                                         = cpfr.ДатаОкончания--параметры договора
                                                                                          
                                                                                          
                                                                                          
       , [Проц ставка открытия]                                                         = cpfr.ПроцентнаяСтавка
       , [Проц ставка текущая]                                                          = ced.ПроцентнаяСтавка
       , [Флаг снижение процентной ставки по КК]                                        = case when cpbkk.ПроцентнаяСтавка-cpakk.ПроцентнаяСтавка>0 then 1 else 0 end
       , [Дельта проц ставки]                                                           = cpbkk.ПроцентнаяСтавка-cpakk.ПроцентнаяСтавка
                                                                                          
       , [created]                                                                      = getdate()
    --into dbo.Dm_ReportKK
    from stg._1ccmr.Справочник_Договоры cmr_d
    left join dwh2.dbo.ClientReferences cr on cr.CMRContractIDRREF=cmr_d.Ссылка
    left join dbo.dm_CMRStatBalance_2 b_today on b_today.external_id=cmr_d.Код and d=cast(getdate() as date)
    left join stg._collection.customers coll_cust on coll_cust.CrmCustomerId=cr.CRMClientGUID
    left join #max_dpd maxdpd on maxdpd.Договор=cmr_d.Ссылка
    left join #ContractEndDates ced on ced.Договор=cmr_d.Ссылка
    left join #kk2 kk on kk.НомерДоговора= cmr_d.Код
    left join [Stg].[_LK].[contracts] lk_c on lk_c.code=cmr_d.Код
    left join  #nearest_payment np on np.Код=cmr_d.Код
    left join (select * 
                from  Stg.[_1cCMR].[Документ_ОбращениеКлиента]
                where НоваяДатаПлатежа <>'2001-01-01 00:00:00'  and Проведен=0x01
                ) dopd on  dopd.ДОговор=cmr_d.Ссылка
    left join  #ContractsParametersAfterKK cpakk on cpakk.Договор=cmr_d.Ссылка
    left join  #ContractsParametersBeforeKK cpbkk on cpbkk.Договор=cmr_d.Ссылка
    left join #ContractsParametersFirstRecord cpfr on cpfr.Договор=cmr_d.Ссылка
    left join #c_end_date c_e_d on c_e_d.external_id=cmr_d.Код
    
    
/*
select * 
from dwh2.dbo.v_balance where date=cast(getdate() as date)

select * from stg._1ccmr.Справочник_Договоры
select * from stg._1ccmr.РегистрСведений_СтатусыДоговоров
 drop table if exists #CmrStatuses
 
 ;
 with last_period as 
 (
 SELECT sd.Договор deal
      , max(Период) mp
   FROM [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров]     sd
  group by sd.Договор
 )
 select d.код external_id
      , st.Наименование LastStatus
      ,mp
   into #CmrStatuses
   FROM [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров]     sd
   join last_period                                           lp on lp.deal    = sd.Договор and lp.mp  = sd.Период
   join [Stg].[_1cCMR].[Справочник_Договоры]                   d on  d.Ссылка  = sd.Договор       
   join [Stg].[_1cCMR].[Справочник_СтатусыДоговоров]          st on st.Ссылка  = sd.Статус

   select * from #CmrStatuses
  */ 

  end
