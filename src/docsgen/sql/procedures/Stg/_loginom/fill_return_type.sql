-- =============================================
-- Author:		А.Никитин
-- Create date: 2023-10-20
-- Description:	DWH-2285 Создать таблицу в которой будет хранится типа клиента
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC _loginom.fill_return_type @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROC _loginom.fill_return_type
as
begin
begin TRY
	SET XACT_ABORT ON;
	SET NOCOUNT ON;

	--declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	
	if OBJECT_ID ('_loginom.return_type') is not null
	begin
		SELECT @rowVersion = isnull((select max(row_ver) from _loginom.return_type), 0x0)
	end

	drop table if exists #t_return_type
	CREATE TABLE #t_return_type
	(
		row_ver binary (8) NULL,
		request_number varchar(50) NOT NULL,
		call_date date NOT NULL,
		return_type varchar(255) NULL
	)

	;with cte_log as 
	(
		select 
			row_ver = O.rowver
			,request_number = cast(O.Number AS varchar(50))
			,call_date = cast(O.Call_date as date)
			,client_type = isnull(O.client_type_2, O.client_type_1)
			,nRow = row_number() over(partition by O.Number, cast(O.Call_date as date) order by O.Call_date desc)
		from _loginom.Originationlog AS O
		where 1=1
			AND O.Number IS NOT NULL
			AND O.Stage in ('Call 1', 'Call 2')
			AND O.Call_date >= '2019-12-01'
			--AND cast(O.Call_date as date) between @saleDateFrom and @saleDateTo
			AND O.rowver > @rowVersion
	)
	INSERT #t_return_type
	(
	    row_ver,
	    request_number,
	    call_date,
	    return_type
	)
	SELECT
		L.row_ver,
		L.request_number,
		L.call_date,
		return_type = 
			CASE 
				when L.client_type in ('docred', 'active') then 'Докредитование'
				when L.client_type in ('parallel') then 'Параллельный'
				when L.client_type in ('repeated', 'repeat') then 'Повторный'
				else 'Первичный' 
			END
	FROM cte_log AS L
	WHERE L.nRow = 1 -- вычисляем последнее значение return_type за день

	CREATE UNIQUE INDEX ix
	ON #t_return_type(request_number, call_date)

	if OBJECT_ID('_loginom.return_type') is null
	begin
		CREATE TABLE _loginom.return_type
		(
			row_ver binary (8) NULL,
			request_number varchar(50) NOT NULL,
			call_date date NOT NULL,
			return_type varchar(255) NULL,
			dwh_created_at datetime,
			dwh_updated_at datetime
		)
		ON _loginom

		ALTER TABLE _loginom.return_type
		ADD CONSTRAINT PK_return_type
		PRIMARY KEY CLUSTERED (request_number, call_date)
		ON _loginom

		CREATE INDEX ix_row_ver
		ON _loginom.return_type(row_ver)
		ON _loginom
	end

	merge _loginom.return_type AS t
	using #t_return_type AS s
		on t.request_number = s.request_number
		AND t.call_date = s.call_date
	when not matched then insert
	(
	    row_ver,
	    request_number,
	    call_date,
	    return_type,
		dwh_created_at,
		dwh_updated_at
	) values
	(
	    s.row_ver,
	    s.request_number,
	    s.call_date,
	    s.return_type,
		getdate(),
		getdate()
	)
	when matched and (t.row_ver <> s.row_ver OR t.return_type <> s.return_type)
	then update SET
		t.row_ver = s.row_ver,
		t.return_type = s.return_type,
		t.dwh_updated_at = getdate()
	;

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
