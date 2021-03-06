/*
	Determine accessionnumber based on folder name
*/
SELECT DISTINCT (WEXAM_ID_STRING), WEF_LOC
FROM W_EXAM
INNER JOIN W_EXAM_FOLDER ON WEF_EXAM_ID = WEXAM_ID
INNER JOIN W_IMAGE_FOLDER ON WIF_EF_ID = WEF_ID
INNER JOIN W_IMAGE_FILE ON WIFI_IF_ID = WIF_ID
WHERE 
	WEXAM_DATE BETWEEN '2018-10-24 00:00:00.000' AND '2018-10-26 00:00:00.000' AND
	WEF_ARCHIVE_STATE = 99 --AND
	--WEF_LOC LIKE '%igis%'