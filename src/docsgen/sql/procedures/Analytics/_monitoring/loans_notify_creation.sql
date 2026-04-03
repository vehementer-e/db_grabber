

CREATE proc [_monitoring].[loans_notify_creation] 
as
begin

drop table if exists #t1
select Номер, [Выданная сумма], [Заем выдан], [Канал от источника], Источник, [Вид займа], getdate() created into #t1 from v_FA
where ( isPts=1 or [Группа каналов]='Банки'  or источник='bankiru-uniapi') and [Заем выдан]>='20240708' and    [Выданная сумма] is not null 



drop table if exists #t2

select    Номер,[Заем выдан], cast(
    Номер+'
'+

FORMAT([Выданная сумма], '0')+'
'+FORMAT([Заем выдан], 'dd HH:mm')+'
'+ isnull([Канал от источника], '')+'
'+     isnull(Источник, '') +'
'+isnull( [Вид займа]      , '')
as nvarchar(max)) 
text, created, d.idcustomer  idcustomer  into #t2  from #t1
a
join stg._Collection.deals d 	on d.number=a.Номер

--select * from notify_loan
--order by 1 desc
--delete from notify_loan where  номер = '24101702607096'
 


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


select a.Номер, a.[Заем выдан], a.text text , a.created , a.text +isnull( b.old_text, '') text_new, a.idcustomer into #to_send  from     #t2 a
left join #hist b on a.Номер=b.Номер

declare @num nvarchar(20) 
declare @message nvarchar(max) 
;

while exists (select top 1 * from    #to_send )
begin


set @num = ( select top 1 Номер from    #to_send a order by  a.[Заем выдан] )
set @message = ( select top 1 text_new from    #to_send where Номер=@num)
exec log_telegram @message        ,'1037811'
--exec log_telegram '5'        ,'1037811'

insert into   notify_loan 
 
--           delete from analytics.dbo.log_telegrams where id='3B1746A6-D9A2-4DDA-B9B5-2BDEF0A7F29D'


select a.Номер, a.[Заем выдан], a.text text , a.created  , a.idcustomer    from      #to_send  a
where a.Номер=@num
delete a from  #to_send a    
where a.Номер=@num




end





end