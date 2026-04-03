

/**************************************************************************
Процедура для расчета коэффициентов регрессионной модели y = a + bx + cx^2
с помощью МНК
Если требуется, чтобы модельные значения были равны значению в первой точке
- то используется модификация МНК с градиентным спуском

Revisions:
dt			user				version		description
13/10/20	datsyplakov			v1.0		Создание процедуры

*************************************************************************/

CREATE procedure [Risk].[calc_mnk_2_variable]

--входные параметры
@flag_first_val bit = 1,
@fact_values dbo.tabletype$mnk_xy READONLY,
--выходные параметры
@a float OUT,
@b float OUT,
@c float OUT

as

--промежуточные параметры
declare @v_fact_values dbo.tabletype$mnk_xy; 
insert into @v_fact_values 
select a.x , a.y from @fact_values a;

declare @sum_x float;
declare @sum_y float;
declare @sum_z float;
declare @sum_x_sq float;
declare @sum_y_sq float;
declare @sum_z_sq float;
declare @sum_xy float;
declare @sum_xz float;
declare @sum_yz float;
declare @n int;

declare @x1 float;
declare @y1 float;
declare @z1 float;

declare @errfunc_value_curr float;
declare @errfunc_value_old float;
declare @grad_a float;
declare @grad_b float;
declare @grad_c float;
declare @alpha float = 0.0001;
declare @eps float = 0.0000001;
declare @a_old float;
declare @b_old float;
declare @c_old float;


--кол-во измерений
select @n = count(*) from @v_fact_values;
--сумма X,Y,Z
select @sum_x = sum(x), @sum_y = sum(y), @sum_z = sum(x*x) from @v_fact_values;

--сумма квадратов X, Y, Z
select @sum_x_sq = sum(power(x,2)), @sum_y_sq = sum(power(y,2)), @sum_z_sq = sum(power(x*x, 2)) from @v_fact_values;

--сумма произведения XY
select @sum_xy = sum(x*y), @sum_xz = sum(x*x*x), @sum_yz = sum(y*x*x) from @v_fact_values;

--первое измерение X, Y, Z
drop table if exists #for_first_val;
select x,y, x*x as z, ROW_NUMBER() over (order by x) as rown
into #for_first_val from @v_fact_values;

select @x1 = x, @y1 = y, @z1 = z from #for_first_val where rown = 1;


if @flag_first_val = 1
begin
----Градиентный спуск 
	--Шаг 0 - инициализация параметров 
	set @b_old = 0.01; set @b = 0.01; 
	set @c_old = 0.01; set @c = 0.01; 
	set @a_old = @y1 - @b * @x1 - @c * @z1; set @a = @y1 - @b * @x1 - @c * @z1; --@y1 - @b * @x1 - @c * @z1;
	set @grad_a = - (-2 * @sum_y + 2 * @a * @n + 2 * @b * @sum_x + 2 * @c * @sum_z);
	set @grad_b = - (-2 * @sum_xy + 2 * @a * @sum_x + 2 * @b * @sum_x_sq + 2 * @c * @sum_xz);
	set @grad_c = - (-2 * @sum_yz + 2 * @a * @sum_z + 2 * @b * @sum_xz + 2 * @c * @sum_z_sq);
	set @errfunc_value_old = -( @sum_y_sq - 2 * @a * @sum_y - 2 * @b * @sum_xy + @n * power(@a,2) + 2 * @a * @b * @sum_x + power(@b,2) * @sum_x_sq
	- 2 * @c * @sum_yz + power(@c,2) * @sum_z_sq + 2 * @a * @c * @sum_z + 2 * @b * @c * @sum_xz );


	--Шаг 1 - движение по вектору-градиенту
	set @b = @b_old + @grad_b * @alpha;
	set @c = @c_old + @grad_c * @alpha;
	set @a = @y1 - @b * @x1 - @c * @z1;
	set @grad_a = - (-2 * @sum_y + 2 * @a * @n + 2 * @b * @sum_x + 2 * @c * @sum_z);
	set @grad_b = - (-2 * @sum_xy + 2 * @a * @sum_x + 2 * @b * @sum_x_sq + 2 * @c * @sum_xz);
	set @grad_c = - (-2 * @sum_yz + 2 * @a * @sum_z + 2 * @b * @sum_xz + 2 * @c * @sum_z_sq);
	set @errfunc_value_curr = -( @sum_y_sq - 2 * @a * @sum_y - 2 * @b * @sum_xy + @n * power(@a,2) + 2 * @a * @b * @sum_x + power(@b,2) * @sum_x_sq
	- 2 * @c * @sum_yz + power(@c,2) * @sum_z_sq + 2 * @a * @c * @sum_z + 2 * @b * @c * @sum_xz );



	--Цикл с Шага 2. Критерий остановки: |дельта Функционала| < eps или прошло более 100000 итераций
	declare @i int = 1;
	declare @max_delta float = 0;

	
	select @max_delta = max(delta) from (
	--select abs(@a - @a_old) as delta
	--union all
	select abs(@b - @b_old) as delta
	union all
	select abs(@c - @c_old) as delta) aa;

	--while not(abs(@errfunc_value_curr - @errfunc_value_old) < @eps or @i > 100000)
	while not(@max_delta < @eps or @i > 100000)
	begin

	set @errfunc_value_old = @errfunc_value_curr;
	set @a_old = @a; set @b_old = @b; set @c_old = @c;

	set @b = @b + @grad_b * @alpha;
	set @c = @c + @grad_c * @alpha;
	set @a = @y1 - @b * @x1 - @c * @z1;
	set @grad_a = - (-2 * @sum_y + 2 * @a * @n + 2 * @b * @sum_x + 2 * @c * @sum_z);
	set @grad_b = - (-2 * @sum_xy + 2 * @a * @sum_x + 2 * @b * @sum_x_sq + 2 * @c * @sum_xz);
	set @grad_c = - (-2 * @sum_yz + 2 * @a * @sum_z + 2 * @b * @sum_xz + 2 * @c * @sum_z_sq);
	set @errfunc_value_curr = -( @sum_y_sq - 2 * @a * @sum_y - 2 * @b * @sum_xy + @n * power(@a,2) + 2 * @a * @b * @sum_x + power(@b,2) * @sum_x_sq
	- 2 * @c * @sum_yz + power(@c,2) * @sum_z_sq + 2 * @a * @c * @sum_z + 2 * @b * @c * @sum_xz );

	select @max_delta = max(delta) from (
	--select abs(@a - @a_old) as delta
	--union all
	select abs(@b - @b_old) as delta
	union all
	select abs(@c - @c_old) as delta) aa;

	set @i = @i + 1;

	end;
end;

if @flag_first_val = 0
begin

--Дописать формулы для МНК из 3х переменных!!!

set @b = @b;

--set @b = (@n * @sum_xy - @sum_x * @sum_y) / (@n * @sum_x_sq - power(@sum_x,2));
--set @a = (@sum_y - @b * @sum_x) / @n;

end;

