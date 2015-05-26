#!/bin/bash

# Icecast listening script 0.3
# Author: Spencer Wohlers
# Last updated: 2015-05-21

# This script allows you to check if IC is currently streaming. If it's not,
# then the script continues to check the server every $CHECK_INTERVAL seconds
# until the server comes online. If we're running on OS X, it sends a
# Notification Center notification that the server is online and quits.

# If you click the Notification Center notification, it will open a web browser
# to the stream URL so you can listen live.

# REQUIRES: curl
# RECOMMENDED: terminal-notifier for customized notifications.

NOTIFICATION_TITLE_EN_US="Live Stream Now Online"
NOTIFICATION_GROUP_EN_US="Live Streaming"
REDIRECT_EN_US="Redirect in place. Please provide a different URL."
OTHER_URL_EN_US="Perhaps try this URL instead:"
NO_RESPONSE_EN_US="No response received."
SERVICE_FILE_MISSING_EN_US="Sorry, I can't find that service file."
USAGE_EN_US="\nPlease select a service. Usage:\n
/notify.sh <servicename>\n\n
The file <servicename> should have the following defined:\n
STREAM_ADDRESS=<address to listen>\n
CHECK_INTERVAL=<interval, in seconds>\n
STREAMING_EN_US=<message, if streaming>\n
OFFLINE_EN_US=<message, if offline>\n
SERVICE_ICON_NAME=<path to service icon>\n"

LAST_HTTP_STATUS=""
CONTINUE_EXECUTION="1"
TERMINAL_NOTIFIER=`which terminal-notifier`
OSASCRIPT=`which osascript`
VLC_PATH="/Applications/VLC.app/Contents/MacOS/VLC"

# Let's get the parameters
if [ $# -gt 0 ]
then
	if [ -e $1 ]
	then
		source "$1"
	else
		echo $SERVICE_FILE_MISSING_EN_US
		exit -1
	fi
else
	echo -e $USAGE_EN_US
	exit -1
fi

# Main while loop.
while [ "$CONTINUE_EXECUTION" == "1" ]
do
    # Sleep, but not on the first loop.
    if [ "$LAST_HTTP_STATUS" != "" ]
    then
        sleep $CHECK_INTERVAL
    fi

    HTTP_STATUS=`curl -s --max-time 1 -o /dev/null -w "%{http_code}\n" "$STREAM_ADDRESS"`
    CURRENT_TIME=`date +%H:%M:%S`
    
    # HTTP STATUS 200 == "OK"
    # This means we're online and streaming. Check twice this is the case, then display a notification.
    if [ "$HTTP_STATUS" == "200" ]
    then
    
        # Let's make sure that wasn't a fluke.
        if [ "$LAST_HTTP_STATUS" == "200" ]
        then
            echo "$CURRENT_TIME: $STREAMING_EN_US"
            CONTINUE_EXECUTION="0"
            if [ "$TERMINAL_NOTIFIER" == "" ]
            then
                if [ "$OSASCRIPT" != "" ]
                then
                    $OSASCRIPT -e "display notification \"$STREAMING_EN_US\" with title \"$NOTIFICATION_TITLE_EN_US\""
                fi
            else
                if [ -e "$VLC_PATH" ]
                then
                    $TERMINAL_NOTIFIER -group "$NOTIFICATION_GROUP_EN_US" -title "$NOTIFICATION_TITLE_EN_US" -message "$STREAMING_EN_US" -execute "$VLC_PATH \"$STREAM_ADDRESS\"" -appIcon "$SERVICE_ICON_NAME"
                else
                    $TERMINAL_NOTIFIER -group "$NOTIFICATION_GROUP_EN_US" -title "$NOTIFICATION_TITLE_EN_US" -message "$STREAMING_EN_US" -open "$STREAM_ADDRESS" -appIcon "$SERVICE_ICON_NAME"
                fi
            fi
        fi
    
    # Any other kind of response means we're not streaming and don't need to send a notification.
    
    # HTTP STATUS 404 == "Not Found"
    elif [ "$HTTP_STATUS" == "404" ]
    then
        echo "$CURRENT_TIME: $OFFLINE_EN_US"
        
    # HTTP STATUS 301 == "Moved Permanently"
    # HTTP STATUS 302 == "Found", at another location
    elif [ "$HTTP_STATUS" == "301" ] || [ "$HTTP_STATUS" == "302" ]
    then
        echo "$CURRENT_TIME: $REDIRECT_EN_US"
        
        # Attempt to give the new location
        NEW_LOCATION=`curl -L -s --max-time 5 -o /dev/null -w "%{url_effective}\n" "$STREAM_ADDRESS"`
        echo "$OTHER_URL_EN_US: $NEW_LOCATION"
        
        CONTINUE_EXECUTION="0"
        
    # HTTP STATUS 302, 000, etc.
    else
        echo "$CURRENT_TIME: $NO_RESPONSE_EN_US"
    fi
    
    LAST_HTTP_STATUS=$HTTP_STATUS
done

exit 0