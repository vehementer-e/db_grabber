-- =============================================
-- Author:		Сабанин А.А
-- Create date: 21.01.2020
-- Description:	Отправка уведомления о наличии нового лидгена
-- =============================================
CREATE PROC [dbo].[Send_Mail_New_Lidgen]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @cnt bigint

	drop table if exists #t
	select ID, partitionID, UF_REGISTERED_AT
	into #t
	from (
		SELECT
			t.ID, 
			partitionID = stg.$PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(t.UF_REGISTERED_AT_date),
			t.UF_REGISTERED_AT
		from Stg.[_LCRM].[lcrm_leads_full_calculated]  t with(nolock)
		where id>19000000  
		and (t.[Канал от источника] not in ('Инвестиции', 'Тест'))
		and t.[Тип-Источник] is null
	) t
 
	create clustered index ix on #t(partitionID)

	declare @partitionID int
	declare cur_partition cursor for select  partitionID from #t group by partitionID order by 1 desc

	drop table if exists #t_ids 
	select top(0) ID, UF_REGISTERED_AT
		into #t_ids
	from #t
	drop table if exists #t_Result_PARTITION
	select  top(0)
		UF_TYPE, 
		UF_SOURCE  , 
		CountAll =count(1) ,
		Заявок =count(UF_ROW_ID) ,
		Займов =count(uf_issued_at) 
		into #t_Result_PARTITION
		from stg._LCRM.lcrm_leads_full st
		group by UF_TYPE, UF_SOURCE
	OPEN cur_partition  
	  create clustered index ix on #t_ids(id)
	FETCH NEXT FROM cur_partition   
	INTO @partitionID
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		DELETE  FROM  #t_ids
		insert into #t_ids
		select ID, UF_REGISTERED_AT from #t where partitionID = @partitionID
	
		insert into #t_Result_PARTITION
		select UF_TYPE, UF_SOURCE , count(Id) CountAll,
		Заявок =count(UF_ROW_ID) ,
		Займов =count(uf_issued_at) 
		from stg._LCRM.lcrm_leads_full st with(nolock)
		where stg.$PARTITION.pfn_range_right_date_part_lcrm_leads_full(st.UF_REGISTERED_AT) = @partitionID
			--and exists(select top(1) 1 from #t_ids t where t.Id = st.ID)
			and exists(
				SELECT top(1) 1
				FROM #t_ids t
				WHERE t.ID = st.ID
					AND t.UF_REGISTERED_AT = st.UF_REGISTERED_AT
			)
			and isnull(cast(UF_SOURCE as nvarchar(1024)),'')<>'' 
		group by UF_TYPE, UF_SOURCE
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
		FETCH NEXT FROM cur_partition   
		INTO @partitionID
	END   
	CLOSE cur_partition;  
	DEALLOCATE cur_partition;  
	drop table if exists #Result
	
	select  UF_TYPE, UF_SOURCE
	, CountAll = sum(CountAll)
	, Заявок = sum(Заявок)
	, Займов = sum(Займов)

	into #Result
	from #t_Result_PARTITION
	group by UF_TYPE, UF_SOURCE

--	select * from #Result
	

-- если есть новые вхоождения, то высылаем сообщения на почту
if exists(select top(1) 1 from #Result)
begin
DECLARE @tableHTML  NVARCHAR(MAX) =
    N'<H1>Уведомление о появлении нового лидгена</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>UF_TYPE</th><th>UF_SOURCE</th>' +  
    N'<th>Количество с 01.01.2020</th>' +  
    N'<th>Заявок</th>' +  
    N'<th>Займов</th></tr>' +  
    CAST ( ( SELECT td = UF_TYPE,       '',  
                    td = UF_SOURCE, '',  
                    td = CountAll, '',
                    td = Заявок, '',
                    td = Займов, ''
				from #Result
				order by Займов desc, UF_TYPE,UF_SOURCE
              FOR XML PATH('tr'), TYPE   
			
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  select @tableHTML

  
  EXEC msdb.dbo.sp_send_dbmail 
    @recipients='a.vdovin@carmoney.ru; A.Taov@carmoney.ru; analytics_kc@carmoney.ru',  --Zudin_S_D@carmoney.ru;; Krivotulov@carmoney.ru
    @subject = 'Уведомление о появлении нового лидгена',  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  
	
end

END
