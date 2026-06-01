#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 2m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./reload.sh)

# Get season files
standings_file="${seasonDir}/${grouping}Standings.json"
conf_standings_file="${seasonDir}/conferenceStandings.json"
stats_file="${seasonDir}/stats.json"
icons_dir="${seasonDir}/icons"

# Load Standings
jq -cs \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg grouping "${grouping}" \
'{
    "variables": {
        "seasonYear": "'${seasonYear}'",
        "standings_file": "'${conf_standings_file}'",
        "stats_file": "'${stats_file}'",
        "icons_dir": "'${icons_dir}'"
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		(.[].tables | map({(.group): .entries[].position})) as $groupingSeqs |
		map(.tables[] | .group as $group | .entries[] | {
			"title": "\(.position)  \(.club)  \(if ((.club|ascii_downcase) == $favTeam) then "★" else "" end)",
			"subtitle": "Points: \(.points)    [ GP: \(.games_played)  W: \(.wins)  L: \(.losses)  T: \(.draws)      GF: \(.goals_scored)  GA: \(.goals_against)  GD: \(.goals_difference | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": "\(.position) \(.club) \($group) \(.team_short_name)",
			"icon": { "path": (if (.team_three_letter_code | IN("NYC", "MTL")) then "images/\(.team_three_letter_code).png" else "\($icons_dir)/\(.team_three_letter_code).svg" end)},
			"text": { "copy": .club },
			"variables": { "teamId":.team_id, "teamName":.club, "teamAbbrev":.team_three_letter_code, "points":.points, "seq":(.position + ((.subposition // 1) - 1)), "conference":$group },
			"mods": {
				"cmd": {"valid": false},
				"alt": {"subtitle": "⌥↩ Sort by Conference", "arg": "", "variables": {"grouping":"conference"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by League", "arg": "", "variables": {"grouping":"league"}}
			}
		}) | (if ($grouping != "league") then ([
		    (.[] | select((.variables.seq) == 1)) |
		    (. |= (.variables.conference) as $conference | {
				"title":"—————  \(.variables.conference | gsub("\\B(?<i>[A-Z])";.i|ascii_downcase))  —————",
				"icon":{"path":"images/iconLarge.png"},
				"match":"\(.variables.conference) \($groupingSeqs | map(."\($conference)" | select(.)) | join(" "))",
				"variables":.variables, "mods":.mods, "valid": false
			}) | (.variables.seq |= 0) | (.variables.teamName |= "")
		]+.) end)
		| (if ($grouping == "conference") then sort_by(.variables.conference, .variables.seq) end)
		| [(.[] | select(($grouping == "league" and .variables.seq == 1) | not) | select(.variables.seq != 0 and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${standings_file}"