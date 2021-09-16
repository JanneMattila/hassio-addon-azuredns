#!/usr/bin/env bashio
set -e

# Variables
bashio::config.require 'seconds'
bashio::config.require 'azure_ad.tenant_id'
bashio::config.require 'azure_ad.client_id'
bashio::config.require 'azure_ad.client_secret'
bashio::config.require 'dns_zone_id'
bashio::config.require 'record_type'
bashio::config.require 'record_name'

SECONDS=$(bashio::config 'seconds')
if test "$SECONDS" -lt 10; then
    PREVIOUS_SECONDS=$SECONDS
    SECONDS=10
    bashio::log.warning "Changing the update frequency to $SECONDS seconds from $PREVIOUS_SECONDS."
fi

AAD_TENANT_ID=$(bashio::config 'azure_ad.tenant_id')
AAD_CLIEND_ID=$(bashio::config 'azure_ad.client_id')
AAD_CLIEND_SECRET=$(bashio::config 'azure_ad.client_secret')

DNS_ZONE_ID=$(bashio::config 'dns_zone_id')
RECORD_TYPE=$(bashio::config 'record_type')
RECORD_NAME=$(bashio::config 'record_name')

RESOURCE_ID=$DNS_ZONE_ID/$RECORD_TYPE/$RECORD_NAME

while true; do
    bashio::log.info "Azure DNS Zone updater check starting..."

    MY_IP=$(curl --no-progress-meter https://api.ipify.org)
    bashio::log.info "Current public IP: $MY_IP"

    BODY="client_id=$AAD_CLIEND_ID&client_secret=$AAD_CLIEND_SECRET&scope=https://management.azure.com/.default&grant_type=client_credentials"
    ACCESS_TOKEN=$(curl --no-progress-meter -H "Content-Type: application/x-www-form-urlencoded" --data "$BODY" "https://login.microsoftonline.com/$AAD_TENANT_ID/oauth2/v2.0/token" | jq -r .access_token)
    CURRENT_IP=$(curl --no-progress-meter -H "Authorization: Bearer $ACCESS_TOKEN" "https://management.azure.com$RESOURCE_ID?api-version=2018-05-01" | jq -r .properties.ARecords[0].ipv4Address)
    bashio::log.info "Current IP in DNS Zone: $CURRENT_IP"

    if test "$CURRENT_IP" = "$MY_IP"; then
        bashio::log.info "IP address match, so no need to update DNS Zone"
    else
        bashio::log.info "DNS Zone update is required due to updated public IP address"
        # https://docs.microsoft.com/en-us/rest/api/dns/record-sets/update#patch-a-recordset
        PATCH_BODY="{ \"properties\": { \"ARecords\": [ { \"ipv4Address\": \"$MY_IP\" } ] } }"
        STATUS=$(curl -X PATCH --no-progress-meter -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" --data "$PATCH_BODY" "https://management.azure.com$RESOURCE_ID?api-version=2018-05-01" | jq -r .properties.provisioningState)
        bashio::log.info "IP Update state: $STATUS"
    fi

    sleep "$SECONDS"
done