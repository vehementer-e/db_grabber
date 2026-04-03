




CREATE PROCEDURE [finAnalytics].[reestrCBQCheck1]
    @repMonth date,
    @dsSelector int
AS
BEGIN

drop table if Exists #checkPool
create table #checkPool(
 checkNum varchar(10) not null,
 checkName varchar(300) not null,
 colNum  varchar(10) not null
)

INSERT INTO #checkPool values ('1','Дата рождения заемщика','5')
INSERT INTO #checkPool values ('2','Тип заемщика (ФЛ / самозанятый / ИП / ЮЛ)','7')
INSERT INTO #checkPool values ('3','Тип договора','10')
INSERT INTO #checkPool values ('4','Тип заемщика (первичный / повторный)','11')
INSERT INTO #checkPool values ('5','Стоимость приобретения задолженности, руб.','19')
INSERT INTO #checkPool values ('6','Данные о приобретенной задолженности','19-21')
INSERT INTO #checkPool values ('7','Номер договора займа','22')
INSERT INTO #checkPool values ('8','Дата заключения договора займа','23')
INSERT INTO #checkPool values ('9','Дата заключения договора займа','23')
INSERT INTO #checkPool values ('10','Дата заключения договора займа','23')
INSERT INTO #checkPool values ('11','Дата заключения договора займа','23')
INSERT INTO #checkPool values ('12','Дата заключения договора займа','23')
INSERT INTO #checkPool values ('13','Договор с лимитом кредитования (да / пусто)','25')
INSERT INTO #checkPool values ('14','Сумма займа по договору, руб.','28')
INSERT INTO #checkPool values ('15','Сумма займа по договору, руб.','28')
INSERT INTO #checkPool values ('16','Сумма займа с учетом доп. соглашений, руб.','29')
INSERT INTO #checkPool values ('17','Объем денежных средств, предоставленных по договору займа за квартал, руб','30')
INSERT INTO #checkPool values ('18','Объем денежных средств, предоставленных по договору займа за квартал, руб','30')
INSERT INTO #checkPool values ('19','Дата заключения доп. соглашения об увеличении суммы займа (кредита)','31')
INSERT INTO #checkPool values ('20','Дата погашения по договору','33')
INSERT INTO #checkPool values ('21','Дата погашения по договору','33')
INSERT INTO #checkPool values ('22','Дата погашения по договору с учетом доп. соглашений','34')
INSERT INTO #checkPool values ('23','Фактическая дата погашения/ закрытия/списания займа ','35')
INSERT INTO #checkPool values ('24','Заем обеспечен ипотекой (да / соответствует / да и соответствует / пусто)','43')
INSERT INTO #checkPool values ('25','Залог жилой недвижимости или нет (жилая / нежилая / жилая и нежилая / пусто)','44')
INSERT INTO #checkPool values ('26','Заем обеспечен иным залогом (за исключением ипотеки / авто)  (соответствует / пусто)','46')
INSERT INTO #checkPool values ('27','Вид иного залога','47')
INSERT INTO #checkPool values ('28','Стоимость предмета залога, руб.','48')
INSERT INTO #checkPool values ('29','Последняя дата оценки залога','49')
INSERT INTO #checkPool values ('30','Последняя дата оценки залога','49')
INSERT INTO #checkPool values ('31','Сведения о поручителе / залогодателе / гаранте (для ФЛ, ИП - ФИО, для - ЮЛ - наименование)','53')
INSERT INTO #checkPool values ('32','Идентификационные данные поручителя / залогодателя / гаранта (ИНН - для  ИП, ЮЛ / серия и номер паспорта - для ФЛ)','54')
INSERT INTO #checkPool values ('33','ПНД на момент выдачи кредита (займа), %','79')
INSERT INTO #checkPool values ('34','Чистый доход МФО от предоставления дополнительных услуг, руб.','85')
INSERT INTO #checkPool values ('35','Данные о размере лимита кредитования ','86 - 89')
INSERT INTO #checkPool values ('36','Максимальный размер лимита за квартал, руб.','89')
INSERT INTO #checkPool values ('37','Дата продажи задолженности','116')
INSERT INTO #checkPool values ('38','Сумма продажи по договору цессии','117')
INSERT INTO #checkPool values ('39','Дата списания задолженности','119')
INSERT INTO #checkPool values ('40','Самая ранняя из следующих дат: ','120')
INSERT INTO #checkPool values ('41','Дата выдачи паспорта заемщика - ФЛ / дата регистрации заемщика - ЮЛ и ИП','4')
INSERT INTO #checkPool values ('42','Дата рождения заемщика','5')
INSERT INTO #checkPool values ('43','Дата приобретения задолженности','18')
INSERT INTO #checkPool values ('44','Дата заключения договора займа','23')
INSERT INTO #checkPool values ('45','Фактическая дата выдачи займа','24')
INSERT INTO #checkPool values ('46','Дата заключения доп. соглашения об увеличении суммы займа (кредита)','31')
INSERT INTO #checkPool values ('47','Фактическая дата погашения/ закрытия/списания/продажи займа','35')
INSERT INTO #checkPool values ('48','Дата заключения доп. соглашения','42')
INSERT INTO #checkPool values ('49','Дата расчета ПДН на момент выдачи кредита (займа)','75')


-----------Отчет сводный
if @dsSelector = 1

begin
select 
 [Номер ошибки] = cast(checkNum	as int)
 ,[Номер графы проверки] = colNum
 ,[Наименование графы проверки] = checkName
 ,[Кол-во ошибок] = isnull(b.errorCount,0)
from #checkPool a
left join (
select 
[№ ошибки]
,errorCount = count(*)
from dwh2.[finAnalytics].[reest_CB_Q_check1]
where [Месяц начала квартала] = dateadd(month,-2,@repMonth)
and [Месяц конца квартала] = @repMonth
group by [№ ошибки]
) b on a.checkNum = b.[№ ошибки]

order by a.checkNum
end

-----------Отчет детализированный
if @dsSelector = 2

select 
 [Месяц начала квартала]
 , [Месяц конца квартала]
 , [Номер ошибки] = cast([№ ошибки] as int)
 , [ФИО / Наименование заемщика]
 , [Номер договора займа]
 , [Номер графы проверки]
 , [Наименование графы проверки]
 , [Значение графы проверки]
 , [Номер графы контроля]
 , [Наименование графы контроля]
 , [Значение графы контроля]
 , [Возможная ошибка]
 , [Результат проверки]
 , [Примечания]
 , [created]
from dwh2.[finAnalytics].[reest_CB_Q_check1]
where [Месяц начала квартала] = dateadd(month,-2,@repMonth)
	and [Месяц конца квартала] = @repMonth

END

