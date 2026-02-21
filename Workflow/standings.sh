#!/bin/zsh --no-rcs

# Get current/selected season
seasons_file="${alfred_workflow_data}/seasons.json"
[[ "$(date +%s)" -ge "$(date -jv 2m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
season="$(jq -r --argjson seasonYear "${seasonYear}" '.seasons[] | select(.season == $seasonYear) | .season_id' "${seasons_file}")"

# Auto Update
[[ -f "${alfred_workflow_data}/seasons.json" ]] && [[ "$(date -r "${alfred_workflow_data}/seasons.json" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./reload.sh)

# Get season files
standings_file="${alfred_workflow_data}/${seasonYear}/${grouping}Standings.json"
conf_standings_file="${alfred_workflow_data}/${seasonYear}/conferenceStandings.json"
stats_file="${alfred_workflow_data}/${seasonYear}/stats.json"
icons_dir="${alfred_workflow_data}/${seasonYear}/icons"

# Load Standings
jq -cs \
   --arg icons_dir "${icons_dir}" \
   --arg favTeam "${(L)favTeam}" \
   --arg grouping "${grouping}" \
'{
    "variables": {
        "seasons_file": "'${seasons_file}'",
        "season": "'${season}'",
        "seasonYear": "'${seasonYear}'",
        "standings_file": "'${conf_standings_file}'",
        "stats_file": "'${stats_file}'",
        "icons_dir": "'${icons_dir}'"
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		map(.tables[] | .group as $group | .entries[] | {
			"title": "\(.position)  \(.club)",
			"subtitle": "Points: \(.points)    [ GP: \(.games_played)  W: \(.wins)  L: \(.losses)  T: \(.draws)      GF: \(.goals_scored)  GA: \(.goals_against)  GD: \(.goals_difference | (if . > 0 then "+"+(.|tostring) else . end)) ]",
			"arg": "stats",
			"match": "\(.position) \(.club) \($group)",
			"icon": { "path": "\($icons_dir)/\(.team_three_letter_code).svg" },
			"text": { "copy": .club },
			"variables": { "teamId":.team_id, "teamName":.club, "teamAbbrev":.team_three_letter_code, "points":.points, "seq":(.subposition // .position), "conference":$group },
			"mods": {
				"alt": {"subtitle": "⌥↩ Sort by Conference", "arg": "", "variables": {"grouping":"conference"}},
			    "ctrl": {"subtitle": "⌃↩ Sort by League", "arg": "", "variables": {"grouping":"league"}}
			}
		}) | (if ($grouping != "league") then ([
		    (.[] | select((.variables.seq) == 1)) |
		    (. |= {"title":"——  \(.variables.conference | gsub("\\B(?<i>[A-Z])";.i|ascii_downcase))  ——", "valid": false, "variables":.variables, "mods":.mods, "match":.variables.conference}) |
			(.variables.seq |= 0)
		]+.) end)
		| (if ($grouping == "conference") then sort_by(.variables.conference, .variables.seq) end)
		| [(.[] | select((.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
		| [(.[] | if ((.variables.teamName|ascii_downcase) == $favTeam) then (.title |= .+"  ★") end)]
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current season",
			"arg": "reload"
		}]
	end)
}' "${standings_file}"