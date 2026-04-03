
CREATE       procedure [marketing].[set_PushProfileName2Send_povt_PDl]
as
begin try

	declare @pushProfile table (
		profileName nvarchar(255),
		description nvarchar(255),
		interactionTypeCode nvarchar(255)
	)
	insert into @pushProfile(profileName, description, interactionTypeCode)
	select ProfileName, description,  interactionTypeCode from (values
		 ('PUSH_ID_NEW_RE-LOAN_3270'				,'Новый'				,N'isNew')
		,('PUSH_ID_REFUSAL_CLIENT_RE-LOAN_3270'		,'Отказ клиента'		,N'isCustomerRejection')
		,('PUSH_ID_REFUSAL_CLIENT_RE-LOAN_3270'		,'Отказ клиента'		,N'isCustomerRejectionPush')
		,('PUSH_ID_NO_ANSWER_3270'					,'Недозвон'				,N'isNotCall2Client')
		,('PUSH_ID_APPLICATION_PROCESSING_3270'		,'Заявка на оформлении'	,N'isNotActiveApplication')
		,('PUSH_ID_REFUSED_3270', 'Отказ компании'							,N'isCompanyRejection')
		,('PUSH_ID_SPECIAL_OFFER_3270','Остальные'							,N'isOtherCases')
		,('PUSH_ID_0_DAY_3449',''											,N'0_days_after_loan_repaid' )
		,('PUSH_ID_1_DAY_3449'						,''						,N'1_days_after_loan_repaid' )
		,('PUSH_ID_2_DAY_3449'						,''						,N'2_days_after_loan_repaid' )
		--,(''										,''						,N'3_days_after_loan_repaid' )
		---,(''										,''						,N'4_days_after_loan_repaid' )
		,('PUSH_ID_5_DAY_3449'						,''						,N'5_days_after_loan_repaid' )
		--,(''										,''						,N'6_days_after_loan_repaid' )
		--,(''										,''						,N'7_days_after_loan_repaid' )
		,('PUSH_ID_8_DAY_3449'						,''						,N'8_days_after_loan_repaid' )
		--,(''										,''						,N'9_days_after_loan_repaid' )
		--,(''										,''						,N'10_days_after_loan_repaid')
		,('PUSH_ID_11_DAY_3449'						,''						,N'11_days_after_loan_repaid')
		--,(''										,''						,N'12_days_after_loan_repaid')
	) t(ProfileName, description,  interactionTypeCode)
	begin tran
		update t
			set t.date2SendPush = iif(pp.profileName is not null,getdate(), null)
				,t.pushProfile2Send = pp.profileName
				--,push_communicationId = iif(pp.profileName is not null,newid(), null)
		from marketing.povt_PDL t
		left join @pushProfile pp on pp.interactionTypeCode = t.interactionTypeCode
		where cdate = cast(getdate() as date)
		
	commit tran
end try
begin catch
	if @@TRANCOUNT>0
			rollback tran
		;throw
end catch
