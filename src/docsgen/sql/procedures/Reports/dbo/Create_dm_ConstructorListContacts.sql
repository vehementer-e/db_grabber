CREATE   PROC dbo.Create_dm_ConstructorListContacts
as

begin

set nocount on
SET XACT_ABORT ON


--drop table if exists dbo.dm_ConstructorListContacts
TRUNCATE TABLE dbo.dm_ConstructorListContacts

INSERT dbo.dm_ConstructorListContacts
(
    TableName,
    CustomerId,
    ContactFio,
    [Тип контактного лица],
    [Тип контакта],
    [Вид контакта],
    ContactName,
    ContactData,
    IsOperative,
    Commentary,
    id
)
Select 
	TableName,
    CustomerId,
    ContactFio,
    [Тип контактного лица],
    [Тип контакта],
    [Вид контакта],
    ContactName,
    ContactData,
    IsOperative,
    Commentary,
    id
--into dbo.dm_ConstructorListContacts
from [dwh2].[cubes].[dim_ListContacts] 

end
