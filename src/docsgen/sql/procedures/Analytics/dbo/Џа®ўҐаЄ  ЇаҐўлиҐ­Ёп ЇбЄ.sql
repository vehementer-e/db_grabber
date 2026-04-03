/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
CREATE   proc [dbo].[Проверка превышения пск]
as
begin
  
  drop table if exists #v_Справочник_Договоры
  SELECT Код, Действует [Дата выдачи], cast(Действует as date) [Дата выдачи день], [Ссылка договор CMR]
  into #v_Справочник_Договоры
  FROM [Analytics].[dbo].[v_Справочник_Договоры]
  where Действует>=cast(getdate()-1 as date) and isInstallment=0 and cast(Действует as date)<'20220303'

  drop table if exists #a1

  select distinct ПСК, Код, [Дата выдачи] into #a1
  from [Stg].[_1cCMR].[Документ_ГрафикПлатежей] g join #v_Справочник_Договоры b on g.Договор=b.[Ссылка договор CMR]
  where  (ПСК>=(select top 1 * from Analytics.[dbo].[current_max_psk])  and [Дата выдачи день]<='20211231' ) or (ПСК>=85.928 and  [Дата выдачи день]>'20211231' )
  and  код not in (select * from [Analytics].dbo.[Учтенные заявки с превышением ПСК] where num is not null)

  insert into [Analytics].dbo.[Учтенные заявки с превышением ПСК]
  select Код from #a1

 ;with v as (
  select текст = (select 'Превышение ПСК по:'+STRING_AGG(cast(' '+Код+' cтавка - '+format(ПСК, '0.000')+' ' as varchar(max)), ',') Текст  from #a1 )
  ,send_to = 'p.ilin@techmoney.ru; A.Taov@carmoney.ru; blagoveschenskaya@carmoney.ru; v.plotnikov@techmoney.ru ; a.hasanshin@carmoney.ru ; e.svideteleva@carmoney.ru'
  ,subject = 'Превышение ПСК'
 )
 select * from v where текст is not null



end

