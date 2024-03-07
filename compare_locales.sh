#!/bin/bash

# Extracts groups, keys and/or any other necessary information
function extract_keys() {
    grep --no-messages -E -o '^(\[[^\s]*\]$|[^=]+=)' "$1"
}


# Base directory containing the locales
base_dir="locale"
# Base language
base_lang="en"

# Initialize an empty array for target languages
target_langs=()

# Populate the array with directory names excluding the base language
while IFS= read -r line; do
    target_langs+=("$line")
done < <(find "$base_dir" -mindepth 1 -maxdepth 1 -type d -not -name "$base_lang" -printf "%P\n" | LC_ALL=C sort)

# Iterate over all files in the base language directory
for file in "$base_dir/$base_lang"/*.cfg; do
    filename=$(basename "$file")

    # Iterate over target languages
    for lang in "${target_langs[@]}"; do
        # Define the file path for the target language
        source_file="$base_dir/$base_lang/$filename"
        target_file="$base_dir/$lang/$filename"

        # Check if the target file exists
        if [[ -f "$target_file" ]]; then
            echo "Comparing $source_file with $target_file"
            # Use diff to compare files, you can also use cmp or other tools
            # diff "$file" "$target_file" > /dev/null
            diff -q <(extract_keys "$source_file") <(extract_keys "$target_file")
            if [[ $? -eq 0 ]]; then
                # echo "No differences found."
                echo ""
            else
                echo "Differences found!"
                diff <(extract_keys "$source_file") <(extract_keys "$target_file")
                exit 1
            fi
        else
            echo "File $lang/$filename does not exist."
            exit 1
        fi
    done
done
