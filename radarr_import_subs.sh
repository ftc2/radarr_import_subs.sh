#!/usr/bin/env bash

#########################
# radarr_import_subs.sh
# Radarr script to import subtitles from subdirectories
#
# https://github.com/ftc2/radarr_import_subs.sh
# (C) 2022 ftc2

#########################
# Installation

# 1) put this script somewhere that radarr can access
# 2) make it executable
#      chmod +x /path/to/radarr_import_subs.sh
# 3) add your radarr API info in the Setup section of this script to trigger rescan after import
#      RADARR_URL, RADARR_API_KEY
# 4) add this script to radarr as a custom connection
#      Radarr WebUI > Settings > Connect > Add (+) > Custom Script
#        Name: Subdirectory Subtitle Importer
#        Triggers: On Import, On Upgrade
#        Path: /path/to/radarr_import_subs.sh

#########################
# Setup

RADARR_URL='http://radarr:7878' # including port (and base path if applicable)
  # no trailing slash!
  # example with base path: 'http://192.168.33.112:7878/basepath'
RADARR_API_KEY='' # Radarr WebUI > Settings > General > Security
RELEASE_GRPS=('RARBG' 'VXT') # only process these groups' releases
SUB_DIRS=('Subs' 'Subtitles') # paths to search for subtitles
SUB_EXTS='srt\|ass' # subtitle file extensions separated by \|
SUB_REGEX=".*en.*\.\(${SUB_EXTS}\)$" # regex used to find subtitles (in this POS regex variant, you have to escape ())
SUB_LANG='en' # this just gets added to final subtitle filenames
LOGGING=''
  #      '': standard logging
  # 'debug': log all messages to stderr to make them visible as Info in radarr logs
  # 'trace': log more info (print environment)

#########################
# Logging

log() {
  # stderr -> radarr Info
  echo "$1" >&2
}
dlog() {
  if [[ "$LOGGING" == 'debug' || "$LOGGING" == 'trace' ]]; then
    log "Debug: ${1}"
  else
    # stdout -> radarr Debug
    echo "$1"
  fi
}
tlog() {
  [[ "$LOGGING" == 'trace' ]] && log "Trace: ${1}"
}

#########################
# Test/Debug

# https://wiki.servarr.com/radarr/custom-scripts#on-importon-upgrade
# first, print out the shell environment from an actual movie import (or set LOGGING=trace):
# log "$(printenv)"
# then look in the logs and copy stuff from there below to simulate a movie
# radarr_eventtype='Test' # uncomment to debug from shell
if [[ "$radarr_eventtype" == 'Test' ]]; then
  # this script needs the following stuff defined for testing:
  radarr_eventtype='Download'
  radarr_moviefile_releasegroup='VXT'
  radarr_moviefile_sourcefolder='/pirate/dl/movies/Final.Fantasy.VII.Advent.Children.Complete.2005.JAPANESE.1080p.BluRay.H264.AAC-VXT'
  radarr_moviefile_sourcepath='/pirate/dl/movies/Final.Fantasy.VII.Advent.Children.Complete.2005.JAPANESE.1080p.BluRay.H264.AAC-VXT/Final.Fantasy.VII.Advent.Children.Complete.2005.JAPANESE.1080p.BluRay.H264.AAC-VXT.mp4'
  radarr_movie_path='/pirate/movies/Final Fantasy VII - Advent Children (2005)'
  radarr_moviefile_path='/pirate/movies/Final Fantasy VII - Advent Children (2005)/Final.Fantasy.VII.Advent.Children.Complete.2005.JAPANESE.1080p.BluRay.H264.AAC-VXT.mp4'
  radarr_moviefile_relativepath='Final.Fantasy.VII.Advent.Children.Complete.2005.JAPANESE.1080p.BluRay.H264.AAC-VXT.mp4'
  radarr_movie_id='1591'
  radarr_movie_title='Final Fantasy VII: Advent Children'
  radarr_movie_year='2005'
fi
# after that, you can just hit the Test button on the Edit Connection dialog in radarr
# alternatively, you can run this script from a shell by setting the event type to Test above

#########################
# Main Script

# check event type
[[ "$radarr_eventtype" != 'Download' ]] && exit 0

# check release group
printf '%s\0' "${RELEASE_GRPS[@]}" | grep -F -x -z -- "$radarr_moviefile_releasegroup" >/dev/null || exit 0

radarr_rescan() {
  local api_url="${RADARR_URL}/api/v3/command?apikey=${RADARR_API_KEY}"
  log "Triggering radarr rescan of ${radarr_movie_title} (${radarr_movie_year})..."
  local response=$(curl \
    --silent \
    -X POST \
    -d "{\"name\": \"RescanMovie\", \"movieId\": ${radarr_movie_id}}" \
    -H 'Content-Type: application/json' \
    "$api_url")
  tlog "$response"
  if command -v jq; then
    # `jq` is installed
    local status=$(echo "$response" | jq '.body | .completionMessage')
    tlog "Rescan API request status: ${status}"
    [[ "$status" == '"Completed"' ]] || log 'ERROR: Failed to trigger rescan in radarr. Check script API settings.'
  fi
}

dlog '----------Subdirectory Subtitle Importer----------'
tlog "$(printenv)"

# full target path for sub files (without file extension)
sub_path_prefix="${radarr_moviefile_path%.*}"

for rel_sub_dir in "${SUB_DIRS[@]}"; do
  dlog "Current subtitle dir: ${rel_sub_dir}"
  sub_dir="${radarr_moviefile_sourcefolder}/${rel_sub_dir}"
  if [[ -d "$sub_dir" ]]; then
    # path exists
    cd "$sub_dir" # `find` searches entire path, so `cd` to get relative path instead!
    num_subs=$(find . -type f -iregex "$SUB_REGEX" -printf '.' | wc -c)
    dlog "Found ${num_subs} matching subtitle(s) in ${sub_dir}"
    find . -type f -iregex "$SUB_REGEX" -print0 |
      while read -r -d '' sub_file; do
        dlog "Current subtitle: ${sub_file}"
        sub_ext="${sub_file##*.}"
        if [[ "$sub_file" =~ ([0-9]) ]]; then
          # sub filename contains a track number
          sub_track_num="${BASH_REMATCH[1]}"
          # if there's only one sub file but it has a funny track number, just assume it's a normal sub (track 2)
          [[ "$num_subs" -eq 1 && "$sub_track_num" -gt 3 ]] && sub_track_num=2
          case "$sub_track_num" in
            1) sub_track="${SUB_LANG}.forced";;
            2) sub_track="${SUB_LANG}";;
            3) sub_track="${SUB_LANG}.sdh";;
            *) sub_track="${SUB_LANG}.${sub_track_num}";;
          esac
        else
          if [[ "$num_subs" -eq 1 ]]; then
            # no track number, only one sub
            sub_track="$SUB_LANG"
          else
            # no track number, multiple subs
            log "ERROR: Multiple matching subtitles were found, but a match was found without a track number in its filename. Aborting. (${sub_dir}/${sub_file##*/})"
            radarr_rescan
            exit 1
          fi
        fi
        log "Copying subtitle: ${rel_sub_dir}/${sub_file##*/} --> ${sub_path_prefix}.${sub_track}.${sub_ext}"
        cp "${sub_file}" "${sub_path_prefix}.${sub_track}.${sub_ext}"
      done
  fi
done

radarr_rescan
