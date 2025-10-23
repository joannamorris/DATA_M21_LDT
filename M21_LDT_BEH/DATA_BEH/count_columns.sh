#!/bin/bash

# Output file
output_file="column_counts_B.txt"

# Clear or create the output file
> "$output_file"

# Loop over all CSV files in the current directory
for file in *.csv; do
    if [ -f "$file" ]; then
        # Count the number of columns (fields) in the first line
        num_columns=$(head -n 1 "$file" | awk -F',' '{print NF}')
        
        # Write filename and column count to output file
        echo "$file: $num_columns" >> "$output_file"
    fi
done

echo "Column counts written to $output_file"