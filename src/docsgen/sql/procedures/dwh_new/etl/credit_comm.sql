create procedure etl.credit_comm as
begin

set nocount on;

truncate table dbo.credit_committee;
insert into dbo.credit_committee select distinct external_id from [Stg].[files].[credit_committee_buffer] where external_id is not null;

select 0;
end

