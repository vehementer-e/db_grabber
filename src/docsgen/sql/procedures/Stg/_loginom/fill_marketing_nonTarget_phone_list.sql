

/*DWH-991*/
-- Usage: запуск процедуры с параметрами
-- EXEC [_loginom].[fill_marketing_nonTarget_phone_list] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   procedure [_loginom].[fill_marketing_nonTarget_phone_list]
as
begin

 declare @date_start date=dateadd(mm, -3, getdate())
  ,@batchSize int = 10000
	declare @t_LOGINOM_CHANNEL table (channel nvarchar(255))
	
  insert into @t_LOGINOM_CHANNEL
  select * from (values('CPA нецелевой') 
  ) t(channel)

drop table if exists #t_last_result
create table #t_last_result
(
	PhoneNumber nvarchar(255),
	uf_rc_reject_cm nvarchar(255)
)
insert into #t_last_result
    select distinct
		PhoneNumber,
		uf_rc_reject_cm
	--into #t_last_result 
	FROM 
		--dbo.lcrm_LOGINOM_CHANNEL lcrm with(nolock)
		_LCRM.lcrm_leads_full_channel_request lcrm with(nolock)
	inner  join @t_LOGINOM_CHANNEL c on charindex(c.channel, lcrm.UF_LOGINOM_CHANNEL) > 0 
     where  UF_REGISTERED_AT>=@date_start
		and uf_rc_reject_cm is not null
	



  
  drop table if exists #t_result

  create table #t_result
  (
	client_number nvarchar(255)
  )
  insert into #t_result
  select distinct
  client_number = PhoneNumber
  from  #t_last_result r where 1=1
  and r.uf_rc_reject_cm in  (
		 'CC.Не подходит под требования  - Год выпуска авто не соответствует требованиям  - КЦ'
		,'CC.Не подходит под требования  - Не собственник - КЦ'
		,'CC.Не подходит под требования  - Нет авто - КЦ'
		,'CC.Не подходит под требования  - Категория авто - КЦ'
		,'CC.Не подходит под требования  - Не подходит по возрастным ограничениям  - КЦ'
		,'CC.Не подходит под требования  - Не РФ /авто не зарегистрированно на территории РФ  - КЦ'
		,'CC.Не подходит под требования  - Вне зоны присутствия бизнеса  - КЦ'
		  )
  
set xact_abort on 
  begin tran
	--удалить записи которы были добавлены более 3хмесяц назад
	
	delete top(@batchSize) from _loginom.marketing_nonTarget_phone_list
	where InsertedDate <=@date_start
	while @@ROWCOUNT>0
	begin
		delete top(@batchSize) from _loginom.marketing_nonTarget_phone_list
		where InsertedDate <=@date_start
	end


	--Добавили новые данные
	insert into _loginom.marketing_nonTarget_phone_list (client_number, InsertedDate)
	select s.client_number, getdate() as InsertedDate
	from #t_result s
	where not exists(select top(1) 1 from _loginom.marketing_nonTarget_phone_list t where t.client_number  = s.client_number)
commit tran

  end
