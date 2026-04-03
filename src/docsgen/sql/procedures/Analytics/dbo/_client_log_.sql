
CREATE proc [dbo].[_client_log_]
as

--select * from _client_crm_log order by created desc
--select * from _client_log order by created desc



--exec sp_select_except '#t3222232332324', '_client_log' , 'clientid' , '#t3222232332324'

drop table if exists #t3222232332324
select clientId, fiobirthday, passportSerialNumber,phone, created, call1 , issued, guid  into #t3222232332324 from _request 
where clientId is not null 
 

--drop table if exists _client_log
--select * into _client_log from #t3222232332324 
    INSERT INTO _client_log ([clientId], [fiobirthday], [passportSerialNumber], [phone], [created], [call1], [issued], [guid])
    SELECT [clientId], [fiobirthday], [passportSerialNumber], [phone], [created], [call1], [issued], [guid]
    FROM  #t3222232332324
    EXCEPT
    SELECT [clientId], [fiobirthday], [passportSerialNumber], [phone], [created], [call1], [issued], [guid]
    FROM _client_log
    WHERE _client_log.clientid IN (
        SELECT clientid
        FROM   #t3222232332324
    );





--select * from linked where is_crm=1 and column_name like '%' + 'фамилия' + '%'
--select * from linked where is_crm=1 and table_name like '%' + 'контак' + '%'

--select top 1000 * from [C3-VSR-SQL02].[crm].dbo.Справочник_КонтактныеЛицаПартнеров
--select top 1000 * from [C3-VSR-SQL02].[crm].dbo.Перечисление_ТипыКонтактнойИнформации