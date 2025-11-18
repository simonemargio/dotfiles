#!/bin/bash
count=$(find . -maxdepth 1 -name "*.flac" | wc -l)
echo "Found $count FLAC files to convert ヾ(⌐■_■)ノ♪"

find . -maxdepth 1 -name "*.flac" | while read f; do
  output="${f%.flac}.mp3"
  if [ ! -f "$output" ]; then
    echo "Converting: $f → $output"
    ffmpeg -i "$f" -ab 320k -q:a 0 -map_metadata 0 -id3v2_version 3 -write_id3v1 1 "$output"
  else
    echo "Skipping $output (already exists) ( ͡° ͜ʖ ͡°)"
  fi
done

echo "Conversion complete! (▰˘◡˘▰)"
