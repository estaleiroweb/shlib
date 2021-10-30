#!/bin/bash

pr() {
	local c=$1
	local cont
	local bin
	local hex

	cont="000$c"
	bin=00000000$(echo "obase=2;$c" | bc)
	hex=00$(echo "obase=16;$c" | bc)
	#hex=000000$(printf "%x\n" $i)
	bin=${bin: -8}
	hex=${hex: -2}
	echo -n "${cont: -3}/${bin:0:4} ${bin:4:4}/$hex"
}
title(){
	echo -e "\e[1mDec/Bin4+Bin4/Hx Paint------------------------------- $1\e[0m"
}
barColor(){
	local txt='                                    '
	pr $1
	echo -e " \e[48;5;${1}m$txt\e[0m ${2}"
}
degrade() {
	for i in $(seq $1 $2 $3); do
		echo -n -e "\e[48;5;${i}m \e[0m"
	done
}
primaryColor() {
	local i
	title 'Color Name'
	for i in $(seq 0 15); do
		barColor $i ${arr[$i]}
	done
}
grayScaleColor() {
	local End=232
	local i
	title 'Percentage Black'
	i=0
	barColor $i "100% (${arr[$i]})"
	for i in $(seq $End 255); do
		p="  $((100 * (24 - (i - End)) / 25))"
		barColor $i "${p: -3}% (Gray)"
	done
	i=15
	barColor $i "  0% (${arr[$i]})"
}
degradeColor() {
	local cont=16
	local ini
	local End
	local sini
	local sEnd
	local txt
	local i
	title 'Ini-End End-Ini Ini-End End-Ini Ini-End End-Ini'
	while [ $cont -lt 48 ]; do
		pr $cont; echo -n ' '
		#degrade $cont 1 $((cont + 5))
		txt=''
		for i in {0..5}; do
			ini=$((cont + (i * 36)))
			End=$((cont + 5 + (i * 36)))
			sini="000$ini";sini=${sini: -3}
			sEnd="000$End";sEnd=${sEnd: -3}
			if [[ $((i % 2)) = 0 ]]; then
				degrade $ini 1 $End
				txt="$txt $sini-$sEnd"
			else
				degrade $End -1 $ini
				txt="$txt $sEnd-$sini"
			fi
		done
		echo "$txt"
		cont=$((cont + 6))
		#pr $End
	done
}

arr=(
	Black
	Red
	Green
	Yellow
	Blue
	Magenta
	Cyan
	GrayLigth
	Gray
	RedLigth
	GreenLigth
	YellowLigth
	BlueLigth
	MagentaLigth
	CyanLigth
	White
)

primaryColor; echo
grayScaleColor; echo
degradeColor; echo
echo -e "\e[1mUse:\e[0m"
echo "     Background-color: echo \"\\e[38;5;<Dec>m<text>\\e[0m\""
echo "     Foreground-color: echo \"\\e[48;5;<Dec>m<text>\\e[0m\""
