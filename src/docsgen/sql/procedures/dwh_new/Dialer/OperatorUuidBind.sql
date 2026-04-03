CREATE procedure [Dialer].[OperatorUuidBind]
   @ProjectUUID nvarchar(100)=''
 , @ProjectTitle nvarchar(100)=''
 , @BindingDate  nvarchar(100)=''
 , @NaumenOperatorLogin nvarchar(100)=''
 , @NaumenOperatorTitle nvarchar(100)=''
 , @NaumenOperatorUUID nvarchar(100)=''
 
as

update [Dialer].[OperatorUuidBinding] 
set ishistory=1
where @NaumenOperatorLogin=NaumenOperatorLogin and cast(BindingDate as date)=cast(getdate() as date)


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
     VALUES
           (
            @ProjectUUID
          , @ProjectTitle
          , getdate()
          , @NaumenOperatorLogin
          , @NaumenOperatorTitle
          , @NaumenOperatorUUID 

          , getdate()
          , getdate()
          , 0
           
           )





