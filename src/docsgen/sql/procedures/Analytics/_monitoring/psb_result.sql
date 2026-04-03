CREATE   proc [_monitoring].[psb_result]	  @mode nvarchar(40) = 'psb-ref'			, @mail int = 1
as
begin
  --  exec  [_monitoring].[psb_result] 'psb-ref'	 , 0
  --  exec  [_monitoring].[psb_result] 'vtb-ref'	 , 0
  --  exec exec_python 'PSB_TO_GD()', 1
  --declare @mode nvarchar(max)	   =  'psb-ref'		  declare @mail int   =  0
  --
  if @mail   = 1 		  return

declare @start datetime = 	 case when @mode='psb-ref' then cast('2024-05-15 17:00:00' as datetime) else  cast('2024-05-27 10:00:00' as datetime)    end

drop table if exists #t1

select a.id, a.client_id, a.created, @mode  source  into #t1  
from v_visit a	    
where (source=@mode or stat_source=@mode	)	and 	 created>=@start

			 and id <> '8dcb2877-1663-4957-b2b7-579fa6b539a6'



--drop table if exists dbo.[visit_psb_vtb]
--select * into dbo.[visit_psb_vtb] from #t1
begin tran
delete from dbo.visit_psb_vtb where  source = @mode
insert into dbo.visit_psb_vtb
select * from #t1
commit tran

--declare @start datetime = 	 cast('2024-05-15 17:00:00' as datetime) 
drop table if exists #t2
select id, source, created, phone  into #t2   from v_lead2	  with(nolock)
 where source =@mode	 and created>=@start
 and phone not in (
 '9796041313'
,'9624789194'
,'9871211579'
,'9793441111'
, '9996021345'
)


drop table if exists #t2_
select id, created, phone, source  into #t2_  from  #t2



--drop table if exists dbo.[lead_psb_vtb]
--select * into dbo.[lead_psb_vtb] from #t2_
begin tran
delete from dbo.[lead_psb_vtb] where  source = @mode
insert into dbo.[lead_psb_vtb]
select * from #t2_
commit tran

	 
drop table if exists #t_
select Код Код, max(сумма  ) сумма_ into #t_	from reports.dbo.dm_Sales 
	group by Код
	--order by 


drop table if exists #t3
select 
 x.created lead_creared
,a.*
, b.сумма_ 

into #t3   from v_request	   a
left join #t_ b on a.НомерЗаявки=b.Код
outer apply (select top 1 * from 	  #t2 b where b.phone  =a.Телефон and 	   b.created<= a.ДатаЗаявки )  x
left join v_FA b1 on a.НомерЗаявки=b1.Номер
left join #t2 x1 on x1.ID=a.marketing_lead_id

 where  ДатаЗаявки>=@start  and a.Телефон  in  (select phone from #t2)
 and НомерЗаявки  not in (
'24051422058810', 
'24051502060222', 
'24052702094142', 
'24051522061716')
and (b1.[Канал от источника] =  case when @mode='psb-ref' then 'ПСБ' else 'ВТБ'   end or x1.id is not null  or ( x.id is not null and a.ДатаЗаявки<='2024-09-05 11:40:00') )
 

  --declare @mode nvarchar(max)	   =  'psb-ref'		  declare @mail int   =  0
 
drop table if exists #t3_
select НомерЗаявки, ДатаЗаявки ДатаЗаявки,  Телефон ,   @mode Источник, ispts  into #t3_  from  #t3

--drop table if exists dbo.[request_psb_vtb]
--select * into dbo.[request_psb_vtb] from #t3_
begin tran
delete from dbo.[request_psb_vtb] where  Источник = @mode
insert into dbo.[request_psb_vtb]
select * from #t3_
commit tran
--alter table	[request_psb_vtb] add ispts  tinyint 


--select a.ispts,  *, [Канал от источника] from #t3 a
--left join v_FA b on a.НомерЗаявки=b.Номер
-- where a.Отказано Is not null and a.isPts=0
--order by 1, 4,3


--select a.ispts,  *, [Канал от источника] from #t3 a
--left join v_FA b on a.НомерЗаявки=b.Номер
----where a.[Заем выдан] Is not null
--order by 1, 4,3
							   
								  
--								  select  a.*, b.[Канал от источника] from #t3		a
--								  left join v_fa b on a.НомерЗаявки=b.Номер 
--order by 6, 4


								  --select isPts  ,  СтатусЗаявки, count(distinct Телефон) from   #t3
								  --group by isPts, СтатусЗаявки
			   

drop table if exists #mail


 select  'Визитов всего'			[Метрика], [Значение] = (select count(distinct id) from   #t1) 	 into #mail
union all select 'Визитов уникальных' 	t, val = (select count(distinct client_id) from   #t1)
union all select 'Лидов всего (уник. клиенты)'			t, val = (select count(distinct phone) from   #t2)
union all select ' '		t, val = null


union all select 'Заявок всего'			t, val = (select count(distinct НомерЗаявки) from   #t3) 
union all select 'Заявок одобрено'		t, val = (select count(distinct НомерЗаявки) from    #t3 where Одобрено Is not null) 
union all select 'Заявок отказ'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where Отказано Is not null) 
union all select 'Заявок в работе'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where Отказано Is  null and Одобрено is null and Аннулировано is null and Забраковано is null) 
union all select 'Заявок закрыто'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where  (Аннулировано is not null or Забраковано Is not null) and Одобрено Is   null and Отказано Is   null ) 
union all select' '		t, val = null

union all select 'Заявок птс'			t, val   =  (select  count(distinct НомерЗаявки) from  #t3 where ispts=1 ) 
union all select 'Заявок птс одобрено'	t, val = (select  count(distinct НомерЗаявки) from   #t3 where ispts=1 and Одобрено Is not null) 
union all select 'Заявок птс отказ'		t, val = (select  count(distinct НомерЗаявки) from   #t3 where ispts=1 and Отказано Is not null) 
union all select 'Заявок птс в работе'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where ispts=1 and Отказано Is  null and Одобрено is null and Аннулировано is null and Забраковано is null) 
union all select 'Заявок птс закрыто'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where ispts=1 and (Аннулировано is not null or Забраковано Is not null) and Одобрено Is   null and Отказано Is   null) 
		   
union all select' '		t, val = null
union all select 'Заявок Инст'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where isinstallment=1  ) 
union all select 'Заявок Инст одобрено'	t, val = (select  count(distinct НомерЗаявки) from   #t3 where isinstallment=1 and Одобрено Is not null) 
union all select 'Заявок Инст отказ'		t, val = (select  count(distinct НомерЗаявки) from   #t3 where isinstallment=1 and Отказано Is not null) 
union all select 'Заявок Инст в работе'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where isinstallment=1 and Отказано Is  null and Одобрено is null and Аннулировано is null and Забраковано is null) 
union all select 'Заявок Инст закрыто'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where isinstallment=1 and  (Аннулировано is not null or Забраковано Is not null) and Одобрено Is   null and Отказано Is   null) 
union all select ' '		t, val = null


union all select 'Заявок ПДЛ'			t, val   = (select  count(distinct НомерЗаявки) from   #t3 where isPdl=1 ) 
union all select 'Заявок ПДЛ одобрено'	t, val = (select  count(distinct НомерЗаявки) from   #t3 where isPdl=1 and Одобрено Is not null) 
union all select 'Заявок ПДЛ отказ'		t, val = (select  count(distinct НомерЗаявки) from   #t3 where isPdl=1 and Отказано Is not null) 
union all select 'Заявок ПДЛ в работе'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where isPdl=1 and Отказано Is  null and Одобрено is null and Аннулировано is null and Забраковано is null) 
union all select 'Заявок ПДЛ закрыто'			t, val = (select  count(distinct НомерЗаявки) from   #t3 where isPdl=1 and (Аннулировано is not null or Забраковано Is not null) and Одобрено Is   null and Отказано Is   null ) 
union all select ' '			t, val = null


union all select 'Выдач всего'						t, val = (select  count(distinct НомерЗаявки) from   #t3 where 1=1 and [Заем выдан] Is not null) 
union all select 'Выдач ПТС'						t, val   = (select  count(distinct НомерЗаявки) from   #t3 where ispts=1 and [Заем выдан] Is not null) 
union all select 'Выдач Инст'						t, val = (select  count(distinct НомерЗаявки) from   #t3 where isinstallment=1 and [Заем выдан] Is not null) 
union all select 'Выдач ПДЛ'						t, val   = (select  count(distinct НомерЗаявки) from   #t3 where isPdl=1 and [Заем выдан] Is not null) 
 		
union all select ' '			t, val = null


union all select 'Сумма всего'						t, val = (select     isnull(sum(сумма_), 0) from   #t3 where 1=1 and [Заем выдан] Is not null) 
union all select 'Сумма ПТС'						t, val   = (select   isnull(sum(сумма_), 0) from   #t3 where ispts=1 and [Заем выдан] Is not null) 
union all select 'Сумма Инст'						t, val = (select     isnull(sum(сумма_), 0) from   #t3 where isinstallment=1 and [Заем выдан] Is not null) 
union all select 'Сумма ПДЛ'						t, val   = (select   isnull(sum(сумма_), 0) from   #t3 where isPdl=1 and [Заем выдан] Is not null) 
 			 
					 
--  select * from #mail

--delete  from log_telegrams	 where recepients='-420003757'  and text is not null
-- select * from log_telegrams
-- order by dt desc

		  DECLARE @text NVARCHAR(MAX)

SET @text = '
'+case when @mode='psb-ref' then 'ПСБ' else 'ВТБ'   end+'
'

-- Populate the text dynamically based on your temporary table #mail
SELECT @text = @text +
  case when [Значение]>=0 then  [Метрика] +   ' - ' + '<b>' + CAST(
 
  
  format( [Значение] , '#,0', 'en-US')  AS NVARCHAR(MAX)) + '</b>' + CHAR(10)   else 	CHAR(10) end 
FROM #mail
SELECT @text = @text-- + case when @mode='psb-ref' then '/psb' else '/vtb'   end

-- Output the generated text
SELECT @text AS [Generated_Text];

--drop table if exists _tg.projects_stat
--select cast(null as nvarchar(max)) text, 'psb-ref' type into _tg.projects_stat 
begin tran
delete from _tg.projects_stat where type=  @mode
insert into _tg.projects_stat
select isnull(@text , 'error') text, @mode type  

commit tran


--exec log_telegram	@text

  if 0=1
 
 begin

 declare @subject  nvarchar(max)   = 	   'Промежуточные результаты пилота с '  + case when @mode='psb-ref' then 'ПСБ' else 'ВТБ'   end	
 declare @html  nvarchar(max)
 exec spQueryToHtmlTable 'select * from #mail' , default,  @html output	   
 select @html

exec msdb.dbo.sp_send_dbmail   
    @profile_name = null,  
   -- @recipients = 'p.ilin@techmoney.ru',  
    @recipients = 'p.ilin@techmoney.ru; A.Taov@carmoney.ru; v.martemyanova@carmoney.ru ',  
    @body = @html,  
    @body_format = 'html',  
    @subject = @subject
end							  --, count(distinct phone), count(distinct case when [Верификация КЦ] is not null then НомерЗаявки end) from #t3
							  
							--  select * from v_lead
							--  where source_name='psb-ref' and created_at_time>='20240515'
							--  order by created_at_time




--select Телефон 	from #t3
--where НомерЗаявки    in (
--'24051422058810', 
--'24051502060222', 
--'24051522061716')


--drop table if exists #t4


--select --top 100 
--  a.id	visit_id
--, a.created	visit_created
--, a.source
--, a.client_id		  
--, a.client_yandex_id
--, b.phone
--, b.created lead_created
--, b.entrypoint 
--, b.status
--, b.id  
--, c.ДатаЗаявки
--, c.НомерЗаявки
--, c.isPts
--, c.[Верификация КЦ]
--, c.СтатусЗаявки	 

--  into #t4

--from #t1 a
--left join v_lead b on a.id=b.visit_id
--left join v_request c on c.Телефон=b.phone	  and c.ДатаЗаявки>=a.created	 and   НомерЗаявки not in (
--'24051422058810', 
--'24051502060222', 
--'24051522061716')
		   
--select * from #t4

							  end

							  

							  
