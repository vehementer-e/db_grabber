

CREATE PROC [finAnalytics].[loadPBR_PDNCheck] 
				@repmonth date
				,@nameData varchar(20)
				,@errorCount int output

AS
BEGIN

	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	set @nameData =trim(@nameData)
	drop table if exists #Data
	create table #Data
			(
			[Номер договора] nvarchar(255)
			,[ПДН на дату выдачи (НЕ для ЦБ)] float
			,[ПДН на отчетную дату] float
			,[Номенклатурная группа] nvarchar(50)
			,[Дата выдачи] nvarchar(50)
			,[Контрагент] nvarchar(255)
			)
	declare @isNullPDN1 varchar(max) = null
	declare @isNullPDN2 varchar(max) = null
	if @nameData='monthly'
		insert into #Data 
					select 
						a.[Номер договора]
						,a.[ПДН на дату выдачи (НЕ для ЦБ)]
						,a.[ПДН на отчетную дату]
						,a.[Номенклатурная группа]
						,a.[Дата выдачи]
						,a.[Контрагент]
					from stg.[files].[pbr_monthly] a	--select * from stg.[files].[pbr_monthly]
					left join stg.[files].[Samozanyat] sz on a.[Номер договора] = sz.[Номер договора]
					where 
						[Признак заемщика] = 'ФЛ'
						and convert(date,a.[Дата выдачи],104) between @repmonth and EOMONTH(@repmonth)
						and upper([Номенклатурная группа]) not like upper('%Самозанят%')
						and sz.[Номер договора] is null
						--1.3.6. Кредиты (займы), предоставленные заемщикам, зарегистрированным по месту пребывания или по месту жительства на 
						--территориях Донецкой Народной Республики, Луганской Народной Республики, Запорожской и Херсонской областей.
						and (
							upper(a.[Адрес регистрации]) not like upper('%Донецкая %')
							and upper(a.[Адрес регистрации]) not like upper('%Луганская %')
						    and upper(a.[Адрес регистрации]) not like upper('%Запорожская %')
							and upper(a.[Адрес регистрации]) not like upper('%Херсонская %')
							--upper(a.[Адрес проживания]) not like upper('%Донецк%')
							--or upper(a.[Адрес проживания]) not like upper('%Луганск%')
						 --   or upper(a.[Адрес проживания]) not like upper('%Запорожск%')
							--or upper(a.[Адрес проживания]) not like upper('%Херсон%')
							)
	if @nameData='weekly'
			insert into #Data 
					select 
						a.[Номер договора]
						,a.[ПДН на дату выдачи (НЕ для ЦБ)]
						,a.[ПДН на отчетную дату]
						,a.[Номенклатурная группа]
						,a.[Дата выдачи]
						,a.[Контрагент]
					from stg.[files].[pbr_weekly]	a
					left join stg.[files].[Samozanyat] sz on a.[Номер договора] = sz.[Номер договора]
					where 
						[Признак заемщика] = 'ФЛ'
						and convert(date,a.[Дата выдачи],104) between DateFromParts(year(@repmonth),month(@repmonth),1) and @repmonth
						and upper([Номенклатурная группа]) not like upper('%Самозанят%')
						and sz.[Номер договора] is null
						and (
							upper(a.[Адрес регистрации]) not like upper('%Донецкая %')
							and upper(a.[Адрес регистрации]) not like upper('%Луганская %')
						    and upper(a.[Адрес регистрации]) not like upper('%Запорожская %')
							and upper(a.[Адрес регистрации]) not like upper('%Херсонская %')
							--upper(a.[Адрес проживания]) not like upper('%Донецк%')
							--or upper(a.[Адрес проживания]) not like upper('%Луганск%')
						 --   or upper(a.[Адрес проживания]) not like upper('%Запорожск%')
							--or upper(a.[Адрес проживания]) not like upper('%Херсон%')
							)
	 set @errorCount = (
						select count(*) from #Data
						where 
						(
							cast(replace(isnull([ПДН на дату выдачи (НЕ для ЦБ)],0),',','.') as float) = 0 
							or
							cast(replace(isnull([ПДН на отчетную дату],0),',','.') as float) = 0 
						))
	 
	 
	 set @isNullPDN1 =
			(
			select
				isnull(STRING_AGG(
								concat(
										[Номер договора]
										,'   '
										,[Номенклатурная группа]
										,'   '
										,[Дата выдачи]
										,'   '
										,[Контрагент]
										,char(10)
										,char(13)
										),'; '),'-')
			from #Data
			where 
				cast(replace(isnull([ПДН на дату выдачи (НЕ для ЦБ)],0),',','.') as float) = 0 
			)
	set @isNullPDN2 = 
			(
			select
				isnull(STRING_AGG(
								concat(
										[Номер договора]
										,'   '
										,[Номенклатурная группа]
										,'   '
										,[Дата выдачи]
										,'   '
										,[Контрагент]
										,char(10)
										,char(13)
										),'; '),'-')
			from #Data
			where 
				cast(replace(isnull([ПДН на отчетную дату],0),',','.') as float) = 0 
			)
	 if (@isNullPDN1!='-' or @isNullPDN2!='-')
		begin
			declare @body_text3 nvarchar(MAX) = CONCAT
				('В ПБР найдены договора ФЛ с датой выдачи в отчетном месяце с нулевым ПДН: '
                 ,'Отчетный месяц: '
				 ,FORMAT( @repmonth, 'MMMM yyyy', 'ru-RU' )
                 ,char(10)
                 ,char(13)
                 ,'ПДН на дату выдачи (НЕ для ЦБ): '
				 ,char(10)
                 ,char(13)
				 ,@isNullPDN1
                 ,char(10)
                 ,char(13)
                 ,'ПДН на отчетную дату: '
				 ,char(10)
                 ,char(13)
				 ,@isNullPDN2
				 ,char(10)
                 ,char(13)
				 ,'Загрузка не остановлена.'
                )
			declare @subject3  nvarchar(200)  = CONCAT('В ПБР найдены новые договора ФЛ с нулевым ПДН за ',FORMAT( eoMONTH(@REPMONTH), 'MMMM yyyy', 'ru-RU' ))
			declare @emailList varchar(255)=''
			set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,5,31))
			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
				,@recipients = @emailList
				,@copy_recipients = ''
				,@body = @body_text3
				,@body_format = 'TEXT'
				,@subject = @subject3;
     end
	drop table if exists  #Data

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

end