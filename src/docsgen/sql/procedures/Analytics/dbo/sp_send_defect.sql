CREATE   proc [dbo].[sp_send_defect] 
@sql   nvarchar(max)= '
select  getdate() created
'
, @problem  nvarchar(max) = 'test problem'
, @to nvarchar(max) = 'p.ilin@smarthorizon.ru'
, @xlsx int = 0
, @show_new int = 0
as

--sp_send_defect default, default,  default, 1

BEGIN TRY 




declare @sql_defect  nvarchar(max) = 'drop table if exists #t0
select * into #t0 from ('+
@sql+'
) x 



declare @defCreated datetime2(0) = ( select max(created ) from #t0)
if @defCreated is null
return

if exists (select top 1 * from _defect where defect ='''+@problem+''' and created >=   @defCreated )
return

if '+cast(@show_new as varchar(1)) +' = 1
begin
alter table #t0 add [NEW] varchar(10)

update #t0 set [NEW] = ''!!!!''  where created > isnull( (select max(created ) from _defect where defect ='''+@problem+'''  ), ''2001-01-01'')


end

if '+cast(@xlsx as varchar(1)) +' = 1
begin
drop table if exists ##defect_xlsx select * into  ##defect_xlsx from #t0

exec python ''sql_to_gmail("select * from ##defect_xlsx order by created desc", name = "'+@problem+'", add_to="'+@to+'")'' , 1
insert into _defect select '''+@problem+''', @defCreated , ''''

end
else 
begin


declare @html nvarchar(max)
exec sp_html ''select * from #t0'',  ''order by created desc'' , @html output 

insert into _defect select '''+@problem+''', @defCreated , @html

exec notify_html ''_defect_catcher: '+@problem+''', '''+@to+''',   @html

end


'


--print (@sql_defect)
exec (@sqL_defect)
 


 --sp_send_defect 'select * from (select getdate() created) x'





END TRY
BEGIN CATCH
    DECLARE 
        @errorMessage NVARCHAR(4000),
        @errorSeverity INT,
        @errorState INT,
        @errorLine INT;

    -- Получаем данные об ошибке
    SELECT 
        @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE(),
        @errorLine = ERROR_LINE();

	set	@errorMessage =   CONCAT('sp_send_defect ошибка, sql =' +@sql+'
	'+'Ошибка на строке: ', @errorLine, ' — ', @errorMessage)

 

    -- Или вернуть через SELECT, если нужно в DataFrame
    SELECT 
        ErrorLine = @errorLine,
        ErrorMessage = @errorMessage;

    -- Повторно выбрасываем ошибку с уточнением строки
    THROW 50000, @errorMessage, 1;
END CATCH;




--create table _defect (defect nvarchar(max), created datetime2(0) , html nvarchar(max) )
