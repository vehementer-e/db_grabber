



CREATE     procedure  [dbo].[GetRelationDegree_uat_JSON]
 
as
set nocount on;
with cte as (
	select 
		versionName, 
		versionId	= Version_ID, 
		versionNumber,
		guid= cast(Code as nvarchar(36)),
		name = Name,
		parentName	= null,
		parentId	= cast(null as nvarchar(36)),
		--PublishOnSite,
		IsActive

		--select *
	from mds.[mdm].RelationDegree_uat
	--where CodeName = '000000001'
	
), cte_version as  (
	select distinct  VersionName, VersionId from cte
		
)

select 
	v.VersionName,
	t.json
from cte_version v	
outer apply (
select json = (
select 
	VersionId 'version.id',
	VersionName 'version.code', 
	items = 
	(select
			guid  , 
			name,
			--cast(PublishOnSite as bit) 'properties.publishOnSite',
			isActive = cast(IsActive as bit)
			--reasons = childs.data,
			--parent   ''
			from cte p  
			--outer apply
			--(
			--	select data = (select  id = c.Id, 
			--			name = c.Name, 
			--			parentId = p.id
			--			from cte c
			--		where c.ParentId = p.id
			--		for json path)
			--) childs
			--where p.VersionId = v.VersionId
			--		and p.ParentId is null
			for json path
	) 
	for json path
) )	 t
 


