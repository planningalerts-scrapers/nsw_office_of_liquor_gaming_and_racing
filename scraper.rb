require "httparty"

def convert_date(text)
  Date.strptime(text, "%d/%m/%Y").to_s
end

# Gets one page worth of application data
def page(current_page, start_date, end_date)
  query = {
    "paginationCriteria": {
      "currentPage": current_page,
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
    "https://lngnoticeboard.onegov.nsw.gov.au/lngnoticeboard/v1/applicationsearch/perform",
    body: query.to_json,
    headers: {"Content-Type" => "application/json"}
  )

  applications =result["results"].map do |application|
    council_reference = application["application"]
    {
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
  end
  { page_count: result["pageCount"], applications: applications }
end

def all(start_date, end_date)
  current_page = 1
  loop do
    result = page(current_page, start_date, end_date)
    result[:applications].each do |application|
      yield application
    end
    current_page += 1
    break if current_page > result[:page_count]
  end
end

# Get the applications from the last 28 days
all(Date.today - 28, Date.today) do |application|
  pp application
end
