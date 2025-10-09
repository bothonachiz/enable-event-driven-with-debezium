# Debezium Workshop
## Change Data Capture in Action

### What We'll Build
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   MSSQL     │───▶│  Debezium   │───▶│    Kafka    │───▶│  Kafbat UI  │
│  Database   │    │ Connector   │    │   Broker    │    │  (Web UI)   │
│  (SaleDB)   │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       ↑                  ↑                 ↑                   ↑
   Port 1433          Port 8083          Port 9092          Port 9000
```

### Repository Structure
```
enable-event-driven/
├── docker-compose.yml                  # Complete environment
├── scripts/
│   └── init.sql                        # Database initialization
│   └── ...                
├── connectors/
│   ├── first-connector.json            # Basic connector
│   └── ...
└── README.md                           # Step-by-step guide
```

---

## 🚀 Prerequisites & Setup

### System Requirements
- **Docker Desktop** installed and running
- **Git** for cloning repository
- **8GB RAM** minimum (Docker containers)
- **Ports available**: 1433, 8083, 9091, 9092, 9000, 2181

### Clone the Repository
```bash
git clone https://github.com/bothonachiz/enable-event-driven-with-debezium.git
cd enable-event-driven-with-debezium
```

### Verify Docker Setup
```bash
docker --version
docker-compose --version

# Check available resources
docker system df
```

---

## 🗄️ Step 1: MSSQL Server Database Setup

### Start MSSQL Server Container
``` bash
# Start only MSSQL Server first
docker compose up --build -d mssql-server

# Wait for MSSQL Server to be ready (30-60 seconds)
docker logs mssql-server -f
```

### Database Initialization Script
**File: `scripts/init.sql`**
```sql
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
```

### Verify Database Setup
``` bash
docker exec mssql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U debezium_user -P Debezium@123 -Q "USE SaleDB; SELECT * FROM products;" -C
```

**Expected Output:**
```
+----+---------------+--------+----------------+-------------------------+-------------------------+
| id | product_name  | price  | note           | created_at              | updated_at              |
+----+---------------+--------+----------------+-------------------------+-------------------------+
|  1 | Product A     | 10.00  |                | 2025-10-05 09:10:34.597 | 2025-10-05 09:10:34.597 |
|  2 | Product B     | 20.00  |                | 2025-10-05 09:10:34.597 | 2025-10-05 09:10:34.597 |
|  3 | Product C     | 30.00  | pre-order item | 2025-10-05 09:10:34.597 | 2025-10-05 09:10:34.597 |
+----+---------------+--------+----------------+-------------------------+-------------------------+
```

---

## 📡 Step 2: Kafka Infrastructure

### Start Kafka

``` bash
# Start Kafka infrastructure
docker compose up --build -d kafka

# Verify containers are running
docker ps
```

### Test Kafka Installation
```bash
# Connect to Kafka container
docker exec -it kafka bash

# Create test topic
kafka-topics --create --topic test-topic \
  --bootstrap-server localhost:9092 \
  --partitions 1 --replication-factor 1

# List topics to verify
kafka-topics --list --bootstrap-server localhost:9092
```

### Send Test Message
```bash
# Start producer (inside kafka container)
kafka-console-producer --topic test-topic --bootstrap-server localhost:9092

# Type a message and press Enter
{"message": "Hello Kafka!", "timestamp": "2025-10-09T09:00:00Z"}

# Press Ctrl+C to exit
```

### Verify Message Reception
```bash
# In another terminal, start consumer
docker exec -it kafka bash
kafka-console-consumer --topic test-topic \
  --bootstrap-server localhost:9092 --from-beginning

# You should see the message you sent
```

---

## 🎮 Step 3: Kafbat UI (Optional but Recommended)

### Start Kafbat UI
```bash
# Start Kafbat UI for web-based Kafka monitoring
docker compose up --build -d kafka-ui
```

### Access Web Interface
- **URL**: http://localhost:8080/
- **Features**:
  - Browse topics and partitions
  - View messages in real-time
  - Monitor consumer groups
  - Inspect message schemas

### Kafka UI Interface Tour
1. **Topics List**: See all Kafka topics
2. **Topic Details**: Message count, partitions
3. **Message Browser**: View actual message content
4. **Consumer Groups**: Monitor consumption lag

---

## 🔗 Step 4: Debezium Kafka Connect

### Start Debezium Connect
```bash
# Start Debezium Kafka Connect service
docker compose up --build -d debezium-kafka-connect

# Wait for Connect to be ready (60-90 seconds)
docker logs debezium-kafka-connect -f
```

### Verify Connect Installation
```bash
# Check Connect REST API
curl -s http://localhost:8083/

# List available connector plugins
curl -s http://localhost:8083/connector-plugins | jq
```
**Expected Debezium Connectors:**
```json
[
  // ....
  {
    "class": "io.debezium.connector.sqlserver.SqlServerConnector",
    "type": "source",
    "version": "3.2.3.Final"
  }
  // ....
]
```

## 🎯 Step 5: Complete Environment Verification
### All Services Running
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected Output:**
```
NAMES                    STATUS       PORTS
debezium-kafka-connect   Up 2 hours   8778/tcp, 0.0.0.0:8083->8083/tcp, 9092/tcp
kafka-ui                 Up 3 hours   0.0.0.0:8080->8080/tcp
kafka                    Up 3 hours   0.0.0.0:9092-9093->9092-9093/tcp
mssql-server             Up 3 hours   0.0.0.0:1433->1433/tcp
```

### Service Health Checks
```bash
# MSSQL server connectivity
docker exec mssql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U debezium_user -P Debezium@123 -Q "SELECT 1" -C

# Kafka broker health  
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092

# Connect cluster health
curl -s http://localhost:8083/connector-plugins | jq length

# Kafka UI accessibility
curl -s http://localhost:8080/ | grep -q "Kafbat"
```

**note**: We haven't created the Debezium connector yet, so this change won't appear in Kafka topics. We'll do that in the next section!

---

## 🥳 Step 6: First Connector Configuration
### The first Connector Configuration File
**File: `connectors/first-connector.json`**

```json
{
    "name": "first-connector", 
    "config": {
        "connector.class": "io.debezium.connector.sqlserver.SqlServerConnector", 
        "database.hostname": "mssql-server", 
        "database.port": "1433", 
        "database.user": "debezium_user", 
        "database.password": "Debezium@123", 
        "database.names": "SaleDB",
        "database.encrypt": "false",
        "topic.prefix": "debezium.sqlserver",
        "table.include.list": "dbo.products", 
        "schema.history.internal.kafka.bootstrap.servers": "kafka:9092", 
        "schema.history.internal.kafka.topic": "schema-changes.sqlserver"
    }
}
```

---

### 🔧 Configuration Parameters Explained
```json
"connector.class": "io.debezium.connector.sqlserver.SqlServerConnector"
```
- **Purpose**: Specifies the connector type
- **Value**: MSSQL Server Debezium connector class

```json
"database.hostname": "mssql-server", 
"database.port": "1433", 
"database.user": "debezium_user", 
"database.password": "Debezium@123", 
"database.names": "SaleDB"
```
- **Purpose**: Database connection parameters
- **note**: User must have replication privileges

```json
"database.encrypt": "false"
```
-- **Purpose**: SSL encryption disabled

```json
"topic.prefix": "debezium.sqlserver"
```
- **Purpose**: Prefix for Kafka topic names
- **Result**: Topics like `debezium.sqlserver.SaleDB.dbo.products`

### Data Selection
```json
"table.include.list": "dbo.products"
```
- **Purpose**: Databases to capture changes from
- **Alternative**: `table.exclude.list` for exclusion

### Schema Management
```json
"schema.history.internal.kafka.bootstrap.servers": "kafka:9092", 
"schema.history.internal.kafka.topic": "schema-changes.sqlserver"
```
- **Purpose**: Tracks database schema evolution
- **Importance**: Handles DDL changes automatically
- **Storage**: Internal Kafka topic for schema history

---

### Step 7: Deploy the Connector
```bash
# Deploy connector via REST API
curl -X POST -H "Content-Type: application/json" --data @connectors/first-connector.json http://localhost:8083/connectors
```

**Expected Response:**
```json
{
  "name": "first-connector",
  "config": { ... },
  "tasks": [],
  "type": "source"
}
```

### Step 8: Verify Connector Status
```bash
# Check connector status
curl -s http://localhost:8083/connectors/first-connector/status | jq

# List all connectors
curl -s http://localhost:8083/connectors | jq
```

**Healthy Status:**
```json
{
  "name": "first-connector",
  "connector": {
    "state": "RUNNING",
    "worker_id": "connect:8083"
  },
  "tasks": [{
    "id": 0,
    "state": "RUNNING",
    "worker_id": "connect:8083"
  }]
}
```

### Step 9: Check Generated Topics
Visit **kafka-ui** (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.products` - products table changes
- `schema-changes.sqlserver` - Schema evolution history
- `enable_event_driven_connect_offsets` - Snapshot latest Log Sequence Number (lsn)

---

## 🧪 Live Testing: Making Changes

### Test 1: INSERT Operation
``` sql
-- Insert new row
INSERT INTO dbo.products (product_name, price) VALUES ('Product D', 199.00);
```

Visit **kafka-ui** (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.products` - products table changes (with operation "c")
- `enable_event_driven_connect_offsets` - Latest Log Sequence Number (lsn) was changed!

``` sql
-- Insert new row again
INSERT INTO dbo.products (product_name, price) VALUES ('Product E', 250.00);
```

Visit **kafka-ui** again (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.products` - products table changes (with operation "c")

### Test 2: 🤔 What happens if Debezium is down

``` bash
# Stop debezium-kafka-connect container
docker compose down debezium-kafka-connect

# Make sure debezium-kafka-connect is gone
docker ps -a | grep debezium-kafka-connect
docker container ls -a | grep debezium-kafka-connect
```

``` sql
-- Insert new row again
INSERT INTO dbo.products (product_name, price, note) VALUES ('Product F', 99.00, 'pre-order item');
```

Visit **kafka-ui** again (http://localhost:8080/) and look for:
- no changes detected

``` bash
# Now start debezium-kafka-connect container
docker compose up --build -d debezium-kafka-connect
```

Visit **kafka-ui** again (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.products` - new products table changes automatically
- `enable_event_driven_connect_offsets` - Latest Log Sequence Number (lsn) was changed!

### Test 3: UPDATE Operation

``` sql
-- Update some products
UPDATE dbo.products SET price = 52.00 WHERE id = 1
```

Visit **kafka-ui** again (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.products` - products table changes (with operation "u")

### Test 4: DELETE Operation

``` sql
-- Delete some products
DELETE dbo.products WHERE price > 100
```

Visit **kafka-ui** again (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.products` - products table changes (with operation "u")

### Test 5: Try to updating connectors

``` sql
-- Create new table customers
CREATE TABLE customers (
    id INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);
-- Enable cdc for Customer
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'customers',
    @role_name = NULL,
    @supports_net_changes = 0;

INSERT INTO customers (FirstName, LastName) VALUES
('John', 'Doe'),
('Anna', 'Smith')
```

``` bash
# Remove an old connector
curl -X DELETE http://localhost:8083/connectors/first-connector

# Deploy new connector
curl -X POST -H "Content-Type: application/json" --data @connectors/update-first-connector.json http://localhost:8083/connectors
```

Visit **kafka-ui** (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.customers` - customers table changes (with operation "c")

### Test 6: Schema evolution

``` sql
-- Alter table add new column
ALTER TABLE customers ADD PhoneNumber NVARCHAR(20) NULL;

-- Create new capture instance
EXEC sys.sp_cdc_enable_table 
    @source_schema = 'dbo',
    @source_name = 'customers', 
    @role_name = NULL, 
    @supports_net_changes = 0, 
    @capture_instance = 'dbo_customers_v2';

-- Insert sample data
INSERT INTO customers (FirstName, LastName, PhoneNumber) VALUES
('Sara', 'Rose', '+66985567767');
```

View debezium connector logs 
``` bash
docker logs -f debezium-kafka-connect
```

and look for:
``` log
2025-10-05T11:28:27,177 INFO   SQL_Server||streaming  Multiple capture instances present for the same table: Capture instance "dbo_customers" [sourceTableId=SaleDB.dbo.customers, changeTableId=SaleDB.cdc.dbo_customers_CT, startLsn=0000002e:00000108:004c, changeTableObjectId=1909581841, stopLsn=0000002e:00001570:004d] and Capture instance "dbo_customers_v2" [sourceTableId=SaleDB.dbo.customers, changeTableId=SaleDB.cdc.dbo_customers_v2_CT, startLsn=0000002e:00001570:004d, changeTableObjectId=1989582126, stopLsn=NULL]   [io.debezium.connector.sqlserver.SqlServerStreamingChangeEventSource]

2025-10-05T11:28:27,178 INFO   SQL_Server||streaming  Schema will be changed for Capture instance "dbo_customers_v2" [sourceTableId=SaleDB.dbo.customers, changeTableId=SaleDB.cdc.dbo_customers_v2_CT, startLsn=0000002e:00001570:004d, changeTableObjectId=1989582126, stopLsn=NULL]   [io.debezium.connector.sqlserver.SqlServerStreamingChangeEventSource]

2025-10-05T11:28:27,178 INFO   SQL_Server||streaming  The stop lsn of Capture instance "dbo_customers" [sourceTableId=SaleDB.dbo.customers, changeTableId=SaleDB.cdc.dbo_customers_CT, startLsn=0000002e:00000108:004c, changeTableObjectId=1909581841, stopLsn=0000002e:00001570:004d] change table became known   [io.debezium.connector.sqlserver.SqlServerStreamingChangeEventSource]

2025-10-05T11:28:42,525 INFO   SQL_Server||streaming  Migrating schema to Capture instance "dbo_customers_v2" [sourceTableId=SaleDB.dbo.customers, changeTableId=SaleDB.cdc.dbo_customers_v2_CT, startLsn=0000002e:00001570:004d, changeTableObjectId=1989582126, stopLsn=NULL]   [io.debezium.connector.sqlserver.SqlServerStreamingChangeEventSource]
```

### Test 7: 🤔 What happens if doesn't create new capture instance

``` sql
-- Alter table add new column
ALTER TABLE customers ADD [Address] NVARCHAR(255) NULL;

-- Insert sample data
INSERT INTO customers (FirstName, LastName, PhoneNumber, [Address]) VALUES
('Lulu', 'Lala', '+66827762213', 'Bangkok');
```

Visit **kafka-ui** (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.customers` - customers table changes (with operation "c")
- But address is missing

``` sql
-- Create new capture instance
EXEC sys.sp_cdc_enable_table 
    @source_schema = 'dbo',
    @source_name = 'customers', 
    @role_name = NULL, 
    @supports_net_changes = 0, 
    @capture_instance = 'dbo_customers_v3';

-- Ops. we got error about limit of capture_instance
-- Try to check Customer capture_instance
SELECT * FROM cdc.change_tables
WHERE capture_instance LIKE 'dbo_customers%'

-- Disabled an old
EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name = N'customers',
    @capture_instance = N'dbo_customers';

-- Now we create new capture instance again
EXEC sys.sp_cdc_enable_table 
    @source_schema = 'dbo',
    @source_name = 'customers', 
    @role_name = NULL, 
    @supports_net_changes = 0, 
    @capture_instance = 'dbo_customers_v3';

-- Insert sample data
INSERT INTO customers (FirstName, LastName, PhoneNumber, [Address]) VALUES
('Lady', 'Gaga', '+66827769988', 'Phuket');
```

Visit **kafka-ui** (http://localhost:8080/) and look for:
- `debezium.sqlserver.SaleDB.dbo.customers` - customers table changes (with operation "c")
- Address is appear

---

## 🔄 Message Transformations

### Problem: Verbose Messages
Default Debezium messages include:
- Complex schema wrapper 
- Source metadata (binlog position, etc.)
- Potentially unwanted fields

### Solution: Single Message Transforms (SMT)

**File: `connectors/remove-source-connector.json`**

```json
{
    "name": "remove-source-connector",
    "config": {
        "connector.class": "io.debezium.connector.sqlserver.SqlServerConnector",
        "database.hostname": "mssql-server",
        "database.port": "1433",
        "database.user": "debezium_user",
        "database.password": "Debezium@123",
        "database.names": "SaleDB",
        "database.encrypt": "false",
        "topic.prefix": "debezium.sqlserver",
        "table.include.list": "dbo.products",
        "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
        "schema.history.internal.kafka.topic": "schema-changes.debezium.tms",
        "decimal.handling.mode": "double",

        "transforms": "RemoveSourceField",
        "transforms.RemoveSourceField.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
        "transforms.RemoveSourceField.exclude": "source",

        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
        "key.converter.schemas.enable": "false",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter.schemas.enable": "false"
    }
}
```

### Transform Configuration
```json
"transforms": "RemoveSourceField"
```
- **Purpose**: Names the transform chain
- **Multiple**: Can chain multiple transforms

```json
"transforms.RemoveSourceField.type": "org.apache.kafka.connect.transforms.ReplaceField$Value"
```
- **Purpose**: Specifies transform implementation
- **ReplaceField$Value**: Operates on message payload

```json
"transforms.RemoveSourceField.exclude": "source"
```
- **Purpose**: Fields to exclude from payload
- **Result**: Removes source metadata

### Converter Configuration
```json
"key.converter": "org.apache.kafka.connect.json.JsonConverter",
"key.converter.schemas.enable": "false"
```
- **Purpose**: How message keys are serialized
- **schemas.enable=false**: Raw JSON without schema wrapper

```json  
"value.converter": "org.apache.kafka.connect.json.JsonConverter",
"value.converter.schemas.enable": "false"
```
- **Purpose**: How message values are serialized
- **schemas.enable=false**: Clean JSON payload only

---

## 🔍 Connector Management

### Useful Management API

```bash
# Connector status
curl -s http://localhost:8083/connectors/first-connector/status

# Connector configuration
curl -s http://localhost:8083/connectors/first-connector/config

# Pause connector
curl -i -X PUT http://localhost:8083/connectors/first-connector/pause

# Resume connector  
curl -i -X PUT http://localhost:8083/connectors/first-connector/resume

# Restart connector
curl -i -X POST http://localhost:8083/connectors/first-connector/restart

# Delete connector
curl -i -X DELETE http://localhost:8083/connectors/first-connector
```

---