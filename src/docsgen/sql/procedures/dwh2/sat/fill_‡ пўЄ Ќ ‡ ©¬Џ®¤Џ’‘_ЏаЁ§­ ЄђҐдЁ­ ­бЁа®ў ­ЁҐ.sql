CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
	--if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование') is not null
	--begin
	--	set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование), 0x0)
	--end

	--1
	select distinct
		СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка,
		GuidЗаявки = cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier),
		ПризнакРефинансирование = cast(1 AS bit),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(Партнеры.ВерсияДанных AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
	--SELECT *
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
		INNER JOIN Stg._1cCRM.Справочник_Офисы AS Офисы
			ON ЗаявкаНаЗаймПодПТС.Офис = Офисы.Ссылка
			AND Офисы.Код = '3645' --Партнер № 3645 Рефинансирование 
	--where ???.ВерсияДанных >= @rowVersion

	--2
	INSERT #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
	select distinct
		СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка,
		GuidЗаявки = cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier),
		ПризнакРефинансирование = cast(1 AS bit),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(???.ВерсияДанных AS binary(8)) -- в Регистрах нет поля ВерсияДанных
	--SELECT *
	FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС
		INNER JOIN Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS Изменения
			ON ЗаявкаНаЗаймПодПТС.Ссылка = Изменения.Заявка
		INNER JOIN Stg._1cCRM.Справочник_Офисы AS Офисы
			ON Изменения.Офис = Офисы.Ссылка
			AND Офисы.Код = '3645' --Партнер № 3645 Рефинансирование 
		LEFT JOIN #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование AS X
			ON X.СсылкаЗаявки = ЗаявкаНаЗаймПодПТС.Ссылка
	WHERE X.СсылкаЗаявки IS NULL -- не добавлена на шаге 1

	create index ix1
	on #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование(GuidЗаявки)


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
            ПризнакРефинансирование,
            created_at,
            updated_at,
            spFillName
		into sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
		from #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование

		alter table sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	begin tran
		/*
		TRUNCATE TABLE sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование

		INSERT sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
		SELECT 
			СсылкаЗаявки,
            GuidЗаявки,
            ПризнакРефинансирование,
            created_at,
            updated_at,
            spFillName
		FROM #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование
		*/

		merge sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование t
		using #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
            ПризнакРефинансирование,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
            s.ПризнакРефинансирование,
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched --and t.ВерсияДанных != s.ВерсияДанных
			and t.ПризнакРефинансирование <> s.ПризнакРефинансирование
		then update SET
			t.ПризнакРефинансирование = s.ПризнакРефинансирование,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			;

		-- удалить записи, удаленные в источнике
		if exists(
			select top(1) 1
			from sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование as t
				left join #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование as s
					on t.GuidЗаявки = s.GuidЗаявки
			where s.GuidЗаявки is null
			)
		begin
			delete t
			from sat.ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование as t
				left join #t_ЗаявкаНаЗаймПодПТС_ПризнакРефинансирование as s
					on t.GuidЗаявки = s.GuidЗаявки
			where s.GuidЗаявки is null
		end
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
