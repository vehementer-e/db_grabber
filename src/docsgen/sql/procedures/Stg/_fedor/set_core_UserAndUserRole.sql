-- Usage: запуск процедуры с параметрами
-- EXEC [_fedor].[set_core_UserAndUserRole];
-- Параметры соответствуют объявлению процедуры ниже.
 CREATE procedure [_fedor].[set_core_UserAndUserRole]
 as
 begin
	begin try
		begin tran
			
				
			merge _fedor.core_UserAndUserRole t
				using _fedor.core_UserAndUserRole_upd s
				on s.IdUser  =t.IdUser
					and s.IdUserRole =  t.IdUserRole
					and t.IsDeleted = 0
			--делаем только вставку 
			when not matched then insert
			(
				[Id]
				, [CreatedOn]
				, [IdUser]
				, [IdUserRole]
				, [IsDeleted]
				, [DWHInsertedDate]
				, [ProcessGUID]
			)
			values
			(
				  s.[Id]
				, s.[CreatedOn]
				, s.[IdUser]
				, s.[IdUserRole]
				, s.[IsDeleted]
				, s.[DWHInsertedDate]
				, s.[ProcessGUID]
			) 
			--update не делаем
			/*
			when matched and t.Id != s.Id
				then update
					set  t.Id = s.Id
						,t.CreatedOn = s.CreatedOn
			*/
			--если роль была удалена у пользователя, то проставляем ее как удаленную.
			WHEN NOT MATCHED BY SOURCE and t.isDeleted = 0
				then update
					set isDeleted = 1
						,deleted_at = getdate()
			OUTPUT $action, deleted.*, INSERTED.*

			;
		commit tran
	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
 end
