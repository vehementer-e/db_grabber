
--exec [risk].[etl_reg_rosstat_income] '20231231';
CREATE PROCEDURE [risk].[etl_reg_rosstat_income] @max_repdt VARCHAR(100)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @ReturnCode INT
		,@ReturnMessage VARCHAR(8000)
		,@curname_file VARCHAR(8000)
		,@cur_column VARCHAR(8000)
		,@cur_repdt DATE
		,@sql NVARCHAR(MAX)
		,@i INT
		,@cnt INT;

	SELECT @cnt = 0;

	SELECT @curname_file = CONCAT (
			'Доход Росстат '
			,@max_repdt
			,'.xlsx'
			)
			
	EXEC stg.dbo.ExecLoadExcel @PathName = '\\10.196.41.14\DWHFiles\Risk\Доход Росстат\'
		,@FileName = @curname_file
		,@SheetName = 'Лист1'
		,@isMoveFile = 'TRUE'
		,@TableName = '##stg_Доход_Росстат'
		,@ReturnCode = @ReturnCode OUTPUT
		,@ReturnMessage = @ReturnMessage OUTPUT
	SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage;



	SELECT @i = 0;

	DROP TABLE

	IF EXISTS #Доход_Росстат;
		SELECT cast(NULL AS DATE) AS repdate
			,cast(NULL AS VARCHAR(8000)) AS Region
			,cast(NULL AS FLOAT) AS regional_income
		INTO #Доход_Росстат;

	WHILE @i <= 3
	BEGIN
		DROP TABLE

		IF EXISTS ##Доход_Росстат;
		DROP TABLE

		IF EXISTS ##Доход_Росстат_cur_date;
		
		SELECT @cur_repdt = dateadd(dd,-1,dateadd(mm, - @i * 3, dateadd(dd, 1, cast(@max_repdt AS DATE))));

		SELECT @cur_column = CASE WHEN format(@cur_repdt, 'MM/dd/yyyy') LIKE '0%' THEN substring(format(@cur_repdt, 'MM/dd/yyyy'), 2, 9) ELSE format(@cur_repdt, 'MM/dd/yyyy') END;

		SELECT @sql = 'select Регион as Region, [' + @cur_column + '] as regional_income into ##Доход_Росстат_cur_date from ##stg_Доход_Росстат;';

		EXEC sp_executesql @sql;

		INSERT INTO #Доход_Росстат
		SELECT cast(@cur_repdt AS DATE) AS repdate
			,a.*
		FROM ##Доход_Росстат_cur_date a;

		SELECT @i = @i + 1;
	END;

	UPDATE risk.REG_ROSSTAT_INCOME
	SET dt_valid_to = getdate()
	WHERE dt_valid_to >= '4444-01-01';

	INSERT INTO risk.REG_ROSSTAT_INCOME
	SELECT a.repdate
		,trim(a.Region) as Region
		,a.regional_income
		,getdate() AS dt_valid_from
		,cast('4444-01-01 00:00:00' AS DATETIME) AS dt_valid_to
	FROM #Доход_Росстат a
	WHERE a.Region IS NOT NULL;


	--Checks
	--1
	WITH max_src_valid_to
	AS (
		SELECT max(dt_valid_to) AS prev_dt_valid_to
		FROM risk.REG_ROSSTAT_INCOME a
		WHERE a.dt_valid_to < '4444-01-01'
		)
		,cur_cnt
	AS (
		SELECT count(DISTINCT Region) AS cnt_cur
		FROM risk.REG_ROSSTAT_INCOME a
		WHERE a.dt_valid_to >= '4444-01-01'
		)
		,prev_cnt
	AS (
		SELECT count(DISTINCT Region) AS cnt_prev
		FROM risk.REG_ROSSTAT_INCOME s
		INNER JOIN max_src_valid_to m
			ON m.prev_dt_valid_to = s.dt_valid_to
		)
	SELECT @cnt=cnt_cur - cnt_prev
	FROM cur_cnt
	INNER JOIN prev_cnt
		ON 1 = 1;

	IF @cnt < 0
		PRINT ('Количество регионов в текущем файле меньше, чем в предыдущих загрузках');
	
	IF @cnt > 0
		PRINT ('Количество регионов в текущем файле больше, чем в предыдущих загрузках');
	
	--2
	WITH max_src_valid_to
	AS (
		SELECT max(dt_valid_to) AS prev_dt_valid_to
		FROM risk.REG_ROSSTAT_INCOME a
		WHERE a.dt_valid_to < '4444-01-01'
		)
		,src
	AS (
		SELECT DISTINCT a.Region
		FROM risk.REG_ROSSTAT_INCOME a
		INNER JOIN max_src_valid_to m
			ON m.prev_dt_valid_to = a.dt_valid_to
		LEFT JOIN risk.REG_ROSSTAT_INCOME c
			ON c.Region = a.Region AND c.dt_valid_to >= '4444-01-01'
		WHERE c.Region IS NULL
		)
	SELECT @cnt = count(*)
	FROM src;

	IF @cnt > 0
		PRINT ('Название некоторых регионов изменились');

	--3
	WITH max_src_valid_to
	AS (
		SELECT max(dt_valid_to) AS prev_dt_valid_to
		FROM risk.REG_ROSSTAT_INCOME a
		WHERE a.dt_valid_to < '4444-01-01'
		)
		,src_prev_load
	AS (
		SELECT a.Region
			,avg(a.regional_income) AS avg_inc_prev
		FROM risk.REG_ROSSTAT_INCOME a
		INNER JOIN max_src_valid_to m
			ON m.prev_dt_valid_to = a.dt_valid_to
		GROUP BY a.Region
		)
		,src_cur_load
	AS (
		SELECT a.Region
			,avg(a.regional_income) AS avg_inc_prev
		FROM risk.REG_ROSSTAT_INCOME a
		WHERE a.dt_valid_to >= '4444-01-01'
		GROUP BY a.Region
		)
	SELECT @cnt = count(*)
	FROM src_prev_load p
	INNER JOIN src_cur_load c
		ON c.Region = p.Region
	WHERE abs(p.avg_inc_prev - c.avg_inc_prev) / p.avg_inc_prev > 0.3;

	IF @cnt > 0
		PRINT ('Среднегодовой доход по региону изменился более чем на 30% относительно предыдущей загрузки');

	DROP TABLE

IF EXISTS #region_mapping;
	SELECT cast(a.regioncode AS VARCHAR(1000)) AS regioncode
		, cast(a.regionname AS VARCHAR(1000)) AS regionname
		, cast(a.region AS VARCHAR(1000)) AS region
	INTO #region_mapping
	FROM (
		VALUES (
			'01'
			, 'Республика Адыгея (Адыгея)'
			, 'РеспубликаАдыгея'
			)
			, (
			'02'
			, 'Республика Башкортостан'
			, 'РеспубликаБашкортостан'
			)
			, (
			'03'
			, 'Республика Бурятия'
			, 'РеспубликаБурятия'
			)
			, (
			'04'
			, 'Республика Алтай'
			, 'РеспубликаАлтай'
			)
			, (
			'05'
			, 'Республика Дагестан'
			, 'РеспубликаДагестан'
			)
			, (
			'06'
			, 'Республика Ингушетия'
			, 'РеспубликаИнгушетия'
			)
			, (
			'07'
			, 'Кабардино-Балкарская Республика'
			, 'Кабардино-БалкарскаяРеспублика'
			)
			, (
			'08'
			, 'Республика Калмыкия'
			, 'РеспубликаКалмыкия'
			)
			, (
			'09'
			, 'Карачаево-Черкесская Республика'
			, 'Карачаево-ЧеркесскаяРеспублика'
			)
			, (
			'10'
			, 'Республика Карелия'
			, 'РеспубликаКарелия'
			)
			, (
			'11'
			, 'Республика Коми'
			, 'РеспубликаКоми'
			)
			, (
			'12'
			, 'Республика Марий Эл'
			, 'РеспубликаМарийЭл'
			)
			, (
			'13'
			, 'Республика Мордовия'
			, 'РеспубликаМордовия'
			)
			, (
			'14'
			, 'Республика Саха (Якутия)'
			, 'РеспубликаСаха(Якутия)'
			)
			, (
			'15'
			, 'Республика Северная Осетия - Алания'
			, 'РеспубликаСевернаяОсетия-Алания'
			)
			, (
			'16'
			, 'Республика Татарстан (Татарстан)'
			, 'РеспубликаТатарстан'
			)
			, (
			'17'
			, 'Республика Тыва'
			, 'РеспубликаТыва'
			)
			, (
			'18'
			, 'Удмуртская Республика'
			, 'УдмуртскаяРеспублика'
			)
			, (
			'19'
			, 'Республика Хакасия'
			, 'РеспубликаХакасия'
			)
			, (
			'20'
			, 'Чеченская Республика'
			, 'ЧеченскаяРеспублика'
			)
			, (
			'21'
			, 'Чувашская Республика - Чувашия'
			, 'ЧувашскаяРеспублика'
			)
			, (
			'22'
			, 'Алтайский край'
			, 'Алтайскийкрай'
			)
			, (
			'23'
			, 'Краснодарский край'
			, 'Краснодарскийкрай'
			)
			, (
			'24'
			, 'Красноярский край'
			, 'Красноярскийкрай'
			)
			, (
			'25'
			, 'Приморский край'
			, 'Приморскийкрай'
			)
			, (
			'26'
			, 'Ставропольский край'
			, 'Ставропольскийкрай'
			)
			, (
			'27'
			, 'Хабаровский край'
			, 'Хабаровскийкрай'
			)
			, (
			'28'
			, 'Амурская область'
			, 'Амурскаяобласть'
			)
			, (
			'29'
			, 'Архангельская область'
			, 'Архангельскаяобласть'
			)
			, (
			'30'
			, 'Астраханская область'
			, 'Астраханскаяобласть'
			)
			, (
			'31'
			, 'Белгородская область'
			, 'Белгородскаяобласть'
			)
			, (
			'32'
			, 'Брянская область'
			, 'Брянскаяобласть'
			)
			, (
			'33'
			, 'Владимирская область'
			, 'Владимирскаяобласть'
			)
			, (
			'34'
			, 'Волгоградская область'
			, 'Волгоградскаяобласть'
			)
			, (
			'35'
			, 'Вологодская область'
			, 'Вологодскаяобласть'
			)
			, (
			'36'
			, 'Воронежская область'
			, 'Воронежскаяобласть'
			)
			, (
			'37'
			, 'Ивановская область'
			, 'Ивановскаяобласть'
			)
			, (
			'38'
			, 'Иркутская область'
			, 'Иркутскаяобласть'
			)
			, (
			'39'
			, 'Калининградская область'
			, 'Калининградскаяобласть'
			)
			, (
			'40'
			, 'Калужская область'
			, 'Калужскаяобласть'
			)
			, (
			'41'
			, 'Камчатский край'
			, 'Камчатскийкрай'
			)
			, (
			'42'
			, 'Кемеровская область'
			, 'Кемеровскаяобласть'
			)
			, (
			'43'
			, 'Кировская область'
			, 'Кировскаяобласть'
			)
			, (
			'44'
			, 'Костромская область'
			, 'Костромскаяобласть'
			)
			, (
			'45'
			, 'Курганская область'
			, 'Курганскаяобласть'
			)
			, (
			'46'
			, 'Курская область'
			, 'Курскаяобласть'
			)
			, (
			'47'
			, 'Ленинградская область'
			, 'Ленинградскаяобласть'
			)
			, (
			'48'
			, 'Липецкая область'
			, 'Липецкаяобласть'
			)
			, (
			'49'
			, 'Магаданская область'
			, 'Магаданскаяобласть'
			)
			, (
			'50'
			, 'Московская область'
			, 'Московскаяобласть'
			)
			, (
			'51'
			, 'Мурманская область'
			, 'Мурманскаяобласть'
			)
			, (
			'52'
			, 'Нижегородская область'
			, 'Нижегородскаяобласть'
			)
			, (
			'53'
			, 'Новгородская область'
			, 'Новгородскаяобласть'
			)
			, (
			'54'
			, 'Новосибирская область'
			, 'Новосибирскаяобласть'
			)
			, (
			'55'
			, 'Омская область'
			, 'Омскаяобласть'
			)
			, (
			'56'
			, 'Оренбургская область'
			, 'Оренбургскаяобласть'
			)
			, (
			'57'
			, 'Орловская область'
			, 'Орловскаяобласть'
			)
			, (
			'58'
			, 'Пензенская область'
			, 'Пензенскаяобласть'
			)
			, (
			'59'
			, 'Пермский край'
			, 'Пермскийкрай'
			)
			, (
			'60'
			, 'Псковская область'
			, 'Псковскаяобласть'
			)
			, (
			'61'
			, 'Ростовская область'
			, 'Ростовскаяобласть'
			)
			, (
			'62'
			, 'Рязанская область'
			, 'Рязанскаяобласть'
			)
			, (
			'63'
			, 'Самарская область'
			, 'Самарскаяобласть'
			)
			, (
			'64'
			, 'Саратовская область'
			, 'Саратовскаяобласть'
			)
			, (
			'65'
			, 'Сахалинская область'
			, 'Сахалинскаяобласть'
			)
			, (
			'66'
			, 'Свердловская область'
			, 'Свердловскаяобласть'
			)
			, (
			'67'
			, 'Смоленская область'
			, 'Смоленскаяобласть'
			)
			, (
			'68'
			, 'Тамбовская область'
			, 'Тамбовскаяобласть'
			)
			, (
			'69'
			, 'Тверская область'
			, 'Тверскаяобласть'
			)
			, (
			'70'
			, 'Томская область'
			, 'Томскаяобласть'
			)
			, (
			'71'
			, 'Тульская область'
			, 'Тульскаяобласть'
			)
			, (
			'72'
			, 'Тюменская область'
			, 'Тюменскаяобласть'
			)
			, (
			'73'
			, 'Ульяновская область'
			, 'Ульяновскаяобласть'
			)
			, (
			'74'
			, 'Челябинская область'
			, 'Челябинскаяобласть'
			)
			, (
			'75'
			, 'Забайкальский край'
			, 'Забайкальскийкрай'
			)
			, (
			'76'
			, 'Ярославская область'
			, 'Ярославскаяобласть'
			)
			, (
			'77'
			, 'Москва'
			, 'г.Москва'
			)
			, (
			'78'
			, 'Санкт-Петербург'
			, 'г.Санкт-Петербург'
			)
			, (
			'79'
			, 'Еврейская автономная область'
			, 'Еврейскаяавт.область'
			)
			, (
			'83'
			, 'Ненецкий автономный округ'
			, 'Ненецкийавт.округ'
			)
			, (
			'86'
			, 'Ханты-Мансийский автономный округ - Югра'
			, 'Ханты-Мансийскийавт.округ'
			)
			, (
			'87'
			, 'Чукотский автономный округ'
			, 'Чукотскийавт.округ'
			)
			, (
			'89'
			, 'Ямало-Ненецкий автономный округ'
			, 'Ямало-Ненецкийавт.округ'
			)
			, (
			'91'
			, 'Республика Крым'
			, 'РеспубликаКрым'
			)
			, (
			'92'
			, 'Севастополь'
			, 'г.Севастополь'
			)
			, 
			(
			'99'
			, 'Иные территории, включая город и космодром Байконур'
			, 'РоссийскаяФедерация'
			), 
			(--24/01/2024 А.Ставничая
			'9999'
			, 'Российская Федерация'
			, 'РоссийскаяФедерация'
			)
		) a(regioncode, regionname, region);

		TRUNCATE TABLE risk.reg_rosstat_income_loginom;

		INSERT INTO risk.reg_rosstat_income_loginom
		SELECT s.regioncode
			,s.regionname
			,avg(a.regional_income) AS average_per_capita_income
			,getdate() AS dt_dml
		FROM #region_mapping s
		LEFT JOIN risk.REG_ROSSTAT_INCOME a
			ON upper(replace(trim(a.region), ' ', '')) = s.region
		WHERE getdate() BETWEEN a.dt_valid_from
				AND a.dt_valid_to
		GROUP BY s.regioncode
			,s.regionname;


END;
