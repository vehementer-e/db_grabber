-- =============================================
-- Author:		
-- Create date: 2020-01-29
-- Description:	
--             exec [dbo].[report_SummaryCheckListFedorTLS]   '2020-01-24T00:00:00', '2020-01-25T00:00:00', 1
-- =============================================
-- Modified: 11.03.2022. А.Никитин
-- Description:	DWH-1590. Отказ от lcrm_tbl_short_w_channel
-- =============================================
CREATE PROCEDURE [dbo].[report_SummaryCheckListFedorTLS]
	-- Add the parameters for the stored procedure here
	--declare
	@DateReportBegin datetime,
	@DateReportEnd datetime,
	@isSummary bit
	--,
	--@NaumenLoginReport varchar(24)
	--@PageNo int 

	
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



  declare @params nvarchar(1024)=''
		,@isSendmail int = 0
  set @params='DateReportBegin='+format(@DateReportBegin,'yyyyMMdd hh:mm:ss')+char(10)+char(13)
             +'DateReportEnd  ='+format(@DateReportEnd  ,'yyyyMMdd hh:mm:ss')+char(10)+char(13)
             +'isSummary      ='+format(cast(@isSummary as int)      ,'0'                )+char(10)+char(13)


	if @isSendmail=1
	begin
	exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','procedure started',@params
	end
  
	declare @GetFilterBeginDate datetime,
			@GetFilterEndDate datetime,
			@GetFilterNaumenLogin varchar(24)


	--set @GetFilterNaumenLogin  = '%';
	--if (@NaumenLoginReport is not null) 
	--begin 
	--	set @GetFilterNaumenLogin = @NaumenLoginReport
	--end 

	set @GetFilterBeginDate  = cast(dateadd(day,0,getdate()) as date);
	if (@DateReportBegin is not null) 
	begin 
		set @GetFilterBeginDate = dateadd(year,0, @DateReportBegin)
	end 


	set @GetFilterEndDate  = cast(dateadd(day,1,getdate()) as date);
	if (@DateReportEnd is not null) 
	begin 
		set @GetFilterEndDate = dateadd(year,0, @DateReportEnd)
	end 

 set @params='GetFilterBeginDate='+format(@GetFilterBeginDate,'yyyyMMdd hh:mm:ss')+char(10)+char(13)
             +'GetFilterEndDate  ='+format(@GetFilterEndDate  ,'yyyyMMdd hh:mm:ss')+char(10)+char(13)
             
if @isSendmail=1
begin
	
	
	exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','parameter for query^',@params
    exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','starting trasnser from  fedor','[PRODSQL02].[Fedor.Core].[core].[Lead]'
end

drop table if exists #l
select * into #l from [PRODSQL02].[Fedor.Core].[core].[Lead] l where l.CreatedOn between @GetFilterBeginDate and @GetFilterEndDate

if @isSendmail=1
begin
 exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','finishing trasnser from  fedor','[PRODSQL02].[Fedor.Core].[core].[Lead]'

 exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','starting trasnser from  fedor','[PRODSQL02].[Fedor.Core].[core].[LeadCommunication]'
end

drop table if exists #lc
 select lc.* into #lc from [PRODSQL02].[Fedor.Core].[core].[LeadCommunication] lc
 --join [PRODSQL02].[Fedor.Core].[core].[Lead] l
	join #l l
	on lc.idlead=l.id
  where l.CreatedOn between @GetFilterBeginDate and @GetFilterEndDate

if @isSendmail=1
begin
exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','finish trasnser from  fedor','[PRODSQL02].[Fedor.Core].[core].[LeadCommunication]'
end
-- запрос по чек листку


--with j as (
--SELECT idLead,[key] вопрос
--,[value] ответ
--  FROM [PRODSQL02].[Fedor.Core].[core].[LeadAndSurvey]
--   outer apply  OPENJSON([SurveyData], '$')
--   where isJSON([SurveyData])=1
--)

if @isSendmail=1
begin
exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','start creting #leadTmp','#leadTmp'
end

drop table if exists #LeadTmp


select * 
into #LeadTmp
from
(
	select top 1000000  
	try_cast(l.IdExternal as numeric(10,0)) LCMR_ID
	, l.LeadChannel
	, l.Phone
	, l.CreatedOn
	, lc.CommunicationEnd  as Конец
	--, 	FIRST_VALUE(lc.CommunicationEnd) over(partition by l.id order by lc.CommunicationEnd desc) as Конец,
	, lc.IdLeadCommunicationResult as КонечныйРезультат
	--FIRST_VALUE(lc.IdLeadCommunicationResult) over(partition by l.id order by lc.CommunicationEnd desc) as КонечныйРезультат,
	, lc.CreatedOn as Начало
	, FIRST_VALUE(lc.CreatedOn) over(partition by l.id order by lc.CreatedOn asc) as ПерваяКоммуникация	
	, lc.IdLeadRejectReason as КонечнаяПричинаЗабраковкиДумает
	--FIRST_VALUE(lc.IdLeadRejectReason) over(partition by l.id order by lc.CommunicationEnd desc) as КонечнаяПричинаЗабраковкиДумает,
	, u.NaumenLogin  as КонечныйОператор
	--FIRST_VALUE(lc.idOwner) over(partition by l.id order by lc.CommunicationEnd desc) as КонечныйОператор,
	
	--rn= row_number() over(partition by l.id order by lc.CommunicationEnd desc, lc.CreatedOn asc)
	, row_number() over(partition by l.id order by lc.CreatedOn asc) as 'НомерПопыткиДозвона'
	, row_number() over(partition by l.id order by lc.CommunicationEnd desc) as 'ПоискПоследнейКоммуникации'
	, lcr.Name 'Результат звонка'
	--, lc.IdLeadCommunicationResult
	, lrr.name 'ПричинаОтказа'
	, l.id
	, l.idStatus
	--, iif(lcr.Name=N'Заявка оформлена',cr.Number, NULL) 'Номер заявки'
	, cr.Number 'Номер заявки'
	, lc.comment 
	--j.вопрос  Question,
	--ответ     Answer, 
	--0
	from  #l l
	left join #lc lc
	on lc.idlead=l.id
	left join  [PRODSQL02].[Fedor.Core].[dictionary].[LeadCommunicationResult] lcr -- результат звонка по коммуникации может быть разный
	on lcr.id=lc.IdLeadCommunicationResult
	left join  [PRODSQL02].[Fedor.Core].[dictionary].[LeadRejectReason] lrr
	on lrr.id=lc.IdLeadRejectReason
	left join prodsql02.[Fedor.Core].[core].clientrequest cr
	on cr.idlead=l.id
	left join  [PRODSQL02].[Fedor.Core].[core].[user] u
	on lc.idOwner  = u.id
	--left join j 
	--on j.idlead=l.id
--	where l.CreatedOn between @GetFilterBeginDate and @GetFilterEndDate -- '2020-01-26T00:00:00' and '2020-01-26T12:00:00' -- >='2020-01-27T12:00:00'
) d
--where d.rn=1
--d.[Номер заявки] = '20012700008734'

--select * from  #LeadTmp lt

if @isSendmail=1
begin
	exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','finish creting #leadTmp','#leadTmp'

	exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','start creating #LeadAnswer','#LeadAnswer'
end

drop table if exists #LeadAnswer


select la.* 
into #LeadAnswer
from [Feodor].[dbo].[dm_LeadAndSurvey] la
where la.[ID лида Fedor] in (select distinct id from #LeadTmp )

--select * from #LeadAnswer
--into #LeadTmp


drop table if exists #t_ЦельЗаймаСправочник
select *  
into #t_ЦельЗаймаСправочник
from [PRODSQL02].[Fedor.Core].[dictionary].[LoanPurpose] 

create index ix_Question on #LeadAnswer(Question) include([ID лида Fedor], answer) 

create clustered index ix_id on #LeadTmp(id)

drop table if exists #CheckList

select  LCMR_ID as 'ЛИД'
, LeadChannel as 'Канал верхнеуровневый'
, Phone as '№ телефона'
--, CreatedOn as 'Дата и время поступления Лида'
, LCRM.UF_REGISTERED_AT as 'Дата и время поступления Лида'
, isnull(dateadd(hour,3,Начало),NULL) as 'Дата и время принятия Лида'
, isnull(dateadd(hour,3,Конец),NULL) as 'Дата и время завершения работы и Лидом'
--, lt.idStatus
--, lcr.Name 'Результат звонка'
--, [Результат звонка]
, las1.Answer as 'Как к Вам обращаться?' --'Имя'
, las2.Answer as 'Какая сумма нужна?'  --'Сумма кредита'
, las3.Answer as 'Как срочно нужна сумма' --'Как срочно?'
, las4.Answer as  'Вы являетесь собственником авто?' --'Есть ли у вас в собственности автомобиль?'
, las5.Answer as  'Как давно вы пользуетесь этим авто?'  --'Как давно вы пользуетесь этим авто'
, las6.Answer as  'На основании чего вы используете авто?'  --'На основании чего вы используете авто?'
--, las7.Answer as  ' '  --'Готов ли собственник авто'
--, las8.Answer as  ' '  --'Переоформит авто на себя'
, isnull(las7.Answer,'') + isnull(las8.Answer,'') as  'Готов ли собственник авто в случае положительного решения переоформить авто на Вас?'  --'Переоформит авто на себя'
, las9.Answer as  'Состояние авто'  --'авто на ходу или нет?'
, las10.Answer as  'Авто зарегистрировано на юр. лицо'  --'уточните правовую форму Вашей организации?'
, iif(len(las11.Answer)>2, Left(right(las11.Answer, charindex('":"', reverse(las11.Answer))), len(right(las11.Answer, charindex('":"', reverse(las11.Answer)))) -1), NULL) as  'Марка'  --'Марка'
, iif(len(las12.Answer)>2, Left(right(las12.Answer, charindex('":"', reverse(las12.Answer))), len(right(las12.Answer, charindex('":"', reverse(las12.Answer)))) -1), NULL)  as  'Модель'  --'Модель'
, las13.Answer as  'Год выпуска'  --'Год выпуска'
, las14.Answer as  'Авто в залоге?'  --'Авто в залоге?'
, las15.Answer as  'Наличие ПТС'  --'ПТС на руках?'
, las16.Answer as  'ПТС оригинал'  --'у Вас ПТС оригинал без отметок или дубликат?'
, '-' [Дубликат взамен утраченного менее 45 дней]
, '-' [Дубликат взамен утраченного 46 дней и более]
, '-' [Дубликат взамен утилизированного]
, iif(len(las17.Answer)>2, Left(right(las17.Answer, charindex('":"', reverse(las17.Answer))), len(right(las17.Answer, charindex('":"', reverse(las17.Answer)))) -1), NULL)  as  'Город регистрации'  --'В каком городе Вы прописаны?'
, iif(len(las18.Answer)>2, Left(right(las18.Answer, charindex('":"', reverse(las18.Answer))), len(right(las18.Answer, charindex('":"', reverse(las18.Answer)))) -1), NULL)  as  'Регион обращения'  --'В каком городе Вы проживаете?'
--, las19.Answer as 'Цель займа'
, ЦельЗаймаСправочник.Name as 'Цель займа'
, las20.Answer as 'Полных лет'
, [Номер заявки] as 'Созданная заявка'
--, lt.КонечныйРезультат 'Результат'
 , iif([Результат звонка] is null, 'нет','Да') 'Результат присвоен корректно?'
, [Результат звонка] 'Результат'
, lt.ПричинаОтказа 'Причина забраковки/отказа/думает'
, lt.comment 'Комментарий (к причине)'
, [КонечныйОператор] 'Оператор'
--, datediff(second, [UF_REGISTERED_AT], ПерваяКоммуникация) 'Скорость обработки лида'
, iif( LCRM.UF_REGISTERED_AT is null or ПерваяКоммуникация is null, null, (3*3600)+(datediff(second, LCRM.UF_REGISTERED_AT, ПерваяКоммуникация))) 'Скорость обработки лида'
, НомерПопыткиДозвона '№ попытки дозвона'
, ПоискПоследнейКоммуникации
--,*
into #CheckList
from #LeadTmp lt
--left join  [PRODSQL02].[Fedor.Core].[dictionary].[LeadCommunicationResult] lcr -- результат звонка по коммуникации может быть разный
--on lcr.id=lt.КонечныйРезультат
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Имя') las1
on  las1.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Сумма кредита') las2
on  las2.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Как срочно?') las3
on  las3.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Есть ли у вас в собственности автомобиль?') las4
on  las4.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Как давно вы пользуетесь этим авто') las5
on  las5.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='На основании чего вы используете авто?') las6
on  las6.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Готов ли собственник авто') las7
on  las7.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Переоформит авто на себя') las8
on  las8.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='авто на ходу или нет?') las9
on  las9.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='уточните правовую форму Вашей организации?') las10
on  las10.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Марка') las11
on  las11.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Модель') las12
on  las12.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Год выпуска') las13
on  las13.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Авто в залоге?') las14
on  las14.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='ПТС на руках?') las15
on  las15.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='у Вас ПТС оригинал без отметок или дубликат?') las16
on  las16.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='В каком городе Вы прописаны?') las17
on  las17.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='В каком городе Вы проживаете?') las18
on  las18.[ID лида Fedor]= lt.id
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer   where Question ='Цель займа') las19
on  las19.[ID лида Fedor]= lt.id
left join #t_ЦельЗаймаСправочник ЦельЗаймаСправочник on las19.Answer=cast(ЦельЗаймаСправочник.id as nvarchar(12))
left join  (select [ID лида Fedor], question, answer from  #LeadAnswer  where Question ='Сколько Вам полных лет?') las20
on  las20.[ID лида Fedor]= lt.id
--DWH-1590. Отказ от lcrm_tbl_short_w_channel
--left join [Stg].[_LCRM].[lcrm_tbl_short_w_channel] LCRM with(nolock)
left join Stg._LCRM.lcrm_leads_full_calculated AS LCRM with(nolock)
on LCRM.id = LCMR_ID
--where [Номер заявки] is not null --= '20012700008734'
--where ПоискПоследнейКоммуникации = 1
order by lt.id --, НомерПопыткиДозвона

if @isSendmail=1
begin
exec logdb.dbo.[LogAndSendMailToAdmin] 'reports.[dbo].[report_SummaryCheckListFedorTLS]','Info','finish creating #LeadAnswer','#LeadAnswer'
end

if (@isSummary = 1)
begin
	select --top 100 
	* from #CheckList where ПоискПоследнейКоммуникации = 1
end
else
begin
	select  --top 100  
	* from #CheckList
end

END

