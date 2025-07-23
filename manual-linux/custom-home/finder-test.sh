#!/bin/sh
# finder-test.sh
# Author: <Your Name>

WRITE_STR="Assignment 1 writer test string"
WRITE_FILE="/tmp/aeld-data/sample.txt"
NUMFILES=10
WRITEDIR="/tmp/aeld-data"

echo "Cleaning up and creating new write directory: ${WRITEDIR}"
rm -rf ${WRITEDIR}
mkdir -p ${WRITEDIR}

echo "Creating ${NUMFILES} files using writer.sh in ${WRITEDIR}..."

for i in $(seq 1 $NUMFILES); do
    file_path="${WRITEDIR}/file${i}.txt"
    /home/writer "$file_path" "$WRITE_STR"
done

echo "Running finder.sh to match string '${WRITE_STR}'..."
MATCHCOUNT=$(/home/finder.sh ${WRITEDIR} "$WRITE_STR" | grep -c "$WRITE_STR")

echo "MATCHCOUNT: ${MATCHCOUNT}"

if [ "$MATCHCOUNT" -eq "$NUMFILES" ]; then
    echo "TEST PASSED"
else
    echo "TEST FAILED: Expected $NUMFILES matches, got $MATCHCOUNT"
fi
