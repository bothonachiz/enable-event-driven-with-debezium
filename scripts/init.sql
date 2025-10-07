-- Create sample database SaleDB
CREATE DATABASE SaleDB;
GO

USE SaleDB;
GO

-- Create example table
CREATE TABLE products (
    id INT PRIMARY KEY IDENTITY(1,1),
    product_name NVARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    note NVARCHAR(100) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
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

-- Enable CDC on the products table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'products',
    @role_name = NULL,
    @supports_net_changes = 0;
GO

-- Insert some sample data
INSERT INTO products (product_name, price, note) VALUES 
('Product A', 10.00, NULL),
('Product B', 20.00, NULL),
('Product C', 30.00, 'pre-order item');
GO