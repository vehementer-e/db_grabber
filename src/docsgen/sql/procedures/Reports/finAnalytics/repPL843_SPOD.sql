





CREATE PROCEDURE [finAnalytics].[repPL843_SPOD]
	@repMonthTo date,
	@selector int


AS
BEGIN
/*
	drop Table if exists #rep

select
repYear	
,rowNum	
,rowName	
,pokazatel	
,aplicator	
,BSAcc	
,symbolName	
,sumAmount = isnull(b.[sumAmount],c.[sumAmount])

into #rep

from(

select
repYear = DATEFROMPARTS(year(@repMonthTo),1,1)
,rowNum	
,rowName	
,pokazatel	
,aplicator	
,BSAcc	 = concat(
					substring(BSAcc,1,1)
					,'2'
					,substring(BSAcc,3,3)
				)
,symbolName
,[sumAmount] = 0

from [dwh2].[finAnalytics].[SPR_repPLf843] a
) l1

left join (
			select
			[repmonth]
			,[accCode]
			,[simbol3]
			,[sumAmount] = sum([sumAmount])
			from [dwh2].[finAnalytics].[repPLf843SPODfact] 
			group by 
			[repmonth]
			,[accCode]
			,[simbol3]
			
			)b on year(@repMonthTo) = year(b.[repmonth]) 
													and l1.BSAcc = b.[accCode] 
													and l1.symbolName = b.[simbol3]
left join (
			select
			[repmonth]
			,[accCode]
			,[simbol5]
			,[sumAmount] = sum([sumAmount])
			from [dwh2].[finAnalytics].[repPLf843SPODfact] 
			group by 
			[repmonth]
			,[accCode]
			,[simbol5]
			) c on year(@repMonthTo) = year(c.[repmonth]) 
													and l1.BSAcc = c.[accCode] 
													and l1.symbolName = c.[simbol5]


/*Расчет агрегированных строк*/

	--rowNum=3
	merge into #rep t1
	using(
		select [sumAmount] = isnull(sum(isnull([sumAmount],0)),0)
		from #rep
		where rowName in ('1.1','1.2','1.3','1.4','1.5','1.6')
	) t2 on (t1.[rowNum]=3)
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=10
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where rowName in ('2.1','2.2','2.3','2.4','2.5','2.6')
	) t2 on (t1.[rowNum]=10 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=17
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('1','2')
	) t2 on (t1.[rowNum]=17 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=19
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('5.1','5.2','5.3','5.4','5.5','5.6','5.7','5.8','5.9','5.10')
	) t2 on (t1.[rowNum]=19 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=30
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('6.1','6.2','6.3','6.4')
	) t2 on (t1.[rowNum]=30 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=18
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('5','6')
	) t2 on (t1.[rowNum]=18 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=35
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('3','4')
	) t2 on (t1.[rowNum]=35 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=37
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('8.1','8.2','8.3','8.4','8.5','8.6','8.7','8.8','8.9','8.10','8.11','8.12','8.13','8.14','8.15',
						'8.16','8.17','8.18','8.19','8.20','8.21','8.22','8.23','8.24','8.25','8.26','8.27','8.28','8.29',
						'8.30','8.31','8.32','8.33','8.34','8.35','8.36','8.37','8.38','8.39','8.40','8.41','8.42','8.43',
						'8.44','8.45','8.46','8.47','8.48','8.49','8.50','8.51','8.52','8.53','8.54','8.55','8.56','8.57',
						'8.58','8.59','8.60','8.61','8.62','8.63','8.64','8.65','8.66','8.67','8.68','8.69','8.70','8.71',
						'8.72','8.73','8.74','8.75','8.76','8.77','8.78','8.79','8.80','8.81','8.82','8.83','8.84','8.85',
						'8.86','8.87','8.88','8.89','8.90','8.91','8.92','8.93','8.94','8.95','8.96','8.97','8.98','8.99',
						'8.100','8.101','8.102','8.103','8.104','8.105','8.106','8.107','8.108','8.109','8.110','8.111','8.112',
						'8.113','8.114','8.115','8.116','8.117','8.118','8.119','8.120','8.121','8.122','8.123','8.124','8.125',
						'8.126','8.127','8.128','8.129','8.130','8.131','8.132','8.133')
	) t2 on (t1.[rowNum]=37 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=171
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('9.1','9.2','9.3','9.4','9.5','9.6','9.7','9.8','9.9','9.10','9.11','9.12','9.13','9.14','9.15',
						'9.16','9.17','9.18','9.19','9.20','9.21','9.22','9.23','9.24','9.25','9.26','9.27','9.28','9.29',
						'9.30','9.31','9.32','9.33','9.34','9.35','9.36','9.37','9.38','9.39','9.40','9.41','9.42','9.43',
						'9.44','9.45','9.46','9.47','9.48','9.49','9.50','9.51','9.52','9.53','9.54','9.55','9.56','9.57',
						'9.58','9.59','9.60','9.61','9.62','9.63','9.64','9.65','9.66','9.67','9.68','9.69','9.70','9.71',
						'9.72','9.73','9.74','9.75','9.76','9.77','9.78','9.79','9.80','9.81','9.82','9.83','9.84','9.85',
						'9.86','9.87','9.88','9.89','9.90','9.91','9.92','9.93','9.94','9.95','9.96','9.97','9.98','9.99','9.100')
	) t2 on (t1.[rowNum]=171 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=272
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('10.1','10.2','10.3','10.4','10.5','10.6','10.7','10.8','10.9','10.10','10.11','10.12','10.13','10.14','10.15',
						'10.16','10.17','10.18','10.19','10.20','10.21','10.22','10.23','10.24','10.25','10.26','10.27','10.28','10.29',
						'10.30','10.31','10.32','10.33','10.34','10.35','10.36','10.37','10.38','10.39','10.40','10.41','10.42','10.43',
						'10.44','10.45','10.46','10.47','10.48','10.49','10.50','10.51','10.52','10.53','10.54','10.55','10.56','10.57',
						'10.58','10.59','10.60','10.61','10.62','10.63','10.64','10.65','10.66','10.67','10.68','10.69','10.70','10.71',
						'10.72','10.73','10.74','10.75','10.76','10.77','10.78','10.79','10.80','10.81','10.82','10.83','10.84','10.85',
						'10.86','10.87','10.88','10.89','10.90','10.91','10.92','10.93','10.94','10.95','10.96','10.97')
	) t2 on (t1.[rowNum]=272 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=370
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('11.1','11.2','11.3','11.4','11.5')
	) t2 on (t1.[rowNum]=370 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=376
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('12.1','12.2','12.3','12.4')
	) t2 on (t1.[rowNum]=376 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=382
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName = '13.2' then abs([sumAmount])
									 when rowName = '13.3' then abs([sumAmount])
									 when rowName = '13.4' then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName = '13.2' then abs([sumAmount])
												when rowName = '13.3' then abs([sumAmount])
												when rowName = '13.4' then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('13.2','13.3','13.4')
	) t2 on (t1.[rowNum]=382 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=386
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName = '13.6' then abs([sumAmount])
									 when rowName = '13.7' then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName = '13.6' then abs([sumAmount])
												when rowName = '13.7' then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('13.6','13.7')
	) t2 on (t1.[rowNum]=386 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=389
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('13.9','13.10','13.11') then abs([sumAmount])
									 when rowName in ('13.12','13.13','13.14') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('13.9','13.10','13.11') then abs([sumAmount])
									 when rowName in ('13.12','13.13','13.14') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('13.9','13.10','13.11','13.12','13.13','13.14')
	) t2 on (t1.[rowNum]=389 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=397
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('13.17','13.19','13.20') then abs([sumAmount])
									 when rowName in ('13.18','13.21') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('13.17','13.19','13.20') then abs([sumAmount])
											 when rowName in ('13.18','13.21') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('13.17','13.18','13.19','13.20','13.21','13.22','13.23','13.24','13.25','13.26')
	) t2 on (t1.[rowNum]=397 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=396
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('13.16','13.22','13.23','13.24','13.25','13.26')
	) t2 on (t1.[rowNum]=396 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=381
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('13.1','13.5','13.8','13.15')
	) t2 on (t1.[rowNum]=381 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=408
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('14.1','14.2')
	) t2 on (t1.[rowNum]=408 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=412
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.2') then abs([sumAmount])
									 when rowName in ('15.3','15.4') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.2') then abs([sumAmount])
									 when rowName in ('15.3','15.4') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('15.2','15.3','15.4')
	) t2 on (t1.[rowNum]=412 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=416
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.6') then abs([sumAmount])
									 when rowName in ('15.7') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.6') then abs([sumAmount])
											when rowName in ('15.7') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('15.6','15.7')
	) t2 on (t1.[rowNum]=416 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=419
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.9','15.10','15.11') then abs([sumAmount])
									 when rowName in ('15.12','15.13','15.14') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.9','15.10','15.11') then abs([sumAmount])
											when rowName in ('15.12','15.13','15.14') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('15.9','15.10','15.11','15.12','15.13','15.14')
	) t2 on (t1.[rowNum]=419 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=426
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.19','15.20','15.21') then abs([sumAmount])
									 when rowName in ('15.16','15.17','15.18') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.19','15.20','15.21') then abs([sumAmount])
											when rowName in ('15.16','15.17','15.18') then abs([sumAmount]) * -1
										end
										) --* -1
							else 0 
							end
		from #rep
		where 
		rowName in ('15.16','15.17','15.18','15.19','15.20','15.21')
	) t2 on (t1.[rowNum]=426 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=433
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.23','15.24','15.25','15.26','15.26.1','15.27','15.28','15.29','15.30') then abs([sumAmount])
									 when rowName in ('15.31','15.32') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.23','15.24','15.25','15.26','15.26.1','15.27','15.28','15.29','15.30') then abs([sumAmount])
											when rowName in ('15.31','15.32') then abs([sumAmount]) * -1
										end
										) --* -1
							else 0 
							end
		from #rep
		where 
		rowName in ('15.23','15.24','15.25','15.26','15.26.1','15.27','15.28','15.29','15.30','15.31','15.32')
	) t2 on (t1.[rowNum]=433 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=445
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.34','15.35') then abs([sumAmount])
									 when rowName in ('15.36','15.37') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.34','15.35') then abs([sumAmount])
											when rowName in ('15.36','15.37') then abs([sumAmount]) * -1
										end
										) --* -1
							else 0 
							end
		from #rep
		where 
		rowName in ('15.34','15.35','15.36','15.37')
	) t2 on (t1.[rowNum]=445 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=450
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.39') then abs([sumAmount])
									 when rowName in ('15.40','15.41') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.39') then abs([sumAmount])
											 when rowName in ('15.40','15.41') then abs([sumAmount]) * -1
										end
										) --* -1
										+
										sum(
										case when rowName in ('15.42','15.43','15.44','15.45','15.46','15.47','15.48','15.49',
												'15.50','15.51','15.52','15.53','15.54','15.55','15.56','15.57','15.58','15.59','15.60',
												'15.61','15.62','15.63','15.64','15.65') then abs([sumAmount])
										end
										)

							else 0 
							+
										sum(
										case when rowName in ('15.42','15.43','15.44','15.45','15.46','15.47','15.48','15.49',
												'15.50','15.51','15.52','15.53','15.54','15.55','15.56','15.57','15.58','15.59','15.60',
												'15.61','15.62','15.63','15.64','15.65') then abs([sumAmount])
										end
										)
							end
		from #rep
		where 
		rowName in ('15.39','15.40','15.41','15.42','15.43','15.44','15.45','15.46','15.47','15.48','15.49',
						'15.50','15.51','15.52','15.53','15.54','15.55','15.56','15.57','15.58','15.59','15.60',
						'15.61','15.62','15.63','15.64','15.65')
	) t2 on (t1.[rowNum]=450 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=478
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('15.67') then abs([sumAmount])
									 when rowName in ('15.68') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('15.67') then abs([sumAmount])
											 when rowName in ('15.68') then abs([sumAmount]) * -1
										end
										) --* -1
										+
										sum(
										case when rowName in ('15.69','15.70','15.71','15.72','15.73') then abs([sumAmount])
										end
										)

							else 0 
							+
										sum(
										case when rowName in ('15.69','15.70','15.71','15.72','15.73') then abs([sumAmount])
										end
										)
							end
		from #rep
		where 
		rowName in ('15.67','15.68','15.69','15.70','15.71','15.72','15.73')
	) t2 on (t1.[rowNum]=478 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=411
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('15.1','15.5','15.8','15.15','15.22','15.33','15.38','15.66')
	) t2 on (t1.[rowNum]=411 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=487
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('16.2','16.3') then abs([sumAmount])
									 when rowName in ('16.4') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('16.2','16.3') then abs([sumAmount])
											 when rowName in ('16.4') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('16.2','16.3','16.4')
	) t2 on (t1.[rowNum]=487 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=491
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('16.6','16.6.1') then abs([sumAmount])
									 when rowName in ('16.7','16.8','16.9','16.10','16.10.1') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('16.6','16.6.1') then abs([sumAmount])
											when rowName in ('16.7','16.8','16.9','16.10','16.10.1') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('16.6','16.6.1','16.7','16.8','16.9','16.10','16.10.1')
	) t2 on (t1.[rowNum]=491 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=499
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('16.12','16.13') then abs([sumAmount])
									 when rowName in ('16.14','16.15') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('16.12','16.13') then abs([sumAmount])
											 when rowName in ('16.14','16.15') then abs([sumAmount]) * -1
										end
										) * -1
							else 0 
							end
		from #rep
		where 
		rowName in ('16.12','16.13','16.14','16.15')
	) t2 on (t1.[rowNum]=499 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=504
	merge into #rep t1
	using(
		select [sumAmount] = case when 
								sum(
								case when rowName in ('16.17') then abs([sumAmount])
									 when rowName in ('16.18') then abs([sumAmount]) * -1
								end
								) > 0 then 
										sum(
										case when rowName in ('16.17') then abs([sumAmount])
											 when rowName in ('16.18') then abs([sumAmount]) * -1
										end
										) * -1
										+
										sum(
										case when rowName in ('16.19','16.20','16.21','16.22','16.23','16.24','16.25','16.26','16.27',
						'16.28','16.29','16.30','16.31','16.32') then abs([sumAmount])
										end
										)

							else 0 
							+
										sum(
										case when rowName in ('16.19','16.20','16.21','16.22','16.23','16.24','16.25','16.26','16.27',
						'16.28','16.29','16.30','16.31','16.32') then abs([sumAmount])
										end
										)
							end
		from #rep
		where 
		rowName in ('16.17','16.18','16.19','16.20','16.21','16.22','16.23','16.24','16.25','16.26','16.27',
						'16.28','16.29','16.30','16.31','16.32')
	) t2 on (t1.[rowNum]=504 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=486
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('16.1','16.5','16.11','16.16')
	) t2 on (t1.[rowNum]=486 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=521
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('8','9','10','11','12','13','14','15','16')
	) t2 on (t1.[rowNum]=521 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=522
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('7','17')
	) t2 on (t1.[rowNum]=522 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=524
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('20.1')
	) t2 on (t1.[rowNum]=524 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=526
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('21.1','21.2')
	) t2 on (t1.[rowNum]=526 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=523
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('20','21')
	) t2 on (t1.[rowNum]=523 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=530
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('18','19','22')
	) t2 on (t1.[rowNum]=530 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=534
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('26.1','26.2')
	) t2 on (t1.[rowNum]=534 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=537
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('27.1','27.2','27.3','27.4')
	) t2 on (t1.[rowNum]=537 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=542
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('28.1','28.2','28.3','28.4')
	) t2 on (t1.[rowNum]=542 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=548
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('30.1','30.2')
	) t2 on (t1.[rowNum]=548 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=551
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('31.1','31.2')
	) t2 on (t1.[rowNum]=551 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=554
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('32.1','32.2')
	) t2 on (t1.[rowNum]=554 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=558
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('34.1','34.2','34.3','34.4','34.5','34.6','34.7','34.8')
	) t2 on (t1.[rowNum]=558 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=567
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('35.1','35.2','35.3','35.4','35.5','35.6','35.7','35.8')
	) t2 on (t1.[rowNum]=567 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=576
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('36.1','36.2')
	) t2 on (t1.[rowNum]=576 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=580
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('38.1','38.2','38.3','38.4')
	) t2 on (t1.[rowNum]=580 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=585
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('39.1','39.2')
	) t2 on (t1.[rowNum]=585 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=592
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('44.1','44.2','44.3','44.4')
	) t2 on (t1.[rowNum]=592 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=597
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('45.1','45.2','45.3','45.4')
	) t2 on (t1.[rowNum]=597 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=602
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('46.1','46.2','46.3','46.4')
	) t2 on (t1.[rowNum]=602 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=607
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('47.1','47.2','47.3','47.4')
	) t2 on (t1.[rowNum]=607 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=613
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('49.1','49.2','49.3','49.4','49.5','49.6','49.7','49.8')
	) t2 on (t1.[rowNum]=613 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=622
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('50.1','50.2','50.3','50.4')
	) t2 on (t1.[rowNum]=622 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=627
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('51.1','51.2','51.3','51.4','51.5','51.6','51.7','51.8')
	) t2 on (t1.[rowNum]=627 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=636
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('52.1','52.2','52.3','52.4')
	) t2 on (t1.[rowNum]=636 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=642
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('54.1','54.2')
	) t2 on (t1.[rowNum]=642 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=645
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('55.1','55.2')
	) t2 on (t1.[rowNum]=645 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=648
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('56.1','56.2')
	) t2 on (t1.[rowNum]=648 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=651
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('57.1','57.2')
	) t2 on (t1.[rowNum]=651 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=654
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('58.1','58.2','58.3','58.4')
	) t2 on (t1.[rowNum]=654 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=659
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('59.1','59.2')
	) t2 on (t1.[rowNum]=659 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=532
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('25','29','33','37','40','41')
	) t2 on (t1.[rowNum]=532 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=533
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('26','27','28')
	) t2 on (t1.[rowNum]=533 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=547
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('30','31','32')
	) t2 on (t1.[rowNum]=547 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=557
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('34','35','36')
	) t2 on (t1.[rowNum]=557 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=579
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('38','39')
	) t2 on (t1.[rowNum]=579 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=590
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('43','48','53','58','59')
	) t2 on (t1.[rowNum]=590 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=591
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('44','45','46','47')
	) t2 on (t1.[rowNum]=591 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=612
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('49','50','51','52')
	) t2 on (t1.[rowNum]=612 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=641
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('54','55','56','57')
	) t2 on (t1.[rowNum]=641 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=662
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('24','42')
	) t2 on (t1.[rowNum]=662 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];

	--rowNum=663
	merge into #rep t1
	using(
		select [sumAmount] = sum([sumAmount])
		from #rep
		where 
		rowName in ('23','60')
	) t2 on (t1.[rowNum]=663 )
	when matched then update
	set t1.[sumAmount]=t2.[sumAmount];
*/
if @selector = 1
begin
/*СПОДЫ Детализация*/
select
repYear	
,rowNum	
,rowName	
,pokazatel	
,aplicator	
,BSAcc	
,symbolName	
,sumAmount = sumAmount/* *-1*/

from dwh2.[finAnalytics].[repPLf843SPOD]
where repYear = DATEFROMPARTS(year(@repMonthTo),1,1)
end

if @selector = 2
begin
/*СПОДЫ Итоги*/
select
repYear	
,rowNum	
,rowName	
,pokazatel	
,aplicator	
,BSAcc	
,symbolName	
,sumAmount = sumAmount/* *-1*/

from dwh2.[finAnalytics].[repPLf843SPOD]
where rowName not like '%.%'
and repYear = DATEFROMPARTS(year(@repMonthTo),1,1)
end    

END
