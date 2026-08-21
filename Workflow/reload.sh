#!/bin/zsh --no-rcs

mkdir -p "${alfred_workflow_data}"
seasons_file="${alfred_workflow_data}/seasons.json"

# Conditionally download seasons file
function getSeason {
    # Get current/selected season
    [[ "$(date +%s)" -ge "$(date -jv 2m +%s)" ]] && seasonYear="$(date +%Y)" || seasonYear="$(($(date +%Y) - 1))"
    season="$(jq -r --argjson seasonYear "${seasonYear}" '.seasons[] | select(.season == $seasonYear) | .season_id' "${seasons_file}")"
    seasonDir="${alfred_workflow_data}/${seasonYear}"
}
[[ -f "${seasons_file}" ]] && getSeason
[[ -n "${season}" ]] && downloadStatus=1 || curl -sf --compressed --connect-timeout 5 -L "https://stats-api.mlssoccer.com/competitions/MLS-COM-000001/seasons" -o "${seasons_file}" && downloadStatus=1 && getSeason

if [[ -n "${downloadStatus}" ]]; then
    # Get season standings
    mkdir -p "${seasonDir}"
    curl -sf --compressed --parallel --max-time 10 \
        -L "https://stats-api.mlssoccer.com/competitions/MLS-COM-000001/seasons/${season}/standings?category=conference" -o "${seasonDir}/conferenceStandings.json" \
        -L "https://stats-api.mlssoccer.com/competitions/MLS-COM-000001/seasons/${season}/standings" -o "${seasonDir}/leagueStandings.json" \
        -L "https://stats-api.mlssoccer.com/statistics/clubs/competitions/MLS-COM-000001/seasons/${season}?per_page=50" -o "${seasonDir}/stats.json"
    set -o extendedglob
    if [[ -f "${seasonDir}/leagueStandings.json" && ! -n ${seasonDir}/icons/*.svg(#qNY1) ]]; then
        # Get Team Logos
        mkdir -p "${seasonDir}/icons"
        teamLogos="$(jq -r '[.tables[].entries[].team_three_letter_code] | join(",")' "${seasonDir}/leagueStandings.json")"
        curl -sf --compressed --parallel --max-time 10 --output-dir "${seasonDir}/icons" -L "https://images.mlssoccer.com/image/upload/assets/logos/{${teamLogos}}.svg" -o "#1.svg"
    fi
    touch "${alfred_workflow_data}"
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi