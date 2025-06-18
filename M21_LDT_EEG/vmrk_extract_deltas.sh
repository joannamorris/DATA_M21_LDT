#!/bin/bash

# Usage: ./extract_vmrk_deltas.sh /path/to/vmrk/files

input_dir="$1"
output_dir="${input_dir}/processed_vmrk"

mkdir -p "$output_dir"

for file in "$input_dir"/*.vmrk; do
    base_name=$(basename "$file")
    output_file="$output_dir/$base_name"

    awk -F',' '
    function rstrip(s) {
        sub(/[[:space:]]+$/, "", s)
        return s
    }
    /^Mk1=New Segment/ { in_markers = 1; count = 1; next }  # Start after Mk1
    in_markers && /^Mk[0-9]+=/ {
        count++
        current = $3
        if (count == 2) {
            prev = current
            diff = 0
        } else {
            diff = current - prev
            prev = current
        }
        clean_line = rstrip($0)
        print clean_line "," diff
        if (count == 901) exit
    }
    ' "$file" > "$output_file"

    echo "Processed: $base_name → $output_file"
done