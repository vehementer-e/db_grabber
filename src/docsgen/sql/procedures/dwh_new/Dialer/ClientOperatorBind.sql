
CREATE procedure [Dialer].[ClientOperatorBind]
      @ProjectUUID nvarchar(100)
    , @ProjectTitle nvarchar(100)
    , @BindingDate  nvarchar(100)
    , @CRMClientGUID nvarchar(100)
    , @CRMClientFIO nvarchar(512)
    , @VelabClientFIO nvarchar(512)
    , @NaumenOperatorLogin nvarchar(100)
    , @NaumenOperatorUUID nvarchar(100)
as    


select @ProjectTitle,@BindingDate,@CRMClientGUID,@CRMClientFIO,@VelabClientFIO,@NaumenOperatorLogin,@NaumenOperatorUUID



update [Dialer].[ClientOperatorBinding]
set isHistory=1 ,updated=getdate()
where [ProjectUUID]=@ProjectUUID
and   [ProjectTitle]          =@ProjectTitle
and   [BindingDate]           =cast(getdate() as date)
and   [CRMClientGUID]         =@CRMClientGUID


INSERT INTO [Dialer].[ClientOperatorBinding]
           ([ProjectUUID]
           ,[ProjectTitle]
           ,[BindingDate]
           ,[CRMClientGUID]
           ,[CRMClientFIO]
           ,[VelabClientFIO]
           ,[NaumenOperatorLogin]
           ,[NaumenOperatorUUID]
           ,[created]
           ,[updated]
           ,[isHistory])
     
     select val.[ProjectUUID]
            ,val.[ProjectTitle]
            ,val.[BindingDate]
            ,val.[CRMClientGUID]
            ,val.[CRMClientFIO]
            ,val.[VelabClientFIO]
            ,uuids.[NaumenOperatorLogin]
            ,uuids.[NaumenOperatorUUID]
            ,val.[created]
            ,val.[updated]
            ,val.[isHistory]
     
     from 
     (
     select
     
           @ProjectUUID ProjectUUID
           ,@ProjectTitle ProjectTitle
           ,getdate() BindingDate
           ,@CRMClientGUID CRMClientGUID
           ,@CRMClientFIO CRMClientFIO
           ,@VelabClientFIO VelabClientFIO
           ,@NaumenOperatorLogin NaumenOperatorLogin
           ,@NaumenOperatorUUID NaumenOperatorUUID
           ,getdate() created
           ,getdate() updated
           ,0         isHistory
     ) as val
     left join [dwh_new].[Dialer].[OperatorUuidBinding] uuids on val.NaumenOperatorLogin=uuids.NaumenOperatorLogin and uuids.isHistory=0 and uuids.BindingDate=cast(getdate() as date)

declare @dt date
set @dt=cast(getdate() as date)
--exec dwh_new.dialer.CreateClientCase_Hard @CRMClientGUID,@dt           

