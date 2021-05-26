require "httparty"

url = "https://lngnoticeboard.onegov.nsw.gov.au/lngnoticeboard/v1/applicationsearch/perform"

# Get the applications from the last 28 days
end_date = Date.today
start_date = end_date - 28

query = {
  "paginationCriteria": {
    "currentPage": 1,
    "pageSize": 25
  },
  "type": "Advanced",
  "criteria": [
    {
      "type": "PostedDate",
      "condition": {
        "start": start_date.to_s,
        "end": end_date.to_s
      }
    }
  ]
}

pp HTTParty.post(
  url,
  body: query.to_json,
  headers: {"Content-Type" => "application/json"}
)
