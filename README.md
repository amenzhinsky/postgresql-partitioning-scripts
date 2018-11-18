# PostgreSQL Partitioning Scripts

Set of scripts that may help to automize PostgreSQL partitioning routines. All of them generate SQL code so before using it, inspect them thoroughly first.

## partition-table-monthly.bash

Partitions an existing table into set of child tables for each month beginning with the oldest record and up to current month, it also creates the default partition for rows that may violate checks in the future.

It requires free space at least of the same size as the partitioned table for copying the data to new tables.

The script ensures the lowest down-time by copying data without locking the source table assuming there will be no updates/deletes but inserts. Then it acquire an exclusive lock, copy remaining rows and makes table names switch renaming the old one to `table_name_old` for manual removal.

```bash
./partition-table-monthly.bash mydatabase orders created_at | psql
```

## create-monthly-partition.bash

Creates a partition for the previously partitioned table for upcoming month. Used to be executed via systemd timer preferably or a cron task.

```bash
./create-monthly-partition.bash orders created_at | psql
```
