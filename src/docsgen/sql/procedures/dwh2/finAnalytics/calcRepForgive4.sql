




CREATE PROCEDURE [finAnalytics].[calcRepForgive4]
	@repmonth date

AS
BEGIN

DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

declare @dateFrom datetime = cast(DATEADD(year,2000,@repmonth) as datetime)
declare @dateToTMP datetime = dateadd(DAY,1,cast(DATEADD(year,2000,eomonth(@repmonth)) as datetime))
declare @dateTo datetime = dateadd(SECOND,-1,@dateToTMP)
--select * from Stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a where a.Период between @dateFrom and @dateTo



delete from finAnalytics.repForgive4 where repmonth=@repmonth

insert into finAnalytics.repForgive4
(repmonth, [Дата проводки], [Счёт Дт.], [Счёт Кт.], [Признак мем.ордера], [Кт. Субконто 1], [Кт. Субконто 2], 
[Кт. Субконто 3], [Наименование счёта Дт.], [Сумма проводки], [Номенклатурная группа], [Есть в отчёте по акциям], dogNum, Символ, [Назначение платежа], Тригер1)

select
l1.repmonth
,l1.[Дата проводки]
,l1.[Счёт Дт.]
,l1.[Счёт Кт.]
,l1.[Признак мем.ордера]
,l1.[Кт. Субконто 1]
,l1.[Кт. Субконто 2]
,l1.[Кт. Субконто 3]
,l1.[Наименование счёта Дт.]
,l1.[Сумма проводки]
,l1.[Номенклатурная группа]
,l1.[Есть в отчёте по акциям?]
,l1.dogNum
,l1.Символ
,l1.[Назначение платежа]
,[Тригер1] = case when l1.[Есть в отчёте по акциям?] = 'Нет' and l1.[Признак мем.ордера] = 'Нет' then 1 else 0 end
from(
select
repmonth = @repmonth
, [Дата проводки] = DATEADD(year,-2000,a.Период)
, [Счёт Дт.] = Dt.Код
, [Счёт Кт.] = Kt.Код
, [Признак мем.ордера] =  case when a.Регистратор_ТипСсылки !=0x00000214  then 'Нет' else 'Да' end
, [Кт. Субконто 1] = sp2.Наименование
, [Кт. Субконто 2] = dc.Наименование
, [Кт. Субконто 3] = sp3.Наименование
, [Наименование счёта Дт.] = accDT.Наименование
, [Сумма проводки] = a.Сумма
, [Номенклатурная группа] = /*case when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%основной%')
					or  upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%ПТС31%')
					or  upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%Рефинансирование%') then 'ПТС'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%installment%') then 'IL'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%PDL%') then 'PDL'
				   when upper(isnull(nomKT.Наименование,pbr.nomenkGroup)) like upper('%бизнес%займ%') then 'БЗ'
				   else '-' end*/
				  -- case when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'ПТС' then 'ПТС'
						--when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Installment' then 'IL'
						--when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'PDL' then 'PDL'
						--when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Бизнес-займ' then 'БЗ'
						--when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Автокредит' then 'Автокредит'
				  -- else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Бизнес-займ' then 'БЗ'
					when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) = 'Installment' then 'IL'
					when dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](isnull(nomKT.Наименование,pbr.nomenkGroup)) end


, [Есть в отчёте по акциям?] = case when ac.zaim is not null then 'Да' else 'Нет' end
, [dogNum] =	 isnull(crkt.Номер,dc.Номер)
, [Символ] = sp1.Наименование
, [Назначение платежа] = a.Содержание
, [Тригер1] = null


from Stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_НоменклатурныеГруппы nomKT on crkt.АЭ_НоменклатурнаяГруппа=nomkT.Ссылка and nomKT.ПометкаУдаления=0x00
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dc on a.СубконтоCt2_Ссылка=dc.Ссылка
left join finAnalytics.PBR_MONTHLY pbr on isnull(crkt.Номер,dc.Номер)=pbr.dogNum and pbr.repmonth=@repmonth
left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы sp1 on a.СубконтоDt1_Ссылка=sp1.Ссылка and sp1.ПометкаУдаления=0x00
left join stg._1cUMFO.Справочник_Контрагенты sp2 on a.СубконтоCt1_Ссылка=sp2.Ссылка
left join stg._1cUMFO.Справочник_БНФОСубконто sp3 on a.СубконтоCt3_Ссылка=sp3.Ссылка
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета accDT on a.СчетАналитическогоУчетаДт=accDT.Ссылка
left join finAnalytics.akcia_vzisk_MONTHLY ac on isnull(crkt.Номер,dc.Номер) = substring(ac.zaim,CHARINDEX('№ ',ac.zaim)+2,CHARINDEX(' от ',ac.zaim)-8)

where 1=1
--and a.Регистратор_Ссылка=0xA3050050568397CF11EFBB77A7D5F99E
and a.Период between @dateFrom and @dateTo
and a.Активность=0x01
and (
	Dt.Код = '71802' and Kt.Код='48802'

)
) l1

--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END
