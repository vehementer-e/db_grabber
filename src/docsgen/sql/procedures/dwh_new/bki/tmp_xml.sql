



-- =============================================
-- Author:		Orlov A.
-- Create date: 2019-07-03
-- Description:
-- =============================================
CREATE PROCEDURE [bki].[tmp_xml]
-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here

	declare @maxdate datetime
	select @maxdate = dateadd(year,2000,dateadd(dd,-10,cast(current_timestamp as date)))
	drop table if exists #table

	select * into #table
	FROM [Stg].[_1CIntegration].[РегистрСведений_ИсторияЗапросовКредитныхИсторийВБКИ]
	where Период> @maxdate
		and ТипБКИ in( 0xB483EC7E9BD95BDE44D1F61310269EFD,0xA98A74BB2C214DED457D411215EF202C)


	truncate table bki.ntable;
	truncate table bki.xtable;

	insert into bki.ntable
	select *               
	,      case when datediff(dd,request_date,период)<15
		and rn=1 then 1
	             else 0 end flag_correct --into #nTable
	from (
	SELECT dateadd(year,-2000,[Период])                                                                                                                              [Период]
	,      request_date                                                                                                                                          
	,      ROW_NUMBER() over (partition by [ОбъектВыгрузки] order by период)                                                                                      as rn
	,      [ОбъектВыгрузки]                                                                                                                                      
	,      try_cast('<'+replace(substring(ТекстОтвета,charindex('?xml',ТекстОтвета),len(ТекстОтвета)-charindex('?xml',ТекстОтвета)),'?','')+'>'+' </xml>' as xml)    ТекстОтвета
	FROM #table               b
	join dwh_new.dbo.requests r on r.external_id=b.ОбъектВыгрузки
	where 1=1
		and ТипБКИ= 0xB483EC7E9BD95BDE44D1F61310269EFD
		and ТекстОтвета <>''
		and ОбъектВыгрузки<>''
		and '<'+replace(substring(ТекстОтвета,charindex('?xml',ТекстОтвета),len(ТекстОтвета)-charindex('?xml',ТекстОтвета)),'?','')+'>' like '<xml%'
	) a
	where rn<5
		and ТекстОтвета is not null --and request_date>@maxdate
	--go
	--drop table xTable


	--declare @maxdate datetime

	insert into bki.xtable
	select *               
	,      case when datediff(dd,request_date,период)<15
		and rn=1 then 1
	             else 0 end flag_correct
	--into xTable
	from (
	SELECT dateadd(year,-2000,[Период])                                                                                                     [Период]
	,      request_date                                                                                                                 
	,      ROW_NUMBER() over (partition by [ОбъектВыгрузки] order by период)                                                             as rn
	,      [ОбъектВыгрузки]        
	, ('<'+
		replace(
			replace(
			substring(ТекстОтвета,charindex('?xml',ТекстОтвета),len(ТекстОтвета)-charindex('?xml',ТекстОтвета))
			,'?',''), 
			'<xml-stylesheet type="text/xsl" href="/schema/schema_3.4.xsl">', '')
			+'></xml>' )ТекстОтвета
	---,      ('<'+replace(substring(ТекстОтвета,charindex('?xml',ТекстОтвета),len(ТекстОтвета)-charindex('?xml',ТекстОтвета)),'?','')+'>')    ТекстОтвета
	FROM #table               b
	join dwh_new.dbo.requests r on r.external_id=b.ОбъектВыгрузки
	where 1=1
		and ТипБКИ= 0xA98A74BB2C214DED457D411215EF202C
		and nullif(ТекстОтвета,'') is not null
		and nullif(ОбъектВыгрузки, '') is not null
 	) a --where  request_date>@maxdate
	where ТекстОтвета is not null
	and try_cast(ТекстОтвета  as xml) is not null



	delete from bki.ntable
	where [ОбъектВыгрузки] collate Cyrillic_General_CI_AS in (select distinct external_id
		from bki.n_AccountReply )

	delete from bki.xtable
	where [ОбъектВыгрузки] collate Cyrillic_General_CI_AS in (select distinct external_id
		from bki.eqv_credits )
end