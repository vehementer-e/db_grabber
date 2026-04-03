
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[SmsUrlClickByDate_updater] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE     procedure [dbo].[SmsUrlClickByDate_updater]
 @url_ending  nvarchar(10)
,@date       nvarchar(50)
,@clicks      nvarchar(10)
AS
begin

  set nocount on

  --select cast('j5cXF' as nvarchar(10)) url_ending,cast('Direct' as nvarchar(50)) label ,cast(2 as int) clicks, getdate() created, getdate() updated into dbo.SMSUrlClicks
  --truncate  table dbo.SMSUrlClicks

  set @date=replace(replace(@date,' ',''),'-','') --2020-06-08 ->20200608
  /*
  create table dbo.SMSUrlClicksByDate
  (url_ending nvarchar(10)
   ,date date
   ,clicks int
   ,created datetime
   ,updated datetime
  )
  */
  if not exists  (select * from  dbo.SMSUrlClicksByDate
  where date=cast(@date as date) and url_ending=@url_ending and clicks=try_cast(@clicks as int)
  ) 
  
  insert into dbo.SMSUrlClicksByDate 
  select @url_ending url_ending
       , cast(@date as date)
       , try_cast(@clicks as int)
       , getdate()   created
       , getdate()   updated

  else 
  update dbo.SMSUrlClicksByDate 
  set clicks=try_cast(@clicks as int)
    , updated=getdate()
where date=cast(@date as date) and url_ending=@url_ending and clicks<>try_cast(@clicks as int)

end
