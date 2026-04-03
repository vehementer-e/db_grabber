
CREATE   PROCEDURE [dbo].[Create_dm_Contracts]
AS BEGIN

SET NOCOUNT ON 

-- точки выдачи
DROP TABLE IF EXISTS #offices

SELECT r.Номер,o.Наименование Партнер,s.Представление СпособОформления
INTO  #offices

 FROM [Stg].[_1cCRM].Документ_ЗаявкаНаЗаймПодПТС    r

JOIN [Stg].[_1cCRM].Справочник_Офисы o ON r.Офис=o.Ссылка
JOIN  [Stg].[_1cCRM].Перечисление_СпособыОформленияЗаявок s ON s.Ссылка=  r.СпособОформления



--повторники/докреды
DROP TABLE IF EXISTS #povt_contract

SELECT DISTINCT external_id,return_type 
INTO #povt_contract
FROM [dwh_new].[dbo].[returned]   re
JOIN dwh_new.dbo.requests r ON re.id=r.id


-- ставки контракта
DROP TABLE IF EXISTS #CMR_ContractParameters

SELECT  
       CMR_ContractParameters.Договор,
      "Ставка начальная"  =   first_value(CMR_ContractParameters.ПроцентнаяСтавка) OVER (PARTITION BY договор ORDER BY Период) 
      ,"Ставка начальная1"  =   first_value(CMR_ContractParameters.НачисляемыеПроценты) OVER (PARTITION BY договор ORDER BY Период) 
      ,"Ставка финальная"   = first_value(CMR_ContractParameters.ПроцентнаяСтавка) OVER (PARTITION BY договор ORDER BY Период DESC) 
      ,"Ставка финальная1"   = first_value(CMR_ContractParameters.НачисляемыеПроценты) OVER (PARTITION BY договор ORDER BY Период DESC) 
      ,CMR_ContractParameters.Период ,CMR_ContractParameters.ПроцентнаяСтавка,CMR_ContractParameters.НачисляемыеПроценты
      INTO #CMR_ContractParameters
  FROM [Stg].[_1cCMR].[РегистрСведений_ПараметрыДоговора] CMR_ContractParameters

DROP TABLE IF EXISTS #stavka

SELECT DISTINCT Договор
     , [Ставка начальная]= CASE WHEN 
                                      CASE WHEN [Ставка начальная]=0.00 THEN [Ставка начальная1] ELSE [Ставка начальная] END 
                                    =30 THEN 100
                           ELSE CASE WHEN [Ставка начальная]=0.00 THEN [Ставка начальная1] ELSE [Ставка начальная] END 
                           END
     , [Ставка финальная]=CASE WHEN [Ставка финальная]=0.00 THEN [Ставка финальная1] ELSE [Ставка финальная] END 
  INTO #stavka
  FROM #CMR_ContractParameters 
  




--даты погашения кредита
DROP TABLE IF EXISTS #ended_contracts

SELECT DISTINCT r. Договор
     , max(r.Период)  Период
    -- , s.Наименование
  INTO #ended_contracts
  FROM [Stg].[_1cCMR].РегистрСведений_СтатусыДоговоров r
  JOIN [Stg].[_1cCMR].Справочник_СтатусыДоговоров       s ON r.Статус=s.Ссылка
 WHERE s.Наименование='Погашен'
 GROUP BY r. Договор

 -- итоговая таблица

DROP TABLE IF EXISTS #CMR_Contracts

SELECT CMR_Contracts_Ссылка       = CMR_Contracts.Ссылка
     , "Договор (номер)"          = CMR_Contracts.[Код]
     , Продукт                    = CMR_Contracts.[КредитныйПродукт]
     , "Сумма выдачи"             = CMR_Contracts.[Сумма]
     , "Ставка начальная"         = s.[Ставка начальная]
     , "Ставка финальная"         = s.[Ставка финальная]
     , Срок                       = CMR_Contracts.Срок
     , "Дата выдачи"              = CMR_Contracts.[Дата]
     , "Дата погашения"           = e.Период
     , "Месяц выдачи"             = month(CMR_Contracts.[Дата])
     , "Месяц погашения"          = month(e.Период)
     , "Место создания договора"  = of_.СпособОформления
     , "Признак повторности (новый, повторный, параллельный, докред)"=
        CASE WHEN p.return_type='repeated'      THEN 'Повторный'
             WHEN p.return_type='dokred'        THEN 'докред'
             WHEN p.return_type='parallel'      THEN 'параллельный'
             WHEN p.return_type IS NULL         THEN 'новый'
             ELSE 'Статус неопределен'
        END
         
     , "Способ выдачи (партнер, пэп-1, пэп-2, вм)"=


     	CASE
      WHEN pep.[ПЭП2]=1 THEN			'пэп-2'
			WHEN pep.[ДатаПодписанияПЭП]=1 AND pep.[ПЭП2]=0 THEN 'ПЭП1'	
	
			WHEN pep.[ВМ]=1 THEN N'ВМ'
      ELSE 
      		CASE WHEN of_.Партнер IS NOT NULL  THEN N'Партнер'
          END
		END 
     , "Точка партнера"           = of_.Партнер
INTO #CMR_Contracts
      
FROM [Stg].[_1cCMR].[Справочник_Договоры] CMR_Contracts             --44875
    LEFT JOIN  #ended_contracts e ON e.Договор=CMR_Contracts.Ссылка 
    left join  #stavka s on s.Договор=CMR_Contracts.Ссылка
    left join #povt_contract p on p.external_id=  CMR_Contracts.Код
    left join Stg._1cCMR.[Справочник_Точки] t on t.ссылка=CMR_Contracts.Точка
    left join [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] pep on pep.ЗаявкаНомер= CMR_Contracts.Код
    left join #offices of_ on of_.Номер=  CMR_Contracts.Код


   
   
--drop table if exists dm_contracts   
--DWH-1764
TRUNCATE TABLE dbo.dm_contracts

INSERT dbo.dm_contracts
(
    CMR_Contracts_Ссылка,
    [Договор (номер)],
    Продукт,
    [Сумма выдачи],
    [Ставка начальная],
    [Ставка финальная],
    Срок,
    [Дата выдачи],
    [Дата погашения],
    [Месяц выдачи],
    [Месяц погашения],
    [Место создания договора],
    [Признак повторности (новый, повторный, параллельный, докред)],
    [Способ выдачи (партнер, пэп-1, пэп-2, вм)],
    [Точка партнера]
)
select 
	CMR_Contracts_Ссылка,
    [Договор (номер)],
    Продукт,
    [Сумма выдачи],
    [Ставка начальная],
    [Ставка финальная],
    Срок,
    [Дата выдачи],
    [Дата погашения],
    [Месяц выдачи],
    [Месяц погашения],
    [Место создания договора],
    [Признак повторности (новый, повторный, параллельный, докред)],
    [Способ выдачи (партнер, пэп-1, пэп-2, вм)],
    [Точка партнера] 
--INTO dm_contracts
FROM #CMR_Contracts 


    end
