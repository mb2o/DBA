/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Id]
      ,[Description]
      ,[TimeStamp]
      ,[MachineName]
      ,[Level]
      ,[EnvironmentId]
  FROM [HIXUpdate].[dbo].[Logs]
  ORDER BY TimeStamp desc