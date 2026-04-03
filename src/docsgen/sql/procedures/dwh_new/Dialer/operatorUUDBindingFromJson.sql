
-- exec dwh_new.Dialer.operatorUUDBindingFromJson 'D:\Scripts\CollectionHard\OperatorUUIDBinding.json'

CREATE   procedure [Dialer].[operatorUUDBindingFromJson] 
@filename nvarchar(1024)
as
begin

  set nocount on
  

  exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] ','Info','started',N'';


  if object_id('tempdb.dbo.#naumen_json') is not null drop table  #naumen_json
  
  create table #naumen_json (j nvarchar(max))

  declare @tsql nvarchar(max)
--  exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] ','Info','after declare variables',N'';

  set @tsql=N'
            bulk insert #naumen_json
            from '''+@filename+'''

            with(
                codepage=65001,
                tablock
                )
                '
  select @tsql
  begin try
--  exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] ','Info','before exec tsql',N'';
  exec (@tsql)
  --exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] ','Info','after exec tsql',N'';
  end try
  begin catch
  exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] error exec tsql','Error',@tsql,N'';
  end catch


  --select * from #naumen_json

  --exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] ','Info',@tsql,N'';

if object_id('tempdb.dbo.#res') is not null drop table  #res


select *
into #res 
from openjson((select j from #naumen_json),N'$.employee')
      with (
         uuid nvarchar(50) N'$.uuid.value',
         ouUUID nvarchar(50) N'$.ouUUID.value',
         title nvarchar(50) N'$.title',
         login nvarchar(50) N'$.login',
         firstName nvarchar(50) N'$.firstName',
         middleName nvarchar(50) N'$.middleName',
         lastName nvarchar(50) N'$.lastName',
         email nvarchar(50) N'$.email',
         internalPhoneNumber nvarchar(50) N'$.internalPhoneNumber',
         workPhoneNumber nvarchar(50) N'$.workPhoneNumber',
         mobilePhoneNumber nvarchar(50) N'$.mobilePhoneNumber',
         homePhoneNumber nvarchar(50) N'$.homePhoneNumber',
         licenseID nvarchar(50) N'$.licenseID',
         creationDate nvarchar(50) N'$.creationDate'
        )

declare @message nvarchar(max)
set @message=format((select count(*) from #res),'0')


exec logdb.dbo.[LogAndSendMailToAdmin] 'procedure [Dialer].[operatorUUDBindingFromJson] ','Finished',@message,N'';

update [Dialer].[OperatorUuidBinding] 
   set ishistory=1
 where  cast(BindingDate as date)=cast(getdate() as date)


INSERT INTO [Dialer].[OperatorUuidBinding]
           ([ProjectUUID]
           ,[ProjectTitle]
           ,[BindingDate]
           ,[NaumenOperatorLogin]
           ,[NaumenOperatorTitle]
           ,[NaumenOperatorUUID]
           ,[created]
           ,[updated]
           ,[isHistory])
  select '' [ProjectUUID]
        ,'' [ProjectTitle]
        ,getdate()
        ,login
        ,title
        ,uuid
        , getdate()
        , getdate()
        , 0
 from #res     

end




/*



*/