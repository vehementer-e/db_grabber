-- =============================================
-- Author:		Kurdin S
-- Create date: 2019-05-07
-- Description:	Отчет о причинах отказа и аннулирования заявок на статусе "Контроль данных" по данным МФО 

-- =============================================
CREATE PROCEDURE [dbo].[Report_CancelledRequestOn_VDK_VD] 
	-- Add the parameters for the stored procedure here
	
@PageNo int

AS
BEGIN

	SET NOCOUNT ON;


    -- Insert statements for procedure here

if @PageNo=1

with t0 as
(
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

      ,kz.[Пользователь_Наим] as [ИсполнительНаим_След]
      ,ls0.[ПричинаНаим] as [ПричинаНаим]
	  ,ms.[Имя] as [МестоСозданияЗаявки]
	  ,ls0.[ПричинаОтказаНаим] as [ПричинаОтказа]
	  ,ls0.[rank]
from (select 
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
		FROM [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c] l0 with (nolock)
		left join [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c] l1 with (nolock)
		on l0.[Заявка]=l1.[Заявка] and l0.[Период]<l1.[Период]
	  ) ls0
-- здесь присоединим комментарии последнего исполнителя
  left join (select a.[Период]	,a.[Заявка] ,a.[Пользователь_Ссылка] ,a.[Пользователь_Наим] ,a.[Должность_Наим] ,a.[Комментарий] --,a.[rank_Rec]
			 from (
				   select a0.[Период] 
					     ,a0.[Заявка]
						 ,a0.[Пользователь_Ссылка]
						 ,a1.[Пользователь_Наим]
						 ,a1.[Должность_Наим] 
						 ,a0.[Комментарий]
						 ,rank() over(partition by a0.[Заявка] order by a0.[Период] desc) as [rank0]
				    from [Stg].[dbo].[aux_ListCommentRequestMFO_1c] a0 with (nolock)
				   -- from [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[РегистрСведений_ГП_КомментарииЗаявок]
				    left join [Stg].[dbo].[aux_UserRoleMFO_1c] a1 with (nolock)
					on a0.[Пользователь_Ссылка]=a1.[Пользователь_Ссылка]
					where a1.[Должность_Наим] like N'Верификация документов%'
				  ) a
			where a.[rank0]=1 --and a.[Должность_Наим] like N'Контроль данных'
			)  kz
	on ls0.[Заявка]=kz.[Заявка] --and ls0.[Исполнитель]=kz.[Пользователь_Ссылка]

-- здесь присоединим фамилию, имя, отчества заемщика
  left join [Stg].[_1cMFO].[Документ_ГП_Заявка] z  with (nolock)
  on ls0.[Заявка]=z.[Ссылка]

-- здесь присоединим место создания
  left join [Stg].[_1cMFO].[Перечисление_ГП_МестаСозданияЗаявки] ms with (nolock) --y
  on z.[МестоСозданияЗаявки]=ms.[Ссылка]

where (ls0.[Период_След] >= dateadd(year,2000,dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0))) -- dateadd(year,2000,dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,dateadd(month,-2,Getdate())),0)))-- 
							and ls0.[Период_След] <= dateadd(year,2000,Getdate())) --dateadd(year,2000,dateadd(day,datediff(day,0,Getdate()),0)))
	  and ls0.[rank]=1 
),

t1 as
(
select * from t0

where --		and ls0.[rank]=1 
--		and 
		t0.[Статус_Нач]=0x9C4DDF3CA0AFEDC84D92D351E60A78D0	-- Верификация документов
			or t0.[Статус_Нач]=0xA52424BDFE434D014FF2A32D8D6ACA6F	-- Верификация документов клиента
		and t0.[Статус_След] in (0x8D0D358E813B836A4F34C2C81F9ADC1D -- Заявка аннулирована
								 ,0x9071FA946610B33A4CAC1731B3AE8E69  --Отказано
								 ,0xB5F1ECA7587F32054B48050A36ABB4D2)  --Отказ документов клиента
		and not t0.[Заявка] in (select l0.[Заявка]
								 from [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c]l0 with (nolock) 
								 left join [Stg].[dbo].[aux_UserRoleMFO_1c] us with (nolock)
									on  l0.[Исполнитель]=us.[Пользователь_Ссылка]
								 where l0.[Статус]=0x8D0D358E813B836A4F34C2C81F9ADC1D -- заявка аннулирована 
										and l0.[Причина] =0xBE43244BC8057B3F4C5A9ACD752A2BD2 -- причина регламент
										and l0.[Исполнитель]=0x00000000000000000000000000000000 -- опер.день
									)
--		and ls0.[ПричинаНаим] not like N'Регламент%' 
		and not t0.[ИсполнительНаим_След] is null
--		and ls0.[Заявка] not in (select l0.[Заявка]
--								 from [dwh_new_Kurdin_S_V].[dbo].[auxtab_ListRequestOnStatusesMFO_1c] l0
--								 left join [dwh_new_Kurdin_S_V].[dbo].[auxtab_UserRoleMFO_1c] us
--									on  l0.[Исполнитель]=us.[Пользователь_Ссылка]
--								 where l0.[Статус]=0x8D0D358E813B836A4F34C2C81F9ADC1D -- заявка аннулирована 
--										and l0.[Причина] =0xBE43244BC8057B3F4C5A9ACD752A2BD2 -- причина регламент
--										and l0.[Исполнитель]=0x00000000000000000000000000000000) -- опер.день

) 
,t2 as
(
select * from t0
where t0.[Статус_Нач]=0x90E899F58D819C6E4EA8DC3B18DFC6B6 --Отказано --t0.[rank]=1 and 
		and t0.[Статус_След] in (0x9071FA946610B33A4CAC1731B3AE8E69  --Отказано
								 ,0xB5F1ECA7587F32054B48050A36ABB4D2)  --Отказ документов клиента
--		and t0.[Заявка]=0xB81500155D4D107811E9844EC9CD9CF4
		and not t0.[Заявка] in  (select distinct [Заявка] from t1)
)
,res as
(
select * from t1 
union all
select * from t2 
)

select [Время] ,[ЗаявкаДата_Исх] ,[ЗаявкаНомер_Исх] ,[ФИОКлиента] ,[СтатусНаим_След] 
		,[ПериодС] ,[ПериодПо] 
		,case when [Комментарий] is null then [ПричинаОтказа] else [Комментарий] end [Комментарий]
		,[ИсполнительНаим_След] ,[ПричинаНаим] ,[МестоСозданияЗаявки]
from res
where not ([Комментарий] is null and [ПричинаОтказа] is null)
	  and [СтатусНаим_След]=N'Отказано' or [СтатусНаим_След]=N'Отказ документов клиента' 
	-- res.[ПричинаНаим] is null --t2.[Заявка]=0xB81500155D4D107811E9844EC9CD9CF4 
 order by [ПериодПо] desc, [ЗаявкаНомер_Исх] desc, [ПериодС] asc


if @PageNo=2

with t0 as
(
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

      ,kz.[Пользователь_Наим] as [ИсполнительНаим_След]
      ,ls0.[ПричинаНаим] as [ПричинаНаим]
	  ,ms.[Имя] as [МестоСозданияЗаявки]
	  ,ls0.[ПричинаОтказаНаим] as [ПричинаОтказа]
	  ,ls0.[rank]
from (select 
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
		FROM [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c] l0  with (nolock)
		left join [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c] l1  with (nolock)
		on l0.[Заявка]=l1.[Заявка] and l0.[Период]<l1.[Период]
	  ) ls0
-- здесь присоединим комментарии последнего исполнителя
  left join (select a.[Период]	,a.[Заявка] ,a.[Пользователь_Ссылка] ,a.[Пользователь_Наим] ,a.[Должность_Наим] ,a.[Комментарий] --,a.[rank_Rec]
			 from (
				   select a0.[Период] 
					     ,a0.[Заявка]
						 ,a0.[Пользователь_Ссылка]
						 ,a1.[Пользователь_Наим]
						 ,a1.[Должность_Наим] 
						 ,a0.[Комментарий]
						 ,rank() over(partition by a0.[Заявка] order by a0.[Период] desc) as [rank0]
				    from [Stg].[dbo].[aux_ListCommentRequestMFO_1c] a0  with (nolock)
				   -- from [C1-VSR-SQL05].[MFO_NIGHT00].[dbo].[РегистрСведений_ГП_КомментарииЗаявок]
				    left join [Stg].[dbo].[aux_UserRoleMFO_1c] a1  with (nolock)
					on a0.[Пользователь_Ссылка]=a1.[Пользователь_Ссылка]
					where a1.[Должность_Наим] like N'Верификация документов%'
				  ) a
			where a.[rank0]=1 --and a.[Должность_Наим] like N'Контроль данных'
			)  kz
	on ls0.[Заявка]=kz.[Заявка] --and ls0.[Исполнитель]=kz.[Пользователь_Ссылка]

-- здесь присоединим фамилию, имя, отчества заемщика
  left join [Stg].[_1cMFO].[Документ_ГП_Заявка] z with (nolock)
  on ls0.[Заявка]=z.[Ссылка]

-- здесь присоединим место создания
  left join [Stg].[_1cMFO].[Перечисление_ГП_МестаСозданияЗаявки] ms  with (nolock)--y
  on z.[МестоСозданияЗаявки]=ms.[Ссылка]

where (ls0.[Период_След]  >= dateadd(year,2000,dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0))) -- dateadd(year,2000,dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,dateadd(month,-2,Getdate())),0)))-- 
							and ls0.[Период_След] <= dateadd(year,2000,Getdate())) --dateadd(year,2000,dateadd(day,datediff(day,0,Getdate()),0)))
	  and ls0.[rank]=1 
),

t1 as
(
select * from t0

where --		and ls0.[rank]=1 
--		and 
		t0.[Статус_Нач]=0x9C4DDF3CA0AFEDC84D92D351E60A78D0	-- Верификация документов
			or t0.[Статус_Нач]=0xA52424BDFE434D014FF2A32D8D6ACA6F	-- Верификация документов клиента
		and t0.[Статус_След] in (0x8D0D358E813B836A4F34C2C81F9ADC1D -- Заявка аннулирована
								 ,0x9071FA946610B33A4CAC1731B3AE8E69  --Отказано
								 ,0xB5F1ECA7587F32054B48050A36ABB4D2)  --Отказ документов клиента
		and not t0.[Заявка] in (select l0.[Заявка]
								 from [Stg].[dbo].[aux_ListRequestOnStatusesMFO_1c] l0  with (nolock)
								 left join [Stg].[dbo].[aux_UserRoleMFO_1c] us  with (nolock)
									on  l0.[Исполнитель]=us.[Пользователь_Ссылка]
								 where l0.[Статус]=0x8D0D358E813B836A4F34C2C81F9ADC1D -- заявка аннулирована 
										and l0.[Причина] =0xBE43244BC8057B3F4C5A9ACD752A2BD2 -- причина регламент
										and l0.[Исполнитель]=0x00000000000000000000000000000000 -- опер.день
									)
--		and ls0.[ПричинаНаим] not like N'Регламент%' 
		and not t0.[ИсполнительНаим_След] is null
--		and ls0.[Заявка] not in (select l0.[Заявка]
--								 from [dwh_new_Kurdin_S_V].[dbo].[auxtab_ListRequestOnStatusesMFO_1c] l0
--								 left join [dwh_new_Kurdin_S_V].[dbo].[auxtab_UserRoleMFO_1c] us
--									on  l0.[Исполнитель]=us.[Пользователь_Ссылка]
--								 where l0.[Статус]=0x8D0D358E813B836A4F34C2C81F9ADC1D -- заявка аннулирована 
--										and l0.[Причина] =0xBE43244BC8057B3F4C5A9ACD752A2BD2 -- причина регламент
--										and l0.[Исполнитель]=0x00000000000000000000000000000000) -- опер.день

) 
,t2 as
(
select * from t0
where t0.[Статус_Нач]=0x90E899F58D819C6E4EA8DC3B18DFC6B6 --Отказано --t0.[rank]=1 and 
		and t0.[Статус_След] in (0x9071FA946610B33A4CAC1731B3AE8E69  --Отказано
								 ,0xB5F1ECA7587F32054B48050A36ABB4D2)  --Отказ документов клиента
--		and t0.[Заявка]=0xB81500155D4D107811E9844EC9CD9CF4
		and not t0.[Заявка] in  (select distinct [Заявка] from t1)
)
,res as
(
select * from t1 
union all
select * from t2 
)

select [Время] ,[ЗаявкаДата_Исх] ,[ЗаявкаНомер_Исх] ,[ФИОКлиента] ,[СтатусНаим_След] 
		,[ПериодС] ,[ПериодПо] 
		,case when [Комментарий] is null then [ПричинаОтказа] else [Комментарий] end [Комментарий]
		,[ИсполнительНаим_След] ,[ПричинаНаим] ,[МестоСозданияЗаявки]
from res
where not ([Комментарий] is null and [ПричинаОтказа] is null)
	  and [СтатусНаим_След]=N'Заявка аннулирована' --or [СтатусНаим_След]=N'Отказ документов клиента' 
	-- res.[ПричинаНаим] is null --t2.[Заявка]=0xB81500155D4D107811E9844EC9CD9CF4 
 order by [ПериодПо] desc, [ЗаявкаНомер_Исх] desc, [ПериодС] asc

END
