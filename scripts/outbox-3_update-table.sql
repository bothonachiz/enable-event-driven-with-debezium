-- Introduce to Outbox Pattern, Step 3 - Update outbox table add column event_topic

-- Change database
USE SaleDB;

-- Alter table add new column
ALTER TABLE outbox ADD event_topic NVARCHAR(50) NOT NULL DEFAULT '';

-- Create new capture instance
EXEC sys.sp_cdc_enable_table 
    @source_schema = 'dbo',
    @source_name = 'outbox', 
    @role_name = NULL, 
    @supports_net_changes = 0, 
    @capture_instance = 'dbo_outbox_v2';