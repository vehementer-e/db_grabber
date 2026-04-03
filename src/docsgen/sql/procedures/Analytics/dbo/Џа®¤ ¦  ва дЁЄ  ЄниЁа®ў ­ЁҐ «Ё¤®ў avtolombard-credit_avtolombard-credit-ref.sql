
CREATE proc [dbo].[Продажа трафика кэширование лидов avtolombard-credit/avtolombard-credit-ref]
as
begin

DROP TABLE IF EXISTS #TMP_leads
CREATE TABLE #TMP_leads
(
	[ID] [numeric](10, 0) NOT NULL,
	[PhoneNumber] [varchar](20) NULL,
	[UF_REGISTERED_AT] [datetime2](7) NULL,
	[UF_SOURCE] [varchar](128) NULL	 ,
	[UF_REGIONS_COMPOSITE] [varchar](128) NULL	 
)

-- 
DECLARE @Return_Table_Name varchar(100)
DECLARE @Return_Number int, @Return_Message varchar(1000)
DECLARE	@Begin_Registered date, @End_Registered date

--название таблицы, которая будет заполнена
SELECT @Return_Table_Name = '#TMP_leads'
SELECT @Begin_Registered = getdate()-5, @End_Registered = getdate()
--SELECT @Begin_Registered = '20230601', @End_Registered = getdate()


EXEC Stg._LCRM.get_leads
	@Debug = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Begin_Registered = @Begin_Registered, -- начальная дата
	@End_Registered = @End_Registered, -- конечная дата
	@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
	@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message = @Return_Message OUTPUT, -- возвращаемое сообщение
    @where ='uf_source in ( ''avtolombard-credit'', ''avtolombard-credit-ref'') '
SELECT @Return_Number, @Return_Message

  -- exec create_table 'stg._lcrm.lcrm_leads_full'


--select *, getdate() crreated into dbo.[Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] from #TMP_leads

begin tran
delete  a from  dbo.[Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref] a
join   #TMP_leads b on a.id=b.id

insert into 	  dbo.[Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref]  
select id, PhoneNumber,[UF_REGISTERED_AT] , uf_source,  getdate() crreated, [UF_REGIONS_COMPOSITE]  from 	  #TMP_leads

 commit tran

--select * from 	    dbo.[Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref]  
--order by 3


--alter table dbo.[Продажа трафика Телефоны avtolombard-credit/avtolombard-credit-ref]  
--add  [UF_REGIONS_COMPOSITE] [varchar](128) NULL	

end