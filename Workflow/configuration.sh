#!/bin/zsh --no-rcs

# Get lastest cache timestamp
readonly lastUpdated=$(date -r "${alfred_workflow_data}" +"%A, %B %d %Y at %I:%M%p" || printf "Never")

cat << EOB
{"items": [
	{
		"title": "Reload Standings",
		"subtitle": "Last Updated: ${lastUpdated}",
		"variables": { "pref_id": "reload" }
	},
	{
		"title": "Open Standings in Browser",
		"arg": "https://www.mlssoccer.com/standings/",
		"variables": { "pref_id": "open" }
	},
	{
		"title": "Configure Workflow...",
		"subtitle": "Open the configuration window for ${alfred_workflow_name}",
		"arg": "alfredpreferences://navigateto/workflows>workflow>${alfred_workflow_uid}>userconfig",
		"variables": { "pref_id": "configure" }
	}
]}
EOB