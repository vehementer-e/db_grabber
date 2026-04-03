  
 
 CREATE PROCEDURE [collection].[create_founded_contact_skip] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)



  begin try


 
	

drop table if exists #Final_table;


select 				
			cast(t1.CreatedOn as date) 'Дата создания'	
			,dateadd(dd,1, EOMONTH(t1.CreatedOn, -1)) 'Месяц создания'
			--,devdb.dbo.dt_st_month(t1.CreatedOn) 'Месяц создания'
			,t1.ContactFio 'ФИО контакта'	
			,t2.Name 'Вид контакта'	
			,t3.Name 'Тип контактного лица'	
			,t4.Name 'Тип контакта'	
			,t1.ContactName 'Наименование контакта'	
			,t1.ContactData '№ / адрес контакта'	
			,case when t1.IsVerified = 1 then 'Да'	
				  when t1.IsVerified = 0 then 'Нет'
			 else 'Не установлено' end 'Актуален'	
			 ,concat(t5.LastName, ' ', t5.FirstName, ' ', t5.MiddleName) 'ФИО сотрудника создавшего контакт'	
			--,t5.LastName+' '+t5.FirstName+' '+t5.MiddleName 'ФИО сотрудника создавшего контакт'	
			,t1.Commentary 'Комментарий'	

into #Final_table
	from [stg].[_Collection].[SkipContact] t1			
	left join [Stg].[_Collection].[ContactPersonType] t2 on t2.Id = t1.ContactPersonTypeId			
	left join [Stg].[_Collection].[CommunicationCustomerType] t3 on t3.Id = t1.CommunicationCustomerTypeId			
	left join [Stg].[_Collection].SkipContactType t4 on t4.Id = t1.SkipContactTypeId			
	left join [Stg].[_Collection].[Employee] t5 on t5.Id = t1.CreatedBy			
	left join [Stg].[_Collection].[EmployeeCollectingStage] t6 on t6.EmployeeId = t5.Id			
	where cast(t1.CreatedOn as date) >= '2023-01-01'			
			and t6.CollectingStageId = 11 -- скилл скип	
			and t1.ContactData is not null --найденные контакты	
	group by 			
			cast(t1.CreatedOn as date)	
			,dateadd(dd,1, EOMONTH(t1.CreatedOn, -1))
			--,devdb.dbo.dt_st_month(t1.CreatedOn)
			,t1.ContactFio	
			,t2.Name	
			,t3.Name	
			,t4.Name	
			,t1.ContactName	
			,t1.ContactData	
			,case when t1.IsVerified = 1 then 'Да'	
				  when t1.IsVerified = 0 then 'Нет'
			 else 'Не установлено' end	
			,concat(t5.LastName, ' ', t5.FirstName, ' ', t5.MiddleName)
			--,t5.LastName+' '+t5.FirstName+' '+t5.MiddleName	
			,t1.Commentary	






					
begin transaction 

    delete from [collection].[founded_contact_skip];
	insert [collection].[founded_contact_skip] (

	  [Дата создания]
      ,[Месяц создания]
      ,[ФИО контакта]
      ,[Вид контакта]
      ,[Тип контактного лица]
      ,[Тип контакта]
      ,[Наименование контакта]
      ,[№ / адрес контакта]
      ,[Актуален]
      ,[ФИО сотрудника создавшего контакт]
      ,[Комментарий]

)



 select 
     
       [Дата создания]
      ,[Месяц создания]
      ,[ФИО контакта]
      ,[Вид контакта]
      ,[Тип контактного лица]
      ,[Тип контакта]
      ,[Наименование контакта]
      ,[№ / адрес контакта]
      ,[Актуален]
      ,[ФИО сотрудника создавшего контакт]
      ,[Комментарий]


 from #Final_table

  
  commit transaction 

  EXEC [collection].set_debug_info @sp_name
			,'Finish';		
			
	end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END
