CREATE   proc [dbo].[Получение сообщения для телеграмм бота со статистикой для лидгенов]
@command nvarchar(max),
--@leadgen_access nvarchar(max) ,
@chat_id bigint
WITH EXECUTE AS OWNER --не удалять эту строку
as
begin

--create table _tg.leadgenBot_log ( command nvarchar(max) , chat_id bigint , created datetime2)
--insert into  _tg.leadgenBot_log select @command, @chat_id, getdate()

if @command in (
 'stat_today'
,'stat_yesterday'
,'stat_week'
,'stat_month'
,'stat_last_3_d'
,'stat_last_5_d'
)
begin
--declare @sql nvarchar(max) = 'select isnull(REPLACE(cast((select string_agg(Лидген +char(10)+text +char(10), ''~''  ) WITHIN GROUP (ORDER BY Лидген ASC) from dbo.[Оперативная витрина со статистикой для лидгенов] where command='''+@command+''' and Лидген in ('+@leadgen_access+')  )as nvarchar(max)), ''~'', ''———————————————''+char(10) ),''Нет данных'')+char(10)+''/''+'''+@command+''''
--select @sql
--exec  (@sql)

SELECT isnull(REPLACE(cast((
					SELECT string_agg(Лидген + CHAR(10) + TEXT + CHAR(10), '~') WITHIN
					GROUP (
							ORDER BY Лидген ASC
							)
					FROM dbo.[Оперативная витрина со статистикой для лидгенов] a
					join 	[_tg].[leadgenBot_USERS] b on a.Лидген=b.uf_source and b.id=@chat_id
					WHERE command = @command
					) AS NVARCHAR(max)), '~', '———————————————' + CHAR(10)), 'Нет данных') + CHAR(10) + '/' +@command+ ''

				--	select * from [_tg].[leadgenBot_USERS]

end


if @command ='start'
select '
Список доступных команд - /help
'

if @command ='help'
select '
Доступные команды:

/stat_today - статистика за сегодня
/stat_yesterday - статистика за вчера
/stat_last_3_d - статистика за последние 3 дня
/stat_last_5_d - статистика за последние 5 дней
/stat_week - статистика за неделю     
/stat_month - статистика за месяц

'



end

--exec dbo.[Получение сообщения для телеграмм бота со статистикой для лидгенов] 'stat_today', ' ''unicom24r'' , '' '' '
--
--select isnull(cast((select top 1 text from dbo.[Оперативная витрина со статистикой для лидгенов] where command='stat_today' and Лидген in ( 'unicom24r' , ' ' ) )as varchar(max)),'Нет данных')+char(10)++char(10)+'/'+'stat_today'

--exec analytics.dbo.[Получение сообщения для телеграмм бота со статистикой для лидгенов] 'help', '''unicom24r'' , '' '''


--select isnull(cast((select string_agg(Лидген +' '+text, char(13)) from dbo.[Оперативная витрина со статистикой для лидгенов] where command='stat_today' and Лидген in ( 'unicom24r' , ' ' ) group by Лидген )as varchar(max)),'Нет данных')+char(10)++char(10)+'/'+'stat_today'

--exec analytics.dbo.[Получение сообщения для телеграмм бота со статистикой для лидгенов] 'stat_month', '''unicom24r'' , ''bankiru'''

--select isnull(cast((select string_agg(Лидген +char(10)+text +char(10), char(10)) from dbo.[Оперативная витрина со статистикой для лидгенов] where command='stat_month' and Лидген in ('unicom24r' , 'bankiru')  )as varchar(max)),'Нет данных')+char(10)+'/'+'stat_month'