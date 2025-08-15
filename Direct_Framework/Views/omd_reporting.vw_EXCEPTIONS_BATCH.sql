/**
 * @view [omd_reporting].[vw_EXCEPTIONS_BATCH]
 * @description Latest batch instances that did not succeed and are active.
 *
 * @package DIRECT Framework
 * @version 2.1.0
 * @see https://github.com/data-solution-automation-engine/DIRECT
 *
 * @resultset Columns:
 *   - BATCH_CODE: Batch code.
 *   - EXECUTION_STATUS_CODE: Status code of the latest instance.
 *   - MOST_RECENT_BATCH_INSTANCE_ID: Latest batch instance id.
 *   - START_TIMESTAMP: Start timestamp of latest instance.
 *   - END_TIMESTAMP: End timestamp of latest instance.
 *
 * @lineage
 * - reads:
 *     table [omd].[BATCH]
 *     table [omd].[BATCH_INSTANCE]
 *
 * @example
 * SELECT TOP 100 * FROM [omd_reporting].[vw_EXCEPTIONS_BATCH];
 */
CREATE VIEW omd_reporting.vw_EXCEPTIONS_BATCH AS

SELECT
    batch.BATCH_CODE,
    main.EXECUTION_STATUS_CODE,
    main.BATCH_INSTANCE_ID AS MOST_RECENT_BATCH_INSTANCE_ID,
    main.START_TIMESTAMP,
    main.END_TIMESTAMP
FROM omd.BATCH_INSTANCE main
JOIN omd.BATCH batch ON main.BATCH_ID=batch.BATCH_ID
JOIN
    (
        SELECT BATCH_ID, MAX(BATCH_INSTANCE_ID) as MAX_BATCH_INSTANCE_ID
        FROM omd.BATCH_INSTANCE
        WHERE BATCH_ID > 0
        GROUP BY BATCH_ID
    ) maxsub
ON  main.BATCH_ID = maxsub.BATCH_ID
AND main.BATCH_INSTANCE_ID=maxsub.MAX_BATCH_INSTANCE_ID
WHERE main.EXECUTION_STATUS_CODE <> 'Succeeded' AND batch.ACTIVE_INDICATOR = 'Y'

