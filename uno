#!/usr/bin/env bash
shopt -s extglob
shopt -s checkwinsize
cd ${0%/*}
exec 2>log.log
mkfifo "$$.fifo"
exec 7<> "$$.fifo"
REPLY=$1
NICKNAME=$2
SESSIONNAME=$3
# set -x
SEDPWD=$(which sed)
sed() {
  if [[ $(uname) == "Darwin" ]]; then
    $SEDPWD -i '' "$@"
  else
    $SEDPWD -i "$@"
  fi
}
clear() {
  tput clear
  printf "\033[2J\033[3J\033[H"
}
end() {
  # clear
  printf "\033]0;\a"
  rm "$$.fifo"
  tput cnorm
  source "${SESSIONNAME}.session"
  unset READY["${NICKNAME}"]
  if [[ -z ${READY[@]} ]]; then
    rm "${SESSIONNAME}.session"
  else
    unset CARDCOUNT["${NICKNAME}"]
    for ((i = 0; i < ${#PLAYERS[@]}; i++ )); do
      [[ "${PLAYERS[$i]}" == "${NICKNAME}" ]] && unset PLAYERS[$i]
    done
    rdy="${READY[@]@A}"
    pls="PLAYERS=(${PLAYERS[@]@Q})"
    cct="${CARDCOUNT[@]@A}"
    sed -e "1s/.*/${rdy:11}/" -e "2s/.*/${pls}/" -e "3s/.*/${cct:11}/" "${SESSIONNAME}.session"
    echo | tee *.fifo > /dev/null
  fi
}
trap end 0
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
  lblue="$(rgb "3" "2" "5")"
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
declare -A READY
declare -A CARDCOUNT
getNickname() {
  if [[ -z "${NICKNAME}" ]] ; then
    prompt "Please choose a nickname:" NICKNAME
  fi
  while [[ -z "${NICKNAME}" || "${NICKNAME}" =~ [^([:alnum:]_.?! )] || ${#NICKNAME} -gt 30  ]]; do
    error "Invalid name. maximum is a total 30 of letters, numbers, spaces and '?_.!'"
    prompt "Please choose a nickname:" NICKNAME
  done
  export NICKNAME
  printf "\033]0;${NICKNAME}\a"
}
getSessionName() {
  if [[ -z "${SESSIONNAME}" ]] ; then
    prompt "Please choose a game name:" SESSIONNAME
  fi
  while [[ -z "${SESSIONNAME}" || "${SESSIONNAME}" =~ [^([:alnum:][:blank:]_.?!)] || -e "${SESSIONNAME}.session" ]]; do
    if [[ -e "${SESSIONNAME}.session" ]]; then
      error "Game already exists"
      unset SESSIONNAME
    else
      error "Invalid name"
    fi
    prompt "Please choose a game name:" SESSIONNAME
  done
  export SESSIONNAME
}
createGame() {
  getNickname
  getSessionName
  READY[${NICKNAME}]=false
  echo ${READY[@]@A} | cut -c 11- > "${SESSIONNAME}.session"
}
joinGame() {
  # export HOST=false
  if [[ -z "$(ls *.session)" ]] &> /dev/null; then
    mainMenu
    return 1
  fi
  print "Available games:"
  if [[ -z "${SESSIONNAME}" ]] ; then
    menu *.session
    SESSIONNAME="$(ls *.session | tail -n+${REPLY} | head -n1)"
    SESSIONNAME=${SESSIONNAME%.*}
  fi
  getNickname
  source "${SESSIONNAME}.session"
  IFS="|"
  while [[ "${IFS}${!READY[*]}${IFS}" =~ "${IFS}${NICKNAME}${IFS}" ]]; do
    error "Nickname taken!"
    getNickname
  done
  unset IFS
  source "${SESSIONNAME}.session"
  READY[${NICKNAME}]=false
  local var="${READY[@]@A}"
  sed "1s/.*/${var:11}/" "${SESSIONNAME}.session"
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
  if [[ -z "${REPLY}" ]]; then
    menu "join game" "create game" "settings" "quit"
  fi
  case ${REPLY} in
    1) joinGame;;
    2) createGame;;
    3) settings;;
    4) exit;;
  esac
}
mainGUI() {
  if [[ "${DIRECTION}" == "down" ]]; then
    local ARROW="⬇"
  else
    local ARROW="⬆"
  fi
  clear
  source "${SESSIONNAME}.session"
  # print "\033[1F\033[K" "HOST: $HOST"
  printf "${reset}\nCurrent Card: \033[A"
  createCard "$CURRENT"
  print "\n\n"
  printf "${ARROW} ═════════════════════════════════════════════════════\n"
  for NAME in "${PLAYERS[@]}"; do
    if [[ "${NAME}" == "${TURN}" ]]; then
      local var="${red}⮕ "
    else
      local var="  "
    fi
    if [[ "${NAME}" == "${NICKNAME}" ]]; then
      print "$var" "${reset}[" "${green}You" "${reset}] " "have " "${lblue}${CARDCOUNT[$NAME]} " "cards"
    else
      print "$var" "${reset}[" "${lblue}${NAME}" "${reset}] " "has " "${lblue}${CARDCOUNT[$NAME]} " "cards"
    fi
  done
  print ""
  printf "═══════════════════════════════════════════════════════\n"
  for CARD in "${CARDS[@]}"; do
    createCard "${CARD}"
  done
  print "\n\n"
}
createCard() {
  nl="\033[B\033[5D"
  eval local COLOR=\$${1:0:1}
  local NUMBER=${1:1}
  case ${NUMBER} in
    +4) printf "${blue}┏━${yellow}━━┓${nl}${blue}┃${reset}${bold}+ 4${red}┃${nl}${green}┗━━${red}━┛\033[2A${reset}";;
    4c) printf "${COLOR}┏━━━┓${nl}┃+ 4┃${nl}┗━━━┛\033[2A${reset}";;
    +2) printf "${COLOR}┏━━━┓${nl}┃+ 2┃${nl}┗━━━┛\033[2A${reset}";;
    p ) printf "${blue}┏━${yellow}━━┓${nl}${blue}┃${reset}${bold} ⨁ ${red}┃${nl}${green}┗━━${red}━┛\033[2A${reset}";;
    pc) printf "${COLOR}┏━━━┓${nl}┃ ⨁ ┃${nl}┗━━━┛\033[2A${reset}";;
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
    CARDS+=("$(randomCard)")
  done
}
remove() {
  unset CARDS[$1]
  CARDS=("${CARDS[@]}")
}
validate() {
  # $1 = current
  # $2 = possible candidate
  local COLOR_1=${1:0:1}
  local COLOR_2=${2:0:1}
  local NUMBER_1=${1:1}
  local NUMBER_2=${2:1}
  if [[ "${NUMBER_1}" == "+2" && -n "${META}" ]]; then
    [[ "${NUMBER_2}" == "+2" ]] && return 0
    return 1
  fi
  [[ "${NUMBER_2}" == "+4" ]] && return 0
  if [[ "${NUMBER_1}" == "+4" && -n "${META}" ]]; then
    [[ "${NUMBER_2}" == "+4" ]] && return 0
    return 1
  fi
  if [[ -z "${META}" ]]; then
    [[ "${NUMBER_2}" == "${NUMBER_1}" || "${COLOR_2}" == "${COLOR_1}" || "${NUMBER_1}" == "p" ]] && return 0
  else
    [[ "${NUMBER_2}" == "${NUMBER_1}" ]] && return 0
    return 1
  fi
}
cardSelector() {
  source "${SESSIONNAME}.session"
  local spaces="  "
  VALID=(0)
  for ((i = 1; i <= ${#CARDS[@]}; i++)); do
    if validate "${CURRENT}" "${CARDS[$((i - 1))]}"; then
      printf " [${i}]${spaces:${#i}}"
      VALID+=($i)
    else
      printf "     "
    fi
  done
  echo
  tput sc
  tput cup $(($(stty size | grep -o "[0-9]* ")-1))
  printf "${bold}%b${reset}" "${lblue}please choose a card or enter " "'0' " "${lblue}to draw one"
  tput rc
  unset SELECTED
  while [[ -n "${SELECTED//[0-9]/}" || -z ${SELECTED} || ! " ${VALID[*]} " =~ " ${SELECTED} " ]] 2> /dev/null; do
    read SELECTED
    printf "\033[1F\033[K"
  done
  export SELECTED
}
applyCard() {
  if [[ "${SELECTED}" -eq 0  ]]; then
    if [[ "${META}" -gt 0 ]]; then
      draw "${META}"
      META=""
      return 0
    else
      draw 1
      if validate "${CURRENT}" "${CARDS[-1]}"; then
        mainGUI
        yn "place card?"
        if [[ "${REPLY}" == "y" ]]; then
          SELECTED="${#CARDS[@]}"
        else
          return 0
        fi
      else
        return 0
      fi
    fi
  fi

  printf  "%b" "\033[1F" "\033[$((SELECTED * 5 - 3))G" "${lblue}[$SELECTED]${reset}"
  let SELECTED--
  CURRENT="${CARDS[$SELECTED]}"
  remove "${SELECTED}"
  REPLY=a
  case "${CURRENT:1}" in
    +4)
      var="${CURRENT@A}"
      sed "4s/.*/${var}/" "${SESSIONNAME}.session"
      mainGUI
      echo | tee *.fifo > /dev/null
      let META+=4
      while [[ $REPLY =~ [^(rgby)] ]]; do
        getkey "choose a color [${r}r/${g}g/${b}b/${y}y]"
      done
      CURRENT="${REPLY}4c";;
    +2) let META+=2;;
    p )
      var="${CURRENT@A}"
      sed "4s/.*/${var}/" "${SESSIONNAME}.session"
      mainGUI
      echo | tee *.fifo > /dev/null
      while [[ $REPLY =~ [^(rgby)] ]]; do
        getkey "choose a color [${r}r/${g}g/${b}b/${y}y]"
      done
      CURRENT="${REPLY}pc";;
    r )
      if [[ "${DIRECTION}" == "⬇" ]]; then
        DIRECTION="up"
      else 
        DIRECTION="down"
      fi;;
    s ) META="skip";;
  esac
}
advanceTurn() {
  local i=0
  source "${SESSIONNAME}.session"
  for NAME in "${PLAYERS[@]}"; do
    if [[ "${NAME}" == "${TURN}" ]]; then
      if [[ "${DIRECTION}" == "down" ]]; then
        if [[ $((++i)) -lt ${#PLAYERS[@]} ]]; then
          TURN="${PLAYERS[i]}"
        else
          TURN="${PLAYERS[0]}"
        fi
      else
        TURN="${PLAYERS[$((--i))]}"
      fi
      break
    fi
    let i++
  done
  var="${TURN[@]@A}"
  sed "5s/.*/${var}/" "${SESSIONNAME}.session"
  sleep 0.1
  echo | tee *.fifo > /dev/null
  # tput bel
}

#####################################
# .session file:                    #
# 1  READY=(["gamer 2"]="true"...)  #
# 2  PLAYERS=([0]="gamer 2"...)     #
# 3  CARDCOUNT=(["gamer 2"]="7"...) #
# 4  CURRENT='rr'                   #
# 5  TURN='gamer 1'                 #
# 6  DIRECTION='⬇'                 #
# 7  META='false'                   #
#                                   #
#####################################
mainMenu
clear
print "${lblue}Players:\n" "${reset}╒════════════════════════════════╕"
tput civis
source "${SESSIONNAME}.session"

# HUB LOOP
while true; do
  printf "\033[3;1H\033[J"
  i=0
  READYCOUNT=0

  for NAME in "${!READY[@]}"; do
    if [[ $i -eq 0 && "${NAME}" == "${NICKNAME}" ]]; then
      export HOST=true
      printf "\033]0;${NICKNAME} [HOST]\a"
    elif [[ $i -eq 0 ]]; then
      printf "\033]0;${NICKNAME}\a"
      export HOST=false
    fi
    if ${READY[${NAME}]}; then
      print "${reset}│ " "${green}${normal}${NAME}" "\033[33G ${reset}│"
      let READYCOUNT++
    else
      print "${reset}│ " "${normal}${NAME}" "\033[33G ${reset}│"
    fi
    let i++
  done
  [[ ${READYCOUNT} -eq ${#READY[@]} ]] && break

  print "${reset}╘════════════════════════════════╛\n"
  print "${reset}Game name: " "${green}${SESSIONNAME}"
  print "${lblue}${blink}Press ${reset}${blink}[space] ${lblue}${blink}to start or ${reset}${blink}[q] to quit"

  unset REPLY
  read -rst0.5 -n1
  source "${SESSIONNAME}.session"
  if [[ "${REPLY}" = " " ]] && ! ${READY[${NICKNAME}]}; then
    READY[${NICKNAME}]=true
    var="${READY[@]@A}"
    sed "1s/.*/${var:11}/" "${SESSIONNAME}.session"
  fi
  [[ "${REPLY}" = "q" ]] && clear && exit
done
clear
printf "${green}Starting game..."

# HOST INIT
if $HOST; then
  for NAME in "${!READY[@]}"; do
    PLAYERS+=("$NAME")
  done
  source "${SESSIONNAME}.session"
  TURN="${PLAYERS[$((SRANDOM % ${#PLAYERS[@]}))]}"

  echo "${READY[@]@A}" | cut -c 12- > "${SESSIONNAME}.session"
  echo "${PLAYERS[@]@A}" | cut -c 12- >> "${SESSIONNAME}.session"
  echo "# CARDCOUNT" >> "${SESSIONNAME}.session"
  echo "CURRENT=$(randomCard)" >> "${SESSIONNAME}.session"
  echo "${TURN@A}" >> "${SESSIONNAME}.session"
  echo "DIRECTION=up" >> "${SESSIONNAME}.session"
  echo "META=''" >> "${SESSIONNAME}.session"
  sleep 0.5
  echo | tee *.fifo > /dev/null
else
  exec 7<&-
  read < "$$.fifo"
  exec 7<> "$$.fifo"
fi
draw 7
source "${SESSIONNAME}.session"
for NAME in "${PLAYERS[@]}"; do
  if [[ "${NAME}" == "${NICKNAME}" ]]; then
    source "${SESSIONNAME}.session"
    CARDCOUNT[${NICKNAME}]=${#CARDS[@]}
    var="${CARDCOUNT[@]@A}"
    sed "3s/.*/${var:11}/" "${SESSIONNAME}.session"
  fi
  sleep 0.1
done
while true; do
  mainGUI
  if [[ "${TURN}" == "${NICKNAME}" ]]; then
    if [[ "${META}" != "skip" ]]; then
      cardSelector
      applyCard
    else
      META=""
      error "\nYou have been skipped"
      sleep 0.5
    fi
    CARDCOUNT[${NICKNAME}]=${#CARDS[@]}
    var1="${CARDCOUNT[@]@A}"
    var2="${CURRENT@A}"
    var3="${DIRECTION@A}"
    var4="${META@A}"
    echo $var4 >&2
    sed -e "3s/.*/${var1:11}/" -e "4s/.*/${var2}/" -e "5s/.*/${var3}/" -e "7s/.*/${var4}/" "${SESSIONNAME}.session"
    sleep 0.1
    advanceTurn
  else
    printf "\033[Gwaiting for ${lblue}${TURN}${reset}...\033[8m"
    exec 7<&-
    read < "$$.fifo"
    exec 7<> "$$.fifo"
  fi
done