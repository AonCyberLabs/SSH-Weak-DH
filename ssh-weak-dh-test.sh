#!/bin/bash

readonly SSH_PATCHED="./openssh-6.?p?/ssh"
readonly SSH_OPTS="-2 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes"
readonly CONFIGS="configs/config-default configs/config-dh_gex_sha1 configs/config-dh_gex_sha256"
readonly BIT_LENGTHS="512 768 1024 1280 1536 2048"
readonly OUT_DIR="ssh-weak-dh"
readonly SSH_WEAK_DH_ANALYZE="./ssh-weak-dh-analyze.py"

usage() {
  local progname=$1

  cat <<- EOF
	Usage: $progname TARGET [PORT]

	This program connects to the given target SSH server with a
  patched SSH client and logs information about the key exchange.
	The log files can be manually analyzed or fed into a script
	to determine whether the server enables weak DH groups.
	EOF
}

run() {
  local config=$1
  local target=$2
  local port=$3
  local out_prefix=$4
  local out_file_name=$(basename $config)

  # redirect stderr containing key exchange information to file
  if [[ "$#" -ne 5 ]]; then
    ${SSH_PATCHED} $SSH_OPTS -F $config -p $port $target 2>&1 | tee "${out_prefix}/${out_file_name}"
  else
    local bit_length=$5
    ${SSH_PATCHED} $SSH_OPTS -d minbits=${bit_length},nbits=${bit_length},maxbits=${bit_length} -F $config -p $port $target 2>&1 | tee "${out_prefix}/${out_file_name}_${bit_length}"
  fi
}

main() {
  # standard SSH port
  local port=22

  if [[ "$#" -ne 1 ]] && [[ "$#" -ne 2 ]]; then
    usage $0
    exit 1
  fi
  # port specified?
  if [[ "$#" -eq 2 ]]; then
    port=$2
  fi

  local target=$1
  local target_clean="${target//+([^[:alnum:]_-\.])/_}"
  local port_clean="${port%%[^0-9]*}"
  local out_prefix="${OUT_DIR}/${target_clean}-${port_clean}"

  mkdir -p "${out_prefix}"

  echo "Saving output files in ${out_prefix}"
  echo ""

  for config in ${CONFIGS}
  do
    # Tests with default OpenSSH client parameters
    run $config $target $port $out_prefix
    # Test some specific parameters
    for bit_length in ${BIT_LENGTHS}
    do
      run $config $target $port $out_prefix $bit_length
    done
  done
  # Check for group1 manually
  ${SSH_PATCHED} $SSH_OPTS -F configs/config-group1 -p $port $target 2>&1 | tee "${out_prefix}/config-group1"

  echo ""
  echo ""
  echo "Analysis of results:"
  echo ""

  python -u $SSH_WEAK_DH_ANALYZE ${out_prefix}
}

main "$@"

