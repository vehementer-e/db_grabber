create procedure GetFsspData as

drop table if exists dbo.FsspData;

with selection as(
select id,
val =
REPLACE(
case when len([dbo].[StripNonNumerics](ExecutionItem))>0 then  SUBSTRING([dbo].[StripNonNumerics](ExecutionItem),2,len([dbo].[StripNonNumerics](ExecutionItem))-2)
else null end 
,'.:',';')
from [C1-VSR-SQL05].[BPMOnline_night00].dbo.KmReportFromFSSP
) , 
result as(
SELECT Id, value 
FROM selection  
    CROSS APPLY STRING_SPLIT(val, ';')
)

--103681
select 
f.id,
f.Debtor,      
f.ExecutiveManufacturing, 
ExecutiveDate =  try_cast(substring(f.ExecutiveManufacturing, charindex('от',f.ExecutiveManufacturing)+3,10) as date),
f.RequisitesDocument, 
f.ExpirationDate,       
f.ExecutionItem,  

flag = case when PATINDEX('%СТ46Ч1П3%',[dbo].[CanonicalString](f.Executor)) >0 then 1 else 0 end,
value = sum(try_cast( r.value as float)),   
f.Department,  
f.Executor,
f.FinapplicationId 
into dbo.FsspData
from [C1-VSR-SQL05].[BPMOnline_night00].dbo.KmReportFromFSSP f 
left join result r on r.id=f.id
group by 
f.id,
f.Debtor,      
f.ExecutiveManufacturing,    
f.RequisitesDocument, 
f.ExpirationDate,       
f.ExecutionItem,     
f.Department,  
f.Executor,
f.FinapplicationId ;

