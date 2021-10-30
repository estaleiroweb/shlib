# sintaxe: chr <code[0-183962]>
chr() {
	local CH
	while (( $# != 0 )); do
		CH="$1";shift
		(( $CH <= 122 )) && printf \\$(printf '%03o' $CH) || echo -n $(perl -CS -le 'print chr shift' $CH)
		# echo -ne "$a \\u2581"
	done
}

# sintaxe: ord <char>
ord() {
	printf '%d' "'$1"
}

# sintaxe: str_repeat <string> <length>
str_repeat(){
	local STRING=$1
	local LENGTH=$2
	[ ! "$STRING" ] && STRING=' '
	[ ! "$LENGTH" ] && LENGTH=1
	printf -- "$STRING%.0s" $(seq 1 $LENGTH)
}

# sintaxe: str_pad <string> <length> <text_pad> <direction[R:rigth,L:left,C:center]>
str_pad(){ # string length stringPad direction (RLC)
	local STRING=$1
	local LENGTH=$2
	local STRPAD=$3
	local DIRECT=$4
	[ ! "$LENGTH" ] && LENGTH=${#STRING}
	local NUMSPC=$(($LENGTH - ${#STRING} - ${#STRPAD}))
	local OUT=''
	local PAD
	
	if (( $LENGTH > ${#STRING} )); then
		case "$DIRECT" in
			[cC]):
				NUMSPC=$((NUMSPC/2))
				PAD="$(str_repeat "$STRPAD" $NUMSPC)"
				OUT="$PAD$STRING$PAD$STRPAD"
				;;
			[lL]):
				PAD="$(str_repeat "$STRPAD" $NUMSPC)"
				OUT="$STRING$PAD"
				;;
			*):
				PAD="$(str_repeat "$STRPAD" $NUMSPC)"
				OUT="$PAD$STRING"
				;;
		esac
	else
		OUT="$STRING"
	fi
	echo -n "${OUT:0:$LENGTH}"
}
