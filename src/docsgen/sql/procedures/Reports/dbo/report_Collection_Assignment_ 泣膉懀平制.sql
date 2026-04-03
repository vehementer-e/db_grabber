

-- exec [dbo].[report_Collection_Assignment] null,null,'Общество с ограниченной ответственностью «Коллекторское агентство «Аркан» (ООО «КА «Аркан»)' 
CREATE  PROCEDURE  [dbo].[report_Collection_Assignment]

--declare
@dtfrom date = null --'2021-08-26'
, @dtto date = null
, @contragent nvarchar(max) = null -- 
, @loan_assignment nvarchar(max) = null -- 
 
AS
BEGIN
	SET NOCOUNT ON;

	if @contragent is null 
	begin
	Set @contragent = 'Не указано'
	end
	
	--if @loan_assignment is null 
	--begin
	--Set @loan_assignment = ''
	--end

	if @dtfrom is null 
	begin
	Set @dtfrom = dateadd(year, -20,GetDate())
	end

	if @dtto is null 
	begin
	Set @dtto = GetDate()
	end
	

	--select @dtfrom
select 
*
from dbo.v_assignment 
where 
Контрагент in (Select value from string_split(@contragent,','))
and cast(ДатаПродажаДоговора as date) >= @dtfrom
and cast(ДатаПродажаДоговора as date) <= @dtto
and Комментарий like '%' + isnull(@loan_assignment,'') + '%'

-- and 

--case when @loan_assignment is null then '1' else контрагент end like (
--case when @loan_assignment is null then '1' else '%' +@loan_assignment + '%' end)

END
