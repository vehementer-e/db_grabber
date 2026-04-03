
CREATE PROCEDURE [finAnalytics].[calcRep840_4]
	@repmonth date,
    @repdate date
AS
BEGIN

BEGIN TRY

delete from finAnalytics.rep840_4
where REPMONTH=@repmonth and REPDATE=@repdate

insert into finAnalytics.rep840_4
(REPMONTH, REPDATE, rownum, col1, col2, col3, col4, col5, 
col6, col7, col8, col9, col10, col11, col12, col13, col14, 
col15, col16, col17, col18, comment, 
checkMethod2, chekResult2, checkMethod3, chekResult3)


---Без просрочки

SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=1
      ,[col1] = '4.1'
      ,[col2] = 'Требования по договору займа без просроченных платежей'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.1.1 и п4.1.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (3,5)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=2
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка3+ строка5'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (4,6)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (3,4,5,6)

  union all
  ---1-7 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=7
      ,[col1] = '4.2'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 1 до 7 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.2.1 и п4.2.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (9,11)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=8
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка10+ строка12'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (10,12)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (9,10,11,12)

   union all
  ---8-30 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=13
      ,[col1] = '4.3'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 8 до 30 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.3.1 и п4.3.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (15,17)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=14
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка16+ строка18 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (16,18)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (15,16,17,18)

  union all
  ---31-60 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=19
      ,[col1] = '4.4'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 31 до 60 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.4.1 и п4.4.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (21,23)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=20
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка22+ строка24 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (22,24)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (21,22,23,24)

  union all
  ---61-90 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=25
      ,[col1] = '4.5'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 61 до 90 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.5.1 и п4.5.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (27,29)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=26
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка28+ строка30 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (28,30)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (27,28,29,30)

    union all
 ---91-120 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=31
      ,[col1] = '4.6'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 91 до 120 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.6.1 и п4.6.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (33,35)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=32
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка34+ строка36 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (34,36)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (33,34,35,36)

  union all
  ---121-180 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=37
      ,[col1] = '4.7'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 121 до 180 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.7.1 и п4.7.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (39,41)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=38
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка40+ строка42 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (40,42)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (39,40,41,42)

  union all
    ---181-270 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=43
      ,[col1] = '4.8'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 181 до 270 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.8.1 и п4.8.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (45,47)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=44
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка46+ строка48 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (46,48)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (45,46,47,48)

  union all
  ---271-360 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=49
      ,[col1] = '4.9'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 271 до 360 календарных дней'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.9.1 и п4.9.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (51,53)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=50
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка52+ строка54 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (52,54)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (51,52,53,54)

  union all
  ---более 360 дней просрочки

    SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=55
      ,[col1] = '4.10'
      ,[col2] = 'Требования по договору займа с просроченными платежами продолжительностью от 361 календарного дня'
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = 'Сумма п4.10.1 и п4.10.2'
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (57,59)
  group by
       [REPMONTH]
      ,[REPDATE]
    
  union all

  SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]=56
      ,[col1] = ''
      ,[col2] = ''
      ,[col3] = sum(col3)
      ,[col4] = sum(col4)
      ,[col5] = sum(col5)
      ,[col6] = sum(col6)
      ,[col7] = sum(col7)
      ,[col8] = sum(col8)
      ,[col9] = sum(col9)
      ,[col10] = sum(col10)
      ,[col11] = sum(col11)
      ,[col12] = sum(col12)
      ,[col13] = sum(col13)
      ,[col14] = sum(col14)
      ,[col15] = sum(col15)
      ,[col16] = sum(col16)
      ,[col17] = sum(col17)
      ,[col18] = max(col18)
      ,[comment] = ' строка58+ строка60 '
      ,null
      ,null
      ,null
      ,null

  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (58,60)
  group by
      [REPMONTH]
      ,[REPDATE]


  union all
  
SELECT 
      [REPMONTH]
      ,[REPDATE]
      ,[rownum]
      ,[col1]
      ,[col2]
      ,[col3]
      ,[col4]
      ,[col5]
      ,[col6]
      ,[col7]
      ,[col8]
      ,[col9]
      ,[col10]
      ,[col11]
      ,[col12]
      ,[col13]
      ,[col14]
      ,[col15]
      ,[col16]
      ,[col17]
      ,[col18]
      ,[comment]
      ,null
      ,null
      ,null
      ,null
  FROM [dwh2].[finAnalytics].[rep840_firstLevel_4] a
  where a.REPMONTH=@REPMONTH and a.REPDATE=@REPDATE
  and a.rownum in (57,58,59,60)

	end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  

END
