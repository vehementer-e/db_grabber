
create proc [dev_опроссервистриггеры_creation]
as
begin

drop table if exists #t1
select a.Телефон

, a.ФИО
, a.Номер
, a.[Вид займа], a.isPts, a.[Выданная сумма], a.[Заем выдан], a.[Заем погашен], b.entrypoint, b.type, b.status, b.decline, b.created ДатаТриггера
, max(case when b.status = 'ACCEPTED' then 'ACCEPTED, ' else '' end )	 over (partition by a.Номер) 
+ max(case when b.decline = 'Красная категория' then 'Красная категория, ' else ''  end )	 over (partition by a.Номер) 
+ max(case when b.decline <> 'Красная категория' then 'decline' else ''  end )	 over (partition by a.Номер)   Типы ,


ROW_NUMBER() over(partition by  a.Телефон order by a.[Заем погашен] desc,  b.created  desc )	rn
, datediff(day, b.created, a.[Заем погашен]) dif
	   into #t1
from v_fa a
join v_lead2  b on a.Телефон=b.phone  
and  b.entrypoint ='TRIGGER' 
and b.created between 
dateadd(day, -7 , a.[Заем погашен] ) and
a.[Заем погашен]
order by 5 desc

 drop table dbo.[dev_опроссервистриггеры]
select a.*,   b.created, b.is_ok bs_ok, c.category into dbo.[dev_опроссервистриггеры] from #t1
a 
left join v_blacklist b on a.Телефон=b.phone
left join v_client_category c on c.phone=a.Телефон	and c.rn_product=1	and c.ispts=1
where a.rn=1 and [Заем погашен]>=getdate()-5
order by 3



select  isnull(category, 'Красный') category, ДатаТриггера ,   [Заем погашен] , ФИО, Телефон, Номер  from dbo.[dev_опроссервистриггеры] 
where  isnull(bs_ok, 1)<>0		and ispts=1
order by [Заем погашен] desc
end