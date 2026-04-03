-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl update_pos
--
--  exec etl.base_etl_update_pos
-- =============================================
CREATE procedure [etl].[base_etl_update_pos]

as
begin
	/* select count(*) from tmp_v_requests
       select count(*) from v_requests
     */
	SET NOCOUNT ON;
	--log

	declare @sp_name NVARCHAR(128) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID) + '.', '') + OBJECT_NAME(@@PROCID)
	declare @params nvarchar(1024) = ''
	exec logDb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure started'
	,                                      ''
	begin try
	;
	with cte
	as
	(
		select r.Наименование as regional_office
		,      o.Наименование as name
		,      o.Адрес           address
		,      o.Координаты      geo /*into dwh_new.staging.pos*/
		,      t.Имя          as pos_type_new
		,      k.Наименование    new_kind_of_activity
		from      (
		select *
		from [prodsql02].[mfo].[dbo].Справочник_ГП_Офисы
		where Наименование like '%Партнер%'
			or Наименование like '%ВМ%'
		)                                                                      as o
		left join (
			select Ссылка
			,      Наименование
			,      Адрес
			from [prodsql02].[mfo].[dbo].Справочник_ГП_Офисы
			where Наименование like '%РП%'
			)                                                                     r on o.Родитель = r.Ссылка
		left join [prodsql02].[mfo].[dbo].Перечисление_ГП_ТипыОфисов              t on t.Ссылка = o.ТипОфиса
		left join [prodsql02].[mfo].[dbo].Справочник_ВидыДеятельностиПартнеров    k on k.Ссылка = o.ВидДеятельности
	)
	,    pos
	as
	(
		select pos.regional_office   
		,      pos.pos_type          
		,      pos.kind_of_activity  
		,      c.regional_office      as new
		,      c.pos_type_new        
		,      c.new_kind_of_activity
		from points_of_sale pos
		JOIN cte            c   on c.name = pos.name
		where pos.regional_office is null
	)

	update pos
	set regional_office =  new
	,   pos_type =         pos_type_new
	,   kind_of_activity = new_kind_of_activity




 /*   ;
    with cte  as (
    select   r.Наименование as regional_office,  o.Наименование as name, o.Адрес address , 
    o.Координаты geo /*into dwh_new.staging.pos*/, t.Имя as pos_type_new, k.Наименование new_kind_of_activity  from (
    select * from [C1-VSR-SQL05].[MFO_NIGHT01].[dbo].Справочник_ГП_Офисы
    where Наименование like '%Партнер%' or Наименование like '%ВМ%'
    ) as o
    left join (
    select Ссылка, Наименование, Адрес from [C1-VSR-SQL05].[MFO_NIGHT01].[dbo].Справочник_ГП_Офисы
    where Наименование like '%РП%'
    ) r on o.Родитель = r.Ссылка
    left join [C1-VSR-SQL05].[MFO_NIGHT01].[dbo].Перечисление_ГП_ТипыОфисов t on t.Ссылка = o.ТипОфиса
    left join [C1-VSR-SQL05].[MFO_NIGHT01].[dbo].Справочник_ВидыДеятельностиПартнеров k on k.Ссылка = o.ВидДеятельности
), 
pos as (
    select pos.regional_office, pos.pos_type, pos.kind_of_activity, c.regional_office as new , c.pos_type_new, c.new_kind_of_activity  from points_of_sale pos 
    JOIN cte c on c.name = pos.name
    where pos.regional_office is null
)

update pos 
set  regional_office = new , pos_type = pos_type_new , kind_of_activity = new_kind_of_activity
-- set regional_office = new 
*/
	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Info'
	,                                      'procedure finished'
	end try
	begin catch
	declare @error_description nvarchar(4000)=N''
	set @error_description ='ErrorNumber: '+ cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+ cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
	+char(10)+char(13)+' ErrorState: '+ cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
	+char(10)+char(13)+' Error_line: '+ cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')

	exec logdb.dbo.[LogAndSendMailToAdmin] @sp_name
	,                                      'Error'
	,                                      'Error'
	,                                      @error_description
	;throw 51000, @error_description, 1
	end catch
end





