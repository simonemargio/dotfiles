#!/bin/bash

read -p "New file name: " fileName

if [ -e "/Users/simonemargio/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Inbox/$fileName.md" ]; then
    nvim "/Users/simonemargio/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Inbox/$fileName.md"
else
    touch "/Users/simonemargio/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Inbox/$fileName.md"
    nvim "/Users/simonemargio/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main/Inbox/$fileName.md"
fi

