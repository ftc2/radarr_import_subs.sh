# radarr_import_subs.sh
This is a script for Radarr to import subtitles from subdirectories (subfolders). It also notifies Radarr of the new subtitles after import.

This copies english subtitles, but it can be easily modified for another language (see Setup section of the script).

Subtitles are named according to track numbers in filenames if present.
Examples:
- `1_English.srt` -> `movie.en.forced.srt`
- `2_English.srt` -> `movie.en.srt`
- `3_English.srt` -> `movie.en.sdh.srt`
- ...
- `9_English.srt` -> `movie.en.9.srt` (unknown track number)

This script depends on `bash`, `find` (with `-regex` and `-printf` support), and `curl`. `jq` is optional but used to verify successful connection to Radarr API; it's not needed to actually trigger a rescan.

Suggestions and PRs welcome.

```bash
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
```

![installation screenshot](https://i.imgur.com/vXXz5K1.png)
