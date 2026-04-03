CREATE       proc [dbo].[bot_partner_get_message]
@command nvarchar(max),
--@partner_access nvarchar(max)
@chat_id bigint
--WITH EXECUTE AS OWNER --не удалять эту строку
as
begin



if @command in (
'stat_today'    
,'stat_yesterday'
,'stat_week'     
,'stat_month'    
,'stat_quarter'  
,'stat_last_month'    

)
begin
--declare @sql nvarchar(max) = 'select isnull(replace(cast((select string_agg(Юрлицо +char(10)+text +char(10), ''~'' ) WITHIN GROUP (ORDER BY Юрлицо ASC) from dbo.[Оперативная витрина со статистикой для партнеров] where command='''+@command+''' and Юрлицо in ('+@partner_access+')  )as nvarchar(max) ) , ''~'', ''———————————————''+char(10) ) ,''Нет данных'')+char(10)+''/''+'''+@command+''''
--select @sql
--exec  (@sql)
if  @chat_id in (select id from 	bot_partner_user_view where partner='*')
begin

SELECT isnull(replace(cast((
					SELECT string_agg(a.Юрлицо + CHAR(10) + TEXT + CHAR(10), ' ~ ') WITHIN
					GROUP (
							ORDER BY a.Юрлицо ASC
							)
					FROM dbo.[Оперативная витрина со статистикой для партнеров] a
										
 
					WHERE command = @command and [Выдано шт]>0
					) AS NVARCHAR(max)), ' ~ ', ' ——————————————— ' + CHAR(10)), ' Нет данных ') + CHAR(10) + '/' +@command
 end
 else 
 begin
SELECT isnull(replace(cast((
					SELECT string_agg(a.Юрлицо + CHAR(10) + TEXT + CHAR(10), ' ~ ') WITHIN
					GROUP (
							ORDER BY a.Юрлицо ASC
							)
					FROM dbo.[Оперативная витрина со статистикой для партнеров] a
										join 
										
										bot_partner_user b on   a.Юрлицо=b.Юрлицо  								
										and b.id=@chat_id  
 
					WHERE command = @command and b.id is not null
					) AS NVARCHAR(max)), ' ~ ', ' ——————————————— ' + CHAR(10)), ' Нет данных ') + CHAR(10) + '/' +@command

end

end

--select * from [_tg].[partnerBot_USERS]

if @command ='start'
select '
Список доступных команд - /help
'

if @command ='help'
select '
Доступные команды:

/stat_today - статистика за сегодня
/stat_yesterday - статистика за вчера
/stat_week - статистика за неделю     
/stat_month - статистика за месяц
/stat_last_month - статистика за месяц
/stat_quarter - статистика за квартал

/requests_today - заявки день в день
/plan_fact - план факт месяц   

'


end
--exec analytics.dbo.[Получение сообщения для телеграмм бота со статистикой для партнеров] 'start', '''bankiru-ref'' , ''bankiru'''
--exec dbo.[Получение сообщения для телеграмм бота со статистикой для лидгенов] 'stat_today', ' ''unicom24r'' , '' '' '
--
--select isnull(cast((select top 1 text from dbo.[Оперативная витрина со статистикой для лидгенов] where command='stat_today' and Лидген in ( 'unicom24r' , ' ' ) )as varchar(max)),'Нет данных')+char(10)++char(10)+'/'+'stat_today'

--exec analytics.dbo.[Получение сообщения для телеграмм бота со статистикой для лидгенов] 'help', '''unicom24r'' , '' '''


--select isnull(cast((select string_agg(Лидген +' '+text, char(13)) from dbo.[Оперативная витрина со статистикой для лидгенов] where command='stat_today' and Лидген in ( 'unicom24r' , ' ' ) group by Лидген )as varchar(max)),'Нет данных')+char(10)++char(10)+'/'+'stat_today'

--exec analytics.dbo.[Получение сообщения для телеграмм бота со статистикой для лидгенов] 'stat_month', '''unicom24r'' , ''bankiru'''

--select isnull(cast((select string_agg(Лидген +char(10)+text +char(10), char(10)) from dbo.[Оперативная витрина со статистикой для лидгенов] where command='stat_month' and Лидген in ('unicom24r' , 'bankiru')  )as varchar(max)),'Нет данных')+char(10)+'/'+'stat_month'