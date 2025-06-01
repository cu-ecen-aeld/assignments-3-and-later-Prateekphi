#!/bin/sh
# Tester script for assignment 1 and assignment 2
# Author: Siddhant Jajoo (Modified for your setup)

set -e
set -u

NUMFILES=10
WRITESTR="AELD_IS_FUN"
WRITEDIR=/tmp/aeld-data
username=$(cat ../conf/username.txt)  # Adjusted to go up dir to conf

# Handle optional input args
if [ $# -ge 1 ]; then
  NUMFILES=$1
fi

if [ $# -ge 2 ]; then
  WRITESTR=$2
fi

if [ $# -ge 3 ]; then
  WRITEDIR="/tmp/aeld-data/$3"
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Cleaning up and creating new write directory: $WRITEDIR"
rm -rf "$WRITEDIR"
mkdir -p "$WRITEDIR"

echo "Creating $NUMFILES files using writer.sh in $WRITEDIR..."

for i in $(seq 1 $NUMFILES); do
  ./writer.sh "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

echo "Running finder.sh..."
OUTPUTSTRING=$(./finder.sh "$WRITEDIR" "$WRITESTR")

# Cleanup
rm -rf "$WRITEDIR"

echo "Checking result..."
echo "$OUTPUTSTRING" | grep "$MATCHSTR" > /dev/null

if [ $? -eq 0 ]; then
  echo "success"
  exit 0
else
  echo "failed: expected '${MATCHSTR}' but got:"
  echo "$OUTPUTSTRING"
  exit 1
fi

