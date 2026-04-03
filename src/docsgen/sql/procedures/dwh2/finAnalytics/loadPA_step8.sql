

CREATE  PROCEDURE [finAnalytics].[loadPA_step8] 
		@repmonth date
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	declare @subjectHeader  nvarchar(250) ='ПА. Процедура обновления комиссий', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Внесение данных в таблицу PA_commPS: ',FORMAT(@repmonth, 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
	
	--declare @repmonth date='2025-05-01'
	declare @startMonth date =@repmonth
	declare @endMonth date =eomonth(@repmonth)
begin try
  begin tran  				
	delete dwh2.finAnalytics.PA_CommPS where repmonth=@repmonth
	
	drop table if exists #allPs
		create table #allPs(repmonth date, numdog varchar(20),summ float,ps varchar(20))
		insert into #allPs(repmonth, numdog,summ,ps)
			select 
				repmonth
				,numdog
				,summ
				,ps='ecompay'
			from dwh2.finAnalytics.comm_Ecompay
			where repmonth=@repmonth
			union all
			select 
				repmonth
				,numDog
				,summ
				,ps='sbp'
			from dwh2.finAnalytics.comm_sbp
			where repmonth=@repmonth
			union all
			select 
				repmonth
				,numdog
				,summ
				,ps='sngb'
			from dwh2.finAnalytics.comm_sngb
			where repmonth=@repmonth
			union all
			select 
				repmonth
				,numdog
				,summ
				,ps='tkb'
			from dwh2.finAnalytics.comm_tkb
			where repmonth=@repmonth
			union all
			select 
				repmonth
				,numdog
				,summ
				,ps='vtkb'
			from dwh2.finAnalytics.comm_vtkb
			where repmonth=@repmonth
			union all
			---Золотая корона
			select 
				repmonth= @startMonth
				,numdog=b.dogNum
				,summ=a.СуммаПолная*0.012
				,ps='korona'
			from Stg.[_1cCMR].[Документ_Платеж] a 
			left join dwh2.[finAnalytics].[PA_DOG] b on a.Договор=b.dogGIUD_CMR
			left join stg.[_1cCMR].[Справочник_ПлатежныеСистемы] c on a.ПлатежнаяСистема=c.Ссылка
			where a.ПлатежнаяСистема=0xB8158548A1C7AF7B11EEF0D6F84CC139 --Золотая Корона
					and cast (dateadd(year,-2000,a.Дата) as date) between @startMonth and @endMonth

	drop table if exists #commPS
	create table #commPS (repmonth date, numdog varchar(20)
							,summ_Ecompay float
							,summ_Sbp float
							,summ_Sngb float
							,summ_Tkb float
							,summ_VTkb float
							,summ_Korona float)
	insert into #commPS (repmonth, numdog,summ_Ecompay,summ_Sbp,summ_Sngb,summ_Tkb,summ_VTkb,summ_Korona)
	select
		repmonth
		,numdog
		,summ_Ecompay=sum(l1.summ_Ecompay)
		,summ_Sbp=sum(l1.summ_Sbp)
		,summ_Sngb=sum(l1.summ_Sngb)
		,summ_Tkb=sum(l1.summ_Tkb)
		,summ_VTkb=sum(l1.summ_VTkb)
		,summ_Korona=sum(l1.summ_Korona)
	from ( 
		select
			repmonth
			,numdog
			,summ_Ecompay=iif(ps='ecompay',summ,0)
			,summ_Sbp=iif(ps='sbp',summ,0)
			,summ_Sngb=iif(ps='sngb',summ,0)
			,summ_Tkb=iif(ps='tkb',summ,0)
			,summ_VTkb=iif(ps='vtkb',summ,0)
			,summ_Korona=iif(ps='korona',summ,0)
		from #allPs) l1
	group by repmonth,numdog
 insert into dwh2.finAnalytics.PA_CommPs (repmonth, dogNum,summ_Ecompay,summ_Sbp,summ_Sngb,summ_Tkb,summ_VTkb,summ_Korona)
	select
		*
	from #commPS
 commit tran
		set @subject=@subjectHeader 
		set @message=concat(@msgHeader,@msgFloor)
		exec finAnalytics.sendEmail @subject,@message ,@strRcp = '99'
	
end try 
 begin catch
    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
   ;throw 51000 
			,@message
			,1;    
  end catch
end
