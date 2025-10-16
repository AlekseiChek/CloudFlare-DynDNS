:global theinterface "ether1"
:global hostname "subdomain.example.net"
:global cfApiToken "YOUR_TOKEN"
:global cfZoneId "ZONE_ID"
:global cfRecordId "RECORD_ID"

# get IP with mask from wan interface
:global ipfresh [/ip address get [/ip address find interface=$theinterface] address]

# check if found
:if ([:typeof $ipfresh] = nil) do={
    :log warning ("No IP address on " . $theinterface)
} else={
    # remove /mask
    :local slashPos [:find $ipfresh "/"]
    :if ($slashPos != nil) do={
        :set ipfresh [:pick $ipfresh 0 $slashPos]
    }

    # resolve hostname
    :local resolved ""
    :do {
        :set resolved [:resolve $hostname]
    } on-error={
        :set resolved "unresolved"
    }

    # print both to log
    :log info ("Interface " . $theinterface . " IP: " . $ipfresh)
    :log info ("Resolved " . $hostname . " -> " . $resolved)

    # Compare IPs and update if different
    :if ($resolved != "unresolved" && $resolved != $ipfresh) do={
        :log info ("IP change detected: Local $ipfresh vs DNS $resolved - Updating Cloudflare")
        
        # Single-line fetch command that we know works
        /tool fetch url="https://api.cloudflare.com/client/v4/zones/$cfZoneId/dns_records/$cfRecordId" http-method=put http-data="{\"type\":\"A\",\"name\":\"$hostname\",\"content\":\"$ipfresh\",\"ttl\":120,\"proxied\":false}" http-header-field="Authorization: Bearer $cfApiToken, Content-Type: application/json" output=user
        :log info "Cloudflare update completed"
        
    } else={
        :if ($resolved = $ipfresh) do={
            :log info "No change needed - IP matches DNS record"
        } else={
            :log warning "Could not resolve $hostname for comparison"
        }
    }
}
