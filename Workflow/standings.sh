#!/bin/zsh --no-rcs

# Get current/selected season
[[ "$(date +%s)" -ge "$(date -jv 2m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${seasonDir}" ]] && reload=$(./reload.sh)

# Load Standings
jq -cs \
   --arg alfred_workflow_keyword "${alfred_workflow_keyword}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg grouping "${grouping}" \
   --arg icons_dir "${seasonDir}/icons" \
   --arg seasonYear "${seasonYear}" \
'{
    "variables": {
        "keyword": $alfred_workflow_keyword,
        "icons_dir": $icons_dir,
        "seasonYear": $seasonYear
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		(.[0].tables | map({(.group): .entries[].position})) as $groupingSeqs |
		map(.tables[] | .group as $group | .entries[] |
		((.club|ascii_downcase) == $favTeam) as $isFavourite | {
			"title": "\(.position)  \(if (.tendency == "up") then "↑" elif (.tendency == "down") then "↓" else "↔" end)  \(.club)  \(if ((.club|ascii_downcase) == $favTeam) then "★" else "" end)",
			"subtitle": "Points: \(.points)    [ GP: \(.games_played)  W: \(.wins)  L: \(.losses)  T: \(.draws)      GF: \(.goals_scored)  GA: \(.goals_against)  GD: \(.goals_difference | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": "\(.position) \(.club) \($group) \(.team_short_name)",
			"icon": { "path": (if (.team_three_letter_code | IN("NYC", "MTL")) then "images/\(.team_three_letter_code).png" else "\($icons_dir)/\(.team_three_letter_code).svg" end)},
			"text": { "copy": .club },
			"variables": { "favTeamNew": .club, "teamId":.team_id, "teamName":.club, "teamAbbrev":.team_three_letter_code, "points":.points, "seq":(.position + ((.subposition // 1) - 1)), "conference":$group },
			"mods": {
				"cmd": {"valid": false},
				"alt": {"subtitle": "⌥↩ Sort by Conference", "arg": "", "variables": {"grouping":"conference"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by League", "arg": "", "variables": {"grouping":"league"}},
				"cmd+shift": {"subtitle": "⇧⌘↩ \(if ($isFavourite) then "Unset" else "Set" end) Favourite Team"}
			}
		}) | (if ($grouping != "league") then ([
		    (unique_by(.variables.conference)[] | select((.variables.seq) == 1)) | (. |= (.variables.conference) as $conference | {
				"title":"—————  \(.variables.conference | gsub("\\B(?<i>[A-Z])";.i|ascii_downcase))  —————",
				"icon":{"path":"images/iconLarge.png"},
				"match":"\(.variables.conference) \($groupingSeqs | map(."\($conference)" | select(.)) | join(" "))",
				"variables":.variables, "mods":.mods, "valid": false
			}) | (.variables.seq |= 0) | (.variables.favTeamNew |= "") | (.mods."cmd+shift".subtitle |= "")
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
}' "${seasonDir}/${grouping}Standings.json"