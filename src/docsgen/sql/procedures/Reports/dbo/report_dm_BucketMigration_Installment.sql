CReate procedure [dbo].[report_dm_BucketMigration_Installment]
as
begin
	select * from dbo.[dm_BucketMigration_Installment]
	where Дата = cast(GetDate() as date)
	order by ДатаВремяПоследнегоПлатежа desc
end

