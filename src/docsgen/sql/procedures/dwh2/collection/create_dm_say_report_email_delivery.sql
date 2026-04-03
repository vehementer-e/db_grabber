
/*
dwh-DWH-898
*/
CREATE  procedure [collection].[create_dm_say_report_email_delivery]
as
begin
SET XACT_ABORT ON;
declare @start_date date = isnull(

dateadd(month,-1, (select max(month_message) from collection.report_say_report_email_delivery))
,'2022-01-01')


  drop table if exists #udal_1;			
  create table #udal_1			
  (CommunicationResultName nvarchar(500)			
  ,Status_Result nvarchar(30)			
  ,Fact_delivery int			
  ,Fact_reading int);			
  insert #udal_1(CommunicationResultName,Status_Result,Fact_delivery,Fact_reading)			
  VALUES ('Письмо доставлено, но сервер получателя поместил его в папку «Спам». Статус окончательный.','Доставлено, не прочитано',1,0),			
('Письмо отклонено сервером как спам.','Доставлено, не прочитано',1,0),			
('Почтовый ящик получателя переполнен. Статус окончательный.','Доставлено, не прочитано',1,0),			
('Просрочено. Статус окончательный.','Доставлено, не прочитано',1,0),			
('Сообщение доставлено. Может измениться на ‘ok_read’, ‘ok_link_visited’, ‘ok_unsubscribed’ или ‘ok_spam_folder’.','Доставлено, не прочитано',1,0),			
('Сообщение доставлено и зарегистрировано его прочтение. Может измениться на ‘ok_link_visited’, ‘ok_unsubscribed’ или ‘ok_spam_folder’.','Доставлено, прочитано',1,1),			
('Сообщение доставлено и прочитано, но пользователь отписался по ссылке в письме. Статус окончательный.','Доставлено, прочитано',1,1),			
('Сообщение доставлено, прочитано и выполнен переход по одной из ссылок. Может измениться на ‘ok_unsubscribed’ или ‘ok_spam_folder’.','Доставлено, прочитано',1,1),			
('Адрес не существует, доставка не удалась. Статус окончательный.','Не доставлено',0,0),			
('Домен не принимает почту или не существует. Статус окончательный.','Не доставлено',0,0),			
('Доставка не удалась по иным причинам. Статус окончательный.','Не доставлено',0,0),			
('Одна или несколько попыток доставки оказались неудачными, но попытки продолжаются. Статус неокончательный.','Не доставлено',0,0),			
('Отправка не выполнялась, т.к. адрес, по которому пытались отправить письмо, ранее отписался. Вы можете пометить этот адрес как отписавшийся и в своей базе данных и больше не отправлять на него. Статус окончательный.','Не доставлено',0,0),			
('Отправка отменена, так как email адрес недоступен (кроме случаев err_unsubscribed и err_not_allowed).','Не доставлено',0,0),			
('Сообщение было отправлено, промежуточный статус до получения ответа о доставке/недоставке.','Не доставлено',0,0),			
('Такого id не существует в целевой системе.','Не доставлено',0,0);			
			
			
drop table if exists #udal_2;			
select t2.Number			
			,t1.Id id_message
			,cast(t1.date as date) date_message
			,datepart(dd,t1.date) day_message
			,datepart(ww,t1.date) weekly_message
			,dateadd(day,- datepart(day, t1.date) + 1, convert(date, t1.date)) month_message
			,t1.ContactPerson
			,t1.PhoneNumber
			,t4.Name ContactPersonName
			,t5.templatename
			,1 message_attemp
			,coalesce(t1.CommunicationResultName,'не определено') CommunicationResultName
			,coalesce(t6.Status_Result,'не определено') Status_Result
			,coalesce(t6.Fact_delivery,0) message_delivery
			,coalesce(t6.Fact_reading,0) message_reading
	into #udal_2		
	FROM --[C2-VSR-SQL04].[collection_night00].[dbo].[Communications] t1		
		 [Stg].[_Collection].[Communications] t1		
	join [Stg].[_Collection].[Deals] t2 on t2.id = t1.IdDeal		
	join [Stg].[_Collection].[communicationType] t3 on t3.Id = t1.CommunicationType		
	join [Stg].[_Collection].[ContactPersonType] t4 on t4.Id = t1.ContactPersonType		
	join [Stg].[_Collection].[CommunicationTemplate] t5 on t5.id = t1.CommunicationTemplateId		
	left join #udal_1 t6 on t6.CommunicationResultName = t1.CommunicationResultName		
	where cast(t1.date as date) >= @start_date	
			and t1.CommunicationType = 6 -- тип сообщения email;

	begin tran
	
	delete from collection.report_say_report_email_delivery
	where month_message>=@start_date

	insert into collection.report_say_report_email_delivery
	select date_message			
			,day_message	
			,weekly_message	
			,month_message	
			,templatename	
			,CommunicationResultName	
			,Status_Result	
			,sum(message_attemp) message_attemp	
			,sum(message_delivery) message_delivery	
			,sum(message_reading) message_reading	

	from #udal_2			
	group by date_message			
			,day_message	
			,weekly_message	
			,month_message	
			,templatename	
			,CommunicationResultName	
			,Status_Result;	
commit tran

end
