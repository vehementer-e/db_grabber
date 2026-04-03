






-- =============================================
-- Author:		Orlov A.
-- Create date: 2019-07-03
-- Description:
-- =============================================

CREATE PROCEDURE [bki].[Main_parser_old]
-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here

	--additional
	DECLARE @idoc          int
	,       @doc           xml
	,       @response_date datetime
	,       @external_id   nvarchar(20)
	,       @flag_correct  int
	,       @rn            int
	while (select count(*)
		from bki.ntable
		where ТекстОтвета is not null )>0
	begin
		select top 1 @doc=ТекстОтвета
		,            @response_date=Период
		,            @external_id= ОбъектВыгрузки
		,            @flag_correct=flag_correct
		,            @rn=rn
		from bki.nTable
		where ТекстОтвета is not null
		-------

		EXEC sp_xml_preparedocument @idoc OUTPUT
		,                           @doc;
		insert into bki.n_AccountReply_tmp exec [bki].[AccountReply]@idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.[n_AddressReply] exec [bki].AddressReply @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.[n_IdReply] exec [bki].IdReply @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.[n_InquiryReply] exec [bki].InquiryReply @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.[n_OwnInquiries] exec [bki].OwnInquiries @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.[n_PersonReply] exec [bki].PersonReply @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		exec sp_xml_removedocument @idoc
		-------

		delete from bki.nTable
		where ОбъектВыгрузки=@external_id
			and rn=@rn
	end

	select *
	from bki.xTable

	--DECLARE @idoc          int
	--,       @doc           xml
	--,       @response_date datetime
	--,       @external_id   nvarchar(20)
	--,       @flag_correct  int
	--,       @rn            int

	declare @t_external_id table ( external_id nvarchar(20)
	,                              rn          int )

	declare cur_xTable cursor for
	select doc = substring(ТекстОтвета,charindex('<bki_response',ТекстОтвета),(len(ТекстОтвета)-charindex('<bki_response',ТекстОтвета))+1)
	,      Период                                                                                                                         
	,      ОбъектВыгрузки                                                                                                                 
	,      flag_correct                                                                                                                   
	,      rn                                                                                                                             

	from bki.xTable
	where ТекстОтвета is not null
		and TRY_CAST(ТекстОтвета as xml) is not null


	order by ОбъектВыгрузки
	OPEN cur_xTable

	FETCH NEXT FROM cur_xTable
	INTO
	@doc
	,@response_date
	,@external_id
	,@flag_correct
	,@rn


	WHILE @@FETCH_STATUS = 0
	begin
		begin try
		print @external_id
		EXEC sp_xml_preparedocument @idoc OUTPUT
		,                           @doc;
		--select @idoc
		--,      @doc
		--,      @response_date
		--,      @external_id
		--,      @flag_correct
		--,      @rn
		insert into bki.eqv_credits_tmp exec [bki].[credits]@idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_collaterals exec [bki].collaterals @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_interest exec [bki].interest @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_own_interest exec [bki].own_interest @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_requests exec [bki].requests @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_scoring exec [bki].scoring @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_additional exec [bki].additional @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_personal exec [bki].personal @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_doc exec [bki].doc @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_history_person exec [bki].history_person @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_history_doc exec [bki].history_doc @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		insert into bki.eqv_addreses exec [bki].addreses @idoc=@idoc,@doc=@doc,
		@response_date=@response_date,@external_id=@external_id,@flag_correct=@flag_correct, @rn=@rn

		-------
		exec sp_xml_removedocument @idoc
		insert into @t_external_id
		select @external_id
		,      @rn

		end try
		begin catch
		declare @msg nvarchar(max)

		SELECT CONCAT ('Ошибка обработки записи: ', @external_id, '; Ошибка:', ERROR_MESSAGE(), '; Процедура: ', ERROR_PROCEDURE())
		print @msg
		;throw 51000, @msg, 1;
		end catch
		FETCH NEXT FROM cur_xTable
		INTO
		@doc
		,@response_date

		,@external_id
		,@flag_correct
		,@rn

	end
	CLOSE cur_xTable;
	DEALLOCATE cur_xTable;
	delete t
	from       bki.xTable     t
	inner join @t_external_id s on s.external_id = ОбъектВыгрузки
			and s.rn= t. rn
END
