# PostgreSQL Partitioning Scripts

Set of scripts that may help to automize PostgreSQL partitioning routines. All of them generate SQL code so before using it, inspect them thoroughly first.

## partition-table-monthly.bash

Partitions an existing table into set of child tables for each month beginning with the oldest record and up to current month and the default one for rows that may violate checks in the future.

```bash
./partition-table-monthly.bash mydatabase orders created_at | psql
```

## create-monthly-partition.bash

Creates a partition for the previously partitioned table for upcoming month. Used to be executed via systemd timer preferably or a cron task.

```bash
./create-monthly-partition.bash orders created_at | psql
```
