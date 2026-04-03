CREATE         proc [_tg].[getBankBotMessage]
@command nvarchar(max),
--@partner_access nvarchar(max)
@chat_id bigint
WITH EXECUTE AS OWNER --не удалять эту строку
as
begin



if @command in (
'start'    
--'stat_today'    
--,'stat_yesterday'
--,'stat_week'     
--,'stat_month'    
--,'stat_quarter'  
--,'stat_last_month'    

)
begin
--declare @sql nvarchar(max) = 'select isnull(replace(cast((select string_agg(Юрлицо +char(10)+text +char(10), ''~'' ) WITHIN GROUP (ORDER BY Юрлицо ASC) from dbo.[Оперативная витрина со статистикой для партнеров] where command='''+@command+''' and Юрлицо in ('+@partner_access+')  )as nvarchar(max) ) , ''~'', ''———————————————''+char(10) ) ,''Нет данных'')+char(10)+''/''+'''+@command+''''
--select @sql
--exec  (@sql)

SELECT isnull(replace(cast((
					SELECT string_agg( TEXT + CHAR(10), ' ~ ') WITHIN
					GROUP (
							ORDER BY b.bank ASC
							)
					FROM _tg.projects_stat a
										join 	[_tg].[bankBot_USERS] b on a.type=b.bank+'-ref' and b.id=@chat_id
 
				--	WHERE command = @command
					) AS NVARCHAR(max)), ' ~ ', ' ——————————————— ' + CHAR(10)), ' Нет данных ') + CHAR(10) + '/' +@command
 
	return
		-- select * from  _tg.projects_stat
end		 
 
--select 1037811 id , 'psb' bank into [_tg].[bankBot_USERS] union all select 1037811, 'vtb' union all select 10378112, 'psb'
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