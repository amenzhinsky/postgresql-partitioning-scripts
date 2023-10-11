#!/bin/bash

set -e
set -u
set -o pipefail

if [[ $# -lt 3 ]]; then
	echo "usage: ${0} DATABASE TABLE COLUMN [INDEX...]

Generates SLQ for monthly partitioning of an existing table.
Do not forget it's required to create partitions manually in
advance to maintain the partitioning, otherwise all new records
will end up in the default partition reducing all the advantages.

environment variables:
    FROM   defines the starting table date to create partitions,
           format YYYY-MM-DD if missing it tries to get the oldest
           COLUMN value using psql (can be really slow).
           If it presents DATABASE argument can be empty.
" >&2
	exit 2
fi

database=$1
table=$2
table_new="${table_new}"
column=$3

shift
shift
shift

from=${FROM:-}
if [[ -z "${from}" ]]; then
	from=$(psql ${database} -qtAc "SELECT ${column}::date FROM ${table} ORDER BY ${column} LIMIT 1;")
	if [[ -z ${from} ]]; then
		echo "error: unable to determine from date" >&2
		exit 1
	fi
fi

echo "BEGIN;"
echo "CREATE TABLE ${table_new} (LIKE ${table} INCLUDING CONSTRAINTS) PARTITION BY RANGE(${column});"
echo "CREATE TABLE ${table}_default PARTITION OF ${table_new} DEFAULT;"
echo

c=$(date -d ${from} +%Y-%m-01)
l=$(date -d "+1 month" +%Y-%m-01)
while [[ ${c} != ${l} ]]; do
	y=$(date -d ${c} +%Y)
	m=$(date -d ${c} +%m)
	n=$(date -d "$(date -d "${c} + 1 month")" +%Y-%m)
	c=$(date -I -d "${c} + 1 month")

	echo "CREATE TABLE ${table}_${y}_${m} PARTITION OF ${table_new}"
	echo "  FOR VALUES FROM ('${y}-${m}-01 00:00:00') TO ('${n}-01 00:00:00');"
	echo
done

echo "INSERT INTO ${table_new} (SELECT * FROM ${table});"
echo "ALTER TABLE ${table_new} ADD CONSTRAINT ${table_new}_pkey PRIMARY KEY (id, ${column});"
echo

for index in $@; do
	echo "CREATE INDEX ${table_new}_${index//,/_}_idx ON ${table_new} (${index})"
done

echo
echo "LOCK ${table} IN ACCESS EXCLUSIVE MODE;"
echo "INSERT INTO ${table_new} (SELECT * FROM ${table} WHERE id > (SELECT MAX(id) FROM ${table_new}));"
echo
echo "CREATE SEQUENCE ${table_new}_id_seq OWNED BY ${table_new}.id;"
echo "ALTER TABLE ${table_new} ALTER COLUMN id SET DEFAULT nextval('${table_new}_id_seq');"
echo "SELECT setval('${table_new}_id_seq', MAX(id)) FROM ${table_new};"
echo
echo "ALTER TABLE ${table} RENAME TO ${table}_old;"
echo "ALTER TABLE ${table_new} RENAME TO ${table};";
echo "COMMIT;"
echo
echo "/* Do not forget to 'DROP ${table}_old;' once everything is done. */"
