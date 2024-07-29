#!/bin/bash
set -e

# This is based on https://stackoverflow.com/a/66723000
function screenIsLocked { [ "$(/usr/libexec/PlistBuddy -c "print :IOConsoleUsers:0:CGSSessionScreenIsLocked" /dev/stdin 2>/dev/null <<< "$(ioreg -n Root -d1 -a)")" = "true" ] && return 0 || return 1; }
function screenIsUnlocked { [ "$(/usr/libexec/PlistBuddy -c "print :IOConsoleUsers:0:CGSSessionScreenIsLocked" /dev/stdin 2>/dev/null <<< "$(ioreg -n Root -d1 -a)")" != "true" ] && return 0 || return 1; }

# This comes from https://community.jamf.com/t5/jamf-pro/check-if-screen-is-locked-in-a-script/m-p/116688
IDLE_TIME=$((`ioreg -c IOHIDSystem | sed -e '/HIDIdleTime/ !{ d' -e 't' -e '}' -e 's/.* = //g' -e 'q'` / 1000000000))

TIME_LOG_FILE="${1:-$PWD/timesheet.csv}"

echo ""
echo "Writing timesheet file to $TIME_LOG_FILE"

if [ ! -f "$TIME_LOG_FILE" ]; then
    echo "Date,Session Start,Session End" > "$TIME_LOG_FILE"
fi

DATE=$(date -I)
TIME=$(date +%H:%M)

LAST_LINE=$(tail -n 1 "$TIME_LOG_FILE")

IFS=',' read -r -a LINE_PARTS <<< "$LAST_LINE"

LAST_DATE="${LINE_PARTS[0]}"

USER_IS_IDLE=$([ $IDLE_TIME -gt 300 ] && echo true || echo false)

LAST_SESSION_STATUS="Unknown"
if [ ${#LINE_PARTS[@]} == 2 ]; then
    LAST_SESSION_STATUS="Open"
elif [ ${#LINE_PARTS[@]} == 3 ]; then
    LAST_SESSION_STATUS="Ended"
fi

echo "Current date: $DATE"
echo "Current time: $TIME"
echo "Last date: $LAST_DATE"
echo "Last session status: $LAST_SESSION_STATUS"
echo "Current idle time: $IDLE_TIME"
echo "User is idle: $USER_IS_IDLE"

if screenIsLocked; then
    echo "Screen is locked..."
    if [ "$LAST_SESSION_STATUS" != "Ended" ] && [ "$DATE" == "$LAST_DATE" ]; then
        echo "Last session still open, writing..."
        echo ",$TIME" >> "$TIME_LOG_FILE"
    else
        echo "Last session already marked as ended, skipping..."
    fi
elif screenIsUnlocked; then
    echo "Screen is unlocked..."
    if [ "$LAST_SESSION_STATUS" != "Open" ]; then
        echo "Last session ended, writing..."
        echo -n "$DATE,$TIME" >> "$TIME_LOG_FILE"
    elif [ "$LAST_DATE" != "$DATE" ]; then
        echo "Last session was on different date, writing..."
        echo "" >> "$TIME_LOG_FILE"
        echo -n "$DATE,$TIME" >> "$TIME_LOG_FILE"
    else
        echo "Last session still open, skipping..."
    fi
fi
