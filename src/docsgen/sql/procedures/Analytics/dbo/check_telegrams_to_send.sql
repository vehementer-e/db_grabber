CREATE  proc [dbo].[check_telegrams_to_send]
as


 select (
        SELECT
        value
        FROM
        OPENJSON((SELECT top 10 dt, id, text, recepients,  isRocket FROM analytics.dbo.log_telegrams WHERE TEXT <>'' order by dt FOR JSON PATH, ROOT('data')), '$.data')
      --  OPENJSON((SELECT top 10 dt, id, text, recepients,  case when dt<=dateadd(minute, - 30,  getdate()) then N'⚠ Неотправленное сообщение от '+ format(dt, 'dd-MMM HH:mm') else '' end old_message  FROM analytics.dbo.log_telegrams order by dt FOR JSON PATH, ROOT('data')), '$.data')
        FOR
        JSON path) json



		--select * 
		--FROM analytics.dbo.log_telegrams order by dt



--[{"value":"{\"dt\":\"2024-02-12T19:58:35.740\",\"id\":\"68CD6512-181A-4E02-A53C-B7436B6E7118\",\"recepients\":\"-4118384701\",\"old_message\":\"⚠ Неотправленное сообщение от 12-Feb 19:58\"}"},{"value":"{\"dt\":\"2024-02-12T19:59:31.293\",\"id\":\"FDEA76C8-5839-4920-BEA7-1CC267DE5474\",\"text\":\"9096887277 - Москва - ПТС\\r\\n9186085404 - Краснодарский край - ПТС\",\"recepients\":\"-1001842900912\",\"old_message\":\"⚠ Неотправленное сообщение от 12-Feb 19:59\"}"}]
