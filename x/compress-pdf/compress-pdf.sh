#!/usr/bin/env bash
set -euo pipefail

program_name="${0##*/}"
default_max_size="300k"
max_size_argument="$default_max_size"
keep_original=1

# Image resolution and JPEG quality, from the best quality to the smallest
# result. The first step that fits the size budget wins.
quality_ladder=(
  "300 92"
  "200 88"
  "150 80"
  "120 72"
  "96 62"
  "72 50"
  "50 40"
)

usage() {
  cat <<USAGE
Usage: $program_name [--max-size SIZE] [--rm] FILE

Compress FILE in place until it fits SIZE. Images are downsampled and
re-encoded as JPEG; text, fonts, links and outlines are preserved.

The file is replaced only when the result is smaller than the original.
The original is saved next to it as FILE.original.pdf unless --rm is given.
Encrypted and signed PDFs are rejected.

Options:
  -m, --max-size SIZE  Size budget as bytes, or with a k (KiB) or M (MiB)
                       suffix. Default: $default_max_size
      --rm             Do not keep a copy of the original file
  -h, --help           Show this help
USAGE
}

error() {
  printf '%s: %s\n' "$program_name" "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "missing command: $1"
}

parse_size() {
  local text=$1
  local digits=${text%%[!0-9]*}
  local suffix=${text#"$digits"}

  [[ -n "$digits" ]] || error "invalid size: $text"

  case "$suffix" in
    "" | b | B) printf '%s\n' "$((digits))" ;;
    k | K) printf '%s\n' "$((digits * 1024))" ;;
    m | M) printf '%s\n' "$((digits * 1024 * 1024))" ;;
    *) error "invalid size suffix: $text" ;;
  esac
}

size_of() {
  stat -c '%s' -- "$1"
}

backup_destination() {
  local input=$1

  case "$input" in
    *.pdf | *.PDF)
      printf '%s.original.pdf\n' "${input%.*}"
      ;;
    *)
      printf '%s.original\n' "$input"
      ;;
  esac
}

human_size() {
  local bytes=$1

  if [[ "$bytes" -ge 1048576 ]]; then
    printf '%d.%d MiB' "$((bytes / 1048576))" "$((bytes * 10 / 1048576 % 10))"
  elif [[ "$bytes" -ge 1024 ]]; then
    printf '%d.%d KiB' "$((bytes / 1024))" "$((bytes * 10 / 1024 % 10))"
  else
    printf '%d B' "$bytes"
  fi
}

has_signature() {
  local input=$1

  qpdf --json --json-key=qpdf "$input" \
    | jq -e '
        def has_signature:
          if type == "object" then
            (.["/Type"]? == "/Sig") or has("/ByteRange") or any(.[]; has_signature)
          elif type == "array" then
            any(.[]; has_signature)
          else
            false
          end;

        .qpdf[1] | has_signature
      ' >/dev/null
}

run_ghostscript() {
  local input=$1
  local output=$2
  local resolution=$3
  local quality=$4

  gs \
    -dSAFER \
    -dBATCH \
    -dNOPAUSE \
    -dQUIET \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.7 \
    -dDetectDuplicateImages=true \
    -dCompressFonts=true \
    -dSubsetFonts=true \
    -dEmbedAllFonts=true \
    -dColorConversionStrategy=/sRGB \
    -dProcessColorModel=/DeviceRGB \
    -dDownsampleColorImages=true \
    -dColorImageDownsampleType=/Bicubic \
    "-dColorImageResolution=$resolution" \
    -dDownsampleGrayImages=true \
    -dGrayImageDownsampleType=/Bicubic \
    "-dGrayImageResolution=$resolution" \
    -dDownsampleMonoImages=true \
    -dMonoImageDownsampleType=/Subsample \
    "-dMonoImageResolution=$((resolution * 4))" \
    -dAutoFilterColorImages=false \
    -dColorImageFilter=/DCTEncode \
    -dAutoFilterGrayImages=false \
    -dGrayImageFilter=/DCTEncode \
    "-dJPEGQ=$quality" \
    "-sOutputFile=$output" \
    "$input"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m | --max-size)
      [[ $# -ge 2 ]] || error "missing value for $1"
      max_size_argument=$2
      shift 2
      ;;
    --max-size=*)
      max_size_argument=${1#*=}
      shift
      ;;
    --rm)
      keep_original=0
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      error "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -eq 1 ]] || {
  usage >&2
  exit 2
}

require_command chmod
require_command cp
require_command dirname
require_command gs
require_command jq
require_command mktemp
require_command mv
require_command qpdf
require_command realpath
require_command rm
require_command stat

max_size=$(parse_size "$max_size_argument")
[[ "$max_size" -gt 0 ]] || error "size budget must be positive: $max_size_argument"

input_arg=$1

[[ -f "$input_arg" ]] || error "input is not a regular file: $input_arg"
[[ -r "$input_arg" ]] || error "input is not readable: $input_arg"
[[ -w "$input_arg" ]] || error "input is not writable: $input_arg"

input_pdf=$(realpath -- "$input_arg")
input_directory=$(dirname -- "$input_pdf")

[[ -w "$input_directory" ]] || error "input directory is not writable: $input_directory"

if [[ "$keep_original" -eq 1 ]]; then
  backup_pdf=$(backup_destination "$input_pdf")
  [[ ! -e "$backup_pdf" && ! -L "$backup_pdf" ]] || error "backup already exists: $backup_pdf"
fi

set +e
qpdf --is-encrypted "$input_pdf" >/dev/null 2>&1
encryption_status=$?
set -e

case "$encryption_status" in
  0) error "encrypted PDFs are not supported" ;;
  2) ;;
  *) error "could not determine PDF encryption status" ;;
esac

if has_signature "$input_pdf"; then
  error "signed PDFs are not supported because rewriting invalidates signatures"
fi

qpdf --check --warning-exit-0 "$input_pdf" >/dev/null
input_pages=$(qpdf --show-npages "$input_pdf")
original_size=$(size_of "$input_pdf")

temporary_directory=$(mktemp -d -p "$input_directory" ".compress-pdf.XXXXXXXXXX")
cleanup() {
  rm -rf -- "$temporary_directory"
}
trap cleanup EXIT

candidate_pdf="$temporary_directory/candidate.pdf"
best_pdf="$temporary_directory/best.pdf"
best_size=0
best_step=

for step in "${quality_ladder[@]}"; do
  read -r resolution quality <<<"$step"

  run_ghostscript "$input_pdf" "$candidate_pdf" "$resolution" "$quality"

  [[ -s "$candidate_pdf" ]] || error "compression produced an empty file"
  qpdf --check --warning-exit-0 "$candidate_pdf" >/dev/null

  candidate_pages=$(qpdf --show-npages "$candidate_pdf")
  [[ "$candidate_pages" == "$input_pages" ]] \
    || error "compression changed the page count: $input_pages -> $candidate_pages"

  candidate_size=$(size_of "$candidate_pdf")

  if [[ -z "$best_step" || "$candidate_size" -lt "$best_size" ]]; then
    mv -f -- "$candidate_pdf" "$best_pdf"
    best_size=$candidate_size
    best_step="$resolution dpi, JPEG quality $quality"
  else
    rm -f -- "$candidate_pdf"
  fi

  [[ "$candidate_size" -gt "$max_size" ]] || break
done

if [[ "$best_size" -ge "$original_size" ]]; then
  printf '%s: %s, already smaller than any candidate; left unchanged\n' \
    "$input_arg" \
    "$(human_size "$original_size")"
  exit 0
fi

if [[ "$keep_original" -eq 1 ]]; then
  cp -p -- "$input_pdf" "$backup_pdf"
fi

chmod --reference="$input_pdf" -- "$best_pdf"
mv -f -- "$best_pdf" "$input_pdf"

final_size=$(size_of "$input_pdf")
printf '%s: %s -> %s (%d%% smaller, %s)\n' \
  "$input_arg" \
  "$(human_size "$original_size")" \
  "$(human_size "$final_size")" \
  "$((100 - 100 * final_size / original_size))" \
  "$best_step"

if [[ "$keep_original" -eq 1 ]]; then
  printf 'Original saved as %s\n' "$backup_pdf"
fi

if [[ "$final_size" -gt "$max_size" ]]; then
  printf '%s: could not reach the %s budget; wrote the smallest result instead\n' \
    "$program_name" \
    "$(human_size "$max_size")" >&2
fi
