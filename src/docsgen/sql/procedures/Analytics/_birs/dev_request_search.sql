CREATE   PROCEDURE [_birs].[dev_request_search] 
  @phone VARCHAR(40),
  @request_number VARCHAR(40) 
AS
IF LEN(@phone) = 10
BEGIN 
SELECT created, isPts, number, status, status2,firstSum, approvedSum, issuedSum, issued, phone, ФИО, origin, call1, call1Approved, checked, call2, Call2Approved, clientVerified, clientApproved, carVerified, approved, closed, declined, declinedByClient, office, partner, isDubl
FROM analytics.dbo.v_fa
WHERE phone = @phone;
END

ELSE
BEGIN
SELECT created, isPts, number, status, status2,firstSum, approvedSum, issuedSum, issued, phone, ФИО, origin, call1, call1Approved, checked, call2, Call2Approved, clientVerified, clientApproved, carVerified, approved, closed, declined, declinedByClient, office, partner, isDubl
FROM analytics.dbo.v_fa
WHERE number = @request_number;
END
