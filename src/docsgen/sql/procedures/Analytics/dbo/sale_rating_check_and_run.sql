CREATE proc [dbo].[sale_rating_check_and_run]
as

if not exists (select * from jobh where succeeded>=cast(getdate() as date) and job_name   = 'Analytics._sale_rating at 9:00' and step_id=0 )
return


if   exists (select * from jobs_running where  job   = 'Analytics._sale_rating at 9:00'   )
return


declare @result nvarchar(max)
exec python 'result = gs2df("1XVVHn4vJvjriKN0Xy6kgQ4SAY6F75q7mGKVcmqPYTFI", "Месяц для рейтинга!A1:A2").iloc[0, 0]', 1, @result output


if @result  is   null 
begin
exec log_email 'Rating month ERROR googlesheet error' 
return

end

if (select   rating_date_from from config ) is null
 begin

update config set 
rating_date_from = try_cast(replace(@result, '"', '') as date),
rating_date_to =   dateadd(month, 1,  try_cast(replace(@result, '"', '') as date)) 


exec log_email 'Rating rating_date_from config ERROR'
return

end


if @result = (select '"'+format( rating_date_from , 'yyyy-MM-01')+'"' from config) 
return



if @result  is not null 
begin
update config set 
rating_date_from = try_cast(replace(@result, '"', '') as date),
rating_date_to =   dateadd(month, 1,  try_cast(replace(@result, '"', '') as date)) 


exec msdb.dbo.sp_start_job  @job_name= 'Analytics._sale_rating at 9:00', @step_name = 'rating_detail'

end

