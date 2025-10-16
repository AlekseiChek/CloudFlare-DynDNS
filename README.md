# Cloudflare Dynamic DNS on MikroTik (RouterOS) — Full Guide

Keep your **Cloudflare A-record** automatically updated with your MikroTik router's WAN IP. This document explains all prerequisites, how to retrieve required IDs, and how to deploy the update script.

---

## 🧩 Prerequisites

Before using the script, make sure you’ve completed the following:

✅ **Created a Zone** (e.g., yourdomain.net)

✅ **Created an FQDN A-record** (e.g., subdomain.yourdomain.net)

✅ **Created an API Token** for your zone with at least **Zone → DNS → Edit** permission

You will also need to retrieve:

✅ **Zone ID**
✅ **FQDN (A-record) ID**

---

## 🔍 Retrieve Zone ID

### Linux (with curl + jq)

```bash
curl -fsS -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones?name=YOUR_DOMAIN" | jq '.result[] | {name,id}'
```

### MikroTik CLI

```rsc
/tool fetch url="https://api.cloudflare.com/client/v4/zones?name=YOUR_DOMAIN" \
  http-method=get \
  http-header-field="Authorization: Bearer YOUR_TOKEN, Content-Type: application/json" \
  output=user
```

This will print the JSON output directly to your MikroTik terminal. Look for the `id` value inside the result object — that’s your Zone ID.

---

## 🔎 Retrieve FQDN A-record ID

### Linux (with curl + jq)

```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records?per_page=100" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" | jq '.result[] | {name,id}'
```

### MikroTik CLI

```rsc
/tool fetch url="https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records?per_page=100" \
  http-method=get \
  http-header-field="Authorization: Bearer YOUR_TOKEN, Content-Type: application/json" \
  output=user
```

This command lists all DNS records in your zone. Find your FQDN and note its `id` value.

---

## 🏗️ (Optional) Create a New FQDN Record via API

If you want to create a new A-record (instead of reusing an existing one):

### Linux example

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "subdomain.yourdomain.net",
    "content": "1.2.3.4",
    "ttl": 120,
    "proxied": false
  }'
```

### MikroTik equivalent

```rsc
:global cfApiToken "YOUR_TOKEN"
:global cfZoneId "YOUR_ZONE_ID"
:global newFqdn "subdomain.yourdomain.net"
:global ipaddr "1.2.3.4"

/tool fetch url="https://api.cloudflare.com/client/v4/zones/$cfZoneId/dns_records" \
  http-method=post \
  http-data="{\"type\":\"A\",\"name\":\"$newFqdn\",\"content\":\"$ipaddr\",\"ttl\":120,\"proxied\":false}" \
  http-header-field="Authorization: Bearer $cfApiToken, Content-Type: application/json" \
  output=user
```

The API will return a JSON response containing the new record’s ID.

---

## ⚙️ What the DDNS Script Does

The **MikroTik DDNS script** automatically:

* Reads the IPv4 address from your chosen interface (e.g., `ether1`)
* Resolves your FQDN and compares it with the current IP
* Updates the Cloudflare A-record via API if the IP has changed
* Logs operations and results to RouterOS system log

---

## 🧰 Example Configuration Variables

```rsc
:global theinterface "ether1"
:global hostname "subdomain.yourdomain.net"
:global cfApiToken "YOUR_CLOUDFLARE_TOKEN"
:global cfZoneId "YOUR_ZONE_ID"
:global cfRecordId "YOUR_FQDN_RECORD_ID"
```

---

## 🚀 Deployment Steps

1. **Create the script** in MikroTik:

   * WinBox/WebFig → System → Scripts → Add
   * Name: `cloudflare-ddns`
   * Paste the script (after editing variables)

2. **Test manually:**

   ```rsc
   /system script run cloudflare-ddns
   ```

   Check the **log** for success messages or errors.

3. **Schedule it automatically (e.g., every 5 min):**

   ```rsc
   /system scheduler add name=cloudflare-ddns interval=5m on-event=cloudflare-ddns
   ```

---

## 🧱 Tips & Troubleshooting

* If output says **“No IP address on ether1”**, your WAN interface name might differ.
* If **nothing changes**, check the logs — the IP may already match DNS.
* To debug API errors, temporarily set `output=file` and open the JSON response.

Example:

```rsc
/tool fetch ... output=file dst-path=cf_debug.json
/file print where name~"cf_debug.json"
```

---

## 🔒 Security Notes

* Store API tokens securely — don’t export them in backups.
* Use restricted tokens (only DNS Edit for your zone).
* Set `proxied=false` unless you want Cloudflare’s orange-cloud proxy.

---

## ✅ Summary

| Task          | Action                              | Tool          |
| ------------- | ----------------------------------- | ------------- |
| Get Zone ID   | `GET /zones?name=...`               | curl or fetch |
| Get Record ID | `GET /zones/<ZONE_ID>/dns_records`  | curl or fetch |
| Create Record | `POST /zones/<ZONE_ID>/dns_records` | curl or fetch |
| Update Record | Script does this automatically      | MikroTik      |

---

Author: **Alex**
License: MIT
Version: v1.0 — Cloudflare Dynamic DNS automation for MikroTik RouterOS
