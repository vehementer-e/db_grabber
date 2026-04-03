CREATE   procedure [dm].[fill_Клиенты_Без_Установленного_ИНН]
as
begin
begin try
	drop table if exists #t
		--DWH-132 берем клиентов у которых есть активный договор и источник данных не FNS
	select distinct 
			  CRMClientId			= Клиент.GuidКлиент
			 ,firstName				= Клиент.Имя
			 ,lastName				= Клиент.Фамилия
			 ,secondName			= Клиент.Отчество
			 ,dateOfBirth			= Клиент.ДатаРождения
			 ,passportSerialNumber	= Клиент_ПаспортныеДанные.Серия
			 ,passportNumber		= Клиент_ПаспортныеДанные.Номер
			 ,dateOfIssue			= Клиент_ПаспортныеДанные.ДатаВыдачи
			 ,type					= 'client'
			 ,created_at			 = getdate()
			 ,Клиент_ИНН.ТаблицаИсточник
			 ,Клиент_ИНН.sourceService
	into #t
	from  hub.Клиенты Клиент 
	inner join sat.Клиент_ПаспортныеДанные Клиент_ПаспортныеДанные
			on Клиент_ПаспортныеДанные.GuidКлиент =Клиент.GuidКлиент
	left join dm.v_Клиент_ИНН  Клиент_ИНН 
			on  Клиент_ИНН.GuidКлиент = Клиент.GuidКлиент
		
	where  1=1
	and (isnull(Клиент_ИНН.sourceService, '') not in ('fns') -- система источника данных не 'fns'
		or  Клиент_ИНН.GuidКлиент is null --инн нет
		)
	and	exists (select top(1) 1 from dbo.dm_CMRStatBalance b 
	where b.d = cast(getdate() as date)
		and b.CMRClientGUID = Клиент.GuidКлиент
	)  --Только действующий клиенты
	
	union
	--берем клиентов из ипорта, как доп источник
	select  distinct  CRMClientId			= Клиент.GuidКлиент
			 ,firstName				= Клиент.Имя
			 ,lastName				= Клиент.Фамилия
			 ,secondName			= Клиент.Отчество
			 ,dateOfBirth			= Клиент.ДатаРождения
			 ,passportSerialNumber	= Клиент_ПаспортныеДанные.Серия
			 ,passportNumber		= Клиент_ПаспортныеДанные.Номер
			 ,dateOfIssue			= Клиент_ПаспортныеДанные.ДатаВыдачи
			 ,type					= 'client'
			 ,created_at			 = getdate() 
			 ,ТаблицаИсточник		= 'Import'
			 ,sourceService			= null
	from stg.files.clients_withoutinn_final t
	inner join hub.Клиенты Клиент on CONCAT_WS(' '
		,Клиент.Фамилия
		,Клиент.Имя
		,Клиент.Отчество) = t.[ФИО / Наименование заемщика]
		and Клиент.ДатаРождения = t.[Дата рождения заемщика]
	inner join sat.Клиент_ПаспортныеДанные Клиент_ПаспортныеДанные
			on Клиент_ПаспортныеДанные.GuidКлиент =Клиент.GuidКлиент
	where not exists(select top(1) 1 from dm.v_Клиент_ИНН  Клиент_ИНН 
		where Клиент_ИНН.GuidКлиент = Клиент.GuidКлиент)

	;with cte as (
		select *, nRow = ROW_NUMBER() OVER(PARTITION BY CRMClientId order by (select 1))  from #t
	)
	delete from cte
	where nRow>1
	begin tran
	--удалим тех которых есть инн
			delete t from [dm].[Клиенты_Без_Установленного_ИНН] t
				where exists(select top(1) 1 from  dm.v_Клиент_ИНН  s
			where s.GuidКлиент = t.CRMClientId
			and s.sourceService='fns')

			--truncate table [dm].[Клиенты_Без_Установленного_ИНН]
		
			
			--2 обновить паспортные данные в реестре
			merge dm.[Клиенты_Без_Установленного_ИНН] AS t
			using #t AS s
				ON t.CRMClientId = s.CRMClientId
			when not matched then insert
			(
				CRMClientId, 
				dateOfBirth, 
				lastName, 
				firstName, 
				secondName, 
				passportSerialNumber, 
				passportNumber, 
				dateOfIssue,
				row_id,
				created_at
			) values
			(
				CRMClientId, 
				dateOfBirth, 
				lastName, 
				firstName, 
				secondName, 
				passportSerialNumber, 
				passportNumber, 
				dateOfIssue,
				newid(),
				getdate()

			)
			;
		
			
		COMMIT TRAN 

end try
begin catch
	if @@TRANCOUNT>0
			rollback tran;
		;throw
end catch
end