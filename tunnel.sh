#!/bin/bash

# tunnel -t SPCP001@10.216.224.4 -f 10.216.224.6
list_ports(){
	netstat -tulpn | awk '{print $4}' | sed -r '1d;s/^.*://'
}
get_new_port() {
	local CONT
	local NEW_PORT=$(shuf -i $RANGE_PORT -n 1)

	[ "$1" ] && CONT=$(($1 + 1)) || CONT=1
	if [ "$(list_ports | grep "$NEW_PORT")" ]; then
		(( $CONT > 10 )) && exit
		get_new_port
	else 
		echo $NEW_PORT
	fi 
}
build_cmd(){
	local I=''

	[ "$ACCESS_IP" ] && [ ! "$ACCESS_IP" = '127.0.0.1' ] && I="$ACCESS_IP:"
	if [ "$SSH_OPT" = 'L' ];then
		echo "$SSH_CMD$SSH_OPT $I$ACCESS_PORT:$FINAL_IP_HOST:$FINAL_PORT '$TUNNEL_HOST' > /dev/null 2>&1 &"
	else
		echo "$SSH_CMD$SSH_OPT $I$ACCESS_PORT '$TUNNEL_HOST' > /dev/null 2>&1 &"
	fi
}
list_tunnels(){
	local PS=$(ps -fC 'ssh' | grep "$TUNNEL_HOST")
	local P=''

	if [ "$ACCESS_IP" ] && [ ! "$ACCESS_IP" = '127.0.0.1' ];then
		[ "$ACCESS_PORT" ] && P="$ACCESS_PORT" || P=''
		PS=$(echo "$PS" | grep "$SSH_CMD$SSH_OPT $ACCESS_IP$P")
	else
		[ "$ACCESS_PORT" ] && P="$ACCESS_PORT" || P='[0-9]+'
		PS=$(echo "$PS" | egrep "$SSH_CMD$SSH_OPT (127\\.0\\.0\\.1:)?$P")
	fi

	[ "$SSH_OPT" = 'L' ] && PS=$(echo "$PS" | grep "$ACCESS_PORT:$FINAL_IP_HOST:$FINAL_PORT")

	echo "$PS"
}
check_tunnel(){
	list_tunnels | head -1 | awk '{print $11}' | sed -r 's/^((([0-9a-z_-]+)\.)+[0-9a-z_-]+:)?([0-9]+).*?/\4/i'
}
do_tunnel(){
	local P=$(check_tunnel)
	
	if [ "$P" ];then
		ACCESS_PORT=$P
	else 
		#local H=$(echo "$TUNNEL_HOST" | sed -r 's/^.*@//')
		[ ! "$ACCESS_PORT" ] && ACCESS_PORT=$(get_new_port)
		[ "$(list_ports | grep $ACCESS_PORT)" ] && return
		local CMD=$(build_cmd)
		#echo "$CMD"
		eval $CMD
	fi
	[ ! "$ACCESS_IP" ] && ACCESS_IP='127.0.0.1'
	echo "$SSH_OPT $ACCESS_IP:$ACCESS_PORT"
	eval "ex_$SSH_OPT"
}
rm_tunnel(){
	local ACCESS_PORT=($(list_tunnels | awk '{print $2}'))
	if [ "$ACCESS_PORT" ];then
		echo "kill process ${ACCESS_PORT[@]}"
		kill -9 ${ACCESS_PORT[@]}
	fi
}
show_conn(){
	local PS=$(lsof -i -P -n)
	echo "$PS" | head -1
	echo "$PS" | grep ESTABLISHED
}
show_tunnels(){
	local PS=$(ps -fC ssh)
	echo "$PS" | head -1
	echo "$PS" | egrep "$SSH_CMD[LDR]"
}
ex_L(){
	echo "ssh $ACCESS_IP -p $ACCESS_PORT"
}
ex_D(){
	local F='<FINAL_IP_HOST>'
	[ "$FINAL_IP_HOST" ] && F="$FINAL_IP_HOST"
	echo "ssh -o \"ProxyCommand=ncat --proxy-type socks4 --proxy $ACCESS_IP:$ACCESS_PORT %h %p\" $F -p $FINAL_PORT"
}
add_fn_after(){
	[ "$FUNCTION_AFTER" ] && FUNCTION_AFTER="$FUNCTION_AFTER;"
	FUNCTION_AFTER="${FUNCTION_AFTER}show_$1"
}
get_parameteres(){
	local END=''
	while [ "$1" ];do
		#echo "$1"
		case "$1" in
			-k) FUNCTION_TUNNEL='rm_tunnel';;
			-t) shift; TUNNEL_HOST="$1";;
			-f) shift; FINAL_IP_HOST="$1";;
			-p) shift; FINAL_PORT="$1";;
			-A) shift; ACCESS_IP=$(echo "$1" | egrep '^127\.');;
			-P) shift; ACCESS_PORT="$1";;
			-D) SSH_OPT='D';;
			-L) SSH_OPT='L';;
			--help)  show_help;;
			--show) shift; END=1; eval "show_$1";;
			--report) shift; add_fn_after "$1";;
		esac
		shift
	done
	[ "$END" ] && exit
	[ ! "$TUNNEL_HOST" ] && show_help
	[ "$SSH_OPT" = 'L' ] && [ ! "$FINAL_IP_HOST" ] && show_help
}
show_help(){
	[ ! "$ACCESS_IP" ] && ACCESS_IP='127.0.0.1'
	[ ! "$ACCESS_PORT" ] && ACCESS_PORT=$(get_new_port)

	echo "Sintaxe:"
	echo "    $0 -t <TUNNEL_HOST> <[-L] <-f FINAL_IP_HOST> | -D [-f FINAL_IP_HOST]>"
	echo "         [-A ACCESS_IP] [-p FINAL_PORT] [-P ACCESS_PORT] [-k] [--help]"
	echo "         [--show|--report conn] [--show|--report tunnels] "
	echo "Cria tunel SSH se não existir e retorna ip e porta utilizada"
	echo "    -L                *Veja em: Tipos de Tunels"
	echo "    -D                *Veja em: Tipos de Tunels"
	echo "    -k                Remove o tunel(s). a ausência deste, cria o tunel ou retorna a porta"
	echo "    -t TUNNEL_HOST    [user@]<ip/host> host que será a ponte para chegar ao host final"
	echo "    -f FINAL_IP_HOST  <ip/host> host que quer atingir Requerido para -L"
	echo "    -p FINAL_PORT     default '${FINAL_PORT}'. Porta para qual porta deseja apontar"
	echo "    -A ACCESS_IP      default '${ACCESS_IP}'. IP para qual porta deseja fixar o tunel para acessá-lo"
	echo "    -P ACCESS_PORT    default auto. Porta para qual porta deseja fixar o tunel para acessá-lo"
	echo "    --show            Mostra apenas status atual: conn, tunnels"
	echo "    --report          Mostra status após executar (idem show)"
	echo "    --help            Mostra esta ajuda"
	echo
	echo "    Após criar o tunel, o app retornará IP:Port, Ex:"
	echo "        $ACCESS_IP:$ACCESS_PORT"
	echo
	echo " Tipos de Tunels: (mapenando PORTA e Rede loopback 127/8)"
	echo "    Tunel -L: Tunel Local"
	echo "        Formação do Tunel: ${SSH_CMD}L [ACCESS_IP:]ACCESS_PORT:FINAL_IP_HOST:FINAL_PORT [USER@]TUNNEL_HOST"
	echo "        Sintaxe de Uso:"
	echo "           ssh [ACCESS_USER@]ACCESS_IP -p ACCESS_PORT"
	echo "        Exemplo de Uso:"
	echo "           $(ex_L)"
	echo
	echo "    Tunel -D: Tunel Dinâmico SOCKS4/5"
	echo "        Formação do Tunel: ${SSH_CMD}D [ACCESS_IP:]ACCESS_PORT [USER@]TUNNEL_HOST"
	echo "        Sintaxe de Uso:"
	echo "           ssh -o \"ProxyCommand=ncat --proxy-type socks4 --proxy ACCESS_IP:ACCESS_PORT %h %p\" [USER@]IP_HOST [-p PORT]"
	echo "        Exemplo de Uso:"
	echo "           $(ex_D)"
	echo

	exit
}
start_vars(){
	SSH_CMD='ssh -N -'
	SSH_OPT='L'
	RANGE_PORT='8090-9090'
	TUNNEL_HOST=''
	ACCESS_IP=''
	ACCESS_PORT=''
	FINAL_IP_HOST=''
	FINAL_PORT=22
	FUNCTION_TUNNEL='do_tunnel'
	FUNCTION_AFTER=''
}

start_vars; get_parameteres $@
#show_conn;show_tunnels;exit
#check_tunnel;exit
#list_tunnels;exit
#get_new_port;exit
$FUNCTION_TUNNEL
[ "$FUNCTION_AFTER" ] && eval "$FUNCTION_AFTER"

#### Outros tuneis ####
	#ssh -N -L SOURCE-PORT:127.0.0.1:DESTINATION-PORT -i KEYFILE bitnami@SERVER-IP
	#ssh -N -R 123:127.0.0.1:456 10.0.3.12
	#ssh -p $SSH_PORT -q -N -R $REMOTE_HOST:$REMOTE_HTTP_PORT:localhost:80 $USER_NAME@$REMOTE_HOST

#### Outros comandos ####
	#lsof -i -P -n | grep ESTABLISHED
	#lsof -i -P -n | grep LISTEN
	#netstat -tulpn | grep LISTEN
	#ss -tulpn | grep LISTEN
	#lsof -i:22 ## see a specific port such as 22 ##
	#nmap -sTU -O IP-address-Here
	#ss -tulw
	#ps aux | grep PID
	#nc -l 127.0.0.1:456
	#nc -z localhost 6000 || echo "no tunnel open"
	#autossh -M 2323 -c arcfour -f -N -L 8088:localhost:80 host2
	#lsof -i tcp@localhost:6000 > /dev/null

#### Relação de confiança ####
	#ssh-keygen -t rsa -f ~/.ssh/id_rsa #Cria chave
	#cat ~/.ssh/id_rsa.pub | ssh -p 8493 user@IP 'mkdir -p ~/.ssh/;cat - >> ~/.ssh/authorized_keys'  #Copia chave

#### Referências ####
	#https://www.vivaolinux.com.br/dica/Construindo-uma-relacao-de-confianca-SSH-entre-os-servidores
	#https://www.cyberciti.biz/faq/unix-linux-check-if-port-is-in-use-command/
