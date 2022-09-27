-- https://learn.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio?view=sql-server-ver16
 

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'development')
  BEGIN
    CREATE DATABASE development
  END
GO

use development
GO

IF DATABASE_PRINCIPAL_ID('Limitedaccess') IS NULL
  BEGIN
    CREATE ROLE Limitedaccess; 
  END
GO

GRANT SELECT,INSERT, UPDATE, EXEC ON DATABASE::development TO Limitedaccess;
GO
GRANT SELECT,INSERT, UPDATE, DELETE, EXEC, ALTER ON SCHEMA::dbo TO Limitedaccess; 
GO
GRANT CREATE  VIEW TO Limitedaccess; 
GO 
GRANT CREATE  table TO Limitedaccess; 
GO 

IF NOT EXISTS 
    (SELECT name  
     FROM master.sys.server_principals
     WHERE name = 'antipodesDeveloper')
BEGIN
   CREATE LOGIN antipodesDeveloper  WITH PASSWORD = '$(PWD)'
END
GO

IF DATABASE_PRINCIPAL_ID('antipodesDeveloper') IS NULL
  CREATE USER antipodesDeveloper FOR LOGIN antipodesDeveloper;
  EXEC sp_addrolemember 'Limitedaccess', 'antipodesDeveloper'; 
GO  