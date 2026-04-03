  CREATE proc [dbo].[_etl_gs] @mode nvarchar(max) = 'costs_sms rating common selfemployed' as 
 
 --EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._marketing_cost manual'

  if @mode like '%selfemployed%'
  
  begin
 

exec python  'df = get_spreadsheet_values("1ocoWlJVbEAQ28utkFxe9rJlzdtyElXsqLvzJRNJilFA", "Лист1!A:C")
if len(df)>0:
	run_sql("drop table if exists _request_selfemployed_manual")
	insert_into_table(df, "_request_selfemployed_manual")', 1


	end




  if @mode like '%common%'
  begin





exec python 'df = gs2df("1FirD-QUL-Udb0FI02571gkMtTcs_3RCj_auO7Ys0YXs", "Лист1!A:A")
if len(df)>0:
	run_sql("drop table if exists source_block_sell_stg")
	insert_into_table(df, "source_block_sell_stg")
	run_sql("insert into source_block_sell select * from source_block_sell_stg where  [Источник трафика] not in (select [Источник трафика] from source_block_sell where [Источник трафика] is not null  )")' , 1
 

exec python  'df = get_spreadsheet_values("17GR6cF0nTzK7VK9uIpQHldtAphUWz2287qDZe4ZJ-MQ", "Лист1!A:C")
if len(df)>0:
	run_sql("drop table if exists _request_exception_partner")
	insert_into_table(df, "_request_exception_partner")', 1



exec python 'df = gs2df("12Nnl8sh3ESEh4aW_Yb5hLBuj6JD6PyZlH1Q9DGnLggw", "Лист1!A:N")
if len(df)>0:
	run_sql("drop table if exists _request_exception")
	insert_into_table(df, "_request_exception")' , 1
 

exec python  'sql2gs("""select b.Номер, a.office, a.channel, b.TransitionsJSON, b.[Номер партнера CRM],b.[Номер партнера],
b.[Exceptions info], b.[Канал от источника лид] , b.[Канал от источника], b.[Источник] from v_request_manual_validation a 
join v_FA b on a.number=b.Номер order by 1 """, "17GR6cF0nTzK7VK9uIpQHldtAphUWz2287qDZe4ZJ-MQ", "Лист2")', 1




	
exec python  'df = get_spreadsheet_values("1z4-eeZWtHXRYfGFl4aQ5w1pNruJyIh3OPtoZzilHJdI", "клиенты, которые направили подтверждение!A:I")
if len(df)>0:
	run_sql("drop table if exists _request_proof_of_use_gs")
	insert_into_table(df, "_request_proof_of_use_gs")', 1


  

exec python 'run_sql("drop table if exists sale_plan_partner")
df = pd.read_excel(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\справочники партнеры.xlsx", sheet_name = "план партнеры")
insert_into_table(df, "sale_plan_partner")', 1


exec python 'xl2sql(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\справочники партнеры.xlsx", "UTM", "sale_partner_utm")', 1


exec python 'run_sql("drop table if exists sale_partner_cost_config")
df = pd.read_excel(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\справочники партнеры.xlsx", sheet_name = "ставки кв юрлиц по месяцам")
insert_into_table(df, "sale_partner_cost_config")', 1

 

exec python 'run_sql("delete from sale_plan")
df = pd.read_excel(r"G:\Мой диск\план продаж.xlsx", sheet_name = "ПланПоДням")
insert_into_table(df, "sale_plan", insert=True)', 1


--exec python 'run_sql("drop table if exists  sale_plan")
--df = pd.read_excel(r"G:\Мой диск\план продаж.xlsx", sheet_name = "ПланПоДням")
--insert_into_table(df, "sale_plan")', 1

exec python 'xl2sql(r"G:\Мой диск\план продаж по каналам.xlsx", "Лист1", "sale_plan_channel")', 1

 

exec python 'run_sql("delete from add_product_refuse")
df = pd.read_excel(r"G:\Мой диск\refuses_CP.xlsx", sheet_name = "refuses_CP")
insert_into_table(df, "add_product_refuse", insert=True)', 1


--exec python 'xl2sql(r"G:\Мой диск\refuses_CP.xlsx", "refuses_CP", "add_product_refuse")', 1

exec exec_python 'run_sql("drop table _gsheets.[dic_Проекты TTC]")
df = get_spreadsheet_values("1DWDArm6Mw5BeeCxFQ3yCztSLwxCf8FBQWuZ1igkSGLs", "Проекты TTC!A:N")
insert_into_table(df, "dic_Проекты TTC", "_gsheets")', 1

 

end


if @mode  like '%marketplace%'

exec exec_python 'run_sql("drop table marketing_source_marketplace")
df = get_spreadsheet_values("1jxSOx5gN2-q0oCk_hfrSKsS03c1xqZqiPcSH7_Hi7Es", "Маркетплейсы!A:B")
insert_into_table(df, "marketing_source_marketplace")', 1





if @mode like '%costs_marketing%'
begin

exec python 'xl2sql(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\Расходы_ CPC + Медийка + Остальное.xlsx", "Продажа трафика2", "marketing_sell_agr")', 1


exec python 'df = pd.read_excel(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\Расходы_ CPC + Медийка + Остальное.xlsx", sheet_name =  "Расходы по месяцам", skiprows=[1,2])
if len(df)>0:
	run_sql("drop table if exists marketing_cost_agr")
	insert_into_table(df, "marketing_cost_agr")', 1


 


exec python 'xl2sql(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\справочники партнеры.xlsx", "привлечение", "marketing_cost_partner")', 1
exec python 'xl2sql(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\справочники партнеры.xlsx", "оформление", "marketing_cost_partner_registration")', 1


end



if @mode like '%costs_sms%'
begin
  
exec python  '
df = get_spreadsheet_values("1BYM_J4tJLjiSBpvydcvBLZI1sMk-HA4KR3w_fvqQgBs", "справочник расходы на смс!A:C")
if len(df)>0:
	run_sql("drop table if exists marketing_cost_sms")
	insert_into_table(df, "marketing_cost_sms")'	, 1 

if not exists (select top 1 * from marketing_cost_sms  )  
RAISERROR ('Справочник  marketing_cost_sms пустой ', 16, 1 );



end			


 if @mode like '%business%'
 begin

   
exec python  '
df = get_spreadsheet_values("1KzlBFroBpzZXLAL94RS1Pv5bjV7vKpTDz1mihk3h9Hw", "ПСБ БЗ!A2:F10000")
if len(df)>0:
	run_sql("drop table if exists marketing_business_lead")
	insert_into_table(df, "marketing_business_lead")'	, 1 


 end



 if @mode like '%rating%'
 begin

--drop table if exists sale_employee
exec python 'df = gs2df("1XVVHn4vJvjriKN0Xy6kgQ4SAY6F75q7mGKVcmqPYTFI", "Сотрудники!A:E")
if len(df)>0:
	run_sql("drop table if exists sale_employee")
	insert_into_table(df, "sale_employee")' , 1



declare @dateLogist  date  
declare @sqlLogist    nvarchar(max)


--CREATE TABLE [dbo].[sale_rating_logist_request]
--(
--      [Номер заявки ] [BIGINT]
--    , [ФИО логиста ] [VARCHAR](33)
--    , [month] [VARCHAR](8)
--    , [loaded_into_dwh] [DATETIME]
--);


begin try
set @dateLogist    =  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
set @sqlLogist   =   'df = gs2df("1mmH8GV-1wNMV_LbRSexTa31tFFvkg0YwdXp8_elgbVk", range="'+format(@dateLogist, 'yyyyMM01')+'!A:B")
df["month"] = "'+format(@dateLogist, 'yyyyMM01')+'"
if len(df)>0:
	run_sql("delete from sale_rating_logist_request where month ='''+format(@dateLogist, 'yyyyMM01')+'''")
	insert_into_table(df, "sale_rating_logist_request", v="1", insert=True)
'
exec python @sqlLogist, 1
 
 end try
 begin catch
 select 1
 end catch

begin try

set @dateLogist    =  cast(DATEADD(MONTH, -1+DATEDIFF(MONTH, 0,           getdate()), 0) as date)
set @sqlLogist   =   'df = gs2df("1mmH8GV-1wNMV_LbRSexTa31tFFvkg0YwdXp8_elgbVk", range="'+format(@dateLogist, 'yyyyMM01')+'!A:B")
df["month"] = "'+format(@dateLogist, 'yyyyMM01')+'"
if len(df)>0:
	run_sql("delete from sale_rating_logist_request where month ='''+format(@dateLogist, 'yyyyMM01')+'''")
	insert_into_table(df, "sale_rating_logist_request", v="1", insert=True)
'
exec python @sqlLogist, 1


 end try
 begin catch
 select 1
 end catch


 end



 if @mode like '%psb presentation%'
begin



exec python 'sql2gs("""


;
with v as (

select isnull( a.issuedMonth, a.call1Month) month



, case 
when a.productType = ''PTS'' and a.source like ''psb%'' and a.isNew=1  then ''PTS BANK новые''
when a.productType = ''PTS'' and a.source like ''psb%'' and a.isNew=0  then ''PTS BANK потвторные''



when a.productType = ''PTS'' and a.source like ''tpokupki%'' and a.isNew=1  then ''PTS T-BANK новые''
when a.productType = ''PTS'' and a.source like ''tpokupki%'' and a.isNew=0  then ''PTS T-BANK потвторные''


when a.productType in ( ''INST'' , ''PDL'') and a.source like ''psb%'' and a.isNew=1  then ''INST PDL BANK новые''
when a.productType in ( ''INST'' , ''PDL'') and a.source like ''psb%'' and a.isNew=0  then ''INST PDL BANK потвторные''


when a.productType in ( ''AUTOCREDIT'')   then ''BUY AUTO'' 
when a.productType in ( ''BIG INST'') and a.source like ''psb%''  then ''LONG INST BANK''
when a.productType in ( ''BIG INST'')    then ''LONG INST MARKET''


when a.productType = ''PTS'' and isnull( a.issuedMonth, a.call1Month)>=''20260101'' and a.source like ''infoseti%''  and a.isNew=1  then ''PTS GPB новые''
when a.productType = ''PTS'' and isnull( a.issuedMonth, a.call1Month)>=''20260101'' and a.source like ''infoseti%''  and a.isNew=0  then ''PTS GPB повторные''


when a.productType = ''PTS''  and a.isNew=1  then ''PTS CM новые''
when a.productType = ''PTS''  and a.isNew=0  then ''PTS CM потвторные''



when a.productType in ( ''INST'' , ''PDL'') and isnull( a.issuedMonth, a.call1Month)>=''20260101'' and a.source like ''infoseti%''   and a.isNew=1  then ''INST PDL GPB новые''
when a.productType in ( ''INST'' , ''PDL'') and isnull( a.issuedMonth, a.call1Month)>=''20260101'' and a.source like ''infoseti%''   and a.isNew=0  then ''INST PDL GPB повторные''

when a.productType in ( ''INST'' , ''PDL'')   and a.isNew=1  then ''INST PDL CM новые''
when a.productType in ( ''INST'' , ''PDL'')   and a.isNew=0  then ''INST PDL CM потвторные''
else ''?'' end presentationType, issuedSum, marketingCost
 

, case 
when a.productType = ''PTS'' and a.source like ''psb%''   then ''PTS BANK'' 



when a.productType = ''PTS'' and a.source like ''tpokupki%'' then ''PTS T-BANK''

when a.productType in ( ''INST'' , ''PDL'') and a.source like ''psb%'' then ''INST PDL BANK''


when a.productType in ( ''AUTOCREDIT'')   then ''null'' 


when a.productType = ''PTS'' and isnull( a.issuedMonth, a.call1Month)>=''20260101''   and a.source like ''infoseti%''  then ''PTS GPB'' 

when a.productType = ''PTS''    then ''PTS CM''

when a.productType in ( ''INST'' , ''PDL'') and isnull( a.issuedMonth, a.call1Month)>=''20260101'' and a.source like ''infoseti%''   then ''INST PDL GPB'' 

when a.productType in ( ''INST'' , ''PDL'')   then ''INST PDL CM''
else ''?'' end presentationType2


, [Сумма Дополнительных Услуг Carmoney Net]
, interestRate/100.0 interestRate
from v_fa a
left join v_request_cost b on a.number=b.Номер
where  isnull( a.issuedMonth, a.call1Month)>=''20250101''

)

select presentationType, month, sum(issuedSum) issuedSum
, cast( sum(marketingCost)/ nullif( ( 0.0+ count(issuedSum)), 0) as  numeric) costOfLoan
, replace( format( sum([Сумма Дополнительных Услуг Carmoney Net])/ nullif( ( 0.0+ sum(issuedSum)), 0) , ''0.00000'') , ''.'', '','') kpShareNet 
, cast(sum([Сумма Дополнительных Услуг Carmoney Net]) as numeric) kpNet
, replace( format( sum(case when interestRate >0 then issuedSum*interestRate end)/ nullif( ( 0.0+ sum(case when interestRate >0 then issuedSum end)), 0) , ''0.00000'') , ''.'', '','') interestRate 
, count(issuedSum)  issuedCnt

from v
group by presentationType, month

union all


select presentationType2, month, sum(issuedSum) issuedSum
, cast( sum(marketingCost)/ nullif( ( 0.0+ count(issuedSum)), 0) as  numeric) costOfLoan 
, replace( format( sum([Сумма Дополнительных Услуг Carmoney Net])/ nullif( ( 0.0+ sum(issuedSum)), 0) , ''0.00000'') , ''.'', '','') kpShareNet 
, cast(sum([Сумма Дополнительных Услуг Carmoney Net]) as numeric) kpNet

, replace( format( sum(case when interestRate >0 then issuedSum*interestRate end)/ nullif( ( 0.0+ sum(case when interestRate >0 then issuedSum end)), 0) , ''0.00000'') , ''.'', '','') interestRate 
, count(issuedSum)  issuedCnt
from v
group by presentationType2, month

""", "1j8CZAKhHSJIZYyGsiPrjjZocng4vOpZt726Bnp0mbJM", "dwh_fact")', 1



end


if 1=0
begin



drop table if exists repayment_ecommpay_rate
exec python  'df = get_spreadsheet_values("1QDJgp1kG4SOtCj_lq51aTPdgRQ9zAjz4BbldMasQx2g", "dwh!A:I")
insert_into_table(df, "repayment_ecommpay_rate")', 1







exec python 'df = pd.read_excel(r"G:\Мой диск\Заявки_источник.xlsx", sheet_name = "Лист1")
insert_into_table(df, "marketing_source_risk_revision_20250813")', 1


exec python 'df = pd.read_excel(r"G:\Мой диск\infoseti для мэтчинга с carmoney.xlsx", sheet_name = "Worksheet")
insert_into_table(df, "marketing_infoseti_carmoney_revision")', 1


exec python 'run_sql("delete from feodor.dbo.dm_feodor_project2")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\feodor_project.xlsx", sheet_name = "Лист1")
insert_into_table(df, "dm_feodor_project2", db="feodor" , insert=True)', 1



exec python 'run_sql("drop table if exists sale_budget_plan_risk_pts")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_budget_plan_risk_pts.xlsx", sheet_name = "Лист1")
insert_into_table(df, "sale_budget_plan_risk_pts")', 1



exec python 'run_sql("drop table if exists sale_budget_plan_risk_pts_2026")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_budget_plan_risk_pts.xlsx", sheet_name = "2026")
insert_into_table(df, "sale_budget_plan_risk_pts_2026")', 1


exec python 'run_sql("drop table if exists sale_oper_plan_pts_2026")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_oper_plan_pts.xlsx", sheet_name = "2026")
insert_into_table(df, "sale_oper_plan_pts_2026")', 1





exec python 'run_sql("drop table if exists sale_budget_plan_risk")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_budget_plan_risk.xlsx", sheet_name = "Лист3")
insert_into_table(df, "sale_budget_plan_risk")', 1




exec python 'run_sql("drop table if exists sale_budget_plan_pivot")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_budget_plan_pivot.xlsx", sheet_name = "Лист1")
insert_into_table(df, "sale_budget_plan_risk_pivot")', 1


exec python 'run_sql("drop table if exists sale_budget_plan_pivot_2026")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_budget_plan_pivot.xlsx", sheet_name = "2026")
insert_into_table(df, "sale_budget_plan_pivot_2026")', 1

exec python 'run_sql("drop table if exists sale_oper_plan_pivot_2026")
df = pd.read_excel(r"G:\Другие компьютеры\Компьютер\Рабочий стол2\папки\_БЮДЖЕТИРОВАНИЕ\Utils\sale_oper_plan_pivot.xlsx", sheet_name = "2026")
insert_into_table(df, "sale_oper_plan_pivot_2026")', 1



exec python 'run_sql("drop table if exists [adhoc_20250711_Входящие лиды ПСБ (psb-deepapi)]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\20250711_Входящие лиды ПСБ (psb-deepapi) с 25.05.01.xlsx", sheet_name = "Входящие лиды ПСБ (psb-deepapi)")
insert_into_table(df, "adhoc_20250711_Входящие лиды ПСБ (psb-deepapi)")', 1




exec python 'run_sql("drop table if exists [adhoc_20260116_BIG пилот]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\Заявки ПТС для BIG 24.12 (1).xlsx", sheet_name = "Таблица3")
insert_into_table(df, "adhoc_20260116_BIG пилот")', 1




exec python 'run_sql("drop table if exists [adhoc_20260202_клиенты для ИНН]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\Sales.  Регулярные обзвоны. Стратегия уведомления по маркенговым предложениям докред повторники ПТС (2).xlsx", sheet_name = "Лист1")
insert_into_table(df, "adhoc_20260202_клиенты для ИНН")', 1




exec python 'run_sql("drop table if exists [adhoc_20260206_analytics_205_1]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_205.xlsx", sheet_name = "1")
insert_into_table(df, "adhoc_20260206_analytics_205_1")', 1



exec python 'run_sql("drop table if exists [adhoc_20260206_analytics_205_2]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_205.xlsx", sheet_name = "2")
insert_into_table(df, "adhoc_20260206_analytics_205_2")', 1


exec python 'run_sql("drop table if exists [adhoc_20260318_stages_BIG_Market]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\Заявки февраль BIG_Market.xlsx", sheet_name = "stages_BIG_Market")
insert_into_table(df, "adhoc_20260318_stages_BIG_Market")', 1



exec python 'run_sql("drop table if exists [adhoc_20260324_analytics_221_1]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_221.xlsx", sheet_name = "1")
insert_into_table(df, "adhoc_20260324_analytics_221_1")', 1



exec python 'run_sql("drop table if exists [adhoc_20260324_analytics_221_2]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_221.xlsx", sheet_name = "2")
insert_into_table(df, "adhoc_20260324_analytics_221_2")', 1


exec python 'run_sql("drop table if exists [adhoc_20260324_analytics_221_3]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_221.xlsx", sheet_name = "3")
insert_into_table(df, "adhoc_20260324_analytics_221_3")', 1



exec python 'run_sql("drop table if exists [adhoc_20260324_analytics_221_4]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_221.xlsx", sheet_name = "4")
insert_into_table(df, "adhoc_20260324_analytics_221_4")', 1

exec python 'run_sql("drop table if exists [adhoc_20260324_analytics_221_5]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_221.xlsx", sheet_name = "5")
insert_into_table(df, "adhoc_20260324_analytics_221_5")', 1

exec python 'run_sql("drop table if exists [adhoc_20260324_analytics_221_6]")
df = pd.read_excel(r"G:\Общие диски\Analytics\STORAGE\dictionary\adhoc\analytics_221.xlsx", sheet_name = "6")
insert_into_table(df, "adhoc_20260324_analytics_221_6")', 1



end
--select * from sale_budget_plan_risk
--select distinct product from sale_budget_plan_risk_pivot
--select 
--  a.[month]
--, a.[product]
--, a.[cntLoan]
--, a.[cntRequest]
--, a.[sumLoan]
--, a.[loaded_into_dwh]

--from  sale_budget_plan_risk_pivot a