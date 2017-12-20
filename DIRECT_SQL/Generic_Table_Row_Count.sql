 select
	t.name [Table],
	max (p.rows) [Rows],
	round (sum (8 * a.data_pages)/1024.0,2) [Data (MB)],
	sum (8 * a.used_pages)/1024.0 [Used (MB)],
	sum (8 * a.total_pages)/1024.0 [Total (MB)]
 from
	sys.tables t
	inner join sys.partitions p
		on t.object_id = p.object_id
	inner join sys.allocation_units a on p.partition_id = a.container_id
group by t.name
order by 1
