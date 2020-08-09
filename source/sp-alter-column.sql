------------------------------------------------------------------------
-- Project:      sp_alter_column                                       -
--               https://github.com/segovoni/sp_alter_column           -
--               The stored procedure is able to alter a column        -
--               with dependencies in your SQL database. It composes   -
--               automatically the appropriate DROP and CREATE         -
--               commands for each object connected to the column      -
--               I want to modify                                      -
--                                                                     -
-- File:         Stored procedure implementation                       -
-- Author:       Sergio Govoni https://www.linkedin.com/in/sgovoni/    -
-- Notes:        --                                                    -
------------------------------------------------------------------------


IF OBJECT_ID('dbo.sp_alter_column', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_alter_column;
GO

CREATE PROCEDURE dbo.sp_alter_column
(
  @schemaname SYSNAME
  ,@tablename SYSNAME
  ,@columnname SYSNAME
  ,@columnrename SYSNAME = @columnname
  ,@datatype SYSNAME
  ,@executionmode bit = 0
)
AS BEGIN
  /*
    Author: Sergio Govoni https://www.linkedin.com/in/sgovoni/
    Version: 1.0
    License: MIT License
    Github repository: https://github.com/segovoni/sp_alter_column
    Documentation will coming soon!
  */

  -- Check input parameters
  IF (LTRIM(RTRIM(ISNULL(@schemaname, ''))) = '')
  BEGIN
    RAISERROR(N'The parameter schema name (@schemaname) is not specified or is empty.', 16, 1);
    RETURN;
  END;

  IF (LTRIM(RTRIM(ISNULL(@tablename, ''))) = '')
  BEGIN
    RAISERROR(N'The parameter table name (@tablename) is not specified or is empty.', 16, 1);
    RETURN;
  END;

  IF (LTRIM(RTRIM(ISNULL(@columnname, ''))) = '')
  BEGIN
    RAISERROR(N'The parameter column name (@columnname) is not specified or is empty.', 16, 1);
    RETURN;
  END;

  IF (LTRIM(RTRIM(ISNULL(@columnrename, ''))) = '')
  BEGIN
    RAISERROR(N'The parameter column rename (@columnrename), if specified, it can not be empty.', 16, 1);
    RETURN;
  END;

  IF (LTRIM(RTRIM(ISNULL(@datatype, ''))) = '')
  BEGIN
    RAISERROR(N'The parameter data type (@datatype) is not specified or is empty.', 16, 1);
    RETURN;
  END;

  IF NOT EXISTS (SELECT
                   ORDINAL_POSITION
                 FROM
                   INFORMATION_SCHEMA.COLUMNS
                 WHERE
                   (TABLE_SCHEMA=@schemaname)
                   AND (TABLE_NAME=@tablename)
                   AND (COLUMN_NAME=@columnname))
  BEGIN
    RAISERROR(N'The object has not been found.', 16, 1);
    RETURN;
  END;

  -- Let's go!
  BEGIN TRY
    SET NOCOUNT ON;

    -- Create temporary table
    CREATE TABLE #tmp_usp_alter_column
    (
      schemaname SYSNAME NOT NULL
      ,tablename SYSNAME NOT NULL
      ,objecttype SYSNAME NOT NULL
      ,operationtype NVARCHAR(1) NOT NULL
      ,sqltext NVARCHAR(MAX) NOT NULL
    );

    -- Foreign key section
    -- Drop foreign key
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      schemap.name AS schemaname
      ,objp.name AS tablename
      ,'FK' AS objecttype
      ,'D' AS operationtype,
      ('ALTER TABLE [' + RTRIM(schemap.name) + '].[' + RTRIM(objp.name) + '] ' +
       'DROP CONSTRAINT [' + RTRIM(constr.name) + '];') AS sqltext
    FROM
      sys.foreign_key_columns AS fkc
    JOIN
      sys.objects AS objp ON objp.object_id=fkc.parent_object_id
    JOIN
      sys.schemas AS schemap ON objp.schema_id=schemap.schema_id
    JOIN
      sys.objects AS objr ON objr.object_id=fkc.referenced_object_id
    JOIN
      sys.schemas AS schemar ON objr.schema_id=schemar.schema_id
    JOIN
      sys.columns AS colr ON colr.column_id=fkc.referenced_column_id and colr.object_id=fkc.referenced_object_id
    JOIN
      sys.columns AS colp ON colp.column_id=fkc.parent_column_id and colp.object_id=fkc.parent_object_id
    JOIN
      sys.objects AS constr ON constr.object_id=fkc.constraint_object_id
    WHERE
      -- ToDo
      ((schemar.name=@schemaname) AND (objr.name=@tablename) AND (colr.name=@columnname) AND (objr.type='U')) OR
      ((schemap.name=@schemaname) AND (objp.name=@tablename) AND (colp.name=@columnname) AND (objr.type='U'));

    -- Create foreign key
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      schemap.name AS schemaname
      ,objp.name AS tablename
      ,'FK' AS objecttype
      ,'C' AS operationtype
      ,('ALTER TABLE [' + RTRIM(schemap.name) + '].[' + RTRIM(objp.name) + '] ' + 
        CASE (fk.is_not_trusted)
          WHEN 0 THEN 'WITH CHECK ADD CONSTRAINT [' + RTRIM(constr.name) + '] '
          WHEN 1 THEN 'WITH NOCHECK ADD CONSTRAINT [' + RTRIM(constr.name) + '] '
        END +
        'FOREIGN KEY ([' + RTRIM(colp.name) + '])' + ' ' +
        'REFERENCES [' + RTRIM(schemar.name) + '].[' + RTRIM(objr.name) + ']([' + RTRIM(colr.name) + ']);') AS sqltext
    FROM
      sys.foreign_key_columns AS fkc
    JOIN
      sys.foreign_keys AS fk ON fkc.constraint_object_id=fk.object_id
    JOIN
      sys.objects AS objp ON objp.object_id=fkc.parent_object_id
    JOIN
      sys.schemas AS schemap ON objp.schema_id=schemap.schema_id
    JOIN
      sys.objects AS objr ON objr.object_id=fkc.referenced_object_id
    JOIN
      sys.schemas AS schemar ON objr.schema_id=schemar.schema_id
    JOIN
      sys.columns AS colr ON colr.column_id=fkc.referenced_column_id and colr.object_id=fkc.referenced_object_id
    JOIN
      sys.columns AS colp ON colp.column_id=fkc.parent_column_id and colp.object_id=fkc.parent_object_id
    JOIN
      sys.objects AS constr ON constr.object_id=fkc.constraint_object_id
    WHERE
      -- ToDo
      /*
      (schemar.name=@schemaname)
      AND (objr.name=@tablename)
      AND (colr.name=@columnname)
      AND (objr.type='U');
      */
      ((schemar.name=@schemaname) AND (objr.name=@tablename) AND (colr.name=@columnname) AND (objr.type='U')) OR
      ((schemap.name=@schemaname) AND (objp.name=@tablename) AND (colp.name=@columnname) AND (objr.type='U'));

    -- Default constraints section
    -- Drop default constraints
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      S.name AS schemaname
      ,O.name AS tablename
      ,'DF' AS objecttype
      ,'D' AS operationtype
      ,('ALTER TABLE [' + RTRIM(S.name) + '].[' + RTRIM(O.name) + '] ' +
        'DROP [' + RTRIM(DC.name) + '];') AS sqltext
    FROM
      sys.default_constraints AS DC
    JOIN
      sys.objects AS O ON DC.parent_object_id=O.object_id
    JOIN
      sys.schemas AS S ON O.schema_id=S.schema_id
    JOIN
      sys.columns AS Col ON Col.default_object_id=DC.object_id
    WHERE
      (S.name=@schemaname)
      AND (O.name=@tablename)
      AND (Col.name=@columnname)
      AND (DC.type='D')
      AND (O.type='U');

    -- Create default constraints
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      S.name AS schemaname
      ,O.name AS tablename
      ,'DF' AS objecttype
      ,'C' AS operationtype
      ,('ALTER TABLE [' + RTRIM(S.name) + '].[' + RTRIM(O.name) + '] ' +
        'ADD CONSTRAINT [' + RTRIM(DC.name) + '] ' +
        'DEFAULT ' + DC.definition + ' ' +
        'FOR [' + Col.name + '];') AS sqltext
    FROM
      sys.default_constraints AS DC
    JOIN
      sys.objects AS O ON DC.parent_object_id=O.object_id
    JOIN
      sys.schemas AS S ON O.schema_id=S.schema_id
    JOIN
      sys.columns AS Col ON Col.default_object_id=DC.object_id
    WHERE
      (S.name=@schemaname)
      AND (O.name=@tablename)
      AND (Col.name=@columnname)
      AND (DC.type='D')
      AND (O.type='U');

    -- Unique constraints and Primary keys section
    -- Drop unique constraints and primary keys
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      DISTINCT
      KCU.TABLE_SCHEMA AS schemaname
      ,KCU.TABLE_NAME AS tablename
      -- ToDo: Keep fixed objecttype code 
      ,KC.type AS objecttype
      ,'D' AS operationtype
      ,('ALTER TABLE [' + RTRIM(KCU.TABLE_SCHEMA) + '].[' + RTRIM(KCU.TABLE_NAME) + '] ' +
        'DROP CONSTRAINT [' + RTRIM(KCU.CONSTRAINT_NAME) + '];') AS sqltext
    FROM
      INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU
    JOIN
      sys.key_constraints AS KC ON KCU.CONSTRAINT_NAME=KC.name
    WHERE
      (KCU.TABLE_SCHEMA=@schemaname)
      AND (KCU.TABLE_NAME=@tablename)
      AND (KCU.COLUMN_NAME=@columnname)
      AND ((KC.type='UQ') OR (KC.type='PK'));

    -- Create unique constraints and primary keys
    WITH UQC_PK AS
    (
      SELECT
        DISTINCT
        'A' AS rowtype
        -- ToDo: Keep fixed objecttype code
        ,K.type AS objecttype
        ,KCU.TABLE_CATALOG
        ,KCU.TABLE_SCHEMA
        ,KCU.TABLE_NAME
        ,KCU.CONSTRAINT_NAME
        ,CAST(0 AS INTEGER) AS ordinal_position
        ,CAST('' AS VARCHAR(MAX)) AS COLUMN_NAME
        ,CAST('ALTER TABLE [' + RTRIM(KCU.TABLE_SCHEMA) + '].[' + RTRIM(KCU.TABLE_NAME) + '] ' +
              (CASE (K.type)
                 WHEN 'PK' THEN 'WITH NOCHECK '
                 ELSE ''
               END)  +
              'ADD CONSTRAINT [' + RTRIM(KCU.CONSTRAINT_NAME) + '] ' +
              (CASE (K.type)
                 WHEN 'UQ' THEN 'UNIQUE'
                 WHEN 'PK' THEN 'PRIMARY KEY'
               END)  + '('AS VARCHAR(MAX)) AS sqltext
      FROM
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU
      JOIN
        sys.key_constraints AS K ON KCU.CONSTRAINT_NAME=K.name
      WHERE
        (KCU.TABLE_SCHEMA=@schemaname) 
        AND (KCU.TABLE_NAME=@tablename) 
        AND (KCU.COLUMN_NAME=@columnname) 
        AND ((K.type='UQ') OR (K.type='PK')) 

      UNION ALL

      SELECT
        'R' AS rowtype
        ,U.objecttype
        ,U.TABLE_CATALOG
        ,U.TABLE_SCHEMA
        ,U.TABLE_NAME
        ,U.CONSTRAINT_NAME
        ,KCU2.ORDINAL_POSITION
        ,U.COLUMN_NAME
        ,CAST(U.sqltext +
              CASE (KCU2.ordinal_position)
                WHEN 1 THEN ''
                ELSE ','
              END + ' [' + RTRIM(KCU2.COLUMN_NAME) + '] ' AS VARCHAR(MAX)) AS sqltext
      FROM
        UQC_PK AS U
      JOIN
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU2 ON (U.TABLE_CATALOG=KCU2.TABLE_CATALOG)
                                                   AND (U.TABLE_SCHEMA=KCU2.TABLE_SCHEMA)
                                                   AND (U.TABLE_NAME=KCU2.TABLE_NAME)
                                                   AND (U.CONSTRAINT_NAME=KCU2.CONSTRAINT_NAME)
      WHERE (KCU2.ordinal_position=U.ordinal_position + 1)
    ),
    UQC_PK2 AS
    (
      SELECT
        MAX(UQC_PK.ordinal_position) AS maxordinalposition
        ,UQC_PK.objecttype
        ,UQC_PK.TABLE_SCHEMA
        ,UQC_PK.TABLE_NAME
        ,UQC_PK.CONSTRAINT_NAME
      FROM
        UQC_PK
      WHERE
        (UQC_PK.rowtype='R')
      GROUP BY
        UQC_PK.objecttype
        ,UQC_PK.TABLE_SCHEMA
        ,UQC_PK.TABLE_NAME
        ,UQC_PK.CONSTRAINT_NAME
    )
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      UQC_PK.TABLE_SCHEMA
      ,UQC_PK.TABLE_NAME
      ,UQC_PK.objecttype
      ,'C'
      ,UQC_PK.sqltext + ') '
    FROM
      UQC_PK2
    JOIN
      UQC_PK ON (UQC_PK.CONSTRAINT_NAME=UQC_PK2.CONSTRAINT_NAME)
            AND (UQC_PK.TABLE_SCHEMA=UQC_PK2.TABLE_SCHEMA)
            AND (UQC_PK.TABLE_NAME=UQC_PK2.TABLE_NAME)
            AND (UQC_PK.ordinal_position=UQC_PK2.maxordinalposition);

    -- Check constraints section
    -- Drop check constraints
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      DISTINCT
      CCU.TABLE_SCHEMA AS schemaname
      ,CCU.TABLE_NAME AS tablename
      -- ToDo: Keep fixed objecttype code
      ,CHK.type AS objecttype
      ,'D' AS operationtype
      ,('ALTER TABLE [' + RTRIM(CCU.TABLE_SCHEMA) + '].[' + RTRIM(CCU.TABLE_NAME) + '] ' +
        'DROP CONSTRAINT [' + RTRIM(CCU.CONSTRAINT_NAME) + '];') AS sqltext
    FROM
      INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CCU
    JOIN
      sys.check_constraints AS CHK ON CCU.CONSTRAINT_NAME=CHK.name
    WHERE
      (CCU.TABLE_SCHEMA=@schemaname)
      AND (CCU.TABLE_NAME=@tablename)
      AND (CCU.COLUMN_NAME=@columnname)
      AND (CHK.type='C');

    -- Create (enabled) check constraints
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      DISTINCT
      CCU.TABLE_SCHEMA AS schemaname
      ,CCU.TABLE_NAME AS tablename
      ,CHK.type AS objecttype
      ,'C' AS operationtype
      ,('ALTER TABLE [' + RTRIM(CCU.TABLE_SCHEMA) + '].[' + RTRIM(CCU.TABLE_NAME) + '] ' +
        CASE (CHK.is_not_trusted)
          WHEN 0 THEN 'WITH CHECK ADD CONSTRAINT [' + RTRIM(CCU.CONSTRAINT_NAME) + '] CHECK ' + RTRIM(CHK.Definition) + ';'
          WHEN 1 THEN 'WITH NOCHECK ADD CONSTRAINT [' + RTRIM(CCU.CONSTRAINT_NAME) + '] CHECK ' + RTRIM(CHK.Definition) + ';'END ) AS sqltext
    FROM
      INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CCU
    JOIN
      sys.check_constraints AS CHK ON CCU.CONSTRAINT_NAME=CHK.name
    WHERE
      (CCU.TABLE_SCHEMA=@schemaname)
      AND (CCU.TABLE_NAME=@tablename)
      AND (CCU.COLUMN_NAME=@columnname)
      AND (CHK.type='C');

    -- Create (disabled) check constraints
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      DISTINCT
      CCU.TABLE_SCHEMA AS schemaname
      ,CCU.TABLE_NAME AS tablename
      ,CHK.type AS objecttype
      ,'I' AS operationtype
      ,('ALTER TABLE [' + RTRIM(CCU.TABLE_SCHEMA) + '].[' + RTRIM(CCU.TABLE_NAME) + '] ' +
        'NOCHECK CONSTRAINT [' + RTRIM(CCU.CONSTRAINT_NAME) + '];') AS sqltext
    FROM
      INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CCU
    JOIN
      sys.check_constraints AS CHK ON CCU.CONSTRAINT_NAME=CHK.name
    WHERE
      (CCU.TABLE_SCHEMA=@schemaname)
      AND (CCU.TABLE_NAME=@tablename)
      AND (CCU.COLUMN_NAME=@columnname)
      AND (CHK.type='C')
      AND (CHK.is_disabled=1);

    -- Statistics section
    -- Drop statistics
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      DISTINCT
      sch.name AS schemaname
      ,obj.name AS tablename
      ,'STATS' AS objecttype
      ,'D' AS operationtype
      ,'DROP STATISTICS [' + RTRIM(sch.name) + '].[' + RTRIM(obj.name) + '].[' + RTRIM(stat.name) + ']' AS SQLStr 
    FROM 
      sys.stats_columns AS statc 
    JOIN 
      sys.stats AS stat ON ((stat.stats_id=statc.stats_id) AND (stat.object_id=statc.object_id)) 
    JOIN 
      sys.objects AS obj ON statc.object_id=obj.object_id 
    JOIN 
      sys.columns AS col ON ((col.column_id=statc.column_id) AND (col.object_id=statc.object_id)) 
    JOIN 
      sys.schemas AS sch ON obj.schema_id=sch.schema_id 
    WHERE 
      (sch.name=@schemaname)
      AND (obj.name=@tablename)
      AND (col.name=@columnname)
      AND ((stat.auto_created=1) OR (stat.user_created=1))
      AND (obj.type='U');

    -- Create statistics
    WITH Stat AS 
    ( 
      SELECT 
        'A' AS RowType 
        ,T.object_id 
        ,T.stats_id 
        ,T.StatLevel 
        ,T.KeyOrdinal 
        ,T.SchemaName 
        ,T.TableName 
        ,CAST('CREATE ' +
              'STATISTICS [' + RTRIM(T.StatsName) + 
              '] ON [' + RTRIM(T.SchemaName) + 
              '].[' + RTRIM(T.TableName) +
              '] ( ' AS VARCHAR(MAX)) AS SQLStr 
      FROM 
      ( 
        SELECT 
          DISTINCT 
          stat.object_id 
          ,stat.stats_id 
          ,CAST(0 AS INTEGER) AS StatLevel 
          ,CAST(0 AS INTEGER) AS KeyOrdinal 
          ,stat.name AS StatsName 
          ,sch.name AS SchemaName 
          ,obj.name AS TableName 
        FROM 
          sys.stats_columns AS statc 
        JOIN 
          sys.stats AS stat ON ((stat.stats_id=statc.stats_id) 
                            AND (stat.object_id=statc.object_id)) 
        JOIN 
          sys.objects AS obj ON statc.object_id=obj.object_id 
        JOIN 
          sys.columns AS col ON ((col.column_id=statc.column_id) 
                             AND (col.object_id=statc.object_id)) 
        JOIN 
          sys.schemas AS sch ON obj.schema_id=sch.schema_id 
        WHERE 
          (sch.name=@schemaname)
          AND (obj.name=@tablename)
          AND (col.name=@columnname)
          AND (obj.type='U')
          AND ((stat.auto_created=1) OR (stat.user_created=1))
      ) AS T 

      UNION ALL 

      SELECT 
        'R' AS RowType 
        ,statcol.object_id 
        ,statcol.stats_id 
        ,CAST(S.StatLevel + 1 AS INTEGER) AS IdxLevel 
        ,CAST(statcol.stats_column_id AS INTEGER) KeyOrdinal 
        ,S.SchemaName 
        ,S.TableName 
        ,CAST(S.SQLStr + CASE (statcol.stats_column_id) WHEN 1 THEN '' ELSE ',' END + 
              ' [' + RTRIM(col.name) + 
              '] ' AS VARCHAR(MAX)) AS SQLStr 
      FROM 
        Stat AS S 
      JOIN 
        sys.stats_columns AS statcol ON ((statcol.object_id=S.object_id) 
                                     AND (statcol.stats_id=S.stats_id)) 
      JOIN 
        sys.columns AS col ON ((col.column_id=statcol.column_id) 
                           AND (col.object_id=statcol.object_id)) 
      WHERE 
        (statcol.stats_column_id=(S.KeyOrdinal + 1)) 
    ), 
    Stat2 AS 
    ( 
      SELECT 
        MAX(Stat.KeyOrdinal) AS MaxKeyOrdinal 
        ,Stat.object_id 
        ,Stat.stats_id 
      FROM 
        Stat 
      JOIN 
        sys.objects AS O ON O.object_id=Stat.object_id 
      WHERE 
        (Stat.RowType='R') 
      GROUP BY 
        Stat.object_id 
        ,Stat.stats_id 
    )
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      Stat.schemaname
      ,Stat.tablename
      ,'STATS' AS objecttype
      ,'C' AS operationtype
      ,Stat.SQLStr + ')'
    FROM 
      Stat2 
    JOIN 
      Stat ON ((Stat.object_id=Stat2.object_id) 
           AND (Stat.stats_id=Stat2.stats_id)) 
           AND (Stat.KeyOrdinal=Stat2.MaxKeyOrdinal);

    -- Indexes section
    -- Drop indexes
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      DISTINCT
      sch.name
      ,obj.name
      ,'IDX' AS objecttype
      ,'D' AS operationtype
      ,('DROP INDEX [' + RTRIM(sch.name) + '].[' + RTRIM(obj.name) + '].[' + RTRIM(idx.name) + '];') AS sqltext
    FROM
      sys.index_columns AS idxc
    JOIN
      sys.indexes AS idx ON ((idx.index_id=idxc.index_id)
                         AND (idx.object_id=idxc.object_id))
    JOIN
      sys.objects AS obj ON idxc.object_id=obj.object_id
    JOIN
      sys.columns AS col ON ((col.column_id=idxc.column_id)
                         AND (col.object_id=idxc.object_id))
    JOIN
      sys.schemas AS sch ON obj.schema_id=sch.schema_id
    WHERE
      (sch.name=@schemaname)
      AND (obj.name=@tablename)
      AND (col.name=@columnname)
      AND (idx.is_unique_constraint=0)
      AND (idx.is_primary_key=0)
      AND (obj.type='U')
    ORDER BY
      sqltext;

    -- Create indexes
    WITH Create_Indexes AS
    (
      SELECT
        'A' AS rowtype
        ,T.object_id
        ,T.index_id
        ,T.IdxLevel
        ,T.KeyOrdinal
        ,T.IsUnique
        ,T.IsClustered
        ,T.SchemaName
        ,T.TableName
        ,CAST('CREATE ' + T.IsUnique + T.IsClustered +
              'INDEX [' + RTRIM(T.IndexName) + '] ON [' + RTRIM(T.SchemaName) + '].[' +
              RTRIM(T.TableName) + '] ( 'AS VARCHAR(MAX)) AS sqltext
      FROM
        (SELECT
           DISTINCT
           idx.object_id
           ,idx.index_id
           ,CAST(0 AS INTEGER) AS IdxLevel
           ,CAST(0 AS INTEGER) AS KeyOrdinal
           ,CAST(CASE (idx.is_unique)
                   WHEN 1 THEN 'UNIQUE '
                   WHEN 0 THEN ''
                   ELSE ''
                 END AS VARCHAR(MAX)) AS IsUnique
           ,CAST(CASE (idx.type)
                   WHEN 1 THEN 'CLUSTERED '
                   WHEN 2 THEN 'NONCLUSTERED '
                   ELSE ''
                 END AS VARCHAR(MAX)) AS IsClustered
           ,idx.name AS IndexName
           ,sch.name AS SchemaName
           ,obj.name AS TableName
         FROM
           sys.index_columns AS idxc
         JOIN
           sys.indexes AS idx ON ((idx.index_id=idxc.index_id) AND (idx.object_id=idxc.object_id))
         JOIN
           sys.objects AS obj ON idxc.object_id=obj.object_id
         JOIN
           sys.columns AS col ON ((col.column_id=idxc.column_id) AND (col.object_id=idxc.object_id))
         JOIN
           sys.schemas AS sch ON obj.schema_id=sch.schema_id
         WHERE
           (sch.name=@schemaname)
           AND (obj.name=@tablename)
           AND (col.name=@columnname)
           AND (idx.is_unique_constraint=0)
           AND (idx.is_primary_key=0)
           AND (obj.type='U')
           AND NOT EXISTS (SELECT
                             [object_id]
                           FROM
                             sys.index_columns AS ic
                           WHERE (ic.is_included_column=1)
                             AND (idxc.[object_id]=ic.[object_id])
                             AND (idxc.index_id=ic.index_id)
                          )
        ) AS T
             
      UNION ALL 
      
      SELECT
        'R' AS RowType
        ,idxcol.object_id
        ,idxcol.index_id
        ,CAST(I.IdxLevel + 1 AS INTEGER) AS IdxLevel
        ,CAST(idxcol.key_ordinal AS INTEGER) AS KeyOrdinal
        ,CAST('' AS VARCHAR(MAX)) AS IsUnique
        ,CAST('' AS VARCHAR(MAX)) AS IsClustered
        ,I.SchemaName
        ,I.TableName
        ,CAST(I.sqltext + CASE (idxcol.key_ordinal)
                            WHEN 1 THEN ''
                            ELSE ','
                          END + ' [' + RTRIM(col.name) + '] ' AS VARCHAR(MAX)) AS sqltext
      FROM
        Create_Indexes AS I
      JOIN
        sys.index_columns AS idxcol ON ((idxcol.object_id=I.object_id) AND (idxcol.index_id=I.index_id))
      JOIN
        sys.columns AS col ON ((col.column_id=idxcol.column_id) AND (col.object_id=idxcol.object_id))
      WHERE
        (idxcol.key_ordinal=I.KeyOrdinal + 1)
    ),
    Create_Indexes2 AS
    (
      SELECT
        MAX(Create_Indexes.KeyOrdinal) AS MaxKeyOrdinal
        ,Create_Indexes.object_id
        ,Create_Indexes.index_id
      FROM
        Create_Indexes
      JOIN
        sys.objects AS O ON (O.object_id=Create_Indexes.object_id)
      WHERE
        (Create_Indexes.RowType='R')
      GROUP BY
        Create_Indexes.object_id
        ,Create_Indexes.index_id
    )
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      Create_Indexes.SchemaName
      ,Create_Indexes.TableName
      ,'IDX' AS objecttype
      ,'C' AS operationtype
      ,Create_Indexes.sqltext + ')'
    FROM
      Create_Indexes2
    JOIN
      Create_Indexes ON ((Create_Indexes.object_id=Create_Indexes2.object_id)
                     AND (Create_Indexes.index_id=Create_Indexes2.index_id)
                     AND (Create_Indexes.KeyOrdinal=Create_Indexes2.MaxKeyOrdinal));

    -- Views section
    -- Refresh views
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    )
    SELECT
      V.TABLE_SCHEMA
      ,V.TABLE_NAME
      ,'VW' AS objecttype
      ,'R' AS OperationType
      ,('EXECUTE sp_refreshview ''[' + RTRIM(V.TABLE_SCHEMA) + '].[' + RTRIM(V.TABLE_NAME) + ']'';') AS sqltext
    FROM
      INFORMATION_SCHEMA.VIEWS AS V
    WHERE
      (V.IS_UPDATABLE='NO');

    DECLARE
      @sqldrop NVARCHAR(MAX) = ''
      --,@sqldropfk NVARCHAR(MAX) = ''
      --,@sqldroppk NVARCHAR(MAX) = ''
      --,@sqldropuq NVARCHAR(MAX) = ''
      --,@sqldropck NVARCHAR(MAX) = ''
      --,@sqldropdf NVARCHAR(MAX) = ''
      --,@sqldropidx NVARCHAR(MAX) = ''
      --,@sqldropstats NVARCHAR(MAX) = ''

      ,@sqlcreate NVARCHAR(MAX) = ''
      --,@sqlcreatefk NVARCHAR(MAX) = ''
      --,@sqlcreatepk NVARCHAR(MAX) = ''
      --,@sqlcreateuq NVARCHAR(MAX) = ''
      --,@sqlcreateck NVARCHAR(MAX) = ''
      --,@sqlcreatedf NVARCHAR(MAX) = ''
      --,@sqlcreateidx NVARCHAR(MAX) = ''
      --,@sqlcreatestats NVARCHAR(MAX) = ''

      ,@sqlaltertable NVARCHAR(MAX) = ''
      ,@sqlrenametable NVARCHAR(MAX) = ''

      ,@crlf NVARCHAR(2) = CHAR(13)+CHAR(10)
      ,@trancount INTEGER = @@TRANCOUNT
      ,@olddatatype SYSNAME
      --,@tmpNewDataType SYSNAME;

    --------------------------------------------------------
    -- DROP statements for the following objects
    --
    -- Foreign key (FK)
    -- Primary key (PK)
    -- Unique constraints (UQ)
    -- Check constraints (CK)
    -- Default constraints (DF)
    -- Indexes (not related to unique constraints, IDX)
    -- Statistics
    --------------------------------------------------------

    IF (@executionmode = 1)
    BEGIN
      IF (@trancount = 0)
        -- Opening an explicit transaction to avoid auto commits
        BEGIN TRANSACTION
    END

    DECLARE C_SQL_DROP CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='FK')
        AND (operationtype='D')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='PK')
        AND (operationtype='D')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='UQ')
        AND (operationtype='D')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='CK')
        AND (operationtype='D')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='DF')
        AND (operationtype='D')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='IDX')
        AND (operationtype='D')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='STATS')
        AND (operationtype='D');
    
    OPEN C_SQL_DROP;

    -- First fetch
    FETCH NEXT FROM C_SQL_DROP INTO @sqldrop

    WHILE (@@FETCH_STATUS=0)
    BEGIN
      IF (@executionmode = 0)
        PRINT(@sqldrop);
      ELSE IF (@executionmode = 1)
        EXEC(@sqldrop);
      FETCH NEXT FROM C_SQL_DROP INTO @sqldrop
    END;
    
    CLOSE C_SQL_DROP;
    DEALLOCATE C_SQL_DROP;

    SET @sqlaltertable = 'ALTER TABLE [' + @schemaname + '].[' + @tablename + 
                         '] ALTER COLUMN [' + @columnname + 
                         '] ' + @datatype + ';' + @CRLF;

    -- ALTER TABLE
    INSERT INTO #tmp_usp_alter_column
    (
      schemaname
      ,tablename
      ,objecttype
      ,operationtype
      ,sqltext
    ) VALUES
    (
      @schemaname
      ,@tablename
      ,'COL'
      ,'A'
      ,@sqlaltertable
    );
	  
    IF (@executionmode = 0)
      PRINT(@sqlaltertable);
    ELSE IF (@executionmode = 1)
      EXEC(@sqlaltertable);

    IF (@columnname <> @columnrename) AND
       (LTRIM(RTRIM(@columnrename)) <> '')
    BEGIN
      SET @sqlrenametable = 'EXEC sp_rename ''[' + @schemaname + '].[' + @tablename +'].[' + @columnname + ']'', ''[' +
                                                   @schemaname + '].[' + @tablename +'].[' + @columnrename + ']''' + @CRLF;	  

      -- Rename
      INSERT INTO #tmp_usp_alter_column
      (
        schemaname
        ,tablename
        ,objecttype
        ,operationtype
        ,sqltext
      ) VALUES
      (
        @schemaname
        ,@tablename
        ,'COL'
        ,'R'
        ,@sqlrenametable
      );

      IF (@executionmode = 0)
        PRINT(@sqlrenametable);
      ELSE IF (@executionmode = 1)
        EXEC(@sqlrenametable);
    END;

    --------------------------------------------------------
    -- CREATE statements for the following objects
    --
    -- Foreign key (FK)
    -- Primary key (PK)
    -- Unique constraints (UQ)
    -- Check constraints (CK)
    -- Default constraints (DF)
    -- Indexes (not related to unique constraints, IDX)
    -- Statistics
    --------------------------------------------------------
    DECLARE C_SQL_CREATE CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='FK')
        AND (operationtype='C')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='PK')
        AND (operationtype='C')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='UQ')
        AND (operationtype='C')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='CK')
        AND (operationtype='C')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='DF')
        AND (operationtype='C')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='IDX')
        AND (operationtype='C')
      UNION ALL
      SELECT
        sqltext
      FROM
        #tmp_usp_alter_column
      WHERE
        (objecttype='STATS')
        AND (operationtype='C');
    
    OPEN C_SQL_CREATE;

    -- First fetch
    FETCH NEXT FROM C_SQL_CREATE INTO @sqlcreate

    WHILE (@@FETCH_STATUS=0)
    BEGIN
      IF (@executionmode = 0)
        PRINT(@sqlcreate);
      ELSE IF (@executionmode = 1)
        EXEC(@sqlcreate);

      FETCH NEXT FROM C_SQL_CREATE INTO @sqlcreate;
    END;
    
    CLOSE C_SQL_CREATE;
    DEALLOCATE C_SQL_CREATE;

    --PRINT(@sqldropfk + @sqldroppk + @sqldropuq + @sqldropck + @sqldropdf + @sqldropidx + @sqldropstats);
    --PRINT(@sqlcreatefk + @sqlcreatepk + @sqlcreateuq + @sqlcreateck + @sqlcreatedf + @sqlcreateidx + @sqlcreatestats);
    IF (@executionmode = 0)
      SELECT * FROM #tmp_usp_alter_column;

    IF (@executionmode = 1) AND
       (@trancount = 0) AND
       (@@ERROR = 0)
      COMMIT TRANSACTION;

    SET NOCOUNT OFF;
  END TRY
  BEGIN CATCH
    IF (@executionmode = 1) AND
       (@trancount = 0)
      ROLLBACK TRANSACTION;

    -- Error handling
    DECLARE
      @ErrorMessage NVARCHAR(MAX)
      ,@ErrorSeverity INTEGER
      ,@ErrorState INTEGER;

    SELECT 
      @ErrorMessage = ERROR_MESSAGE()
      ,@ErrorSeverity = ERROR_SEVERITY()
      ,@ErrorState = ERROR_STATE();

    SET NOCOUNT OFF;

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
  END CATCH
END;
GO