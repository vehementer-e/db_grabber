
-- =============================================
-- Author:		<Sabanin A.A.>
-- Create date: <19.03.2020>
-- Description:	<Description,,>
-- exec  [files].[leadRef2_postloader]
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[leadRef2_postloader];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [files].[leadRef2_postloader]
as begin
set nocount on


begin try
  
 begin tran
	delete from [files].[leadRef2_buffer]

	INSERT INTO [files].[leadRef2_buffer]
	( [Тип-Источник]
		  ,[Канал от источника]
		  ,[created])

	select [Тип-Источник]
		  ,[Канал от источника]
		  ,[created] 
	from [files].[leadRef2_buffer_stg] b
commit tran
  select 0
end try
begin catch
	 declare @ErrorNumer  INT= ERROR_NUMBER() 
				,@ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
				,@ErrorSeverity INT = ERROR_SEVERITY()
				,@ErrorState INT = ERROR_STATE()
		 if xact_state() <> 0
		 begin
		 	rollback transaction;
		 end

		;throw
end catch
end
