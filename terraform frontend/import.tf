# Import existing Cloudflare records if they exist
# This file helps handle cases where DNS records already exist

# To import existing records, run:
# terraform import 'cloudflare_record.cert_validation["vetrii.vetrii.com"]' <zone_id>/<record_id>

# You can find the zone ID using:
# curl -X GET "https://api.cloudflare.com/client/v4/zones" \
#   -H "Authorization: Bearer <api_token>" \
#   -H "Content-Type: application/json"

# You can find the record ID using:
# curl -X GET "https://api.cloudflare.com/client/v4/zones/<zone_id>/dns_records" \
#   -H "Authorization: Bearer <api_token>" \
#   -H "Content-Type: application/json"

# Example import commands (replace with actual values):
# terraform import 'cloudflare_record.cert_validation["vetrii.vetrii.com"]' zoneID/recordID
# terraform import 'cloudflare_record.cert_validation["staging-vetrii.vetrii.com"]' zoneID/recordID 