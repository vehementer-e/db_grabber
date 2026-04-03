create       proc  sale_report_promotion
as
begin

drop table if exists  #t1


select          v.ФИО                                                                                              [ФИО клиента]    
               ,v.Телефон                                                                                          [Номер телефона]   
               ,f1.number                                                                                        [Номер заявки]  
               ,CONCAT(Имя,' ', SUBSTRING(Фамилия, 1, 1),'.')                                                      [Имя участника] 
               ,SUBSTRING(v.Телефон, 6, 5)                                                                         [Номер участника]
			   ,v.[Верификация КЦ]                                                                                 [Дата подачи заявки]
			   ,v.[Договор зарегистрирован]                                                                        [Подписание 2 пакета]
			   ,v.[Заем выдан]                                                                                     [Дата выдачи]
			   ,case
			        when f1.ispts=1 then 'Птс'
					when f1.ispdl=1 then 'Пдл'
					when f1.isinstallment=1 then 'Инст'
			    end                                                                                                [Продукт]
			   ,case
			        when v.ВидЗайма = 'Первичный' then 'Новый'
					else 'Повторный'
				end                                                                                                [Вид займа]
			   ,v.НомерЗаявки
			   ,case
			        when v.[Заем погашен] is null then 'Да'
					else 'Нет'
			    end                                                                                                [Активный договор]
				, [Признак Страховка]

into #t1
from v_request v
left join v_fa f1 on v.number = f1.number
where v.[Заем выдан] >='20220101'


drop table if exists  #t2
select  Код, dpd into #t2 from v_balance where d = cast(getdate() as date)


select          t.[ФИО клиента]
               ,t.[Номер телефона]
			   ,t.[Номер заявки]
			   ,t.[Имя участника] 
			   ,t.[Номер участника]
			   ,t.[Дата подачи заявки]
			   ,t.[Подписание 2 пакета]
			   ,t.[Дата выдачи]
			   ,t.[Активный договор]
			   ,t.[Признак Страховка]
			   ,case
			        when DATEDIFF (SECOND, t.[Дата подачи заявки],t.[Подписание 2 пакета]) < 86400 then 1
					else 0 
				end                                      [за 24 часа подписал договор]
			   ,case
			        when DATEDIFF (SECOND, t.[Дата подачи заявки],t.[Дата выдачи]) < 86400 then 1
					else 0 
				end                                      [за 24 часа получил деньги]
			   ,case
			        when dpd>0 then 'Да'
			    end                                      [Просрочка]
			   ,t.[Продукт]
			   ,t.[Вид займа]
               ,r.client_passport_serial_number          [Серия паспорта]    
               ,r.client_passport_number                 [Номер паспорта]
			   ,r.passport_issue_date                    [Дата выдачи паспорта]
			   ,r.passport_issued_by                     [Кем выдан]
			   ,r.passport_issued_code                   [Код подразделения]
			   ,r.client_birthday                        [Дата рождения]
			   ,r.client_birth_place                     [Место рождения]
			   ,r.client_inn                             [ИНН]
			   ,r.registration_address                   [Адрес регистрации]
from #t1 t
left join stg._LK.requests r on r.num_1c=t.НомерЗаявки
left join #t2 t2 on t.НомерЗаявки = t2.Код


end