
CREATE PROC [finAnalytics].[checkRepPublic] 
    @repmonth date
AS
BEGIN
	
    begin try
	
		
	/*Контроли*/
	--8.1_1
	merge into dwh2.finAnalytics.repPublicPL_8_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_1 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_8_2 a
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;

	--8.1_5
	merge into dwh2.finAnalytics.repPublicPL_8_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_1 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) t2 on (t1.rowName = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;


		--8.2_2
	merge into dwh2.finAnalytics.repPublicPL_8_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_2 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) t2 on (t1.rowName = '2' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;


	--5.1_5
	merge into dwh2.finAnalytics.repPublicPL_5_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_5_1 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) t2 on (t1.rowName = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;


		--5.2_1_1
	merge into dwh2.finAnalytics.repPublicPL_5_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_5_2 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_5_1 a
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--5.2_1_2
	merge into dwh2.finAnalytics.repPublicPL_5_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_5_2 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;


		--5.2_3
	merge into dwh2.finAnalytics.repPublicPL_5_2 t1
	using(
		select
		RowName = '3'
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = 'Внимание! Необходим ручной контроль сроков депозитов - не должен превышать 92 дней';


	--8.3_1_1
	merge into dwh2.finAnalytics.repPublicPL_8_3 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)  
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(
								isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)  
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(abs(
								isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)  
								- 
								isnull(b.amountCheck,0))))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol1,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--8.3_1_2
	merge into dwh2.finAnalytics.repPublicPL_8_3 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol2,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;

	--8.3_1_3
	merge into dwh2.finAnalytics.repPublicPL_8_3 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult3 = t2.checkResult;


	--8.3_7_1
	merge into dwh2.finAnalytics.repPublicPL_8_3 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)  
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(
								isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)  
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)  
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol1,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--8.3_7_2
	merge into dwh2.finAnalytics.repPublicPL_8_3 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol2,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;

	--8.3_7_3
	merge into dwh2.finAnalytics.repPublicPL_8_3 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(isnull(a.sumAmountCol7,0) 
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult3 = t2.checkResult;

	--8.4_7_1
	merge into dwh2.finAnalytics.repPublicPL_8_4 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountCol1,0)
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(
								isnull(a.sumAmountCol1,0)
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountCol1,0)
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_4 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol1,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--8.4_7_2
	merge into dwh2.finAnalytics.repPublicPL_8_4 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountCol2,0) 
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(isnull(a.sumAmountCol2,0) 
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountCol2,0) 
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_4 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol2,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;

	--8.4_7_3
	merge into dwh2.finAnalytics.repPublicPL_8_4 t1
	using(
		select
		checkResult = case 
						when abs(
								isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)) < 100 then 'OK'
						when abs(isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)) >= 100 
									then concat('Ошибка', str(isnull(a.sumAmountItog,0) 
								- 
								isnull(b.amountCheck,0)))
					  end
		--,amountRep = isnull(a.sumAmountCol3,0) + isnull(a.sumAmountCol4,0)
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_4 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_8_1 a
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult3 = t2.checkResult;

	--8.1_4
	merge into dwh2.finAnalytics.repPublicPL_8_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_8_1 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_8_4 a
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) t2 on (t1.rowName = '4' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;


	--9.1_3
	merge into dwh2.finAnalytics.repPublicPL_9_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_9_1 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) t2 on (t1.rowName = '3' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;

		--8.6_1
	merge into dwh2.finAnalytics.repPublicPL_8_6 t1
	using(
		select
		Razdel = 1
		) t2 on (t1.razdel = t2.razdel and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = 'Внимание! Необходим ручной контроль, в случае наличия остатка на БС ручной ввод данных';

	--8.6_2
	merge into dwh2.finAnalytics.repPublicPL_8_6 t1
	using(
		select
		Razdel = 2
		) t2 on (t1.razdel = t2.razdel and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = 'Внимание! Необходим ручной ввод данных';

	--8.6_15
	merge into dwh2.finAnalytics.repPublicPL_8_6 t1
	using(
		select
		Razdel = 15
		) t2 on (t1.razdel = t2.razdel and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = 'Внимание! Необходим ручной контроль, в случае наличия остатка на БС ручной ввод данных';

	--8.6_16
	merge into dwh2.finAnalytics.repPublicPL_8_6 t1
	using(
		select
		Razdel = 16
		) t2 on (t1.razdel = t2.razdel and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = 'Внимание! Необходим ручной контроль, в случае наличия остатка на БС ручной ввод данных';

	--17.3_1_1
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountItog,0)
		from dwh2.finAnalytics.repPublicPL_17_3 a
		where a.repmonth = DateFromParts(year(@repmonth)-1,12,1)
		and a.RowName = '5'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--17.3_1_2
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol4,0)
		from dwh2.finAnalytics.repPublicPL_17_1 a
		where a.repmonth = DateFromParts(year(@repmonth)-1,12,1)
		and a.RowName = '13'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;

	--17.3_4
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		Razdel = 4
		) t2 on (t1.razdel = t2.razdel and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = '!Внимание (проверить на наличие прочего движения для ручного ввода)';

	--17.3_5_1
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		amountCheck = isnull(a.sumAmountCol4,0)
		from dwh2.finAnalytics.repPublicPL_17_1 a
		where a.repmonth = @repmonth
		and a.RowName = '13'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) t2 on (t1.rowName = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--17.3_5_2
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
checkResult = case 
						when abs(isnull(l1.amountOSV,0) - isnull(l1.amountRep,0)+isnull(l1.amount84,0)) < 100 
							then 'OK'
						when abs(isnull(l1.amountOSV,0) - isnull(l1.amountRep,0)+isnull(l1.amount84,0)) >= 100 
							then concat('Ошибка', str(isnull(l1.amountOSV,0) - isnull(l1.amountRep,0)+isnull(l1.amount84,0)))
					  end
from(
select
		amountRep = a.sumAmountItog
		,amount84 = b.sumAmountItog
		,amountOSV = c.sumAmountItog
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		[sumAmountItog] = sum([sumAmountItog])
		from dwh2.finAnalytics.repPublicPL_8_4
		where repmonth = @repmonth
		and RowName in ('3.9','5.2','6.3','7.107')
		) b on 1=1
		left join(
		select
		[sumAmountItog] = sum(restOUT_BU*-1)
		from dwh2.finAnalytics.OSV_MONTHLY a
		left join stg.[_1cUMFO].[Справочник_ДоговорыКонтрагентов] d on a.subconto2UID = d.ссылка
		left join stg.[_1cUMFO].[Справочник_БНФОГруппыФинансовогоУчетаРасчетов] g on d.БНФОГруппаФинансовогоУчета=g.ссылка
		where a.repMonth = @repmonth
		and (
			acc2order = '47425'
			or (acc2order = '60324'
			and g.Наименование in ('60311,60312_Расчеты с поставщиками и подрядчиками'
							  ,'60322,60323_Расчеты с прочими дебиторами и кредиторами'
							  ,'60324_Резервы под обесценение'
							  )
				)
		)
		) c on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
) l1
		) t2 on (t1.razdel = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;


		--17.5_2
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol7],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol7],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol7],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountCol7],0))
		from dwh2.finAnalytics.repPublicPL_17_3 a
		where a.repmonth = @repmonth
		and rowName in ('1.2','2.3','2.4','3.2')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5.2'
		) t2 on (t1.rowName = '5.2' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


		--17.5_3
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountCol9],0))
		from dwh2.finAnalytics.repPublicPL_17_3 a
		where a.repmonth = @repmonth
		and rowName in ('1.3','2.5','2.6','3.3')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5.3'
		) t2 on (t1.rowName = '5.3' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


		--17.5_4
	merge into dwh2.finAnalytics.repPublicPL_17_3 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_3 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountCol9],0))
		from dwh2.finAnalytics.repPublicPL_17_3 a
		where a.repmonth = @repmonth
		and rowName in ('1.4','2.7','2.8','3.4')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5.4'
		) t2 on (t1.rowName = '5.4' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


		--17.1_13_1
	merge into dwh2.finAnalytics.repPublicPL_17_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_1 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '14'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '13'
		) t2 on (t1.rowName = '13' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--17.1_13_2
	merge into dwh2.finAnalytics.repPublicPL_17_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol4],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol4],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol4],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_17_1 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountCol9],0))
		from dwh2.finAnalytics.repPublicPL_17_3 a
		where a.repmonth = @repmonth
		and rowName in ('5')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '13'
		) t2 on (t1.rowName = '13' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;

	--19.1_2_1
	merge into dwh2.finAnalytics.repPublicPL_19_1 t1
	using(
		select
checkResult = case 
	when abs(isnull(l1.sumAmountItog,0) - isnull(l2.amountCheck,0)) < 100 
							then 'OK'
	when abs(isnull(l1.sumAmountItog,0) - isnull(l2.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(l1.sumAmountItog,0) - isnull(l2.amountCheck,0)))
				end
from(
		select
		sumAmountItog = abs(sum(isnull(a.sumAmountItog,0)))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and a.RowName in ('2.1',',2.2','2.3','2.4','2.5','2.7','2.8','2.9','2.10','2.12')
) l1

left join (
select
amountCheck = sum(isnull(restOD,0) + isnull(restPRC,0))
from dwh2.finAnalytics.DEPO_MONTHLY a
where a.repMonth = @repmonth
and clientType = 'КО'
) l2 on 1=1
		) t2 on (t1.rowName = '2' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.1_3_1
	merge into dwh2.finAnalytics.repPublicPL_19_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_1 a
		left join (
		select
		amountCheck = sum(isnull(restOD,0) + isnull(restPRC,0))
		from dwh2.finAnalytics.DEPO_MONTHLY a
		where a.repMonth = @repmonth
		and clientType = 'ЮЛ'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) t2 on (t1.rowName = '3' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--19.1_4_1
	merge into dwh2.finAnalytics.repPublicPL_19_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_1 a
		left join (
		select
		amountCheck = sum(isnull(restOD,0) + isnull(restPRC,0))
		from dwh2.finAnalytics.DEPO_MONTHLY a
		where a.repMonth = @repmonth
		and clientType = 'ФЛ'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) t2 on (t1.rowName = '4' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--19.1_5_1
	merge into dwh2.finAnalytics.repPublicPL_19_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_1 a
		left join (
		select
		amountCheck = sum(isnull(restOD,0) + isnull(restPRC,0))
		from dwh2.finAnalytics.DEPO_MONTHLY a
		where a.repMonth = @repmonth
		and clientType = 'ИП'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) t2 on (t1.rowName = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--19.1_8
	merge into dwh2.finAnalytics.repPublicPL_19_1 t1
	using(
		select rowName = '8.1'
		union all
		select rowName = '8.2'
		union all
		select rowName = '8.3'
		union all
		select rowName = '8.4'
		union all
		select rowName = '8.5'
		union all
		select rowName = '8.6'
		union all
		select rowName = '8.7'
		union all
		select rowName = '8.8'
		union all
		select rowName = '8.9'
		union all
		select rowName = '8.10'
		union all
		select rowName = '8.11'
		union all
		select rowName = '8.12'
		union all
		select rowName = '8.13'
		union all
		select rowName = '8.14'
		union all
		select rowName = '8.15'
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = '! Внимание (в случае признания кредиторской задолжностью)';

		--19.1_10_2
	merge into dwh2.finAnalytics.repPublicPL_19_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_1 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '17'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '10'
		) t2 on (t1.rowName = '10' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;


		--19.2_6-8
	merge into dwh2.finAnalytics.repPublicPL_19_2 t1
	using(
		select rowName = '6', checkResult = 'Внимание! Необходим ручной ввод данных на основании данных предоставленных от подразделения '
		union all
		select rowName = '7', checkResult = 'Внимание! Необходим ручной ввод данных графа 3 по данным из Графика по выпускам облигаций '
		union all
		select rowName = '8', checkResult = 'Внимание! Необходим ручной контроль, в случае наличия остатка в строке 8 графа 3 Таблица 19.1'
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult = t2.checkResult;
    
	
	--19.4_1_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('2')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_1_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('2')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	


		--19.4_2_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('3')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) t2 on (t1.rowName = '2' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_2_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('3')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) t2 on (t1.rowName = '2' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	
	
	--19.4_3_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('4')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) t2 on (t1.rowName = '3' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_3_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('4')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '3'
		) t2 on (t1.rowName = '3' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	
	
	--19.4_4_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('5')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) t2 on (t1.rowName = '4' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_4_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('5')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) t2 on (t1.rowName = '4' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	

		--19.4_6_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('6')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) t2 on (t1.rowName = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_6_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('6')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '5'
		) t2 on (t1.rowName = '5' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	

		--19.4_6_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('7')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '6'
		) t2 on (t1.rowName = '6' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_6_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('7')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '6'
		) t2 on (t1.rowName = '6' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	

		--19.4_7_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('8')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_7_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('8')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '7'
		) t2 on (t1.rowName = '7' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;
		
		--19.4_8_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('9')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '8'
		) t2 on (t1.rowName = '8' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_8_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('9')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '8'
		) t2 on (t1.rowName = '8' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	

		--19.4_9_1
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol3],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = datefromParts(year(@repmonth)-1,12,1)
		and rowName in ('10')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '9'
		) t2 on (t1.rowName = '9' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;	

		--19.4_9_2
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol10],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_19_4 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('10')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '9'
		) t2 on (t1.rowName = '9' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult2 = t2.checkResult;	

		--19.7_7
	merge into dwh2.finAnalytics.repPublicPL_19_4 t1
	using(
		select checkResult = '! Внимание (в случае признания кредиторской задолжностью)'
		) t2 on (t1.rowName in ('7.1','7.2','7.3','7.4','7.5','7.6','7.7','7.8','7.9','7.10','7.11','7.12','7.13','7.14','7.15') and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--21.1_9
	merge into dwh2.finAnalytics.repPublicPL_21_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_21_1 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '22'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '9'
		) t2 on (t1.rowName = '9' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--21.1_6.1,8.4
	merge into dwh2.finAnalytics.repPublicPL_21_1 t1
	using(
		select rowName = '6.1', checkResult = 'Внимание! В случае остатка на счете 60331 необходим ручной контроль отбора данных для отражения либо в строке 6 либо в строке 8'
		union all
		select rowName = '8.4', checkResult = 'Внимание! В случае остатка на счете 60331 необходим ручной контроль отбора данных для отражения либо в строке 8 либо в строке 6'
		) t2 on (t1.rowName =t2.RowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


		--25.1_23
	merge into dwh2.finAnalytics.repPublicPL_25_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф843'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_25_1 a
		left join (
		select
		amountCheck = a.sumAmount
		from [dwh2].[finAnalytics].[repPLf843] a
		where a.repmonth = @repmonth
		and a.RowName = '22'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '23' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


		--26.1_9.3,14.2
	merge into dwh2.finAnalytics.repPublicPL_26_1 t1
	using(
		select rowName = '9.3', checkResult = 'Внимание! Необходим ручной контроль, в случае наличия арендных обязательств кредитных организаций'
		union all
		select rowName = '14.2', checkResult = 'Внимание! Необходим ручной контроль, в случае наличия арендных обязательств кредитных организаций'
		) t2 on (t1.rowName =t2.RowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


		--26.1_16
	merge into dwh2.finAnalytics.repPublicPL_26_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф843'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_26_1 a
		left join (
		select
		amountCheck = a.sumAmount
		from [dwh2].[finAnalytics].[repPLf843] a
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '16'
		) t2 on (t1.rowName = '16' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--31.1_2
	merge into dwh2.finAnalytics.repPublicPL_31_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_31_1 a
		left join (
		select
		amountCheck = sum(amountCess)*-1
		from(
		select
		amountCess = isnull(sum(isnull(a.finreservBU,0)),0)
		from dwh2.[finAnalytics].[ReestrCession] a
		where a.REPDATE between DATEFROMPARTS(year(@repmonth),1,1)  and EOMONTH(@repmonth)--@repmonth and EOMONTH(@repmonth)--DATEFROMPARTS(year(@repmonth),1,1)  and EOMONTH(@repmonth)
		union all
		select
		amountBack = isnull(sum(isnull(a.finreservBU,0)),0)*-1
		from dwh2.[finAnalytics].[ReestrCession] a
		where a.dateBack between DATEFROMPARTS(year(@repmonth),1,1)  and EOMONTH(@repmonth)--@repmonth and EOMONTH(@repmonth)--DATEFROMPARTS(year(@repmonth),1,1)  and EOMONTH(@repmonth)
		union all
		select
		amountChange = isnull(sum(isnull(a.newFinreservBU,0)),0)
					-	isnull(sum(isnull(a.finreservBU,0)),0)
		from dwh2.[finAnalytics].[ReestrCession] a
		where a.dateChangePrice between DATEFROMPARTS(year(@repmonth),1,1)  and EOMONTH(@repmonth)--@repmonth and EOMONTH(@repmonth)--DATEFROMPARTS(year(@repmonth),1,1)  and EOMONTH(@repmonth)
		) l1
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '2'
		) t2 on (t1.rowName = '2' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		
	--40.2_1
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_2 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '1'
		) t2 on (t1.rowName = '1' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_4
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_2 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '4'
		) t2 on (t1.rowName = '4' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_8
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_2 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '14'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '8'
		) t2 on (t1.rowName = '8' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_14
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_2 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '17'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '14'
		) t2 on (t1.rowName = '14' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_4.1-4.348
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		a.rowName
		,checkResult = case 
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol6],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_2 a
		left join (
		select
		rowName
		,amountCheck = a.[sumAmountCol3]
					+	a.[sumAmountCol4]
					+	a.[sumAmountCol5]
		from [dwh2].[finAnalytics].repPublicPL_40_2 a
		where a.repmonth = @repmonth
		and a.RowName not in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15')
		) b on a.rowName=b.rowName
		where a.repmonth = @repmonth
		and a.RowName not in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15')
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_11.99-11.109
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		a.rowName
		,checkResult = 'Графа 3-5 необходим ручной ввод данных на основании данных предоставленных от подразделения'
		from dwh2.finAnalytics.repPublicPL_40_2 a
		where a.repmonth = @repmonth
		and a.RowName in ('11.99','11.100','11.101','11.102','11.103','11.104','11.105','11.106','11.107','11.108','11.109')
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_11.99-11.109
	merge into dwh2.finAnalytics.repPublicPL_40_2 t1
	using(
		select
		a.rowName
		,checkResult = 'Графа 3-5 необходим ручной ввод данных на основании данных предоставленных от подразделения'
		from dwh2.finAnalytics.repPublicPL_40_2 a
		where a.repmonth = @repmonth
		and a.RowName in ('11.110','11.111','11.112','11.113','11.114','11.115','11.116','11.117','11.118','11.119','11.120'
						 ,'11.121','11.122','11.123','11.124')
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--31.1_14
	merge into dwh2.finAnalytics.repPublicPL_31_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф843'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_31_1 a
		left join (
		select
		amountCheck = a.sumAmount
		from [dwh2].[finAnalytics].[repPLf843] a
		where a.repmonth = @repmonth
		and a.RowName = '10'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '14'
		) t2 on (t1.rowName = '14' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

		--33.1_20
	merge into dwh2.finAnalytics.repPublicPL_33_1 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф843'
						when abs(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.sumAmountItog,0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_33_1 a
		left join (
		select
		amountCheck = a.sumAmount
		from [dwh2].[finAnalytics].[repPLf843] a
		where a.repmonth = @repmonth
		and a.RowName = '13'
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '20'
		) t2 on (t1.rowName = '20' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;


	--40.8_11
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_8 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('1')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '11'
		) t2 on (t1.rowName = '11' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.8_11.1-11.98
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		a.rowName
		,checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when b.amountCheck is null 
							then 'Нет данных ф842'
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_8 a
		left join (
		select
		rowName
		,amountCheck = a.[sumAmountCol3]
					+	a.[sumAmountCol4]
					+	a.[sumAmountCol5]
					+	a.[sumAmountCol6]
					+	a.[sumAmountCol7]
					+	a.[sumAmountCol8]
		from [dwh2].[finAnalytics].repPublicPL_40_8 a
		where a.repmonth = @repmonth
		and a.razdel = 11 and a.RowName != '11'
		) b on a.rowName=b.rowName
		where a.repmonth = @repmonth
		and a.razdel = 11 and a.RowName != '11'
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;
	
	--40.8_13
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_8 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('7')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '13'
		) t2 on (t1.rowName = '13' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_12
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		a.rowName
		,checkResult = 'Внимание! Строка 12  Графы 3-9 необходим ручной ввод данных '
		from dwh2.finAnalytics.repPublicPL_40_8 a
		where a.repmonth = @repmonth
		and a.RowName in ('12')
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_13
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		a.rowName
		,checkResult = 'Внимание! Графа 3-8 необходим ручной ввод данных на основании данных предоставленных от подразделения '
		from dwh2.finAnalytics.repPublicPL_40_8 a
		where a.repmonth = @repmonth
		and a.RowName in ('13.1','13.2','13.3','13.4','13.5','13.6','13.7','13.8','13.9','13.10')
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	--40.2_14
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		a.rowName
		,checkResult = 'Внимание! Необходим ручной ввод данных, в случае признания кредиторской задолжностью'
		from dwh2.finAnalytics.repPublicPL_40_8 a
		where a.repmonth = @repmonth
		and a.RowName in ('14.1','14.2','14.3','14.4','14.5','14.6','14.7','14.8','14.9','14.10','14.11','14.12','14.13','14.14','14.15')
		) t2 on (t1.rowName = t2.rowName and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;
	
	--40.8_15
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка', str(isnull(a.[sumAmountCol9],0) - isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_8 a
		left join (
		select
		amountCheck = sum(isnull(a.[sumAmountItog],0))
		from dwh2.finAnalytics.repPublicPL_19_1 a
		where a.repmonth = @repmonth
		and rowName in ('9')
		) b on 1=1
		where a.repmonth = @repmonth
		and a.RowName = '15'
		) t2 on (t1.rowName = '15' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;
	
	--40.8_17
	merge into dwh2.finAnalytics.repPublicPL_40_8 t1
	using(
		select
		checkResult = case 
						when abs(isnull(a.[sumAmountCol9],0)
							+	isnull(r.[sumAmountCol9],0)
							-	isnull(b.amountCheck,0)) < 100 
							then 'OK'
						when abs(isnull(a.[sumAmountCol9],0)
							+	isnull(r.[sumAmountCol9],0)
							-	isnull(b.amountCheck,0)) >= 100 
							then concat('Ошибка ', str(isnull(a.[sumAmountCol9],0)
							+	isnull(r.[sumAmountCol9],0)
							-	isnull(b.amountCheck,0)))
					  end
		--,amountRep = a.sumAmountItog
		--,amountcheck = b.amountCheck
		from dwh2.finAnalytics.repPublicPL_40_8 a
		left join (
		select
		amountCheck = a.restOut
		from [dwh2].[finAnalytics].[rep842] a
		where a.repmonth = @repmonth
		and a.RowName = '17'
		) b on 1=1
		left join dwh2.finAnalytics.repPublicPL_40_8 r on r.repmonth = @repmonth and r.rowName = '18'
		where a.repmonth = @repmonth
		and a.RowName = '17'
		) t2 on (t1.rowName = '17' and t1.repmonth = @repmonth)
		when matched then update
		set t1.checkResult1 = t2.checkResult;

	end try

	begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры контроля даных для публикуемой отчетности'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	declare @subject  nvarchar(200) = 'Ошибка расчета контроля для Публикуемой'
	declare @emailList nvarchar(200)
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch

END
