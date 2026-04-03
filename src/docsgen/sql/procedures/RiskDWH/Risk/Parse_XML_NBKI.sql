

CREATE procedure [Risk].[Parse_XML_NBKI]
as
begin

 DECLARE @idoc int, @doc varchar(max), @response_date datetime,  @external_id nvarchar(20), @flag_correct int, @rn int
 , @id int 

 drop table if exists #t
 select 0 id
 into #t

 while (select min(id) from #t)>=0
 begin
    select top 1  
	--xmldata
	@id = nbki.id,
	@response_date=Getdate(),@external_id= nbki.id, @flag_correct=1, @rn=1	,
	@doc =  xmldata 

	from stg.files.XMLdataNBKI nbki
	left join #t t on t.id = nbki.id
	where
	t.id  is null 
	order by nbki.id desc


	 
	if (@@ROWCOUNT>0)
	begin
	--select @id
	print @id;
		insert into #t
		select @id
	end
	else
	begin
	print @id;
	select -1
		insert into #t
		select -1
	end
    -------

	
		 EXEC sp_xml_preparedocument @idoc OUTPUT, @doc;
	
	/*
		 insert into RiskDWH.[dbo].[AccountReply_tmp] exec RiskDWH.[risk].[AccountReply_NBKI]@idoc=@idoc,@doc=@doc,
	@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

	--select * from RiskDWH.[dbo].[AccountReply_tmp]
	

			 insert into RiskDWH.[dbo].AddressReply_tmp exec RiskDWH.[risk].[AddressReply_NBKI] @idoc=@idoc,@doc=@doc,
	@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

	--select * from RiskDWH.[dbo].[AddressReply_tmp]	

		
			 insert into RiskDWH.[dbo].[IdReply_tmp] exec RiskDWH.[risk].[IdReply_NBKI] @idoc=@idoc,@doc=@doc,
	@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn
	--select * from RiskDWH.[dbo].[IdReply_tmp]
	
				
			 insert into RiskDWH.[dbo].[InquiryReply_tmp] exec RiskDWH.[risk].[InquiryReply_NBKI] @idoc=@idoc,@doc=@doc,
	@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn
	--select * from RiskDWH.[dbo].[InquiryReply_tmp]
	

			 insert into RiskDWH.[dbo].[OwnInquiries_tmp] exec RiskDWH.[risk].[OwnInquiries_NBKI] @idoc=@idoc,@doc=@doc,
	@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

	--select * from RiskDWH.[dbo].[OwnInquiries_tmp]


			 insert into RiskDWH.[dbo].[PersonReply_tmp] exec RiskDWH.[risk].[PersonReply_NBKI] @idoc=@idoc,@doc=@doc,
	@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

	--select * from RiskDWH.[dbo].[PersonReply_tmp]

	*/

	exec sp_xml_removedocument @idoc;


	end


	-- заполнение служебных таблиц
	/*
	  drop table if exists #t;
	  -- найдем предполагаемую заявку по которой шел запрос
	  with заявка as
	  (
	  select * from
	  (
	  select 
		  Номер
		  , replace(seriesNumber,' ','') + idNum Паспорт
		  , rn = ROW_NUMBER() over (partition by external_id order by дата desc)
		  , external_id 
	  from dbo.IdReply_tmp reply
	  left join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС pts 
		on replace(reply.seriesNumber,' ','') + reply.idNum = pts.СерияПаспорта +  pts.НомерПаспорта
	  where дата < '4020-12-21' or дата is null
	  ) s
	  where s.rn=1
	  )
  
	  select 
			  serialNum
			  ,Номер
			  ,ar.external_id 
			  , OwnAccounts_Id = ROW_NUMBER() over(order by ar.external_id)
	  into #t
	  from dbo.AccountReply_tmp ar
	  left join заявка rep on ar.external_id =rep.external_id

	  delete from [RiskDWH].[dbo].OwnAccounts_tmp

	  insert into [RiskDWH].[dbo].OwnAccounts_tmp
	  select distinct OwnAccounts_Id, external_id  as report_id
	  from #t

	  insert into [RiskDWH].[dbo].[Account_tmp]
	  select serialNum,Номер as [acctNum]
		  ,[OwnAccounts_Id] from #t

		  */

end