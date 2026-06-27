use master;
GO

-- Drop and recereate the 'DataWarehouse' database
if exists (select 1 from sys.databases wher name='DataWarehouse')
begin
	alter database DataWarehouse set single_user with rollback immediate;
	drop database DataWarehouse;
end;
go


-- Create the 'DataWarehouse' database

create database DataWarehouse;
go


use DataWarehouse;

-- Creating Schemas

create schema bronze;
go -- separate batches when working with multiple SQL Statements

create schema silver;
go -- separate batches when working with multiple SQL Statements

create schema gold;
go -- separate batches when working with multiple SQL Statements


