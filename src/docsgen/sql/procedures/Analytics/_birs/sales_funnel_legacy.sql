

CREATE     proc [_birs].[sales_funnel_legacy]


@now_d_start_ssrs date = null,
@compare_d_start_ssrs date = null,
@now_HH_ssrs int = null,
@now_MM_ssrs int = null,
@isInstallment_ssrs int = null


as

begin





set datefirst 1;
declare @now_d_start datetime = cast(@now_d_start_ssrs as date)
declare @compare_d_start datetime = cast(@compare_d_start_ssrs as date)
--declare @now_d_start datetime = cast(getdate() as date)
--declare @compare_d_start datetime = cast(getdate()-1 as date)


declare @now_hh int = cast(@now_HH_ssrs as int)
declare @now_MM int = cast(@now_MM_ssrs as int)
--declare @now_hh int = cast(16 as int)
--declare @now_MM int = cast(0 as int)

declare @now_dt_end datetime    =  dateadd(day, 1,  cast(@now_d_start as datetime))
declare @compare_dt_end datetime    =  dateadd(day, 1,  cast(@compare_d_start as datetime))
;

declare @replication_dt_for_now_d_start datetime = (
select top 1 [replication_created] replications_dt 
from [Reports].[dbo].[dm_report_CRM_requests_replication_over_day] fa_repl 
where cast([replication_created] as date)=@now_d_start  
order by abs(datediff(SECOND, cast([replication_created] as time), cast(dateadd(minute, @now_MM, dateadd(hour, @now_hh, cast('2020-01-01' as datetime))) as time)))
)

declare @replication_dt_for_compare_d_start datetime = (
select top 1 [replication_created] replications_dt from [Reports].[dbo].[dm_report_CRM_requests_replication_over_day] fa_repl where cast([replication_created] as date)=@compare_d_start order by abs(datediff(SECOND, cast([replication_created] as time), cast(@replication_dt_for_now_d_start as time))) 
)

--select @replication_dt_for_now_d_start, @replication_dt_for_compare_d_start

;

with v as (



select 


---------------------------
---------------------------
---------------------------
count(case when  [Верификация КЦ] between @now_d_start and  @now_dt_end and  [Верификация КЦ]             between @now_d_start and  @now_dt_end and  [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then [Верификация КЦ] end )                                          ВКЦ_новые_заявки_т1,
count(case when  [Верификация КЦ] between @now_d_start and  @now_dt_end and  [Предварительное одобрение]  between @now_d_start and  @now_dt_end and  [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then [Предварительное одобрение] end )                               ПО_новые_заявки_т1,
count(case when  [Верификация КЦ] between @now_d_start and  @now_dt_end and  ([Встреча назначена]         between @now_d_start and  @now_dt_end 
                                                                            or [Контроль данных]           between @now_d_start and  @now_dt_end) and [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then isnull([Встреча назначена], [Предварительное одобрение])  end ) ВН_или_КД_новые_заявки_т1,
count(case when  [Верификация КЦ] between @now_d_start and  @now_dt_end and   [Контроль данных]            between @now_d_start and  @now_dt_end and  [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then [Контроль данных] end )                                         КД_новые_заявки_т1,



count(case when [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Верификация КЦ]             between @now_d_start and  @now_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_т1,  

count(case when [Место cоздания]in ('Ввод операторами LCRM',  'ЛКК клиента')  and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Верификация КЦ]             between @now_d_start and  @now_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Ввод_операторами_LCRM_т1,  
count(case when [Место cоздания]in ('Ввод операторами LCRM',  'ЛКК клиента')  and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Предварительное одобрение]             between @now_d_start and  @now_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Ввод_операторами_LCRM_т1,  
count(case when [Место cоздания]in ('Ввод операторами LCRM',  'ЛКК клиента')  and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Контроль данных]             between @now_d_start and  @now_dt_end then [Контроль данных] end )                                           КД_все_заявки_Ввод_операторами_LCRM_т1, 

count(case when [Место cоздания]='Ввод операторами FEDOR' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Верификация КЦ]             between @now_d_start and  @now_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Ввод_операторами_FEDOR_т1,  
count(case when [Место cоздания]='Ввод операторами FEDOR' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Предварительное одобрение]             between @now_d_start and  @now_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Ввод_операторами_FEDOR_т1,  
count(case when [Место cоздания]='Ввод операторами FEDOR' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Контроль данных]             between @now_d_start and  @now_dt_end then [Контроль данных] end )                                           КД_все_заявки_Ввод_операторами_FEDOR_т1,  

count(case when [Место cоздания]='Оформление на партнерском сайте' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Верификация КЦ]             between @now_d_start and  @now_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Оформление_на_партнерском_сайте_т1,  
count(case when [Место cоздания]='Оформление на партнерском сайте' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Предварительное одобрение]             between @now_d_start and  @now_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Оформление_на_партнерском_сайте_т1,  
count(case when [Место cоздания]='Оформление на партнерском сайте' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Контроль данных]             between @now_d_start and  @now_dt_end then [Контроль данных] end )                                           КД_все_заявки_Оформление_на_партнерском_сайте_т1,  

count(case when [Место cоздания]='Оформление в мобильном приложении' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Верификация КЦ]             between @now_d_start and  @now_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Оформление_в_мобильном_приложении_т1,  
count(case when [Место cоздания]='Оформление в мобильном приложении' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Предварительное одобрение]             between @now_d_start and  @now_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Оформление_в_мобильном_приложении_т1,  
count(case when [Место cоздания]='Оформление в мобильном приложении' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Контроль данных]             between @now_d_start and  @now_dt_end then [Контроль данных] end )                                           КД_все_заявки_Оформление_в_мобильном_приложении_т1,  

count(case when [Место cоздания]='Ввод операторами КЦ' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Верификация КЦ]             between @now_d_start and  @now_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Ввод_операторами_КЦ_т1,  
count(case when [Место cоздания]='Ввод операторами КЦ' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Предварительное одобрение]             between @now_d_start and  @now_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Ввод_операторами_КЦ_т1,  
count(case when [Место cоздания]='Ввод операторами КЦ' and [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Контроль данных]             between @now_d_start and  @now_dt_end then [Контроль данных] end )                                           КД_все_заявки_Ввод_операторами_КЦ_т1,  

count(case when [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Предварительное одобрение]  between @now_d_start and  @now_dt_end then [Предварительное одобрение] end )                                ПО_все_заявки_т1,  
count(case when [Верификация КЦ] between @now_d_start and  @now_dt_end and   ([Встреча назначена]          between @now_d_start and  @now_dt_end
                                                                                                                     or [Контроль данных]            between @now_d_start and  @now_dt_end) then isnull([Встреча назначена], [Предварительное одобрение])  end ) ВН_или_КД_все_заявки_т1,  
count(case when [Верификация КЦ] between @now_d_start and  @now_dt_end and    [Контроль данных]            between @now_d_start and  @now_dt_end then [Контроль данных] end )                                          КД_все_заявки_т1,  


---------------------------
---------------------------
---------------------------

	 
count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and [Верификация КЦ]             between @compare_d_start and  @compare_dt_end  and [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then [Верификация КЦ] end )                                             ВКЦ_новые_заявки_т0, 

count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and  [Предварительное одобрение]  between @compare_d_start and  @compare_dt_end  and [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then [Предварительное одобрение] end )                                  ПО_новые_заявки_т0, 
count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and  ([Встреча назначена]         between @compare_d_start and  @compare_dt_end 
              or [Контроль данных]           between @compare_d_start and  @compare_dt_end) and [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then isnull([Встреча назначена], [Предварительное одобрение])  end )    ВН_или_КД_новые_заявки_т0, 
count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and  [Контроль данных]            between @compare_d_start and  @compare_dt_end  and [Вид займа]='Первичный' and [Место cоздания] <> 'Оформление на партнерском сайте' then [Контроль данных] end )                                            КД_новые_заявки_т0, 



count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and   [Верификация КЦ]             between @compare_d_start and  @compare_dt_end then [Верификация КЦ] end )                                            ВКЦ_все_заявки_т0,  

count(case when [Место cоздания] in ('Ввод операторами LCRM',  'ЛКК клиента') and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Верификация КЦ]             between @compare_d_start and  @compare_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Ввод_операторами_LCRM_т0,  
count(case when [Место cоздания] in ('Ввод операторами LCRM',  'ЛКК клиента') and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Предварительное одобрение]             between @compare_d_start and  @compare_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Ввод_операторами_LCRM_т0,  
count(case when [Место cоздания] in ('Ввод операторами LCRM',  'ЛКК клиента') and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Контроль данных]             between @compare_d_start and  @compare_dt_end then [Контроль данных] end )                                           КД_все_заявки_Ввод_операторами_LCRM_т0, 

count(case when [Место cоздания]='Ввод операторами FEDOR' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Верификация КЦ]             between @compare_d_start and  @compare_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Ввод_операторами_FEDOR_т0,  
count(case when [Место cоздания]='Ввод операторами FEDOR' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Предварительное одобрение]             between @compare_d_start and  @compare_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Ввод_операторами_FEDOR_т0,  
count(case when [Место cоздания]='Ввод операторами FEDOR' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Контроль данных]             between @compare_d_start and  @compare_dt_end then [Контроль данных] end )                                           КД_все_заявки_Ввод_операторами_FEDOR_т0,  

count(case when [Место cоздания]='Оформление на партнерском сайте' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Верификация КЦ]             between @compare_d_start and  @compare_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Оформление_на_партнерском_сайте_т0,  
count(case when [Место cоздания]='Оформление на партнерском сайте' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Предварительное одобрение]             between @compare_d_start and  @compare_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Оформление_на_партнерском_сайте_т0,  
count(case when [Место cоздания]='Оформление на партнерском сайте' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Контроль данных]             between @compare_d_start and  @compare_dt_end then [Контроль данных] end )                                           КД_все_заявки_Оформление_на_партнерском_сайте_т0,  

count(case when [Место cоздания]='Оформление в мобильном приложении' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Верификация КЦ]             between @compare_d_start and  @compare_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Оформление_в_мобильном_приложении_т0,  
count(case when [Место cоздания]='Оформление в мобильном приложении' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Предварительное одобрение]             between @compare_d_start and  @compare_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Оформление_в_мобильном_приложении_т0,  
count(case when [Место cоздания]='Оформление в мобильном приложении' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Контроль данных]             between @compare_d_start and  @compare_dt_end then [Контроль данных] end )                                           КД_все_заявки_Оформление_в_мобильном_приложении_т0,  

count(case when [Место cоздания]='Ввод операторами КЦ' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Верификация КЦ]             between @compare_d_start and  @compare_dt_end then [Верификация КЦ] end )                                           ВКЦ_все_заявки_Ввод_операторами_КЦ_т0,  
count(case when [Место cоздания]='Ввод операторами КЦ' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Предварительное одобрение]             between @compare_d_start and  @compare_dt_end then [Предварительное одобрение] end )                                           ПО_все_заявки_Ввод_операторами_КЦ_т0,  
count(case when [Место cоздания]='Ввод операторами КЦ' and [Верификация КЦ] between @compare_d_start and  @compare_dt_end and    [Контроль данных]             between @compare_d_start and  @compare_dt_end then [Контроль данных] end )                                           КД_все_заявки_Ввод_операторами_КЦ_т0,  

count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and   [Предварительное одобрение]  between @compare_d_start and  @compare_dt_end then [Предварительное одобрение] end )								   ПО_все_заявки_т0,  
count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and  ([Встреча назначена]          between @compare_d_start and  @compare_dt_end 
              or [Контроль данных]            between @compare_d_start and  @compare_dt_end) then isnull([Встреча назначена], [Предварительное одобрение])  end )  ВН_или_КД_все_заявки_т0, 
count(case when [Верификация КЦ] between @compare_d_start and   @compare_dt_end  and   [Контроль данных]            between @compare_d_start and  @compare_dt_end then [Контроль данных] end )										   КД_все_заявки_т0
	

from 
[Reports].[dbo].[dm_report_CRM_requests_replication_over_day] fa
join (select Номер НомерСРМ, case when Инстолмент =1 or ПДЛ=1 then 1 else 0 end isInstallment from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС where Фамилия <>'' ) b on fa.номер=b.НомерСРМ 
and isInstallment=@isInstallment_ssrs
where replication_created in (@replication_dt_for_now_d_start, @replication_dt_for_compare_d_start)

)

SELECT 
       [ВКЦ_новые_заявки_т1]
      ,[ПО_новые_заявки_т1]
      ,[ВН_или_КД_новые_заявки_т1]
      ,[КД_новые_заявки_т1]
      ,[ВКЦ_все_заявки_т1]
	  ,ВКЦ_все_заявки_Ввод_операторами_FEDOR_т1
	  ,ВКЦ_все_заявки_Ввод_операторами_LCRM_т1
	  ,ВКЦ_все_заявки_Ввод_операторами_КЦ_т1
	  ,ВКЦ_все_заявки_Оформление_в_мобильном_приложении_т1
	  ,ВКЦ_все_заявки_Оформление_на_партнерском_сайте_т1
	  ,ПО_все_заявки_Ввод_операторами_FEDOR_т1
	  ,ПО_все_заявки_Ввод_операторами_LCRM_т1
	  ,ПО_все_заявки_Ввод_операторами_КЦ_т1
	  ,ПО_все_заявки_Оформление_в_мобильном_приложении_т1
	  ,ПО_все_заявки_Оформление_на_партнерском_сайте_т1
	  ,КД_все_заявки_Ввод_операторами_FEDOR_т1
	  ,КД_все_заявки_Ввод_операторами_LCRM_т1
	  ,КД_все_заявки_Ввод_операторами_КЦ_т1
	  ,КД_все_заявки_Оформление_в_мобильном_приложении_т1
	  ,КД_все_заявки_Оформление_на_партнерском_сайте_т1
	  
      ,[ПО_все_заявки_т1]
      ,[ВН_или_КД_все_заявки_т1]
      ,[КД_все_заявки_т1]
      ,[ВКЦ_новые_заявки_т0]
      ,[ПО_новые_заявки_т0]
      ,[ВН_или_КД_новые_заявки_т0]
      ,[КД_новые_заявки_т0]
      ,[ВКЦ_все_заявки_т0]
	  ,ВКЦ_все_заявки_Ввод_операторами_FEDOR_т0
	  ,ВКЦ_все_заявки_Ввод_операторами_LCRM_т0
	  ,ВКЦ_все_заявки_Ввод_операторами_КЦ_т0
	  ,ВКЦ_все_заявки_Оформление_в_мобильном_приложении_т0
	  ,ВКЦ_все_заявки_Оформление_на_партнерском_сайте_т0
	  ,ПО_все_заявки_Ввод_операторами_FEDOR_т0
	  ,ПО_все_заявки_Ввод_операторами_LCRM_т0
	  ,ПО_все_заявки_Ввод_операторами_КЦ_т0
	  ,ПО_все_заявки_Оформление_в_мобильном_приложении_т0
	  ,ПО_все_заявки_Оформление_на_партнерском_сайте_т0
	  ,КД_все_заявки_Ввод_операторами_FEDOR_т0
	  ,КД_все_заявки_Ввод_операторами_LCRM_т0
	  ,КД_все_заявки_Ввод_операторами_КЦ_т0
	  ,КД_все_заявки_Оформление_в_мобильном_приложении_т0
	  ,КД_все_заявки_Оформление_на_партнерском_сайте_т0
      ,[ПО_все_заявки_т0]
      ,[ВН_или_КД_все_заявки_т0]
      ,[КД_все_заявки_т0]

	  ,@replication_dt_for_now_d_start replication_dt_for_now_d_start
	  ,@replication_dt_for_compare_d_start replication_dt_for_compare_d_start

      from v

end