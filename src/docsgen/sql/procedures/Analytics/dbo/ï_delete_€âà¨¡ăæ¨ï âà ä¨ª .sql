

create   proc dbo.[Атрибуция трафика]
as

begin



DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] [numeric](10, 0) NOT NULL,
	[PhoneNumber] [varchar](20) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_STAT_AD_TYPE] [varchar](512) NULL,
	[UF_STAT_CAMPAIGN] [varchar](512) NULL,
	[UF_SOURCE] [varchar](512) NULL,
	UF_TYPE [varchar](512) NULL
	

)

-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = '20221107' , @End_Registered = getdate()


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

SELECT @Return_Number, @Return_Message


drop table if exists #f

select phonenumber,
case
when uf_type   in ( 'site3_gazprom_bank', 'site3_gazprom_bank_installment')  then 'Газпром'
when uf_type   in ( 'site3_soyuz_installment', 'site3_soyuz')      then 'Союз'
when uf_source in ( 'bank-souz-ref', 'bank-souz-installment-ref')  then 'Союз'
when uf_type = 'site3_installment_lk' and uf_stat_campaign = '5387'  then 'Союз'
when [UF_STAT_AD_TYPE] = 'partner' and uf_stat_campaign = '5387'  then 'Союз'
when [UF_STAT_AD_TYPE] = 'partner' and uf_stat_campaign = '150'  then 'Союз'
when uf_source in ( 'beeline', 'beeline-installment-ref')  then 'Билайн'
when uf_source in ( 'tochkabank-installment-ref', 'tochkabank-ref')  then 'Точка'
when uf_type = 'site3_installment_lk' and uf_stat_campaign = '5469'  then 'Модуль'
end	   ,
type = 'lead',
dt = uf_registered_at
into #f
from #TMP_leads 
where [UF_STAT_CAMPAIGN] ='5469'
order by id desc


select * from  #t2 a
--order by id desc
left join reports.dbo.dm_factor_analysis_001 b on a.PhoneNumber=b.Телефон
order by b.ДатаЗаявкиПолная desc


end