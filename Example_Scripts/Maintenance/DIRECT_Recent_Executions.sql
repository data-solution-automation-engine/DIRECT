SELECT
MODULE_CODE,
modinst.EXECUTION_STATUS_CODE,
modinst.MODULE_INSTANCE_ID,
modinst.START_DATETIME,
modinst.END_DATETIME, module.MODULE_ID
FROM MODULE_INSTANCE modinst
JOIN MODULE module ON modinst.MODULE_ID=module.MODULE_ID
ORDER BY modinst.MODULE_INSTANCE_ID DESC