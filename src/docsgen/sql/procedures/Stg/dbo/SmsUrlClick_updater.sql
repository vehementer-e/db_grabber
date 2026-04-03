--select * from _collection.SmsWithShortUrl u left join dbo.SMSUrlClicks c on u.url_ending=c.url_ending order by 1 desc
--  exec SmsUrlClick_updater 'jdnGa','Direct',4
CREATE   procedure [dbo].[SmsUrlClick_updater]
 @url_ending  nvarchar(10)
,@label       nvarchar(50)
,@clicks      nvarchar(10)
AS
begin
/*
select 

 @url_ending  
,@label       
,@clicks      
*/
  set nocount on
  --select cast('j5cXF' as nvarchar(10)) url_ending,cast('Direct' as nvarchar(50)) label ,cast(2 as int) clicks, getdate() created, getdate() updated into dbo.SMSUrlClicks
  --truncate  table dbo.SMSUrlClicks
  declare @i int

  if not exists  (select * from  dbo.SMSUrlClicks 
  where url_ending=@url_ending and clicks=@clicks
  ) 
  begin
  insert into dbo.SMSUrlClicks select @url_ending,@label,@clicks ,getdate(),getdate()
  return
  end
  
  select @i=count(*) from  dbo.SMSUrlClicks 
  where url_ending=@url_ending and clicks<>@clicks

  if @i<>0
   begin
    
      update  dbo.SMSUrlClicks 
      set updated=getdate(), clicks=@clicks,label=@label
      where url_ending=@url_ending and clicks<>@clicks
      select 'updated'=@@ROWCOUNT
    end
  
end
