/* Controleer dubbelen in eigen tabel */
SELECT TBICODE, COUNT(TBICODE)
  FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
  GROUP BY TBICODE
  HAVING COUNT(TBICODE) > 1
  

/* Controleer eigen met chipsoft tabellen */
SELECT *
  FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
WHERE TBICODE NOT IN (
SELECT TBICODE COLLATE DATABASE_DEFAULT 
FROM [EZIS_LZB].dbo.CSZISLIB_TBI 
)

SELECT *
FROM [EZIS_LZB].dbo.CSZISLIB_TBI
WHERE TBICODE NOT IN (
SELECT TBICODE COLLATE DATABASE_DEFAULT 
FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
)

SELECT *
FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
WHERE TBITYPE = 'V' AND ZORGVCODE = ''

SELECT *
FROM [EZIS_LZB].dbo.CSZISLIB_TBI
WHERE TBITYPE = 'V'


SELECT *
FROM [EZIS_LZB].dbo.CSZISLIB_TBI
WHERE TBICODE IN (
	SELECT TBICODE COLLATE DATABASE_DEFAULT 
	FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
	WHERE VERZVORM = '' AND ZORGVCODE = ''
) AND ZORGVCODE = ''


/* Insert missende LZB */
INSERT INTO [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
SELECT *
FROM [EZIS_LZB].dbo.CSZISLIB_TBI
WHERE TBICODE NOT IN (
SELECT TBICODE COLLATE DATABASE_DEFAULT 
FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
)

/* Update ALLE VELDEN */
UPDATE [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
SET [FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[INSTCODE] = T2.INSTCODE COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].ZORGVSOORT = T2.ZORGVSOORT COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].ZORGVCODE = T2.ZORGVCODE COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].TBIGROEP = T2.TBIGROEP COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].T_A_V = T2.T_A_V COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].ADRES = T2.ADRES COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].HUISNR = T2.HUISNR COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].POSTCODE = T2.POSTCODE COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].LAND = T2.LAND COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].TELEFOON1 = T2.TELEFOON1 COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].TYPETEL1 = T2.TYPETEL1 COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[TELEFOON2] = T2.[TELEFOON2] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[TYPETEL2] = T2.[TYPETEL2] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[POLISCHECK] = T2.[POLISCHECK] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[MACHTIGING] = T2.[MACHTIGING] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[MACHTCHECK] = T2.[MACHTCHECK] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[MACHTDUUR] = T2.[MACHTDUUR] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[VERWKAART] = T2.[VERWKAART] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[AANLVORM] = T2.[AANLVORM] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[ENVELOP] = T2.[ENVELOP] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[BORDEREL] = T2.[BORDEREL] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[FACTPATK] = T2.[FACTPATK] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[FACTPATP] = T2.[FACTPATP] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[FACTPATD] = T2.[FACTPATD] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[BETINST] = T2.[BETINST] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[DEBITEURNR] = T2.[DEBITEURNR] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[REKCODE] = T2.[REKCODE] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[BEGINDAT] = T2.[BEGINDAT] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[EINDEDAT] = T2.[EINDEDAT] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[FAKTOPNDAG] = T2.[FAKTOPNDAG] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[BTW] = T2.[BTW] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[STDLAYOUT] = T2.[STDLAYOUT] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[SegmentA] = T2.[SegmentA] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[SegmentB] = T2.[SegmentB] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[SegmentAO] = T2.[SegmentAO] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[COVOPTION] = T2.[COVOPTION] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[ISAWBZ] = T2.[ISAWBZ] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[BSNNIETVER] = T2.[BSNNIETVER] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[SegmentBO] = T2.[SegmentBO] COLLATE DATABASE_DEFAULT,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[VEKTHERDECL] = T2.[VEKTHERDECL] ,
[FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[VEKTHERTERMIJN] = T2.[VEKTHERTERMIJN]
FROM [EZIS_LZB].dbo.CSZISLIB_TBI as T2
WHERE [FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[TBICODE] = T2.TBICODE COLLATE DATABASE_DEFAULT 
AND [FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[VERZVORM] = ''

/* Update [VERZVORM] */
UPDATE [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
SET [FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[VERZVORM] = T2.[VERZVORM] COLLATE DATABASE_DEFAULT
FROM [EZIS_LZB].dbo.CSZISLIB_TBI as T2
WHERE [FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[TBICODE] = T2.TBICODE COLLATE DATABASE_DEFAULT 
AND [FZR_aanlevering].[dbo].[LZB_cszislib_tbi].[VERZVORM] = ''


/* Controle omnummering LZB, exclusief V */
SELECT COUNT(*) 
FROM FZR_aanlevering.dbo.ALG_omnummering_cszislib_tbi
WHERE OUD_LZB != ''

SELECT COUNT(*) 
FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]

SELECT *
FROM FZR_aanlevering.dbo.ALG_omnummering_cszislib_tbi
WHERE [OUD_LZB] NOT IN (
	SELECT TBICODE COLLATE DATABASE_DEFAULT 
	FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
) AND OUD_LZB != ''

SELECT *
FROM [FZR_aanlevering].[dbo].[LZB_cszislib_tbi]
WHERE TBICODE NOT IN (
	SELECT [OUD_LZB] COLLATE DATABASE_DEFAULT 
	FROM FZR_aanlevering.dbo.ALG_omnummering_cszislib_tbi
	WHERE OUD_LZB != ''
) 

SELECT INSTCODE, COUNT(INSTCODE)
FROM [FZR_aanlevering].[dbo].[FZR_cszislib_tbi]
WHERE VERVALLEN = 0 AND TBITYPE = 'V'
GROUP BY INSTCODE
HAVING COUNT(INSTCODE) > 1

SELECT LEFT(NIEUW, 5), COUNT(LEFT(NIEUW, 5))
FROM FZR_aanlevering.dbo.FZR_omnummering_cszislib_tbi
WHERE  NIEUW LIKE 'V%'
GROUP BY LEFT(NIEUW, 5)
HAVING COUNT(LEFT(NIEUW, 5)) > 1


SELECT *
FROM FZR_aanlevering.dbo.FZR_omnummering_cszislib_tbi
WHERE  NIEUW LIKE 'V9999%'