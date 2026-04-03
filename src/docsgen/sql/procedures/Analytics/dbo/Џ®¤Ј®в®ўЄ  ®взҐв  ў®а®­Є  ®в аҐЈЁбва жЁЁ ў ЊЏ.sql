
CREATE proc [dbo].[Подготовка отчета воронка от регистрации в МП]
as
begin


drop table if exists #t1
SELECT cast( [Дата коммуникации] as date) [День коммуникации] , [Дата коммуникации], [Имя шаблона], [Текст шаблона], [Способ связи]
	  into #t1
  FROM [Analytics].[dbo].v_communication_comc
  where [Тип коммуникации]='SMS'
 /* 
  select [Имя шаблона], min([Текст шаблона]) [Текст шаблона] into #t2 from #t1
  group by [Имя шаблона]
  order by [Имя шаблона]


  select *,
  case 
  when [Имя шаблона] like '%мп%' or 
   [Имя шаблона] like '%прило%' or 
   [Текст шаблона] like '%прило%' or 
   [Текст шаблона] like '%мп%' --or 
  then 1 else 0 end 
  
  from #t2
  order by 3, 1

  Ссылка на МП
  Предложение скачать МП и оформить займ
  Отправка смс в наумен
  Не зарегистрировался в МП
  Заявка после лида
  Smart Inst Выбор предложения
  IVR mobile
  IVR whatsapp

  Онлайн связь в мобильном приложении: https://clck.ru/GuYND и WhatsApp: +79038808845
  */

  drop table if exists #l
  select [Дата лида], IsInstallment, Телефон into #l
  from v_feodor_leads

  create nonclustered index t on #l ([Дата лида], Телефон)


  drop table if exists #t3
  select  cast( [Дата коммуникации] as date) [День коммуникации] , [Дата коммуникации], [Имя шаблона], [Текст шаблона], [Способ связи], isnull(x.IsInstallment, 0) [Тип продукта по смс]
  into #t3
  from #t1 a
  outer apply (select top 1 * from #l b where a.[Способ связи]=b.Телефон and b.[Дата лида] between dateadd(day, -1, [Дата коммуникации]) and [Дата коммуникации] order by b.[Дата лида] desc ) x
  where [Имя шаблона] in
  (
'Ссылка на МП'
,'Предложение скачать МП и оформить займ'
,'Отправка смс в наумен'
,'Не зарегистрировался в МП'
,'Заявка после лида'
,'IVR mobile'
)
--order by [Текст шаблона]


;
with v as (
select *, ROW_NUMBER() over(partition by [День коммуникации], [Способ связи] order by [Дата коммуникации]) rn from #t3
--order by 1
)
delete from v
where rn>1


;
  drop table if exists #reg_


select u.username username, min(r.created_at) [Дата регистрации] , cast(min(r.created_at) as date) [День регистрации] into #reg_ from stg._lk.register_mp r
join stg._lk.users u on u.id=r.user_id
group by  u.username

  drop table if exists #reg


select a.*, isnull(x.IsInstallment, 0) [Тип продукта до регистрации] into #reg from #reg_ a
  outer apply (select top 1 * from #l b where a.username=b.Телефон and b.[Дата лида] between dateadd(day, -1, [Дата регистрации]) and [Дата регистрации] order by b.[Дата лида] desc ) x




select isnull(a.[День коммуникации], b.[День регистрации]) День , isnull(a.[Способ связи], b.username)  Телефон,* into #f from #t3 a
left join #reg b on a.[Способ связи]=b.username and a.[День коммуникации]=b.[День регистрации]

drop table if exists #r_f

--select Номер Номер, телефон, датазаявкиполная into #fa from reports.dbo.dm_factor_analysis
select Номер Номер, телефон, датазаявкиполная
,[Верификация кц] 
,[Предварительное одобрение] 
,[контроль данных] 
,[Одобрено] 
, [Заем выдан] 
, [выданная сумма] 
, 1-isPts isInstallment
, [Место cоздания]
, Место_создания_2
, case when [Группа каналов]='cpa' then [Канал от источника] else [Группа каналов] end Канал
 into #r_f 

from reports.dbo.dm_factor_analysis

drop table if exists #final


select 
 a.День	
,b.Неделя
, format(b.Неделя, 'dd-MM-yyyy')+' - '+format(dateadd(day, 6, b.Неделя), 'dd-MM-yyyy') Неделя_Текстовое_Представление
,b.Месяц
, a.[Тип продукта по смс]
,a.[Телефон]	
,a.[Дата коммуникации]	
,a.[Имя шаблона]	
,a.[Текст шаблона]	
,a.[Способ связи]	
,a.[username]	
,a.[Дата регистрации]	
,x.[Номер]	
,x.[датазаявкиполная]	
,x.[Верификация кц]	
,x.[Предварительное одобрение]	
,x.[контроль данных]	
,x.[Одобрено]	
,x.[Заем выдан]	
,x.[выданная сумма]	
,x.[isInstallment]
,isnull(x.[Место cоздания]	   , 'Заявка не создана')  [Место cоздания]	
,isnull(x.[Место_создания_2]   , 'Заявка не создана')  [Место_создания_2]
,isnull(x.[Канал] 			   , 'Заявка не создана')  [Канал] 			
, GETDATE() as created
, case isnull(isnull(isnull([Тип продукта по смс], [Тип продукта до регистрации]), x.[isInstallment]), 0)
when 0 then 'ПТС'
when 1 then 'Беззалог' end
[Первоначальный тип продукта]
into #final
from #f a
outer apply (select top 1 * from #r_f b where a.Телефон=b.Телефон and  b.датазаявкиполная between [День регистрации] and dateadd(day, 1, [Дата регистрации]) 

order by 
[Заем выдан] desc
,[Одобрено] desc
,[контроль данных] desc
,[Предварительное одобрение] desc
,[Верификация кц] desc
) x
left join v_Calendar b on a.День=b.Дата

--drop table if exists dbo.[Отчет воронка от регистрации в МП]
--select * into dbo.[Отчет воронка от регистрации в МП]  from #final

begin tran
delete from dbo.[Отчет воронка от регистрации в МП]

insert into dbo.[Отчет воронка от регистрации в МП]
select * from #final
commit tran

	
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '442246D0-3A07-4959-8D8B-4BAB6C99BD78'

end