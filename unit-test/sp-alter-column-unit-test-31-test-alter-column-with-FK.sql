------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- Test:         UnitTestAlterColumn.[test alter column with FK]       -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE UnitTestAlterColumn.[test alter column with FK]
AS
BEGIN
  /*
    Arrange
  */
  DECLARE
    @TestSchemaName AS SYSNAME = 'UnitTestAlterColumn'
    ,@TestTableName AS SYSNAME = 'test table alter column with FK'
    ,@TestTableNameReferenced AS SYSNAME = 'test table alter column with FK referenced'
    ,@TestColumnName AS SYSNAME = 'AddressID';

  -- UnitTestAlterColumn.Expected
  DROP TABLE IF EXISTS UnitTestAlterColumn.Expected;
  CREATE TABLE UnitTestAlterColumn.Expected
  (
    IS_NULLABLE SYSNAME
    ,DATA_TYPE SYSNAME
    ,NUMERIC_PRECISION INTEGER
  );
  INSERT INTO UnitTestAlterColumn.Expected
  (
    IS_NULLABLE
    ,DATA_TYPE
    ,NUMERIC_PRECISION
  )
  VALUES
  (
    'YES'
    ,'INT'
    ,10 -- Integer
    --,19 -- BigInt
  );

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
    ,@datatype='INTEGER NULL'
    ,@executionmode=1;

  -- UnitTestAlterColumn.Actual
  SELECT
    IS_NULLABLE
    ,DATA_TYPE
    ,NUMERIC_PRECISION
  INTO
    UnitTestAlterColumn.Actual
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

  /*
    Assert
  */
  EXEC tSQLt.AssertEqualsTable 
    @Expected = N'UnitTestAlterColumn.Expected'
    ,@Actual = N'UnitTestAlterColumn.Actual'
    ,@Message = N'The expected data was not returned.';
END;
GO


EXEC tSQLt.Run 'UnitTestAlterColumn.[test alter column with FK]';
GO


--SELECT * FROM tSQLt.TestResult;