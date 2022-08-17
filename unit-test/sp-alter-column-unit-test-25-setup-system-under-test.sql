------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- File:         Unit test - Setup SUT (System Under Test)             -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------

USE [sp_alter_column_devtest];
GO


/*
  1. Download sp_alter_column from https://github.com/segovoni/sp_alter_column

  2. Execute sp-alter-column.sql in the database you have just installed
     tSQLt framework (sp_alter_column_devtest for this example)
*/
