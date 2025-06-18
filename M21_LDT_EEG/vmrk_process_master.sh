#!/bin/bash

# Usage: ./process_vmrk_master.sh /path/to/vmrk/files

input_dir="${1:-.}"
output_dir="${input_dir}/processed_vmrk"
master_output="${output_dir}/combined_S220_S221.csv"

mkdir -p "$output_dir"
> "$master_output"

# Add header row
echo "Marker,ResponseCode,TimeMS,Size,ChanNum,RT,word_trig,cond_trig,SubjID" >> "$master_output"

for file in "$input_dir"/*.vmrk; do
    base_name=$(basename "$file")

    # Extract subject ID like "S245" from filename
    
    if [[ "$base_name" =~ S[0-9]{3,4} ]]; then
        subj_id="${BASH_REMATCH[0]}"
    else
        echo "Warning: could not extract subject ID from $base_name"
        continue
    fi

    output_file="$output_dir/$base_name"

    # Convert CRLF to LF if needed
    dos2unix "$file" 2>/dev/null

awk -v sid="$subj_id" '
BEGIN {
    FS="[,=]"
    in_markers = 0
}

/^\[Marker Infos\]/ { in_markers = 1; next }

in_markers && /^Mk[0-9]+=Stimulus/ {
    marker = $1
    condition = $3
    time = $4
    size = $5
    ch = $6

    if (count >= 1 &&(condition ~ /^S?220$/ || condition ~ /^S?221$/)) {
        rt = time - time_buf[1]
        prev1 = code_buf[1]
        prev2 = code_buf[0]

        out = marker "," condition "," time "," size "," ch "," rt "," prev1 "," prev2 "," sid
        print out >> "'"$master_output"'"
    }

    # Shift buffers for time and condition code
    time_buf[0] = time_buf[1]
    time_buf[1] = time
    code_buf[0] = code_buf[1]
    code_buf[1] = condition

    count++
}
' "$file"


    echo "Processed: $base_name"
done

echo "Combined S220/S221 lines saved to: $master_output"	