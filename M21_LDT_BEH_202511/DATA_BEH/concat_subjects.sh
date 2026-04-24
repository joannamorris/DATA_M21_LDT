#!/bin/bash

# Directory containing your subject CSV files
DATA_DIR="/Users/jmorris/Git/DATA_M21_LDT/M21_LDT_BEH/rawdata_csv_files/PC_raw_rt_data/B"
OUTPUT_FILE="${DATA_DIR}/all_subjects_combined.csv"

# Remove output file if it already exists
rm -f "$OUTPUT_FILE"

# Initialize a flag to track the first file
first_file=true

# Loop through all subject CSVs in numerical order
for file in "$DATA_DIR"/subject-*.csv; do
    if [ "$first_file" = true ]; then
        # Write the header + data for the first file
        cat "$file" > "$OUTPUT_FILE"
        first_file=false
    else
        # Append all subsequent files without their headers
        tail -n +2 "$file" >> "$OUTPUT_FILE"
    fi
done

echo "✅ Concatenation complete."
echo "Output saved to: $OUTPUT_FILE"