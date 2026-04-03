
/**************************************************************************
Процедура для расчета коэффициентов регрессионной модели y = a + bx
(y = a + b*ln(x), y = a * b^x) с помощью МНК
Если требуется, чтобы модельные значения были равны значению в первой точке
- то используется модификация МНК с градиентным спуском

Revisions:
dt			user				version		description
13/10/20	datsyplakov			v1.0		Создание процедуры

*************************************************************************/

CREATE procedure [Risk].[calc_mnk_1_variable]

--входные параметры
@function_type varchar(10) = 'LNX',
@flag_first_val bit = 1,
@fact_values dbo.tabletype$mnk_xy READONLY,
--выходные параметры
@a float OUT,
@b float OUT

as

--промежуточные параметры
declare @v_fact_values dbo.tabletype$mnk_xy; 
insert into @v_fact_values 
select * from @fact_values;


declare @sum_x float;
declare @sum_y float;
declare @sum_x_sq float;
declare @sum_y_sq float;
declare @sum_xy float;
declare @n int;
declare @x1 float;
declare @y1 float;
declare @errfunc_value_curr float;
declare @errfunc_value_old float;
declare @grad_a float;
declare @grad_b float;
declare @alpha float = 0.0001;
declare @eps float = 0.000001;
declare @a_old float;
declare @b_old float;

--Логарифмический тренд y = a + b*ln(x)
if @function_type = 'LNX'
begin
update @v_fact_values
set x = log(x);
end;

--Степенной тренд y = a * x^b
if @function_type = 'XPOWER'
begin
update @v_fact_values
set x = log(x), y = log(y);
end;

--кол-во измерений
select @n = count(*) from @v_fact_values;
--сумма X
select @sum_x = sum(x) from @v_fact_values;
--сумма Y
select @sum_y = sum(y) from @v_fact_values;
--сумма квадратов X
select @sum_x_sq = sum(power(x,2)) from @v_fact_values;
--сумма квадратов Y
select @sum_y_sq = sum(power(y,2)) from @v_fact_values;
--сумма произведения XY
select @sum_xy = sum(x*y) from @v_fact_values;
--первое измерение X и Y
drop table if exists #for_first_val;
select x,y, ROW_NUMBER() over (order by x) as rown
into #for_first_val from @v_fact_values;

select @x1 = x, @y1 = y from #for_first_val where rown = 1;



if @flag_first_val = 1
begin
	----Градиентный спуск 
	--Шаг 0 - инициализация параметров 
	set @b = 0.1; set @b_old = 0.1;
	set @a = @y1 - @b * @x1; set @a_old = @y1 - @b_old * @x1;
	set @grad_a = - (-2 * @sum_y + 2 * @a * @n + 2 * @b * @sum_x);
	set @grad_b = - (-2 * @sum_xy + 2 * @a * @sum_x + 2 * @b * @sum_x_sq);
	set @errfunc_value_old = -( @sum_y_sq - 2 * @a * @sum_y - 2 * @b * @sum_xy + @n * power(@a,2) + 2 * @a * @b * @sum_x + power(@b,2) * @sum_x_sq);

	--Шаг 1 - движение по вектору-градиенту
	set @b = @b + @grad_b * @alpha;
	set @a = @y1 - @b * @x1;
	set @grad_a = - (-2 * @sum_y + 2 * @a * @n + 2 * @b * @sum_x);
	set @grad_b = - (-2 * @sum_xy + 2 * @a * @sum_x + 2 * @b * @sum_x_sq);
	set @errfunc_value_curr = -( @sum_y_sq - 2 * @a * @sum_y - 2 * @b * @sum_xy + @n * power(@a,2) + 2 * @a * @b * @sum_x + power(@b,2) * @sum_x_sq);



	--Цикл с Шага 2. 1) Критерий остановки: |дельта Функионала| < eps или прошло более 100000 итераций
	--				 2) Критерий остановки: |дельта значений коэф B| < eps или прошло более 100000 итераций
	declare @i int = 1;
	declare @max_delta float = 0;

	
	select @max_delta = max(delta) from (
	select abs(@b - @b_old) as delta	
	) aa;

	--while not(abs(@errfunc_value_curr - @errfunc_value_old) < @eps or @i > 100000)
	while not(@max_delta < @eps or @i > 100000)
	begin

	set @errfunc_value_old = @errfunc_value_curr;
	set @b_old = @b;
	set @b = @b + @grad_b * @alpha;
	set @a = @y1 - @b * @x1;
	set @grad_a = - (-2 * @sum_y + 2 * @a * @n + 2 * @b * @sum_x);
	set @grad_b = - (-2 * @sum_xy + 2 * @a * @sum_x + 2 * @b * @sum_x_sq);
	set @errfunc_value_curr = -( @sum_y_sq - 2 * @a * @sum_y - 2 * @b * @sum_xy + @n * power(@a,2) + 2 * @a * @b * @sum_x + power(@b,2) * @sum_x_sq);
	select @max_delta = max(delta) from (
	select abs(@b - @b_old) as delta
	) aa;
	
	set @i = @i + 1;

	end;

end;

if @flag_first_val = 0
begin

set @b = (@n * @sum_xy - @sum_x * @sum_y) / (@n * @sum_x_sq - power(@sum_x,2));
set @a = (@sum_y - @b * @sum_x) / @n;

end;

