#!/bin/sh

DB_ARGS="-U $DB_USER -h $DB_HOST -p $DB_PORT"

# Wait for the database to be ready
attempt_n=0
echo "Waiting for the database to be ready..."
until [ "$attempt_n" -ge 5 ]; do

	# Check if the database is ready
	if PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c '\q' 2>/dev/null; then
		break
	fi

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
PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c "CREATE DATABASE \"$DB_NAME\";"

# Import all the SQL files in the data directory
for sql_file in ./data/*.sql; do
	echo "Importing $sql_file..."
	PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -d "$DB_NAME" -f "$sql_file"
done

# Import data from subdirectories in separate databases
for dir in ./data/*/; do

	# Use the directory name as the database name
	dir_name=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')

	# Create the database
	echo "Creating database $dir_name..."
	PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c "CREATE DATABASE \"$dir_name\";"

	# Import all the SQL files in the directory
	for sql_file in "$dir"*.sql; do
		echo "Importing $sql_file..."
		PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -d "$dir_name" -f "$sql_file"
	done

done

echo "Database data import complete!"
