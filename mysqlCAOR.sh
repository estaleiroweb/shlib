#!/bin/bash

# ./mysqlCAOR.sh [db [tb]] #It does CAOR of the specific database or table
# ./mysqlCAOR.sh           #It does CAOR of the tables oldest checked of $DAYS
DAYS=7                     # Config it if you want

my() {
	mysql -e "$1"
}
caor_item(){
	echo -n "   - $1="
	local RET=$(my "$1 TABLE \`${2}\`.\`$3\`;" | sed 1d | cut -d$'\t' -f 4)
	echo "$RET"
	[ "$RET" = "OK" ] && return 0 || return 1
}
caor(){
	echo "${1}.$2"
	caor_item CHECK "$1" "$2" || caor_item REPAIR "$1" "$2"
	#caor_item ANALYZE "$1" "$2" &&
	caor_item OPTIMIZE "$1" "$2"
}
main(){
	local W; local SQL; local QUANT; local CONT=0;
	if [ "$1" ]; then
		W="AND t.TABLE_SCHEMA='$1'"
		[ "$2" ] && W="$W 
			AND t.TABLE_NAME='$2'"
		W="$W 
			ORDER BY 
				t.TABLE_SCHEMA, 
				t.TABLE_NAME"
	else
		W="AND (
				t.CHECK_TIME IS NULL OR 
				t.CHECK_TIME<=NOW() - INTERVAL $DAYS DAY
			)"
		W="$W 
			ORDER BY 
				t.CHECK_TIME,
				t.TABLE_SCHEMA, 
				t.TABLE_NAME"
		W="$W 
			LIMIT 50"
	fi

	SQL="
		SELECT t.TABLE_SCHEMA, t.TABLE_NAME
		FROM information_schema.TABLES t
		WHERE t.TABLE_TYPE='BASE TABLE'
		AND t.ENGINE='MyISAM'
		$W
	"
	#echo "$SQL"
	QUANT=$(my "SELECT COUNT(1) FROM ($SQL) t" | sed 1d)

	IFS=$'\n' && for T in $(my "$SQL" | sed 1d); do 
		IFS=$'\t' && read -r -a LN <<< "$T"
		CONT=$((CONT + 1))

		echo -n "$CONT/$QUANT [$(date '+%F %T.%N')]: "
		caor "${LN[0]}" "${LN[1]}"
	done
	echo "END [$(date '+%F %T.%N')]"
}

main $@
