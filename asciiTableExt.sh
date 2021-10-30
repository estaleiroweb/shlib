#!/bin/bash
. $(dirname "$0")/strFuc.inc.sh

MAX_COL=10
COL=0

CONT=32
MAX_CONT=183962
while ((CONT<=MAX_CONT)); do
	((CONT++))
	((COL++))
	str_pad "$CONT:" 9 ' ' R 
	chr $CONT
	echo -n '	'
	if (( COL >= MAX_COL )); then
		COL=0
		echo
	fi
done
echo
