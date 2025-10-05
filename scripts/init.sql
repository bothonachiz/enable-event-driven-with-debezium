-- Create sample database SaleDB
CREATE DATABASE SaleDB;
GO

USE SaleDB;
GO

-- Create example table
CREATE TABLE Products (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Note NVARCHAR(100) NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Create a dedicated user for Debezium
CREATE LOGIN debezium_user WITH PASSWORD = 'Debezium@123';
GO

CREATE USER debezium_user FOR LOGIN debezium_user;
GO

-- Grant necessary permissions to the Debezium user
ALTER ROLE db_owner ADD MEMBER debezium_user;
GO

USE SaleDB;
GO

-- Enable CDC on the database
EXEC sys.sp_cdc_enable_db;
GO

-- Enable CDC on the Products table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Products',
    @role_name = NULL,
    @supports_net_changes = 0;
GO

-- Insert some sample data
INSERT INTO Products (ProductName, Price, Note) VALUES 
('Product A', 10.00, NULL),
('Product B', 20.00, NULL),
('Product C', 30.00, 'pre-order item');
GO