
CREATE   PROC [dbo].[report_document_is_signed_pep]
	@docType nvarchar(255) = 'pledge-agreement', -- 'pledge-agreement'
	@BeginDate date = NULL,
	@EndDate date	= NULL,
	@ValueIsSigned varchar(30) = '1,0'
as
	set @BeginDate = isnull(@BeginDate, dateadd(dd,1, EOMONTH(getdate(),-2)))
	set @EndDate = isnull(@EndDate, getdate())

	DECLARE @t_ValueIsSigned table(val int)

	INSERT @t_ValueIsSigned(val)
	SELECT try_convert(int, S.value)
	FROM string_split(@ValueIsSigned, ',') AS S

select 
	external_id = lk_c.code
	,doc_type = lk_ult.type 
	,doc_type_name = lk_ult.full_description
	,doc_name = lk_cd.name
	,doc_created_time = dateadd(hh, 3, lk_ul.created_at)
	
	,sms_send_date = dateadd(hh, 3,lk_pep_log.sms_send_date)
	,sms_input_date =  dateadd(hh, 3, lk_pep_log.sms_input_date)
	,is_signed = iif( lk_pep_log.sms_input_date is not null, 1, 0)
	--2020-04-16 07:42:47.000

from stg._LK.contracts lk_c
	inner join stg._LK.contract_documents	lk_cd 
		on lk_cd.contract_id =  lk_c.id
	inner join stg._LK.user_link_contract	lk_lc 
		on lk_lc.contract_documents_id = lk_cd.id
	inner join stg._lk.user_link			lk_ul
		on lk_ul.id = lk_lc.user_link_id
	
	inner join stg._lk.user_link_types lk_ult 
	  on lk_ul.user_link_type_id =lk_ult.id
		--and lk_ul.active = 1
 
	left join stg._LK.pep_activity_log lk_pep_log on lk_pep_log .id = lk_ul.pep_activity_log_id
		

WHERE 1=1
	and lk_ult.type = @docType
	AND lk_cd.is_pep = 1
	and cast(
		dateadd(hh, 3, lk_ul.created_at) 
		as date)
		between @BeginDate and @EndDate
	AND iif( lk_pep_log.sms_input_date is not null, 1, 0) IN (
		SELECT V.val FROM @t_ValueIsSigned AS V
		)
order by external_id, doc_created_time
 
