------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- File:         Unit test - Setup tSQLt framework                     -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [master];
GO

-- Enable CLR at the SQL Server instance level
-- tSQLt framework requires this option
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled';
GO


USE [Alter_Column_DB];
GO

-- Enable TRUSTWORTHY property at the database level
-- in each database you want to install tSQLt framework
ALTER DATABASE [Alter_Column_DB] SET TRUSTWORTHY ON;
GO


/*
  1. Download the tSQLt framework from https://tsqlt.org/

  2. Execute tSQLt.class.sql in the database you want to install
     tSQLt framework
  
  3. Download sp_alter_column from https://github.com/segovoni/sp_alter_column

  4. Execute sp-alter-column.sql in the database you have just installed
     tSQLt framework
*/