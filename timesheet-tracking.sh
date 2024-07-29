#!/bin/sh
set -e

# This is based on https://stackoverflow.com/a/66723000
function screenIsLocked { [ "$(/usr/libexec/PlistBuddy -c "print :IOConsoleUsers:0:CGSSessionScreenIsLocked" /dev/stdin 2>/dev/null <<< "$(ioreg -n Root -d1 -a)")" = "true" ] && return 0 || return 1; }
function screenIsUnlocked { [ "$(/usr/libexec/PlistBuddy -c "print :IOConsoleUsers:0:CGSSessionScreenIsLocked" /dev/stdin 2>/dev/null <<< "$(ioreg -n Root -d1 -a)")" != "true" ] && return 0 || return 1; }

# This comes from https://community.jamf.com/t5/jamf-pro/check-if-screen-is-locked-in-a-script/m-p/116688
IDLE_TIME=$((`ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' -e 's/.* = //g' -e 'q'` / 1000000000))

TIME_LOG_FILE=~/timesheet.csv

if [ ! -f "$TIME_LOG_FILE" ]; then
    echo "Date,Time,Status" > "$TIME_LOG_FILE"
fi

DATE=$(date -I)
TIME=$(date +%H:%M)

LAST_LINE=$(tail -n 1 "$TIME_LOG_FILE")

LAST_DATE=$(cut -d',' -f1 <<< $LAST_LINE)
LAST_STATUS=$(cut -d',' -f3 <<< $LAST_LINE)

USER_IS_IDLE=$([ $IDLE_TIME -gt 300 ] && echo true || echo false)

echo ""
echo "Current date: $DATE"
echo "Current time: $TIME"
echo "Last date: $LAST_DATE"
echo "Last status: $LAST_STATUS"
echo "Current idle time: $IDLE_TIME"
echo "User is idle: $USER_IS_IDLE"

if [ "$DATE" != "$LAST_DATE" ]; then
    if screenIsLocked || [ $USER_IS_IDLE = true ] ; then
        echo "New day but user inactive, aborting..."
        exit 0
    else
        echo "New day and user active, writing..."
        echo "$DATE,$TIME,Unlocked" >> "$TIME_LOG_FILE"
        exit 0
    fi
fi

if screenIsLocked; then
    echo "Screen is locked..."
    if [ "$LAST_STATUS" != "Locked" ]; then
        echo "Last entry was unlocked, writing..."
        echo "$DATE,$TIME,Locked" >> "$TIME_LOG_FILE"
    else
        echo "Last entry was locked, skipping..."
    fi
elif screenIsUnlocked; then
    echo "Screen is unlocked..."
    if [ "$LAST_STATUS" != "Unlocked" ]; then
        echo "Last entry was locked, writing..."
        echo "$DATE,$TIME,Unlocked" >> "$TIME_LOG_FILE"
    else
        echo "Last entry was unlocked, skipping..."
    fi
fi
