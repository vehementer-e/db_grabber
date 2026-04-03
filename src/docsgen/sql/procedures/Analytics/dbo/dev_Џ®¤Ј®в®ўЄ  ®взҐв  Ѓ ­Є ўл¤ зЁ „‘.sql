

create   proc dbo.[Подготовка отчета Банк выдачи ДС]
as


begin

select * from  openquery(lkprod, 'select * from information_schema.columns where table_name like ''%card%''')
select * from  openquery(lkprod, 'select * from information_schema.columns where table_name like ''%confirm%''')
select * from  openquery(lkprod, 'select * from information_schema.columns where column_name like ''%card%''')
select * from  openquery(lkprod, 'select * from information_schema.columns where column_name like ''%confirm%''')


delete from ##Банк
delete from ##Банк_название

drop table if exists ##Банк
select Банк, sum([Выданная сумма]) [Выданная сумма]
into ##Банк
from
(
select left(card_number, 6)  Банк, card_holder, card_token, num_1c, created_at, b.[Способ выдачи], b.[Выданная сумма] from stg._lk.requests a
join reports.dbo.dm_factor_analysis_001 b on a.num_1c=b.Номер and b.[Заем выдан] between '20220101' and '20220630' and isnull(b.[Способ выдачи] , '')<>'Через Contact'

)
x
group by Банк
order by Банк

create table ##Банк_название
(
bin nvarchar(max),
bank_name nvarchar(max)
)


select distinct bank_name from ##Банк_название
select * into [Банк выдачи ДС справочник]  from ##Банк_название
select * from ##Банк

end