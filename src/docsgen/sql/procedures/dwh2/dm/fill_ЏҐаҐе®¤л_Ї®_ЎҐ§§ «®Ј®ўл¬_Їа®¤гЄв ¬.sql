CREATE   PROC dm.fill_Переходы_по_беззалоговым_продуктам
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table dm.Переходы_по_беззалоговым_продуктам
begin try
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	DECLARE @Period datetime2(0) = '2000-01-01'

	SELECT @mode = isnull(@mode, 1)

	if OBJECT_ID ('dm.Переходы_по_беззалоговым_продуктам') is not NULL
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from dm.Переходы_по_беззалоговым_продуктам), 0x0)
		SELECT @Period = isnull((select dateadd(HOUR, -3, max(Период)) from dm.Переходы_по_беззалоговым_продуктам), '2000-01-01')
	end


	drop table if exists #t_Заявки
	SELECT DISTINCT
		СсылкаЗаявки = D.Ссылка,
		GuidЗаявки = cast([dbo].[getGUIDFrom1C_IDRREF](D.Ссылка) as uniqueidentifier),
		НомерЗаявки = D.Номер
	into #t_Заявки
	FROM Stg._1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов AS R
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS D
			ON R.Объект_Ссылка = D.Ссылка
	WHERE 1=1
		AND D.Номер NOT LIKE '%-%'
		AND R.Период >= dateadd(YEAR, 2000, @Period)
		AND R.Реквизит = 'ПДЛ'


	drop table if exists #t_Переходы_по_беззалоговым_продуктам
	SELECT
		created_at = CURRENT_TIMESTAMP,
		T.СсылкаЗаявки,
		T.GuidЗаявки,
		T.НомерЗаявки,
		Период = dateadd(year, -2000, R.Период),
		isPDL = CASE R.ЗначениеРеквизитаПослеПредставление when 'Да' then 1 else 0 end,
		isInitialProduct = CASE when row_number() over(partition by R.Объект_Ссылка order by R.Период)=1 then 1 else 0 end
		--,R.* 
	into #t_Переходы_по_беззалоговым_продуктам
	FROM Stg._1cCRM.РегистрСведений_ИсторияИзмененияРеквизитовОбъектов AS R
		INNER JOIN #t_Заявки AS T
			ON T.СсылкаЗаявки = R.Объект_Ссылка
	WHERE 1=1
		AND R.Реквизит = 'ПДЛ'

	if OBJECT_ID('dm.Переходы_по_беззалоговым_продуктам') is null
	begin
		select top(0)
			created_at,
			СсылкаЗаявки,
			GuidЗаявки,
			НомерЗаявки,
			Период,
			isPDL,
			isInitialProduct
		into dm.Переходы_по_беззалоговым_продуктам
		from #t_Переходы_по_беззалоговым_продуктам

		--alter table dm.Переходы_по_беззалоговым_продуктам
		--	alter column GuidЗаявки uniqueidentifier not null

		--ALTER TABLE dm.Переходы_по_беззалоговым_продуктам
		--	ADD CONSTRAINT PK_Переходы_по_беззалоговым_продуктам PRIMARY KEY CLUSTERED (GuidЗаявки)

		CREATE INDEX ix_НомерЗаявки
		ON dm.Переходы_по_беззалоговым_продуктам(НомерЗаявки, Период)
	end
	
	begin TRAN
		--удалить данные по выбранным заявкам
		DELETE D
		FROM dm.Переходы_по_беззалоговым_продуктам AS D
			INNER JOIN #t_Заявки AS T
				ON D.НомерЗаявки = T.НомерЗаявки
		--WHERE D.Период >= @Period

		INSERT dm.Переходы_по_беззалоговым_продуктам
		(
			created_at,
			СсылкаЗаявки,
			GuidЗаявки,
			НомерЗаявки,
			Период,
			isPDL,
			isInitialProduct
		)
		SELECT 
			T.created_at,
			T.СсылкаЗаявки,
			T.GuidЗаявки,
			T.НомерЗаявки,
			T.Период,
			T.isPDL,
			T.isInitialProduct
		FROM #t_Переходы_по_беззалоговым_продуктам AS T

	commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
