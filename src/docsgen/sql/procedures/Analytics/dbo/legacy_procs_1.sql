


create proc 

dbo.legacy_procs_1 as

begin

	
declare @date_from datetime = cast(dateadd(dd,-1, getdate()) as date)

drop table if exists #temp
select
	dos.attempt_start as dt,
	dos.client_number as phone,
	'Робот-Лидогенератор' as project_title,
	'Марина' as operator_title,
	dos.attempt_result as call_result,
	NULL as refus_reason,
	lh.UF_ROW_ID as id_issue,
	0 as toggle_issue_by_call,
	datediff(ss,dos.attempt_start,dos.attempt_end) as call_duration,
	'https://ncc.cm.carmoney.ru/fx/callrecord?session_id=' + dos.session_id as link_by_call
into #temp
from
	NaumenDbReport.[dbo].[detail_outbound_sessions] dos with(nolock) 
	left join feodor.dbo.dm_leads_history lh with(nolock) on lh.uuid = dos.case_uuid
where
	dos.project_id = 'corebo00000000000n8i9hcja56hji2o'
	and dos.attempt_start between @date_from and cast(getdate() as date)
	and dos.login is NULL
	and dos.attempt_result = 'abandoned'

select
	dos.attempt_start as dt,
	dos.client_number as phone,
	cc.projecttitle as project_title,
	case
		when charindex('обзвон',t.Наименование)>0 then 'доработка по клиенту'
		else ltrim(lower(replace(replace(replace(t.Наименование,'(Звонок:',''),')',''),'(','')))
	end	as task_title,
	em.title as operator_title,
	dos.attempt_result as call_result,
	lh.UF_RC_REJECT_CM as refus_reason,
	ISNULL(lh.UF_ROW_ID, z.Номер) as id_issue,
	IIF(dos.attempt_result in ('MP','Consent'),1,0) as toggle_issue_by_call,
	datediff(ss,dos.attempt_start,dos.attempt_end) as call_duration,
	'https://ncc.cm.carmoney.ru/fx/callrecord?session_id=' + dos.session_id as link_by_call
into #temp2
from
	[NaumenDbReport].[dbo].[mv_call_case] cc  with(nolock) 
	inner join NaumenDbReport.[dbo].[detail_outbound_sessions] dos with(nolock) on dos.case_uuid=cc.uuid
	inner join [NaumenDbReport].dbo.[mv_employee] em (nolock) on em.login = dos.login
	inner join devDB.dbo.nau_result_decryption nrd on nrd.result_nau_eng = dos.attempt_result
	left join Feodor.dbo.dm_leads_history lh (nolock) on lh.uuid = cc.uuid
	left join Stg.[_1cCRM].[Документ_ТелефонныйЗвонок] tc1c (nolock) on tc1c.Session_id = dos.session_id --тянем не Федоровские звонки
	left join Stg.[_1cCRM].[Документ_CRM_Взаимодействие] v (nolock) on tc1c.ВзаимодействиеОснование_Ссылка = v.Ссылка
	left join Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z (nolock) on z.Ссылка = v.Заявка_Ссылка	 
	left join Stg.[_1cCRM].Задача_ЗадачаИсполнителя t (nolock) on v.Задача = t.Ссылка
where
	dos.attempt_start between @date_from and cast(getdate() as date)
	and dos.login is not NULL
	and (lh.uuid is not NULL or tc1c.Ссылка is not NULL)


insert into 
	devDB.dbo.Report_calls_search (dt,	phone,	project_title, task_title,	operator_title,	call_result, refus_reason,id_issue,toggle_issue_by_call,	call_duration,	link_by_call)
select
	*
from(
select
	dt,
	phone,
	project_title,
	'запрос недостающих данных' as task_title,
	operator_title,
	call_result,
	cast(refus_reason as nvarchar(250)) as refus_reason,
	id_issue,
	toggle_issue_by_call,
	call_duration,
	link_by_call
from
	#temp2
union all
	select
		dt,
		phone,
		project_title,
		'запрос недостающих данных' as task_title,
		operator_title,
		call_result,
		cast(refus_reason as nvarchar(250)) as refus_reason,
		id_issue,
		toggle_issue_by_call,
		call_duration,
		link_by_call
	from
		#temp)d

update
	devDB.dbo.Report_calls_search
set 
	refus_reason = replace(replace(refus_reason,'Ручной ввод: CC.',''),'Ручной ввод: СС.','')
where
	refus_reason is not NULL


	end