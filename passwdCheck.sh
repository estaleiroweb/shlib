#!/bin/bash

chkPasswd(){
	local USR="$1"
	local PASSWD="$2"
	local QUITE="$3"
	local ORIGPASS=`grep -w "$USR" /etc/shadow | cut -d: -f2`
	local ALGO=`echo $ORIGPASS | cut -d'$' -f2`
	local SALT=`echo $ORIGPASS | cut -d'$' -f3`
	local CKPASSWD=$(perl -le "print crypt('$PASSWD','\$$ALGO\$$SALT\$')")
	local OUT
	
	if [ "$QUITE" != '-q' ]; then
		echo "ALGO    : $ALGO"
		echo "SALT    : $SALT"
		echo "OrigPass: $ORIGPASS"
		echo "CkPasswd: $CKPASSWD"
		[ "$CKPASSWD" = "$ORIGPASS" ] && echo "Password MATCH" ||  echo "Password NOT Match"
	fi
	
	[ "$CKPASSWD" = "$ORIGPASS" ] && return 0 || return 1
}
chk4_only(){
	local USR="$1"
	local PASSWD="$2"
	local ORIGPASS=`grep -w "$USR" /etc/shadow | cut -d: -f2`
	local ALGO=`echo $ORIGPASS | cut -d'$' -f2`
	local SALT=`echo $ORIGPASS | cut -d'$' -f3`

	echo "ALGO${ALGO}"
	echo "SALT=${SALT}"
	echo "ORIGPASS=${ORIGPASS}"

	openssl passwd -crypt -salt "${SALT}" "${PASSWD}"
}

if [ ! "$(cat /etc/shadow 2> /dev/null)" ]; then
	echo 'Premition denied. Use:'
	echo "sudo $0 [user]"
	exit 1
fi
[ "$1" ] && USR=$1 || USR="$USER"
if [ ! "$(grep -w "$USR" /etc/shadow)" ]; then
	echo 'Non-user'
	exit 1
fi

echo -n "Password of $USR: "; read -s PASSWD; echo
chkPasswd "$USR" "$PASSWD" "$2"
exit $?
