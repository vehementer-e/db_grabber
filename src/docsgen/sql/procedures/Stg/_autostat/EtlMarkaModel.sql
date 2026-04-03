
/*
exec _autostat.EtlMarkaModel @jsonData ='{}'
exec _autostat.EtlMarkaModel @jsonData = '[{"Marka":"Audi","Models":[{"ModelName":"A1","Generations":[{"GenerationName":"I","Modifications":[{"ModificationName":"1.4 AT/122/Бензин/Передний"},{"ModificationName":"1.4 AT/140/Бензин/Передний"}]},{"GenerationName":"I Рестайлинг","Modifications":[{"ModificationName":"1.4 AT/125/Бензин/Передний"}]}]}]}]'
select * from _autostat.Marka
select * from _autostat.Model
select * from _autostat.Generation
--truncate table _autostat.Model
*/
-- Usage: запуск процедуры с параметрами
-- EXEC [_autostat].[EtlMarkaModel] @jsonData = <value>;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure [_autostat].[EtlMarkaModel]
	@jsonData nvarchar(max)
as
begin
	
	
	create table #in_MarkaModel (
		Marka varchar(255),
		Model varchar(255),
		Generation varchar(255),
		Modification varchar(255)
	)
	insert into #in_MarkaModel(Marka, Model, Generation, Modification)
	select  brands.Marka,
		models.ModelName,
		Generations.Generation,
		Modifications.Modification
	FROM OPENJSON(@jsonData)
  WITH (
    Marka varchar(255) 'strict $.Marka',
    Models NVARCHAR(MAX) '$.Models' AS JSON
  ) brands
  OUTER APPLY OPENJSON(Models)
  WITH (ModelName NVARCHAR(255) '$.ModelName',
	Generations NVARCHAR(max) '$.Generations' as JSON
	)
  models
   OUTER APPLY OPENJSON(Generations)
  WITH (Generation NVARCHAR(255) '$.GenerationName',
	Modifications NVARCHAR(max) '$.Modifications' as JSON
	) Generations
   OUTER APPLY OPENJSON(Modifications)
  WITH (Modification NVARCHAR(255) '$.ModificationName'
	) Modifications
  ;
  create table #result_marka (
	Action nvarchar(255),
	MarkaId uniqueidentifier,
	Marka varchar(255),
	isMarkaDeleted bit
	
  )
  create table #result_model (
	Action nvarchar(255),
	Marka varchar(255),
	ModelId uniqueidentifier,
	Model varchar(255),
	isModelDeleted bit
  )

  create table #result_Generation (
	Action nvarchar(255),
	Marka varchar(255),
	Model varchar(255),
	GenerationId uniqueidentifier,
	Generation varchar(255),
	isGenerationDeleted bit

  )

set xact_abort on

begin tran

  merge _autostat.Marka t
  using (
	select distinct Marka from #in_MarkaModel
  ) s on s.Marka = t.Name
  when not matched then insert (Name, InsertedDate)
  values(s.Marka, getdate())
  When matched then UPDATE
	set isDeleted = 0,
		InsertedDate = iif(isDeleted =1, getdate(), t.InsertedDate),
		DeleteDate = null
  WHEN NOT MATCHED BY SOURCE  then UPDATE
	set isDeleted = 1,
		DeleteDate = getdate()
OUTPUT $action, 
	ISNULL(DELETED.IdGuid, INSERTED.IdGuid) MarkaId,
	iif($action = 'UPDATE', INSERTED.Name, ISNULL(DELETED.Name, INSERTED.Name))  Marka,
	iif($action = 'UPDATE', INSERTED.isDeleted, ISNULL(DELETED.isDeleted, INSERTED.isDeleted)) isMarkaDeleted

INTO #result_marka;

  merge _autostat.Model t
  using (
	select	distinct 
		MarkaId,
		mm.Marka,
		isMarkaDeleted,
		mm.Model as Model
	from #in_MarkaModel mm
		INNER join #result_marka m on m.Marka = mm.Marka 
	) s
	on s.MarkaId = t.MarkaId
		and s.Model = t.Name
	when not matched 
	then insert (MarkaId, Name, InsertedDate)
	values(s.MarkaId, s.Model, getdate())
	when matched then update
		set isDeleted = isMarkaDeleted
			,InsertedDate = iif(isDeleted =1 and isMarkaDeleted = 0, getdate(), InsertedDate)
			,DeleteDate = iif(isMarkaDeleted= 0 , null, getdate())
	 WHEN NOT MATCHED BY SOURCE  then update
	set isDeleted = 1,
		DeleteDate = getdate()
	
	OUTPUT $action, 
		s.Marka as Marka,
		ISnull(DELETED.idGuid, INSERTED.idGuid) AS ModelId, 
		iif($action = 'UPDATE', INSERTED.Name, ISNULL(DELETED.Name, INSERTED.Name))  Model,
		iif($action = 'UPDATE', INSERTED.isDeleted, ISNULL(DELETED.isDeleted, INSERTED.isDeleted)) isModelDeleted
		
	INTO #result_model;
	

 merge _autostat.Generation t
  using (
	select	 distinct 
		mm.Marka,
		mm.Model,
		m.ModelId,
		m.isModelDeleted,
		mm.Generation

	from #in_MarkaModel mm
	inner join #result_model m on m.Marka = mm.marka
		and m.Model = mm.Model
		
	) s
	on s.ModelId= t.ModelId
		and s.Generation= t.Name
	when not matched 
	then insert (ModelId, Name, InsertedDate)
	values(s.ModelId, s.Generation, getdate())
	when matched then update
		set isDeleted = isModelDeleted
			,InsertedDate = iif(isDeleted =1 and isModelDeleted = 0, getdate(), InsertedDate)
			,DeleteDate = iif(isModelDeleted= 0 , null, getdate())
	 WHEN NOT MATCHED BY SOURCE  then update
	set isDeleted = 1,
		DeleteDate = getdate()
	OUTPUT $action, 
		s.Marka as Marka,
		s.Model,
		ISnull(DELETED.idGuid, INSERTED.idGuid) AS GenerationId, 
		iif($action = 'UPDATE', INSERTED.Name, ISNULL(DELETED.Name, INSERTED.Name))  Generation,
		iif($action = 'UPDATE', INSERTED.isDeleted, ISNULL(DELETED.isDeleted, INSERTED.isDeleted)) isGenerationDeleted
		
	INTO #result_Generation;

 merge _autostat.Modification t
  using (
	select	 distinct 
		mm.Marka,
		mm.Model,
		mm.Generation,
		m.GenerationId,
		m.isGenerationDeleted,
		mm.Modification
	from #in_MarkaModel mm
	inner join #result_Generation m on m.Marka = mm.marka
		and m.Model = mm.Model
		and m.Generation = mm.Generation
		
	) s
	on s.GenerationId= t.GenerationId
		and s.Generation= t.Name
	when not matched 
	then insert (GenerationId, Name, InsertedDate)
	values(s.GenerationId, s.Modification, getdate())
	when matched then update
		set isDeleted = isGenerationDeleted
			,InsertedDate = iif(isDeleted =1 and isGenerationDeleted = 0, getdate(), InsertedDate)
			,DeleteDate = iif(isGenerationDeleted= 0 , null, getdate())
	 WHEN NOT MATCHED BY SOURCE  then update
	set isDeleted = 1,
		DeleteDate = getdate()
	;

commit tran

end
