#!/usr/bin/env bash
#
# validate.sh – Validate a FHIR resource against a profile using the local
# Matchbox instance.
#
# Usage:
#   ./validate.sh <file.json> [profile-url]
#
# Examples:
#   ./validate.sh examples/patient-se-base.json
#   ./validate.sh examples/patient-se-base.json http://hl7.se/fhir/ig/base/StructureDefinition/SEBasePatient
#
set -euo pipefail

BASE_URL="${MATCHBOX_URL:-http://localhost:8080/matchboxv3/fhir}"
FILE="${1:?Usage: $0 <file.json> [profile-url]}"
PROFILE="${2:-}"

if [[ ! -f "$FILE" ]]; then
  echo "Error: file '$FILE' not found." >&2
  exit 1
fi

# Determine content type from extension
case "$FILE" in
  *.xml) CONTENT_TYPE="application/fhir+xml" ;;
  *)     CONTENT_TYPE="application/fhir+json" ;;
esac

# Build the URL
URL="${BASE_URL}/\$validate"
if [[ -n "$PROFILE" ]]; then
  URL="${URL}?profile=${PROFILE}"
fi

echo "▶ Validating: $FILE"
[[ -n "$PROFILE" ]] && echo "  Profile:    $PROFILE"
echo "  Endpoint:   $URL"
echo ""

curl -s -X POST "$URL" \
  -H "Content-Type: ${CONTENT_TYPE}" \
  -H "Accept: application/fhir+json" \
  -d @"$FILE" | python3 -m json.tool

echo ""
