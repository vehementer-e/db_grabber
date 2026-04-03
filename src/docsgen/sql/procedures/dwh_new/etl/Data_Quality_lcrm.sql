

CREATE procedure [etl].[Data_Quality_lcrm]
as
begin


DECLARE @Names VARCHAR(8000),
        @query varchar(5000),
		-- вызвано ограничением текста sql запроса
		@PageSize INT = 400, 
		@PageNum  INT = 0,
		@TotalRows INT = 201,
		@OrigPageSize INT = 2000000, 
		@OrigPageNum  INT = 0,
		@OrigTotalRows INT = 10000000;


exec [log].[LogAndSendMailToAdmin] 'LCRM Data Quality','Info','procedure started','LCRM Data Quality process started.';


  -- удалим дубли, оставим только последний по дате обновления
 -- with dubli_lcrm as
 -- (
 -- SELECT *, rn=(ROW_NUMBER() over(partition by id order by UF_UPDATED_AT desc)) 
 -- FROM [dwh_new].[staging].[lcrm_tbl_full]
 -- where id in 
	--		  (
	--			SELECT id
	--			FROM  [dwh_new].[staging].[lcrm_tbl_full]
	--			group by id
	--			having COUNT(id)>1
	--		  )
 -- )
 -- --select * FROM dubli_lcrm where rn>1 
  
 --DELETE FROM dubli_lcrm where rn>1

-- *************************
-- Все идентификаторы в LCRM
-- *************************

/* перепишем код так как пошли ошибки выборки */

---- очистим идентификаторы
--TRUNCATE TABLE staging.lcrm_tbl_id; 


-- --получим размер данных
-- -- Ограничение в 20 млн - иначе необходимо делать выгрузку по разным годам регистрации
-- if OBJECT_ID('tempdb.dbo.#temptable') is not null
--drop table dbo.#temptable;
--create table #temptable (ID int null)


--set @query='select max(c1.ID) as OrigTotal
--     from  carmoney_light_crm   c1'

--	exec( 'INSERT INTO #temptable SELECT max(OrigTotal) as ID  from OPENQUERY(LCRM,'''+ @query + ''')')

--	SELECT 	 @OrigTotalRows = (select iif(max(ID)>50000000, 30000000,max(ID)) IDD from #temptable)

--	SELECT @OrigTotalRows

--	Set @OrigPageNum = 3;

---- pagination load id
--while @OrigTotalRows > @OrigPageSize* @OrigPageNum
--begin
--	set @query='select 
--		 c1.ID
--		 ,c1.UF_UPDATED_AT
--		 from  carmoney_light_crm   c1	
--		 where c1.ID >=' + cast(@OrigPageSize* @OrigPageNum as varchar) +' and c1.ID <=' + cast(((@OrigPageSize* (@OrigPageNum+1))-1) as varchar) 

--		Set @OrigPageNum = @OrigPageNum+1;

--		--SELECT @query

--		SELECT cast(@OrigPageSize* @OrigPageNum as varchar)

--		exec( 'INSERT INTO staging.lcrm_tbl_id with(tablockx) select *  from OPENQUERY(LCRM,'''+ @query + ''')')
--end


truncate table staging.lcrm_tbl_id_update
     
declare @ii bigint=0
      , @prev_i bigint =-1
	  --, @query nvarchar(max)=N''
	  ,@tsql  nvarchar(max)=N''

declare @dt datetime

set @dt=dateadd(day,-2,cast(getdate() as date))

select @ii

while @ii<>@prev_i
begin
begin try
set @prev_i=@ii
       begin tran
    set @query='select 
     c1.ID  
    ,c1.UF_UPDATED_AT 
     from  carmoney_light_crm   c1
     join     (select id from carmoney_light_crm   c2
       where 
        c2.id> '''''+format(@ii,'0')+'''''                
		   and c2.UF_UPDATED_AT>'''''+format(@dt,'yyyy-MM-ddTHH:mm:ss')+'''''
order by c2.id
limit 1000000
) c2 
 on c2.id=c1.id' 

set @tsql='INSERT INTO staging.lcrm_tbl_id_update with(tablockx)  select *  from OPENQUERY(LCRM,'''+@query+''')'


exec (@tsql)
/*
 
*/
set @ii=cast(isnull((select max(id) from [staging].[lcrm_tbl_id_update]),'0') as bigint)

select @ii, getdate()

commit tran


end try
begin catch
select 'catch error!'
if @@TRANCOUNT>0 commit tran
set @prev_i=-1
end catch

end

-- теперь обновим за два дня
begin tran
		DELETE FROM [dwh_new].[staging].[lcrm_tbl_id]
		where  id in
					(
						SELECT id
						FROM [staging].[lcrm_tbl_id_update]
					)

	-- добавим недостающие или обновленные данные
	INSERT INTO [dwh_new].[staging].[lcrm_tbl_id] with(tablockx)  
		 select 
		 c1.ID
		,c1.UF_UPDATED_AT
		 from  [staging].[lcrm_tbl_id_update]  c1

commit tran
-- конец



if OBJECT_ID('tempdb.dbo.#tt') is not null
drop table dbo.#tt;


-- найдем все строки, которых нет в оригинале или
-- + Загрузим все, где даты не верны
WITH TMP AS 
( 
	SELECT ordernum.id as ID, ROW_NUMBER() over(order by id) as num1
	FROM
	(
							SELECT distinct idd.id
							FROM [staging].[lcrm_tbl_id] idd
							left join
							[dwh_new].[staging].[lcrm_tbl_full] qd
							on idd.id = qd.ID 
							where qd.ID is null and idd.id is not null 

							UNION

							SELECT  distinct idd.id
							FROM [staging].[lcrm_tbl_id] idd
							inner join
							[dwh_new].[staging].[lcrm_tbl_full] qd
							on idd.id = qd.ID and idd.UF_UPDATED_AT <> qd.UF_UPDATED_AT
							where qd.ID is not null and idd.id is not null 
	) ordernum
) 


SELECT *
 into #tt
 FROM TMP
 order by num1

--select * from #tt order by num1
--select * from [dwh_new].[staging].[lcrm_tbl_full]  where id in (select id from #tt)

--DECLARE @Names VARCHAR(8000),
--        @query varchar(5000),
--		-- вызвано ограничением текста sql запроса
--		@PageSize INT = 400, 
--		@PageNum  INT = 0,
--		@TotalRows INT = 201,
--		@OrigPageSize INT = 2000000, 
--		@OrigPageNum  INT = 0,
--		@OrigTotalRows INT = 10000000;

select @TotalRows = (select max(num1) from #tt)

--SELECT @TotalRows

 if @TotalRows is null
	 begin
	 SET @TotalRows = 0
	 end 

-- 25.11.2019 изменения кода, так как появились новые поля в LCRM
-- создаем таблицу по последним 1000 данным LCRM
if OBJECT_ID('[staging].[lcrm_tbl_update]') is not null
drop table [staging].[lcrm_tbl_update];

set @query='select *
		from  carmoney_light_crm   c1	
		order by id desc
		limit 1000'

	--exec( 'select *  from OPENQUERY(LCRM,'''+ @query + ''')');
exec( 'select * INTO [staging].[lcrm_tbl_update] from OPENQUERY(LCRM,'''+ @query + ''')');

-- очистим  таблицу куда будем ложить отсутсвующие данные и данные для обновления
TRUNCATE TABLE [staging].[lcrm_tbl_update];  

if @TotalRows<2000000 and @TotalRows>0
begin

	-- pagination
	while @TotalRows > @PageSize* @PageNum
	begin
    
		set @Names= null

		-- идем по идентдификаторам
		SELECT @Names = COALESCE(@Names + ', ', '') + cast(ID as varchar(10))
		FROM #tt
		WHERE ID IS NOT NULL  and num1>=@PageSize* @PageNum and num1<=((@PageSize* (@PageNum+1))-1)

		--select @PageNum, @PageSize* @PageNum, ((@PageSize* (@PageNum+1))-1)

		set @query='select *
			 from  carmoney_light_crm   c1	
			 where c1.ID in(' + @Names + ')'

		Set @PageNum = @PageNum+1;
			--select @PageNum, @query
			exec( 'INSERT INTO [staging].[lcrm_tbl_update] with(tablockx) select *  from OPENQUERY(LCRM,'''+ @query + ''')');
	
		end

end;
else
begin
	
	if @TotalRows=0
		SELECT 0;
	else 
		SELECT -1;
		--SELECT N'Ошибка: слишком много строк для обновления';
end;


-- ************************************
-- подготовим список id для удаления
-- ************************************
 -- Найдем количество строк для удаления и последующего добаления
 -- Запишем результат в таблицу обновлений
 DECLARE @RowToUpdate INT,
		 @strcount varchar(1024);
 SELECT @RowToUpdate = (SELECT count(*) FROM [staging].[lcrm_tbl_update])

 if @RowToUpdate is null
	 begin
	 SET @strcount = 'LCRM Data Quality udpate count: 0'
	 SET @RowToUpdate = 0
	 end 
 else
	 begin
	  SET @strcount = 'LCRM Data Quality udpate count: 0' + cast(@RowToUpdate as varchar)
	 end

  
 --SELECT @RowToUpdate

exec [log].[LogAndSendMailToAdmin] 'LCRM Data Quality','Info','procedure calculated row to update', @strcount


 -- начнем транзакцию
 begin tran
  
  -- удалим строки, у которых не совпадает дата обновления
if @RowToUpdate<2000000 
	begin
		DELETE FROM [dwh_new].[staging].[lcrm_tbl_full]
		where  id in
					(
						SELECT id
						FROM [staging].[lcrm_tbl_update]
					)

	-- добавим недостающие или обновленные данные
	INSERT INTO [dwh_new].[staging].[lcrm_tbl_full] with(tablockx)  
		 select 
		 c1.ID
		,c1.UF_NAME
		,c1.UF_PHONE
		,c1.UF_FROM_SITE
		,c1.UF_VIEWED
		,c1.UF_STATUS_S1
		,c1.UF_STATUS_S2
		,c1.UF_REGISTERED_AT
		,c1.UF_UPDATED_AT
		,c1.UF_ISSUED_AT
		,c1.UF_ROW_ID
		,NULL as UF_LEAD_ID -- c1.UF_LEAD_ID
		,c1.UF_SUM_LOAN
		,c1.UF_SUM_ACCEPTED
		,c1.UF_REJECTED_COMMENT
		,c1.UF_REGION_NAME
		,c1.UF_AGENT_NAME
		,c1.UF_AGENT_TYPE
		,c1.UF_DOC_CITY
		,c1.UF_REGION_REF_ID
		,c1.UF_LOAN_MONTH_COUNT
		,c1.UF_STAT_SOURCE
		,c1.UF_STAT_AD_TYPE
		,c1.UF_STAT_CAMPAIGN
		,c1.UF_STAT_DETAIL_INFO
		,c1.UF_STAT_TERM
		,c1.UF_STAT_SYSTEM
		,c1.UF_STAT_FIRST_PAGE
		,c1.UF_STAT_INT_PAGE
		,c1.UF_STAT_CLIENT_ID_YA
		,c1.UF_STAT_CLIENT_ID_GA
		,c1.UF_TYPE
		,c1.UF_MANAGER_TAXI
		,NULL as  UF_CC_OPERATOR_ID --c1.UF_CC_OPERATOR_ID
		,NULL as  UF_CC_STATUS --c1.UF_CC_STATUS
		,c1.UF_SOURCE
		,c1.UF_STAT_CLICK_ID_YA
		,c1.UF_STAT_CLICK_ID_GA
		,c1.UF_STAT_REFERRER
		,NULL as  UF_CC_DEFERRED_TO --c1.UF_CC_DEFERRED_TO
		,NULL as UF_CC_CANCEL_ID  --c1.UF_CC_CANCEL_ID
		,NULL as  UF_CC_TYPE_ID --c1.UF_CC_TYPE_ID
		,NULL as  UF_CC_SOURCE_ID --c1.UF_CC_SOURCE_ID
		,NULL as  UF_CC_DEFER_COUNT --c1.UF_CC_DEFER_COUNT
		,NULL as  UF_CC_COMMENT --c1.UF_CC_COMMENT
		,NULL as  UF_STATUS_DEB --c1.UF_STATUS_DEB
		,c1.UF_ACTUALIZE_AT
		,NULL as UF_LOAN_STATUS --c1.UF_LOAN_STATUS
		,NULL as UF_REASON_FOR_CANCEL --c1.UF_REASON_FOR_CANCEL
		,c1.UF_CLT_ORG_NAME
		,c1.UF_CLT_JOB
		,c1.UF_CLT_PASS_CITY
		,c1.UF_CLT_BIRTH_DAY
		,c1.UF_CLT_MARITAL_STATE
		,c1.UF_CLT_PASS_ID
		,c1.UF_CLT_AVG_INCOME
		,c1.UF_CLT_FIO
		,c1.UF_CLT_EMAIL
		,c1.UF_CAR_ISSUE_YEAR
		,c1.UF_CAR_MARK
		,c1.UF_CAR_MODEL
		,c1.UF_CAR_COST_RUB
		,c1.UF_PHONE_ADD
		,c1.UF_REGION_FROM_TITLE
		,c1.UF_COMMENT
		,c1.UF_PRODUCT
		,c1.UF_PARTNER_OFFICE
		,c1.UF_COMAGIC_ID
		,c1.UF_COMAGIC_PHONE_VRT
		,NULL as UF_CC_COMPLAINT_ID --c1.UF_CC_COMPLAINT_ID
		,c1.UF_PARENT_ID
		,c1.UF_COMAGIC_CAMP_ID
		, NULL as UF_CC_API_ERROR_TEXT --c1.UF_CC_API_ERROR_TEXT
		,c1.UF_CLT_NAME_FIRST
		,c1.UF_CLT_NAME_SECOND
		,c1.UF_CLT_NAME_LAST
		,c1.UF_CLB_CHANNEL
		,c1.UF_CLB_TYPE
		,NULL as UF_DOUBLICATE --c1.UF_DOUBLICATE
		,c1.UF_REPEAT_CUSTOMER
		,NULL as UF_PAUSED --c1.UF_PAUSED
		,c1.UF_LOAN_CREDIT_TYPE
		,c1.UF_PARTNER_ID
		,c1.UF_GROUP_ID
		,c1.UF_PRIORITY
		,c1.UF_COMAGIC_REGION
		,NULL as UF_RARUS_ID --c1.UF_RARUS_ID
		,NULL  as UF_RC_CALL_TYPE --c1.UF_RC_CALL_TYPE
		,NULL as UF_RC_CALL_SOURCE --c1.UF_RC_CALL_SOURCE
		,NULL as UF_RC_CALL_SERVICE --c1.UF_RC_CALL_SERVICE
		,NULL as UF_RC_CALL_RESULT --c1.UF_RC_CALL_RESULT
		,c1.UF_RC_REJECT_CLIENT
		,c1.UF_RC_REJECT_CM
		,c1.UF_REGIONS_COMPOSITE
		,c1.UF_CLT_FIRST_VISIT
		,c1.UF_STAT_CID_YA_INH
		,c1.UF_STAT_CID_GA_INH
		,NULL as UF_USER_IP --c1.UF_USER_IP
		,c1.UF_TYPE_SHADOW
		,c1.UF_SOURCE_SHADOW
		,c1.UF_CLIENT_ID
		,c1.UF_COMAGIC_DURATION
		,c1.UF_SIM_REGION
		, NULL as UF_SIM_OPERATOR --c1.UF_SIM_OPERATOR
		,c1.UF_MFO_CREATED_IN
		,c1.UF_MFO_CREATED_IN_SH
		,c1.UF_DOC_CITY_NORM
		,c1.UF_MATCH_ALGORITHM
		,NULL as UF_RO_CITY_COMPOSITE --c1.UF_RO_CITY_COMPOSITE
		,c1.UF_VISITOR_ID
		,c1.UF_COMAGIC_VID
		,c1.UF_IS_DUPLICATE
		,NULL as UF_RATE_PERCENT --c1.UF_RATE_PERCENT
		,NULL as UF_RATE_MAX_PERCENT --c1.UF_RATE_MAX_PERCENT
		,c1.UF_RATE_MIN_PERCENT
		,NULL as UF_RATE_MAX_MNT_CNT --c1.UF_RATE_MAX_MNT_CNT
		,c1.UF_TARIFF_OR_PRODUCT
		,c1.UF_LOAN_PAID_AT
		,NULL as UF_LOAN_METHOD --c1.UF_LOAN_METHOD
		,c1.UF_PARTNER_CLICK_ID
		,c1.UF_TARGET
		,c1.UF_OUTGOING_TYPE
		,c1.UF_BUSINESS_VALUE
		,c1.UF_DEFERRED
		,c1.UF_STEP
		,c1.UF_CLID
		,c1.UF_ADRIVER_POST_VIEW
		,c1.UF_APPMECA_TRACKER
		,c1.UF_CRM_LAST_STATUS
		 from  [staging].[lcrm_tbl_update]  c1


  	end;
  commit
 -- select 0;  

  if @RowToUpdate<3000000 
	begin
		exec [log].[LogAndSendMailToAdmin] 'LCRM Data Quality','Info','procedure finished','LCRM Data Quality process finished.'
		select 0;
	end
   else
	begin
		exec [log].[LogAndSendMailToAdmin] 'LCRM Data Quality','Info','procedure canceled','LCRM Data Quality process update canceled (more 3 000 000 rows).'
		select -1;
	end

end






