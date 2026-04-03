--Dictionary.set_isRussiaDayOff @isReloadAll =1
create   procedure Dictionary.set_isRussiaDayOff
	@isReloadAll bit = 0
as
begin try
	declare @maxdt date  
	
	select @maxdt = dateadd(dd,1, eomonth(getdate(),-1))
	if @isReloadAll = 1
		set @maxdt ='2000-01-01'
		
	drop table if exists #tResult
	select Дата = cast(dateadd(year,-2000, ДанныеПроизводственногоКалендаря.Дата) as date)
		,ВидыДня = ВидыДнейПроизводственногоКалендаря.Имя
		into #tResult
	from stg._1cUMFO.РегистрСведений_ДанныеПроизводственногоКалендаря ДанныеПроизводственногоКалендаря
	inner join stg._1cUMFO.Перечисление_ВидыДнейПроизводственногоКалендаря ВидыДнейПроизводственногоКалендаря
		on ВидыДнейПроизводственногоКалендаря.ССылка = ДанныеПроизводственногоКалендаря.ВидДня
	where dateadd(year,-2000, ДанныеПроизводственногоКалендаря.Дата)>=@maxdt
	
	--alter table [Dictionary].[calendar]
	--	add isRussiaDayOff bit default 0 
	begin tran
		update c
			set isRussiaDayOff = iif(
				t.ВидыДня in ('Воскресенье', 'Суббота', 'Праздник'), 1
			,case 
				when t.ВидыДня in ('Рабочий', 'Предпраздничный') then 0
				when c.weekday_name in ('Суббота', 'Воскресенье') then 1
				
			else 0 end)
		from [Dictionary].[calendar] c
		left join #tResult t on t.Дата = c.DT
		where c.DT>=@maxdt

	commit tran

end try
begin catch 
	if @@TRANCOUNT>0
		rollback tran
end catch
