/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [Herkomst], [quota], [database], count([database]) as aantal, sum(mailboxsize) as totaalmb, sum(mailboxitems) as totaalitems
  FROM [exchange].[dbo].[MailboxReport_Bravis_20150313]
  WHERE [migratiegroep] = 'FZR'
  GROUP BY [database],[quota], [Herkomst]
  ORDER BY [Herkomst] DESC, [quota] ASC, [database] ASC

SELECT distinct([migratiegroep])
  FROM [exchange].[dbo].[MailboxReport_Bravis_20150313]

SELECT *
FROM [exchange].[dbo].[MailboxReport_Bravis_20150313]
WHERE [migratiegroep] IN (
'MEDSTAF','APO','Zorggroep 3','Zorggroep 2','MED','Zorggroep 1','Zorggroep 1 & 3','Zorggroep 3','MT','Secr','Zorggroep 1 & 2','RvB','Zorggroep 2','Zorggroep 2 & 3','Zorggroep  1'
)
AND [NewSmtpaddress] like '%rvb%'
ORDER BY [migratiegroep], [NewSmtpaddress]

SELECT displayname, [NewSmtpaddress], logon, quota, [database]
FROM [exchange].[dbo].[MailboxReport_Bravis_20150313]
WHERE [moved] IS NOT NULL AND logon is not null and
[migratiegroep] IN (
'MEDSTAF','APO','Zorggroep 3','Zorggroep 2','MED','Zorggroep 1','Zorggroep 1 & 3','Zorggroep 3','MT','Secr','Zorggroep 1 & 2','RvB','Zorggroep 2','Zorggroep 2 & 3','Zorggroep  1'
) 
ORDER BY [logon]


SELECT [herkomst],count(*)
FROM [exchange].[dbo].[MailboxReport_Bravis_20150313]
WHERE [migratiegroep] IS NOT NULL
GROUP BY [herkomst]


SELECT count(*)
FROM [exchange].[dbo].[MailboxReport_Bravis_20150313]
WHERE leidend IS NOT NULL