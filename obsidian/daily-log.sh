#!/bin/bash

current_date=$(date "+%Y-%m-%d")
file_path="/Users/simonemargio/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Journal/${current_date}.md"

if [ ! -e "$file_path" ]; then
    touch "$file_path"    
fi

nvim "$file_path"
