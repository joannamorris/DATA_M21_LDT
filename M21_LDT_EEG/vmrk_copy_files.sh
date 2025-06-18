#!/bin/bash

# Usage: ./copy_vmrk_files.sh [search_dir]
# If no argument is given, defaults to current directory

search_dir="${1:-.}"
target_dir="VMRK"

if [[ ! -d "$search_dir" ]]; then
    echo "Error: '$search_dir' is not a valid directory."
    exit 1
fi

mkdir -p "$target_dir"
echo "Searching for .vmrk files with S### or S#### in filename..."

# Find all .vmrk files, then grep for filenames with S followed by 3 or 4 digits
find "$search_dir" -type f -name "*.vmrk" | grep -E 'S[0-9]{3,4}.*\.vmrk$' | while read -r file; do
    echo "Copying: $file"
    cp "$file" "$target_dir"
done

echo "Done. Matching .vmrk files copied to '$target_dir'."