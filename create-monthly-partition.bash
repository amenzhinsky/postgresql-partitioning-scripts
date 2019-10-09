#!/bin/bash

set -e
set -u
set -o pipefail

if [[ $# != 2 ]]; then
	echo "usage: ${0} TABLE COLUMN

Creates a partition for the named table assuming it has
the default partition with '_default' suffix and it may
contain rows that would  violate the created partition
constraints.

environment variables:
    DATE   overrides current date, so a new partition
           will be created for the following month,
           format YYYY-MM-DD.
" >&2
	exit 2
fi

table=$1
column=$2

date=${DATE:-$(date -I)}
from=$(date -d "${date} + 1 month" +%Y-%m-01)
upto=$(date -d "${date} + 2 month" +%Y-%m-01)
name=$(date -d ${from} +%Y_%m)

echo "BEGIN;"
echo "  ALTER TABLE ${table} DETACH PARTITION ${table}_default;"
echo "  CREATE TABLE IF NOT EXISTS ${table}_${name} PARTITION OF ${table}"
echo "    FOR VALUES FROM ('${from} 00:00:00') TO ('${upto} 00:00:00');"
echo "  INSERT INTO ${table}_${name} ("
echo "    SELECT * FROM ${table}_default"
echo "    WHERE ${column} >= '${from} 00:00:00'"
echo "      AND ${column} < '${upto} 00:00:00'"
echo "  );"
echo "  DELETE FROM ${table}_default "
echo "    WHERE ${column} >= '${from} 00:00:00'"
echo "      AND ${column} < '${upto} 00:00:00';"
echo "  ALTER TABLE ${table} ATTACH PARTITION ${table}_default DEFAULT;"
echo "COMMIT;"
