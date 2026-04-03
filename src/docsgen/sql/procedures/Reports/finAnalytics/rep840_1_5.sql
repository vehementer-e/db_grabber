



CREATE PROCEDURE [finAnalytics].[rep840_1_5]
        @repmonth date,
        @sumRang int

AS
BEGIN
  
	select
	[repMonth], 
	[returnDate], 
	[loadDataDate], 
	[vipuskNum], 
	[ISINcode], 
	[emissionAmount], 
	[nominal], 
	[issueDate], 
	[stavka], 
	[isDosroch], 
	[nonPogashCount], 
	[restOD], 
	[cupon], 
	[moneyForIssue]
    from dwh2.[finAnalytics].SPR_ObligacGrafic
	where REPMONTH= @repmonth
    
END
