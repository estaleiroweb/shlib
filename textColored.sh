#!/bin/bash
:<<coment
echo -e '\033[EST;COR1;COR2m TEXTO'; tput sgr0 
EST=Estilo
COR1=cor da letra
COR2=cor do fundo
É obrigatório o uso de um desses parametros
NORMAL="\033[0m"
CINZA="\033[1;30m"
VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
AZUL="\033[1;34m"
ROXO="\033[1;35m"
CIANO="\033[1;36m"
BRANCO="\033[1;37m"
CINZA="\033[1;38m"

echo "Tamanho: ${#A_EST[@]}"
echo "Chaves : ${!A_EST[@]}"
echo "Values : ${A_EST[@]}"

#for ELEMENT in `seq ${#A_EST[@]}`; do
#for ELEMENT in {0..9}; do
coment

declare -a A_EST
declare -a A_CORL
declare -a A_CORF

# Estilos:
A_EST[0]='Nenhum'
A_EST[1]='Negrito'
A_EST[4]='Sublinhado'
A_EST[5]='Piscante  '
A_EST[7]='Reverso'
A_EST[8]='Oculto'

# Cores de texto 3n e fundo 4n:
A_COR=(
	[0]='Preto'
	[1]='Vermelho'
	[2]='Verde'
	[3]='Amarelo'
	[4]='Azul'
	[5]='Magenta (Rosa)'
	[6]='Ciano (Azul Ciano)'
	[7]='Branco'
)

LARG_E=10
LARG_C=20
TL="Cor da Letra"
TF="Cor do Fundo"
TL="$TL`printf "%${LARG_C}s" ""`"
TF="$TF`printf "%${LARG_C}s" ""`"
echo -n "| ${TL:0:$LARG_C} | ${TF:0:$LARG_C} |"
for ELEMENT in ${!A_EST[@]}; do
	P="${A_EST[$ELEMENT]}`printf "%${LARG_E}s" ""`"
	echo -n " ${P:0:$LARG_E} |"
done
echo
for CORF in ${!A_COR[@]}; do
	for CORL in ${!A_COR[@]}; do
		CL="[3$CORL] ${A_COR[$CORL]}`printf "%${LARG_C}s" ""`"
		CF="[4$CORF] ${A_COR[$CORF]}`printf "%${LARG_C}s" ""`"
		echo -n "| ${CL:0:$LARG_C} | ${CF:0:$LARG_C} |"
		for EST in ${!A_EST[@]}; do 
			C="$EST;3$CORL;4$CORF"
			CC="$C`printf "%${LARG_E}s" ""`"
			#echo -n -e "\033[${C}m $CC \033[0m|"
			echo -n -e "\033[${C}m ${CC:0:$LARG_E} \033[0m|"
		done
		echo
	done
done
tput sgr0
