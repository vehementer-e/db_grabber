CREATE   PROC tmp.TMP_AND_INSERT_marketing_povt_inst_NEW
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
--insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-04-01' and '2023-04-30'

insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-05-01' and '2023-05-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-06-01' and '2023-06-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-07-01' and '2023-07-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-08-01' and '2023-08-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-09-01' and '2023-09-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-10-01' and '2023-10-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-11-01' and '2023-11-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2023-12-01' and '2023-12-31'

insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-01-01' and '2024-01-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-02-01' and '2024-02-29'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-03-01' and '2024-03-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-04-01' and '2024-04-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-05-01' and '2024-05-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-06-01' and '2024-06-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-07-01' and '2024-07-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-08-01' and '2024-08-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-09-01' and '2024-09-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-10-01' and '2024-10-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-11-01' and '2024-11-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2024-12-01' and '2024-12-31'

insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-01-01' and '2025-01-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-02-01' and '2025-02-28'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-03-01' and '2025-03-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-04-01' and '2025-04-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-05-01' and '2025-05-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-06-01' and '2025-06-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-07-01' and '2025-07-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-08-01' and '2025-08-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-09-01' and '2025-09-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-10-01' and '2025-10-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-11-01' and '2025-11-30'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2025-12-01' and '2025-12-31'

insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2026-01-01' and '2026-01-31'
insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2026-02-01' and '2026-02-28'

--insert dwh2.marketing.povt_inst_NEW select * from dwh2.marketing.povt_inst where cdate between '2026-03-01' and '2026-03-31'

END
