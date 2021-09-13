#!/usr/bin/with-contenv bashio

# Variables
AAD_TENANT_ID="<your_tenant_id>"
AAD_CLIEND_ID="<your_app_id>"
AAD_CLIEND_SECRET="<your_app_secret>"

DNS_ZONE_ID="/subscriptions/<your_sub_id>/resourceGroups/<your_rg>/providers/Microsoft.Network/dnszones/<your_dns_zone>"
RECORD_TYPE="A"
RECORD_NAME="demo1"
RESOURCE_ID=$DNS_ZONE_ID/$RECORD_TYPE/$RECORD_NAME

###########################################################
# Note: You need to make sure correct permissions have been
# given for the service principal to update DNZ Zone record:
# az role assignment create --role "DNS Zone Contributor" --assignee $AAD_CLIEND_ID --scope $RESOURCE_ID
###########################################################

export MY_IP=$(curl --no-progress-meter https://api.ipify.org)
echo "Current public IP: $MY_IP"

BODY="client_id=$AAD_CLIEND_ID&client_secret=$AAD_CLIEND_SECRET&scope=https://management.azure.com/.default&grant_type=client_credentials"
ACCESS_TOKEN=$(curl --no-progress-meter -H "Content-Type: application/x-www-form-urlencoded" --data $BODY "https://login.microsoftonline.com/$AAD_TENANT_ID/oauth2/v2.0/token" | jq -r .access_token)
CURRENT_IP=$(curl --no-progress-meter -H "Authorization: Bearer $ACCESS_TOKEN" "https://management.azure.com$RESOURCE_ID?api-version=2018-05-01" | jq -r .properties.ARecords[0].ipv4Address)
echo "Current IP in DNS Zone: $CURRENT_IP"

if test "$CURRENT_IP" = "$MY_IP"; then
    echo "IP address match, so no need to update DNS Zone"
else
    echo "DNS Zone update is required due to updated public IP address"
    # https://docs.microsoft.com/en-us/rest/api/dns/record-sets/update#patch-a-recordset
    PATCH_BODY="{ \"properties\": { \"ARecords\": [ { \"ipv4Address\": \"$MY_IP\" } ] } }"
    STATUS=$(curl -X PATCH --no-progress-meter -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" --data "$PATCH_BODY" "https://management.azure.com$RESOURCE_ID?api-version=2018-05-01" | jq -r .properties.provisioningState)
    echo "IP Update state: $STATUS"
fi
