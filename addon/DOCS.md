# Docs

Note: You need to make sure correct permissions have been
given for the service principal to update DNZ Zone record:

```bash
DNS_ZONE_ID="<your domain here>"
RECORD_TYPE="A"
RECORD_NAME="demo1"
RESOURCE_ID=$DNS_ZONE_ID/$RECORD_TYPE/$RECORD_NAME
echo $RESOURCE_ID

# Resource Id should be something similar to this:
# /subscriptions/<your_sub_id>/resourceGroups/<your_rg>/providers/Microsoft.Network/dnszones/<your_dns_zone>"
az role assignment create --role "DNS Zone Contributor" --assignee $AAD_CLIEND_ID --scope $RESOURCE_ID
```
