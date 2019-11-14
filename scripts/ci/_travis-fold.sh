# private variable to track folds within this script
# This script has been copied from: https://github.com/NationalBankBelgium/stark/blob/master/scripts/ci/_travis-fold.sh
travisFoldStack=()

GITHUB_ACTIONS=${GITHUB_ACTIONS:-}

function travisFoldStart() {
  local foldName="${0#./}  ${1}"
  # get current time as nanoseconds since the beginning of the epoch
  foldStartTime=$(date +%s%N)
  # convert all non alphanum chars except for "-" and "." to "--"
  local sanitizedFoldName=${foldName//[^[:alnum:]\-\.]/--}
  # strip trailing "-"
  sanitizedFoldName=${sanitizedFoldName%-}
  # push the foldName onto the stack
  travisFoldStack+=("${sanitizedFoldName}|${foldStartTime}")

  echo ""
  if [[ ${GITHUB_ACTIONS} == true ]]; then
    echo "github_fold:start:${sanitizedFoldName}"
    echo "github_time:start:${sanitizedFoldName}"
  fi
  local enterArrow="===>  ${foldName}  ==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>==>"
  # keep all messages consistently wide 80chars regardless of the foldName
  echo ${enterArrow:0:100}
  if [[ ${2:-} != "no-xtrace" ]]; then
    # turn on verbose mode so that we have better visibility into what's going on
    # http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_02_03.html#table_02_01
    set -x
  fi
}

function travisFoldEnd() {
  set +x
  local foldName="${0#./}  ${1}"
  # convert all non alphanum chars except for "-" and "." to "--"
  local sanitizedFoldName=${foldName//[^[:alnum:]\-\.]/--}
  # strip trailing "-"
  sanitizedFoldName=${sanitizedFoldName%-}

  # consult and update travisFoldStack
  local lastFoldIndex=$(expr ${#travisFoldStack[@]} - 1)
  local lastFoldString=${travisFoldStack[$lastFoldIndex]}
  # split the string by | and then turn that into an array
  local lastFoldArray=(${lastFoldString//\|/ })
  local lastSanitizedFoldName=${lastFoldArray[0]}

  if [[ ${GITHUB_ACTIONS} == true ]]; then
    local lastFoldStartTime=${lastFoldArray[1]}
    local foldFinishTime=$(date +%s%N)
    local foldDuration=$(expr ${foldFinishTime} - ${lastFoldStartTime})

    # write into build-perf.log file
    local logIndent=$(expr ${lastFoldIndex} \* 2)
    printf "%6ss%${logIndent}s: %s\n" $(expr ${foldDuration} / 1000000000) " " "${foldName}" >> ${LOGS_FILE}
  fi

  # pop
  travisFoldStack=(${travisFoldStack[@]:0:lastFoldIndex})

  # check for misalignment
  if [[ ${lastSanitizedFoldName} != ${sanitizedFoldName} ]]; then
    echo "GitHub fold mis-alignment detected! travisFoldEnd expected sanitized fold name '${lastSanitizedFoldName}', but received '${sanitizedFoldName}' (after sanitization)"
    exit 1
  fi

  local returnArrow="<===  ${foldName}  <==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<=="
  # keep all messages consistently wide 80chars regardless of the foldName
  echo ${returnArrow:0:100}
  echo ""
  if [[ ${GITHUB_ACTIONS} == true ]]; then
    echo "github_time:end:${sanitizedFoldName}:start=${lastFoldStartTime},finish=${foldFinishTime},duration=${foldDuration}"
    echo "github_fold:end:${sanitizedFoldName}"
  fi
}

function travisFoldReturnArrows() {
  # print out return arrows so that it's easy to see the end of the script in the log
  echo ""
  returnArrow="<===  ${0#./}  <==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<=="
  # keep all messages consistently wide 80chars regardless of the foldName
  echo ${returnArrow:0:100}
  echo "<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==="
  echo ""
}
