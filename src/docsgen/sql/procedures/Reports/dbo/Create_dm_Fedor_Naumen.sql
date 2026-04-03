

-- =============================================
-- Author:		Anton Sabanin
-- Create date: 18.06.2021
-- Description:	dwh-1143
-- exec [dbo].[Create_dm_Fedor_Naumen]
-- =============================================
CREATE   PROCEDURE [dbo].[Create_dm_Fedor_Naumen]
	
AS
BEGIN
	

	SET NOCOUNT ON;
-- Ищем новые статусы за последний день в витрине федора
-- Ищем новые звонки за последний день
-- генерируем витрину
drop table if exists #t1
select [Номер заявки],[Дата статуса], [Дата след.статуса], Статус , '8' + cr.ClientPhoneMobile  collate Cyrillic_General_CI_AS as ClientPhoneMobile
, ШагЗаявки , ПоследнийШаг, [Дата заведения заявки]
into #t1
from dbo.dm_FedorVerificationRequests fvr --_2021_03_26
	join stg.[_fedor].[core_ClientRequest] cr on fvr.[Номер заявки] = cr.number
		where [Дата заведения заявки]>=dateadd(day, -1,cast(getdate() as date)) 

-- 
drop table if exists #t
select session_id, created, [connected], src_id, dst_id,text_reason, datediff(second, connected, ended) продолжительность ,leg_id
into #t
from
[NaumenDbReport].[dbo].[call_legs]  (nolock) cl where  [connected]>=dateadd(day, -1,cast(getdate() as date))   --and leg_id=1
--and cl.dst_id in (select distinct top 10  ClientPhoneMobile from #t1)

CREATE CLUSTERED INDEX [created] ON #t
(
	[created] ASC,
	[dst_id] ASC
)

--- дополнительно очистим по номеру телефона
drop table if exists #t2
select tt.* 
, rn = ROW_NUMBER() over(partition by session_id order by продолжительность desc)
into #t2
from #t tt 
 join (select ClientPhoneMobile from #t1 group by ClientPhoneMobile)  t_f on tt.dst_id = t_f.ClientPhoneMobile


delete from #t2 where rn>1

drop table if exists #t_res --dbo.dm_Fedor_Naumen_session_id

select t_fin.[Номер заявки],t_fin.[Дата статуса],created, t_fin.Статус , t_fin.ClientPhoneMobile, t_fin.[Дата заведения заявки],
ttt.session_id,  ttt.text_reason , ttt.продолжительность
into #t_res
--dbo.dm_Fedor_Naumen_session_id
From #t1 t_fin
left join(
select 
[Номер заявки],[Дата статуса],created, Статус , ClientPhoneMobile,
iif (([created] >=[Дата статуса] and [created] < [Дата след.статуса]) or ([created]< [Дата статуса]  and ШагЗаявки = 1 ) or ([created]>= [Дата след.статуса]  and ШагЗаявки = ПоследнийШаг ) ,1 ,0) visible
, t.session_id,  t.text_reason, t.продолжительность
--, rn
from #t1 t1 
left join #t2 t on t.dst_id = t1.ClientPhoneMobile
--where [Номер заявки] = 	'21061100113432'
) ttt
on t_fin.[Номер заявки] = ttt.[Номер заявки] and t_fin.[Дата статуса] = ttt.[Дата статуса] and ttt.visible=1
--where t_fin.[Номер заявки] = 	'21061100113432'
order by t_fin.[Номер заявки],t_fin.[Дата статуса],ttt.created


begin tran

delete from dbo.dm_Fedor_Naumen_session_id where [Номер заявки] in (select distinct [Номер заявки] from #t_res )

insert into dbo.dm_Fedor_Naumen_session_id
select * from #t_res 

commit tran

END
