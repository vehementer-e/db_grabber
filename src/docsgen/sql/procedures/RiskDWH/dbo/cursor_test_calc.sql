
CREATE PROCEDURE dbo.cursor_test_calc
   AS
 
   --объявляем переменные
   DECLARE @external_id numeric
   DECLARE @collateral_id numeric
   DECLARE @cur_collateral_id numeric
   DECLARE @dt_open date
   DECLARE @od numeric
   DECLARE @collateral_price numeric
   DECLARE @splitted_collateral_price numeric


   

   DECLARE my_cur CURSOR FOR
     SELECT a.external_id,a.collateral_id, a.dt_open, a.od, a.price from dbo.cursor_test a
order by a.collateral_id,a.dt_open,a.external_id;
   
   truncate table dbo.cursor_test_result;
   

   OPEN my_cur

   FETCH NEXT FROM my_cur INTO @external_id,@collateral_id, @dt_open, @od, @collateral_price


   WHILE @@FETCH_STATUS = 0
   
   BEGIN
        select @splitted_collateral_price=iif(isnull(@cur_collateral_id,@collateral_id)=@collateral_id,isnull(@splitted_collateral_price, @collateral_price)-@od, @collateral_price-@od);

insert into dbo.cursor_test_result
values (@external_id,@collateral_id, @dt_open, @od, @collateral_price, @splitted_collateral_price)
select @cur_collateral_id=@collateral_id;
        --считываем следующую строку курсора
        FETCH NEXT FROM my_cur INTO @external_id, @collateral_id, @dt_open, @od, @collateral_price
   END
   
   --закрываем курсор
   CLOSE my_cur
   DEALLOCATE my_cur
