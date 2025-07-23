#!/bin/sh

# Check if exactly three arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Error: Three arguments required."
    echo "Usage: $0 <directory> <search_string> <output_file>"
    exit 1
fi

filesdir="$1"
searchstr="$2"
outfile="$3"

# Check if the directory exists
if [ ! -d "$filesdir" ]; then
    echo "Error: '$filesdir' is not a valid directory."
    exit 1
fi

# Count number of files (recursively)
num_files=$(find "$filesdir" -type f | wc -l)

# Count matching lines
num_matches=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)

# Output result to the output file
echo "The number of files are $num_files and the number of matching lines are $num_matches" > "$outfile"

# Exit successfully
exit 0

