

/*
declare @ReceivedMessage nvarchar(max) = '
{"packet":"legacyLead","id":"113726775","uf_phone":"+7 (915) 644-70-00","UF_ROW_ID":null,"uf_name":null,"uf_source":"liknot","uf_type":"api","UF_RC_REJECT_CM":"CC.Не подходит под требования  - Год выпуска авто не соответствует требованиям  - КЦ","UF_ACTUALIZE_AT":"02.04.2021 16:11:22"}'

exec   [files].[XMLLoader] null, null, null, null
*/
-- Usage: запуск процедуры с параметрами
-- EXEC [files].[XMLLoader]
--      @passport = <value>,
--      @FIO = <value>,
--      @birthdate = <value>,
--      @xmldata = <value>;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure [files].[XMLLoader]
	  
   @passport nvarchar(255)
  , @FIO nvarchar(100)
  , @birthdate  nvarchar(255)
  , @xmldata nvarchar(max)

as 

begin

insert into [files].[XMLdataNBKI]
SELECT  @passport
      , @FIO
      , @birthdate
      , @xmldata
  
select 0
end
