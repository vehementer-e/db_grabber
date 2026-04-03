
CREATE   procedure [dbo].[Fill_KD_V_Employees]
as
begin
	merge dbo.KDEmployees t
	using (
	select DisplayName                     
	,      getdate()                        as CreateAt
	,      iif(IsEnable =0, UpdateAt, null) as Fired
	from [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers]
	where Department like '%Отдел документарных%'

	union
		--Добавили по запросу от Кадырова Р.А
		select * from (values
		('Столица Никита Алексеевич', getdate(), null	)
		,('Кадыров Руслан Ахатович', getdate(), null) --17.05.2022
		) t(DisplayName, CreateAt, Fired)
	--	order by DisplayName
	) s
	on s.DisplayName = t.Employee
	when not matched then insert(Employee, Created, Fired)
	values(DisplayName, CreateAt, Fired)
	when matched and s.Fired is not null
	and t.Fired is null
	then update
	set Fired =    s.Fired
	,   UpdateAt = getdate()
;

merge dbo.VEmployees t
	using (
	select DisplayName                     
	,      getdate()                        as CreateAt
	,      iif(IsEnable =0, UpdateAt, null) as Fired
	from [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers]
	where Department like '%Отдел по сделкам физических лиц%'
	union
		--Добавили по запросу от Кадырова Р.А
	select * from (values
		('Фролова Кристина Павловна', getdate(), null	)
		,('Кадыров Руслан Ахатович', getdate(), null) --17.05.2022
		) t(DisplayName, CreateAt, Fired)

	) s
	on s.DisplayName = t.Employee
	when not matched then insert(Employee, Created, Fired)
	values(DisplayName, CreateAt, Fired)
	when matched and s.Fired is not null
	and t.Fired is null
	then update
	set Fired =    s.Fired
	,   UpdateAt = getdate()
;


end
