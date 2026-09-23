#!/usr/bin/env bash
#
# Usage: set this file as the post-processing script in the simple-scan preferences. No extra arguments needed.
#
# For reference, at the time of writing the arguments from simple-scan are:
# $1    - the mime type, eg application/pdf
# $2    - boolean, keep original file
# $3    - the filename
# $4..N - postprocessing script arguments entered in preferences

mime_type=$1
keep_original=$2
filename=$3

# OCR is applied to PDF only, other formats are left as saved.
if [ "$mime_type" != "application/pdf" ]; then
  exit 0
fi

# simple-scan expects the script to keep the original as "<name>_orig.<ext>".
if [ "$keep_original" = "true" ]; then
  cp -- "$filename" "${filename%.*}_orig.${filename##*.}" || exit 1
fi

log=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/simple-scan-postprocessing.XXXXXX.log")
if ! ocrmypdf --deskew --clean --force-ocr "$filename" "$filename" &> "$log"; then
  notify-send "OCR failed. See $log"
  exit 1
fi
rm -f -- "$log"
notify-send "OCR complete"
