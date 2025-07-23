#!/bin/sh
# Tester script for assignment 1 and assignment 2

set -e
set -u

NUMFILES=10
WRITESTR="AELD_IS_FUN"
WRITEDIR=/tmp/aeld-data

if [ -f /home/conf/username.txt ]; then
  username=$(cat /home/conf/username.txt)
else
  echo "Error: /home/conf/username.txt not found!"
  exit 1
fi

# Optional input args
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

echo "Creating $NUMFILES files using writer in $WRITEDIR..."

for i in $(seq 1 $NUMFILES); do
  ./writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

echo "Running finder.sh..."
FINDRESULTFILE="/tmp/finder-result.txt"
./finder.sh "$WRITEDIR" "$WRITESTR" "$FINDRESULTFILE"
OUTPUTSTRING=$(cat "$FINDRESULTFILE")

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

