CREATE PROCEDURE collection.fill_dm_client_portrait
	@ReportDate date = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportDate IS NULL
		SET @ReportDate = cast(getdate() as date);
	
	BEGIN TRY

        --------------------------------------------------------------------
        -- 1. Выбираем данные за сегодня во временную таблицу 
        --------------------------------------------------------------------
		select
			bal.d as SliceDate,
			concat(dog.Фамилия, ' ', dog.Имя, ' ', dog.Отчество) as ClientFio,
			cl_dog.GuidКлиент as ClientGUID,
			dog.[ДатаРождения] as BirthDate,
			substring(cl.Пол, 1, 1) as Gender,
			case when cl.ФизЛицо = 1 then 'Наёмный работник' else 'ИП' end as EmploymentType,
			dog.КодДоговораЗайма as Number,
			dog.ДатаДоговораЗайма as ContractStart,
			MONTH(dog.ДатаДоговораЗайма) as ContractStartMonth,
			bal.dpd,
			'' as bucket
		into #daily_slice
		from
			dwh2.hub.ДоговорЗайма dog
			inner join
			dwh2.link.Клиент_ДоговорЗайма cl_dog on cl_dog.КодДоговораЗайма = dog.КодДоговораЗайма
			inner join
			dwh2.hub.Клиенты cl on cl.GuidКлиент = cl_dog.GuidКлиент
			inner join
			[dwh2].[dbo].[dm_CMRStatBalance] bal on bal.external_id = dog.КодДоговораЗайма and bal.d = @ReportDate
		where
			bal.dpd > 0;

        --------------------------------------------------------------------
        -- 3. Если нет таблицы collection.dm_client_portret – создаём её
        --------------------------------------------------------------------
        IF OBJECT_ID('collection.dm_client_portret', 'U') IS NULL
        BEGIN
            SELECT TOP (0) *
            INTO collection.dm_client_portret
            FROM #daily_slice;
        END;
        --------------------------------------------------------------------
        -- 2. загрузкa в dm_client_portrait
        --------------------------------------------------------------------
        BEGIN TRAN;
        
		IF DAY(GETDATE()) <> 1
        BEGIN
            ----------------------------------------------------------------
            -- если сегодня НЕ 1-е - удаляем записи за вчера 
            ----------------------------------------------------------------
            DELETE T
            FROM collection.dm_client_portret AS T
            WHERE T.SliceDate = DATEADD(DAY, -1, CAST(GETDATE() AS date));
        END

        INSERT INTO collection.dm_client_portret
        SELECT *
        FROM #daily_slice;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
    END CATCH;
END;
