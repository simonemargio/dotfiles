#!/bin/bash

#######################################################################################################################################
#######################################################################################################################################


########################
#### CONFIGURATION #####
########################

# LOAD ENV VARIABLE FOR LOCAL CONFIGURATION
#
# CONFIGURATION_ENV_OFFSITE_STORAGE_PATH
# CONFIGURATION_CHECK_LOG_ERROR
# RESTORE_FOLDER_PATH
# PATH_TO_SAVE_LOG
# PATH_TO_COPY_ERROR_LOG
source "$HOME/.config/restic/env/configuration.env"

# LOAD ENV VARIABLE FOR LOCAL EMAIL SENDER
#
# EMAIL_FROM
# EMAIL_TO
# EMAIL_SUBJECT
# EMAIL_FROM
# EMAIL_PASSWORD
# EMAIL_SMTP
source "$HOME/.config/restic/env/.email.env"


#######################################################################################################################################
#######################################################################################################################################

#######################
#### SCRIPT START #####
#######################

# Keep awake during check execution
caffeinate -s &
caffeinate_pid=$!
data_delete_log=$(date -v -14d "+%Y-%m-%d")

# Search every .log file and:
# 1. Save them in daily folder
# 2. Extract all text and seach bad word as "error"
# 
# If ther's an error send an email allert
for file in "$PATH_TO_SAVE_LOG"/*; do

  # Delete folder older than 14 days 
  data_file_log=$(echo "$file" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")

  if [[ "$data_file_log" < "$data_delete_log" ]]; then
      rm -r "$file"
      echo "[INFO]-APPLY-LOG-RETENTION-DELETED-($file)"
  else
      # Check if the file is a regular file
      if [ -f "$file" ]; then
         
          # Extract the day, month, and year from the log's date
          year=$(date -jf "%Y-%m-%d" "$data_file_log" "+%Y")
          month=$(date -jf "%Y-%m-%d" "$data_file_log" "+%m")
          day=$(date -jf "%Y-%m-%d" "$data_file_log" "+%d")

          # Create the folder if it doesn't exist
          folder="$PATH_TO_SAVE_LOG/$year-$month-$day"
          mkdir -p "$folder"

          # Move the log file to the folder
          mv "$file" "$folder/"
          echo "[INFO]-LOG-MOVED-TO-($folder)"

          # Read the content of the file and convert it to lowercase
          content=$(<"$folder/$(basename "$file")" tr '[:upper:]' '[:lower:]')
         
          # Check if the content contains the word "error"
          if [[ $content == *"error"* ]] || [[ $content == *"errors"* ]] || [[ $content == *"denied"* ]]; then
              if [[ $content != *"no errors were found"* ]]; then 
                  mv "$folder/$(basename "$file")" "$PATH_TO_COPY_ERROR_LOG/"
                  echo "[ERROR]-File-($folder/$(basename "$file"))-SEND-EMAIL-ALERT"
                  sendemail -f "$EMAIL_FROM" -t "$EMAIL_TO" -u "$EMAIL_SUBJECT" -m "$content" -s $EMAIL_SMTP -o tls=yes -xu "$EMAIL_FROM" -xp "$EMAIL_PASSWORD"
              fi 
          fi 
      fi
  fi
done

#######################################################################################################################################
#######################################################################################################################################

umount $PATH_TO_MOUNT_NAS
kill "$caffeinate_pid"
echo "[INFO]-END-CHECK-LOG"
echo "[INFO]-ALL-DONE-END-BACKUP-SCRIPT! d–(^ ‿ ^ )z"
