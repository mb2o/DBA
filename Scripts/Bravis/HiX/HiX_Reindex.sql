use [HIX_PRODUCTIE];
go

/****** Object:  StoredProcedure [dbo].[Ezis_ReIndex]    Script Date: 7-5-2020 16:46:06 ******/

set ansi_nulls on;
go

set quoted_identifier on;
go

alter procedure dbo.Ezis_ReIndex 
	@Mode              sysname = null, 
	@PlayTimeInMinutes int     = 60, 
	@MaxAvgSeconds     int     = 900, 
	@LikeTableName     sysname = null
with recompile
as
	begin
		set nocount on;
		declare 
			@PeriodType varchar(2);
		declare 
			@PeriodAmount int;
		declare 
			@ReindexMode int;
		-----------------------------------------------------------------------------
		--- !!! pas hier de indexhoudbaarheidsdatum en de Reindex methode aan !!! ---
		-----------------------------------------------------------------------------
		set @PeriodType = 'D';        -- M=maanden, W=weken, D=dagen
		set @PeriodAmount = 0;        -- aantal maanden/weken of dagen, als de index ouder dan deze waarde is komt de index in aanmerking voor herindexering
		set @ReindexMode = 3;         -- 1='dbcc dbreindex', 2 = 'alter index offline', 3 = 'alter index online'
		-------------------------------------------------------
		--- !!! hieronder niets aanpassen               !!! ---
		-------------------------------------------------------
		if @mode = 'clear'
			begin
				if OBJECT_ID('dbo.EzisIndexLog') is not null
					drop table dbo.EzisIndexLog;
				return;
		end;

/*
update dbo.EzisIndexLog set IndexStart = DateAdd(dd, -7, IndexStart), IndexStop = DateAdd(dd, -7, IndexStop)
*/
		declare 
			@ScriptStartTime datetime;
		set @ScriptStartTime = GETDATE();
		declare 
			@IndexStillGoodDate datetime;
		set @IndexStillGoodDate = case @PeriodType
									  when 'M'
									  then DATEADD(mm, -ISNULL(@PeriodAmount, 1), GETDATE()) - SUBSTRING(CONVERT(nvarchar(12), GETDATE(), 114), 1, 12)
									  when 'W'
									  then DATEADD(ww, -ISNULL(@PeriodAmount, 1), GETDATE()) - SUBSTRING(CONVERT(nvarchar(12), GETDATE(), 114), 1, 12)
									  when 'D'
									  then DATEADD(dd, -ISNULL(@PeriodAmount, 1), GETDATE()) - SUBSTRING(CONVERT(nvarchar(12), GETDATE(), 114), 1, 12)
									  when 'Mi'
									  then DATEADD(mi, -ISNULL(@PeriodAmount, 1), GETDATE()) - SUBSTRING(CONVERT(nvarchar(12), GETDATE(), 114), 1, 12)
								  else null
								  end;
		if OBJECT_ID('dbo.EzisIndexLog') is null
			begin
				create table dbo.EzisIndexLog(
					TableId      int, 
					IndexName    sysname, 
					IndexStart   datetime, 
					IndexStop    datetime, 
					NrOfRows     int, 
					ScriptStart  datetime, 
					ReIndexQuery varchar(8000));
				create clustered index IndexLog on dbo.EzisIndexLog(TableID, IndexName, IndexStart);
		end;
		insert into dbo.EzisIndexLog
		select id as TableID, 
			   name as IndexName, 
			   null as IndexStart, 
			   null as IndexStop, 
			   rowcnt as NrOfRows, 
			   @ScriptStartTime as ScriptStart, 
			   null as ReIndexQuery
		from sysindexes as si
		where indid not in (0, 255) and 
		OBJECTPROPERTY(id, 'IsUserTable') = 1 and 
		INDEXPROPERTY(id, name, 'IsStatistics') = 0 and 
		(ISNULL(@LikeTableName, '') = '' or 
		 OBJECT_NAME(id) like @LikeTableName) and 
		not exists
		(
			select *
			from dbo.EzisIndexLog as il with(nolock)
			where il.TableId = si.id and 
				  il.IndexName = si.name and 
				  (IndexStart is null or 
				   IndexStart >= @IndexStillGoodDate)
		);
		declare 
			@TableID int;
		declare 
			@IndexName sysname;
		declare 
			@Q varchar(8000);
		declare 
			@Start datetime;
		declare 
			@NrOfRows int;
		if @mode = 'show'
			begin
				select case @ReindexMode
						   when 1
						   then 'dbcc dbreindex([' + OBJECT_NAME(il.TableId) + '],[' + il.IndexName + '])'
						   when 2
						   then case
									when NrOfRows between 0 and 100000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR = 100, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 100001 and 1000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  99, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 1000001 and 5000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  98, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 5000001 and 10000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  97, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 10000001 and 50000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  96, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows >= 50000001
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
								else 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(online = OFF, SORT_IN_TEMPDB = ON)'
								end
						   when 3
						   then case
									when NrOfRows between 0 and 100000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR = 100, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
								else '] reorganize'
																												   end
									when NrOfRows between 100001 and 1000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  99, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
					   else '] reorganize'
																												   end
									when NrOfRows between 1000001 and 5000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  98, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows between 5000001 and 10000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  97, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows between 10000001 and 50000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  96, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
			else '] reorganize'
																												   end
									when NrOfRows >= 50000001
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
		else '] reorganize'
																												   end
		else 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																						   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																								not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																						   then '] rebuild with(online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
		else '] reorganize'
																					   end
								end
		else 'Herindexeren [' + OBJECT_NAME(il.TableId) + '],[' + il.IndexName + ']'
					   end as ReIndexQuery, 
					   GemDuurInSec, 
					   NrOfRows, 
					   LaatsteReIndexDatum, 
					   DATEDIFF(dd, LaatsteReIndexDatum, GETDATE()) as AantalDagenOud
				from
					dbo.EzisIndexLog as il
				left outer join
				(
					select TableId, 
						   IndexName, 
						   AVG(DATEDIFF(ss, IndexStart, IndexStop)) as GemDuurInSec, 
						   MAX(IndexStop) as LaatsteReIndexDatum
					from dbo.EzisIndexLog
					where IndexStop is not null and 
						  IndexStop >= DATEADD(dd, -60, GETDATE())
					group by TableId, 
							 IndexName
				) as il2 on il.TableId = il2.TableId and 
							il.IndexName = il2.IndexName
				where IndexStart is null
					  and 
					  --   and (il.IndexName not like '%VRLIJST_VROPSLG%')
					  --and (il.IndexName not like '%METINGEN_METINGEN_M%') 
					  --and (il.IndexName not like '%SEELOG_SEELOGI%')
					  --and (il.IndexName not like '%MUTLOG_MUTLOG%')
					  --and (NrOfRows <= 500000000)   -- 20181114 MBL maximaliseren REINDEX 
					  NrOfRows > 0   -- 20181114 MBL Start REINDEX
					  and 
					  (ISNULL(@LikeTableName, '') = '' or 
					   OBJECT_NAME(il.TableId) like @LikeTableName)
				order by ISNULL(DATEDIFF(dd, LaatsteReIndexDatum, GETDATE()), 999) desc, 
						 NrOfRows asc;
		end;
		if @Mode = 'reindex'
			begin
				while GETDATE() < DATEADD(mi, @PlayTimeInMinutes, @ScriptStartTime)
					begin
						set @TableId = null;
						set @ReindexMode = 3; -- 20170616 BVS RMR

						select top 1 @TableId = il.TableId, 
									 @IndexName = il.IndexName, 
									 @NrOfRows = il.NrOfRows
						from dbo.EzisIndexLog as il
						where IndexStart is null
							  and
							  --   and (il.IndexName not like '%VRLIJST_VROPSLG%') 
							  il.IndexName not like '%METINGEN_METINGEN%' 
							  --and (il.IndexName not like '%SEELOG_SEELOGI%')
							  and 
							  il.IndexName not like '%MUTLOG_MUTLOG%' and 
							  NrOfRows <= 500000000   -- 20181114 MBL maximaliseren REINDEX
							  and 
							  NrOfRows > 100000   -- 20181114 MBL Start REINDEX

							  and 
							  (ISNULL(@LikeTableName, '') = '' or 
							   OBJECT_NAME(TableId) like @LikeTableName)
						order by ISNULL(DATEDIFF(dd,
						(
							select MAX(IndexStop)
							from dbo.EzisIndexLog as il2
							where il.TableId = il2.TableId and 
								  il.IndexName = il2.IndexName and 
								  IndexStop is not null
						), GETDATE()), 999) desc, 
								 NrOfRows asc;
						if @TableId is null
							begin
								break;
						end;

						/* Toegevoegd voor bepaling van @reindexmode - 20171616 */
						if exists
						(
							select SchemaName = OBJECT_SCHEMA_NAME(p.object_id), 
								   ObjectName = OBJECT_NAME(p.object_id), 
								   IndexName = si.name, 
								   p.object_id, 
								   p.index_id, 
								   au.type_desc
							from
								sys.system_internals_allocation_units as au --Has allocation type
							join
								sys.system_internals_partitions as p --Has an Index_ID
								on au.container_id = p.partition_id
							join
								sys.indexes as si --For the name of the index
								on si.object_id = p.object_id and 
								   si.index_id = p.index_id
							where au.type_desc = 'LOB_DATA' and 
								  p.object_id = @TableID and 
								  si.name = @IndexName
						)
							begin
								set @ReindexMode = 2;
						end;

						/* EINDE TOEVOEGING */

						select @Q = case @ReindexMode
										when 1
										then 'dbcc dbreindex([' + OBJECT_NAME(@TableId) + '],[' + @IndexName + '])'
										when 2
										then case
												 when @NrOfRows between 0 and 100000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR = 100, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 100001 and 1000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  99, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 1000001 and 5000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  98, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 5000001 and 10000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  97, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 10000001 and 50000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  96, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows >= 50000001
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
											 else 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
											 end
										when 3
										then case
												 when @NrOfRows between 0 and 100000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR = 100, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
											 else '] reorganize'
																															end
												 when @NrOfRows between 100001 and 1000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  99, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
							   else '] reorganize'
																															end
												 when @NrOfRows between 1000001 and 5000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  98, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
						else '] reorganize'
																															end
												 when @NrOfRows between 5000001 and 10000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  97, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
						else '] reorganize'
																															end
												 when @NrOfRows between 10000001 and 50000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  96, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
								else '] reorganize'
																															end
												 when @NrOfRows >= 50000001
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
							else '] reorganize'
																															end
							else 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																										   when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																												not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																										   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
							else '] reorganize'
																									   end
											 end
									end;
						raiserror(@Q, 0, 1) with nowait;
						set @Start = GETDATE();
						update dbo.EzisIndexLog
						set 
							IndexStart = @Start
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart is null;
						update dbo.EzisIndexLog
						set 
							ReIndexQuery = CONVERT(varchar(8000), @Q)
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart = @Start;
						exec (@Q);
						update dbo.EzisIndexLog
						set 
							IndexStop = GETDATE()
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart = @Start;
		end;
				raiserror('Done', 0, 1) with nowait;
		end;
		if @Mode = 'reindex_resume'
			begin
				create table #EZIS_Reindex_resume(
					IndexName           varchar(255), 
					ReindexQuery        varchar(255), 
					GemDuurInSec        integer, 
					NrOfRows            integer, 
					LaatsteReindexDatum datetime, 
					AantalDagenOud      integer);
				set @MaxAvgSeconds = 60;   --20181116 RMR
				insert into #EZIS_Reindex_resume
				select il.indexname, 
					   case @ReindexMode
						   when 1
						   then 'dbcc dbreindex([' + OBJECT_NAME(il.TableId) + '],[' + il.IndexName + '])'
						   when 2
						   then case
									when NrOfRows between 0 and 100000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR = 100, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 100001 and 1000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  99, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 1000001 and 5000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  98, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 5000001 and 10000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  97, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 10000001 and 50000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  96, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows >= 50000001
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
								else 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
								end
						   when 3
						   then case
									when NrOfRows between 0 and 100000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR = 100, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
								else '] reorganize'
																												   end
									when NrOfRows between 100001 and 1000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  99, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
					   else '] reorganize'
																												   end
									when NrOfRows between 1000001 and 5000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  98, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows between 5000001 and 10000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  97, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows between 10000001 and 50000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  96, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows >= 50000001
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
			else 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																							   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																									not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																							   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
			else '] reorganize'
																						   end
								end
		else 'Herindexeren [' + OBJECT_NAME(il.TableId) + '],[' + il.IndexName + ']'
					   end as ReIndexQuery, 
					   GemDuurInSec, 
					   NrOfRows, 
					   LaatsteReIndexDatum, 
					   DATEDIFF(dd, LaatsteReIndexDatum, GETDATE()) as AantalDagenOud
				from
					dbo.EzisIndexLog as il
				left outer join
				(
					select TableId, 
						   IndexName, 
						   AVG(DATEDIFF(ss, IndexStart, IndexStop)) as GemDuurInSec, 
						   MAX(IndexStop) as LaatsteReIndexDatum
					from dbo.EzisIndexLog
					where IndexStop is not null and 
						  IndexStop >= DATEADD(dd, -60, GETDATE())
					group by TableId, 
							 IndexName
				) as il2 on il.TableId = il2.TableId and 
							il.IndexName = il2.IndexName
				where IndexStart is null
					  and 
					  --		and ((il.IndexName not like '%VRLIJST_LSTOPSLG%') 
					  GemDuurInSec > @MaxAvgSeconds
					  --		and (NrOfRows <= 25000000)  --20181114 MBL maximaliseren FAST REINDEX
					  and 
					  NrOfRows > 0  --20181114 MBL Start waarde
					  and 
					  (ISNULL(@LikeTableName, '') = '' or 
					   OBJECT_NAME(il.TableId) like @LikeTableName)
				order by ISNULL(DATEDIFF(dd, LaatsteReIndexDatum, GETDATE()), 999) desc, 
						 NrOfRows asc;
				while GETDATE() < DATEADD(mi, @PlayTimeInMinutes, @ScriptStartTime)
					begin

						/****************************************************************************************/
						if
						(
							select COUNT(*)
							from sys.index_resumable_operations
						) > 0
							begin
								print N'Groter dan 1';
								-- Toon de indexes die gepauzeerd zijn
								declare 
									@ResumeQuery varchar(2000);
								set @ResumeQuery =
								(
									select top 1
									--					'ALTER INDEX [' + i.name + '] on dbo.[' + o.name + '] RESUME with(MAX_DURATION='+ @PlayTimeInMinutes +')' AS ResumeQry
									'ALTER INDEX [' + i.name + '] on dbo.[' + o.name + '] RESUME with(MAX_DURATION=1)' as ResumeQry
									from sys.index_resumable_operations as i, 
										 sys.objects as o
									where i.object_id = o.object_id
									order by percent_complete desc
								);

								-- Neem de index die het hoogste percentage heeft
								raiserror(@ResumeQuery, 0, 1) with nowait;
								exec (@ResumeQuery);
						end;
						if GETDATE() < DATEADD(mi, @PlayTimeInMinutes, @ScriptStartTime)
							begin

								/***************************************************************************************/
								set @TableId = null;
								set @ReindexMode = 3; -- 20170616 BVS RMR

								select top 1 @TableId = il.TableId, 
											 @IndexName = il.IndexName, 
											 @NrOfRows = il.NrOfRows
								from dbo.EzisIndexLog as il
								where IndexStart is null
									  and
									  --   and (il.IndexName not like '%VRLIJST_VROPSLG%')
									  --and (il.IndexName not like '%METINGEN_METINGEN%') 
									  --and (il.IndexName not like '%SEELOG_SEELOGI%')
									  --and (il.IndexName not like '%MUTLOG_MUTLOG%')
									  --and (NrOfRows <= 500000000)   -- 20181114 MBL maximaliseren REINDEX
									  --and (NrOfRows >     100000)   -- 20181114 MBL Start REINDEX 
									  il.IndexName collate SQL_Latin1_General_CP1_CI_AS in
								(
									select IndexName
									from #EZIS_Reindex_resume
								) and 
									  (ISNULL(@LikeTableName, '') = '' or 
									   OBJECT_NAME(TableId) like @LikeTableName)
								order by ISNULL(DATEDIFF(dd,
								(
									select MAX(IndexStop)
									from dbo.EzisIndexLog as il2
									where il.TableId = il2.TableId and 
										  il.IndexName = il2.IndexName and 
										  IndexStop is not null
								), GETDATE()), 999) desc, 
										 NrOfRows asc;
								if @TableId is null
									begin
										break;
								end;

								/* Toegevoegd voor bepaling van @reindexmode - 20171616 */
								if exists
								(
									select SchemaName = OBJECT_SCHEMA_NAME(p.object_id), 
										   ObjectName = OBJECT_NAME(p.object_id), 
										   IndexName = si.name, 
										   p.object_id, 
										   p.index_id, 
										   au.type_desc
									from
										sys.system_internals_allocation_units as au --Has allocation type
									join
										sys.system_internals_partitions as p --Has an Index_ID
										on au.container_id = p.partition_id
									join
										sys.indexes as si --For the name of the index
										on si.object_id = p.object_id and 
										   si.index_id = p.index_id
									where au.type_desc = 'LOB_DATA' and 
										  p.object_id = @TableID and 
										  si.name = @IndexName
								)
									begin
										set @ReindexMode = 3;
								end;

								/* EINDE TOEVOEGING */

								select @Q = case @ReindexMode
												when 1
												then 'dbcc dbreindex([' + OBJECT_NAME(@TableId) + '],[' + @IndexName + '])'
												when 2
												then case
														 when @NrOfRows between 0 and 100000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR = 100, online = OFF, SORT_IN_TEMPDB = ON)'
														 when @NrOfRows between 100001 and 1000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  99, online = OFF, SORT_IN_TEMPDB = ON)'
														 when @NrOfRows between 1000001 and 5000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  98, online = OFF, SORT_IN_TEMPDB = ON)'
														 when @NrOfRows between 5000001 and 10000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  97, online = OFF, SORT_IN_TEMPDB = ON)'
														 when @NrOfRows between 10000001 and 50000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  96, online = OFF, SORT_IN_TEMPDB = ON)'
														 when @NrOfRows >= 50000001
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
													 else 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
													 end
												when 3
												then case
														 when @NrOfRows between 0 and 100000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																		when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																			 not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																																		then '] rebuild with(FILLFACTOR = 100, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
													 else '] reorganize'
																																	end
														 when @NrOfRows between 100001 and 1000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																		when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																			 not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																																		then '] rebuild with(FILLFACTOR =  99, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
									   else '] reorganize'
																																	end
														 when @NrOfRows between 1000001 and 5000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																		when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																			 not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																																		then '] rebuild with(FILLFACTOR =  98, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
								else '] reorganize'
																																	end
														 when @NrOfRows between 5000001 and 10000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																		when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																			 not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																																		then '] rebuild with(FILLFACTOR =  97, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
								else '] reorganize'
																																	end
														 when @NrOfRows between 10000001 and 50000000
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																		when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																			 not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																																		then '] rebuild with(FILLFACTOR =  96, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
										else '] reorganize'
																																	end
														 when @NrOfRows >= 50000001
														 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																		when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																			 not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																																		then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
									else '] reorganize'
																																	end
									else 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																												   when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																														not exists
								(
									select *
									from syscolumns
									where xtype in (34, 35, 99) and 
									syscolumns.id = @TableId
								)
																												   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, RESUMABLE = ON, MAX_DURATION = 1)'
									else '] reorganize'
																											   end
													 end
											end;
								raiserror(@Q, 0, 1) with nowait;
								set @Start = GETDATE();
								update dbo.EzisIndexLog
								set 
									IndexStart = @Start
								where TableId = @TableId and 
									  IndexName = @IndexName and 
									  IndexStart is null;
								update dbo.EzisIndexLog
								set 
									ReIndexQuery = CONVERT(varchar(8000), @Q)
								where TableId = @TableId and 
									  IndexName = @IndexName and 
									  IndexStart = @Start;
								exec (@Q);
								update dbo.EzisIndexLog
								set 
									IndexStop = GETDATE()
								where TableId = @TableId and 
									  IndexName = @IndexName and 
									  IndexStart = @Start;
						end;
						raiserror('Done', 0, 1) with nowait;
		end;
		end;
		if @mode = 'reindex_fast'
			begin
				--set @MaxAvgSeconds = 60   --20181116 RMR
				create table #EZIS_Reindex_fast(
					IndexName           varchar(255), 
					ReindexQuery        varchar(255), 
					GemDuurInSec        integer, 
					NrOfRows            integer, 
					LaatsteReindexDatum datetime, 
					AantalDagenOud      integer);
				insert into #EZIS_Reindex_fast
				select il.indexname, 
					   case @ReindexMode
						   when 1
						   then 'dbcc dbreindex([' + OBJECT_NAME(il.TableId) + '],[' + il.IndexName + '])'
						   when 2
						   then case
									when NrOfRows between 0 and 100000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR = 100, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 100001 and 1000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  99, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 1000001 and 5000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  98, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 5000001 and 10000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  97, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows between 10000001 and 50000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  96, online = OFF, SORT_IN_TEMPDB = ON)'
									when NrOfRows >= 50000001
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
								else 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
								end
						   when 3
						   then case
									when NrOfRows between 0 and 100000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR = 100, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
								else '] reorganize'
																												   end
									when NrOfRows between 100001 and 1000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  99, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
					   else '] reorganize'
																												   end
									when NrOfRows between 1000001 and 5000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  98, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows between 5000001 and 10000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  97, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows between 10000001 and 50000000
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  96, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
				else '] reorganize'
																												   end
									when NrOfRows >= 50000001
									then 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																													   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																															not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																													   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
			else '] reorganize'
																												   end
		else 'alter index [' + il.IndexName + '] on dbo.[' + OBJECT_NAME(il.TableId) + case
																						   when INDEXPROPERTY(il.TableId, il.IndexName, 'IsClustered') = 0 or 
																								not exists
				(
					select *
					from syscolumns
					where xtype in (34, 35, 99) and 
					syscolumns.id = il.TableId
				)
																						   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
		else '] reorganize'
																					   end
								end
						else 'Herindexeren [' + OBJECT_NAME(il.TableId) + '],[' + il.IndexName + ']'
					   end as ReIndexQuery, 
					   GemDuurInSec, 
					   NrOfRows, 
					   LaatsteReIndexDatum, 
					   DATEDIFF(dd, LaatsteReIndexDatum, GETDATE()) as AantalDagenOud
				from
					dbo.EzisIndexLog as il
				left outer join
				(
					select TableId, 
						   IndexName, 
						   AVG(DATEDIFF(ss, IndexStart, IndexStop)) as GemDuurInSec, 
						   MAX(IndexStop) as LaatsteReIndexDatum
					from dbo.EzisIndexLog
					where IndexStop is not null and 
						  IndexStop >= DATEADD(dd, -60, GETDATE())
					group by TableId, 
							 IndexName
				) as il2 on il.TableId = il2.TableId and 
							il.IndexName = il2.IndexName
				where IndexStart is null
					  and 
					  --		and ((il.IndexName not like '%VRLIJST_LSTOPSLG%') 
					  GemDuurInSec <= @MaxAvgSeconds
					  --		and (NrOfRows <= 25000000)  --20181114 MBL maximaliseren FAST REINDEX
					  and 
					  NrOfRows > 0  --20181114 MBL Start waarde
					  and 
					  (ISNULL(@LikeTableName, '') = '' or 
					   OBJECT_NAME(il.TableId) like @LikeTableName)
				order by ISNULL(DATEDIFF(dd, LaatsteReIndexDatum, GETDATE()), 999) desc, 
						 NrOfRows asc;

				/************************************************************************************************/
				while GETDATE() < DATEADD(mi, @PlayTimeInMinutes, @ScriptStartTime)
					begin
						set @TableId = null;
						set @ReindexMode = 3;    -- 20170616 BVS RMR
						set @NrOfRows = 0;
						select top 1 @TableId = il.TableId, 
									 @IndexName = il.IndexName, 
									 @NrOfRows = il.NrOfRows
						from dbo.EzisIndexLog as il
						where IndexStart is null
							  and

							  --and (il.IndexName not like '%VRLIJST_LSTOPSLG%') 
							  il.IndexName not like '%MUTLOG_MUTLOG%'
							  --			and (NrOfRows <= 10000000)
							  and 
							  il.IndexName collate SQL_Latin1_General_CP1_CI_AS in
						(
							select IndexName
							from #EZIS_Reindex_fast
						) and 
							  (ISNULL(@LikeTableName, '') = '' or 
							   OBJECT_NAME(TableId) like @LikeTableName)
						order by ISNULL(DATEDIFF(dd,
						(
							select MAX(IndexStop)
							from dbo.EzisIndexLog as il2
							where il.TableId = il2.TableId and 
								  il.IndexName = il2.IndexName and 
								  IndexStop is not null
						), GETDATE()), 999) desc, 
								 NrOfRows asc;
						if @TableId is null
							begin
								break;
						end;

						/* Toegevoegd voor bepaling van @reindexmode - 20171616 */
						if exists
						(
							select SchemaName = OBJECT_SCHEMA_NAME(p.object_id), 
								   ObjectName = OBJECT_NAME(p.object_id), 
								   IndexName = si.name, 
								   p.object_id, 
								   p.index_id, 
								   au.type_desc
							from
								sys.system_internals_allocation_units as au --Has allocation type
							join
								sys.system_internals_partitions as p --Has an Index_ID
								on au.container_id = p.partition_id
							join
								sys.indexes as si --For the name of the index
								on si.object_id = p.object_id and 
								   si.index_id = p.index_id
							where au.type_desc = 'LOB_DATA' and 
								  p.object_id = @TableID and 
								  si.name = @IndexName
						)
							begin
								set @ReindexMode = 2;
						end;

						/* EINDE TOEVOEGING */

						select @Q = case @ReindexMode
										when 1
										then 'dbcc dbreindex([' + OBJECT_NAME(@TableId) + '],[' + @IndexName + '])'
										when 2
										then case
												 when @NrOfRows between 0 and 100000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR = 100, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 100001 and 1000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  99, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 1000001 and 5000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  98, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 5000001 and 10000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  97, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows between 10000001 and 50000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  96, online = OFF, SORT_IN_TEMPDB = ON)'
												 when @NrOfRows >= 50000001
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
											 else 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] rebuild with(FILLFACTOR =  95, online = OFF, SORT_IN_TEMPDB = ON)'
											 end
										when 3
										then case
												 when @NrOfRows between 0 and 100000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR = 100, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
											 else '] reorganize'
																															end
												 when @NrOfRows between 100001 and 1000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  99, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
							   else '] reorganize'
																															end
												 when @NrOfRows between 1000001 and 5000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  98, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
						else '] reorganize'
																															end
												 when @NrOfRows between 5000001 and 10000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  97, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
						else '] reorganize'
																															end
												 when @NrOfRows between 10000001 and 50000000
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  96, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
								else '] reorganize'
																															end
												 when @NrOfRows >= 50000001
												 then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																																when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																																	 not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																																then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
							else '] reorganize'
																															end
							else 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + case
																										   when INDEXPROPERTY(@TableId, @IndexName, 'IsClustered') = 0 or 
																												not exists
						(
							select *
							from syscolumns
							where xtype in (34, 35, 99) and 
							syscolumns.id = @TableId
						)
																										   then '] rebuild with(FILLFACTOR =  95, online = ON, MAXDOP=12, SORT_IN_TEMPDB = ON)'
							else '] reorganize'
																									   end
											 end
									end;
						raiserror(@Q, 0, 1) with nowait;
						set @Start = GETDATE();
						update dbo.EzisIndexLog
						set 
							IndexStart = @Start
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart is null;
						update dbo.EzisIndexLog
						set 
							ReIndexQuery = CONVERT(varchar(8000), @Q)
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart = @Start;
						exec (@Q);
						update dbo.EzisIndexLog
						set 
							IndexStop = GETDATE()
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart = @Start;
		end;
				raiserror('Done', 0, 1) with nowait;
		end;
		if @Mode = 'reorganize'
			begin
				while GETDATE() < DATEADD(mi, @PlayTimeInMinutes, @ScriptStartTime)
					begin
						set @TableId = null;
						set @ReindexMode = 3; -- 20170616 BVS RMR

						select top 1 @TableId = il.TableId, 
									 @IndexName = il.IndexName, 
									 @NrOfRows = il.NrOfRows
						from dbo.EzisIndexLog as il
						where IndexStart is null
							  and
							  --		    and (il.IndexName not like '%VRLIJST_VROPSLG%') 
							  il.IndexName not like '%METINGEN_METINGEN%'
							  --          and (il.IndexName not like '%SEELOG_SEELOGI%') 
							  --			and (il.IndexName not like '%ORDERCOM_ORDPLUG%')
							  --			and (il.IndexName not like '%ORDERCOM_ORDER%')
							  and 
							  il.IndexName not like '%MUTLOG_MUTLOG%' and 
							  NrOfRows >= 500000000   -- 20181114 MBL maximaliseren REINDEX
							  --			and (NrOfRows >    5000000)   -- 20181114 MBL Start REINDEX

							  and 
							  (ISNULL(@LikeTableName, '') = '' or 
							   OBJECT_NAME(TableId) like @LikeTableName)
						order by ISNULL(DATEDIFF(dd,
						(
							select MAX(IndexStop)
							from dbo.EzisIndexLog as il2
							where il.TableId = il2.TableId and 
								  il.IndexName = il2.IndexName and 
								  IndexStop is not null
						), GETDATE()), 999) desc, 
								 NrOfRows asc;
						if @TableId is null
							begin
								break;
						end;

						/* Toegevoegd voor bepaling van @reindexmode - 20171616 */
						if exists
						(
							select SchemaName = OBJECT_SCHEMA_NAME(p.object_id), 
								   ObjectName = OBJECT_NAME(p.object_id), 
								   IndexName = si.name, 
								   p.object_id, 
								   p.index_id, 
								   au.type_desc
							from
								sys.system_internals_allocation_units as au --Has allocation type
							join
								sys.system_internals_partitions as p --Has an Index_ID
								on au.container_id = p.partition_id
							join
								sys.indexes as si --For the name of the index
								on si.object_id = p.object_id and 
								   si.index_id = p.index_id
							where au.type_desc = 'LOB_DATA' and 
								  p.object_id = @TableID and 
								  si.name = @IndexName
						)
							begin
								set @ReindexMode = 2;
						end;

						/* EINDE TOEVOEGING */

						select @Q = case @ReindexMode
										when 1
										then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] REORGANIZE'
										when 2
										then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] REORGANIZE'
										when 3
										then 'alter index [' + @IndexName + '] on dbo.[' + OBJECT_NAME(@TableId) + '] REORGANIZE'
									end;
						raiserror(@Q, 0, 1) with nowait;
						set @Start = GETDATE();
						update dbo.EzisIndexLog
						set 
							IndexStart = @Start
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart is null;
						exec (@Q);
						update dbo.EzisIndexLog
						set 
							IndexStop = GETDATE()
						where TableId = @TableId and 
							  IndexName = @IndexName and 
							  IndexStart = @Start;
		end;
				raiserror('Done', 0, 1) with nowait;
		end;
		if @mode is null or 
		   @mode = 'reindex' or 
		   @mode = 'show'
			begin
				select 'Nog ' + CAST(COUNT(*) as sysname) + ' indexen te herindexeren,
Historisch gezien ongeveer ' + CAST(CAST(SUM(ISNULL(GemDuurInSec, 0)) / 60 as int) as sysname) + ' minuten werk.
Totaal ' + CAST(CAST(SUM(CAST(NrOfRows as bigint)) / 1000000 as integer) as sysname) + ' miljoen records te verwerken.
Oudste index voor de controle is van ' + CONVERT(char(8), MIN(ISNULL(OudsteIndex, '29991231')), 112)
				from
					dbo.EzisIndexLog as il
				left outer join
				(
					select TableId, 
						   IndexName, 
						   AVG(DATEDIFF(ss, IndexStart, IndexStop)) as GemDuurInSec, 
						   MAX(IndexStop) as LaatsteReIndexDatum, 
						   MIN(IndexStop) as OudsteIndex
					from dbo.EzisIndexLog
					where IndexStop is not null and 
						  IndexStop >= DATEADD(dd, -60, GETDATE())
					group by TableId, 
							 IndexName
				) as il2 on il.TableId = il2.TableId and 
							il.IndexName = il2.IndexName
				where IndexStart is null
					  and 
					  --   and (il.IndexName not like '%VRLIJST_VROPSLG%')
					  --and (il.IndexName not like '%METINGEN_METINGEN%') 
					  --and (il.IndexName not like '%SEELOG_SEELOGI%')
					  --and (il.IndexName not like '%MUTLOG_MUTLOG%')
					  --and (NrOfRows <= 500000000)   -- 20181114 MBL maximaliseren REINDEX 
					  NrOfRows > 1   -- 20181114 MBL Start REINDEX

					  and 
					  (ISNULL(@LikeTableName, '') = '' or 
					   OBJECT_NAME(il.TableId) like @LikeTableName);
		end;
		if @mode = 'reindex_fast'
			begin
				select 'Nog ' + CAST(COUNT(*) as sysname) + ' indexen te fast-herindexeren,
Historisch gezien ongeveer ' + CAST(CAST(SUM(ISNULL(GemDuurInSec, 0)) / 60 as int) as sysname) + ' minuten werk.
Totaal ' + CAST(CAST(SUM(CAST(NrOfRows as bigint)) / 1000000 as integer) as sysname) + ' miljoen records te verwerken.
Oudste index voor de controle is van ' + CONVERT(char(8), MIN(ISNULL(OudsteIndex, '29991231')), 112)
				from
					dbo.EzisIndexLog as il
				left outer join
				(
					select TableId, 
						   IndexName, 
						   AVG(DATEDIFF(ss, IndexStart, IndexStop)) as GemDuurInSec, 
						   MAX(IndexStop) as LaatsteReIndexDatum, 
						   MIN(IndexStop) as OudsteIndex
					from dbo.EzisIndexLog
					where IndexStop is not null and 
						  IndexStop >= DATEADD(dd, -60, GETDATE())
					group by TableId, 
							 IndexName
				) as il2 on il.TableId = il2.TableId and 
							il.IndexName = il2.IndexName
				where IndexStart is null
					  and 
					  --        and (il.IndexName not like '%VRLIJST_VROPSLG%') 
					  il.IndexName not like '%METINGEN_METINGEN%' and 
					  il.IndexName not like '%SEELOG_SEELOGI%' and 
					  il.IndexName not like '%MUTLOG_MUTLOG%' and 
					  GemDuurInSec <= @MaxAvgSeconds
					  --		and (NrOfRows <= 25000000)
					  and 
					  NrOfRows >= 1 and 
					  (ISNULL(@LikeTableName, '') = '' or 
					   OBJECT_NAME(il.TableId) like @LikeTableName);
		end;
	end;