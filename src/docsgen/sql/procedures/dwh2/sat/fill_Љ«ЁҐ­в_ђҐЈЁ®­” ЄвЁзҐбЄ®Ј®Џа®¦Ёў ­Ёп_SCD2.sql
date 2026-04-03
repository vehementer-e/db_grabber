
CREATE   PROC sat.fill_Клиент_РегионФактическогоПроживания_SCD2
	@portion_id uniqueidentifier
	--@mode int = 1
as
begin
	--truncate table sat.fill_Клиент_РегионФактическогоПроживания_SCD2
begin try

	--test
	--временно выключить заполнение
	--DELETE R
	--FROM sat.Клиент_РегионФактическогоПроживания_SCD2_stg AS R
	--WHERE R.portion_id = @portion_id


	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Клиент_РегионФактическогоПроживания_SCD2
	SELECT 
		R.GuidКлиент,
		R.СсылкаКлиент,
		R.date_from,
		R.date_to,
		R.РегионФактическогоПроживания,
		R.GMTРегионФактическогоПроживания,
		R.created_at,
		R.updated_at,
		R.spFillName,
		R.ВерсияДанных 
	INTO #t_Клиент_РегионФактическогоПроживания_SCD2
	FROM sat.Клиент_РегионФактическогоПроживания_SCD2_stg AS R
	WHERE R.portion_id = @portion_id

	if OBJECT_ID('sat.Клиент_РегионФактическогоПроживания_SCD2') is null
	begin
		select top(0)
			GuidКлиент,
            СсылкаКлиент,
			date_from,
			date_to,
            РегионФактическогоПроживания,
            GMTРегионФактическогоПроживания,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
		into sat.Клиент_РегионФактическогоПроживания_SCD2
		from #t_Клиент_РегионФактическогоПроживания_SCD2

		alter table sat.Клиент_РегионФактическогоПроживания_SCD2
			alter column GuidКлиент uniqueidentifier not null

		alter table sat.Клиент_РегионФактическогоПроживания_SCD2
			alter column date_from date not null

		alter table sat.Клиент_РегионФактическогоПроживания_SCD2
			alter column date_to date not null

		ALTER TABLE sat.Клиент_РегионФактическогоПроживания_SCD2
			ADD CONSTRAINT PK_Клиент_РегионФактическогоПроживания_SCD2 PRIMARY KEY CLUSTERED (GuidКлиент, date_from)
	end

	DELETE s
	FROM #t_Клиент_РегионФактическогоПроживания_SCD2 AS s
	WHERE s.РегионФактическогоПроживания IS NULL

	-- удалить то, что не изменилось
	DELETE s
	FROM #t_Клиент_РегионФактическогоПроживания_SCD2 AS s
		INNER JOIN sat.Клиент_РегионФактическогоПроживания_SCD2 AS t
			ON t.GuidКлиент = s.GuidКлиент
			AND s.date_from BETWEEN t.date_from AND t.date_to
			AND isnull(t.РегионФактическогоПроживания,'*') = isnull(s.РегионФактическогоПроживания,'*')
			AND isnull(t.GMTРегионФактическогоПроживания,99) = isnull(s.GMTРегионФактическогоПроживания,99)

	-- date_from = дата первой заявки
	-- для новых клиентов, у которых нет записей в sat
	UPDATE s
	SET date_from = isnull(T.date_from, '2000-01-01')
	FROM #t_Клиент_РегионФактическогоПроживания_SCD2 AS s
		INNER JOIN (
			SELECT 
				H.GuidКлиент,
				date_from = cast(min(R.ДатаЗаявки) AS date)
			FROM #t_Клиент_РегионФактическогоПроживания_SCD2 AS H
				LEFT JOIN link.Клиент_Заявка AS L
					ON L.GuidКлиент = H.GuidКлиент
				LEFT JOIN hub.Заявка AS R
					ON R.GuidЗаявки = L.GuidЗаявки
			WHERE NOT EXISTS(
				SELECT TOP(1) 1
				FROM sat.Клиент_РегионФактическогоПроживания_SCD2 AS X
				WHERE X.GuidКлиент = H.GuidКлиент
				)
			GROUP BY H.GuidКлиент
		) AS T
		ON T.GuidКлиент = s.GuidКлиент



	begin tran
		merge sat.Клиент_РегионФактическогоПроживания_SCD2 AS t
		using #t_Клиент_РегионФактическогоПроживания_SCD2 AS s
			on t.GuidКлиент = s.GuidКлиент
			AND t.date_from = s.date_from
		when not matched then insert
		(
			GuidКлиент,
			СсылкаКлиент,
			date_from,
			date_to,
			РегионФактическогоПроживания,
			GMTРегионФактическогоПроживания,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidКлиент,
			s.СсылкаКлиент,
			s.date_from,
			s.date_to,
			s.РегионФактическогоПроживания,
			s.GMTРегионФактическогоПроживания,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched and (
			t.ВерсияДанных <> s.ВерсияДанных
			OR t.РегионФактическогоПроживания <> s.РегионФактическогоПроживания
			OR t.GMTРегионФактическогоПроживания <> s.GMTРегионФактическогоПроживания
			)
		then update SET
			t.РегионФактическогоПроживания = s.РегионФактическогоПроживания,
			t.GMTРегионФактическогоПроживания = s.GMTРегионФактическогоПроживания,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных
		;

		DELETE R
		FROM sat.Клиент_РегионФактическогоПроживания_SCD2_stg AS R
		WHERE R.portion_id = @portion_id
	commit tran

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
