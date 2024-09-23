/*
Batches without parents.
*/
SELECT *
FROM
(
	SELECT
		 batch.*
		,CASE WHEN isChildBatch.BATCH_ID IS NULL THEN 1 ELSE 0 END AS IS_MISSING_PARENT
	FROM omd.BATCH batch
	LEFT OUTER JOIN (SELECT DISTINCT BATCH_ID FROM omd.BATCH_HIERARCHY) isChildBatch
		ON batch.BATCH_ID = isChildBatch.BATCH_ID
	WHERE
		 batch.BATCH_ID != 0
	 AND batch.ACTIVE_INDICATOR = 'Y'

) sub
WHERE IS_MISSING_PARENT = 1