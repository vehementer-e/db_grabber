
CREATE     proc [_gsheets].[load_google_sheet_to_DWH]  @mode nvarchar(max) = '' ,  @wait int = 1
--exec       [_gsheets].[load_google_sheet_to_DWH]  'Кейсы партнеров'
--exec       [_gsheets].[load_google_sheet_to_DWH]  'статус отправки лидов'
as
begin

select 1/0


/*

exec msdb.dbo.sp_update_jobstep @job_name= 'Analytics. ETL. daily at 8:00'
		,  @step_id = 11
		, @command = 'exec  [_gsheets].[load_google_sheet_to_DWH]  ''dic_клики_ПСБ''





exec  [_gsheets].[load_google_sheet_to_DWH]  ''dic_смс_ВТБ''
exec       [_gsheets].[load_google_sheet_to_DWH]  ''Кейсы партнеров''

'

*/
declare @datet___ datetime   =  getdate()  

  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  ----------------------------------------------------------------------- 

if @mode = 'dic_Попытки Naumen'
begin
drop table if exists _gsheets.[dic_Попытки Naumen]
exec exec_python '
df = get_spreadsheet_values("1T9m-qumpLplhd_lyLTZwf_7p3OUjtmecQlKz2vXrgiI", "Лист1!A:H")
insert_into_table(df, "dic_Попытки Naumen", "_gsheets")
'	, @wait
if not exists (select top 1  * from _gsheets.[dic_Попытки Naumen] ) and @wait=1
RAISERROR ('Справочник _gsheets.[dic_Попытки Naumen] пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );
end

  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------

if @mode = 'dic_Проекты NAUMEN'
begin
drop table if exists _gsheets.[dic_Проекты TTC]
exec exec_python '
df = get_spreadsheet_values("1DWDArm6Mw5BeeCxFQ3yCztSLwxCf8FBQWuZ1igkSGLs", "Проекты TTC!A:N")
insert_into_table(df, "dic_Проекты TTC", "_gsheets")
'	, @wait
if not exists (select top 1 * from _gsheets.[dic_Проекты TTC] ) and @wait=1
RAISERROR ('Справочник _gsheets.[dic_Проекты TTC пустой]', -- Message text.
               16, -- Severity.
               1 -- State.
               );
end		  	 


-----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------

if @mode = 'dic_клики_ПСБ'
begin
drop table if exists _gsheets.[dic_клики_ПСБ]
exec exec_python '
df = get_spreadsheet_values("1AhngIGL0HbCuj7nnZs9CA1Ke9MEwr_b6-gX5MLAdF5w", "Онлайн!A3:C180")
insert_into_table(df, "dic_клики_ПСБ", "_gsheets")
'	, @wait
if not exists (select top 1 * from _gsheets.[dic_клики_ПСБ] )and @wait=1
RAISERROR ('Справочник _gsheets.[dic_клики_ПСБ пустой]', -- Message text.
               16, -- Severity.
               1 -- State.
               );
				
end				
				if @mode = 'dic_смс_ВТБ'
begin
drop table if exists _gsheets.[dic_смс_ВТБ]
exec exec_python '
df = get_spreadsheet_values("1AhngIGL0HbCuj7nnZs9CA1Ke9MEwr_b6-gX5MLAdF5w", "СМС_ВТБ!A1:B1180")
insert_into_table(df, "dic_смс_ВТБ", "_gsheets")
'	,  @wait 
if not exists (select top 1 * from _gsheets.[dic_смс_ВТБ] ) and @wait=1
RAISERROR ('Справочник _gsheets.[dic_смс_ВТБ]', -- Message text.
               16, -- Severity.
               1 -- State.
               );

			  

end		  


  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  -----------------------------------------------------------------------
  ----------------------------------------------------------------------


if @mode = 'Продажа трафика'
begin

--declare @datet___ datetime   =  getdate()  

exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Analytics\Стоимость займа\GOOGLESHEETS",
                       name = "Расходы_ CPC + Медийка + Остальное" ,
					   name2 = "Продажа трафика"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[продажа трафика_stg] where created>=@datet___	) and @wait=1 
begin
RAISERROR ('Справочник stg.files.[продажа трафика_stg] не обновился или пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );
			   select 1/0 

			   end

end
	
if @mode = 'Связка номер точки utm метка'
begin

--declare @datet___ datetime   =  getdate()  


exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Партнеры\GOOGLESHEETS",
                       name = "справочники партнеры" ,
					   name2 = "Связка номер точки utm метка"
                       )
'	   , @wait 
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[связка номер точки utm метка_stg] where created>=@datet___	)  and @wait=1 
begin
RAISERROR ('Справочник stg.files.[связка номер точки utm метка_stg] не обновился или пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );
			   select 1/0 

			   end

end

if @mode = 'План продаж партнеры'
begin

--declare @datet___ datetime   =  getdate()  

exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Партнеры\GOOGLESHEETS",
                       name = "справочники партнеры" ,
					   name2 = "План продаж партнеры"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[план продаж партнеры_stg] where created>=@datet___	) and @wait=1 
begin
RAISERROR ('Справочник stg.files.[план продаж партнеры_stg] не обновился или пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );
			   select 1/0 

			   end

end

if @mode = 'ставки кв юрлиц по месяцам'
begin 
--declare @datet___ datetime   =  getdate()   
exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Analytics\Стоимость займа\GOOGLESHEETS",
                       name = "справочники партнеры" ,
					   name2 = "ставки кв юрлиц по месяцам"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[ставки кв юрлиц по месяцам_stg] where created>=@datet___	)  and @wait=1 
begin RAISERROR ('Справочник stg.files.[ставки кв юрлиц по месяцам_stg] не обновился или пустой',  16,   1    ); select 1/0   end
 end

 if @mode = 'Партнеры расходы на оформление'
begin 
--declare @datet___ datetime   =  getdate()   
exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Analytics\Стоимость займа\GOOGLESHEETS",
                       name = "справочники партнеры" ,
					   name2 = "Партнеры расходы на оформление"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[партнеры расходы на оформление_stg] where created>=@datet___	)  and @wait=1 
begin RAISERROR ('Справочник stg.files.[партнеры расходы на оформление_stg] не обновился или пустой',  16,   1    ); select 1/0   end
 end
 if @mode = 'Партнеры расходы на привлечение'
begin 
--declare @datet___ datetime   =  getdate()   
exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Analytics\Стоимость займа\GOOGLESHEETS",
                       name = "справочники партнеры" ,
					   name2 = "Партнеры расходы на привлечение"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[партнеры расходы на привлечение_stg] where created>=@datet___	)  and @wait=1 
begin RAISERROR ('Справочник stg.files.[партнеры расходы на привлечение_stg] не обновился или пустой',  16,   1    ); select 1/0   end
 end
			
	  
if @mode = 'Расходы по кликовым офферам'
begin

--declare @datet___ datetime   =  getdate()  

exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы",
                       dst = r"\\10.196.41.14\DWHFiles\Analytics\Стоимость займа\GOOGLESHEETS",
                       name = "Расходы_ CPC + Медийка + Остальное" ,
					   name2 = "Тарифы контакты_Лидогенераторы CPA"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:30'
if not exists (select top 1 * from stg.files.[Расходы по кликовым офферам_stg] where created>=@datet___	)  and @wait=1 
RAISERROR ('Справочник stg.files.[Расходы по кликовым офферам_stg] не обновился или пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );

end
			


if @mode = 'Расходы по месяцам'
begin

--declare @datet___ datetime   =  getdate()  

exec exec_python 'update_marketing_costs()'	   , @wait
if  @wait=1 

waitfor delay '00:03:00'
if not exists (select top 100 * from stg.files.[Расходы по месяцам_stg] where created>=@datet___	)  and @wait=1 
RAISERROR ('Справочник stg.files.[Расходы по месяцам_stg] не обновился или пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );

end


if @mode = 'Расторжения КП'
begin

--declare @datet___ datetime   =  getdate()  

exec exec_python '
DRIVE_to_DWH_FILES(src = r"G:\Мой диск",
                       dst = r"\\10.196.41.14\DWHFiles\CP\GOOGLESHEETS",
                       name = "refuses_CP" ,
					   name2 = "refuses_CP_GOOGLESHEETS"
                       )
'	   , @wait
if  @wait=1 

waitfor delay '00:03:00'
if not exists (select top 1 * from stg.files.[refuses_CP_GOOGLESHEETS_stg] where created>=@datet___	)  and @wait=1 
RAISERROR ('Справочник stg.files.[refuses_CP_GOOGLESHEETS_stg] не обновился или пустой', -- Message text.
               16, -- Severity.
               1 -- State.
               );

end


if @mode = 'Кейсы партнеров'
begin

--declare @datet___ datetime   =  getdate()  

drop table if exists _gsheets.[dic_Кейсы_партнеров]
exec exec_python '
df = get_spreadsheet_values("17GR6cF0nTzK7VK9uIpQHldtAphUWz2287qDZe4ZJ-MQ", "Лист1!A:C")
insert_into_table(df, "dic_Кейсы_партнеров", "_gsheets")
'	, @wait 

if not exists (select top 1 * from _gsheets.[dic_Кейсы_партнеров] )  and @wait=1 
RAISERROR ('Справочник _gsheets.[dic_Кейсы_партнеров]', -- Message text.
               16, -- Severity.
               1 -- State.
               );



end			

if @mode = 'costs_sms'
begin

--declare @datet___ datetime   =  getdate()  

drop table if exists _gsheets.[dic_costs_sms]
exec exec_python '
df = get_spreadsheet_values("1BYM_J4tJLjiSBpvydcvBLZI1sMk-HA4KR3w_fvqQgBs", "справочник расходы на смс!A:C")
insert_into_table(df, "dic_costs_sms", "_gsheets")
'	, @wait
if not exists (select top 1 * from _gsheets.[dic_costs_sms] )  and @wait=1 
RAISERROR ('Справочник _gsheets.[dic_Кейсы_партнеров]', -- Message text.
               16, -- Severity.
               1 -- State.
               );



end			



if @mode ='uniapi to gs'
begin

exec exec_python '
sql_to_gs("""

   select a.id, a.created externalRequestCreated, pb.Api2Accepted , pb.api2Declined , b.linkCreated, b.source, b.created leadCreated,   c.event, c.status_crm ,c.number, c.origin, c.created requestCreated, c.ispts, c.call1

, case when c.ispts=0 then  ''BEZZALOG - >''         end as   BEZZALOG
, case when c.ispts=0 then  c.[_profile] 		   end as [_profile] 		
, case when c.ispts=0 then  c.[_passport] 		   end as [_passport] 		
, case when c.ispts=0 then  c.[_photos] 		   end as [_photos] 		
, case when c.ispts=0 then  c.[_pack1] 			   end as [_pack1] 			
, case when c.ispts=0 then  c.[_call1] 			   end as [_call1] 			
, case when c.ispts=0 then  c.[_workAndIncome] 	   end as [_workAndIncome] 	
, case when c.ispts=0 then  c.[_cardLinked] 	   end as [_cardLinked] 	
, case when c.ispts=0 then  c.[_approvalWaiting]   end as [_approvalWaiting]
, case when c.ispts=0 then  c.[_offerSelection]    end as [_offerSelection] 
, case when c.ispts=0 then  c.[_contractSigning]   end as [_contractSigning]
, case when c.ispts=0 then  c.[_calculatorPts] 	   end as [_calculatorPts] 	
, case when c.ispts=1 then ''PTS - >''                    end as PTS
, case when c.ispts=1 then 	c.[_calculatorPts]		   end as [_calculatorPts]
, case when c.ispts=1 then   c.[_profilePts] 		   end as [_profilePts] 		  
, case when c.ispts=1 then   c.[_docPhotoPts] 		   end as [_docPhotoPts] 		  
, case when c.ispts=1 then   c.[_docPhotoLoadedPts] 	   end as [_docPhotoLoadedPts] 	  
, case when c.ispts=1 then   c.[_pack1Pts] 			   end as [_pack1Pts] 			  
, case when c.ispts=1 then   c.[_pack1SignedPts] 	   end as [_pack1SignedPts] 	  
, case when c.ispts=1 then   c.[_clientAndDocPhoto2Pts] end as [_clientAndDocPhoto2Pts]
, case when c.ispts=1 then   c.[_additionalInfoPTS] 	   end as [_additionalInfoPTS] 	  
, case when c.ispts=1 then   c.[_carDocPhotoPTS] 	   end as [_carDocPhotoPTS] 	  
, case when c.ispts=1 then   c.[_issueMethodPts] 	   end as [_issueMethodPts] 	  
, case when c.ispts=1 then   c.[_cardLinkedPTS] 		   end as [_cardLinkedPTS] 		  
, case when c.ispts=1 then   c.[_carPhotoPTS] 		   end as [_carPhotoPTS] 		  
, case when c.ispts=1 then   c.[_fullRequestPTS] 	   end as [_fullRequestPTS] 	  
, case when c.ispts=1 then   c.[_approvalPTS] 		   end as [_approvalPTS] 		  
, case when c.ispts=1 then   c.[_pack2PTS] 			   end as [_pack2PTS] 			  
, case when c.ispts=1 then   c.[_pack2SignedPTS] 	   end as [_pack2SignedPTS] 	  




from v_request_external a
left join v_Postback pb on pb.lead_id = a.id and isApi2=1
join v_lead2 b on a.id=b.id
left join _request c on c. leadid=a.id 
where b.entrypoint=''UNI_API'' and a.created >= cast( getdate()-10  as date) 
order by 2 desc


            """, "1QRFy6YVLB1iZpJV205Bg8k4bXax0B6btVHGg_Hjt9yQ", sheet_name="UNIAPI_20241023150852")#,  make_sheet="UNIAPI")
			'			  , @wait



end
if @mode ='кейсы партнеров to gs'
begin

exec exec_python '
sql_to_gs("""

        select b.Номер, a.office, a.channel, b.TransitionsJSON, b.[Номер партнера CRM],b.[Номер партнера], b.[Exceptions info], b.[Канал от источника лид] , b.[Канал от источника], b.[Источник] from v_request_manual_validation a
    join v_FA b on a.number=b.Номер
    order by 1 

            """, "17GR6cF0nTzK7VK9uIpQHldtAphUWz2287qDZe4ZJ-MQ", "Лист2")
			'			  , @wait



end


if @mode ='статус отправки лидов to gs'
begin

exec exec_python '
sql_to_gs("""

        select Job_Name, job_enabled, created, updated, getdate() ДатаОтчета from jobs
where Job_Name like ''%sell traffic%''
order by job_enabled desc


            """, "1ipc4DwVaWkYpv3grQygFRzDP-hot7tFL1WXcD3Fz3YE", "status")
			'			  , @wait
			
exec exec_python '
sql_to_gs("""

select  кому partner, cast( report_dt  as date) date , count(*) cnt from [v_Проданный трафик]
 
 group by кому, cast( report_dt  as date) 
order by  cast( report_dt  as date)  desc, 1 desc

            """, "1ipc4DwVaWkYpv3grQygFRzDP-hot7tFL1WXcD3Fz3YE", "stat")
			'			  , @wait







end



end

--exec [_gsheets].[load_google_sheet_to_DWH] 'план продаж партнеры'





