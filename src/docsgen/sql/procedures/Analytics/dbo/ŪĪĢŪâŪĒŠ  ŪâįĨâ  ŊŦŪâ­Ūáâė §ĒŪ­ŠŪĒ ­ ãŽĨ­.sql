
CREATE   proc [dbo].[Подготовка отчета плотность звонков наумен]

as 
begin

declare @startdate as date = cast(getdate() - 11  as date)

drop table if exists #pr

select 'corebo00000000000n35ltu7n0jje82k' pr into #pr union
select 'corebo00000000000mqpsrh9u28s16g8' union
select 'corebo00000000000n8i9hcja56hji2o' union
select 'corebo00000000000nhc39ilthenudg4' union
select 'corebo00000000000n56bur0s6arg22o' union
select 'corebo00000000000mtmnhcj42ev6svs' union
select 'corebo00000000000mtmnk1gt6gdvdc0' union
select 'corebo00000000000mqi35tcal14edv4' union
select 'corebo00000000000nchpe3fv0j6f4ag' union
select 'corebo00000000000n56buhov4c5cjug' union
select 'corebo00000000000nfl3ha5m324gqro' union
select 'corebo00000000000o1kc5vogkqq4ke0' union
select 'corebo00000000000n9q7vju6irp0vmg' union
select 'corebo00000000000nd135ldk2oc12gs' union
select 'corebo00000000000n25qe838j4oni4k' union
select 'corebo00000000000o7kd1vmc3ra8als' union
select 'corebo00000000000o3988iubi6174ks' union
select 'corebo00000000000o1n1tekji32s4q4' union
select 'corebo00000000000o1kc5vogkqq4ke0' union
select 'corebo00000000000o5sq5co51hpk8m8' union
select 'corebo00000000000o7j6jja14ctq4p4' union
select IdExternal from Feodor.dbo.dm_feodor_projects  union

select 'corebo00000000000nqvsc5jtklnqd70' union 
select 'corebo00000000000ms0iggb3gbo7lv0' union 
select 'corebo00000000000msiiqd99k5req2s' union 
select 'corebo00000000000n2c4ma01jeu56tg' union 
select 'corebo00000000000n25qgjgs0g82mjo' union 
select 'corebo00000000000ms6slfj341gnrd0' union 
select 'corebo00000000000ms8u5urtmth4ev0' union 
select 'corebo00000000000mqi35tcal14edv4' union 
select 'corebo00000000000mmh99j7n6gj1dh0' union 
select 'corebo00000000000mm1tt1cr218d59k' union 
select 'corebo00000000000mokh4an1665brtk' union 
select 'corebo00000000000nbb1b9jb7da9aa0' union 
select 'corebo00000000000n2ngq5c3h7idjh8' union 
select 'corebo00000000000n8r40vet4t9ap58' union 
select 'corebo00000000000mr2v66ju30bt7sg' union 
select 'corebo00000000000mqfr66nk2bfpln0' union 
select 'corebo00000000000mtmnk1gt6gdvdc0' union 
select 'corebo00000000000n8i9hcja56hji2o' union 
select 'corebo00000000000nfv3p83uiqcn9kg' union 
select 'corebo00000000000mpe8lf4jka7rer8' union 
select 'corebo00000000000nfl3ha5m324gqro' union 
select 'corebo00000000000n35ltu7n0jje82k' union 
select 'corebo00000000000n25qe838j4oni4k' union 
select 'corebo00000000000mrjiqupb60gdldc' union 
select 'corebo00000000000nd2o4o2ej2bo5l4' union 
select 'corebo00000000000ms4b9aud5rar9oo' union 
select 'corebo00000000000n25qdghk472krt8' union 
select 'corebo00000000000n56buhov4c5cjug' union 
select 'corebo00000000000n2ngrt4mji7srs8' union 
select 'corebo00000000000n9lae4v61imm0m4' union 
select 'corebo00000000000n25qgnvfnogtjf8' union 
select 'corebo00000000000n2u10qdrkhgc1r4' union 
select 'corebo00000000000n2u15l5ohuq8gp0' union 
select 'corebo00000000000n9q7vju6irp0vmg' union 
select 'corebo00000000000n56bur0s6arg22o' union 
select 'corebo00000000000n25qereimll7884' union 
select 'corebo00000000000n25qfiqhjjmogcg' union 
select 'corebo00000000000mqpsrh9u28s16g8' union 
select 'corebo00000000000nb2602rnmrgdmrk' union 
select 'corebo00000000000nb269ejp3kvdmf8' union 
select 'corebo00000000000nr8tj5chijbg124' union 
select 'corebo00000000000mmg311cmgpk12ek' union 
select 'corebo00000000000nfv43b583tqck9k' union 
select 'corebo00000000000nd135ldk2oc12gs' union 
select 'corebo00000000000nchpe3fv0j6f4ag' union 
select 'corebo00000000000nchqr3rfktcr5hc' union 
select 'corebo00000000000nhc39ilthenudg4' union 
select 'corebo00000000000mn2eg74l4nb9950' union 
select 'corebo00000000000n25ihpl26il6uho' union 
select 'corebo00000000000niqoqsgh2tui8k0' union 
select 'corebo00000000000niqoje3j0hnrbr0' union 
select 'corebo00000000000niqonh1g2763918' union 
select 'corebo00000000000nnqgig6i7tis940' union 
select 'corebo00000000000niqosbsl6j5cmfs' union 
select 'corebo00000000000nsklmuti0jijl5o' union 
select 'corebo00000000000mtmnhcj42ev6svs' union 
select 'corebo00000000000mm1tts6og6rs2fk' union 
select 'corebo00000000000mqrftq8mhigv9qo' union 
select 'corebo00000000000n25qftft0i6nq2s' union 
select 'corebo00000000000mmp6cjhc0392dig' union 
select 'corebo00000000000nd2o74eg1r67938' union 
select 'corebo00000000000ncj5h1s4irsailk' union 
select 'corebo00000000000nqckou5524ntca0' union 
select 'corebo00000000000mmsuu7psg3t39ss' union 
select 'corebo00000000000ntveaeqb47pg1q0' union 
select 'corebo00000000000ntveeltm4rn8h3c' union 
select 'corebo00000000000nv396h4hh51ijlg' union 
select 'corebo00000000000nv4mqrsin6g8sck' union 
select 'corebo00000000000nvg57ke41losnr8' union 
select 'corebo00000000000o5juafkhm50e0mk' union 
select 'corebo00000000000n25qe838j4oni4k' union 
select 'corebo00000000000o7kd1vmc3ra8als' union 
select 'corebo00000000000o3988iubi6174ks' union 
select 'corebo00000000000o1n1tekji32s4q4' union 
select 'corebo00000000000o1kc5vogkqq4ke0' union 
select 'corebo00000000000o5sq5co51hpk8m8' union 
select 'corebo00000000000o7j6jja14ctq4p4'  union

select 'corebo00000000000nqvsc5jtklnqd70' union 
select 'corebo00000000000ms0iggb3gbo7lv0' union 
select 'corebo00000000000msiiqd99k5req2s' union 
select 'corebo00000000000n2c4ma01jeu56tg' union 
select 'corebo00000000000n25qgjgs0g82mjo' union 
select 'corebo00000000000ms6slfj341gnrd0' union 
select 'corebo00000000000ms8u5urtmth4ev0' union 
select 'corebo00000000000mqi35tcal14edv4' union 
select 'corebo00000000000mmh99j7n6gj1dh0' union 
select 'corebo00000000000mm1tt1cr218d59k' union 
select 'corebo00000000000mokh4an1665brtk' union 
select 'corebo00000000000nbb1b9jb7da9aa0' union 
select 'corebo00000000000n2ngq5c3h7idjh8' union 
select 'corebo00000000000n8r40vet4t9ap58' union 
select 'corebo00000000000mr2v66ju30bt7sg' union 
select 'corebo00000000000mqfr66nk2bfpln0' union 
select 'corebo00000000000mtmnk1gt6gdvdc0' union 
select 'corebo00000000000n8i9hcja56hji2o' union 
select 'corebo00000000000nfv3p83uiqcn9kg' union 
select 'corebo00000000000mpe8lf4jka7rer8' union 
select 'corebo00000000000nfl3ha5m324gqro' union 
select 'corebo00000000000n35ltu7n0jje82k' union 
select 'corebo00000000000n25qe838j4oni4k' union 
select 'corebo00000000000mrjiqupb60gdldc' union 
select 'corebo00000000000nd2o4o2ej2bo5l4' union 
select 'corebo00000000000ms4b9aud5rar9oo' union 
select 'corebo00000000000n25qdghk472krt8' union 
select 'corebo00000000000n56buhov4c5cjug' union 
select 'corebo00000000000n2ngrt4mji7srs8' union 
select 'corebo00000000000n9lae4v61imm0m4' union 
select 'corebo00000000000n25qgnvfnogtjf8' union 
select 'corebo00000000000n2u10qdrkhgc1r4' union 
select 'corebo00000000000n2u15l5ohuq8gp0' union 
select 'corebo00000000000n9q7vju6irp0vmg' union 
select 'corebo00000000000n56bur0s6arg22o' union 
select 'corebo00000000000n25qereimll7884' union 
select 'corebo00000000000n25qfiqhjjmogcg' union 
select 'corebo00000000000mqpsrh9u28s16g8' union 
select 'corebo00000000000nb2602rnmrgdmrk' union 
select 'corebo00000000000nb269ejp3kvdmf8' union 
select 'corebo00000000000nr8tj5chijbg124' union 
select 'corebo00000000000mmg311cmgpk12ek' union 
select 'corebo00000000000nfv43b583tqck9k' union 
select 'corebo00000000000nd135ldk2oc12gs' union 
select 'corebo00000000000nchpe3fv0j6f4ag' union 
select 'corebo00000000000nchqr3rfktcr5hc' union 
select 'corebo00000000000nhc39ilthenudg4' union 
select 'corebo00000000000mn2eg74l4nb9950' union 
select 'corebo00000000000n25ihpl26il6uho' union 
select 'corebo00000000000niqoqsgh2tui8k0' union 
select 'corebo00000000000niqoje3j0hnrbr0' union 
select 'corebo00000000000niqonh1g2763918' union 
select 'corebo00000000000nnqgig6i7tis940' union 
select 'corebo00000000000niqosbsl6j5cmfs' union 
select 'corebo00000000000nsklmuti0jijl5o' union 
select 'corebo00000000000mtmnhcj42ev6svs' union 
select 'corebo00000000000mm1tts6og6rs2fk' union 
select 'corebo00000000000mqrftq8mhigv9qo' union 
select 'corebo00000000000n25qftft0i6nq2s' union 
select 'corebo00000000000mmp6cjhc0392dig' union 
select 'corebo00000000000nd2o74eg1r67938' union 
select 'corebo00000000000ncj5h1s4irsailk' union 
select 'corebo00000000000nqckou5524ntca0' union 
select 'corebo00000000000mmsuu7psg3t39ss' union 
select 'corebo00000000000ntveaeqb47pg1q0' union 
select 'corebo00000000000ntveeltm4rn8h3c' union 
select 'corebo00000000000nv396h4hh51ijlg' union 
select 'corebo00000000000nv4mqrsin6g8sck' union 
select 'corebo00000000000nvg57ke41losnr8' union 
select 'corebo00000000000o5juafkhm50e0mk' union 
select 'corebo00000000000n25qe838j4oni4k' union 
select 'corebo00000000000o7kd1vmc3ra8als' union 
select 'corebo00000000000o3988iubi6174ks' union 
select 'corebo00000000000o1n1tekji32s4q4' union 
select 'corebo00000000000o1kc5vogkqq4ke0' union 
select 'corebo00000000000o5sq5co51hpk8m8' union 
select 'corebo00000000000o7j6jja14ctq4p4'  


drop table if exists #case

select 
cast(month(creationdate) as int) as mon, 
cast(creationdate as date) as d,
cast(count(uuid) as int) as 'Загружено кейсов',
projectuuid 'Проект'
into #case
from [NaumenDbReport].[dbo].mv_call_case (nolock)
where
creationdate >= @startdate
and projectuuid in (select * from #pr) 
group by month(creationdate), 
cast(creationdate as date),projectuuid


--Обработано:
drop table if exists #obrabot

select 
cast(month(mch.finisheddate) as int) as mon, 
cast(mch.finisheddate as date) as d,
cast(count(mch.historyuuid) as int) as 'Обработано',
mcc.projectuuid 'Проект'
into  #obrabot
from [NaumenDbReport].[dbo].mv_case_history mch (nolock)
left join [NaumenDbReport].[dbo].mv_call_case mcc (nolock) on mch.historyuuid = mcc.uuid and mch.finisheddate is not null
where
mch.finisheddate >= @startdate
and mcc.projectuuid in (select * from #pr) 
and mch.finisheddate is not null
group by month(mch.finisheddate), 
cast(mch.finisheddate as date),mcc.projectuuid


--Попытки:
drop table if exists #pop

select 
cast(month(attempt_start) as int) as mon, 
cast(attempt_start as date) as d, 
cast(count(session_id) as int) as 'Попытки',
project_id 'Проект'
into #pop
from [NaumenDbReport].[dbo].detail_outbound_sessions dos (nolock)
where
attempt_start >= @startdate
and project_id   in (select * from #pr) 
group by month(attempt_start), 
cast(attempt_start as date),project_id 


--Попытки уникальные:
drop table if exists #uniq

select 
cast(month(attempt_start) as int) as mon, 
cast(attempt_start as date) as d, 
cast(count(distinct case_uuid) as int) as 'Уникальных кейсов',
project_id 'Проект'
into #uniq
from [NaumenDbReport].[dbo].detail_outbound_sessions dos (nolock)
where
attempt_start >= @startdate
and project_id in (select * from #pr) 
group by month(attempt_start), 
cast(attempt_start as date),project_id 

--Разница

drop table if exists #razn

select  cast(o.mon as int) mon, cast(o.d as date) d,
	iif(c.[Загружено кейсов] is null,o.Обработано, cast(o.Обработано - c.[Загружено кейсов] as int)) Разница,
	o.Проект
into  #razn
from #obrabot o
	left join #case c on o.d = c.d and o.Проект = c.Проект

drop table if exists  #obrabotka

select o.mon,o.d,c.[Загружено кейсов],o.Обработано,p.Попытки,r.Разница, o.Проект,u.[Уникальных кейсов] Уникальных_кейсов
--,case when format(month(getdate()), 'yyyy-MM-01') = format(month(c.d), 'yyyy-MM-01') then 'Текущий месяц' else format(c.d, 'yyyy-MM-01') end 'Месяц текст'
into #obrabotka
	from #obrabot o
	left join #case c on c.d = o.d and c.Проект = o.Проект
	left join #pop p on o.d = p.d and o.Проект = p.Проект
	left join #razn r on o.d = r.d and o.Проект = r.Проект
	left join #uniq u on o.d = u.d and o.Проект = u.Проект
order by c.d


drop table if exists #t1


select cast(attempt_start as date) Дата ,
n.projecttitle,
datepart(month,attempt_start) as mon, datepart(day,attempt_start) as d, 
datepart(hour,attempt_start) as h, datepart(minute,attempt_start) as m, 
count(session_id) as calls
--,case 
--	when format(month(getdate()), 'yyyy-MM-01') = format(month(attempt_start), 'yyyy-MM-01') then 'Текущий месяц' else format(attempt_start, 'yyyy-MM-01')
--end [Месяц текст]
into #t1
from NaumenDbReport.dbo.detail_outbound_sessions dos 
join reports.[dbo].[dm_NaumenProjects] n on dos.project_id = n.projectuuid
where
--attempt_start >= format(dateadd(m,-3,getdate()), 'yyyy-MM-01') 
attempt_start >= @startdate
and dos.project_id in
(
 select * from #pr  
)
group by cast(attempt_start as date),
n.projecttitle,
datepart(month,attempt_start), 
datepart(day,attempt_start), 
datepart(hour,attempt_start), 
datepart(minute,attempt_start)
--,case when format(month(getdate()), 'yyyy-MM-01') = format(month(attempt_start), 'yyyy-MM-01') then 'Текущий месяц' else format(attempt_start, 'yyyy-MM-01') end 





delete from Analytics.dbo.[Плотность звонков Naumen] where Дата<    dateadd(month, -6, cast( format( getdate() , 'yyyy-MM-01') as date))
delete from Analytics.dbo.[Обработка кейсов Naumen]  where d   <    dateadd(month, -6, cast( format( getdate() , 'yyyy-MM-01') as date))


begin tran

--drop table if exists Analytics.dbo.[Плотность звонков Naumen]
--select * into Analytics.dbo.[Плотность звонков Naumen]
--from #t1

delete from Analytics.dbo.[Плотность звонков Naumen] where Дата >= @startdate
--update Analytics.dbo.[Плотность звонков Naumen] set [Месяц текст] = case when format(month(getdate()), 'yyyy-MM-01') = format(month(Дата), 'yyyy-MM-01') then 'Текущий месяц' else format(Дата, 'yyyy-MM-01') end  
insert into Analytics.dbo.[Плотность звонков Naumen]
select *
from #t1

delete from Analytics.dbo.[Обработка кейсов Naumen] where d >= @startdate
insert into Analytics.dbo.[Обработка кейсов Naumen]
select *
from #obrabotka

commit tran


--select * from Analytics.dbo.[Плотность звонков Naumen]
--order by 1 desc

	
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '8CC3884B-1C6E-4C10-899A-3A4D6F8BFDCD'	  , 1

end

