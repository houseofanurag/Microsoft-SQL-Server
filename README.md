# SQL Server Database Utility Scripts

![SQL Server](https://img.shields.io/badge/Microsoft_SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)

A collection of practical SQL Server scripts for database administration, performance tuning, and schema documentation.

## 📋 Scripts Overview

| Script File | Description |
|-------------|-------------|
| **dQCreateIndexes.sql** | Generates CREATE INDEX statements for missing indexes reported by SQL Server |
| **dQCreateMissingIndexes.sql** | Creates indexes identified in the missing indexes DMVs |
| **dQDropUniqueConstraints.sql** | Scripts DROP statements for unique constraints in a database |
| **dQGetTableDDL.sql** | Generates complete table DDL (without constraints) |
| **dQGetTableDDLWithConstraints.sql** | Generates complete table DDL including constraints |
| **dQToAddFK.sql** | Scripts missing foreign keys based on naming conventions |
| **dQToDropFK.sql** | Generates DROP statements for foreign keys |
| **getAllTables.sql** | Lists all tables in a database with schema information |
| **getIndexDetails.sql** | Provides detailed index information including fragmentation |
| **getSPDDL.sql** | Scripts stored procedure definitions |
| **getViewDDL.sql** | Generates CREATE VIEW statements |
| **identifyConstraints.sql** | Identifies and documents all constraints in a database |
| **missingFKAndTarget.sql** | Finds potential missing foreign keys and their target tables |
| **rowCountByTables.sql** | Reports row counts for all tables |
| **sqlServerStatistics.sql** | Basic statistics collection script |
| **sqlServerAdvancedStatistics.sql** | Comprehensive performance statistics collection |

## 🚀 Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/houseofanurag/Microsoft-SQL-Server.git
