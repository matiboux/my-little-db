#!/bin/sh

DB_ARGS="--user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST --port=$DB_PORT"

# Wait for the database to be ready
attempt_n=0
echo "Waiting for the database to be ready..."
until [ "$attempt_n" -ge 5 ]; do

	# Check if the database is ready
	mariadb-admin ping $DB_ARGS --silent && break

	attempt_n=$((attempt_n + 1))
	echo "Database is unavailable, sleeping 5 seconds..."
	sleep 5

done

if [ "$attempt_n" -ge 5 ]; then
	echo "Failed to initialize the database, exiting"
	exit 1
fi

# Create the database
echo "Creating the database..."
mariadb $DB_ARGS -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

# Import all the SQL files in the data directory
for sql_file in ./data/*.sql; do
	echo "Importing $sql_file..."
	mariadb $DB_ARGS --database="$DB_NAME" < "$sql_file"
done

# Import data from subdirectories in separate databases
for dir in ./data/*/; do

	# Use the directory name as the database name
	dir_name=$(basename "$dir")

	# Create the database
	echo "Creating database $dir_name..."
	mariadb $DB_ARGS -e "CREATE DATABASE IF NOT EXISTS \`$dir_name\`;"

	# Import all the SQL files in the directory
	for sql_file in "$dir"*.sql; do
		echo "Importing $sql_file..."
		mariadb $DB_ARGS --database="$dir_name" < "$sql_file"
	done

done

echo "Database data import complete!"
