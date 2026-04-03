-- =============================================
-- Author:		Сабанин А.А
-- Create date: 27.03.2020
-- Description:	Отправка отчета о изменении заявки на запрещенных статусах
--exec [dbo].[monitoring_changed_request_on_forbidden_statuses] 
-- =============================================
CREATE PROCEDURE [dbo].[monitoring_changed_request_on_forbidden_statuses] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  Declare @dt_begin datetime
  , @dt_end datetime

  Set @dt_begin = cast(dateadd(day,-1,GetDate()) as date)
  Set @dt_end = cast(dateadd(day,0,GetDate()) as date)

  --Select @dt_begin, @dt_end

  if object_id('tempdb.dbo.#t')  is not null drop table #t

  Select *
  , HASHBYTES('SHA2_256',isnull([lastName],'')+ isnull([firstName],'') + isnull([secondName],'') + isnull(birthday,'') + isnull(mobilePhone,'')+ isnull(passportSerial,'')+ isnull(passportNumber,'')
 + isnull(locationOfBirth,'') + isnull([placeOfIssue],'') + isnull(dateOfIssue,'') + isnull(departmentCode,'')+ isnull(registrationAddres,'')) as hash_all
  -- distinct guidrequest 
  into #t
  --select  * 
  FROM [Stg].[_1cCRM].[RMQ_CRM_Monitoring]
 -- where try_cast (datestuatusrequest as datetime) is null
 --order by receivedate
  
  where [datestuatusrequest]>'20010101' and [datestuatusrequest] between @dt_begin and @dt_end

   -- реальный случай
   --select * from #t  where guidrequest =  'b34544de-d681-4a51-9408-6ef5f424cf01' order by publishTime

  -- получим список эталонов для заявок, которые изменились за вчера
  if object_id('tempdb.dbo.#t_standart')  is not null drop table #t_standart

  Select rn = ROW_NUMBER() over(partition by guidrequest order by publishTime asc), *
  into #t_standart
  FROM [Stg].[_1cCRM].[RMQ_CRM_Monitoring] where  [code] = 'VerificationClientsDocuments' 
   and  guidrequest in (select guidrequest from #t)




--      ----для теста
--select * from #t_standart  where guid =  '0c1aab0d-933f-416c-95bf-9c2a9f484ef9'
----update #t_standart set firstName='тест' where guid =  '0c1aab0d-933f-416c-95bf-9c2a9f484ef9'
--update #t_standart set residentialAddress='тест' where guid =  '0c1aab0d-933f-416c-95bf-9c2a9f484ef9'

--select * from #t_standart  where guid =  '0c1aab0d-933f-416c-95bf-9c2a9f484ef9'

   -- посчитаем хеш для значимых полей
   if object_id('tempdb.dbo.#t_hash')  is not null drop table #t_hash

   select  HASHBYTES('SHA2_256',isnull([lastName],'')+ isnull([firstName],'') + isnull([secondName],'') + isnull(birthday,'') + isnull(mobilePhone,'')+ isnull(passportSerial,'')+ isnull(passportNumber,'')
 + isnull(locationOfBirth,'') + isnull([placeOfIssue],'') + isnull(dateOfIssue,'') + isnull(departmentCode,'')+ isnull(registrationAddres,'')) as hash_standart, * --guidrequest, publishTime, datestuatusrequest
   into #t_hash
   from #t_standart where rn = 1


      ---part 2 residentialAddress
     -- получим список эталонов для заявок, которые изменились за вчера
  if object_id('tempdb.dbo.#t_standart_residentialAddress')  is not null drop table #t_standart_residentialAddress

  Select rn = ROW_NUMBER() over(partition by guidrequest order by publishTime asc), *
  into #t_standart_residentialAddress
  FROM [Stg].[_1cCRM].[RMQ_CRM_Monitoring] where  [code] = 'ApprovedClientsDocuments' 
   and  guidrequest in (select guidrequest from #t)

         ----для теста
--select * from #t_standart_residentialAddress  where  number ='20032610000052'-- guid =  '0c1aab0d-933f-416c-95bf-9c2a9f484ef9'
--select * from #t_standart_residentialAddress  where guid =  '7189ae76-fbe9-4bbe-9c14-bf96126a8ff7'
--update #t_standart set firstName='тест' where guid =  '0c1aab0d-933f-416c-95bf-9c2a9f484ef9'
--update #t_standart_residentialAddress set residentialAddress='тест' where guid =  '7189ae76-fbe9-4bbe-9c14-bf96126a8ff7'
--select * from #t_standart_residentialAddress  where guid =  '7189ae76-fbe9-4bbe-9c14-bf96126a8ff7'


   -- найдем самый первый статус
      -- посчитаем хеш для значимых полей
   if object_id('tempdb.dbo.#t_hash_residentialAddress')  is not null drop table #t_hash_residentialAddress

   select  HASHBYTES('SHA2_256',isnull(residentialAddress,'')) as hash_standart, * --guidrequest, publishTime, datestuatusrequest
   into #t_hash_residentialAddress
   from #t_standart_residentialAddress where rn = 1



   --select * from #t_hash_residentialAddress


      if object_id('tempdb.dbo.#t_res')  is not null drop table #t_res

   Select @dt_begin as date_begin, dateadd(second,-1,@dt_end) as date_end, t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
   , fld = 'lastName', standart_value = t.lastName, forbidden_value = t_error.lastName   
   into #t_res
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all and HASHBYTES('SHA2_256',t.lastName) <> HASHBYTES('SHA2_256',t_error.lastName)
   union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'firstName', standart_value = t.firstName, forbidden_value =  t_error.firstName  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.firstName) <> HASHBYTES('SHA2_256',t_error.firstName)
      union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'secondName', standart_value = t.secondName, forbidden_value =  t_error.secondName  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.secondName) <> HASHBYTES('SHA2_256',t_error.secondName)
      union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'birthday', standart_value = t.birthday, forbidden_value =  t_error.birthday  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.birthday) <> HASHBYTES('SHA2_256',t_error.birthday)
         union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'mobilePhone', standart_value = t.mobilePhone, forbidden_value =  t_error.mobilePhone  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.mobilePhone) <> HASHBYTES('SHA2_256',t_error.mobilePhone)

--
   union all
   Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
   , fld = 'passportSerial', standart_value = t.passportSerial, forbidden_value = t_error.passportSerial  
    from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all and HASHBYTES('SHA2_256',t.passportSerial) <> HASHBYTES('SHA2_256',t_error.passportSerial)
   union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
    , fld = 'passportNumber', standart_value = t.passportNumber, forbidden_value =  t_error.passportNumber  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.passportNumber) <> HASHBYTES('SHA2_256',t_error.passportNumber)
   --
         union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'locationOfBirth', standart_value = t.locationOfBirth, forbidden_value =  t_error.locationOfBirth  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.locationOfBirth) <> HASHBYTES('SHA2_256',t_error.locationOfBirth)
         union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'placeOfIssue', standart_value = t.placeOfIssue, forbidden_value =  t_error.placeOfIssue  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.placeOfIssue) <> HASHBYTES('SHA2_256',t_error.placeOfIssue)
   -- + isnull(locationOfBirth,'') + isnull([placeOfIssue],'') + isnull(dateOfIssue,'') + isnull(departmentCode,'')+ isnull(registrationAddres,'')) as hash_standart, 
            union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'dateOfIssue', standart_value = t.dateOfIssue, forbidden_value =  t_error.dateOfIssue  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.dateOfIssue) <> HASHBYTES('SHA2_256',t_error.dateOfIssue)
            union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'departmentCode', standart_value = t.departmentCode, forbidden_value =  t_error.departmentCode  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.departmentCode) <> HASHBYTES('SHA2_256',t_error.departmentCode)
               union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'registrationAddres', standart_value = t.registrationAddres, forbidden_value =  t_error.registrationAddres  
   from #t t_error
   left join #t_hash t on t_error.guidrequest = t.guidrequest
   where hash_standart is not null and hash_standart<> hash_all  and HASHBYTES('SHA2_256',t.registrationAddres) <> HASHBYTES('SHA2_256',t_error.registrationAddres)

    union all
     Select @dt_begin, dateadd(second,-1,@dt_end), t_error.number, t_error.code,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint) 'diffrents', DATEADD(second,  cast(t_error.publishTime as bigint) - cast(t.publishTime  as bigint), t.datestuatusrequest) ДатаИзмененияОценка, t_error.datestuatusrequest
      , fld = 'residentialAddress', standart_value = t.residentialAddress, forbidden_value =  t_error.residentialAddress  
   from #t t_error
   left join #t_hash_residentialAddress t on t_error.guidrequest = t.guidrequest
   where HASHBYTES('SHA2_256',t.residentialAddress) <> HASHBYTES('SHA2_256',t_error.residentialAddress)
   and t_error.code in ('ApprovedClientsDocuments', 'ControlApprovingClientsDocuments', 'VerificationDocuments', 'ControlVerificationDocuments', 'Approved', 'P2P', 'CheckPEP_PTS', 'RegistrationContract', 'ContractRegistered', 'ControlContractSigned')


   --select * from #t_res
   --order by number, diffrents

   
   
DECLARE @tableHTML  NVARCHAR(MAX) ;  
declare @cnt bigint
set @cnt=cast(isnull((select count(number) as cnt from #t_res) ,0) as bigint)

-- если есть новые вхоождения, то высылаем сообщения на почту
--Номер заявки, Статус, Дата/время изменения, измененный реквизит (значение измененного реквизита и значение до изменения).
-- если есть новые вхоождения, то высылаем сообщения на почту
if @cnt>0 
begin
SET @tableHTML =  
    N'<H1>Уведомление о заявках с измененными данными клиента на запрещенных статусах. <br>Дата от ' 
	+ format(@dt_begin, 'dd-MM-yyyy HH:mm:ss','en-us') + ' до ' + format(dateadd(second,-1,@dt_end), 'dd-MM-yyyy HH:mm:ss','en-us') + ' </H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Номер заявки</th><th>Статус</th>' +  
	N'<th>Дата/время изменения (Оценка)</th><th>Измененный реквизит</th><th>Значение измененного реквизита</th>' +  
    N'<th>Значение до изменения</th></tr>' +  
    CAST ( ( SELECT td = number,       '',  
                    td = code, '',  
                    td = ДатаИзмененияОценка, '',
					td = fld, '',
					td = forbidden_value, '',
					td = standart_value, ''

				from #t_res
				
				order by  number, diffrents
 
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  
  
  --select @tableHTML

  EXEC msdb.dbo.sp_send_dbmail 
    @profile_name = 'Default',  
    @recipients='dwh112@carmoney.ru;prometov@carmoney.ru;',  --; Krivotulov@carmoney.ru
    @subject = 'Отчет по заявкам с измененными данными клиента на запрещенных статусах',  
    @body = @tableHTML,  
    @body_format = 'HTML' ; 
end 
END
