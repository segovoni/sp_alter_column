------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- Test:         UnitTestAlterColumn.[test alter column with PK]       -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE UnitTestAlterColumn.[test alter column with PK]
AS
BEGIN
  /*
    Arrange
  */
  DECLARE
    @TestSchemaName AS SYSNAME = 'UnitTestAlterColumn'
    ,@TestTableName AS SYSNAME = 'test table alter column with PK'
    ,@TestColumnName AS SYSNAME = 'ID';

  -- UnitTestAlterColumn.Expected
  DROP TABLE IF EXISTS UnitTestAlterColumn.Expected;
  CREATE TABLE UnitTestAlterColumn.Expected
  (
    IS_NULLABLE SYSNAME
    ,DATA_TYPE SYSNAME
    ,CHARACTER_MAXIMUM_LENGTH INTEGER
  );
  INSERT INTO UnitTestAlterColumn.Expected
  (
    IS_NULLABLE
    ,DATA_TYPE
    ,CHARACTER_MAXIMUM_LENGTH
  )
  VALUES
  (
    'NO'
    ,'NVARCHAR'
    ,256
  );

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
    ,@datatype = 'NVARCHAR(256) NOT NULL'
    ,@executionmode = 1;

  SELECT
    IS_NULLABLE
    ,DATA_TYPE
    ,CHARACTER_MAXIMUM_LENGTH
  INTO
    UnitTestAlterColumn.Actual
  FROM
    INFORMATION_SCHEMA.COLUMNS
  WHERE
    (TABLE_SCHEMA = @TestSchemaName)
    AND (TABLE_NAME = @TestTableName)
    AND (COLUMN_NAME = @TestColumnName);

  DROP TABLE IF EXISTS dbo.[test table alter column with PK];

  /*
    Assert
  */
  EXEC tSQLt.AssertEqualsTable 
    @Expected = N'UnitTestAlterColumn.Expected'
    ,@Actual = N'UnitTestAlterColumn.Actual'
    ,@Message = N'The expected data was not returned.';
END;
GO


EXEC tSQLt.Run 'UnitTestAlterColumn.[test alter column with PK]';
GO


--SELECT * FROM tSQLt.TestResult;