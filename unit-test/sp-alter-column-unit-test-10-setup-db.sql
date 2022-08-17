------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- File:         Unit test - Setup DB                                  -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [master];
GO

-- Drop database if exists
IF (DB_ID('sp_alter_column_devtest') IS NOT NULL)
BEGIN
  ALTER DATABASE [sp_alter_column_devtest]
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

  DROP DATABASE [sp_alter_column_devtest];
END;
GO

-- Create database
CREATE DATABASE [sp_alter_column_devtest];
GO

/*
USE [sp_alter_column_devtest];
GO

IF OBJECT_ID('dbo.Tab2', 'U') IS NOT NULL
  DROP TABLE dbo.Tab2;
GO

IF OBJECT_ID('dbo.Tab1', 'U') IS NOT NULL
  DROP TABLE dbo.Tab1;
GO

CREATE TABLE dbo.Tab1
(
  ID INTEGER IDENTITY(1, 1) NOT NULL PRIMARY KEY
  ,Codice VARCHAR(20) NOT NULL
  ,Quantity INTEGER NOT NULL DEFAULT(0)
);
GO

CREATE TABLE dbo.Tab2
(
  ID INTEGER IDENTITY(1, 1) NOT NULL PRIMARY KEY
  ,IDTab1 INTEGER NULL
);
GO

ALTER TABLE dbo.Tab2 ADD CONSTRAINT FK_Tab2_to_Tab1
  FOREIGN KEY (IDTab1)
  REFERENCES dbo.Tab1(ID);
GO

ALTER TABLE dbo.Tab1 ADD CONSTRAINT UQ_Codice UNIQUE(Codice);
GO

INSERT INTO dbo.Tab1 (Codice, Quantity) VALUES ('A', 1), ('B', 2), ('C', 3);
INSERT INTO dbo.Tab2 (IDTab1) VALUES (1);
GO

CREATE STATISTICS Tab1_Stats_Codice ON dbo.Tab1(Codice);
GO

CREATE INDEX Tab1_IDX_Codice_Quantity ON dbo.Tab1
(
  Codice,
  Quantity
);
GO


SELECT * FROM dbo.Tab1;
SELECT * FROM dbo.Tab2;
*/

GO