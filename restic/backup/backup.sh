#!/bin/sh

#######################################################################################################################################
#######################################################################################################################################


########################
#### CONFIGURATION #####
########################

# LOAD ENV VARIABLE FOR OFFSITE REPOSITORY
#
# PATH_NAS
# PATH_TO_MOUNT_NAS
# RESTIC_PASSWORD
source "$HOME/.config/restic/env/.repository-nas.env"

# LOAD ENV VARIABLE FOR LOCAL CONFIGURATION
#
# CONFIGURATION_ENV_OFFSITE_STORAGE_PATH
# CONFIGURATION_CHECK_LOG_ERROR
# RESTORE_FOLDER_PATH
# PATH_TO_SAVE_LOG
# PATH_TO_COPY_ERROR_LOG
source "$HOME/.config/restic/env/configuration.env"

# BUCKET NAME
BUCKET_NAME_ICLOUD="iCloud"
BUCKET_NAME_USER="User"

# FOLDER TO BACKUP
PATH_BACKUP_GITHUB=""
PATH_BACKUP_DOCUMENT=""
PATH_BACKUP_DESKTOP=""
PATH_BACKUP_DOWNLOAD=""
PATH_BACKUP_USER=""


# EXCLUDE FILE
EXCLUDE_FILE_PATH_ICLOUD=$HOME/.config/restic/backup/icloud-exclude-file.txt
EXCLUDE_FILE_PATH_USER=$HOME/.config/restic/backup/user-exclude-file.txt

# RETENTION RULE
KEEP_HOURLY_ICLOUD=24
KEEP_DAILY_ICLOUD=30
KEEP_WEEKLY_ICLOUD=52
KEEP_MONTHLY_ICLOUD=12

# RETENTION RULE
KEEP_HOURLY_USER=24
KEEP_DAILY_USER=30
KEEP_WEEKLY_USER=53
KEEP_MONTHLY_USER=12
KEEP_YEARLY_USER=1

# NOT BACKUP BETWEEN
NOT_BACKUP_FROM_TIME="00:30:00"
NOT_BACKUP_TO_TIME="06:50:00"

#######################################################################################################################################
#######################################################################################################################################

# Keep awake during backup execution
caffeinate -s &
caffeinate_pid=$!

check_internet_connection() {
    if /sbin/ping -q -c 1 -W 1 google.com > /dev/null; then
        return
    else
        sleep 360

        if /sbin/ping -q -c 1 -W 1 google.com > /dev/null; then
            return
        else
            echo "[INFO]-ABORT-BACKUP-NO-INTERNET-CONNTETION-AT-($current_time)"
            kill "$caffeinate_pid"
            exit 0
        fi    
    fi
}

# Check current time
check_time() {
    current_time=$(date +"%T")
    if [[ "$current_time" > "$NOT_BACKUP_FROM_TIME" && "$current_time" < "$NOT_BACKUP_TO_TIME" ]]; then
        echo "[INFO]-ABORT-BACKUP-TIME-POLICY-SET-AT($current_time)"
        kill "$caffeinate_pid"
        exit 0
    fi
}

mount_nas_volume() {
    mount_smbfs $PATH_NAS $PATH_TO_MOUNT_NAS

    if [ ! -d "$PATH_TO_MOUNT_NAS" ]; then
    echo "[INFO]-CREATE-FOLDER-TO-($PATH_TO_MOUNT_NAS)"
    mkdir -p $PATH_TO_MOUNT_NAS

    if [ $? -ne 0 ]; then
        echo "[INFO]-ABORT-BACKUP-UNABLE-TO-CREATE-FOLDER-TO-($PATH_TO_MOUNT_NAS)"
        kill "$caffeinate_pid"
        exit 0
    fi
fi
}

#######################
##### BACKUP USER #####
#######################
user_backup() {
    export GOMAXPROCS=6

    echo "[INFO]-START-USER-BACKUP"
    nice -n 1 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_USER --verbose backup --compression max  \
    $PATH_BACKUP_USER                                                                            \
    --exclude-file=$EXCLUDE_FILE_PATH_USER
    echo "[INFO]-END-USER-BACKUP"

    echo "[INFO]-START-USER-RETENTION-POLICY"
    nice -n 1 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_USER --verbose forget                    \
    --keep-hourly $KEEP_HOURLY_USER                                                              \
    --keep-daily $KEEP_DAILY_USER                                                                \
    --keep-weekly $KEEP_WEEKLY_USER                                                              \
    --keep-monthly $KEEP_MONTHLY_USER                                                            \
    --keep-yearly $KEEP_YEARLY_USER                                                              \
    --prune
    echo "[INFO]-END-USER-RETENTION-POLICY"

    echo "[INFO]-START-USER-BACKUP-CHECK"
    nice -n 1 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_USER check
    echo "[INFO]-END-USER-BACKUP-CHECK"
}

#######################################################################################################################################
#######################################################################################################################################

#######################
#### BACKUP ICLOUD ####
#######################
icloud_backup() {
    export GOMAXPROCS=1

    echo "[INFO]-START-ICLOUD-BACKUP"
    nice -n 10 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_ICLOUD --verbose backup --compression max   \
    $PATH_BACKUP_GITHUB                                                                              \
    $PATH_BACKUP_DOCUMENT                                                                            \
    $PATH_BACKUP_DESKTOP                                                                             \
    $PATH_BACKUP_DOWNLOAD                                                                            \
    --exclude-file=$EXCLUDE_FILE_PATH_ICLOUD
    echo "[INFO]-END-ICLOUD-BACKUP"


    echo "[INFO]-START-ICLOUD-RETENTION-POLICY"
    nice -n 10 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_ICLOUD --verbose forget                    \
    --keep-hourly $KEEP_HOURLY_ICLOUD                                                               \
    --keep-daily $KEEP_DAILY_ICLOUD                                                                 \
    --keep-weekly $KEEP_WEEKLY_ICLOUD                                                               \
    --keep-monthly $KEEP_MONTHLY_ICLOUD                                                             \
    --prune
    echo "[INFO]-END-ICLOUD-RETENTION-POLICY"


    echo "[INFO]-START-ICLOUD-BACKUP-CHECK"
    nice -n 10 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_ICLOUD check
    echo "[INFO]-END-ICLOUD-BACKUP-CHECK"    
}
#######################################################################################################################################
#######################################################################################################################################


###############
#### INIT #####
###############
if [ "$1" == "init" ]; then
  mount_nas_volume  
  restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_ICLOUD init
  restic -r $RESTIC_REPOSITORY/$BUCKET_NAME_USER init
  umount $PATH_TO_MOUNT_NAS
  exit 0
fi

#######################################################################################################################################
#######################################################################################################################################

###############
#### DEBUG ####
###############
if [ "$1" == "debug" ]; then
  echo "CAFFEINATE PID-[$caffeinate_pid]"
  echo "REPOSITORY INFO"
  echo "AWS_ACCESS_KEY_ID-[$AWS_ACCESS_KEY_ID]"
  echo "AWS_SECRET_ACCESS_KEY-[$AWS_SECRET_ACCESS_KEY]"
  echo "RESTIC_PASSWORD-[$RESTIC_PASSWORD]"
  echo "RESTIC_REPOSITORY-[$RESTIC_REPOSITORY]"
  echo "RETENTION RULE"
  echo "KEEP_HOURLY-[$KEEP_HOURLY]" 
  echo "KEEP_DAILY-[$KEEP_DAILY]"
  echo "KEEP_WEEKLY-[$KEEP_WEEKLY]"
  echo "KEEP_MONTHLY-[$KEEP_MONTHLY]"
  export GOMAXPROCS=1

  nice -n 10 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME --verbose backup --compression max  \
  $PATH_BACKUP_GITHUB                                                                      \
  $PATH_BACKUP_DOCUMENT                                                                    \
  $PATH_BACKUP_DESKTOP                                                                     \
  $PATH_BACKUP_DOWNLOAD                                                                    \
  --exclude-file=$EXCLUDE_FILE_PATH --dry-run -vv | grep "added"
  
  nice -n 10 restic -r $RESTIC_REPOSITORY/$BUCKET_NAME --verbose forget                    \
  --keep-hourly $KEEP_HOURLY                                                               \
  --keep-daily $KEEP_DAILY                                                                 \
  --keep-weekly $KEEP_WEEKLY                                                               \
  --keep-monthly $KEEP_MONTHLY                                                             \
  --prune 
  
  umount $PATH_TO_MOUNT_NAS
  kill "$caffeinate_pid"
  exit 0
fi

#######################################################################################################################################
#######################################################################################################################################



#######################
#### SCRIPT START #####
#######################

check_time
check_internet_connection
mount_nas_volume
icloud_backup
user_backup

#######################################################################################################################################
#######################################################################################################################################


kill "$caffeinate_pid"

###############
####  LOG  ####
###############
echo "[INFO]-START-CHECK-LOG-FOR-ERROR"
source $CONFIGURATION_CHECK_LOG_ERROR


#######################################################################################################################################
#######################################################################################################################################


