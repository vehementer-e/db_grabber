

CREATE PROC [finAnalytics].[sys_infoEntries]
	@dt varchar(5),@kt varchar(5), @answer nvarchar(2000) out 
AS
BEGIN
	set @answer =null
	declare @searchCount int
		
	set @answer = (select concat(
						'СубконтоCt1_Ссылка=',Ct1,char(13)
						,'СубконтоCt2_Ссылка=',Ct2,char(13)
						,'СубконтоCt3_Ссылка=',Ct3,char(13)
						,'СубконтоDt1_Ссылка=',Dt1,char(13)
						,'СубконтоDt2_Ссылка=',Dt2,char(13)
						,'СубконтоDt3_Ссылка=',Dt3,char(13)
						)
					from dwh2.finAnalytics.SYS_SPR_entries where  dt=@dt and kt=@kt)
	if @answer is null 
		begin
			--проверяем проводку на пристутвие
			set @searchCount=(
								select
									count(*)
								from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
								left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
								left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00
								where (b.Код =@dt and c.Код =@kt)		
							)
			if @searchCount=0 
				begin
					set @answer='Такого вида проводок в РегистрБухгалтерии_БНФОБанковский не существует!'	
				end
			else
				begin
					--добавляе проводку
					insert into dwh2.finAnalytics.SYS_SPR_entries (dt,kt,Ct1,Ct2,Ct3,Dt1,Dt2,Dt3,id,dateUpdateLink)
					values (@dt,@kt,'','','','','','',0,null)
					--собираем информацию по субконто
					declare @columnSearch nvarchar(20)='Ссылка'
					--формируем таблицу таблиц для поиска	
					drop table if exists #testListTable
					create table #testListTable (id int identity(1,1),tablename varchar(100), columnname varchar(100))
					insert into #testListTable
					select
						table_name
						,column_name
					from stg.[INFORMATION_SCHEMA].columns with (nolock)
					where Table_schema='_1cUMFO' 	
					 and column_name=@columnSearch and Table_name not like '%_upd%'
					declare @countTest int =(select count(*) from #testListTable)

					--обновляем индексы таблицы dwh2.finAnalytics.SYS_SPR_entries
					drop table if exists #index
					create table #index (id int identity (1,1),dt varchar(5),kt varchar(5))
					insert into #index (dt,kt)
						select 
							dt
							,kt 
						from dwh2.finAnalytics.SYS_SPR_entries
					merge dwh2.finAnalytics.SYS_SPR_entries tgt
					using #index src
						on tgt.dt=src.dt and tgt.kt=src.kt
							when matched then
								update set tgt.id=src.id;
					---
					declare @rowtest int =500
					declare @contEntries int =(select count(*) from dwh2.finAnalytics.SYS_SPR_entries)
					declare @i int =0, @j int =0 
					declare @Ct1 binary(16),@Ct2 binary(16),@Ct3 binary(16),@Dt1 binary(16),@Dt2 binary(16),@Dt3 binary(16)
					declare @sqlString nvarchar(2000),@paramDef nvarchar(200), @result binary(16),@table nvarchar(200), @tablename nvarchar(200)

					select @i=id from dwh2.finAnalytics.SYS_SPR_entries where dateUpdateLink is null
					-- формируем таблицу из @rowtest строк чтобы иcчключить вариант пустых ссылок в проводке
					drop table if exists #testEntriesBnfo
					select top(@rowtest)
							СубконтоCt1_Ссылка=a.СубконтоCt1_Ссылка
							,СубконтоCt2_Ссылка=a.СубконтоCt2_Ссылка
							,СубконтоCt3_Ссылка=a.СубконтоCt3_Ссылка
							,СубконтоDt1_Ссылка=a.СубконтоDt1_Ссылка
							,СубконтоDt2_Ссылка=a.СубконтоDt2_Ссылка
							,СубконтоDt3_Ссылка=a.СубконтоDt3_Ссылка
					into #testEntriesBnfo
					from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
					left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетДт=b.Ссылка and b.ПометкаУдаления=0x00
					left join stg._1cUMFO.ПланСчетов_БНФОБанковский c on a.СчетКт=c.Ссылка and c.ПометкаУдаления=0x00
					where (b.Код=@dt and c.Код=@kt)
							and a.Активность=0x01
					order by a.Период desc
					set @Ct1=(select top(1) СубконтоCt1_Ссылка from #testEntriesBnfo where СубконтоCt1_Ссылка is not null and СубконтоCt1_Ссылка!=convert (binary(16),0))
					set @Ct2=(select top(1) СубконтоCt2_Ссылка from #testEntriesBnfo where СубконтоCt2_Ссылка is not null and СубконтоCt2_Ссылка!=convert (binary(16),0))
					set @Ct3=(select top(1) СубконтоCt3_Ссылка from #testEntriesBnfo where СубконтоCt3_Ссылка is not null and СубконтоCt3_Ссылка!=convert (binary(16),0))
					set @Dt1=(select top(1) СубконтоDt1_Ссылка from #testEntriesBnfo where СубконтоDt1_Ссылка is not null and СубконтоDt1_Ссылка!=convert (binary(16),0))
					set @Dt2=(select top(1) СубконтоDt2_Ссылка from #testEntriesBnfo where СубконтоDt2_Ссылка is not null and СубконтоDt2_Ссылка!=convert (binary(16),0))
					set @Dt3=(select top(1) СубконтоDt3_Ссылка from #testEntriesBnfo where СубконтоDt3_Ссылка is not null and СубконтоDt3_Ссылка!=convert (binary(16),0))
					--------Ct1
					set @result=null
						if @Ct1 is not null 
							begin
								set @j=@countTest
								while @j >0
									begin
										set @tablename=(select tablename from #testListTable where id=@j)
										set @table=concat('stg._1cUMFO.',@tablename)
										set @sqlString=concat('select top(1) @resultOut=',@columnSearch,' FROM  ',@table,' where ',@columnSearch,'=@link')
										set @paramDef = '@link binary(16),@resultOut binary(16) output'
										exec sp_executesql 	@sqlString,@paramDef,@link=@Ct1,@resultOut=@result output
										if @result is not null break
										set @j=@j-1
									end;
								end
					update dwh2.finAnalytics.SYS_SPR_entries
						set Ct1=iif(@result is not null,@table,iif(@Ct1 is null or convert(int,@Ct1)=0,'пусто','нет связи'))
							,dateUpdateLink=getdate()
							,idCt1=(select stg_id from dwh2.finAnalytics.SYS_SPR_stg where stgname=@tablename )
					where id=@i
					----------Ct2
					set @result=null
						if @Ct2 is not null 
							begin
								set @j=@countTest
								while @j >0
									begin
										set @tablename=(select tablename from #testListTable where id=@j)
										set @table=concat('stg._1cUMFO.',@tablename)
										set @sqlString=concat('select top(1) @resultOut=',@columnSearch,' FROM  ',@table,' where ',@columnSearch,'=@link')
										set @paramDef = '@link binary(16),@resultOut binary(16) output'
										exec sp_executesql 	@sqlString,@paramDef,@link=@Ct2,@resultOut=@result output
										if @result is not null break
										set @j=@j-1
									end;
							end
					update dwh2.finAnalytics.SYS_SPR_entries
							set Ct2=iif(@result is not null,@table,iif(@Ct2 is null or convert(int,@Ct2)=0,'пусто','нет связи'))
							,dateUpdateLink=getdate()
							,idCt2=(select stg_id from dwh2.finAnalytics.SYS_SPR_stg where stgname=@tablename )
					where id=@i
					----------Ct3
					set @result=null
						if @Ct3 is not null 
							begin
								set @j=@countTest
								while @j >0
									begin
										set @tablename=(select tablename from #testListTable where id=@j)
										set @table=concat('stg._1cUMFO.',@tablename)
										set @sqlString=concat('select top(1) @resultOut=',@columnSearch,' FROM  ',@table,' where ',@columnSearch,'=@link')
										set @paramDef = '@link binary(16),@resultOut binary(16) output'
										exec sp_executesql 	@sqlString,@paramDef,@link=@Ct3,@resultOut=@result output
										if @result is not null break
										set @j=@j-1
									end;
							end
					update dwh2.finAnalytics.SYS_SPR_entries
							set Ct3=iif(@result is not null,@table,iif(@Ct3 is null or convert(int,@Ct3)=0,'пусто','нет связи'))
							,dateUpdateLink=getdate()
							,idCt3=(select stg_id from dwh2.finAnalytics.SYS_SPR_stg where stgname=@tablename )
					where id=@i
					----------Dt1
					set @result=null
						if @Dt1 is not null 
							begin
								set @j=@countTest
								while @j >0
									begin
										set @tablename=(select tablename from #testListTable where id=@j)
										set @table=concat('stg._1cUMFO.',@tablename)
										set @sqlString=concat('select top(1) @resultOut=',@columnSearch,' FROM  ',@table,' where ',@columnSearch,'=@link')
										set @paramDef = '@link binary(16),@resultOut binary(16) output'
										exec sp_executesql 	@sqlString,@paramDef,@link=@Dt1,@resultOut=@result output
										if @result is not null break
										set @j=@j-1
									end;
							end
					update dwh2.finAnalytics.SYS_SPR_entries
							set Dt1=iif(@result is not null,@table,iif(@Dt1 is null or convert(int,@Dt1)=0,'пусто','нет связи'))
							,dateUpdateLink=getdate()
							,idDt1=(select stg_id from dwh2.finAnalytics.SYS_SPR_stg where stgname=@tablename )
					where id=@i
					----------Dt2
					set @result=null
						if @Dt2 is not null 
							begin
								set @j=@countTest
								while @j >0
									begin
										set @tablename=(select tablename from #testListTable where id=@j)
										set @table=concat('stg._1cUMFO.',@tablename)
										set @sqlString=concat('select top(1) @resultOut=',@columnSearch,' FROM  ',@table,' where ',@columnSearch,'=@link')
										set @paramDef = '@link binary(16),@resultOut binary(16) output'
										exec sp_executesql 	@sqlString,@paramDef,@link=@Dt2,@resultOut=@result output
										if @result is not null break
										set @j=@j-1
									end;
							end
					update dwh2.finAnalytics.SYS_SPR_entries
							set Dt2=iif(@result is not null,@table,iif(@Dt2 is null or convert(int,@Dt2)=0,'пусто','нет связи'))
							,dateUpdateLink=getdate()
							,idDt2=(select stg_id from dwh2.finAnalytics.SYS_SPR_stg where stgname=@tablename )
					where id=@i
					----------Dt3
					set @result=null
						if @Dt3 is not null 
							begin
								set @j=@countTest
								while @j >0
									begin
										set @tablename=(select tablename from #testListTable where id=@j)
										set @table=concat('stg._1cUMFO.',@tablename)
										set @sqlString=concat('select top(1) @resultOut=',@columnSearch,' FROM  ',@table,' where ',@columnSearch,'=@link')
										set @paramDef = '@link binary(16),@resultOut binary(16) output'
										exec sp_executesql 	@sqlString,@paramDef,@link=@Dt3,@resultOut=@result output
										if @result is not null break
										set @j=@j-1
									end;
							end
					update dwh2.finAnalytics.SYS_SPR_entries
							set Dt3=iif(@result is not null,@table,iif(@Dt3 is null or convert(int,@Dt3)=0,'пусто','нет связи'))
							,dateUpdateLink=getdate()
							,idDt3=(select stg_id from dwh2.finAnalytics.SYS_SPR_stg where stgname=@tablename )
					where id=@i
					set @answer = (select concat(
						'СубконтоCt1_Ссылка=',Ct1,char(13)
						,'СубконтоCt2_Ссылка=',Ct2,char(13)
						,'СубконтоCt3_Ссылка=',Ct3,char(13)
						,'СубконтоDt1_Ссылка=',Dt1,char(13)
						,'СубконтоDt2_Ссылка=',Dt2,char(13)
						,'СубконтоDt3_Ссылка=',Dt3,char(13)
						)
					from dwh2.finAnalytics.SYS_SPR_entries where  dt=@dt and kt=@kt)
				end
		end


END
