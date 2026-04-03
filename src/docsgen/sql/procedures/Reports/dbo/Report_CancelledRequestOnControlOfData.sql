-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	Отчет о причинах отказа и аннулирования заявок на статусе "Контроль данных" по данным МФО 

-- =============================================
CREATE PROCEDURE [dbo].[Report_CancelledRequestOnControlOfData] 
	-- Add the parameters for the stored procedure here
	
@PageNo int

AS
BEGIN

	SET NOCOUNT ON;


    -- Insert statements for procedure here


drop table if exists #ListRequestOnStatusesMFO_1c 

SELECT 
	   zl.[Период] as [Период]
      ,zl.[Регистратор_ТипСсылки]
      ,zl.[Регистратор_Ссылка]
      ,zl.[Заявка]
	  ,z.[Номер] AS [ЗаявкаНомер]
      ,zl.[Исполнитель]
	  ,u.[Наименование] as [ИсполнительНаим]
      ,zl.[Статус]
	  ,zs.[Наименование] as [СтатусНаим]
      ,zl.[Причина]
	  ,zrs.[Имя] as [ПричинаНаим]
      ,zl.[ПричинаОтказа] as [ПричинаОтказа]
	  ,cof.[Наименование] as [ПричинаОтказаНаим]
	  ,cof.[Кодификатор] as [ПричинаОтказаКод]
	  ,cof.[Вид]

into #ListRequestOnStatusesMFO_1c

from [Stg].[_1cMFO].[РегистрСведений_ГП_СписокЗаявок] zl  with (nolock) -- zayvka list
	LEFT JOIN [Stg].[_1cMFO].[Документ_ГП_Заявка] z with (nolock) -- zayvka
	ON zl.[Заявка]=z.[Ссылка]
	LEFT JOIN [Stg].[_1cMFO].[Справочник_Пользователи] u with (nolock) --user
	ON zl.[Исполнитель]=u.[Ссылка]
	LEFT JOIN [Stg].[_1cMFO].[Справочник_ГП_СтатусыЗаявок] zs with (nolock)
	ON zl.[Статус]=zs.[Ссылка]
	LEFT JOIN [Stg].[_1cMFO].[Перечисление_ГП_ПричиныСтатусаЗаявки] zrs with (nolock)
	ON zl.[Причина]=zrs.[Ссылка]
	LEFT JOIN [Stg].[_1cMFO].[Справочник_ПричиныОтказа] cof with (nolock) -- cause of failure
	ON zl.[ПричинаОтказа]=cof.[Ссылка]
where zl.[Период]>= dateadd(year,2000, dateadd(MONTH,datediff(MONTH,0,dateadd(month,-2,Getdate())),0))  -- zs.[Наименование]=N'Контроль данных'
order by z.[Номер] asc

--select * from #ListRequestOnStatusesMFO_1c


drop table if exists #ListCommentRequestMFO_1c
select 
		zc.[Период] 
		,zc.[Заявка]
		,z.[Номер] as [НомерЗаявки] 
		,zc.[ГУИДЗаписи] 
		,zc.[ДатаЗаявки] 
		,zc.[Клиент] 
		,zc.[Пользователь_Тип] 
		,zc.[Пользователь_Строка] 
		,zc.[Пользователь_Ссылка] 
		,cast(zc.[Комментарий] as nvarchar(255)) as [Комментарий] 
		,zll.[ПричинаОтказа] 
		,zc.[ОбщийДоступ] 
		,zc.[Должность]
into #ListCommentRequestMFO_1c
from [Stg].[_1cMFO].[РегистрСведений_ГП_КомментарииЗаявок] zc with (nolock)
  left join (select [Заявка] 
					,r.[Наименование] as [ПричинаОтказа]
			 from [Stg].[_1cMFO].[РегистрСведений_ГП_СписокЗаявок_ИтогиСрезПоследних] zll0 with (nolock)
			 left join [Stg].[_1cMFO].[Справочник_ПричиныОтказа] r with (nolock) on zll0.[ПричинаОтказа]=r.[Ссылка]
			) zll
  on zc.[Заявка]=zll.[Заявка]
	left join [Stg].[_1cMFO].[Документ_ГП_Заявка] z with (nolock) -- zayvka
	on zc.[Заявка]=z.[Ссылка]
where [ДатаЗаявки]>=dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0)
 order by [ДатаЗаявки] desc

 --  select * from #ListCommentRequestMFO_1c where [НомерЗаявки]='20021310000227' order by 1 desc

drop table if exists #UserRoleMFO_1c
select us.[Пользователь_Ссылка] ,us.[Пользователь_Наим] ,us.[Должность_Ссылка] ,us.[Должность_Наим]
		,case 
			when sum(isnull(s.[Администратор],0))>0 then N'Админ'
			when sum(isnull(s.[СотрудникСБ],0))>0 then N'СБ'
			when sum(isnull(s.[ПерсональныйМенеджер],0))>0 then N'ПМ'
			when sum(isnull(s.[Администратор],0))>0 and sum(isnull(s.[СотрудникСБ],0))=0 and sum(isnull(s.[ПерсональныйМенеджер],0))=0 then N'Админ'
			when us.[Должность_Ссылка] is null then N'Админ'
			else N'Ошибка'
		end as [РольПользователя]
					--		,s.[НазваниеРоли]
					--		,us.[ДатаРождения] ,us.[ДатаПриемаНаработу] ,us.[ДатаУвольнения]
into #UserRoleMFO_1c

from (
	  select u.[Ссылка] as [Пользователь_Ссылка] ,u.[Наименование] as [Пользователь_Наим] ,u.[Должность] as [Должность_Ссылка] ,dl.[Наименование] as [Должность_Наим]
	  from [Stg].[_1cMFO].[Справочник_Пользователи] u  with (nolock)
	  left join [Stg].[_1cMFO].[Справочник_ДолжностиОрганизаций] dl with (nolock)
		on u.[Должность]=dl.[Ссылка]
	  ) us
left join (select d.[Ссылка] as [Должность_Ссылка] ,d.[Наименование] as [Наименование]
					,case 
						when dn.[НазваниеРоли]=N'СлужбаБезопасностиМФО' then 1 
						when dn.[НазваниеРоли]=N'НачальникСБМФО' then 1
						else 0 end as [СотрудникСБ]
						,case 
							when dn.[НазваниеРоли]=N'КонтактЦентрМФО' then 1 
							when dn.[НазваниеРоли]=N'КоллЦентрМФО' then 1
							when dn.[НазваниеРоли]=N'АвтоКредитМФО' then 1
						else 0 end as [ПерсональныйМенеджер]
						,case 
							when dn.[НазваниеРоли]=N'АдминистраторМФО' then 1 
						else 0 end as [Администратор]
						,dn.[НазваниеРоли] ,dn.[ПредставлениеРоли] ,d.[Наименование] as [Должность_Наим]
			from [Stg].[_1cMFO].[Справочник_ДолжностиОрганизаций] d with (nolock)
			left join [Stg].[_1cMFO].[Справочник_ДолжностиОрганизаций_НастройкиДоступа] dn with (nolock)
				on d.[Ссылка]=dn.[Ссылка] 
			where d.[ПометкаУдаления]=0x00) s
on us.[Должность_Ссылка]=s.[Должность_Ссылка]
group by us.[Пользователь_Ссылка] ,us.[Пользователь_Наим],us.[Должность_Ссылка],us.[Должность_Наим]	

--select * from #UserRoleMFO_1c

drop table if exists #Comment_last_user
select a0.[Период] 
					     ,a0.[Заявка]
						 ,a0.[НомерЗаявки]
						 ,a0.[Пользователь_Ссылка]
						 ,a1.[Пользователь_Наим]
						 ,a1.[Должность_Наим] 
						 ,a0.[Комментарий]
						 ,rank() over(partition by a0.[Заявка] order by a0.[Период] desc) as [rank0]
into #Comment_last_user
from #ListCommentRequestMFO_1c a0 with (nolock)
	left join #UserRoleMFO_1c a1 with (nolock) on a0.[Пользователь_Ссылка]=a1.[Пользователь_Ссылка]
where a1.[Должность_Наим] like N'Контроль данных%' or a1.[Должность_Наим] like N'% КД%'

--  select * from #Comment_last_user where [НомерЗаявки]='20021310000227' order by 1 desc



drop table if exists #Requst_last_status
select 
			  l0.[Заявка]
			  ,l0.[ЗаявкаНомер]
			  ,l0.[Статус] as [Статус_Нач]
			  ,l0.[СтатусНаим] as [СтатусНаим_Нач]
			  ,l0.[Период] as [Период_Нач]
			  ,l1.[Период] as [Период_След]
			  ,l1.[Статус] as [Статус_След]
			  ,l1.[СтатусНаим] as [СтатусНаим_След]
			  ,l1.[Исполнитель]
			  ,l1.[ПричинаНаим]
			  ,l1.[ПричинаОтказаНаим]
			  ,rank() over(partition by l0.[Заявка], l0.[Период] order by l1.[Период] asc) as [rank]
into #Requst_last_status
from #ListRequestOnStatusesMFO_1c l0 with (nolock)
	left join #ListRequestOnStatusesMFO_1c l1 with (nolock)
	on l0.[Заявка]=l1.[Заявка] and l0.[Период]<l1.[Период]

-- select * from #Requst_last_status where [ЗаявкаНомер] in ('20031610000171', '20031610000110' ,'20031800015708') order by 2 desc ,5 desc



drop table if exists  #t0
select
 	  cast(isnull(ls0.[Период_След],ls0.[Период_Нач]) as time) as [Время]
	  ,ls0.[Заявка] --as [ЗаявкаСсылка_Исх]
      ,dateadd(year,-2000,ls0.[Период_Нач]) as [ЗаявкаДата_Исх]
      ,ls0.[ЗаявкаНомер] as [ЗаявкаНомер_Исх]--[ЗаявкаНомер]
	  ,(z.[Фамилия]+' '+z.[Имя]+' '+z.[Отчество]) as [ФИОКлиента]
      ,ls0.[Статус_Нач]
	  ,ls0.[СтатусНаим_Нач]
      ,ls0.[Статус_След]
      ,ls0.[СтатусНаим_След]
	  ,dateadd(year,-2000,ls0.[Период_Нач]) as [ПериодС]
      ,dateadd(year,-2000,ls0.[Период_След]) as [ПериодПо]
	  ,kz.[Комментарий]

      ,u.[Наименование]/*kz.[Пользователь_Наим]*/ as [ИсполнительНаим_След]
      ,ls0.[ПричинаНаим] as [ПричинаНаим]
	  ,ms.[Имя] as [МестоСозданияЗаявки]
	  ,ls0.[ПричинаОтказаНаим] as [ПричинаОтказа]
	  ,ls0.[rank]

into #t0

from (select * from #Requst_last_status) ls0

-- здесь присоединим комментарии последнего исполнителя
  left join (select a.[Период]	
					,a.[Заявка] 
					,a.[Пользователь_Ссылка] 
					,a.[Пользователь_Наим] 
					,a.[Должность_Наим] 
					,a.[Комментарий] --,a.[rank_Rec]
			 from (select * from #Comment_last_user) a
			 where a.[rank0]=1 
			)  kz
	on ls0.[Заявка]=kz.[Заявка] 

-- здесь присоединим фамилию, имя, отчества пользователя
  left join [Stg].[_1cMFO].[Справочник_Пользователи] u
  on ls0.[Исполнитель]=u.[Ссылка]

-- здесь присоединим фамилию, имя, отчества заемщика
  left join [Stg].[_1cMFO].[Документ_ГП_Заявка] z  with (nolock)
  on ls0.[Заявка]=z.[Ссылка]

-- здесь присоединим место создания
  left join [Stg].[_1cMFO].[Перечисление_ГП_МестаСозданияЗаявки] ms with (nolock) --y
  on z.[МестоСозданияЗаявки]=ms.[Ссылка]

where (ls0.[Период_След] >= dateadd(year,2000,dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0)))
							and ls0.[Период_След] <= dateadd(year,2000,Getdate()))
	  and ls0.[rank]=1 

-- select * from #t0 where [ЗаявкаНомер_Исх] in ('20031610000171', '20031610000110' ,'20031800015708') order by 10 desc

drop table if exists  #t1
select * 
into #t1
from #t0 t0

where --		and ls0.[rank]=1 
--		and 
		t0.[Статус_Нач]=0x90E899F58D819C6E4EA8DC3B18DFC6B6
		and t0.[Статус_След] in (0x8D0D358E813B836A4F34C2C81F9ADC1D -- Заявка аннулирована
								 ,0x9071FA946610B33A4CAC1731B3AE8E69  --Отказано
								 ,0xB5F1ECA7587F32054B48050A36ABB4D2)  --Отказ документов клиента
		and not t0.[Заявка] in (select l0.[Заявка] --,l0.[Исполнитель]
								 from #ListRequestOnStatusesMFO_1c l0 with (nolock) 
								 left join #UserRoleMFO_1c us with (nolock)
									on  l0.[Исполнитель]=us.[Пользователь_Ссылка]
								 where l0.[Статус]=0x8D0D358E813B836A4F34C2C81F9ADC1D -- заявка аннулирована 
										and l0.[Причина] =0xBE43244BC8057B3F4C5A9ACD752A2BD2 -- причина регламент
										and l0.[Исполнитель]=0x00000000000000000000000000000000 -- опер.день
									)

		and not t0.[ИсполнительНаим_След] is null

order by 4 desc ,3 desc


--select * from #t1 where [ЗаявкаНомер_Исх] in ('20031610000171', '20031610000110' ,'20031800015708') order by 1

drop table if exists  #t2
select * 
into #t2
from #t0 t0
where t0.[Статус_Нач]=0x90E899F58D819C6E4EA8DC3B18DFC6B6 --Отказано --t0.[rank]=1 and 
		and t0.[Статус_След] in (0x9071FA946610B33A4CAC1731B3AE8E69  --Отказано
								 ,0xB5F1ECA7587F32054B48050A36ABB4D2)  --Отказ документов клиента

		and not t0.[Заявка] in  (select distinct [Заявка] from #t1)

order by 4 desc ,3 desc

-- select * from #t2 where [ЗаявкаНомер_Исх] in ('20031610000171', '20031610000110' ,'20031800015708')

drop table if exists #res 
select * 
into #res
from #t1 
union all
select * from #t2 

-- select * from #res where [ЗаявкаНомер_Исх] in ('20031700015540', '20031710000225' ,'20032010000041')


if @PageNo=1

select [Время] ,[ЗаявкаДата_Исх] ,[ЗаявкаНомер_Исх] ,[ФИОКлиента] ,[СтатусНаим_След] 
		,[ПериодС] ,[ПериодПо] 
		,case when [Комментарий] is null then [ПричинаОтказа] else [Комментарий] end [Комментарий]
		,[ИсполнительНаим_След] ,[ПричинаНаим] ,[МестоСозданияЗаявки]
from #res
where [СтатусНаим_След]=N'Отказано'
	  /*and not ([Комментарий] is null and [ПричинаОтказа] is null)*/
	  ----or [СтатусНаим_След]=N'Отказ документов клиента' 
	  --and not [ИсполнительНаим_След] is null or 
	  and [ИсполнительНаим_След]<>''

 order by [ПериодПо] desc, [ЗаявкаНомер_Исх] desc, [ПериодС] asc

 -- select * from #res where [ЗаявкаНомер_Исх] in ('20031700015540', '20031710000225' ,'20032010000041')

if @PageNo=2

select [Время] ,[ЗаявкаДата_Исх] ,[ЗаявкаНомер_Исх] ,[ФИОКлиента] ,[СтатусНаим_След] 
		,[ПериодС] ,[ПериодПо] 
		,case when [Комментарий] is null then [ПричинаОтказа] else [Комментарий] end [Комментарий]
		,[ИсполнительНаим_След] ,[ПричинаНаим] ,[МестоСозданияЗаявки]
from #res
where /*not ([Комментарий] is null and [ПричинаОтказа] is null)
	  and*/ [СтатусНаим_След]=N'Заявка аннулирована' --or [СтатусНаим_След]=N'Отказ документов клиента' 
	  --and not [ИсполнительНаим_След] is null or 
	  and [ИсполнительНаим_След]<>''

 order by [ПериодПо] desc, [ЗаявкаНомер_Исх] desc, [ПериодС] asc
 
END
