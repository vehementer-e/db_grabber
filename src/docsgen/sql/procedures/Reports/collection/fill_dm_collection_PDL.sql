-- =======================================================
-- Description:	DWH-105 Реализовать отчет collection PDL
-- EXEC collection.fill_dm_collection_PDL @isDebug = 1, @external_id = '25032723148835'
-- EXEC collection.fill_dm_collection_PDL @isDebug = 1, @mode = 1
-- =======================================================
CREATE   PROC [collection].[fill_dm_collection_PDL]
	--@days int = 20, -- актуализация витрины за последние @days дней
	@mode int = 1, -- 
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0,
	@external_id nvarchar(30) = NULL
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @InsertRows int = 0, @DeleteRows int = 0
	DECLARE @maxBalanceDate date
	--DECLARE @rowVersion binary(8) = 0x0, @dateAdd datetime2(0) = '2000-01-01', @dateFile datetime2(0) = '2000-01-01'
	DECLARE @created_at datetime = '2000-01-01'

	SELECT @eventName = 'dwh2.collection.fill_dm_collection_PDL', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID ('collection.dm_collection_PDL') is not null
			AND @mode = 1
			AND @external_id IS NULL
		begin
			SELECT @created_at = isnull(dateadd(hour, -1, max(D.created_at)), '2000-01-01')
			from collection.dm_collection_PDL AS D
		end

		DROP TABLE IF EXISTS #t_deal
		CREATE TABLE #t_deal(
			external_id nvarchar(30),
			ContractStartDate date,
			[сумма платежей за все время] money
		)

		IF @external_id IS NOT NULL BEGIN
			INSERT #t_deal(
				external_id,
				ContractStartDate,
				[сумма платежей за все время]
			)
			select 
				b.external_id, 
				b.ContractStartDate,
				sum(b.[сумма поступлений]) as 'сумма платежей за все время'
			from dwh2.dbo.dm_CMRStatBalance as b
			where b.external_id = @external_id
				and b.[Тип Продукта] ='PDL'
			group by b.external_id, b.ContractStartDate
		END
		ELSE BEGIN
			INSERT #t_deal(
				external_id,
				ContractStartDate,
				[сумма платежей за все время]
			)
			select 
				b.external_id, 
				b.ContractStartDate,
				sum(b.[сумма поступлений]) as 'сумма платежей за все время'
			from dwh2.dbo.dm_CMRStatBalance as b
			WHERE b.DWHInsertedDate >= @created_at
				and b.[Тип Продукта] ='PDL'
				and b.external_id is not null
			group by b.external_id, b.ContractStartDate
		END
--select * from #t_deal order by 2 desc
		CREATE INDEX ix_external_id ON #t_deal(external_id)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_deal
			SELECT * INTO ##t_deal FROM #t_deal
		END


		drop table if exists #balance_open

		select b.external_id, b.ContractStartDate, b.bucket
		into #balance_open
		from #t_deal as t
			inner join dwh2.dbo.dm_CMRStatBalance as b
				on b.external_id = t.external_id
		--where [Тип Продукта] ='PDL' and d=cast(getdate() as date)
		where b.d = cast(getdate() as date)

--select * from #balance_open order by 2 desc;

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##balance_open
			SELECT * INTO ##balance_open FROM #balance_open
		END


		drop table if exists #balance

		select 
			c.external_id,
			c.ContractStartDate,
			c.[сумма платежей за все время],
			case 
				when o.[bucket] is not null then o.[bucket]
				else 'Погашен' 
			end as 'Бакет просрочки'
		into #balance
		from #t_deal as c 
			left join #balance_open o on c.external_id = o.external_id

--select * from #balance;

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##balance
			SELECT * INTO ##balance FROM #balance
		END


		drop table if exists #crutch_NextPaymentInfo

		select n.NextPaymentDate, n.DealId
		into #crutch_NextPaymentInfo
		from #t_deal as d
			inner join Stg._Collection.Deals as t
				on t.number = d.external_id
			inner join Stg._collection.NextPaymentInfo as n
				on n.DealId = t.Id

--select * from #crutch_NextPaymentInfo

		update #crutch_NextPaymentInfo
		set NextPaymentDate = getdate()
		where datepart(yyyy,NextPaymentDate) = 0001

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##crutch_NextPaymentInfo
			SELECT * INTO ##crutch_NextPaymentInfo FROM #crutch_NextPaymentInfo
		END


		drop table if exists #final_table

		select 
			ContractStartDate 'Дата выдачи'
			,t.Number 'Номер договора'
			,[Sum] 'Сумма кредита'
			,concat(c.LastName, ' ', c.Name, ' ', c.MiddleName) 'ФИО клиента'
			,cs.name 'Стадия коллекшин'
			,OverdueDays 'Срок просрочки'
			,t2.[Бакет просрочки]
			,cnt.Count_overdue 'количество выходов впросрочек'
			,DebtSum 'Од'
			,[Percent] 'Проценты'
			/* c.Name 'Имя'	
			,c.LastName 'Фамилия'
			,c.MiddleName'Отчество'*/
			,case when t.[CurrentAmountOwed]>=0 then t.[CurrentAmountOwed] else 0 end 'полная сумма задолжности -'
			--,CurrentAmountOwed 'сумма задолжности'
			,t2.[сумма платежей за все время] 'сумма платежей за все время'
			,case 
				when [reason_credit_vacation] ='Пролонгация PDL' 
					and period_end >=cast(getdate() as date) 
				then 1 
				else  0 
			end 'флаг активной пролнгации в настоящие время' 
			--корректировка расчета пролонгации
			--,count([d.number] ) 'количество пролонгаций'
			,t.LastPaymentSum 'сумма последнего платежа'

			,cast(t.LastPaymentDate as date) 'дата последнего платежа'
			,case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)
							end 'Дата платежа по графику'			
				,dateadd(day,- datepart(day, (case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)
						end)) + 1, 			
				convert(date, (case when datepart(yyyy,t5.NextPaymentDate) >= 2000 then cast(t5.NextPaymentDate as date)					
						end))) 'Месяц платежа по графику'	
			--,CurrentAmountOwed 'полная сумма задолжности'
			,reg.Region [Регион]
			,PermanentRegisteredAddress [Адрес]
			--далее идут данные для моих расчетов в сводной таблице
			--,cs.name 'Стадия коллекшин'
			,kk.*
			--,case when [reason_credit_vacation] is not  null and OverdueDays <3 then 1 else  0 end 'пролонгация активна' --корректировка расчета пролонгации
			--,cnt.Count_overdue 'количество просрочек'
			--,sch.MonthPay
			--,cast(getdate() as smalldatetime) 'Дата_время формирования реестра'
			--,cast(getdate() as date) 'current date'
			-- ,sch.ДатаПлатежа
			--,NextPaymentDate

			--,t2.bucket
			--,case when t.[CurrentAmountOwed]>=0 then t.[CurrentAmountOwed] else 0 end 'полная сумма задолжности (без-)'
			,case 
				when t.[OverdueDays]>0 and [Бакет просрочки]!='Погашен'
				then 1 
				else 0 
			end 'флаг нахождения в просрочке' --убрал из просрочки договора которые погашены и имеют дпд
			,rn = ROW_NUMBER() over(partition by t.Number order by kk.[period_end] desc )
			--для подсчета доли находящихся в просроске и определения последней даты пролонгации
			,[Использование пролонгации]= case when kk.period_start is not null then 1 else 0 end
		into #final_table
		from #balance as t2
			left join Stg._Collection.Deals as t
				on t.number=t2.external_id
			left join Stg._Collection.collectingStage as cs
				on cs.id = t.StageId
			LEFT JOIN Stg._Collection.customers AS c
				ON c.Id = t.IdCustomer
			LEFT JOIN Stg._Collection.Registration AS reg
				ON reg.IdCustomer = c.Id
			left join (
				SELECT  
					r.number as договор
					,r.operation_type
					,r.period_start
					,r.period_end
					,r.reason_credit_vacation
					,r.create_at
					--,case  when [period_end] is null then 1 else  0 end 'пролонгация активна'
				FROM #t_deal as d
					inner join dwh2.dbo.dm_restructurings as r
						on r.number = d.external_id
				where r.operation_type='Реструктуризация' 
					and r.reason_credit_vacation ='Пролонгация PDL'
				) as kk
				on kk.договор=t.number
			left join (
				select  Number,Count_overdue
				FROM #t_deal as d
					inner join dwh2.dbo.dm_OverdueIndicators as o
						on o.Number = d.external_id
				) as cnt 
				on cnt.Number = t.number

			--left join #schedull sch on  sch.Код=t.number
			left join #crutch_NextPaymentInfo as t5
				on t5.DealId = t.Id
			--left join #count_kk d on d.[number]=t.[number]

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##final_table
			SELECT * INTO ##final_table FROM #final_table
		END


		drop table if exists #count_kk

		SELECT 
			r.number,
			count(r.number) as 'количество пролонгаций'
		into #count_kk
		FROM #t_deal as d
			inner join dwh2.dbo.dm_restructurings as r
				on r.number = d.external_id
		where r.operation_type='Реструктуризация' 
			and r.reason_credit_vacation = 'Пролонгация PDL'
		group BY r.number

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##count_kk
			SELECT * INTO ##count_kk FROM #count_kk
		END


		drop table if exists #for_column

		select t.*,
			d.[количество пролонгаций]
			--sum([флаг активной пролнгации в настоящие время])
			--avg(Sum)
		into #for_column
		from #final_table as t
			left join #count_kk as d
				on d.number = t.[Номер договора]
		where rn = 1
			--and t.[Бакет просрочки] != 'Погашен' --and [количество пролонгаций]='3' 
			--and reason_credit_vacation='Пролонгация' 

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##for_column
			SELECT * INTO ##for_column FROM #for_column
		END

		/*
		select 
			[Дата выдачи]
			,[Номер договора]  ---int
			,cast([Сумма кредита] as int) [Сумма кредита] ---int
			,[ФИО клиента]
			,[Стадия коллекшин]
			,[Срок просрочки]
			,[Бакет просрочки]
			,[количество выходов впросрочек]
			,[Од]
			,[Проценты]
			,case 
				when [Бакет просрочки]='PreDel' or [Бакет просрочки]='Погашен' 
				then 0 
				else [полная сумма задолжности -] 
			end as [полная сумма задолжности -] --сумму задолжности из свода по предэлинку
			,[сумма платежей за все время]
			,[флаг активной пролнгации в настоящие время]
			,[количество пролонгаций]
			,[сумма последнего платежа]
			,[дата последнего платежа]
			,[Дата платежа по графику]
			,[Месяц платежа по графику]
			,[Регион]
			,[Адрес]
			,[флаг нахождения в просрочке]
			,[rn]
			,[Использование пролонгации]
		from #for_column
		*/


		drop table if exists #dpd_for_prolong

		select 
			b.external_id,
			b.d,
			b.dpd
		into #dpd_for_prolong
		from #t_deal as t
			inner join dwh2.dbo.dm_CMRStatBalance as b
				on b.external_id = t.external_id

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##dpd_for_prolong
			SELECT * INTO ##dpd_for_prolong FROM #dpd_for_prolong
		END


		drop table if exists #out_prlong

		--расчет для пролонгации
		;with prlong as (
			select 
				t.[Дата выдачи],
				t.[Номер договора],
				t.[Сумма кредита],
				t.[ФИО клиента],
				d.[количество пролонгаций],
				[Дата пролонгации 1] = t.period_start --Котелевец А.В. 05.06. 2025 для договора 25010722949803 ошибка
				/*
				DATEADD(day, -1,t.period_start) 'Дата пролонгации 1' 
				-- добавлена функция минус один день так как в таблице рестратинг данные отличаются от спейса +1 день
				*/
				,rn2 = ROW_NUMBER() over(partition by t.[Номер договора] order by t.[period_start])
				,rn3 = ROW_NUMBER() over(partition by t.[Номер договора] order by t.[period_start] desc)
				,dpd
				,[Од]
				,[Проценты]
				--,case when t.period_end>=cast(getdate() as date) then 1 else 0 end 'флаг активной пролнгации в настоящие время'
				--sum([флаг активной пролнгации в настоящие время])
				--avg(Sum)
			from #final_table as t
				left join #count_kk as d 
					on d.[number]=t.[Номер договора]
				left join #dpd_for_prolong as dpd
					on dpd.external_id = t.[Номер договора] 
					and DATEADD(day, -1, t.period_start) = dpd.d ---добавдено дпд  --?? почему 2 дня ??? 
			where reason_credit_vacation = 'Пролонгация PDL' 
			--rn=1 --and t.[Бакет просрочки] != 'Погашен' --and [количество пролонгаций]='3' 
		),
		prlong_1 as (
			select 
				[Номер договора],
				[Дата пролонгации 1] 'Дата пролонгации 1'
				-- добавлена функция минус один день так как в таблице рестратинг данные отличаются от спейса +1 день
				,dpd
			from prlong
			where rn2 = 1
			--and t.[Бакет просрочки] != 'Погашен' --and [количество пролонгаций]='3' 
		),
		prlong_2 as (
			select 
				[Номер договора],
				[Дата пролонгации 1] 'Дата пролонгации 2'
				-- добавлена функция минус один день так как в таблице рестратинг данные отличаются от спейса +1 день
				,dpd
			from prlong
			where rn2 = 2
			--and t.[Бакет просрочки] != 'Погашен' --and [количество пролонгаций]='3' 
		),
		prolong_3 as (
			select 
				[Номер договора],
				[Дата пролонгации 1] 'Дата пролонгации 3'
				,dpd
			from prlong
			where rn2 = 3
		),
		prolong_4 as (
			select 
				[Номер договора],
				[Дата пролонгации 1] 'Дата пролонгации 4'
				,dpd
			from prlong
			where rn2 = 4
		),
		prolong_5 as (
			select 
				[Номер договора],
				[Дата пролонгации 1] 'Дата пролонгации 5'
				,dpd
			from prlong
			where rn2 = 5
		)
		select 
			pr.[Дата выдачи],
			pr.[Номер договора],
			cast(pr.[Сумма кредита] as int) [Сумма кредита],
			pr.[ФИО клиента],
			pr.[количество пролонгаций]
			,pr1.[Дата пролонгации 1]
			,pr2.[Дата пролонгации 2]
			,pr3.[Дата пролонгации 3]
			,pr4.[Дата пролонгации 4]
			,pr5.[Дата пролонгации 5]
			,
			/*case when pr2.dpd >0 then 1 else 0 end +*/
			case 
				when pr.dpd >0 then 1 
				else 0 
			end 'Наличие просрочки при оформление пролонгации'
			,cast([Од] as float) [Од] 
			,cast([Проценты] as float) [Проценты]
			--,case when pr.dpd >0 then 1 else 0 end 'Наличие просрочки при оформление пролонгации-1'
			--,[флаг активной пролнгации в настоящие время]  
			--,case when pr.[Дата пролонгации 1] >=cast(getdate() as date)  then 1 else 0 end
		into #out_prlong
		from prlong as pr
			left join prlong_1 as pr1
				on pr.[Номер договора] = pr1.[Номер договора] 
			left join prlong_2 as pr2
				on pr.[Номер договора] = pr2.[Номер договора] 
			left join prolong_3 as pr3
			    on pr.[Номер договора] = pr3.[Номер договора]
			left join prolong_4 as pr4
			    on pr.[Номер договора] = pr4.[Номер договора]
			left join prolong_5 as pr5
			    on pr.[Номер договора] = pr5.[Номер договора]
		where pr.rn3=1


		DROP TABLE IF EXISTS #t_dm_collection_PDL

		select 
			created_at = getdate(),
			T.[Дата выдачи]
			,T.[Номер договора]  ---int
			,cast(T.[Сумма кредита] as int) [Сумма кредита] ---int
			,T.[ФИО клиента]
			,T.[Стадия коллекшин]
			,T.[Срок просрочки]
			,T.[Бакет просрочки]
			,T.[количество выходов впросрочек]
			,T.[Од]
			,T.[Проценты]
			,case 
				when T.[Бакет просрочки]='PreDel' or T.[Бакет просрочки]='Погашен' 
				then 0 
				else T.[полная сумма задолжности -] 
			end as [полная сумма задолжности -] --сумму задолжности из свода по предэлинку
			,T.[сумма платежей за все время]
			,T.[флаг активной пролнгации в настоящие время]
			,T.[количество пролонгаций]
			,T.[сумма последнего платежа]
			,T.[дата последнего платежа]
			,T.[Дата платежа по графику]
			,T.[Месяц платежа по графику]
			,T.[Регион]
			,T.[Адрес]
			,T.[флаг нахождения в просрочке]
			,T.[rn]
			,T.[Использование пролонгации]

			--P.[количество пролонгаций]
			,P.[Дата пролонгации 1]
			,P.[Дата пролонгации 2]
			,P.[Дата пролонгации 3]
			,P.[Дата пролонгации 4]
			,P.[Дата пролонгации 5]
			,P.[Наличие просрочки при оформление пролонгации]
			--,P.[Од] 
			--,P.[Проценты]
		INTO #t_dm_collection_PDL
		from #for_column as T
			left join #out_prlong as P
				on P.[Номер договора] = T.[Номер договора]
		where T.[Номер договора] is not null

		if @isDebug = 1 begin
			select *
			from #t_dm_collection_PDL
		end 

		CREATE INDEX ix_Номер_договора ON #t_dm_collection_PDL([Номер договора])
		
		IF object_id('collection.dm_collection_PDL') IS NULL
		BEGIN
			SELECT TOP(0)
				T.created_at
				,T.[Дата выдачи]
				,T.[Номер договора]
				,T.[Сумма кредита]
				,T.[ФИО клиента]
				,T.[Стадия коллекшин]
				,T.[Срок просрочки]
				,T.[Бакет просрочки]
				,T.[количество выходов впросрочек]
				,T.[Од]
				,T.[Проценты]
				,T.[полная сумма задолжности -] --сумму задолжности из свода по предэлинку
				,T.[сумма платежей за все время]
				,T.[флаг активной пролнгации в настоящие время]
				,T.[количество пролонгаций]
				,T.[сумма последнего платежа]
				,T.[дата последнего платежа]
				,T.[Дата платежа по графику]
				,T.[Месяц платежа по графику]
				,T.[Регион]
				,T.[Адрес]
				,T.[флаг нахождения в просрочке]
				,T.[rn]
				,T.[Использование пролонгации]

				,T.[Дата пролонгации 1]
				,T.[Дата пролонгации 2]
				,T.[Дата пролонгации 3]
				,T.[Дата пролонгации 4]
				,T.[Дата пролонгации 5]
				,T.[Наличие просрочки при оформление пролонгации]
			INTO collection.dm_collection_PDL
			FROM #t_dm_collection_PDL as T
			--alter table collection.dm_collection_PDL
			--	alter column response_Id bigint not null

			--ALTER TABLE collection.dm_collection_PDL
			--	ADD CONSTRAINT PK_dm_pravoRuBankruptcy PRIMARY KEY CLUSTERED (GuidЗаявки, Этап)

			CREATE INDEX ix_Номер_договора ON collection.dm_collection_PDL([Номер договора])
			CREATE INDEX ix_created_at ON collection.dm_collection_PDL(created_at)
		END

		BEGIN TRAN
			DELETE C
			FROM collection.dm_collection_PDL AS C
			WHERE EXISTS(
					SELECT TOP(1) 1
					FROM #t_dm_collection_PDL AS R
					WHERE R.[Номер договора] = C.[Номер договора]
				)

			INSERT collection.dm_collection_PDL
			(
				created_at
				,[Дата выдачи]
				,[Номер договора]
				,[Сумма кредита]
				,[ФИО клиента]
				,[Стадия коллекшин]
				,[Срок просрочки]
				,[Бакет просрочки]
				,[количество выходов впросрочек]
				,[Од]
				,[Проценты]
				,[полная сумма задолжности -] --сумму задолжности из свода по предэлинку
				,[сумма платежей за все время]
				,[флаг активной пролнгации в настоящие время]
				,[количество пролонгаций]
				,[сумма последнего платежа]
				,[дата последнего платежа]
				,[Дата платежа по графику]
				,[Месяц платежа по графику]
				,[Регион]
				,[Адрес]
				,[флаг нахождения в просрочке]
				,[rn]
				,[Использование пролонгации]

				,[Дата пролонгации 1]
				,[Дата пролонгации 2]
				,[Дата пролонгации 3]
				,[Дата пролонгации 4]
				,[Дата пролонгации 5]
				,[Наличие просрочки при оформление пролонгации]
			)
			SELECT
				T.created_at
				,T.[Дата выдачи]
				,T.[Номер договора]
				,T.[Сумма кредита]
				,T.[ФИО клиента]
				,T.[Стадия коллекшин]
				,T.[Срок просрочки]
				,T.[Бакет просрочки]
				,T.[количество выходов впросрочек]
				,T.[Од]
				,T.[Проценты]
				,T.[полная сумма задолжности -] --сумму задолжности из свода по предэлинку
				,T.[сумма платежей за все время]
				,T.[флаг активной пролнгации в настоящие время]
				,T.[количество пролонгаций]
				,T.[сумма последнего платежа]
				,T.[дата последнего платежа]
				,T.[Дата платежа по графику]
				,T.[Месяц платежа по графику]
				,T.[Регион]
				,T.[Адрес]
				,T.[флаг нахождения в просрочке]
				,T.[rn]
				,T.[Использование пролонгации]

				,T.[Дата пролонгации 1]
				,T.[Дата пролонгации 2]
				,T.[Дата пролонгации 3]
				,T.[Дата пролонгации 4]
				,T.[Дата пролонгации 5]
				,T.[Наличие просрочки при оформление пролонгации]
			FROM #t_dm_collection_PDL as T
		COMMIT

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка заполнения dwh2.collection.dm_collection_PDL'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH

END
