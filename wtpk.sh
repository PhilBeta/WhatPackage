#!/bin/bash
# __        ___           _   ____            _                    
# \ \      / / |__   __ _| |_|  _ \ __ _  ___| | ____ _  __ _  ___ 
#  \ \ /\ / /| '_ \ / _` | __| |_) / _` |/ __| |/ / _` |/ _` |/ _ \
#   \ V  V / | | | | (_| | |_|  __/ (_| | (__|   < (_| | (_| |  __/
#    \_/\_/  |_| |_|\__,_|\__|_|   \__,_|\___|_|\_\__,_|\__, |\___|
#                                                       |___/      
# WhatPackage - A ChatGPT Package Discovery Tool
# Programmed By Phil Beta

# How to use:
# Export your OpenAI API key into an environment variable named WTPK_API_KEY. Run this script once to load the wtpk() function into memory. Call WhatPackage using 'wtpk' followed by the task you're trying to complete. WhatPackage will list 1-10 relevant packages available for your current environment. Enter number to install.

# Easy start: uncomment the line below and paste your OpenAI API key.
# WTPK_API_KEY=

WTPK_SHOW_REQUEST_PHRASE=1
WTPK_SHOW_RAW_RESPONSE=1
WTPK_MODEL="gpt-3.5-turbo"
WTPK_TEMPERATURE="1.0"

wtpk() (

	# check for api key
	if [ -z $WTPK_API_KEY ]; then
		echo "To start using WhatPackage, you must specify your OpenAI API key."
		echo "-> export WTPK_API_KEY=YOUR_OPENAI_API_KEY"
		return 1
	fi

	# capture all arguments as a single line of input.
	user_input="$@"

	# if no input is provided, display a welcome message.
	if [ -z "$user_input" ]; then
		echo "What would you like help with??"
	fi

	# fetch environment details
	source /etc/os-release
	os_name=$PRETTY_NAME
	environment_details="$(uname -a)"


	# main loop
	while true; do

		# ask for input if none is yet provided.
		if [ -z "$user_input" ]; then
			echo -n ">> "
			read user_input
		fi

		# if the input is a number. Handle it as an install command.
		digits="${user_input//[^0-9]/}"
		if [[ "$digits" == "$user_input" ]]; then
			# install the app and exit
			commandIndex="$((digits-1))"
			eval ${commands[$commandIndex]}
			return 0
		elif [[ "$user_input" == [qQ] ]]; then
			return 0
		else
			request_phrase="I am running ${os_name}. List some packages available for my environment to help me accomplish the following task: $user_input. App must run in console and must be fully installable in one script from a fresh OS with no additional steps. Max 10, and only include relevant responses. The install script should include sudo if needed. Include an in-depth description for each item. Pretend you are an API and output the data in JSON format using this exact structure [{name,longDescription,installScript},...]. Don't output anything else!"	
			
			# (optional) dislay request phrase
			if [ $WTPK_SHOW_REQUEST_PHRASE -eq 1 ]; then
				echo -n "Request: "
				echo "$request_phrase"
			fi	

			# execute request
			echo -n "Thinking.."
			response="$( curl https://api.openai.com/v1/chat/completions -s \
				-H 'Content-Type: application/json' \
				-H "Authorization: Bearer ${WTPK_API_KEY}" \
				-d "{
					\"model\": \"$WTPK_MODEL\",
					\"temperature\": $WTPK_TEMPERATURE,
					\"messages\": [{\"role\": \"user\", \"content\": \"$request_phrase\"}]
			}" | jq -r .choices[0].message.content )"

			echo ""

			# (optional) display raw response
			if [ $WTPK_SHOW_RAW_RESPONSE -eq 1 ]; then
				echo -n "Raw response: "
				echo $response
			fi

			# determine the number of found items.
			find_count=$(echo "$response"|jq length) || find_count=0
			
			declare -A commands=()
			if [ -n $find_count ]; then
			for ((i=0; i<find_count; i++)); do
				# print the index of the item
				# TODO format and parse the data in a faster way than this.
				echo "$(echo "$response" | jq -r .[$i].name)"
				echo "$(echo "$response" | jq -r .[$i].longDescription)"
				echo -n "$((i+1))> "
				echo $(echo "$response" | jq -r .[$i].installScript)
				echo
				commands[$i]="$(echo "$response" | jq -r .[$i].installScript)"
		
			done
			fi

		fi
	
		if [ $find_count -ne 0 ]; then
			echo "Type 1-$find_count to install, or search again."
		else
			echo "Oops! Something messed up. Try again."
		fi

		#clear user input so we are prompted to re-enter it on the next loop.
		user_input=""
		

	done


)

