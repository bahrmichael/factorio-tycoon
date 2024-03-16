#!/bin/bash

function error() {
    echo "ERROR:" "$@" >&2
}

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

# MacOS compatibility:
#   'stat -f "%N"' instead
#   'sort -z' not supported, can't pipe 'find -print0'
# WARN: as var is double-quoted below, there should be no whitespaces!
STAT_OPTS="-c%n"
case "$(uname -s)" in
    Darwin*)
        STAT_OPTS="-f%N"
        ;;
    Linux*|*)
        ;;
esac

# Populate the array with directory names excluding the base language
while IFS= read -r line; do
    target_langs+=("$line")
done < <(find "$base_dir" -mindepth 1 -maxdepth 1 -type d -not -name "$base_lang" -print0 | xargs -0 stat "$STAT_OPTS" | LC_ALL=C sort)

# Iterate over all files in the base language directory
tmp_file=
let ERRORS=0
for source_file in "$base_dir/$base_lang"/*.cfg; do
    filename=$(basename "$source_file")

    # Create temp file only once and reuse
    [[ -z $tmp_file ]] && tmp_file=$(mktemp -t "compare-locales.XXXXXXXX")
    # Overwrite temp file with extracted keys
    extract_keys "$source_file" >"$tmp_file" || {
        let ERRORS+=1000
        error "Unable to extract from: $source_file"
        continue
    }

    # Iterate over target languages
    for lang in "${target_langs[@]}"; do
        # Define the file path for the target language
        target_file="$lang/$filename"

        # Check if the target file exists
        [[ ! -f $target_file ]] && {
            error "File does not exist: $target_file"
            let ERRORS+=1
            continue
        }

        #echo "Comparing $source_file with $target_file"
        diff -U0 -N --label "$source_file" "$tmp_file" --label "$target_file" <(extract_keys "$target_file") || {
            let ERRORS+=1
        }
    done
done

# Notify of any errors
[[ $ERRORS -gt 0 ]] && error "Total errors: $ERRORS"


# Finally, cleanup and exit
rm "$tmp_file"
exit $ERRORS
