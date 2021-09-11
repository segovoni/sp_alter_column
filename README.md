# SQL Server sp_alter_column stored procedure!

The *sp_alter_column* stored procedure is able to alter a column with dependencies in your SQL Server database!

If you ever had to change the data type or the name of a column, you may have incurred into the [error message 5074](https://docs.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-events-and-errors?view=sql-server-2017#errors-5000-to-5999) which indicates that it is impossible to modify the column due to the presence of linked objects such as a Primary Key, Foreign Key, Indexes, Constraints, Statistics and so on.

This is the error you probably faced:

```sql
Msg 5074, Level 16, State 1, Line 1135 - The object 'objectname' is dependent on column 'columnname'.

Msg 4922, Level 16, State 9, Line 1135 - ALTER TABLE ALTER COLUMN Columnname failed because one or more objects access this column.
```

Changing the column name is not a trivial operation especially if the column is referenced in Views, Stored Procedures etc. To execute the rename of a column, there is the [sp_rename](https://docs.microsoft.com/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql?view=sql-server-2017) system Stored Procedure, but for changing the data type of the column, if you don't want to use any third-party tools, you have no other option than to manually create a T-SQL script.

How did you solve the problem?

Some of you have probably deleted manually the linked objects, changed the data type, the size or the properties of the column, and then you may have recreated the previously deleted objects manually. You must have been very careful to avoid chenging the properties of the objects themselves during DROP and CREATE operations.

I have faced several times this issue, so I have decided to create a stored procedure that is able to compose automatically the appropriate DROP and CREATE commands for each object connected to the column I want to modify. This is how the stored procedure [sp_alter_column](https://github.com/segovoni/sp_alter_column) was born, and it's now available on this GitHub repository!

## Roadmap

The roadmap of the *sp_alter_column* is always updated as-soon-as the features planned are implemented. Check the roadmap [here](roadmap.md).

# Getting Started

Download the [sp-alter-column.sql](/source/sp-alter-column.sql), this script creates the *sp_alter_column* stored procedure in your database!


Enjoy!
