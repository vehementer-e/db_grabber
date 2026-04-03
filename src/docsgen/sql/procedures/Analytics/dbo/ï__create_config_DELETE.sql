
CREATE proc [dbo].[__create_config] as
begin
--create table config 
--(
--rating_date_from date,
--rating_date_to date)
--insert into config
--select null, null

update config set rating_date_from = '20230301'
update config set rating_date_to = '20230401'


end