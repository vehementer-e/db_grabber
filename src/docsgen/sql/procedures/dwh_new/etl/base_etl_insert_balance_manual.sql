-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 05-03-2019
-- Description:	airflow etl insert_balance

--
--  exec etl.base_etl_insert_balance_manual

-- =============================================
CREATE   procedure   [etl].[base_etl_insert_balance_manual]
    
as
begin
	/* select count(*) from tmp_v_requests
       select count(*) from v_requests
     */
	SET NOCOUNT ON;
	--log
	exec [log].[LogAndSendMailToAdmin] 'etl.base_etl_insert_balance','Info','procedure started',''

    /**
     select * into dwh_new.dbo.balance_manual from dwh_new.dbo.balance
     */
    
    truncate table  dbo.balance_manual;
    
    insert into  dbo.balance_manual
    
    select b.Ссылка external_link
         , r.Номер external_id 
         , cr.ВидДвижения action_type_id
         , case when year(cr.Период)>2018 then DATEADD(year,-2000,cr.Период) else cr.Период end as moment
         , sum( case 
                    when cr.Вид = 0xA3DBD252B629EFDE45312018E2F4C5DF
                        then cr.Сумма
                    else 0
                end) as principal
         , sum( case
                    when cr.Вид = 0x83862A805ED0E9F042572467ABEA7C11
                    then cr.Сумма
                    else 0
                end) as percents
         , sum( case                                                                                                 
                    when cr.Вид = 0x8C8F7EFDFE1942A24ACAE8C38B924DDA
                    then cr.Сумма
                    else 0
                end) as fines
         , sum( case                                                                                  
                    when cr.Вид = 0xBEC58539CF56B2BF47AA3E45AE6172F5
                    then cr.Сумма
                    else 0
                    end) as overpayment
         , sum( case                                                                                  
                    when cr.Вид = 0x8F256D5874AF89354543DD824E1D4816
                    then cr.Сумма
                    else 0
                end) as other_payments
      from [prodsql02].[mfo].[dbo].[РегистрНакопления_ГП_ОстаткиЗаймов] cr
            left join [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] r on r.ссылка=cr.Договор
            left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] b on b.ссылка = r.Заявка
    group by
            b.Ссылка
          , r.Номер
          , cr.ВидДвижения
          , cr.Период 
;

-- added 190519 by turabov
--balance writeoff
IF  EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='balance_wtiteoff_manual') 
    drop table dbo.balance_wtiteoff_manual;

    select b.Ссылка external_link
         , r.Номер external_id 
         , cr.ВидДвижения action_type_id
         , case when year(cr.Период)>2018 then DATEADD(year,-2000,cr.Период) else cr.Период end as moment
         , sum( case 
                    when cr.Вид = 0xA3DBD252B629EFDE45312018E2F4C5DF
                        then cr.Сумма
                    else 0
                end) as principal
         , sum( case
                    when cr.Вид = 0x83862A805ED0E9F042572467ABEA7C11
                    then cr.Сумма
                    else 0
                end) as percents
         , sum( case                                                                                                 
                    when cr.Вид = 0x8C8F7EFDFE1942A24ACAE8C38B924DDA
                    then cr.Сумма
                    else 0
                end) as fines
         , sum( case                                                                                  
                    when cr.Вид = 0xBEC58539CF56B2BF47AA3E45AE6172F5
                    then cr.Сумма
                    else 0
                    end) as overpayment
         , sum( case                                                                                  
                    when cr.Вид = 0x8F256D5874AF89354543DD824E1D4816
                    then cr.Сумма
                    else 0
                end) as other_payments
		into dbo.balance_wtiteoff_manual
      from [prodsql02].[mfo].[dbo].[РегистрНакопления_ГП_ОстаткиЗаймов] cr
            left join [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] r on r.ссылка=cr.Договор
            left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] b on b.ссылка = r.Заявка
	  where cr.Сумма<0
    group by
            b.Ссылка
          , r.Номер
          , cr.ВидДвижения
          , cr.Период 
--end of balance writeoff

;--todo: вынетси в отдельный шаг 

IF  EXISTS (SELECT 1 
           FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_TYPE='BASE TABLE' 
           AND TABLE_NAME='stat_v_balance2_manual') 
    drop table dbo.stat_v_balance2_manual;

select * into dbo.stat_v_balance2_manual from dbo.v_balance3_manual;

/*
create index idx_stvb_cdate
on stat_v_balance2(cdate) ;
  */
create index idx_stvb_overdue_days_p
on stat_v_balance2_manual(overdue_days_p);

create index idx_stvb_credit_id
on stat_v_balance2_manual(credit_id);


CREATE NONCLUSTERED INDEX idx_stat_v_balance2_cdate_external_id_principal_cnl_percents_cnl_fines_cnl
ON [dbo].[stat_v_balance2_manual] ([cdate])
INCLUDE ([external_id],[principal_cnl],[percents_cnl],[fines_cnl],[overpayments_cnl],[otherpayments_cnl],[overpayments_acc],[total_rest],[overdue_days_p])



    exec [log].[LogAndSendMailToAdmin] 'etl.base_etl_insert_balance','Info','procedure finished',N''


end





