#!/bin/bash

# Relay listening script 0.1
# Author: Spencer Wohlers
# Last updated: 2015-05-05

# This script allows you to check if Relay is currently streaming. If it's not,
# then the script continues to check the server every $CHECK_INTERVAL seconds
# until the server comes online. If we're running on OS X, it sends a
# Notification Center notification that the server is online and quits.

# If you click the Notification Center notification, it will open a web browser
# to the stream URL so you can listen live.

# REQUIRES: curl
# RECOMMENDED: terminal-notifier for customized notifications.

# YOU MAY EDIT THESE VALUES:
STREAM_ADDRESS="http://amp.relay.fm:8000/stream"
CHECK_INTERVAL=2

NOTIFICATION_TITLE_EN_US="Live Stream Now Online"
NOTIFICATION_GROUP_EN_US="Live Streaming"
RELAY_STREAMING_EN_US="Relay.FM is now streaming."
RELAY_OFFLINE_EN_US="Relay.FM is offline."
REDIRECT_EN_US="Redirect in place. Please provide a different URL."
OTHER_URL_EN_US="Perhaps try this URL instead:"
NO_RESPONSE_EN_US="No response received."
SERVICE_ICON_NAME="relayfm.png"

# TRY NOT TO EDIT ANYTHING BELOW THIS LINE:
LAST_HTTP_STATUS=""
CONTINUE_EXECUTION="1"
TERMINAL_NOTIFIER=`which terminal-notifier`
OSASCRIPT=`which osascript`

# Main while loop
while [ "$CONTINUE_EXECUTION" == "1" ]
do
    sleep $CHECK_INTERVAL

    HTTP_STATUS=`curl -s --max-time 1 -o /dev/null -w "%{http_code}\n" "$STREAM_ADDRESS"`
    CURRENT_TIME=`date +%H:%M:%S`
    
    # HTTP STATUS 200 == "OK"
    if [ "$HTTP_STATUS" == "200" ]
    then
    
        # Let's make sure that wasn't a fluke.
        if [ "$LAST_HTTP_STATUS" == "200" ]
        then
            echo "$CURRENT_TIME: $RELAY_STREAMING_EN_US"
            CONTINUE_EXECUTION="0"
            if [ "$TERMINAL_NOTIFIER" == "" ]
            then
                if [ "$OSASCRIPT" != "" ]
                then
                    osascript -e "display notification \"$RELAY_STREAMING_EN_US\" with title \"$NOTIFICATION_TITLE_EN_US\""
                fi
            else
                $TERMINAL_NOTIFIER -group "$NOTIFICATION_GROUP_EN_US" -title "$NOTIFICATION_TITLE_EN_US" -message "$RELAY_STREAMING_EN_US" -open "$STREAM_ADDRESS" -appIcon "$SERVICE_ICON_NAME"
            fi
        fi
    
    # HTTP STATUS 404 == "Not Found"
    elif [ "$HTTP_STATUS" == "404" ]
    then
        echo "$CURRENT_TIME: $RELAY_OFFLINE_EN_US"
        
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