

CREATE PROCEDURE [finAnalytics].[calcRep840FirstLevel_4]
	@repmonth date,
    @repdate date
    
AS
BEGIN

DROP TABLE IF EXISTS #ID_LIST
Create table #ID_LIST(
[ID] [int] NOT NULL)

INSERT INTO #ID_LIST
select id
from finAnalytics.Reserv_NU a
where a.REPMONTH=@repmonth


DROP TABLE IF EXISTS #RESERV
Create table #RESERV(
    [REPMONTH] [date] NOT NULL,
	[dogNum] [nvarchar](20) NOT NULL,
	[isRestrukt] [nvarchar](10) NOT NULL,
	[isRefinance] [nvarchar](10) NOT NULL,
	[isBunkrupt] [nvarchar](10) NOT NULL,
	[clientType] [nvarchar](10) NOT NULL,
	[zaymType] [nvarchar](50) NOT NULL,
	[client] [nvarchar](500) NOT NULL,
	[nomenklGroup] [nvarchar](200) NULL,
	[isAkcia0] [nvarchar](10) NULL,
	[restAll] [float] NULL,
	[restOD] [float] NULL,
	[restPRC] [float] NULL,
	[restPenia] [float] NULL,
	[restGosposhl] [float] NULL,
	[srokDolg] [int] NULL,
	[historicPros] [int] NULL,
	[allPros] [int] NULL,
	[zaymGroup] [nvarchar](200) NULL,
	[untervalName] [nvarchar](300) NULL,
	[reservPRC] [float] NULL,
	[reservSum] [float] NULL,
	[sumOD] [float] NULL,
	[sumPRC] [float] NULL,
	[sumPenia] [float] NULL,
    [PROScategoy] int not null,
    [PSK_prc] float null
)

INSERT INTO #RESERV
select
REPMONTH, dogNum, isRestrukt, isRefinance, isBunkrupt, clientType, zaymType, client, 
nomenklGroup, isAkcia0, restAll, restOD, restPRC, restPenia, restGosposhl, srokDolg, 
historicPros, allPros, zaymGroup, untervalName, reservPRC, reservSum, sumOD, sumPRC, sumPenia,
case when allPros = 0 then 1
     when allPros between 1 and 7 then 2
     when allPros between 8 and 30 then 3
     when allPros between 31 and 60 then 4
     when allPros between 61 and 90 then 5
     when allPros between 91 and 120 then 6
     when allPros between 121 and 180 then 7
     when allPros between 181 and 270 then 8
     when allPros between 271 and 360 then 9
     when allPros >=361 then 10
     end
, a.PSK_prc
from finAnalytics.Reserv_NU a
inner join #ID_LIST b on a.ID=b.ID

BEGIN TRY

delete from finAnalytics.rep840_firstLevel_4
where REPMONTH=@repmonth and REPDATE=@repdate-- and razdel='4'

------------Без просрочки
declare @dataLevel int = 1
declare @prosCategory int = 1
declare @rowNum int = 3
declare @rowName varchar(30) = '4.1.1'
declare @rowPokazatel varchar(500) = '    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @rowNum = 4
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @rowNum = 5
set @rowName='4.1.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @rowNum = 6
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 1-7 дней
set @dataLevel = 1
set @prosCategory = 2
set @rowNum = 9
set @rowName='4.2.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 2
set @rowNum = 10
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 2
set @rowNum = 11
set @rowName='4.2.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 2
set @rowNum = 12
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 8-30 дней
set @dataLevel = 1
set @prosCategory = 3
set @rowNum = 15
set @rowName='4.3.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 3
set @rowNum = 16
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 3
set @rowNum = 17
set @rowName='4.3.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 3
set @rowNum = 18
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 31-60 дней
set @dataLevel = 1
set @prosCategory = 4
set @rowNum = 21
set @rowName='4.4.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 4
set @rowNum = 22
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 4
set @rowNum = 23
set @rowName='4.4.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 4
set @rowNum = 24
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 61-90 дней
set @dataLevel = 1
set @prosCategory = 5
set @rowNum = 27
set @rowName='4.5.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 5
set @rowNum = 28
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 5
set @rowNum = 29
set @rowName='4.5.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 5
set @rowNum = 30
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 91-120 дней
set @dataLevel = 1
set @prosCategory = 6
set @rowNum = 33
set @rowName='4.6.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 6
set @rowNum = 34
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 6
set @rowNum = 35
set @rowName='4.6.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 6
set @rowNum = 36
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 121-180 дней
set @dataLevel = 1
set @prosCategory = 7
set @rowNum = 39
set @rowName='4.7.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 7
set @rowNum = 40
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 7
set @rowNum = 41
set @rowName='4.7.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 7
set @rowNum = 42
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 181-270 дней
set @dataLevel = 1
set @prosCategory = 8
set @rowNum = 45
set @rowName='4.8.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 8
set @rowNum = 46
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 8
set @rowNum = 47
set @rowName='4.8.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 8
set @rowNum = 48
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка 271-360 дней
set @dataLevel = 1
set @prosCategory = 9
set @rowNum = 51
set @rowName='4.9.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 9
set @rowNum = 52
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 9
set @rowNum = 53
set @rowName='4.9.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 9
set @rowNum = 54
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

------------Просрочка более 360 дней
set @dataLevel = 1
set @prosCategory = 10
set @rowNum = 57
set @rowName='4.10.1'
set @rowPokazatel='    по основному долгу'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 2
set @prosCategory = 10
set @rowNum = 58
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 3
set @prosCategory = 10
set @rowNum = 59
set @rowName='4.10.2'
set @rowPokazatel='    по процентным доходам'
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

set @dataLevel = 4
set @prosCategory = 10
set @rowNum = 60
set @rowName=''
set @rowPokazatel=''
exec finAnalytics.calcRep840FirstLevel_4sub  @dataLevel, @prosCategory, @repmonth,@repdate,@rowNum,@rowName,@rowPokazatel

end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  

END