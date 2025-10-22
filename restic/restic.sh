#!/bin/bash

# ---- CONFIGURATION ---- #

# LOAD ENV VARIABLE FOR OFFSITE REPOSITORY
#
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# RESTIC_PASSWORD
# RESTIC_REPOSITORY
# BUCKET_NAME
source "$HOME/.config/restic/env/.repository-nas.env"

# LOAD ENV VARIABLE FOR LOCAL CONFIGURATION
#
# CONFIGURATION_ENV_OFFSITE_STORAGE_PATH
# CONFIGURATION_CHECK_LOG_ERROR
# RESTORE_FOLDER_PATH
# PATH_TO_SAVE_LOG
# PATH_TO_COPY_ERROR_LOG
source "$HOME/.config/restic/env/configuration.env"

BUCKET_NAME=""

mount_nas_volume() {
    mount_smbfs $PATH_NAS $PATH_TO_MOUNT_NAS

    if [ ! -d "$PATH_TO_MOUNT_NAS" ]; then
    echo "[INFO]-CREATE-FOLDER-TO-($PATH_TO_MOUNT_NAS)"
    mkdir -p $PATH_TO_MOUNT_NAS

    if [ $? -ne 0 ]; then
        echo "[INFO]-ABORT-BACKUP-UNABLE-TO-CREATE-FOLDER-TO-($PATH_TO_MOUNT_NAS)"
        exit 0
    fi
fi
}


print_snapshot_list () {
    menu_list=1

    while [[ $menu_list -ne 0 ]]; do
        clear
        echo "
██████╗ ███████╗███████╗████████╗██╗ ██████╗
██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║██╔════╝
██████╔╝█████╗  ███████╗   ██║   ██║██║     
██╔══██╗██╔══╝  ╚════██║   ██║   ██║██║     
██║  ██║███████╗███████║   ██║   ██║╚██████╗
╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝
Simone Margio                              
        "
        echo "# ---- Menu --- #"
        echo "1-iCloud"
        echo "2-User"
        echo "3-Offsite"
        echo '4-Log'
        echo " "
        echo "0-Exit"
        echo " "
        echo -n "-> "
        read snapshot_list_choise    

        case $snapshot_list_choise in
            "1")
                # icloud
                mount_nas_volume
                restic -r $RESTIC_REPOSITORY/icloud snapshots
                BUCKET_NAME="iCloud"
                print_snapshot_operation
                umount $PATH_TO_MOUNT_NAS
                ;; 
            "2")
                # user
                mount_nas_volume
                restic -r $RESTIC_REPOSITORY/user snapshots
                BUCKET_NAME="User"
                print_snapshot_operation
                umount $PATH_TO_MOUNT_NAS
                ;;       
            "3")
                # offsite
                source "$HOME/.config/restic/env/.repository-offsite.env"
                restic -r $RESTIC_REPOSITORY/simone-offsite snapshots
                BUCKET_NAME="simone-offsite"
                print_snapshot_operation
                source "$HOME/.config/restic/env/.repository-nas.env"
                ;;      
            "4")
                # log
                print_log_folder
                ;;    
            "0")
                menu_list=0
                ;;
        esac

    done


}

print_snapshot_operation () {
    menu_snapshot_operation=1
    while [[ $menu_snapshot_operation -ne 0 ]]; do
        echo " "
        echo "# ---- [$BUCKET_NAME] ---- #"
        echo "1-Mount"
        echo "2-Search file"
        echo "3-Show all file"
        echo "4-Show folder file"
        echo "5-Restore folder"
        echo "6-Restore file"
        echo "7-Restore snapshot"
        echo " "
        echo "8-Adavenced option"
        echo " "
        echo "0-back"
        echo " "
        echo -n "-> "
        read snapshot_list_choise    

        case $snapshot_list_choise in
            "1")
                # Mount
                if [ ! -d "$RESTORE_FOLDER_PATH/mount" ]; then
                    mkdir -p "$RESTORE_FOLDER_PATH/mount"
                fi
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME mount $RESTORE_FOLDER_PATH/mount
                ;;  
            "2")
                # Search file
                echo "Snapshot ID (es: 7fb1f5)"
                read restore_id
                echo "File name"
                read restore_file_name
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME find -s $restore_id $restore_file_name*
                ;;  
            "3")
                # Show all file
                echo "Snapshot ID (es: 7fb1f5)"
                read show_id                
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME ls $show_id
                ;; 
            "4")
                # Show folder file
                echo "Snapshot ID (es: 7fb1f5)"
                read show_id          
                echo "Path folder"
                read path_folder
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME ls $show_id $path_folder
                ;; 
            "5")
                # Restore folder
                echo "Snapshot ID:/folder (es: 7fb1f5:/work)"
                read restore_id_folder
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME restore $restore_id_folder --target $RESTORE_FOLDER_PATH/restore
                ;;   
            "6")
                # Restore file
                echo "Snapshot ID (es: 7fb1f5)"
                read restore_id
                echo "Path and file name"
                read restore_file_name
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME restore $restore_id --target $RESTORE_FOLDER_PATH/restore --include $restore_file_name
                ;;  
            "7")
                # Restore snapshot
                echo "Snapshot ID (es: 7fb1f5)"
                read restore_id
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME restore $restore_id --target $RESTORE_FOLDER_PATH/restore
                ;;     
            "8")
                # Advanced option
                print_snapshot_advanced_operation
                ;;                                     
            "0")
                clear
                menu_snapshot_operation=0
                ;;
        esac
        echo " "
    done
}


print_snapshot_advanced_operation () {
    menu_snapshot_advanced_operation=1
    
    while [[ $menu_snapshot_advanced_operation -ne 0 ]]; do
        echo " "
        echo "# ---- [$BUCKET_NAME] ---- #"
        echo "1-Delete snapshot"
        echo "2-Prune"
        echo "3-Repair repository"
        echo " "
        echo "0-back"
        echo " "
        echo -n "-> "
        read snapshot_advanced_list_choise    

        case $snapshot_advanced_list_choise in
           
            "1")
                # Delete snapshot
                echo "Snapshot ID (es: 7fb1f5) to delete"
                read delete_id                
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME forget $delete_id
                ;; 
            "2")
                # Purge
                echo "Cleanup unreferenced data"
                restic -r $RESTIC_REPOSITORY/$BUCKET_NAME prune
                ;;                                    
            "0")
                menu_snapshot_advanced_operation=0
                ;;
        esac
        echo " "
    done
    print_snapshot_operation
}


print_log_folder () {
    menu_log_folder=1

     while [[ $menu_log_folder -ne 0 ]]; do
        index=1
        echo " "
        for file in "$PATH_TO_SAVE_LOG"/*; do
            echo "$index-$(basename "$file")"
            ((index++))
        done
        echo " "
        echo "0-Back"
        echo " "
        echo -n "-> "
        read log_choise

        if [[ $log_choise == 0 ]]; then
            break
        fi

        if ! [[ "$log_choise" =~ ^[0-9]+$ ]] || [ "$log_choise" -lt 1 ] || [ "$log_choise" -ge "$index" ]; then
            echo "Invalid input. Please enter a valid number between 1 and $((index-1))."
        fi
        
        selected_folder=$(ls -1 "$PATH_TO_SAVE_LOG" | sed -n "${log_choise}p")
        selected_path="$PATH_TO_SAVE_LOG/$selected_folder"
        

        if [ -n "$selected_folder" ]; then
            if [ -d "$selected_path" ]; then
                # Enter into selected folder
                cd $selected_path
                print_log_file $selected_path
            fi
        fi
        echo " "
    done
}


print_log_file () {
    # Take $selected_path
    local path_current_log_folder=$1
    menu_log_file=1

     while [[ $menu_log_file -ne 0 ]]; do
        index=1
        echo " "
        for file in "$path_current_log_folder"/*; do
            echo "$index-$(basename "$file")"
            ((index++))
        done
        echo " "
        echo "0-Back"
        echo " "
        echo -n "-> "
        read log_choise

        if [[ $log_choise == 0 ]]; then
            break
        fi

        if ! [[ "$log_choise" =~ ^[0-9]+$ ]] || [ "$log_choise" -lt 1 ] || [ "$log_choise" -ge "$index" ]; then
            echo "Invalid input. Please enter a valid number between 1 and $((index-1))."
        fi
        
        selected_file=$(ls -1 "$path_current_log_folder" | sed -n "${log_choise}p")
        selected_path="$path_current_log_folder/$selected_file"

        if [ -f "$selected_path" ]; then
            cat "$selected_path"
        fi
        echo " "
    done
}

# ---- SCRIPT START ---- #
print_snapshot_list
clear
echo "Exit, happy backup time Simo! (▰˘◡˘▰)"