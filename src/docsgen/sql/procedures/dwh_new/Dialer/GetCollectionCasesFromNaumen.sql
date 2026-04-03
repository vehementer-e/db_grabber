-- exec [Dialer].[GetCollectionCasesFromNaumen]
 CREATE   procedure [Dialer].[GetCollectionCasesFromNaumen]
as
begin

set nocount on
begin tran
delete from reports.dbo.dm_NaumenCases   where dt>dateadd(day,-1,cast(getdate() as date))
 /*
 update reports.dbo.dm_NaumenCases
 set ishistory=1
 ,updated=getdate()
  where dt=dateadd(day,-1,cast(getdate() as date))
  and ishistory=0
  */
declare @tsql nvarchar(max)
set  @tsql=
'
SELECT uuid
     , history
     , priority
     , creationdate
     , projectuuid
     , projecttitle
     , clientuuid
     , clienttitle
     , stateuuid
     , statetitle
     , operatoruuid
     , operatortitle
     , casecomment
     , lasthistoryitem
     , operatorfirstname
     , operatormiddlename
     , operatorlastname
     , operatoremail
     , operatorinternalphonenumber
     , operatorworkphonenumber
     , operatormobilephonenumber
     , operatorhomephonenumber
     , operatordateofbirth
     , totalnumberofphones
     , numberofbadphones
     , plannedphonetime
     , lastcall
     , removed
     , removaldate
     , phonenumbers
     , email
     , stringvalue1
     , stringvalue2
     , uploadstate
     , uploadeddate
     , modifieddate
     , allowedtimefrom
     , allowedtimeto
     , finisheddate
     , timezone
FROM report_db.public.mv_call_case
where 
removaldate is null
and  creationdate>'''+format(dateadd(day,-1,cast(getdate() as date)),'yyyy-MM-dd')+'''
'

--select @tsql

/*
projectuuid=''corebo00000000000mkhaol8egu7qgqs'' or projectuuid=''corebo00000000000mjapldk2nhr2tts'' or projectuuid=''corebo00000000000mkhao6h43hspdvs'' or projectuuid=''corebo00000000000mokdmrhl5oqlgks''   or projectuuid=''corebo00000000000mnvpah31jdpe1a0''  
and 
*/

  
set @tsql='insert into reports.dbo.dm_NaumenCases select cast(getdate() as date) dt, *, ishistory=0,created=getdate(),updated=getdate() 
from openquery(naumen ,'''+replace(@tsql,'''','''''')+''')
'

--select @tsql


exec(@tsql)    

commit tran

end