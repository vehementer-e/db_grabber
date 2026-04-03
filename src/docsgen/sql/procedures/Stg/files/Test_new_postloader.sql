-- Usage: запуск процедуры с параметрами
-- EXEC files.Test_new_postloader @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE files.Test_new_postloader as begin 
 begin tran 
  truncate table files.test_new
 insert into   files.test_new (
 [Тип-Источник] ,
 [Канал от источника] ,
 [F3] ,
 [F4] ,
 [F5] ,
 [F6] ,
 [F7] ,
 [F8] ,
 [F9] ,
 [F10] ,
 [F11] ,
 [F12] ,
 [F13] ,
 [F14] ,
 [F15] ,
 [F16] ,
 [F17] ,
 [F18] ,
 [F19] ,
 [F20] ,
 [F21] ,
 [F22] ,
 [F23] ,
 [F24] ,
 [F25] ,
 [F26] ,
 [created] ) 
 select 
 [Тип-Источник] ,
 [Канал от источника] ,
 [F3] ,
 [F4] ,
 [F5] ,
 [F6] ,
 [F7] ,
 [F8] ,
 [F9] ,
 [F10] ,
 [F11] ,
 [F12] ,
 [F13] ,
 [F14] ,
 [F15] ,
 [F16] ,
 [F17] ,
 [F18] ,
 [F19] ,
 [F20] ,
 [F21] ,
 [F22] ,
 [F23] ,
 [F24] ,
 [F25] ,
 [F26] ,
 [created]  from files.Test_new_buffer 
 commit tran  
 end 