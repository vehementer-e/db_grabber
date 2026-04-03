-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 23.04.2019
-- Description:	
-- exec reportChangedObjects '20190423'
-- =============================================
CREATE PROCEDURE [dbo].[reportChangedObjects]
	@dt date
AS
BEGIN
	SET NOCOUNT ON;


select distinct dbname
     , [schema]
     , [name]
     , c
  from (  select dbname
               , [schema]
               , [name]
               , objectid
               , colid 
               , number
               , count(distinct   date) c
               --, text
             --  , t
             --  , l
            from ( select dbname
                        , OBJECT_SCHEMA_NAME(objectid,db_id(dbname)) [schema]
                        , object_name(objectid,db_id(dbname)) [name]
                        , date
                        , objectid
                        , colid 
                        , number
                        , text
                    --    , lag(text) over (partition by dbname,objectid,number,colid order by date) t
                    --    , iif(checksum(text)<>checksum(lag(text) over (partition by dbname,objectid,number,colid order by date)),'несовпадают','совпадают') l 
                    from logdb.[dbo].[DWH_OBJECT_TEXT]
                 )q 
           where cast([date] as date)=@dt
           group by 
           dbname
               , [schema]
               , [name]
    
               , objectid
               , colid 
               , number
               having count(distinct   date)>1
               )
    q
     --order by 1,2,3,number,colid 


END
