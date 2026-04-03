
CREATE proc [dbo].[sale_report_selfemployed_validation] as


select number номер, call1 ДатаЗаявки, checking КД, issued Выдан, productType ТипПродукта, productSubType ПодТипПродукта, origin МестоСоздания, status_crm Статус,  isSelfEmployed ПризнакСЗ, b.[номер заявки] РучнойСамозанятый, limitChoise ВыбранноеПредложение, inn from request a
left join Analytics.dbo.[_request_selfemployed_manual] b on a.number =  cast( b.[номер заявки] as varchar(max))

where issued >='20251201'

 and productType  in ( 'PTS', 'BIG INST')

 --and isnull(isSelfEmployed , 2) <>1 
 
and   ( limitChoise = 'selfEmployed' or productSubType like '%самоз%' or  b.[номер заявки] is not null) 
order by issued 