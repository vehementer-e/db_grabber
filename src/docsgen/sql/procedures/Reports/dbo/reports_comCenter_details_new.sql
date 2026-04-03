--
/*
exec dbo.[reports_comCenter_details_new] 
	@method_guid = '7eb6c10d-1952-4958-8389-b8a7d2e1f19e', 
	@communicationTemplates = 'cecbd9ce-2ced-11ec-a14c-0242ac130005'
*/
CREATE   PROC dbo.reports_comCenter_details_new
	@communicationDateBegin date = null,
	@communicationDateEnd date = null,
	@communicationTemplates nvarchar(max) = null,
	@RecipientSearch nvarchar(255) = null,
	@method_guid nvarchar(36) 
as

	set @communicationDateBegin = isnull(@communicationDateBegin, dateadd(dd, -1, EOMONTH(getdate(),-1)))
	set @communicationDateEnd = isnull(@communicationDateEnd, getdate())

SELECT cont.full_name AS fullName
, comCode.name as communication_code_name 
, comcode.guid as communication_code_guid 
, contMeth.value AS recipient
, CONCAT(template.name,'(',template.code,')') AS template
, COALESCE(NULL,0) AS mailing
, template.guid as template_guid
, sysCode.code AS system
, comCode.code AS communication_code_status
, comJour.code_time AS statusDate
, com.created_at AS communicationDate
, com.guid AS communicationId
, CONCAT('https://comc.carmoney.ru/communication/', com.guid) AS linkMessage 

,prev.prev_statuses


FROM (SELECT comJour2.communication_guid, comJour2.communication_code_guid, comJour2.code_time 
		FROM (SELECT communication_guid, max(code_time) AS code_time 
				FROM [stg].[_comcenter].communications_journal 
				GROUP BY communication_guid) comJour 
				LEFT JOIN [stg].[_comcenter].communications_journal comJour2 ON comJour2.communication_guid = comJour.communication_guid 
				AND comJour2.code_time = comJour.code_time) comJour 
			LEFT JOIN [stg].[_comcenter].communications com ON com.guid = comJour.communication_guid 
			LEFT JOIN [stg].[_comcenter].communication_codes comCode ON comCode.guid = comJour.communication_code_guid 
			LEFT JOIN [stg].[_comcenter].contacts_methods contMeth ON contMeth.guid = com.contact_method_guid 
			LEFT JOIN [stg].[_comcenter].contacts cont ON cont.guid = contMeth.contact_guid 
			LEFT JOIN [stg].[_comcenter].system_codes sysCode ON sysCode.guid = com.system_code_guid 
			LEFT JOIN [stg].[_comcenter].templates template ON template.guid = com.template_guid 
			OUTER APPLY
			(
				select REVERSE(STUFF(REVERSE((
				select prev_comCode.code + ' - ' + FORMAT(prev_cmj.code_time, 'yyyy.MM.dd HH:mm:ss') + '
				' as 'data()'
				from (select max(code_time) code_time, communication_guid, communication_code_guid
					from [stg].[_comcenter].communications_journal prev_cmj 
					group by communication_guid, communication_code_guid 
				) prev_cmj
					left join [stg].[_comcenter].communication_codes prev_comCode 
						on prev_comCode.guid = prev_cmj.communication_code_guid			
				where prev_cmj.communication_guid =  com.guid
								and prev_cmj.code_time<comJour.code_time
			order by prev_cmj.code_time desc
				FOR XML PATH(''), TYPE
	).value('.[1]', 'nvarchar(max)')),1,1,'')) prev_statuses
			) prev
				WHERE 1=1 
					AND (com.method_guid=@method_guid) 
					AND (NOT (comJour.communication_code_guid='9dff029d-647b-456e-a2c2-fe08734b7bc3')) 
					AND (cast(com.created_at as date) between @communicationDateBegin and @communicationDateEnd)
					AND (contMeth.method_guid=@method_guid) 
					and (com.template_guid in (select value from string_split(@communicationTemplates, ',')
									)
					and (contMeth.value like '%'+@RecipientSearch+'%' or nullif(@RecipientSearch,'') is null))
				--GROUP BY com.guid 
				--ORDER BY comJour.code_time DESC
