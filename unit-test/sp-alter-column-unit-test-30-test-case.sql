------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- File:         Test cases for sp_alter_column                        -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [Alter_Column_DB];
GO

EXEC tSQLt.DropClass 'UnitTest_sp_alter_column';
EXEC tSQLt.NewTestClass 'UnitTestAlterColumn';
GO

CREATE OR ALTER PROCEDURE UnitTestAlterColumn.[test alter column with PK]
AS
BEGIN
  /*
    Arrange
  */
  DECLARE
    @EXPECTED_IS_NULLABLE AS SYSNAME = 'NO'
    ,@EXPECTED_DATA_TYPE AS SYSNAME = 'NVARCHAR'
    ,@EXPECTED_CHARACTER_MAXIMUM_LENGTH AS INTEGER = 256
    ,@ACTUAL_IS_NULLABLE AS SYSNAME
    ,@ACTUAL_DATA_TYPE AS SYSNAME
    ,@ACTUAL_CHARACTER_MAXIMUM_LENGTH AS INTEGER
    ,@TestSchemaName AS SYSNAME = 'UnitTestAlterColumn'
    ,@TestTableName AS SYSNAME = 'test table alter column with PK'
    ,@TestColumnName AS SYSNAME = 'ID';

  DROP TABLE IF EXISTS UnitTestAlterColumn.[test table alter column with PK];

  CREATE TABLE UnitTestAlterColumn.[test table alter column with PK]
  (
    ID NVARCHAR(20) NOT NULL PRIMARY KEY
    ,FirstName NVARCHAR(40) NOT NULL
    ,LastName NVARCHAR(40) NOT NULL
  );
  INSERT INTO UnitTestAlterColumn.[test table alter column with PK]
  (
    ID
    ,FirstName
    ,LastName
  )
  VALUES
  (
    'ID20200802'
    ,'My first name'
    ,'My last name'
  );

  /*
    Act
  */
  EXEC dbo.sp_alter_column
    @schemaname = @TestSchemaName
    ,@tablename = @TestTableName
    ,@columnname = @TestColumnName
    --,@columnrename=''
    ,@datatype = 'NVARCHAR(256) NOT NULL'
    ,@executionmode = 1;

  /*
    Assert
  */
  SELECT
    @ACTUAL_IS_NULLABLE = IS_NULLABLE
    ,@ACTUAL_DATA_TYPE = DATA_TYPE
    ,@ACTUAL_CHARACTER_MAXIMUM_LENGTH = CHARACTER_MAXIMUM_LENGTH
  FROM
    INFORMATION_SCHEMA.COLUMNS
  WHERE
    (TABLE_SCHEMA = @TestSchemaName)
    AND (TABLE_NAME = @TestTableName)
    AND (COLUMN_NAME = @TestColumnName);

  DROP TABLE IF EXISTS dbo.[test table alter column with PK];
 
  EXEC tSQLt.AssertEquals @EXPECTED_IS_NULLABLE, @ACTUAL_IS_NULLABLE;
  EXEC tSQLt.AssertEquals @EXPECTED_DATA_TYPE, @ACTUAL_DATA_TYPE;
  EXEC tSQLt.AssertEquals @EXPECTED_CHARACTER_MAXIMUM_LENGTH, @ACTUAL_CHARACTER_MAXIMUM_LENGTH;
END;
GO

CREATE OR ALTER PROCEDURE UnitTestAlterColumn.[test alter column with FK]
AS
BEGIN
  /*
    Arrange
  */
  DECLARE
    @EXPECTED_IS_NULLABLE AS SYSNAME = 'YES'
    ,@EXPECTED_DATA_TYPE AS SYSNAME = 'INT'
    ,@EXPECTED_NUMERIC_PRECISION AS INTEGER = 10  -- 19 -- Bigint
    ,@ACTUAL_IS_NULLABLE AS SYSNAME
    ,@ACTUAL_DATA_TYPE AS SYSNAME
    ,@ACTUAL_NUMERIC_PRECISION AS INTEGER
    ,@TestSchemaName AS SYSNAME = 'UnitTestAlterColumn'
    ,@TestTableName AS SYSNAME = 'test table alter column with FK'
    ,@TestTableNameReferenced AS SYSNAME = 'test table alter column with FK referenced'
    ,@TestColumnName AS SYSNAME = 'AddressID';

  DROP TABLE IF EXISTS UnitTestAlterColumn.[test table alter column with FK referenced];
  CREATE TABLE UnitTestAlterColumn.[test table alter column with FK referenced]
  (
    ID INTEGER NOT NULL PRIMARY KEY
    ,AddressLine NVARCHAR(128) NOT NULL
  );
  INSERT INTO UnitTestAlterColumn.[test table alter column with FK referenced]
  (
    ID
    ,AddressLine
  )
  VALUES
  (
    '1'
    ,'Italy'
  );

  DROP TABLE IF EXISTS UnitTestAlterColumn.[test table alter column with FK];
  CREATE TABLE UnitTestAlterColumn.[test table alter column with FK]
  (
    ID NVARCHAR(20) NOT NULL PRIMARY KEY
    ,FirstName NVARCHAR(40) NOT NULL
    ,LastName NVARCHAR(40) NOT NULL
    ,AddressID INTEGER NULL
  );
  ALTER TABLE UnitTestAlterColumn.[test table alter column with FK]
    ADD CONSTRAINT [FK test table alter column with FK referenced AddressID]
    FOREIGN KEY (AddressID) REFERENCES UnitTestAlterColumn.[test table alter column with FK referenced](ID);
  INSERT INTO UnitTestAlterColumn.[test table alter column with FK]
  (
    ID
    ,FirstName
    ,LastName
    ,AddressID
  )
  VALUES
  (
    'ID20200802'
    ,'My first name'
    ,'My last name'
    ,1
  );

  /*
    Act
  */
  EXEC dbo.sp_alter_column
    @schemaname = @TestSchemaName
    ,@tablename = @TestTableName
    ,@columnname = @TestColumnName
    --,@columnrename=''
    ,@datatype='INTEGER NULL'
    ,@executionmode=1;

  /*
    Assert
  */
  SELECT
    @ACTUAL_IS_NULLABLE = IS_NULLABLE
    ,@ACTUAL_DATA_TYPE = DATA_TYPE
    ,@ACTUAL_NUMERIC_PRECISION = NUMERIC_PRECISION
  FROM
    INFORMATION_SCHEMA.COLUMNS
  WHERE
    (TABLE_SCHEMA = @TestSchemaName)
    AND (TABLE_NAME = @TestTableName)
    AND (COLUMN_NAME = @TestColumnName);

  ALTER TABLE UnitTestAlterColumn.[test table alter column with FK]
    DROP CONSTRAINT [FK test table alter column with FK referenced AddressID]
  DROP TABLE IF EXISTS UnitTestAlterColumn.[test table alter column with FK referenced];
  DROP TABLE IF EXISTS UnitTestAlterColumn.[test table alter column with FK];
 
  EXEC tSQLt.AssertEquals @EXPECTED_IS_NULLABLE, @ACTUAL_IS_NULLABLE;
  EXEC tSQLt.AssertEquals @EXPECTED_DATA_TYPE, @ACTUAL_DATA_TYPE;
  EXEC tSQLt.AssertEquals @EXPECTED_NUMERIC_PRECISION, @ACTUAL_NUMERIC_PRECISION;
END;
GO

EXEC tSQLt.Run 'UnitTestAlterColumn';
GO

-- Cleanup
EXEC tSQLt.DropClass 'UnitTest_sp_alter_column';
GO