# SQL Server sp_alter_column stored procedure!

The *sp_alter_column* stored procedure is able to alter a column with dependencies in your SQL Server database!

It will have been happened to you to change the data type or the name of a column and be faced with the error 5074 which indicates that it is impossible to modify the column due to the presence of linked objects such as a Primary Key, Foreign Key, Indexes, Constraints, Statistics and so on.

This is the error you probably faced on:

```sql
Msg 5074, Level 16, State 1, Line 1135 - The object 'objectname' is dependent on column 'Columnname'.

Msg 4922, Level 16, State 9, Line 1135 - ALTER TABLE ALTER COLUMN Columnname failed because one or more objects access this column.
```

How did you solve the problem?

I faced several times this issue, so I decided to create a stored procedure that is able to compose automatically the appropriate commands to DROP and CREATE objects connected to the column I want to modify. Thus was born the Stored Procedure *sp_alter_column* which is now available on this GitHub repository.

## Roadmap

The roadmap of the *sp_alter_column* is always updated as-soon-as the features planned are implemented. Check the roadmap [here](roadmap.md).

# Getting Started

Download the [sp-alter-column.sql](/source/sp-alter-column.sql), this script creates the *sp_alter_column* stored procedure in your database!


Enjoy!
