#!/bin/sh
set -e

PLIST_TEMPLATE_FILENAME="com.user.timesheet.plist.template"
PLIST_FILENAME="com.user.timesheet.plist"

SOURCE_PLIST=$PWD/$PLIST_FILENAME

if [ -f "$SOURCE_PLIST" ]; then
    echo "Existing generated plist file found..."
else
    echo "Generating initial plist file..."
    sed "s:{{current_dir}}:$PWD:g" "$PLIST_TEMPLATE_FILENAME" > "$SOURCE_PLIST"
fi

DESTINATION_PLIST=~/Library/LaunchAgents/$PLIST_FILENAME

if [ -e "$DESTINATION_PLIST" ]; then
    echo "LaunchAgent plist already installed, unloading for re-loading"
    launchctl unload "$DESTINATION_PLIST"
else
    echo "LaunchAgent plist not installed yet, creating symlink..."
    ln "$SOURCE_PLIST" "$DESTINATION_PLIST"
fi

if [ "$1" == "remove" ]; then
    echo "remove requested deleting symlink"
    rm "$DESTINATION_PLIST"
else
    echo "Loading LaunchAgent $DESTINATION_PLIST"
    launchctl load "$DESTINATION_PLIST"
fi
