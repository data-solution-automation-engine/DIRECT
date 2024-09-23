 select
	t.name [Table],
	MAX(FORMAT(p.rows, '#,###')) AS [Rows],
	FORMAT(SUM(round(8 * a.data_pages/1024.0,2)),'#,###') [Data (MB)],
	FORMAT(SUM(round(8 * a.used_pages/1024.0,2)),'#,###') [Used (MB)],
	FORMAT(SUM(round(8 * a.total_pages/1024.0,2)),'#,###') [Total (MB)]
 from
	sys.tables t
	inner join sys.partitions p
		on t.object_id = p.object_id
	inner join sys.allocation_units a on p.partition_id = a.container_id
group by t.name
order by 
CAST(FORMAT(SUM(round(8 * a.total_pages/1024.0,2)),'####') AS INT)
DESC
