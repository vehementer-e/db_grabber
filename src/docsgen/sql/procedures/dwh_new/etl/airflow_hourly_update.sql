-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 26-02-2019
-- Description:	Процедура заполняемт таблицу [dbo].[dash_sales_today] моментальным значением суммы заявок 
-- exec etl.airflow_hourly_update
-- select * from [dbo].[dash_sales_today]
-- =============================================
CREATE PROCEDURE [etl].[airflow_hourly_update]
	
AS
BEGIN
	
	
	SET NOCOUNT ON;
	--log
	exec [log].[LogAndSendMailToAdmin] '[etl].[airflow_hourly_update]','Info','procedure started',''


	declare @value float	

	select @value=sum(Сумма)  from (
    select 
        r.Номер external_id, 
        r.Сумма, 
        Статус, 
        row_number() over (partition by rh.Заявка order by  rh.период desc) rn_reversed
    from [prodsql02].[mfo].[dbo].РегистрСведений_ГП_СписокЗаявок rh
    inner join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] r on rh.Заявка = r.Ссылка
    where rh.период >= dateadd(yy, 2000, cast( CURRENT_TIMESTAMP as date))
    )f 
    where rn_reversed =1  and Статус = 0xA398265179685AF34EED1A6B6349A87B

	--insert into dwh_new_dev
  /*
	truncate table [dbo].[dash_sales_today]

	insert into [dbo].[dash_sales_today] (amount) 
		select @value
    */

  --insert into dwh_new		
 delete from [dwh_new].[dbo].[dash_sales_today]

	insert into [dwh_new].[dbo].[dash_sales_today] (amount) 
		select @value

		--log result
   declare @result nvarchar(100)
   set @result=N'value='		 +format(isnull(@value,0.0),'0')
   exec [log].[LogAndSendMailToAdmin] '[etl].[airflow_hourly_update]','Info','procedure finished',@result
END
