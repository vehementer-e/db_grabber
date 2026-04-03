
CREATE proc [dbo].[Новые лидгены]
as
begin

 SELECT td = UF_TYPE,       '',  
                    td = UF_SOURCE, '',  
                    td = CountAll, ''
				from
				(
					(
					select top 1000  UF_TYPE, UF_SOURCE , count(*) CountAll
					from Analytics.dbo.v_leads with (nolock)
					where id>19000000  and
					 ([Канал от источника] not in ('Инвестиции', 'Тест'))
					and isnull( cast(UF_SOURCE as nvarchar(1024)),'')<>''
					group by UF_TYPE, UF_SOURCE
					order by UF_TYPE,UF_SOURCE
					) as a1
					left join stg.files.leadRef2_buffer a2 with (nolock)
					on
					case when isnull( cast(a1.UF_TYPE as nvarchar(1024)),'')=''
						 then cast(a1.UF_SOURCE as nvarchar(1024))
		 
					else	
							cast(a1.UF_TYPE as nvarchar(1024))+' - '+ cast(a1.UF_SOURCE as nvarchar(1024))
					end

				=a2.[Тип-Источник]
				) 
				where [Тип-Источник] is null
				order by UF_TYPE,UF_SOURCE


				end