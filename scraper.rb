require "httparty"

url = "https://lngnoticeboard.onegov.nsw.gov.au/lngnoticeboard/v1/applicationsearch/perform"

# Get the applications from the last 28 days
end_date = Date.today
start_date = end_date - 28

def convert_date(text)
  Date.strptime(text, "%d/%m/%Y").to_s
end

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

result = HTTParty.post(
  url,
  body: query.to_json,
  headers: {"Content-Type" => "application/json"}
)

result["results"].each do |application|
  council_reference = application["application"]
  record = {
    "council_reference" => council_reference,
    "address" => application["address"],
    "description" => application["type"],
    "info_url" => "https://lngnoticeboard.onegov.nsw.gov.au/searchresult/details/#{council_reference}",
    "date_scraped" => Date.today.to_s,
    "date_received" => convert_date(application["posted"]),
    "on_notice_to" => convert_date(application["submissionClose"]),
    "latitude" => application["latitude"],
    "longitude" => application["longitude"]
  }
  pp record
end
