curl -X 'GET' \
  'https://snowstorm.snomedtools.org/snowstorm/snomed-ct/MAIN/concepts/45389009/descendants?stated=false&offset=0&limit=200' \
  -H 'accept: application/json' \
  -H 'Accept-Language: en-X-900000000000509007,en-X-900000000000508004,en' | jq -r ".items | .[] | [.conceptId, .pt.term] | @csv"
