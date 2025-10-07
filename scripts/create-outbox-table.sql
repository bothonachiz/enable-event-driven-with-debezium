-- Create database
IF NOT EXISTS (SELECT *
FROM sys.databases
WHERE name = 'SaleDB')
BEGIN
    CREATE DATABASE SaleDB;
END;
GO

-- Change database
USE SaleDB;
GO

-- Create the outbox table
CREATE TABLE outbox
(
    id UNIQUEIDENTIFIER PRIMARY KEY NOT NULL DEFAULT NEWID(),
    aggregatetype NVARCHAR(255) NOT NULL,
    aggregateid NVARCHAR(255) NOT NULL,
    type NVARCHAR(255) NOT NULL,
    payload NVARCHAR(MAX) NOT NULL,
    timestamp DATETIME2 DEFAULT GETDATE()
);
GO

-- Create sale order table
CREATE TABLE sale_orders
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    sale_order_number NVARCHAR(12) NOT NULL,
    customer NVARCHAR(255) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    total_items INT NOT NULL,
    is_cancelled BIT DEFAULT 0
);
GO

-- Create sale order item table
CREATE TABLE sale_order_items
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    sale_order_id INT NOT NULL,
    sale_order_item_number NVARCHAR(15) NOT NULL,
    sku NVARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (sale_order_id) REFERENCES sale_orders(id)
);
GO

-- Enable CDC on the Outbox table
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'outbox',
    @role_name = NULL,
    @supports_net_changes = 0;
GO
