# PostgreSQL Partitioning Scripts

Set of scripts that may help to automize PostgreSQL partitioning routines. All of them generate SQL code so inspect it thoroughly first before executing.

## partition-table-monthly.bash

Partitions an existing table into a set of child tables for each month beginning with the oldest record (can be overwritten with `FROM` environment variable) and up to the current month, it also creates the default partition table for rows that may violate partition checks in the future.

It requires some free space at least of the same size as the partitioned table for copying the existing data to new tables.

The script ensures the lowest down-time by copying data without locking the source table assuming there will be no updates/deletes but inserts. Then it acquire an exclusive lock, copy remaining rows and makes table names switch renaming the old one to `table_name_old` for manual removal.

```bash
./partition-table-monthly.bash mydatabase orders created_at | psql
```

## create-monthly-partition.bash

Creates a partition for the previously partitioned table for the upcoming month.

```bash
./create-monthly-partition.bash orders created_at | psql
```
