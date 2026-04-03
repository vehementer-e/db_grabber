
CREATE   PROC [_birs].[selling_traffic_stat]
@mode nvarchar(max) = 'update'
as
begin


IF 	@mode =  'update'

begin


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'D3413F50-FF12-4887-8914-3B123ED9CBE3'

exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'E5EAE794-D01D-4D5E-A48A-52B41C19C9FA'	 , 1


 end


 if @mode = 'select'
 begin



  --select [Поступление (без НДС)], [Поступление _(с НДС)], [Тип трафика (ПТС/Беззалог)], [Период оказания услуг] from   stg.files.[продажа трафика_stg]
  --order by 1
  select  [bezzalog_net]  [Поступление (без НДС)],    [bezzalog_net]/(1-0.2/1.2) [Поступление _(с НДС)] , 'Беззалог' [Тип трафика (ПТС/Беззалог)], month   [Период оказания услуг]    from   stg.files.[продажа трафика2_stg] where month <getdate() union all
  select  [pts_net]        ,  [pts_net]/(1-0.2/1.2) , 'ПТС', month       from   stg.files.[продажа трафика2_stg] where month <getdate()
  order by 1
 


 --select * from stg.files.[продажа трафика2_stg]
 --order by 1
 -- order by 1


end

end
