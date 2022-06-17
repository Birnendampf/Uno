#!/usr/bin/env bash
shopt -s extglob
cd ${0%/*}
# echo $0
# echo $PWD
debug() {
	printf "%b=\t%b\n" "SESSIONNAME" "${SESSIONNAME}" "NICKNAME" "${NICKNAME}" "PLAYERS=" "${PLAYERS[@]}" > log$$.log
}
# trap debug DEBUG
# String formatters
	# RGB tool allows you to enter three values on a range from 0 to 5 for red, green, and blue, which will be converted to an ANSI control sequence.
	# For more info, see here: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
	rgb() { printf "\033[1;38;5;$(( 16 + 36 * $1 + 6 * $2 + $3 ))m"; }

	red="$(rgb "5" "0" "0")"
	green="$(rgb "0" "3" "0")"
	blue="$(rgb "0" "0" "5")"
	yellow="$(rgb "5" "5" "0")"
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
	rm "${SESSIONNAME}.session" &> /dev/null
	tput cvvis
	printf "${reset}"
}
trap end 0
# clear() {
	# printf "\033[1J\033[H"
	# tput clear
# }
createCard() {
	nl="\033[B\033[5D"
	NUMBER=$1
	eval COLOR=\$$2
	case ${NUMBER} in 
		+4) printf "${blue}┏━${yellow}━━┓${nl}${blue}┃+ ${red}4┃${nl}${green}┗━━${red}━┛\033[2A${reset}";;
		p ) printf "${blue}┏━${yellow}━━┓${nl}${blue}┃ ⨁ ${red}┃${nl}${green}┗━━${red}━┛\033[2A${reset}";;
		r ) printf "${COLOR}┏━━━┓${nl}┃ ⇄ ┃${nl}┗━━━┛\033[2A${reset}";;
		s ) printf "${COLOR}┏━━━┓${nl}┃ ⊘ ┃${nl}┗━━━┛\033[2A${reset}";;
		* )	printf "${COLOR}┏━━━┓${nl}┃ ${NUMBER} ┃${nl}┗━━━┛\033[2A${reset}";;
	esac
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
	getNickname
	getSessionName
	echo "PLAYERS=(\"${NICKNAME}\")" > "${SESSIONNAME}.session"
}
joinGame() {
	print "Available games:"
	if [[ -z "$(ls *.session)" ]] &> /dev/null; then
		error "No games available"
		mainMenu
		return 1
	fi
	menu *.session
	SESSIONNAME="$(ls *.session | tail -n+${REPLY} | head -n1)"
	SESSIONNAME=${SESSIONNAME%.*}
	getNickname
	eval $(cat "${SESSIONNAME}.session")
	var="("
	PLAYERS[${#PLAYERS[@]}]="${NICKNAME}"
	for name in "${PLAYERS[@]}"; do
		var+="\"${name}\" "
	done
	var+=")"
	sed -E "s/PLAYERS=.*/PLAYERS=$var/" "${SESSIONNAME}.session" > tmp
	mv tmp "${SESSIONNAME}.session"

}
settings() {
	print "This does not exist yet :("
	mainMenu
	return 1
}
mainMenu() {
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
mainMenu

clear
print "${lblue}Players:\n" "${reset}╒════════════════════════════════╕"
READY=false
while true; do
	tput civis
	eval $(cat "${SESSIONNAME}.session")
	printf "\033[3;1H\033[J"
	i=0
	READYCOUNT=0
	for NAME in "${PLAYERS[@]}"; do 
		let i++
		if [[ $NAME = $NICKNAME && $READY = "true" && -z $(grep -o "#$i" "${SESSIONNAME}.session") ]]; then
			echo "#$i" >> "${SESSIONNAME}.session"
		fi
		if [[ -n $(grep -o "#$i" "${SESSIONNAME}.session") ]]; then
			print "${reset}│ " "${green}${normal}${NAME}" "\033[33G ${reset}│"
			let READYCOUNT++
		else
			print "${reset}│ " "${normal}${NAME}" "\033[33G ${reset}│"
		fi
	done
	print "${reset}╘════════════════════════════════╛\n"
	print "${reset}Game name: " "${green}${SESSIONNAME}"
	print "${lblue}${blink}Press ${reset}${blink}[space] ${lblue}${blink}to start"
	unset REPLY
	read -rst1 -n1
	[[ -n ${REPLY} ]] && READY=true
	[[ ${READYCOUNT} -eq ${#PLAYERS[@]} ]] && break
done
unset i
printf "\033[1F\033[0K"
printf "${blue}Game starting in  "
for (( i=3; i>0; i-- )); do
	printf "${bold}\033[D$i"
	sleep 1
done
print "\n${blue}INSERT ACTUAL GAME HERE"
