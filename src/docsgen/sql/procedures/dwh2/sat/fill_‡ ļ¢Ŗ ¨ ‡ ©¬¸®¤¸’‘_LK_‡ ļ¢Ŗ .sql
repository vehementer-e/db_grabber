CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_LK_Заявка
	@mode int = 1
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_LK_Заявка
begin try
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	SELECT @mode = isnull(@mode, 1)

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_LK_Заявка

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_LK_Заявка') is not null
		AND @mode = 1
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_LK_Заявка), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -72, max(S.lk_updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_LK_Заявка AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(GuidЗаявки nvarchar(100)) -- uniqueidentifier)

	--1
	INSERT #t_Заявки(GuidЗаявки)
	SELECT LK_Заявка.guid
	FROM Stg._LK.requests AS LK_Заявка
	WHERE LK_Заявка.updated_at >= @updated_at
		AND try_cast(LK_Заявка.guid AS uniqueidentifier) IS NOT NULL
	

	CREATE INDEX IX1
	ON #t_Заявки(GuidЗаявки)

	select distinct
		СсылкаЗаявки = LK_Заявка.СсылкаЗаявки,
		GuidЗаявки = LK_Заявка.GuidЗаявки,

		lk_request_id = LK_Заявка.id,
		lk_request_code = LK_Заявка.code,
		lk_promocode = LK_Заявка.promo_code,
		lk_created_at = LK_Заявка.lk_created_at,
		lk_updated_at = LK_Заявка.lk_updated_at,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_LK_Заявка
	FROM (
		SELECT 
			СсылкаЗаявки = Заявка.СсылкаЗаявки,
			GuidЗаявки = LKЗаявка.guid,
			LKЗаявка.Id,
			LKЗаявка.code,
			LKЗаявка.promo_code,
			lk_created_at = LKЗаявка.created_at,
			lk_updated_at = LKЗаявка.updated_at,
			rn = row_number() OVER(
				PARTITION BY LKЗаявка.guid 
				ORDER BY LKЗаявка.updated_at DESC, Заявка.НомерЗаявки DESC
			)
		FROM #t_Заявки AS T
			INNER JOIN Stg._LK.requests AS LKЗаявка
				ON LKЗаявка.guid = T.GuidЗаявки
			INNER JOIN hub.Заявка AS Заявка
				ON Заявка.GuidЗаявки = T.GuidЗаявки
		) AS LK_Заявка
	WHERE LK_Заявка.rn = 1
	

	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_LK_Заявка') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			lk_request_id,
			lk_request_code,
			lk_promocode,
			lk_created_at,
			lk_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_LK_Заявка
		from #t_ЗаявкаНаЗаймПодПТС_LK_Заявка

		alter table sat.ЗаявкаНаЗаймПодПТС_LK_Заявка
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_LK_Заявка
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_LK_Заявка PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_LK_Заявка t
		using #t_ЗаявкаНаЗаймПодПТС_LK_Заявка s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			lk_request_id,
			lk_request_code,
			lk_promocode,
			lk_created_at,
			lk_updated_at,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.lk_request_id,
			s.lk_request_code,
			s.lk_promocode,
			s.lk_created_at,
			s.lk_updated_at,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			AND t.lk_updated_at != s.lk_updated_at
		then update SET
			t.lk_request_id = s.lk_request_id,
			t.lk_request_code = s.lk_request_code,
			t.lk_promocode = s.lk_promocode,
			t.lk_created_at = s.lk_created_at,
			t.lk_updated_at = s.lk_updated_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
			;
	--commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
