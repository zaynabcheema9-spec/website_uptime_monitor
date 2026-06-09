#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/1512163442885263552/sz7vS0PT2zky9b8a9NnpgUle78ZkVRs-x_EOMzKRBCGKgiCeKYjSXjaotSdwcu0j-52X"
WEBSITES_FILE="websites.txt"
LOG_FILE="website-log.txt"

CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: DISCORD_WEBHOOK_URL is not set."
    exit 1
fi

if [ ! -f "$WEBSITES_FILE" ]; then
    echo "Error: websites.txt file not found."
    exit 1
fi

TOTAL_CHECKS=0
UP_COUNT=0
DOWN_COUNT=0

while IFS= read -r WEBSITE_URL || [ -n "$WEBSITE_URL" ]
do
    WEBSITE_URL=$(echo "$WEBSITE_URL" | tr -d '\r')

    if [ -z "$WEBSITE_URL" ]; then
        continue
    fi

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    HTTP_CODE=$(curl -L -o /dev/null -s -w "%{http_code}" "$WEBSITE_URL")

    if [ "$HTTP_CODE" = "200" ]; then
        STATUS="UP"
        UP_COUNT=$((UP_COUNT + 1))
    else
        STATUS="DOWN"
        DOWN_COUNT=$((DOWN_COUNT + 1))

        ALERT_MESSAGE="ALERT | Website: $WEBSITE_URL | Status: DOWN | HTTP Code: $HTTP_CODE | Time: $CURRENT_TIME"

        jq -n --arg content "$ALERT_MESSAGE" '{content: $content}' | \
        curl -s -H "Content-Type: application/json" \
        -d @- \
        "$WEBHOOK_URL"
    fi

    echo "$CURRENT_TIME | $WEBSITE_URL | $STATUS | $HTTP_CODE" >> "$LOG_FILE"

done < "$WEBSITES_FILE"

if [ "$TOTAL_CHECKS" -gt 0 ]; then
    UPTIME=$(awk "BEGIN {printf \"%.2f\", ($UP_COUNT/$TOTAL_CHECKS)*100}")
else
    UPTIME="0"
fi

SUMMARY_MESSAGE="DAILY REPORT | Total Websites: $TOTAL_CHECKS | UP: $UP_COUNT | DOWN: $DOWN_COUNT | Overall Uptime: $UPTIME% | Time: $CURRENT_TIME"

curl -X POST "$WEBHOOK_URL" \
-H "Content-Type: application/json" \
--data-raw "{\"content\":\"$SUMMARY_MESSAGE\"}"

echo "Monitoring completed. Total: $TOTAL_CHECKS, UP: $UP_COUNT, DOWN: $DOWN_COUNT"