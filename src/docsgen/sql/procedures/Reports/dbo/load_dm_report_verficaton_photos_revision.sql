 CREATE procedure dbo.load_dm_report_verficaton_photos_revision
	
as
begin
 --declare @start_date_update date = '20200713'
 declare @start_date_update date = cast(getdate()-30 as date) 
 
 select 
       t.[Направление]
      ,t.[ВерхнийУровеньКомментария]
      ,t.[НижнийУровеньКомментария]
      ,t.[ЧеловекопонятноеНазваниеДляНижнегоУровня], 
  dateadd(year, -2000, c.Период) ДатаКомментария,
  c.[Комментарий],
  c.Заявка,
  c.[Пользователь_Ссылка],
  getdate() as created
  
   into #t
  from stg.files.verification_types_of_comments_buffer t
  left join  stg.[_1cMFO].[РегистрСведений_ГП_КомментарииЗаявок]  c on c.Комментарий like '%'+t.[ВерхнийУровеньКомментария]+'%'
                                                                  and  c.Комментарий like '%'+t.[НижнийУровеньКомментария]+'%' 

																  and dateadd(year, -2000, c.Период)>=@start_date_update



begin tran
	delete from dbo.dm_report_verficaton_photos_revision where ДатаКомментария>=@start_date_update
	insert into dbo.dm_report_verficaton_photos_revision
	select * from #t
commit tran
end
