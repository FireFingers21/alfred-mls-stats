#!/bin/zsh --no-rcs

# Get age of stats_file in minutes
[[ -f "${stats_file}" ]] && minutes="$((($(date +%s)-$(date -r "${stats_file}" +%s))/60))"

# Download Stats Data
if [[ "${forceReload}" -eq 1 ]]; then
    # Rate limit to only refresh if data is older than 1 minute
    [[ "${minutes}" -gt 0 || -z "${minutes}" ]] && reload=$(./reload.sh) && minutes=0
fi

# Format Last Updated Time
if [[ ! -f "${stats_file}" || ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${stats_file}" +'%Y-%m-%d')"
fi

# Format Stats to Markdown
if [[ -f "${stats_file}" ]]; then
    lastUpdatedDate="$(date -r "${stats_file}" +%Y-%m-%d)"
    mdOutput=$(jq -crs --arg teamId "${teamId}" --arg icons_dir "${icons_dir}" --arg lastUpdatedDate "${lastUpdatedDate}" \
'(.[].team_statistics | select(length>0) | length) as $leagueCnt |
map(.team_statistics + .tables[0].entries + .tables[1].entries) | flatten(1) | map(select(.team_id == $teamId)) | add |
40 as $spaces |
    "![Team Logo](\($icons_dir)/\(.three_letter_code)small.png)\n",
    "# "+.team_name,
    "\n**Games Played:** \(.games_played)      ·      **Points:** \(.points)      ·      **Date:** \($lastUpdatedDate)",
    "\n***\n\n### General\n\n```",
    ("Wins:"|.+" "*($spaces-length))+"\(.wins)",
    ("Losses:"|.+" "*($spaces-length))+"\(.losses)",
    ("Ties:"|.+" "*($spaces-length))+"\(.draws)",
    ("Fouls:"|.+" "*($spaces-length))+"\(.fouls_against_opponent)",
    ("Fouls Suffered:"|.+" "*($spaces-length))+"\(.fouls_suffered)",
    ("Offside:"|.+" "*($spaces-length))+"\(.offsides)",
    ("Yellow Cards:"|.+" "*($spaces-length))+"\(.cards_yellow)",
    ("Red Cards:"|.+" "*($spaces-length))+"\(.cards_red)",
    "```\n\n### Passing\n\n```",
    ("Completed Passes (%):"|.+" "*($spaces-length))+"\(.passes_successful_sum) (\(.passes_successful_sum/.passes_sum*100|round)%)",
    ("Total Passes:"|.+" "*($spaces-length))+"\(.passes_sum)",
    ("Free Kicks:"|.+" "*($spaces-length))+"\(.free_kicks_sum)",
    ("Corner Kicks:"|.+" "*($spaces-length))+"\(.corner_kicks_sum)",
    ("Assists:"|.+" "*($spaces-length))+"\(.assists)",
    ("Accurate Long Balls (%):"|.+" "*($spaces-length))+"\(.crosses_successful_sum) (\(.passes_from_open_play_long_successful_ratio)%)",
    "```\n\n### Attacking\n\n```",
    ("Goals:"|.+" "*($spaces-length))+"\(.goals_scored)",
    ("Key Passes:"|.+" "*($spaces-length))+"\(.second_assists)",
    ("Corner Kicks:"|.+" "*($spaces-length))+"\(.corner_kicks_sum)",
    ("Expected Goals:"|.+" "*($spaces-length))+"\(.xG*100|round/100)",
    ("Penalty Kick Goals:"|.+" "*($spaces-length))+"\(.penalties_successful)",
    ("Penalty Kicks Taken (%):"|.+" "*($spaces-length))+"\(.penalties_sum) (\(.penalty_conversion_rate*100)%)",
    ("Shot Conversion Ratio:"|.+" "*($spaces-length))+"\(.shots_at_goal_sum)",
    ("Shots on Target (%):"|.+" "*($spaces-length))+"\(.shots_on_target) (\(.shots_on_target/.shots_at_goal_sum*100|round)%)",
    "```\n\n### Defending\n\n```",
    ("Goals Against:"|.+" "*($spaces-length))+"\(.goals_against)",
    ("Shots Against:"|.+" "*($spaces-length))+"\(.shots_faced)",
    ("Clean Sheet:"|.+" "*($spaces-length))+"\(.clean_sheets)",
    ("Saves Percentage:"|.+" "*($spaces-length))+"\(.shots_faced/.goalkeeper_saves*100|round)%",
    ("Aerial Duel Percentage:"|.+" "*($spaces-length))+"\(.tackling_games_air_won/.tackling_games_air_sum*100|round)%",
    ("Clearances:"|.+" "*($spaces-length))+"\(.defensive_clearances)",
    ("Penalties Conceded:"|.+" "*($spaces-length))+"\(.penalties_caused)",
    ("Penalty Saves (%):"|.+" "*($spaces-length))+"\(.penalties_saved) (\(.penalties_saved/.penalties_sum*100|round)%)",
    "```"
' "${standings_file}" "${stats_file}" | sed 's/\"/\\"/g')
else
    lastUpdatedDate="$(date -r "${seasons_file}" +%Y-%m-%d)"
    [[ -f "${seasons_file}" ]] && minutes="$((($(date +%s)-$(date -r "${seasons_file}" +%s))/60))"
    mdOutput="![Team Logo](${icons_dir}/${teamAbbrev}small.png)
# ${teamName}
**Games Played:** N/A      ·      **Points:** N/A      ·      **Date**: ${lastUpdatedDate}
***
*No Team Stats available yet*"
fi

# Output Formatted Stats to Text View
cat << EOB
{
    "variables": { "forceReload": 1, "minutes": "${minutes}" },
    "response": "${mdOutput//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now"
}
EOB