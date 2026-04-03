
create    procedure durationToDateTimeInterval
   @entered_dt datetime2='2020-04-03 13:53:47.0000000'
  ,@duration_full int =3629
  ,@login nvarchar(50)=''

as
begin

declare  @entered datetime2=@entered_dt
declare  @duration int =@duration_full

-- дата и время (час) начала
 declare @start_dt datetime,@next_dt datetime
 declare @CurrentHourDuration bigint

 create table #t (dt datetime,duration bigint)

 while @duration>0
 begin
      -- select @entered, @duration

       set @start_dt=format(@entered,'yyyyMMdd HH:00')
       set @next_dt= cast(format(dateadd(hour,1,@entered),'yyyyMMdd HH:00') as datetime)
 
       set @CurrentHourDuration= datediff(second,@entered,@next_dt)
 
       insert into #t select @start_dt, case when @duration>@CurrentHourDuration then @CurrentHourDuration else @duration end

       set @duration=@duration- @CurrentHourDuration
       set @entered= @next_dt


 end

 select [login]=@login,dt,duration from #t








 
end
