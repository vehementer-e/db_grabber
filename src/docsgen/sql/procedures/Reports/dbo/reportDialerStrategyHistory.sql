-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 17.04.2019
-- Description:	Отчет для проекта Dialer по сформированной стратегии
-- exec reportDialerStrategyHistory '20190417',3
-- =============================================
CREATE PROCEDURE reportDialerStrategyHistory
    @StrategyDate date='20190417'
  , @filterNo int=1
AS
BEGIN
	
	SET NOCOUNT ON;

  declare @dt smalldatetime
  --  ,@StrategyDate date='20190417'
 -- , @filterNo int=1
  ,@historyGUID uniqueidentifier
                

  set @historyGUID= (select max([guid]) from dwh_new.dialer.Strategy_history where logdatetime= (select max(logdatetime) from dwh_new.dialer.Strategy_history where logDateTime>@strategydate))
  --select @historyGUID

  select [logDateTime]
      ,[filter]
      ,[filterNO]
      ,[guid]
      ,[external_id]
      ,[fio]
      ,[birth_date]
      ,[credit_date]
      ,[credit_amount]
      ,[fraud_flag]
      ,[agent_flag]
      ,[agent_name]
      ,[overdue_amount]
      ,[principal_rest]
      ,[total_rest]
      ,[dpd]
      ,[dpd_bucket]
      ,[last_pay_date]
      ,[last_pay_amount]
      ,[adress_projivaniya]
      ,[adress_registraciyi]
      ,[ТелефонМобильный]
      ,[ТелСупруги]
      ,[ТелефонАдресаПроживания]
      ,[ТелефонКонтактныйОсновной]
      ,[ТелефонКонтактныйДополнительный]
      ,[КонтактноеЛицоТелМобильный]
      ,[КонтактноеЛицоТелКонтактный]
      ,[ТелМобильныйРуководителя]
      ,[ТелРабочийРуководителя]
      ,[tel_1_mts]
      ,[tel_2_mts]
      ,[tel_3_mts]
      ,[tel_4_mts]
      ,[tel_5_mts]
      ,[tel_6_mts]
      ,[tel_7_mts]
      ,[email]
       from dwh_new.dialer.Strategy_history where  [guid]=@historyGUID
  and filterno=@filterNo
  

END
