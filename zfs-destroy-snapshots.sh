#! /bin/bash

# Define variables.
export PARENT_PID=$$
DATASET=$1
ZPOOL=$(printf "$DATASET" | awk -F'/' '{print $1}')

# Pretty styling
RED="\u001b[31;1m"
WHITE="\u001b[37m"
GREY="\u001b[30;1m"
UNDERLINE="\033[4m"
CLEAR="\033[0m"

# Temporarily set zpool property `listsnapshots=on`
LISTSNAPSHOTS_PREV=$(zpool get -o value -Hp listsnapshots amalgm)
zpool set listsnapshots=on "$ZPOOL"

echo $LISTSNAPSHOTS

# On error, warn user then exit parent process.
function paramsError {
	printf "$RED"
	printf 'ERROR: $1 is unset or empty\n'
	printf "$WHITE"
	printf 'Example: `zfs-destroy-snapshots.sh tank/Downloads`\n'
	printf "$CLEAR"
	kill -s TERM $PARENT_PID
}

# On call, cleanly exit the script.
function cleanExit {
	# Return zpool property `listsnapshots` to original setting
	zpool set listsnapshots="$LISTSNAPSHOTS_PREV" "$ZPOOL"
	printf "$CLEAR"
	kill -s TERM $PARENT_PID
	exit # Just in case
}

# Ensure $1 and $2 are set; otherwise exit.
test -n "$1"     || paramsError
test "$1" != " " || paramsError

# Ensure both the pool and dataset exist.
zfs list -H -o name -t snapshot "$DATASET" >> /dev/null || cleanExit

# Warn the user before they do something stupid.
#####clear
printf " #####################################  $RED WARNING $WHITE  ################################### \n"
printf "$UNDERLINE The following snapshots for dataset $RED$DATASET$WHITE in zpool $RED$ZPOOL$WHITE will be destroyed: $CLEAR \n"
zfs list -o name,used -t snapshot "$DATASET"
echo -n " -- TOTAL "
zfs list -H -o usedbysnapshots "$DATASET"

# Prompt the user; are you SURE you want to risk doing something stupid?
printf "$RED"
read -p "Destroy all of the above snapshots? (y) " -n 1 -r
printf "$RED"
printf '\n'

# If input is 'y' or 'Y', proceed with destroying listed snapshots.
if [[ $REPLY =~ ^[Yy]$ ]]
then
	printf "$GREY"
	clear
	zfs list -H -o name -t snapshot "$DATASET" | xargs -t -P4 --replace=@ zfs destroy '@'
	cleanExit
# Otherwise, abandon ship!
else
	printf "Okay, nevermind then. Bye!\n"
	cleanExit
fi
