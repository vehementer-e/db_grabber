/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
CREATE   proc [dbo].[Проверка соотвествия ставок инстоллмент]
as
begin
  
  drop table if exists #v_Справочник_Договоры
  SELECT Код, Действует [Дата выдачи], [Ссылка договор CMR], Срок
  into #v_Справочник_Договоры
  FROM [Analytics].[dbo].[v_Справочник_Договоры]
  where Действует>=cast(getdate()-1 as date) and isInstallment=1

  drop table if exists #a1

  select distinct case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end Ставка, Код, [Дата выдачи] , b.Срок into #a1
  from [Stg].[_1cCMR].РегистрСведений_ПараметрыДоговора g join #v_Справочник_Договоры b on g.Договор=b.[Ссылка договор CMR]
  where case when b.Срок<=6 and case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end=290 then 1
             when b.Срок>6  and case when ПроцентнаяСтавка=0 then НачисляемыеПроценты else ПроцентнаяСтавка end=145 then 1
			 else 0 end <>1
  and  код not in (select * from [Analytics].[dbo].[Учтенные заявки с некорректной связкой ставки и продукта инстоллмент] where num is not null)

--  CREATE TABLE [dbo].[Учтенные заявки с некорректной связкой ставки и продукта инстоллмент]--(--      [num] [NVARCHAR](MAX)--);
--

  insert into [Analytics].[dbo].[Учтенные заявки с некорректной связкой ставки и продукта инстоллмент]
  select Код from #a1

 ;with v as (
  select текст = (select 'Несоответствие ставки и продукта по:'+STRING_AGG(cast(' '+Код+' cтавка - '+format(Ставка, '0.000')+' срок - '+format(Срок, '0')+' ' as varchar(max)), ',') Текст  from #a1 )
  ,send_to = 'p.ilin@techmoney.ru; A.Taov@techmoney.ru; blagoveschenskaya@carmoney.ru; v.plotnikov@techmoney.ru ; a.hasanshin@techmoney.ru ; e.svideteleva@techmoney.ru'
  ,subject = 'Инстоллмент некорректная ставка'
 )
 select * from v where текст is not null

 
end

