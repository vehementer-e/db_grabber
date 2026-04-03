
--exec [etl].[base_etl_mt_requests_loans_mfo]

CREATE PROCEDURE [etl].[base_etl_mt_requests_loans_mfo]
	-- Add the parameters for the stored procedure here

AS
BEGIN 

	SET NOCOUNT ON;

		--24.03.2020
	SET DATEFIRST 1;

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime,
		@GetDate2000 datetime
set @DateStart=dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0)
--dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
--dateadd(month,datediff(month,0,GetDate()),-720);
--dateadd(day,datediff(day,0,GetDate()-2),0);
set	@DateStart2=dateadd(year,2000,@DateStart);
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-10,Getdate()))),0);
set @DateStartCurr=dateadd(day,-14,dateadd(day,datediff(day,0,Getdate()),0)); --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0); --dateadd(day,-15,dateadd(day,datediff(day,0,Getdate()),0)); --
set @DateStartCurr2000=dateadd(day,-14,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0)); --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,dateadd(year,2000,Getdate()))),0); --dateadd(day,-15,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0)); --
set @GetDate2000=dateadd(year,2000,getdate());

--select dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,dateadd(year,2000,Getdate()))),0)


--if OBJECT_ID('[dwh_new_Kurdin_S_V].[dbo].[mt_ReqLoan_1cMFO]') is not null
--truncate table [dwh_new_Kurdin_S_V].[dbo].[mt_ReqLoan_1cMFO];

--if OBJECT_ID('[dwh_new_Kurdin_S_V].[dbo].[mt_ReqLoan_1cMFO]') is not null
--drop table [dwh_new_Kurdin_S_V].[dbo].[mt_ReqLoan_1cMFO];

--create table [dwh_new_Kurdin_S_V].[dbo].[mt_ReqLoan_1cMFO]
--(
--[ЗаявкаПериодУчета] datetime2 null
--,[ЗаявкаДатаОперации] datetime null 
--,[ЗаявкаНомер] nvarchar(255) null	
--,[ЗаявкаНомерМФО] nvarchar(255) null
--,[ЗаявкаСсылка] binary(16) null

--,[Фамилия] nvarchar(255) null
--,[Имя] nvarchar(255) null
--,[Отчество] nvarchar(255) null
--,[ДатаРождения] date null 

--,[ПервичнаяСумма] decimal(15,2)  null
--,[СуммаЗаявки] decimal(15,2) null
--,[СуммаДопПродуктовЗаявка] decimal(15,2) null
--,[СуммаБезДопУслугЗаявка] decimal(15,2) null
--,[Колво] decimal(15,2) null
--,[КолвоДопПродуктовЗаявка] decimal(15,2) null

--,[ЗаявкаСрок] int null
--,[ПроцентнаяСтавка] decimal(15,2) null
--,[КредитныйПродукт] nvarchar(255) null

--,[Докредитование] nvarchar(255) null
--,[Повторность] nvarchar(255) null
--,[ДатаПогашПервДог] datetime null 
--,[ПовторностьNew] nvarchar(255) null 

--,[ЗаявкаТочкаКод] nvarchar(255) null	
--,[ЗаявкаТочка] nvarchar(255) null
--,[ЗаявкаВыезднойМенеджер] nvarchar(255) null
--,[ЗаявкаРегион] nvarchar(255) null
--,[ЗаявкаРегион2] nvarchar(255) null
--,[ЗаявкаРОРегион] nvarchar(255) null
--,[ЗаявкаДивизион] nvarchar(255) null
--,[ЗаявкаАгент] nvarchar(255) null
--,[ЗаявкаАгентМФО] nvarchar(255)  null

--,[ДатаЗаявки] datetime  null
----,[ЗаявкаДеньНедели] int  null

----,[ЗаявкаНеделя] int  null
----,[ЗаявкаДеньМесяца] int  null
----,[ЗаявкаМесяц] int  null
----,[ЗаявкаГод] int  null

----,[НаименованиеЛиста] nvarchar(255) null
--,[ЗаявкаНаименованиеПараметра] nvarchar(255) null


--,[ЗаявкаКогорта] nvarchar(255) null

--,[ВидДоговора] nvarchar(255) null
--,[ЗаявкаТекСтатусМФО] binary(16) null
--,[ЗаявкаСтатусНаим] nvarchar(255) null
--,[ЗаявкаЛидогенератор] binary(16) null


--,[ЗаявкаКаналМФО_ТочкаВх] nvarchar(255) null
--,[ТочкаВходаЗаявки] nvarchar(255) null
--,[МестоСоздЗаявки] nvarchar(255) null
--,[СпособВыдачиЗайма] nvarchar(255) null
--,[ЕстьОсновнаяЗаявка] nvarchar(255) null
--,[ПризнакОформлНовой] nvarchar(50) null
--,[ЗаявкаПризнакАннулирования] nvarchar(50) null
--,[ВремяПриходаНаВерификацию] datetime  null
--,[ЗаявкаТекСтатус] nvarchar(255) null 
--,[ПричинаИзмСтатусаЗаявки] nvarchar(255) null


--------------------------
--------для договора
--,[ПериодУчетаДоговор] datetime2 null
--,[ДоговорСсылка] binary(16) null

--,[ДоговорНомер] nvarchar(255) null	
--,[ДоговорНомерМФО] nvarchar(255) null

--,[ДатаВыдачиДоговора]  datetime null 
--,[ДатаОкончанияДоговора] datetime  null

--,[ДоговорПервичнаяСумма] decimal(15,2)  null
--,[СуммаДоговора] decimal(15,2) null
--,[ДоговорСуммаДопПродуктов] decimal(15,2) null
--,[ДоговорСуммаБезДопУслуг] decimal(15,2) null
--,[ДоговорКолво] decimal(15,2) null
--,[ДоговорКолвоДопПродуктов] decimal(15,2) null

--,[ДоговорСрок] int null
--,[ДоговорПроцентнаяСтавка] decimal(15,2) null
--,[ДоговорКредитныйПродукт] nvarchar(255) null

--,[ДоговорТочкаКод] nvarchar(255) null	
--,[ДоговорТочка] nvarchar(255) null
--,[ДоговорВыезднойМенеджер] nvarchar(255) null
--,[ДоговорРегион] nvarchar(255) null
--,[ДоговорРегион2] nvarchar(255) null
--,[ДоговорРОРегион] nvarchar(255) null
--,[ДоговорДивизион] nvarchar(255) null

--,[ДоговорАгентМФО] nvarchar(255) null

--,[ДоговорНомерГрафика] int null

--,[ДоговорДатаНачала] datetime null
--,[ДатаДоговора] datetime  null


--,[ДоговорВидДоговора] nvarchar(255) null
--,[ДоговорТекСтатусМФО] nvarchar(255) null
--,[ДоговорСтатусНаим_UMFO] nvarchar(255) null
--);

with 
	rl as -- RequestLoan_1cMFO (ЗаявкиЗаймы)
(
SELECT distinct
dateadd(MONTH,datediff(MONTH,0,dateadd(year,-2000,cast(z.[Дата] as datetime2))),0) as [ЗаявкаПериодУчета]
--,z.[Ссылка] as [СсылкаЗаявка]
,dateadd(year,-2000,cast(z.[Дата] as datetime)) as [ЗаявкаДатаОперации]
,z.[Номер] as [ЗаявкаНомер]
,z.[Номер] as [ЗаявкаНомерМФО]
,z.[Ссылка] as [ЗаявкаСсылка]

,z.[Фамилия]
,z.[Имя]
,z.[Отчество]
,cast(dateadd(year,-2000,cast(z.[ДатаРождения]as datetime2)) as date) as [ДатаРождения]

--,case when zs.[Наименование]=N'Заем выдан' and not d.[Ссылка] is null then zl.[Период] end as [ДатаВыдачиДоговора]
--,case when zs.[Наименование]=N'Заем выдан' and not d.[Ссылка] is null then dateadd(month,d.[Срок], zl.[Период]) end as [ДатаОкончанияДоговора]

,case when prez.[Сумма]=0 then z.[Сумма] else prez.[Сумма] end as [ПервичнаяСумма]
,z.[Сумма] as [СуммаЗаявки]
,0 as [СуммаДопПродуктовЗаявка]
,0 as [СуммаБезДопУслугЗаявка]
,1 as [Колво]
,0 as [КолвоДопПродуктовЗаявка]

,z.[Срок] as [ЗаявкаСрок]
,case when z.[ПроцентнаяСтавка]<>0 then z.[ПроцентнаяСтавка] else kp.[ТекущаяСсуда] end as [ПроцентнаяСтавка]
,kp.[Наименование] as [КредитныйПродукт]

,case 
	when dkr.[Имя]=N'ДокредитованиеПодТекущийЗалог'  then N'Докредитование под текущий залог'
	when dkr.[Имя]=N'ПараллельныйЗаем'  then N'Параллельный заем'
	else dkr.[Имя]
end as [Докредитование] --dkr.[Имя] as [Докредитование]
,z.[ПовторныйКлиент] as [Повторность]
,ssd0.[ПериодПогашения] as [ДатаПогашПервДог]
,case when ssd0.[ПериодПогашения] is null then N'Нет' else N'Да' end as [ПовторностьNew] 


,o.[Код] as [ЗаявкаТочкаКод]
,o.[Наименование] as [ЗаявкаТочка]
,case when o.[ВыезднойМенеджер]=0x01 then N'ВыезднойМенеджер' else N'' end as [ЗаявкаВыезднойМенеджер]
,case 
	when tch.[РП_Регион] is null then N'Москва' 
	when tch.[РП_Регион] like N'%Москва%' or tch.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
	else 
		case when tch.[РП_Регион] like N'РП ВМ%' then substring(tch.[РП_Регион], 7,50) else substring(tch.[РП_Регион], 4,50) end
end as [ЗаявкаРегион]
,case 
	when tch.[РП_Регион] is null then N'Москва' 
	when tch.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
	else substring(tch.[РП_Регион], 4,50)
end as [ЗаявкаРегион2]
,case when tch.[РО_Регион] is null then N'Центральный регион' else substring(tch.[РО_Регион], 4,50) end as [ЗаявкаРОРегион]
,N'' [ЗаявкаДивизион]
,cl.[Наименование] as [ЗаявкаАгент]
,cl.[Наименование] as [ЗаявкаАгентМФО]

--,null as [ЗаявкаНомерГрафика]

--,null as [ЗаявкаДатаНачала]
,cast(dateadd(year,-2000,z.[Дата]) as datetime) as [ДатаЗаявки]

--,datepart(dw,cast(dateadd(year,-2000,z.[Дата]) as datetime2)) as [ЗаявкаДеньНедели]
--,datepart(wk,cast(dateadd(year,-2000,z.[Дата]) as datetime2)) as [ЗаявкаНеделя]
--,datepart(dd,cast(dateadd(year,-2000,z.[Дата]) as datetime2)) as [ЗаявкаДеньМесяца]
--,datepart(mm,cast(dateadd(year,-2000,z.[Дата]) as datetime2))  as [ЗаявкаМесяц]
--,datepart(yyyy,cast(dateadd(year,-2000,z.[Дата]) as datetime2)) as [ЗаявкаГод]

--,N'ИТОГ_2_ЗАЯВКИ_по_каналам' as [НаименованиеЛиста]

,case
	when rek.[Наименование] is null then ms.[Имя]
	else
		case
			when rek.[Наименование]=N'КЦ' or ms.[Имя]=N'LCRM' then N'Контакт центр'
			when rek.[Наименование] in (N'Контекст (контекстная реклама)' ,N'Контекст (контекстная реклама)' ,N'Сайт (carmoney.ru)' ,N'Живо-чат' ,N'Roistat')  
				then N'Интернет'
			when rek.[Наименование]  in (N'Лидогенератор' ,N'Кокос' ,N'Creditors24') then N'Лидогенератор'
			when rek.[Наименование] =N'Повторный клиент' then N'Повторная заявка/займ'
			when rek.[Наименование] =N'Мобильное приложение' then N'Мобильное приложение'
			when rek.[Наименование] =N'Сторонний КЦ' then N'Сторонний КЦ'
			when rek.[Наименование] =N'Прочее' then N'Прочее'
--					when then
			else rek.[Наименование] 
		end
end as [ЗаявкаНаименованиеПараметра]

--,N'Ежедневный' as [ПериодичностьОтчета]

,case
	when z.[Сумма]<=150000 then N'до 150'
	when z.[Сумма]>150000 and z.[Сумма]<=700000 then N'151-700'
	when z.[Сумма]>700000 and z.[Сумма]<=1000000 then N'701-1000'
	when z.[Сумма]>1000000 then N'более 1000'
	else N'Прочее'
end as [ЗаявкаКогорта]

,N'' as [ВидДоговора]
,zs.[Ссылка] as [ЗаявкаТекСтатусМФО]
,zs.[Наименование] as [ЗаявкаСтатусНаим]
,null as [ЗаявкаЛидогенератор]

,case
	when not d.[Номер] is null
		then 	  
			case 
				when tvk.[Имя]=N'ПовторныйЗайм' then 
					case 
						when not tv2k.[Имя] is null then 
														case 
															when tv2k.[Имя]=N'Другое' then  N'Прочее'
															when tv2k.[Имя]=N'ЛКПартнера' then  N'Партнер'
															else tv2k.[Имя] 
														end
						else rek.[Наименование] 
					 end
				when tvk.[Имя] is null then rek.[Наименование] 
				else 
					case 
						when tvk.[Имя]=N'Другое' then  N'Прочее'
						when tvk.[Имя]=N'ЛКПартнера' then  N'Партнер'
						else tvk.[Имя] 
					end 
			end
	else rek.[Наименование]
end as [ЗаявкаКаналМФО_ТочкаВх]

,rek.[Наименование] as [ТочкаВходаЗаявки]
,ms.[Имя] as [МестоСоздЗаявки]
,svz.[Имя] as [СпособВыдачиЗайма]
,dblzz.[ПризнакНаличияОсн] as [ЕстьОсновнаяЗаявка]
,znz.[НомерВторойЗаявки] as [ПризнакОформлНовой]
,case
	when zs.[Ссылка]=0x8D0D358E813B836A4F34C2C81F9ADC1D then
		case 
			when az.[Ссылка] is null then
										case 
											when urs.[РольПользователя]=N'ПМ' then N'ПМ-ошибка данных'
											when urs.[РольПользователя]=N'СБ' then N'СБ-ошибка данных'
											when urs.[РольПользователя]=N'Администратор' then N'Админ'
											else N'Администратор'
										end
			else N''
		end
	else N''
end as [ЗаявкаПризнакАннулирования]
,zvf.[ПериодВерификации] as [ВремяПриходаНаВерификацию]
,zs.[Наименование] as [ЗаявкаТекСтатус]
,zrs.[Имя] as [ПричинаИзмСтатусаЗаявки]
--,d.[Номер] as [ДоговорНомер]
--,dl.[Статус] as [ДогТекСтатус]

--------------------------------------------------
--------------------------------------------------
-- для договора
,case 
	when not dv.[ДатаВыдачиЗайма] is null then dateadd(MONTH,datediff(MONTH,0,dv.[ДатаВыдачиЗайма]),0) --dateadd(MONTH,datediff(MONTH,0,dv.[ДатаВыдачиЗайма]),0)
--	else  dateadd(MONTH,datediff(MONTH,0,cast(dateadd(year,-2000,zl.[Период]) as datetime2)),0) --dateadd(MONTH,datediff(MONTH,0,zl.[Период]),0)
end as [ПериодУчетаДоговор]
--,dv.[ДатаВыдачиЗайма] as [ПериодУчетаДоговор]
,d.[Ссылка] as [ДоговорСсылка]


,d.[Номер] as [ДоговорНомер]
,d.[Номер] as [ДоговорНомерМФО]

,dv.[ДатаВыдачиЗайма] as [ДатаВыдачиДоговора]
,case when not dv.[ДатаВыдачиЗайма] is null then dateadd(month,d.[Срок], dv.[ДатаВыдачиЗайма]) end as [ДатаОкончанияДоговора]

,case when prez.[Сумма]=0 then z.[Сумма] else prez.[Сумма] end as [ДоговорПервичнаяСумма]
,d.[Сумма] as [СуммаДоговора]
,d.[СуммаДополнительныхУслуг] as [ДоговорСуммаДопПродуктов]
,(isnull(d.[Сумма],0)-isnull(d.[СуммаДополнительныхУслуг],0)) as [ДоговорСуммаБезДопУслуг]
,case when not dv.[ДатаВыдачиЗайма] is null then 1 end as [ДоговорКолво]
,case when d.[СуммаДополнительныхУслуг]<>0 then 1 else 0 end as [ДоговорКолвоДопПродуктов] 

,d.[Срок] as [ДоговорСрок]
,case when d.[ПроцентнаяСтавка]<>0 then d.[ПроцентнаяСтавка] else kp.[ТекущаяСсуда] end as [ДоговорПроцентнаяСтавка]
,kpd.[Наименование] as [ДоговорКредитныйПродукт]


,od.[Код] as [ДоговорТочкаКод]
,od.[Наименование] as [ДоговорТочка]
,case when od.[ВыезднойМенеджер]=0x01 then N'ВыезднойМенеджер' else N'' end as [ДоговорВыезднойМенеджер]


,case 
	when tchd.[РП_Регион] is null then N'Москва' 
	when tchd.[РП_Регион] like N'%Москва%' or tchd.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
	else 
		case when tchd.[РП_Регион] like N'РП ВМ%' then substring(tchd.[РП_Регион], 7,50) else substring(tchd.[РП_Регион], 4,50) end
end as [ДоговорРегион]
,case 
	when tchd.[РП_Регион] is null then N'Москва'
	when tchd.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
	else substring(tchd.[РП_Регион], 4,50)
end as [ДоговорРегион2]
,case when tchd.[РО_Регион] is null then N'Центральный регион' else substring(tchd.[РО_Регион], 4,50) end as [ДоговорРОРегион]

,N'' as [ДоговорДивизион]

,tchd.[Агент] as [ДоговорАгентМФО]

,null as [ДоговорНомерГрафика]

,dv.[ДатаВыдачиЗайма] as [ДоговорДатаНачала]
,d.[Дата] as [ДатаДоговора]

,null as [ДоговорВидДоговора]
,dl.[Статус] as [ДоговорТекСтатусМФО]
,dl.[Статус] as [ДоговорСтатусНаим_UMFO]


--------------------------------------------------
--------------------------------------------------

FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок_ИтогиСрезПоследних] zl
	
	left join [prodsql02].[mfo].[dbo].[Перечисление_ГП_ПричиныСтатусаЗаявки] zrs
	ON zl.[Причина]=zrs.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] z -- zayvka
		on zl.[Заявка]=z.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Документ_DZ_ПредварительнаяЗаявка] prez -- предварительная заявка
		on z.[ПредварительнаяЗаявка]=prez.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыЗаявок] zs
		on zl.[Статус]=zs.[Ссылка]

	left join (
				select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион],mt0.[ПодчНаим] as [Точка],mt0.[Подчиненный] as [ТочкаСсылка] 
				from [Stg].[dbo].[aux_OfficeMFO_1c]  mt0
					left join(select * from [Stg].[dbo].[aux_OfficeMFO_1c]) mt1
					on mt0.[ПроРодитель]=mt1.[Подчиненный]
				where mt0.[ПодчНаим] like N'Партнер%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр' or mt0.[ПодчНаим] like N'%ВМ%'
				) tch -- Точка-РП-РО
		on z.[Точка]=tch.[ТочкаСсылка]

  	left join [prodsql02].[mfo].[dbo].[Перечисление_СпособыВыдачиЗаймов] svz --y
		on z.[СпособВыдачиЗайма]=svz.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Перечисление_ВидыДокредитования] dkr --y
		on z.[Докредитование]=dkr.[Ссылка]

	left join (select dblzz4.[ПризнакНаличияОсн], dblzz4.[ДубльЗаявки]
			   from (select [ПризнакНаличияОсн] ,[ДубльЗаявки]
					 from (select dblzz1.[Номер] as [ОсновнаяЗаявка], N'Y' as [ПризнакНаличияОсн] ,dblzz0.[ДубльЗаявки] 
						   from [prodsql02].[mfo].[dbo].[РегистрСведений_ДублиЗаявок] dblzz0
								left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] dblzz1
								on dblzz0.[ОсновнаяЗаявка]=dblzz1.[Ссылка]
							) dblzz3
				group by [ПризнакНаличияОсн], [ДубльЗаявки]
					 ) dblzz4
				) dblzz
		on z.[Ссылка]=dblzz.[ДубльЗаявки]

	left join [prodsql02].[mfo].[dbo].[Перечисление_ГП_МестаСозданияЗаявки] ms --y
		on z.[МестоСозданияЗаявки]=ms.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[РегистрСведений_ТочкиВходаЗаявок] tv
		on z.[ПредварительнаяЗаявка]=tv.[ПредварительнаяЗаявка]

	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] d
		on z.[Ссылка]=d.[Заявка]

	left join (select dl0.[Договор], dl1.[Наименование] as [Статус] 
			   from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров_ИтогиСрезПоследних] dl0
			   left join [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыДоговоров] dl1
			   on dl0.[Статус]=dl1.[Ссылка]
			   ) dl
		on d.[Ссылка]=dl.[Договор]


	left join [prodsql02].[mfo].[dbo].[Справочник_НастройкиПринадлежностиКРекламнымКомпаниям] rek
		on tv.[ТочкаВхода]=rek.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Перечисление_ТочкиВходаКлиентов] tvk
		on d.[ТочкаВходаКлиента]=tvk.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Перечисление_ТочкиВходаКлиентов] tv2k
		on d.[ТочкаВходаПовторногоКлиента]=tv2k.[Ссылка]


	left join (SELECT min(sd0.[Период]) as [ПериодПогашения] ,d0.[Контрагент] as [Контрагент] --,d0.[Номер] as [НомерПогашДоговора]
			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров_ИтогиСрезПоследних] sd0
					left join (
							   select [Ссылка],[Номер],[Контрагент]
							   from [prodsql02].[mfo].[dbo].[Документ_ГП_Договор]
							   ) d0
					on sd0.[Договор]=d0.[Ссылка]
				where [Статус]=0xB074EC051022E2274B7AA44702431457  -- Статус Погашен
				group by d0.[Контрагент]
			   ) ssd0 -- таблица с договорами с минимальной датой в статусе погашен из МФО
		on z.[КонтрагентКлиент]=ssd0.[Контрагент] and z.[Дата]>ssd0.[ПериодПогашения]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_КредитныеПродукты] kp
		on z.[КредитныйПродукт]=kp.[Ссылка]

	left join (SELECT max(cast(dateadd(year,-2000,[Период]) as datetime2)) as [ДатаВыдачиЗайма],[Заявка]
			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок]
			   WHERE [Статус]=0xA398265179685AF34EED1A6B6349A87B -- Статус заем выдан
			   GROUP BY [Заявка]
				) dv
		on z.[Ссылка]=dv.[Заявка]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_Офисы] o
		on z.[Точка]=o.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Справочник_Контрагенты] cl
		on o.[Партнер]=cl.[Ссылка]
	

	left join (Select znz3.[Ссылка] ,znz3.[Номер] ,znz3.[НомерВторойЗаявки] --,case when zz.[НомерВторойЗаявки]<>N''  then N'Y' else N'' end as [ПризнакОформлНовой],zz.[rank_zz1Num]
			   from (select znz0.[Ссылка] ,znz0.[Номер] ,cast((case when znz1.[Ссылка] is null then N'' else znz1.[Номер] end) as nvarchar(255)) as [НомерВторойЗаявки]
				  		   ,rank() over(partition by znz0.[Ссылка] order by (case when znz1.[Ссылка] is null then N'' else znz1.[Номер] end) desc) as [rank_zz1Num]
					 from [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] znz0
					 left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] znz1
					 on znz0.[Ссылка]<>znz1.[Ссылка] and znz0.[Дата]<znz1.[Дата]
						 and dateadd(day,datediff(day,0,znz0.[Дата]),0)=dateadd(day,datediff(day,0,znz1.[Дата]),0)
						 and znz0.[КонтрагентКлиент]=znz1.[КонтрагентКлиент]
					 where znz0.[ПометкаУдаления]=0x00 and znz0.[Дата] between @DateStartCurr2000 and @GetDate2000) znz3
			  where znz3.[rank_zz1Num]=1 
--			  order by znz3.[Номер] desc	
			  ) znz  -- таблица с признаком наличия новой заявки из МФО
		on z.[Ссылка]=znz.[Ссылка]

	left join (select min([Период]) as [ПериодВерификации] ,[Заявка]
			   from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок]
			   where ([Период] between @DateStartCurr2000 and @GetDate2000) and [Регистратор_ТипСсылки]<>0x00002B23 -- не документ "АннулированиеЗаявки"
					  and [Статус] in (0x870149E219B7829348ECAD1B81C4AE97  --Статус Верификация КЦ
				 					   ,0xA52424BDFE434D014FF2A32D8D6ACA6F --Статус Верификация документов клиента
										-- ,0x9C4DDF3CA0AFEDC84D92D351E60A78D0 --Статус Верификация документов
									   ,0x8D0D358E813B836A4F34C2C81F9ADC1D --Статус Заявка аннулирована
									  )
				group by [Заявка]			   
			   ) zvf -- таблица с датой начала верификации заявки из МФО
		on z.[Ссылка]=zvf.[Заявка]
	
	left join [Stg].[dbo].[aux_UserRoleMFO_1c] urs
	  on zl.[Исполнитель]=urs.[Пользователь_Ссылка]

	left join [prodsql02].[mfo].[dbo].[Документ_ГП_АннулированиеЗаявки] az
	  on zl.[Регистратор_Ссылка]=az.[Ссылка]


--------- Для договора

	left join [Stg].[dbo].[aux_OfficesOfPartnersMFO_1c] tchd
		on d.[Точка]=tchd.[ТочкаСсылка]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_КредитныеПродукты] kpd
		ON d.[КредитныйПродукт]=kpd.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_Офисы] od
		ON d.[Точка]=od.[Ссылка]

	--left join (
	--		  select dsd0.[Договор] ,dsd1.[Наименование] as [ТекСтатусдоговора]
	--		  from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров_ИтогиСрезПоследних] dsd0
	--			left join [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыДоговоров] dsd1
	--				on dsd0.[Статус]=dsd1.[Ссылка] 
	--		  ) dsd
	--	on d.[Ссылка]=dsd.[Договор]

  where z.[Дата] between @DateStartCurr2000 and @GetDate2000 -- between @GetDate2000Start and @GetDate2000 
		and z.[ПометкаУдаления]=0x00
		--cast(dateadd(year,-2000,z.[Дата]) as datetime2)  >= dateadd(month,0,dateadd(month,datediff(month,0,@GetDate2000),0)) 
		--and cast(dateadd(year,-2000,z.[Дата]) as datetime2)<dateadd(day,datediff(day,0,GetDate()),0) 
		 --and Month(z.[Дата])=Month(@DateReport)
--  order by z.[Дата] asc
)

select distinct * into #tmpl from rl where [ЗаявкаДатаОперации]>=@DateStartCurr

begin tran

delete from [dwh_new].[dbo].[mt_requests_loans_mfo] 
where [ЗаявкаДатаОперации] >= @DateStartCurr; --@DateStartCurr;	--dateadd(day,datediff(day,0,Getdate()),0); -- @DateStart; --dateadd(day,datediff(day,0,Getdate()),0); --


insert into [dwh_new].[dbo].[mt_requests_loans_mfo] ([ЗаявкаПериодУчета] ,[ЗаявкаДатаОперации] ,[ЗаявкаНомер] ,[ЗаявкаНомерМФО] ,[ЗаявкаСсылка] 
														,[Фамилия] ,[Имя] ,[Отчество] ,[ДатаРождения] 
														,[ПервичнаяСумма] ,[СуммаЗаявки] ,[СуммаДопПродуктовЗаявка] ,[СуммаБезДопУслугЗаявка] ,[Колво] ,[КолвоДопПродуктовЗаявка] 
														,[ЗаявкаСрок] ,[ПроцентнаяСтавка] ,[КредитныйПродукт] 
														,[Докредитование] ,[Повторность] ,[ДатаПогашПервДог] ,[ПовторностьNew] 
														,[ЗаявкаТочкаКод] ,[ЗаявкаТочка] ,[ЗаявкаВыезднойМенеджер] ,[ЗаявкаРегион] ,[ЗаявкаРегион2] ,[ЗаявкаРОРегион] ,[ЗаявкаДивизион] ,[ЗаявкаАгент] ,[ЗаявкаАгентМФО] 
														,[ДатаЗаявки] --,[ЗаявкаДеньНедели] ,[ЗаявкаНеделя] ,[ЗаявкаДеньМесяца] ,[ЗаявкаМесяц] ,[ЗаявкаГод] 
														--,[НаименованиеЛиста] nvarchar(255) null
														,[ЗаявкаНаименованиеПараметра] ,[ЗаявкаКогорта] 
														,[ВидДоговора] ,[ЗаявкаТекСтатусМФО] ,[ЗаявкаСтатусНаим] ,[ЗаявкаЛидогенератор] 
														,[ЗаявкаКаналМФО_ТочкаВх] ,[ТочкаВходаЗаявки] ,[МестоСоздЗаявки] ,[СпособВыдачиЗайма] ,[ЕстьОсновнаяЗаявка] 
														,[ПризнакОформлНовой] ,[ЗаявкаПризнакАннулирования] ,[ВремяПриходаНаВерификацию] ,[ЗаявкаТекСтатус] ,[ПричинаИзмСтатусаЗаявки]
														------------------------
														------для договора
														,[ПериодУчетаДоговор] ,[ДоговорСсылка] ,[ДоговорНомер] ,[ДоговорНомерМФО] ,[ДатаВыдачиДоговора] ,[ДатаОкончанияДоговора] 
														,[ДоговорПервичнаяСумма] ,[СуммаДоговора] ,[ДоговорСуммаДопПродуктов] ,[ДоговорСуммаБезДопУслуг] ,[ДоговорКолво] ,[ДоговорКолвоДопПродуктов]
														,[ДоговорСрок] ,[ДоговорПроцентнаяСтавка] ,[ДоговорКредитныйПродукт] 
														,[ДоговорТочкаКод] ,[ДоговорТочка] ,[ДоговорВыезднойМенеджер] ,[ДоговорРегион] ,[ДоговорРегион2] ,[ДоговорРОРегион] ,[ДоговорДивизион] ,[ДоговорАгентМФО] 
														,[ДоговорНомерГрафика] ,[ДоговорДатаНачала] ,[ДатаДоговора] 
														,[ДоговорВидДоговора] ,[ДоговорТекСтатусМФО] ,[ДоговорСтатусНаим_UMFO]
														)
select * from #tmpl


commit tran
 
 

begin tran

delete from dwh_new.dbo.mt_PlaceOfIssueOfLoan 
where [ДатаВыдачиДоговора] >= @DateStartCurr; 
 
--drop table if exists dwh_new.dbo.mt_PlaceOfIssueOfLoan
insert into dwh_new.dbo.mt_PlaceOfIssueOfLoan ([ДоговорНомер] ,[ДатаВыдачиДоговора] ,[ДоговорТочкаКод] ,[ДоговорТочка])
select  [ДоговорНомер] ,[ДатаВыдачиДоговора] ,[ДоговорТочкаКод] ,[ДоговорТочка]
from #tmpl
where not [ДоговорНомер] is null and [ДатаВыдачиДоговора] >= @DateStartCurr
 
commit tran
	
END

