CREATE   PROC tmp.TMP_AND_INSERT_risk_povt_buffer_history_NEW
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-03-01' and '2025-03-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-04-01' and '2025-04-30'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-05-01' and '2025-05-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-06-01' and '2025-06-30'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-07-01' and '2025-07-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-08-01' and '2025-08-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-09-01' and '2025-09-30'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-10-01' and '2025-10-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-11-01' and '2025-11-30'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2025-12-01' and '2025-12-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2026-01-01' and '2026-01-31'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2026-02-01' and '2026-02-28'
--insert dwh2.risk.povt_buffer_history_NEW select * from dwh2.risk.povt_buffer_history where cdate between '2026-03-01' and '2026-03-31'


END
