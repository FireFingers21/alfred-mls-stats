#!/bin/zsh --no-rcs

seasons_file="${alfred_workflow_data}/seasons.json"

mkdir -p "${alfred_workflow_data}"
curl -sf --compressed --connect-timeout 10 "https://stats-api.mlssoccer.com/competitions/MLS-COM-000001/seasons" -o "${seasons_file}" && downloadStatus=1

if [[ -n "${downloadStatus}" ]]; then
    # Get current/selected season
    [[ "$(date +%s)" -ge "$(date -jv 2m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
    season="$(jq -r --argjson seasonYear "${seasonYear}" '.seasons[] | select(.season == $seasonYear) | .season_id' "${seasons_file}")"
    seasonDir="${alfred_workflow_data}/${seasonYear}"
    # Get season standings
    mkdir -p "${seasonDir}"
    curl -sf --compressed --parallel \
        -L "https://stats-api.mlssoccer.com/competitions/MLS-COM-000001/seasons/${season}/standings?category=conference" -o "${seasonDir}/conferenceStandings.json" \
        -L "https://stats-api.mlssoccer.com/competitions/MLS-COM-000001/seasons/${season}/standings" -o "${seasonDir}/leagueStandings.json" \
        -L "https://stats-api.mlssoccer.com/statistics/clubs/competitions/MLS-COM-000001/seasons/${season}?per_page=50" -o "${seasonDir}/stats.json"
    if [[ -f "${seasonDir}/leagueStandings.json" ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamLogos=($(jq -r '"https://images.mlssoccer.com/image/upload/assets/logos/" + .tables[].entries[].team_three_letter_code + ".svg"' "${seasonDir}/leagueStandings.json"))
        curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" --remote-name-all -L "${teamLogos[@]}"
    fi
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi