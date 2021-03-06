/****** Script for SelectTopNRows command from SSMS  ******/
TRUNCATE TABLE [avanade].[dbo].[AHC_HL7Journal];

/* Insert from patiënt into avanade */
INSERT INTO [avanade].[dbo].[AHC_HL7Journal]
SELECT
	[PARTVERZ] AS 'IN1InsuranceCompanyId'
	,[NRPARTVERZ] AS 'IN1InsuranceId'
	,convert(VARCHAR, [INGANGSDAT], 105) AS 'IN1InsuranceStartDate'
	,convert(VARCHAR, [GEBDAT], 105) AS 'PIDBirthDate'
	,[BSN] AS 'PIDBSN'
	,'' AS 'PIDBSN1'
	,[WOONPLAATS] AS 'PIDCity'
	,[LAND] AS 'PIDCountryRegionId'
	,'PA' AS 'PIDCustGroup'
	,CASE WHEN [GESLACHT] = 'M' THEN [VOORLETTER] ELSE [VOORLETTER] END AS 'PIDFirstName'
    ,[GESLACHT] AS 'PIDGender'
	,CASE WHEN [GESLACHT] = 'M' THEN [ACHTERNAAM] ELSE [MEISJESNAA] END AS 'PIDLastName'
    ,[BURGSTAAT] AS 'PIDMaritalStatus'
	,CASE WHEN [GESLACHT] = 'M' THEN [VOORVOEGA] ELSE [VOORVOEGM] END AS 'PIDMiddleName'
	,CASE WHEN [GESLACHT] = 'V' THEN [ACHTERNAAM] ELSE [MEISJESNAA] END AS 'PIDPartnerLastName'
	,CASE WHEN [GESLACHT] = 'V' THEN [VOORVOEGA] ELSE [VOORVOEGM] END AS 'PIDPartnerMiddleName'
    ,[PATIENTNR] AS 'PIDPatientId'
    ,[TELEFOON1] AS 'PIDPhone'
    ,[TELEFOON2] AS 'PIDPhone2'
    ,'' AS 'PIDPrefix'
    ,([ADRES] + ' ' + [HUISNR]) collate database_default AS 'PIDStreet'
    ,[POSTCODE] AS 'PIDZipCodeId'
    ,'' AS 'PreferredName'
    ,'Initial Patient load 30-1-2014' AS 'LogText'
FROM [GTHIXSQL01.ZKH.LOCAL].[HIX_TEST].[dbo].PATIENT_PATIENT
ORDER BY PATIENTNR DESC;

/* haal alle verzekeraars op */
TRUNCATE TABLE [avanade].[dbo].[CSZISLIB_TBI];
INSERT INTO [avanade].[dbo].[CSZISLIB_TBI] SELECT * FROM [GTHIXSQL01.ZKH.LOCAL].[HIX_TEST].[dbo].[CSZISLIB_TBI];

/* update verzekeraars */
UPDATE [avanade].[dbo].[AHC_HL7Journal] 
	SET [IN1InsuranceCompanyId] = [avanade].[dbo].[CSZISLIB_TBI].[INSTCODE]
    FROM [avanade].[dbo].[AHC_HL7Journal] 
    INNER JOIN [avanade].[dbo].[CSZISLIB_TBI]
    ON [avanade].[dbo].[AHC_HL7Journal].[IN1InsuranceCompanyId] = [avanade].[dbo].[CSZISLIB_TBI].[TBICODE];

/* update PIDCountryRegionId */	
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'NLD' WHERE [PIDCountryRegionId] = '';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'ANT' WHERE [PIDCountryRegionId] = 'AN';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'AUT' WHERE [PIDCountryRegionId] = 'AT';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'ABW' WHERE [PIDCountryRegionId] = 'AW';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'BEL' WHERE [PIDCountryRegionId] = 'BE';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'BGR' WHERE [PIDCountryRegionId] = 'BG';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'BRA' WHERE [PIDCountryRegionId] = 'BR';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'CAN' WHERE [PIDCountryRegionId] = 'CA';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'CHE' WHERE [PIDCountryRegionId] = 'CH';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'CXR' WHERE [PIDCountryRegionId] = 'CX';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'CZE' WHERE [PIDCountryRegionId] = 'CZ';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'DEU' WHERE [PIDCountryRegionId] = 'DE';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'DNK' WHERE [PIDCountryRegionId] = 'DK';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'EST' WHERE [PIDCountryRegionId] = 'EE';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = '' WHERE [PIDCountryRegionId] = 'EH';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'ESP' WHERE [PIDCountryRegionId] = 'ES';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'ETH' WHERE [PIDCountryRegionId] = 'ET';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'FIN' WHERE [PIDCountryRegionId] = 'FI';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'FRA' WHERE [PIDCountryRegionId] = 'FR';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'GBR' WHERE [PIDCountryRegionId] = 'GB';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'GRC' WHERE [PIDCountryRegionId] = 'GR';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'HUN' WHERE [PIDCountryRegionId] = 'HU';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'IRL' WHERE [PIDCountryRegionId] = 'IE';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'ITA' WHERE [PIDCountryRegionId] = 'IT';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'LTU' WHERE [PIDCountryRegionId] = 'LT';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'LUX' WHERE [PIDCountryRegionId] = 'LU';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'MAR' WHERE [PIDCountryRegionId] = 'MA';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'NLD' WHERE [PIDCountryRegionId] = 'NL';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'NOR' WHERE [PIDCountryRegionId] = 'NO';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'POL' WHERE [PIDCountryRegionId] = 'PL';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'PRT' WHERE [PIDCountryRegionId] = 'PT';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'ROU' WHERE [PIDCountryRegionId] = 'RO';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'SRB' WHERE [PIDCountryRegionId] = 'RS';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'RUS' WHERE [PIDCountryRegionId] = 'RU';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'SWE' WHERE [PIDCountryRegionId] = 'SE';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'SGP' WHERE [PIDCountryRegionId] = 'SG';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'SVN' WHERE [PIDCountryRegionId] = 'SI';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDCountryRegionId] = 'USA' WHERE [PIDCountryRegionId] = 'US';

/* update telnummers */
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET PIDPhone = PIDPhone2, PIDPhone2 = '' WHERE [PIDPhone] = '' AND PIDPhone2 != '';

/* update PreferredName */
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PreferredName] = ''
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PreferredName] = [PIDLastName]																	WHERE [PIDMiddleName] = '' ;
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PreferredName] = CONCAT([PIDMiddleName],' ',[PIDLastName])										WHERE [PIDMiddleName] != '';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PreferredName] = CONCAT([PIDPartnerLastName],'-',[PreferredName])								WHERE [PIDPartnerLastName] != '' AND [PIDPartnerMiddleName] = '';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PreferredName] = CONCAT([PIDPartnerMiddleName],' ',[PIDPartnerLastName], '-', [PreferredName])	WHERE [PIDPartnerLastName] != '' AND [PIDPartnerMiddleName] != '';

/* Update gender */
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDGender] = 0	WHERE [PIDGender] = '' OR  [PIDGender] = 'O';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDGender] = 1	WHERE [PIDGender] = 'M' ;
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDGender] = 2	WHERE [PIDGender] = 'V' ;

/* Update Maritalstatus */
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDMaritalStatus] = 0	WHERE [PIDMaritalStatus] = '' OR [PIDMaritalStatus] = 'S';
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDMaritalStatus] = 1	WHERE [PIDMaritalStatus] = 'O' ;
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDMaritalStatus] = 2	WHERE [PIDMaritalStatus] = 'G' ;
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDMaritalStatus] = 4	WHERE [PIDMaritalStatus] = 'W' ;

/* Update FirstName */
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'A','A.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'B','B.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'C','C.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'D','D.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'E','E.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'F','F.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'G','G.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'H','H.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'I','I.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'J','J.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'K','K.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'L','L.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'M','M.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'N','N.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'O','O.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'P','P.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'Q','Q.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'R','R.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'S','S.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'T','T.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'U','U.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'V','V.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'W','W.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'X','X.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'Y','Y.');
UPDATE [avanade].[dbo].[AHC_HL7Journal] SET [PIDFirstName] = REPLACE([PIDFirstName],'Z','Z.');


/* Upload naar AX4H server */
INSERT INTO [FZR-AX4HDB-02\AX4HEALTH_ACC].[FZR_AANLEVERING].[dbo].[AHC_HL7Journal]
SELECT * FROM [avanade].[dbo].[AHC_HL7Journal];

/* Upload naar AX4H server LZB */
INSERT INTO [AAX4HDB01\AX4HEALTH_ACC].[AX4HealthR2].[dbo].[AHC_HL7Journal]
SELECT * FROM [avanade].[dbo].[AHC_HL7Journal];