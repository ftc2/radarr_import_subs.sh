# radarr_import_subs.sh
Radarr script to import subtitles from subdirectories (subfolders)

This copies english subtitles, but it can be easily modified for another language (see SETUP section of the script).

It renames subtitles according to track number in filename if present.
Examples:
- `1_English.srt` -> `movie.en.forced.srt`
- `2_English.srt` -> `movie.en.srt`
- `3_English.srt` -> `movie.en.sdh.srt`
- `9_English.srt` -> `movie.en.9.srt`

Suggestions and PRs welcome.

```bash
#########################
# Installation

# 1) put this script somewhere that radarr can access
# 2) make it executable
#      chmod +x /path/to/radarr_import_subs.sh
# 3) Radarr WebUI > Settings > Connect > Add (+) > Custom Script
#      Name: Subdirectory Subtitle Importer
#      Triggers: On Import, On Upgrade
#      Path: /path/to/radarr_import_subs.sh

#########################
# Setup

release_grps=('RARBG' 'VXT') # only process these groups' releases
sub_dirs=('Subs' 'Subtitles') # paths to search for subtitles; use () to search all subdirectories
sub_exts='srt\|ass' # subtitle file extensions separated by \|
sub_regex=".*en.*\.\(${sub_exts}\)$" # regex used to find subtitles (in this POS regex variant, you have to escape ())
sub_lang='en' # this just gets added to final subtitle filenames
LOGGING=''
  #      '': standard logging
  # 'debug': log all messages to stderr to make them visible as Info in radarr logs
  # 'trace': log more info (print environment)
```

![installation screenshot](https://i.imgur.com/vXXz5K1.png)
