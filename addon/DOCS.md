# Home Assistant Add-on: Azure DNS Zone updater

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "Azure DNS Zone updater" add-on and click it.
3. Click on the "INSTALL" button.

## How to use

You need to have access to Azure DNS Zone and you should be
able to make [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals) to you Azure AD tenant.

Service principal requires permissions to the target
Azure DNS Zone resource in order to update the IP address to the
selected record.

Here is example [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) example how to set up the permissions:

```bash
# Your Client ID of the app registration
AAD_CLIEND_ID="<client id here>"

# Copy your Azure DNS Zone Resource ID here:
DNS_ZONE_ID="/subscriptions/<your_sub_id>/resourceGroups/<your_rg>/providers/Microsoft.Network/dnszones/<your_dns_zone>"
RECORD_TYPE="A"
RECORD_NAME="demo1"
RESOURCE_ID=$DNS_ZONE_ID/$RECORD_TYPE/$RECORD_NAME

# Create role assingment
az role assignment create --role "DNS Zone Contributor" --assignee $AAD_CLIEND_ID --scope $RESOURCE_ID
```

## Configuration

Following configuration parameters are required:

```yaml
seconds: 3600
aad_tenant_dd: "<your_tenant_id>"
aad_client_id: "<your_app_id>"
aad_client_secret: "<your_app_secret>"
dns_zone_id: "/subscriptions/<your_sub_id>/resourceGroups/<your_rg>/providers/Microsoft.Network/dnszones/<your_dns_zone>"
record_type: "A"
record_name: "demo1"
```

Configuration with example values for `homeassistant.contoso.com`:

```yaml
seconds: 3600
aad_tenant_dd: "41476b44-ef0d-4e69-b957-04ed8f1dfc04"
aad_client_id: "55676858-5756-4718-b0bd-22e10c2451d3"
aad_client_secret: "~05T0a3D1qRPs..4FML7NH6O.Kv~aMfKTQ"
dns_zone_id: "/subscriptions/7752d7ac-47a0-43aa-9d43-e7329e5be325/resourceGroups/rg-domain/providers/Microsoft.Network/dnszones/contoso.com"
record_type: "A"
record_name: "homeassistant"
```
