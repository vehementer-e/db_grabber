
CREATE   PROC dm.Update_реестр_blacklists_для_запроса_ИНН
as
BEGIN
	SET XACT_ABORT ON

	begin try
		--delete from dm.реестр_blacklists_для_запроса_ИНН
		drop table if exists #t_реестр

		SELECT DISTINCT
			L.row_id,
			ФИО = L.fio,
			ДатаРождения = L.birthdate,
			Фамилия = cast(NULL AS nvarchar(250)),
			Имя = cast(NULL AS nvarchar(250)),
			Отчество = cast(NULL AS nvarchar(250)),
			СерияПаспорта = substring(L.passport, 1, 4),
			НомерПаспорта = substring(L.passport, 6, 6),
			--[КемВыдан_Паспорт] [nvarchar] (500) NOT NULL,
			--[ДатаВыдачи_Паспорта] [date] NULL,
			ДатаДобавления = getdate(),
			ДатаОбновленияПД = getdate()
			--ДатаЗапросаДанных
			--ДатаПолученияИНН
		INTO #t_реестр
		FROM dm.blacklists AS L
		WHERE 1=1
			AND L.birthdate IS NOT NULL
			AND L.passport LIKE '[0-9][0-9][0-9][0-9] [0-9][0-9][0-9][0-9][0-9][0-9]'
			AND L.inn IS NOT NULL

		drop table if exists #t_реестр_ФИО

		SELECT 
			T.row_id,
			ord_pos = row_number() OVER (PARTITION BY T.row_id ORDER BY getdate()),
			F.value
		INTO #t_реестр_ФИО
		from #t_реестр AS T
			OUTER APPLY string_split(T.ФИО, ' ') AS F
		WHERE 1=1

		--SELECT * FROM #t_реестр_ФИО
		
		UPDATE T
		SET T.Фамилия = T1.value,
			T.Имя = T2.value,
			T.Отчество = T3.value
		FROM #t_реестр AS T
			LEFT JOIN #t_реестр_ФИО AS T1 ON T1.row_id = T.row_id AND T1.ord_pos = 1
			LEFT JOIN #t_реестр_ФИО AS T2 ON T2.row_id = T.row_id AND T2.ord_pos = 2
			LEFT JOIN #t_реестр_ФИО AS T3 ON T3.row_id = T.row_id AND T3.ord_pos = 3

		-- обновить паспортные данные в реестре
		merge dm.реестр_blacklists_для_запроса_ИНН AS t
		using #t_реестр AS s
			ON t.row_id = s.row_id
		when not matched then insert
		(
			row_id,
			ФИО,
			ДатаРождения,
			Фамилия,
			Имя,
			Отчество,
			СерияПаспорта,
			НомерПаспорта,
			ДатаДобавления,
			ДатаОбновленияПД
			--ДатаЗапросаДанных,
			--ДатаПолученияИНН,
			--ИНН,
			--ТаблицаИсточник,
			--tryCount,
			--id
		) values
		(
			s.row_id,
			s.ФИО,
			s.ДатаРождения,
			s.Фамилия,
			s.Имя,
			s.Отчество,
			s.СерияПаспорта,
			s.НомерПаспорта,
			s.ДатаДобавления,
			s.ДатаОбновленияПД
		)
		when matched
		then update SET
			--s.row_id,
			t.ФИО = s.ФИО,
			t.ДатаРождения = s.ДатаРождения,
			t.Фамилия = s.Фамилия,
			t.Имя = s.Имя,
			t.Отчество = s.Отчество,
			t.СерияПаспорта = s.СерияПаспорта,
			t.НомерПаспорта = s.НомерПаспорта,
			t.ДатаДобавления = s.ДатаДобавления,
			t.ДатаОбновленияПД = s.ДатаОбновленияПД
			;
	END TRY
	begin catch
		if @@TRANCOUNT>0
			rollback tran;
		;throw
	end catch
END
