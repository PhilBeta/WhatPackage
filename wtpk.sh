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
# Export your OpenAI API key into an environment variable named WTPK_API_KEY. Run script and input the task you're trying to complete. WhatPackage will list 1-10 relevant packages available for your current environment. Enter number to install. Current version is very buggy and has no error handling, so expect to to manually resend your requests a occasionally.

# Easy start: uncomment the line below and paste your OpenAI API key.
# WTPK_API_KEY=


wtpk() {

	# check for api key
	if [ -z $WTPK_API_KEY ]; then
		echo "To start using WhatPackage, you must specify your OpenAI API key."
		echo "-> export WTPK_API_KEY=YOUR_OPENAI_API_KEY"
		exit 1
	fi

	# capture all arguments as a single line of input.
	user_input="$@"

	# if no input is provided, display a welcome message.
	if [ -z "$user_input" ]; then
		echo "What would you like help with?"
	fi

	source /etc/os-release

	get_request_text() {
		echo "I am running $PRETTY_NAME $(uname -a). List some popular packages available for my environment to help me accomplish the following task: $user_input. App must only run in console and can be fully installed in one script from a fresh OS with no additional steps. Max 10, and only include relevant responses. The install script should include sudo if needed. Include an in-depth description for each item. Pretend you are an API and output the data in JSON format using this exact structure [{name,longDescription,installScript},...]. Don't output anything else!"	
	}


	get_chat_response() {
		echo "$( { curl https://api.openai.com/v1/chat/completions -s \
		-H 'Content-Type: application/json' \
		 -H "Authorization: Bearer ${WTPK_API_KEY}" \
		-d "{
		\"model\": \"gpt-3.5-turbo\",
		\"temperature\": 1.0,
		\"messages\": [{\"role\": \"user\", \"content\": \"$(get_request_text)\"}]
		}" | jq -r .choices[0].message.content; 
	response_code=$?; } )"
	}

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
			exit 1
		elif [[ "$user_input" == [qQ] ]]; then
			exit 1
		else
			echo 'Thinking.. '
			chat_response=$(get_chat_response)
			find_count=$(echo "$chat_response"|jq length)
			echo
			declare -A commands=()
			if [ -n $find_count ]; then
			for ((i=0; i<find_count; i++)); do
				# print the index of the item
				# TODO format and parse the data in a faster way than this.
				echo "$(echo "$chat_response" | jq -r .[$i].name)"
				echo "$(echo "$chat_response" | jq -r .[$i].longDescription)"
				echo -n "$((i+1))> "
				echo $(echo "$chat_response" | jq -r .[$i].installScript)
				echo
				commands[$i]="$(echo "$chat_response" | jq -r .[$i].installScript)"
		
			done
			fi

		fi

		#clear user input so we are prompted to re-enter it on the next loop.
		user_input=""
		echo "Type 1-$find_count to install, or search again."

	done


}

