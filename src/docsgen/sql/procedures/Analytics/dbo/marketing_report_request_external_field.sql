CREATE proc [dbo].[marketing_report_request_external_field] @mode nvarchar(max) = 'update' as
 

 if @mode = 'select'
 begin
 select * from [marketing_report_request_external_field_log]
 return
 end




 --------------------------1



drop table if exists  #t1
select * into #t1 from [v_request_external] a
 
--where a.producttype='Кредитная карта'  
where a.created>='20250301'
--order by a.created
 delete from #t1 where [lastName] like 'Тесто%'


drop table if exists  #t2
select b.source,a.* into #t2 from  #t1 a
left join v_lead2 b on a.id=b.id
--where a.producttype='Кредитная карта'  
 
 update  a set a.employmentPosition  = null  from #t2 a where employmentPosition =''




drop table if exists  #t3

 
 ;
 with v as (
 select   --top 1000
		 
  a.[productType]
  , a.source
,case when a.[employmentType]                   <>'' then 1 else 0 end [employmentType]                   
,case when a.[employmentPosition]				<>'' then 1 else 0 end [employmentPosition]				
,case when a.[employmentExperienceInMonth]		<>'' then 1 else 0 end [employmentExperienceInMonth]		
,case when a.[employmentPlace]					<>'' then 1 else 0 end [employmentPlace]					
,case when a.[employmentAddres]					<>'' then 1 else 0 end [employmentAddres]					
,case when a.[workPhone]						<>'' then 1 else 0 end [workPhone]						
,case when a.[employmentAddresLegal]			<>'' then 1 else 0 end [employmentAddresLegal]			
,case when a.[isUnemployed]						<>'' then 1 else 0 end [isUnemployed]						
,case when a.[unemployedReason]					<>'' then 1 else 0 end [unemployedReason]					
,case when a.[carPrice]							<>'' then 1 else 0 end [carPrice]							
,case when a.[carBrand]							<>'' then 1 else 0 end [carBrand]							
,case when a.[carModel]							<>'' then 1 else 0 end [carModel]							
,case when a.[carType]							<>'' then 1 else 0 end [carType]							
,case when a.[carYear]							<>'' then 1 else 0 end [carYear]							
,case when a.[carEngineNumber]					<>'' then 1 else 0 end [carEngineNumber]					
,case when a.[carRegNumber]						<>'' then 1 else 0 end [carRegNumber]						
,case when a.[carTransmissionNumber]			<>'' then 1 else 0 end [carTransmissionNumber]			
,case when a.[carVin]							<>'' then 1 else 0 end [carVin]							
,case when a.[depositType]						<>'' then 1 else 0 end [depositType]						
,case when a.[maritageStatus]					<>'' then 1 else 0 end [maritageStatus]					
,case when a.[educationType]					<>'' then 1 else 0 end [educationType]					
,case when a.[bankPurposeType]					<>'' then 1 else 0 end [bankPurposeType]					
,case when a.[bankRejectType]					<>'' then 1 else 0 end [bankRejectType]					
,case when a.[salaryBank]						<>'' then 1 else 0 end [salaryBank]						
,case when a.[sum]								<>'' then 1 else 0 end [sum]								
,case when a.[term]								<>'' then 1 else 0 end [term]								
,case when a.[termDay]							<>'' then 1 else 0 end [termDay]							
,case when a.[phone]							<>'' then 1 else 0 end [phone]							
,case when a.[homePhone]						<>'' then 1 else 0 end [homePhone]						
,case when a.[lastName]							<>'' then 1 else 0 end [lastName]							
,case when a.[firstName]						<>'' then 1 else 0 end [firstName]						
,case when a.[middleName]						<>'' then 1 else 0 end [middleName]						
,case when a.[birthDate]						<>'' then 1 else 0 end [birthDate]						
,case when a.[sex]								<>'' then 1 else 0 end [sex]								
,case when a.[email]							<>'' then 1 else 0 end [email]							
,case when a.[inn]								<>'' then 1 else 0 end [inn]								
,case when a.[snils]							<>'' then 1 else 0 end [snils]							
,case when a.[isReadyToDeposit] 				<>'' then 1 else 0 end [isReadyToDeposit] 				


, cast(created as date) date

from #t2 a




)



SELECT  
    productType,
    source,
	date, 
    column_name AS parameter_name,
    value_column AS parameter_value
	into #t3
FROM (
    SELECT 
        productType,
        source , date
        
,[employmentType]                   
,[employmentPosition]				
,[employmentExperienceInMonth]		
,[employmentPlace]					
,[employmentAddres]					
,[workPhone]						
,[employmentAddresLegal]			
,[isUnemployed]						
,[unemployedReason]					
,[carPrice]							
,[carBrand]							
,[carModel]							
,[carType]							
,[carYear]							
,[carEngineNumber]					
,[carRegNumber]						
,[carTransmissionNumber]			
,[carVin]							
,[depositType]						
,[maritageStatus]					
,[educationType]					
,[bankPurposeType]					
,[bankRejectType]					
,[salaryBank]						
,[sum]								
,[term]								
,[termDay]							
,[phone]							
,[homePhone]						
,[lastName]							
,[firstName]						
,[middleName]						
,[birthDate]						
,[sex]								
,[email]							
,[inn]								
,[snils]							
,[isReadyToDeposit] 				
    FROM v -- замените your_table на имя вашей таблицы
) AS a
UNPIVOT (
    value_column FOR column_name IN (
      [employmentType]                   
,[employmentPosition]				
,[employmentExperienceInMonth]		
,[employmentPlace]					
,[employmentAddres]					
,[workPhone]						
,[employmentAddresLegal]			
,[isUnemployed]						
,[unemployedReason]					
,[carPrice]							
,[carBrand]							
,[carModel]							
,[carType]							
,[carYear]							
,[carEngineNumber]					
,[carRegNumber]						
,[carTransmissionNumber]			
,[carVin]							
,[depositType]						
,[maritageStatus]					
,[educationType]					
,[bankPurposeType]					
,[bankRejectType]					
,[salaryBank]						
,[sum]								
,[term]								
,[termDay]							
,[phone]							
,[homePhone]						
,[lastName]							
,[firstName]						
,[middleName]						
,[birthDate]						
,[sex]								
,[email]							
,[inn]								
,[snils]							
,[isReadyToDeposit] 	
    )
) AS unpvt
WHERE value_column IS NOT NULL
ORDER BY productType, source, parameter_name;


 drop table if exists [marketing_report_request_external_field_log]
 select * into marketing_report_request_external_field_log from #t3



 --------------------------2

select 
  a.created
, b.number
, b.leadId
, b.phone
,
case 
when a.workphone              <>''  and c.field='Рабочий телефон'  then a.workphone       
when a.homePhone              <>''  and c.field='Дополнительный номер'  then a.homePhone     
when a.snils                  <>''  and c.field='СНИЛС'  then  a.snils         
when a.employmentPosition    <>''   and c.field='Должность'  then a.employmentPosition   
when a.employmentType         <>''   and c.field='Тип занятости'  then a.employmentType   
when a.monthlyCreditPayments  <>''   and c.field='Ежемесячные платежи по кредитам'  then cast( a.monthlyCreditPayments as nvarchar(255))
when a.employmentPlace        <>''   and c.field='Наименование работодателя'  then a.employmentPlace    
when a.employmentAddresLegal  <>''   and c.field='Юридический адрес работодателя'  then  a.employmentAddresLegal
when a.employmentAddres       <>''   and c.field='Фактический адрес работодателя'  then a.employmentAddres   
end fieldExternal
 


, c.field
, c.event
, c.result
, c.comment
, l.source
from v_request_external a
left join v_lead2 l on l.id=a.id
join request b on a.id=b.leadId and b.origin = 'uniapi'
join v_request_field c on c.number=b.number and

case 
when   a.workphone <> b.phone  and c.field='Рабочий телефон'  then 1
when  a.homePhone <> b.phone  and c.field='Дополнительный номер'  then 1
when a.snils                  <>''   and c.field='СНИЛС'  then 1
when a.employmentPosition    <>''    and c.field='Должность'  then 1
when a.employmentType         <>''   and c.field='Тип занятости'  then 1
when a.monthlyCreditPayments  <>''   and c.field='Ежемесячные платежи по кредитам'  then 1
when a.employmentPlace        <>''   and c.field='Наименование работодателя'  then 1
when a.employmentAddresLegal  <>''   and c.field='Юридический адрес работодателя'  then 1
when a.employmentAddres       <>''   and c.field='Фактический адрес работодателя'  then 1
end =1
 
where l.source ='psb-deepapi' and a.created>=getdate()-15
order by 2


  --Рабочий телефон
 --СНИЛС
 --Дополнительный номер
 --Должность
 --Тип занятости
 --Ежемесячные платежи по кредитам
 --Наименование работодателя
 --Юридический адрес работодателя
 --Фактический адрес места работы 
 
 select    id lead_id,created, productType, sum from v_request_external where sum is null
 order by created desc
