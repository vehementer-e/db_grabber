


CREATE   proc [dbo].[notify_loan_creation]
as
--return

drop table if exists #t1
select Номер, [Выданная сумма], [Заем выдан], [Канал от источника], Источник, [Вид займа], getdate() created, productType productType into #t1 from v_FA
where ( isPts=1 or [Группа каналов]='Банки'  or источник in ('bankiru-uniapi',  'psb-deepapi') ) and [Заем выдан]>='2025-11-01 13:33' and    [Выданная сумма] is not null 

insert into #t1
select number, 0, created, channel+' '+ status_crm2+ ' '+isnull(region, 'region=null') , source, returnType, getdate() created , productType  from request with(nolock) where 
--select number, 0, created,  channel , source, returnType, getdate() created   from request where 
source like '%' + 'psb-deepapi' + '%' and created>='2025-06-11 13:33' and isdubl=0

drop table if exists #t2

select    a.Номер,  a.[Заем выдан], cast(
      a.Номер+'
'+

FORMAT(  a.[Выданная сумма], '0')+'
'+FORMAT(  a.[Заем выдан], 'dd HH:mm')+'
'+ isnull(  a.[Канал от источника], '')+'
'+     isnull(  a.Источник, '') +'
'+isnull(   a.[Вид займа]      , '')
as nvarchar(max)) 
text,   a.created, d.idcustomer  idcustomer 
, a.productType 
, r.productTypeExternal productTypeExternal
, a.[Выданная сумма]
into #t2  from #t1
a
left join stg._Collection.deals d 	on d.number=a.Номер
left join _request r 	on r.number=a.Номер


--select * from notify_loan
--order by 1 desc
--delete from notify_loan where  номер = '24101702607096'
 
 ;with v  as (select *, row_number() over(partition by номер  order by [Заем выдан] desc ) rn from #t2 ) delete from v where rn>1



delete a from  #t2 a      join notify_loan  b on a.Номер=b.Номер       and a.text=b.text

drop table if exists #hist

select a.Номер Номер, STRING_AGG('
==========
old:'
+format(b.created, 'dd.MM HH:mm')+'
'+b.text , '
' ) within group (order by b.created desc) old_text into #hist from    #t2 a    left  join notify_loan  b on a.Номер=b.Номер       and a.text<>b.text
group by a.Номер



drop table if exists #to_send


select a.Номер, a.[Заем выдан], a.text text , a.created , a.text + isnull('
'+a.productType, '') + isnull('
'+a.productTypeExternal, '')  +isnull( b.old_text, '') text_new
, a.idcustomer 
, a.productType
, a.productTypeExternal
, a.[Выданная сумма]
into #to_send  from     #t2 a
left join #hist b on a.Номер=b.Номер


delete from #to_send where номер is null

declare @num nvarchar(20) 
declare @message nvarchar(max) 
declare @vidan int

;

while exists (select top 1 * from    #to_send )
begin


set @num = ( select top 1 Номер from    #to_send a order by  a.[Заем выдан] )
set @vidan = ( select top 1  case when [Выданная сумма] >0 then 1 else 0 end from    #to_send where Номер=@num)
set @message = ( select top 1 text_new from    #to_send where Номер=@num)

if @vidan=1
exec log_telegram @message        ,'1037811'
--if @message like '%' + 'psb-deepapi' + '%'
--exec log_telegram @message        ,'709239629'
if @message like '%' + 'psb-deepapi' + '%'
exec log_telegram @message        ,'330256271'

--exec log_telegram '5'        ,'1037811'

insert into   notify_loan 
 
--           delete from analytics.dbo.log_telegrams where id='3B1746A6-D9A2-4DDA-B9B5-2BDEF0A7F29D'


select a.Номер, a.[Заем выдан], a.text text , a.created  , a.idcustomer , a.productType  , a.productTypeExternal   from      #to_send  a
where a.Номер=@num
delete a from  #to_send a    
where a.Номер=@num

--alter table notify_loan add productType nvarchar(50)
--alter table notify_loan add productTypeExternal nvarchar(50)


end





 --select * from notify_loan
 --order by created desc


 --select * from v_fa where number='25102123806300'