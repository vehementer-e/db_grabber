-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-11-20
-- Description:	Создание основной таблицы
-- exec _loginom.[loginom_blacklists_mfo_umfo_collection]
-- =============================================

CREATE PROC [dm].[blacklists_mfo_umfo_collection]
	-- Add the parameters for the stored procedure here

AS

-- 16.03.2020 меняем [c1-vsr-sql09] на [C2-VSR-LSQL]
-- 14.01.2021 DWH-907
BEGIN  --auxtab_RequestMFO_1c

	SET NOCOUNT ON;
	SET XACT_ABORT ON;
begin try

	/*DWH-1042*/
	drop table if exists #t_РегистрСведений_ЧерныеСпискиФЛ
	select top(0) FIO, birthdate, passport
	into #t_РегистрСведений_ЧерныеСпискиФЛ
	from dm.blacklists
	

	insert into #t_РегистрСведений_ЧерныеСпискиФЛ
select distinct
		ФИО,
		dateadd(year,-2000,ДатаРождения) birthdate,
		concat(NULLIF(СерияДок, ''), ' ', NULLIF(НомДок, '')) as passport

	 from stg.[_1CIntegration].[РегистрСведений_ЧерныеСпискиФЛ]
	 outer apply OPENJSON(ДопСвойства, '$."СведФЛИП"')
	  WITH (
			СерияДок NVARCHAR(50) N'$."СведДокУдЛичн"."СерияДок"',
			НомДок NVARCHAR(50) N'$."СведДокУдЛичн"."НомДок"'
		 ) js 
		 where ISJSON(ДопСвойства) > 0
	 and nullif(concat(NULLIF(СерияДок, ''), ' ', NULLIF(НомДок, '')), '') is not null

	insert into #t_РегистрСведений_ЧерныеСпискиФЛ
	select distinct
		ФИО,
		dateadd(year,-2000,ДатаРождения) birthdate,
		PASSPORT
	  from stg.[_1CIntegration].[РегистрСведений_ЧерныеСпискиФЛ]
	 outer apply OPENJSON(ДопСвойства)
	 		 WITH (
			PASSPORT NVARCHAR(125) N'$.PASSPORT'
		 ) js 
		 where ISJSON(ДопСвойства) > 0
	 and js.passport is not null

	insert into #t_РегистрСведений_ЧерныеСпискиФЛ
	select distinct
	 ФИО,
		dateadd(year,-2000,ДатаРождения) birthdate,
		PASSPORT
	 from  stg.[_1CIntegration].[РегистрСведений_ЧерныеСпискиФЛ]
	outer apply OPENJSON(ДопСвойства, '$."ФЛ"."СписокДокументов"."Документ"')
	 		 WITH (
			
			PASSPORT NVARCHAR(125) N'$."Номер"'
		 ) js 
		 where ISJSON(ДопСвойства) > 0
	and js.passport is not null

	insert into #t_РегистрСведений_ЧерныеСпискиФЛ
	 select distinct
		ФИО,
		dateadd(year,-2000,ДатаРождения) birthdate,
		null passport
	  from stg.[_1CIntegration].[РегистрСведений_ЧерныеСпискиФЛ]
	 
		where ISJSON(ДопСвойства) = 0

	insert into #t_РегистрСведений_ЧерныеСпискиФЛ
	select ФИО,
		dateadd(year,-2000,ДатаРождения) birthdate,
		null as passport
		from stg.[_1CIntegration].[РегистрСведений_ЧерныеСпискиФЛ] s
	where not exists(select top(1) 1 from #t_РегистрСведений_ЧерныеСпискиФЛ t
	where t.FIO = s.ФИО
		and t.birthdate = dateadd(year,-2000, s.ДатаРождения))



	drop table if exists #t0
	SELECT distinct 
		concat(TRIM(Фамилия),' ', TRIM(Имя),' ', TRIM(Отчество)) fio, 
		dateadd(year,-2000,cast(ДатаРождения as datetime2)) birthdate, 
		N'МФО' type
		,cast(null as varchar(255)) as passport
		,cast(a.ИНН as nvarchar(30)) as inn --DWH-2673
		,cast(null as varchar(36)) as row_id
	into #t0
	FROM stg.[_1cMFO].[РегистрСведений_ГП_ЧерныйСписок] a
	where a.Исполнитель in (0x814E00155D01BF0711E805CA62D369F2,0xA2D200155D4D095311E9168477E33435,0xA2D600155D4D153311E9B829C88DD3F0)
		or cast(период as date) >= '40190901'
  
	union all
	SELECT
		FIO,
		birthdate, 
		'ИнтеграцияФЛ' as [type],
		passport, 
		cast(null as nvarchar(30)) as inn,
		cast(null as varchar(36)) as row_id
	FROM #t_РегистрСведений_ЧерныеСпискиФЛ

	union all

	SELECT DISTINCT
		D.ФИО AS fio, 
		dateadd(year,-2000,D.ДатаРождения) AS birthdate,
		N'ПЭТ' AS type, 
		concat(NULLIF(D.СерияПаспортаРФ, ''), ' ', NULLIF(D.НомерПаспортаРФ, '')) as passport,
		nullif(trim(D.ИНН), '') AS inn,
		cast(null as varchar(36)) as row_id
	FROM stg._1cUMFO.[Документ_АЭ_ПереченьТеррористовЭкстремистов_Данные] AS D
	where D.ссылка in(SELECT top 1 ссылка FROM stg._1cUMFO.[Документ_АЭ_ПереченьТеррористовЭкстремистов] order by дата desc)
	
	union all

	SELECT distinct 
		фио fio,
		birthdate = iif	(year(ДатаРождения)>3000
			, dateadd(year,-2000, ДатаРождения)
			,NULLIF(ДатаРождения,'')),
		N'ФРОМУ' type,
		cast(null as varchar(255)) as passport,
		cast(null as nvarchar(30)) as inn,
		cast(null as varchar(36)) as row_id
	
	FROM stg._1cUMFO.[Документ_АЭ_ПереченьФРОМУ_Данные]
	where ссылка in(SELECT top 1 ссылка
	FROM stg._1cUMFO.[Документ_АЭ_ПереченьФРОМУ]
	order by дата desc)
	 union ALL

	SELECT distinct 
		fio = фио ,
		birthdate = iif	(year(ДатаРождения)>3000
			, dateadd(year,-2000, ДатаРождения)
			,NULLIF(ДатаРождения,'')),
		type = N'СБООН' ,
		passport = cast(null as varchar(255)),
		inn = cast(null as nvarchar(30)),
		row_id = cast(null as varchar(36))
	FROM stg._1cUMFO.Документ_АЭ_ПереченьСБООН_Данные	  t
	where ссылка in(SELECT top 1 ссылка
	FROM stg._1cUMFO.Документ_АЭ_ПереченьСБООН
	order by дата desc)
	and  t.фио>''

	
	union ALL
    
	SELECT distinct 
		фио fio,
		case when ДатаРождения <> '' then ДатаРождения  end birthdate, 
		N'Комиссия' type, 
		concat(NULLIF(ДокументСерия	, ''), ' ', NULLIF(ДокументНомер, '')) as passport,
		cast(null as nvarchar(30)) as inn,
		cast(null as varchar(36)) as row_id
	FROM stg._1cUMFO.Документ_АЭ_СписокРешенийМежведомственнойКомиссии_решения
	where ссылка in(SELECT top 1 ссылка FROM stg._1cUMFO.Документ_АЭ_СписокРешенийМежведомственнойКомиссии order by дата desc)

	/*DWH-907*/
	union ALL

	select 
		FIO,
		BirthdayDt as birthdate,
		case 
			when FraudConfirmed = 1then 'CollectionFraudConfirmed'
			when HardFraud = 1 then 'CollectionHardFraud'
			end as type,
		passport,
		nullif(trim(t.ИНН), '') AS inn,
		cast(null as varchar(36)) as row_id
	from (
		select 
			c.CrmCustomerId,
			concat( cpd.LastName, ' ', cpd.[FirstName],  ' ', cpd.MiddleName) as fio
			, FraudConfirmed = SIGN(SUM(case when cst.name in ('Fraud подтвержденный') then 1 else 0           end))
			, HardFraud      = SIGN(SUM(case when cst.name in ('HardFraud')   then 1 else 0           end))
			,concat(NULLIF(cpd.Series, ''), ' ', NULLIF(cpd.Number, '')) as passport
			,BirthdayDt
			,inn.ИНН
		from Stg._Collection.[CustomerStatus] cs 
			join Stg._Collection.Customers c on c.Id = cs.CustomerId  
			join Stg._Collection.CustomerState cst on cs.CustomerStateId=cst.Id 
			left join Stg.[_Collection].[CustomerPersonalData] cpd on cpd.IdCustomer = c.Id

			LEFT JOIN dm.v_Клиент_ИНН inn
				ON inn.GuidКлиент = c.CrmCustomerId
			

		where cs.IsActive=1  
		group by CrmCustomerId,
			concat( cpd.LastName, ' ', cpd.[FirstName],  ' ', cpd.MiddleName)
			,concat(NULLIF(cpd.Series, ''), ' ', NULLIF(cpd.Number, ''))
			,BirthdayDt
			,inn.ИНН
		having SIGN(SUM(case when cst.name in ('Fraud подтвержденный') then 1 else 0           end)) =1
			or SIGN(SUM(case when cst.name in ('HardFraud')   then 1 else 0           end)) =1
	 ) t
  

	UPDATE L
	SET row_id = 
		cast(
			hashbytes(
				'SHA2_256',
				concat(L.fio, '|', convert(varchar(10), L.birthdate, 120), '|', L.type, '|', L.passport)
			) AS uniqueidentifier
		)
	from #t0 AS L

begin tran

	delete from dm.blacklists_history  
		where [date]=cast(dateadd(day,-1,getdate()) as date)

	insert into dm.blacklists_history(
		[fio], 
		[birthdate], 
		[type], 
		[date], 
		[passport],
		inn,
		row_id
		)
	select [fio], 
		[birthdate], 
		[type], 
		[date], 
		[passport],
		inn,
		row_id
	FROM dm.blacklists with (nolock)
	


	truncate table dm.blacklists;

	insert into dm.blacklists
	(
		[fio], [birthdate], [type], [date], [passport], inn, row_id
	)
	select 
		[fio],
		[birthdate],
		[type],
		cast(getdate() as date) as [date],
		nullif(passport,'') as passport,
		inn,
		row_id
	FROM #t0

commit tran


	--delete from [LOGINOMDB].loginomdb.dbo.[blacklists];

	--insert into [LOGINOMDB].loginomdb.dbo.blacklists
	--select [fio] ,[birthdate] ,[type] , cast(getdate() as date)  as [date] , nullif(passport,'') as passport from #t0
end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch
END
