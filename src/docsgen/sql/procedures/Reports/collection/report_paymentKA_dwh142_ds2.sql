CREATE   PROCEDURE [collection].[report_paymentKA_dwh142_ds2]
AS
BEGIN
    SELECT 
        *
    FROM 
		[Collection].[paymentKA_dwh142_heap]
	WHERE
		dt is not null
	order by 
		dt desc;
END