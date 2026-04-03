
CREATE   PROC [dm].[Update_реестр_просрочников_для_запроса_ИНН]
as
BEGIN
	SET XACT_ABORT ON

	begin try
		--delete from dm.реестр_просрочников_для_запроса_ИНН
		drop table if exists #t
		
		select 
		 CRMClientId			= Клиент.GuidКлиент
		 ,firstName				= Клиент.Имя
		 ,lastName				= Клиент.Фамилия
		 ,secondName			= Клиент.Отчество
		 ,dateOfBirth			= Клиент.ДатаРождения
		 ,passportSerialNumber	= Клиент_ПаспортныеДанные.Серия
		 ,passportNumber		= Клиент_ПаспортныеДанные.Номер
		 ,dateOfIssue			= Клиент_ПаспортныеДанные.ДатаВыдачи
		 ,type					= 'client'
		 ,created_at			= getdate()
		
		into #t
		from hub.Клиенты Клиент
		inner join sat.Клиент_ПаспортныеДанные Клиент_ПаспортныеДанные
			on Клиент_ПаспортныеДанные.GuidКлиент =Клиент.GuidКлиент
		where not exists(select top(1) 1 from sat.Клиент_ИНН 
			where Клиент_ИНН.GuidКлиент = Клиент.GuidКлиент
			)
		--Проверяем что у партнера есть актив договор
			and exists(select top(1) 1 from dbo.dm_CMRStatBalance sb 
				where sb.d = cast(getdate() as date)
				and sb.CMRClientGUID =  Клиент.GuidКлиент
				and [остаток всего] > 0
				and [dpd] >= 70 -- берем тех у кого есть просрочка
				)


		BEGIN TRAN
			--удалим тех которых есть инн
			delete t from dm.реестр_просрочников_для_запроса_ИНН t
				where exists(select top(1) 1 from  sat.Клиент_ИНН  s
			where s.GuidКлиент = t.CRMClientId)
			
			--2 обновить паспортные данные в реестре
			merge dm.реестр_просрочников_для_запроса_ИНН AS t
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
	END TRY
	begin catch
		if @@TRANCOUNT>0
			rollback tran;
		;throw
	end catch
END
