#!/usr/bin/env bash
shopt -s extglob
cd ${0%/*}
exec 2>log.log
declare -a CARDS
debug() {
	printf "%b=\t%b\n" "SESSIONNAME" "${SESSIONNAME}" "NICKNAME" "${NICKNAME}" "PLAYERS=" "${PLAYERS[@]}" > log$$.log
}
# trap debug DEBUG
# String formatters
	# RGB tool allows you to enter three values on a range from 0 to 5 for red, green, and blue, which will be converted to an ANSI control sequence.
	# For more info, see here: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
	rgb() { printf "\033[1;38;5;$(( 16 + 36 * $1 + 6 * $2 + $3 ))m"; }

	red="$(rgb "5" "0" "0")"
	r="$(rgb "5" "0" "0")"
	green="$(rgb "0" "3" "0")"
	g="$(rgb "0" "3" "0")"
	blue="$(rgb "0" "0" "5")"
	b="$(rgb "0" "0" "5")"
	yellow="$(rgb "5" "5" "0")"
	y="$(rgb "5" "5" "0")"
	lblue="$(rgb "4" "3" "5")"
	bold="\033[1m"
	faint="\033[2m"
	italic="\033[3m"
	underline="\033[4m"
	blink="\033[5m"
	normal="\033[22m"
	reset="\033[0m"

# Print functions
	print() {
		printf "${bold}%b${reset}" "$@"
		printf "\n"
	}
	# Prints input in red and bold. every argument will be a new line
	error() {
		printf "${red}%b${reset}\n" "$@"
	}

# UI functions
	prompt() {
		printf "${lblue}%b${reset} " "$1"
		read -r $2
	}
	getkey() {
		printf "${green}%b${reset} " "$1"
		read -rsn1
		REPLY=$(tr [:upper:] '[:lower:]' <<< ${REPLY})
		eval "$2"=${REPLY} 2> /dev/null
		printf "\n"
	}
	yn() {
		printf "${green}%b${reset} [y/n]" "$1"
		read -rsn1
		while [[ ${REPLY} != "y" && ${REPLY} != "n" ]]; do
			read -rsn1
		done
		printf "\n"
	}
	menu() {
		[[ -z $@ ]] && exit 1
		local i=0
		for arg in "$@"; do
			printf "$((++i)))  ${green}%b\n${reset}" "$arg"
			# printf "${arg}"
		done
		REPLY=0
		while [[ -z ${REPLY} || -n "${REPLY//[1-9]/}" || ${REPLY} -gt $i ]] 2> /dev/null; do
			read -r
			# move up and delete text
			printf "\033[1F\033[K"
		done
		# color selected option blue
		printf "\033[$(($#+1-${REPLY}))F"
		printf "${blue}${REPLY})  %b${reset}" "$(eval echo "\${$REPLY}")"
		printf "\033[$(($#+1-${REPLY}))E"
	}
#
end() {
	tput reset
	source "${SESSIONNAME}.session"
	unset PLAYERS[${PLAYERID}]
	if [[ -z ${PLAYERS[@]} ]]; then
		rm "${SESSIONNAME}.session"
	else
		var="(${PLAYERS[@]@Q})"
		sed -e "s/PLAYERS=.*/PLAYERS=$var/" -e "/#\\\\${PLAYERID}/d" "${SESSIONNAME}.session" > tmp
		mv tmp "${SESSIONNAME}.session"
	fi
}
trap end 0
# clear() {
	# printf "\033[1J\033[H"
	# tput clear
# }
createCard() {
	nl="\033[B\033[5D"
	eval local COLOR=\$${1:0:1}
	local NUMBER=${1:1}
	case ${NUMBER} in 
		+4) printf "${blue}┏━${yellow}━━┓${nl}${blue}┃${reset}${bold}+ 4${red}┃${nl}${green}┗━━${red}━┛\033[2A${reset}";;
		+2) printf "${COLOR}┏━━━┓${nl}┃+ 2┃${nl}┗━━━┛\033[2A${reset}";;
		p ) printf "${blue}┏━${yellow}━━┓${nl}${blue}┃${reset}${bold} ⨁ ${red}┃${nl}${green}┗━━${red}━┛\033[2A${reset}";;
		r ) printf "${COLOR}┏━━━┓${nl}┃ ⇄ ┃${nl}┗━━━┛\033[2A${reset}";;
		s ) printf "${COLOR}┏━━━┓${nl}┃ ⊘ ┃${nl}┗━━━┛\033[2A${reset}";;
		* )	printf "${COLOR}┏━━━┓${nl}┃ ${NUMBER} ┃${nl}┗━━━┛\033[2A${reset}";;
	esac
}
randomCard() {
	local OUT
	RND=$(( 1 + $SRANDOM % 27 ))
	COL=$(( 1 + $SRANDOM % 4 ))
	case ${COL} in
		1) OUT=r;;
		2) OUT=g;;
		3) OUT=b;;
		4) OUT=y;;
	esac
	case ${RND} in
		1 | 2 ) OUT+="1";;
		3 | 4 ) OUT+="2";;
		5 | 6 ) OUT+="3";;
		7 | 8 ) OUT+="4";;
		9 | 10) OUT+="5";;
		11| 12) OUT+="6";;
		13| 14) OUT+="7";;
		15| 16) OUT+="8";;
		17| 18) OUT+="9";;
		19| 20) OUT+="s";;
		21| 22) OUT+="r";;
		23| 24) OUT+="+2";;
		25		) OUT+="0";;
		26		) OUT+="p";;
		27		) OUT+="+4";;
	esac
	printf "${OUT}"
}
draw() {
	for (( i=0; i<$1; i++)); do
	CARDS[${#CARDS[@]}]="$(randomCard)"
	done
}
getNickname() {
	prompt "Please choose a nickname:" NICKNAME
	while [[ -z "${NICKNAME}" || "${NICKNAME}" =~ "\t\\" || ${#NICKNAME} -gt 30  ]]; do
		error "Invalid name. A maximum of 30 caracters and no \"\\\" and tabstops are allowed"
		prompt "Please choose a nickname:" NICKNAME
	done
	export NICKNAME
}
getSessionName() {
	prompt "Please choose a game name:" SESSIONNAME
	while [[ -z "${SESSIONNAME}" || "${SESSIONNAME}" =~ [^([:alnum:][:blank:]_.?!)] || -e "${SESSIONNAME}.session" ]]; do
		[[ -e "${SESSIONNAME}.session" ]] && error "Game already exists" || error "Invalid name"
		prompt "Please choose a game name" SESSIONNAME
	done
	export SESSIONNAME
}
createGame() {
	HOST=true
	getNickname
	getSessionName
	echo "PLAYERS=(\"${NICKNAME}\")" > "${SESSIONNAME}.session"
}
joinGame() {
	HOST=false
	if [[ -z "$(ls *.session)" ]] &> /dev/null; then
		mainMenu
		return 1
	fi
	print "Available games:"
	menu *.session
	SESSIONNAME="$(ls *.session | tail -n+${REPLY} | head -n1)"
	SESSIONNAME=${SESSIONNAME%.*}
	getNickname
	source "${SESSIONNAME}.session"

	PLAYERS+=("${NICKNAME}")
	var="(${PLAYERS[@]@Q})"
	sed "s/PLAYERS=.*/PLAYERS=$var/" "${SESSIONNAME}.session" > tmp
	mv tmp "${SESSIONNAME}.session"

}
settings() {
	print "This does not exist yet :("
	mainMenu
	return 1
}
mainMenu() {
	clear
	print "${red}╔${blue}═${yellow}═${red}═${green}═${blue}═${yellow}═${red}═${green}═${blue}═${yellow}═${red}═${green}═${blue}═${yellow}═${red}╗"
	print "${green}║" " TERMINAL UNO " "${yellow}║"
	print "${blue}╚${yellow}═${red}══${blue}═${yellow}═${red}═${green}═${blue}═${yellow}═${red}═${green}═${blue}═${yellow}═${red}═${green}╝"
	menu "join game" "create game" "settings" "quit"
	case ${REPLY} in
		1) joinGame;;
		2) createGame;;
		3) settings;;
		4) exit;;
	esac
}

if true; then # REMOVE

mainMenu

clear
print "${lblue}Players:\n" "${reset}╒════════════════════════════════╕"
READY=false
tput civis
while true; do
	source "${SESSIONNAME}.session"
	printf "\033[3;1H\033[J"
	i=0
	READYCOUNT=0
	for NAME in "${PLAYERS[@]}"; do 
		if [[ "${NAME}" = "${NICKNAME}" ]]; then
			if [[ "${READY}" = "true" && -z $(grep -o "#\\\\$i" "${SESSIONNAME}.session") ]]; then
				echo "#\\$i" >> "${SESSIONNAME}.session"
			elif [[ "${EXIT}" = true ]]; then 
			PLAYERID=$i
			exit
			fi
		fi
		if [[ -n $(grep -o "#\\\\$i" "${SESSIONNAME}.session") ]]; then
			print "${reset}│ " "${green}${normal}${NAME}" "\033[33G ${reset}│"
			let READYCOUNT++
		else
			print "${reset}│ " "${normal}${NAME}" "\033[33G ${reset}│"
		fi
		let i++
	done
	[[ ${READYCOUNT} -eq ${#PLAYERS[@]} ]] && break
	print "${reset}╘════════════════════════════════╛\n"
	print "${reset}Game name: " "${green}${SESSIONNAME}"
	print "${lblue}${blink}Press ${reset}${blink}[space] ${lblue}${blink}to start or ${reset}${blink}[q] to quit"
	unset REPLY
	read -rst1 -n1
	[[ "${REPLY}" = " " ]] && READY=true
	[[ "${REPLY}" = "q" ]] && EXIT=true
done
clear
unset i
printf "\033[1F\033[0K"
printf "${blue}Game starting in  "
for (( i=3; i>0; i-- )); do
	printf "\033[GGame starting in $i"
	sleep 1
done
for (( i=5; i>=0; i-- )); do
	printf "\033[G$(rgb "0" "0" "$i")Game starting in 0"
	sleep 0.1
done
fi # REMOVE
print
printf "\nCurrent Card:\033[A"
createCard "$(randomCard)"
print "\n\n"