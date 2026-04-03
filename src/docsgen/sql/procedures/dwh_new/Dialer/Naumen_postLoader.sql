

-- exec Dialer.Naumen_postLoader
CREATE procedure [Dialer].[Naumen_postLoader]
  @filename nvarchar(255)=N'D:\Scripts\dialer\loadedCases.json'
as
begin

set nocount on

if object_id('tempdb.dbo.#naumen_json') is not null drop table  #naumen_json
create table #naumen_json (j nvarchar(max))

declare @tsql nvarchar(max)


set @tsql=N'
            bulk insert #naumen_json
            from '''+@filename+'''

            with(
                codepage=65001,
                tablock
                )
                '
--select @tsql
exec (@tsql)
--select * from #naumen_json

if object_id('tempdb.dbo.#naumen_json_pages') is not null drop table  #naumen_json_pages
select * into #naumen_json_pages from openjson((select j from #naumen_json),N'$.files')

      with (
          [page]      nvarchar(50) N'$.page'
          ,callcase   nvarchar(max) as Json
)

declare @callcase nvarchar(max)=''
select @callcase=@callcase+substring(callcase,2,len(callcase)-2)+',' from #naumen_json_pages
set @callcase='{"callcase":['+substring(@callcase,1,len(@callcase)-1)+']}'


--select @callcase
--select len(@callcase)
/*
select * from openjson((select j from #naumen_json),N'$')

      with (
          cnt nvarchar(50) N'$.count'
          )
if object_id('tempdb.dbo.#res') is not null drop table  #res
*/
if object_id('tempdb.dbo.#res') is not null drop table  #res
select *
into #res from openjson((select @callcase)/*(select j from #naumen_json)*/,N'$.callcase')

      with (
          uuid nvarchar(50) N'$.uuid.value'
          ,id nvarchar(50) N'$.id'
          ,title nvarchar(50) N'$.title'
          ,parentUUID nvarchar(50) N'$.parent.uuid.value'
          ,parentTitle nvarchar(50) N'$.parent.title'
          ,creationDate nvarchar(50) N'$.creationDate'
          ,completionDate nvarchar(50) N'$.completionDate'
          ,lastModified nvarchar(50) N'$.lastModified'
          ,stateId  nvarchar(50)N'$.state.id'
          ,stateTitle nvarchar(50)N'$.state.title'
          ,[priority] nvarchar(50)N'$.priority'
          ,phoneNumber1Type nvarchar(50)N'$.phoneNumber1.phoneNumber.phoneNumberType'
          ,phoneNumber1invalid nvarchar(50)N'$.phoneNumber1.phoneNumber.invalid'
          ,phoneNumber1value nvarchar(50)N'$.phoneNumber1.phoneNumber.value'

          ,phoneNumber2Type nvarchar(50)N'$.phoneNumber2.phoneNumber.phoneNumberType'
          ,phoneNumber2invalid nvarchar(50)N'$.phoneNumber2.phoneNumber.invalid'
          ,phoneNumber2value nvarchar(50)N'$.phoneNumber2.phoneNumber.value'

          ,phoneNumber3Type nvarchar(50)N'$.phoneNumber3.phoneNumber.phoneNumberType'
          ,phoneNumber3invalid nvarchar(50)N'$.phoneNumber3.phoneNumber.invalid'
          ,phoneNumber3value nvarchar(50)N'$.phoneNumber3.phoneNumber.value'

          ,phoneNumber4Type nvarchar(50)N'$.phoneNumber4.phoneNumber.phoneNumberType'
          ,phoneNumber4invalid nvarchar(50)N'$.phoneNumber4.phoneNumber.invalid'
          ,phoneNumber4value nvarchar(50)N'$.phoneNumber4.phoneNumber.value'

          ,phoneNumber5Type nvarchar(50)N'$.phoneNumber5.phoneNumber.phoneNumberType'
          ,phoneNumber5invalid nvarchar(50)N'$.phoneNumber5.phoneNumber.invalid'
          ,phoneNumber5value nvarchar(50)N'$.phoneNumber5.phoneNumber.value'

          ,phoneNumber6Type nvarchar(50)N'$.phoneNumber6.phoneNumber.phoneNumberType'
          ,phoneNumber6invalid nvarchar(50)N'$.phoneNumber6.phoneNumber.invalid'
          ,phoneNumber6value nvarchar(50)N'$.phoneNumber6.phoneNumber.value'

          ,[phoneNumbers]   nvarchar(max) as Json
          ,callFormAttribute0Id nvarchar(50) N'$.callForm.attribute[0].id'
          ,callFormAttribute0title nvarchar(50) N'$.callForm.attribute[0].title'
          ,callFormAttribute0value nvarchar(50) N'$.callForm.attribute[0].value[0].value'


          ,callFormAttribute1Id nvarchar(50) N'$.callForm.attribute[1].id'
          ,callFormAttribute1title nvarchar(50) N'$.callForm.attribute[1].title'
          ,callFormAttribute1value nvarchar(50) N'$.callForm.attribute[1].value[0].value'

          ,callFormAttribute2Id nvarchar(50) N'$.callForm.attribute[2].id'
          ,callFormAttribute2title nvarchar(50) N'$.callForm.attribute[2].title'
          ,callFormAttribute2value nvarchar(50) N'$.callForm.attribute[2].value[0].value'


          ,callFormAttribute3Id nvarchar(50) N'$.callForm.attribute[3].id'
          ,callFormAttribute3title nvarchar(50) N'$.callForm.attribute[3].title'
          ,callFormAttribute3value nvarchar(50) N'$.callForm.attribute[3].value[0].value'


          ,callFormAttribute4Id nvarchar(50) N'$.callForm.attribute[4].id'
          ,callFormAttribute4title nvarchar(50) N'$.callForm.attribute[4].title'
          ,callFormAttribute4value nvarchar(50) N'$.callForm.attribute[4].value[0].value'

          
          ,callFormAttribute5Id nvarchar(50) N'$.callForm.attribute[5].id'
          ,callFormAttribute5title nvarchar(50) N'$.callForm.attribute[5].title'
          ,callFormAttribute5value nvarchar(50) N'$.callForm.attribute[5].value[0].value'

          
          ,callFormAttribute6Id nvarchar(50) N'$.callForm.attribute[6].id'
          ,callFormAttribute6title nvarchar(50) N'$.callForm.attribute[6].title'
          ,callFormAttribute6value nvarchar(50) N'$.callForm.attribute[6].value[0].value'

          
          ,callFormAttribute7Id nvarchar(50) N'$.callForm.attribute[7].id'
          ,callFormAttribute7title nvarchar(50) N'$.callForm.attribute[7].title'
          ,callFormAttribute7value nvarchar(50) N'$.callForm.attribute[7].value[0].value'

          ,timeZone  nvarchar(50) N'$.timeZone'


          )
insert into dwh_new.Dialer.LoadedCases
select getdate() LoadDate, r.*  from #res r
          
end


