 
create   proc marketingSourceIntersection
as
 
-- update a set 
--    a.[hasLeadBankiruDeepapi]        =  case when b1.id  is not null then 1  end  
--,   a.[hasLeadBankiruDeepapiPts]	 =  case when b2.id  is not null then 1  end  


--from _request a
--left join lead_request b1 on a.phone=b1.phone and b1.created between dATEADD(day, -30, a.created) and  a.created and b1.source='bankiru-deepapi'
--left join lead_request b2 on a.phone=b2.phone and b2.created between dATEADD(day, -30, a.created) and  a.created and b2.source='bankiru-deepapi-pts'
--where b1.id is not null or b2.id is not null  
 

 UPDATE a
SET a.[hasLeadBankiruDeepapi] = 1
FROM _request a
 JOIN lead_request b1 
    ON a.phone = b1.phone 
   AND b1.created BETWEEN DATEADD(day, -30, a.created) AND a.created 
   AND b1.source = 'bankiru-deepapi'
--WHERE b1.id IS NOT NULL;


UPDATE a
SET a.[hasLeadBankiruDeepapiPts] = 1
FROM _request a
 JOIN lead_request b2 
    ON a.phone = b2.phone 
   AND b2.created BETWEEN DATEADD(day, -30, a.created) AND a.created 
   AND b2.source = 'bankiru-deepapi-pts'
 
UPDATE a
SET a.[hasLeadBankiruInstallmentCheck] = 1
FROM _request a
 JOIN v_lead2 b2 
    ON a.phone = b2.phone 
   AND b2.created BETWEEN DATEADD(day, -30, a.created) AND a.created 
   AND b2.source = 'bankiru-installment-check'
 




--alter table _request add hasLeadBankiruDeepapi tinyint
--alter table _request_log add hasLeadBankiruDeepapi tinyint
--alter table _request add hasLeadBankiruDeepapiPts tinyint
--alter table _request_log add hasLeadBankiruDeepapiPts tinyint
--alter table _request add [hasLeadBankiruInstallmentCheck] tinyint
--alter table _request_log add [hasLeadBankiruInstallmentCheck] tinyint