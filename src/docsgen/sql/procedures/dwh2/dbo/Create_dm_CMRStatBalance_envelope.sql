
--exec dbo.[Create_dm_CMRStatBalance_envelope] @Mode = 2
CREATE PROC [dbo].[Create_dm_CMRStatBalance_envelope]
	@Mode int,
	@isDebug int = 0
as	
begin
	SELECT @isDebug = isnull(@isDebug, 0)
	
	declare @text nvarchar(max)=N''
	,@new_line nvarchar(255) = char(10)+char(13)
	,@subject nvarchar(255) = concat_ws(' ', 'Формирование витрины CMRStatBalance', format(getdate(), 'dd.MM.yyyy HH:mm'))
	,@TotalActiveContractOnToday int -- кол активных договоров по данным из Справочник_Договоры на сегодня
	,@TotalRowOnTodayInCMRStatBalance int -- кол строк за сегодня в dm_CMRStatBalance
	,@AllTotalRowInCMRStatBalance int -- кол строк всего в dm_CMRStatBalance
	,@description nvarchar(1024)
	,@ProcessGUID nvarchar(36) = newid()
  	,@error_description nvarchar(4000)=N''
		set @text=concat_ws(' '
			, 'Старт расчета витрины CMRStatBalance @Mode = '
				, cast(@Mode as nvarchar(10))
				, format(getdate(),'dd.MM.yyyy HH:mm:ss')
				)
	if(@Mode in (0, 2))
	begin
		--DWH-1645 Расширить мониторинг формирования dm_CMRStatBalance

		-- кол договоров, которые были в статусе 'Действует' по данным из Справочник_Договоры на сегодня
		--SELECT @TotalActiveContractOnToday = count(1)
		--FROM (
		--	SELECT DISTINCT d.Ссылка
		--	FROM Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS sd
		--		INNER JOIN Stg._1ccmr.Справочник_Договоры AS d
		--			ON d.Ссылка = sd.Договор
		--		INNER JOIN Stg._1ccmr.Справочник_СтатусыДоговоров AS ssd
		--			ON ssd.Ссылка = sd.Статус
		--	WHERE ssd.Наименование='Действует'
		--	) AS A

		-- кол-во активных договоров на сегодня
		SELECT @TotalActiveContractOnToday = count(DISTINCT A.Договор)
		FROM Stg.dbo._1cАналитическиеПоказатели AS A
		WHERE convert(date, A.Период) = convert(date, getdate())

		SELECT @description =
			(
			SELECT
				'TotalActiveContractOnToday' = @TotalActiveContractOnToday
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
			@text = @text
			,@threadKey = @subject

		EXEC LogDb.dbo.LogAndSendMailToAdmin 'trying start dbo.[Create_dm_CMRStatBalance]',
			'Info','Started', @description, 1, @ProcessGUID
	end
	begin try
   
		EXEC dbo.Create_dm_CMRStatBalance 
			@Mode = @Mode,
			@isDebug = @isDebug
	
		if(@Mode in (0, 2))
		 begin

			--DWH-1645 Расширить мониторинг формирования dm_CMRStatBalance
			SELECT @TotalRowOnTodayInCMRStatBalance = count(1)
			FROM dbo.dm_CMRStatBalance AS B
			WHERE B.d = cast(getdate() AS date)

			SELECT @AllTotalRowInCMRStatBalance = count(1)
			FROM dbo.dm_CMRStatBalance AS B

			SELECT @description =
				(
				SELECT
					'TotalRowOnTodayInCMRStatBalance' = @TotalRowOnTodayInCMRStatBalance,
					'AllTotalRowInCMRStatBalance' = @AllTotalRowInCMRStatBalance
				FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
				)

			exec logdb.dbo.[LogAndSendMailToAdmin] 'exec dbo.[Create_dm_CMRStatBalance] - completed successfully',
				'Info','Done', @description, 1, @ProcessGUID

			set @text=':галочка: Расчет витрины - CMRStatBalance_2 завершен успешно. @Mode = ' + cast(@Mode as nvarchar(10)) +' ' +format(getdate(),'dd.MM.yyyy HH:mm:ss')

			EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				,@threadKey = @subject
        end
        
	end try
	begin catch
		set @error_description =concat('ErrorNumber: ',cast(format(ERROR_NUMBER(),'0') as nvarchar(50)),	
			@new_line,
			' ErrorSEVERITY: ', cast(format(ERROR_SEVERITY(),'0') as nvarchar(50)),
			@new_line,
			' ErrorState: ', cast(format(ERROR_State(),'0') as nvarchar(50)),
			@new_line,
			' ErrorProcedure: ', isnull( ERROR_PROCEDURE() ,''),
			@new_line,
			' Error_line: ', cast(format(ERROR_LINE(),'0') as nvarchar(50)),
			@new_line,
			' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
			)
      	
		set @text=':exclamation: Расчет витрины - CMRStatBalance. завершился с ошибкой. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		
      	EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
		--		,@threadKey = @subject
		EXEC  [CommonDb].[SendNotification].[Send2GChat_DwhAlarm]
			@text = @text
	--		,@threadKey = @subject

      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error dbo.[Create_dm_CMRStatBalance]',
			'Error','Error',@error_description, 1, @ProcessGUID
      
		;throw 51000, @error_description, 1
	end catch

end
