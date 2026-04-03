CREATE proc [dbo].[_update_openrowsets]

as
begin



declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='


set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Adhoc\adhoc — копия.xlsx'''
set @sheet  =  'Adhoc'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'adhoc'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Верификация\verification_types_of_comments.xlsx'''
set @sheet  =  'verification_types_of_comments'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'verification_types_of_comments'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'
/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/


set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Installment\installment выгрузка из вупры.xlsx'''
set @sheet  =  'installment'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'installment выгрузка из вупры'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'
/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx'''
set @sheet  =  'Партнеры_привлечение'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'Стоимость займа Партнеры_привлечение'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'

/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx'''
set @sheet  =  'Партнеры_оформление'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'Стоимость займа Партнеры_оформление'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'


/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx'''
set @sheet  =  'CPA'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'Стоимость займа CPA'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'



/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Стоимость займа\Расходы по месяцам от подразделений.xlsx'''
set @sheet  =  'Агрегированные_Данные'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'Стоимость займа Агрегированные_Данные'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'


/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  '\\c2-vsr-dwh2.cm.carmoney.ru\DWHFiles\Analytics\Стоимость займа\Ставки КВ партнеров по месяцам.xlsx'''
set @sheet  =  'Ставки КВ партнеров по месяцам'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'Ставки КВ партнеров по месяцам'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'



/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/
set @path  =  'D:\DWHFiles\Analytics\ПШ\Погашения с начала выдачи.xlsx'''
set @sheet  =  'Sheet1'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'qiwi_repayments'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'

/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  'D:\DWHFiles\Analytics\Опросы клиентов\Опрос заявка.xlsx'''
set @sheet  =  'welcome'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'request_link_welcome'
set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  'D:\DWHFiles\Analytics\Опросы клиентов\Опрос заявка.xlsx'''
set @sheet  =  'exit'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'request_link_exit'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'

/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/


set @path  =  'D:\DWHFiles\Analytics\Опросы клиентов\NEW WELCOME_ Опрос клиентов о качестве обслуживания.xlsx'''
set @sheet  =  '0'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'welcome_survey'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'



/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/


set @path  =  'D:\DWHFiles\Analytics\Опросы клиентов\NEW exit_ Опрос клиентов о качестве обслуживания.xlsx'''
set @sheet  =  '0'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'exit_survey'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'




/*

declare @table nvarchar(max)
declare @source nvarchar(max)
declare @sql nvarchar(max)   
declare @path nvarchar(max)   
declare @sheet nvarchar(max)   
declare @driver nvarchar(max)   = 'OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0; Database='
*/

set @path  =  'D:\DWHFiles\Analytics\Кэшдрайв залоги\Кэшдрайв залоги.xlsx'''
set @sheet  =  'Залоги'
set @source  = @driver+@path+', ''select * from ['+@sheet+'$]'')'
set @table  =  'cashdrive_pledges'

set @sql     = 'drop table if exists [_openrowset_'+ @table +'] select * into [_openrowset_'+ @table +'] from '+@source
exec (@sql)
--select 'select * from analytics.dbo.[_openrowset_'+ @table +']'







end