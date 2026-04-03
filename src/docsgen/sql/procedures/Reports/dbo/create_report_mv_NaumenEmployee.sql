-- =============================================
-- Author:		A. Kotelevets 
-- Create date: 06-11-2020
-- Description:	DWH-773
-- exec [create_report_mv_NaumenEmployee]
-- =============================================
CREATE procedure dbo.[create_report_mv_NaumenEmployee]
as 
begin
drop table if exists #t_mv_employee
	select 
		[uuid], 
		[title], 
		[creationdate], 
		[removed], 
		[removaldate], 
		[ou], 
		[outitle], 
		[firstname], 
		[middlename], 
		[lastname], 
		[email], 
		[internalphonenumber], 
		[workphonenumber], 
		[mobilephonenumber], 
		[homephonenumber], 
		[dateofbirth], 
		[post], 
		[department], 
		[privatecode], 
		[timezone], 
		[address], 
		[coment], 
		[login],
		loaded_into_reports = getdate()  
	into #t_mv_employee
	from [NaumenDbReport].[dbo].[mv_employee]

	if exists (select top(1) 1 from #t_mv_employee)
	begin
		delete from  dbo.mv_NaumenEmployee
		where cast(loaded_into_reports as date) = cast(loaded_into_reports as date)
		
		insert into dbo.mv_NaumenEmployee
		(
			[uuid], 
			[title], 
			[creationdate], 
			[removed], 
			[removaldate], 
			[ou], 
			[outitle], 
			[firstname], 
			[middlename], 
			[lastname], 
			[email], 
			[internalphonenumber], 
			[workphonenumber], 
			[mobilephonenumber], 
			[homephonenumber], 
			[dateofbirth], 
			[post], 
			[department], 
			[privatecode], 
			[timezone], 
			[address], 
			[coment], 
			[login],
			loaded_into_reports
		)
		select 
			[uuid], 
			[title], 
			[creationdate], 
			[removed], 
			[removaldate], 
			[ou], 
			[outitle], 
			[firstname], 
			[middlename], 
			[lastname], 
			[email], 
			[internalphonenumber], 
			[workphonenumber], 
			[mobilephonenumber], 
			[homephonenumber], 
			[dateofbirth], 
			[post], 
			[department], 
			[privatecode], 
			[timezone], 
			[address], 
			[coment], 
			[login],
			loaded_into_reports
		from #t_mv_employee
	end
drop table if exists #t_mv_employee

end
