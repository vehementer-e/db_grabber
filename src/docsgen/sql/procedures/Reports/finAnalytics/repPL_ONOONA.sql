


CREATE PROCEDURE [finAnalytics].[repPL_ONOONA]
	@repmonth date
	
AS
BEGIN
    SELECT [repmonth]
      ,[rowNum]
      ,[nalogObject]
      ,[balAccNum]
      ,[valCode]
      ,[restActive_IN]
      ,[restPassive_IN]
      ,[nalogBase_IN]
      ,[timeDiffNalog_IN]
      ,[timeDiffMinus_IN]
      ,[nalogDelayPassiveFR_IN] = round([nalogDelayPassiveFR_IN],0)
      ,[nalogDelayPassiveKap_IN] = round([nalogDelayPassiveKap_IN],0)
      ,[nalogDelayActiveFR_IN] = round([nalogDelayActiveFR_IN],0)
      ,[nalogDelayActiveKap_IN] = round([nalogDelayActiveKap_IN],0)
      ,[nalogDelaySPOD_IN]
      ,[restActive_OUT]
      ,[restPassive_OUT]
      ,[nalogBase_OUT]
      ,[timeDiffNalog_OUT]
      ,[timeDiffMinus_OUT]
      ,[nalogDelayPassiveFR_OUT] = round([nalogDelayPassiveFR_OUT],0)
      ,[nalogDelayPassiveKap_OUT] = round([nalogDelayPassiveKap_OUT],0)
      ,[nalogDelayActiveFR_OUT] = round([nalogDelayActiveFR_OUT],0)
      ,[nalogDelayActiveKap_OUT] = round([nalogDelayActiveKap_OUT],0)
      ,[nalogDelaySPOD_OUT]
      ,[dateLoad]
  FROM [dwh2].[finAnalytics].[repPL_ONOONA]
  where repmonth = @repmonth

END
