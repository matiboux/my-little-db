#!/bin/sh

set -e

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

# List root SQL files
root_sql_files=$(find ./data -maxdepth 1 -type f -name '*.sql' | sort)

if [ -n "$root_sql_files" ]; then

	# Create the database if it does not exist
	if ! PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
		echo "Creating database '$DB_NAME'..."
		PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c "CREATE DATABASE \"$DB_NAME\";"
	fi

	# Import root SQL files in the database
	for sql_file in $root_sql_files; do
		echo "Importing '$sql_file'..."
		PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -d "$DB_NAME" -f "$sql_file"
	done

fi

# List subdirectories for other databases to import
root_dirs=$(find ./data -mindepth 1 -maxdepth 1 -type d | sort)

if [ -n "$root_dirs" ]; then

	echo "$root_dirs" | while IFS= read -r dir; do

		# List SQL files in the subdirectory
		dir_sql_files=$(find "$dir" -maxdepth 1 -type f -name '*.sql' | sort)

		if [ -n "$dir_sql_files" ]; then

			# Create the database, from the slugified directory name, if it does not exist
			dir_name=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')
			if ! PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -lqt | cut -d \| -f 1 | grep -qw "$dir_name"; then
				echo "Creating database '$dir_name'..."
				PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c "CREATE DATABASE \"$dir_name\";"
			fi

			# Import all the SQL files in the directory
			echo $dir_sql_files | while IFS= read -r sql_file; do
				echo "Importing '$sql_file'..."
				if head -c 5 "$sql_file" | grep -q "PGDMP"; then
					# Use pg_restore for PostgreSQL dump files

					# Search for users to create in the PostgreSQL dump file
					users=$(grep -oP --binary-files=text "GRANT ALL ON DATABASE .+ TO \K[^;]+" "$sql_file" | sort -u)
					if [ -n "$users" ]; then
						for user in $users; do
							# Create the user if it does not exist
							if ! PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c "\du" | cut -d \| -f 1 | grep -qw "$user"; then
								echo "Creating user '$user'..."
								PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -c "CREATE USER \"$user\";"
							fi
						done
					fi

					# Load the dump file into the database
					PGPASSWORD=$DB_PASSWORD pg_restore $DB_ARGS -d "$dir_name" --no-owner --clean --if-exists "$sql_file"

				else
					# Use psql for regular SQL files

					# Load the SQL file into the database
					PGPASSWORD=$DB_PASSWORD psql $DB_ARGS -d "$dir_name" -f "$sql_file"

				fi
			done

		fi

	done

fi

echo "Database data import complete!"
