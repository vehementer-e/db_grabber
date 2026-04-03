--DWH-1007
CREATE PROC [_loginom].[fill_marketing_prioritization_nonTarget_phone_list]
as
begin

declare @date_start date=dateadd(mm, -6, getdate())
  ,@batchSize int = 10000
	declare @t_LOGINOM_CHANNEL table (channel nvarchar(255))
	
  insert into @t_LOGINOM_CHANNEL
  select * from (values('CPA нецелевой') 
  ) t(channel)

drop table if exists #t_lcrm
--выбираем лиды которые поступили с @date_start (за последние n месяцев) - по каналу @t_LOGINOM_CHANNEL
create table #t_lcrm
(
	PhoneNumber nvarchar(255)
)
insert into #t_lcrm

	 select PhoneNumber
	
	FROM 
	--dbo.lcrm_LOGINOM_CHANNEL lcrm with(nolock)
		_LCRM.lcrm_leads_full_channel_request lcrm with(nolock)
		inner  join @t_LOGINOM_CHANNEL c on charindex(c.channel, UF_LOGINOM_CHANNEL) > 0 
     where  UF_REGISTERED_AT>=@date_start--[Группа каналов]='CPA'
	 group by PhoneNumber
/*
    select UF_PHONE
	--max(UF_UPDATED_AT) UF_UPDATED_AT 
	--into #t_last_result 
	FROM [_LCRM].[lcrm_tbl_short_w_channel] 
	inner  join @t_LOGINOM_CHANNEL c on charindex(c.channel, [Канал от источника]) > 0 
     where  UF_UPDATED_AT>=@date_start--[Группа каналов]='CPA'
  
  group by UF_PHONE
  */
  --выбираем звонки с @date_start (за последние n месяцев)
 if OBJECT_ID('tempdb..#t_Naumen_Communication_result') is not null
	drop table #t_Naumen_Communication_result
create table 	#t_Naumen_Communication_result(
	client_number nvarchar(255)
	--last_attempt_date date
)
insert into #t_Naumen_Communication_result  
	 select 
	client_number= case 
		when substring(client_number, 1, 1) = '8'  then substring(client_number, 2, len(client_number))
		else client_number end
	-- last_attempt_date = attempt_date
	
	from 
	(
  select  
		 --[attempt_date] = max(cast(isnull(attempt_end, attempt_start) as date))
		 --[attempt_date] = max(cast(namumen.attempt_end as date))
		namumen.[client_number]
    
	  --from [NaumenDbReport].[dbo].[detail_outbound_sessions] namumen with(nolock)
	  --FROM NaumenDbReport.dbo.detail_outbound_sessions AS namumen WITH(INDEX=ix_attempt_start_3, NOLOCK) --DWH-1877
	  FROM NaumenDbReport.dbo.detail_outbound_sessions AS namumen
		WITH(INDEX=[columnStore_ix], NOLOCK)
	  WHERE namumen.attempt_start >= @date_start
		--AND namumen.attempt_start >= '2022-04-29' -- нужно для использования индекса ix_attempt_start_3
	  group by namumen.[client_number]
	) s

drop table if exists #t_result
create table #t_result (client_number nvarchar(255))
	insert into #t_result

	select 
		client_number = PhoneNumber  
	
	from #t_lcrm
	EXCEPT--реализация через  EXCEPT получилась быстрее чем различные варианты JOIN
	select 
		client_number
	from #t_Naumen_Communication_result
	 

begin tran
	delete top(@batchSize) from _loginom.marketing_prioritization_nonTarget_phone_list
	where InsertedDate <=@date_start
	while @@ROWCOUNT>0
	begin
		delete top(@batchSize) from _loginom.marketing_prioritization_nonTarget_phone_list
		where InsertedDate <=@date_start
	end


	--Добавили новые данные
	insert into _loginom.marketing_prioritization_nonTarget_phone_list (client_number, InsertedDate)
	select s.client_number, getdate() as InsertedDate
	from #t_result s
	where not exists(select top(1) 1 from _loginom.marketing_prioritization_nonTarget_phone_list t where t.client_number  = s.client_number)


commit tran

		
	
end
