require "httparty"
require "scraperwiki"

def convert_date(text)
  Date.strptime(text, "%d/%m/%Y").to_s
end

# Create the search and return its ID
def setup_search(start_date, end_date)
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
    "https://lngnoticeboard.onegov.nsw.gov.au/lngnoticeboard/v1/applicationsearch/perform",
    body: query.to_json,
    headers: {"Content-Type" => "application/json"}
  )

  # Search ID needs to be a string for a later api call. So might as well make it so here
  result["searchID"].to_s
end

def page(page, search_id)
  result = HTTParty.post(
    "https://lngnoticeboard.onegov.nsw.gov.au/lngnoticeboard/v1/applicationsearch/page",
    body: {"searchID": search_id, "page": page}.to_json,
    headers: {"Content-Type" => "application/json"}
  )
  result["results"].each do |application|
    council_reference = application["application"]
    yield(
      "council_reference" => council_reference,
      "address" => application["address"],
      "description" => application["type"],
      "info_url" => "https://lngnoticeboard.onegov.nsw.gov.au/searchresult/details/#{council_reference}",
      "date_scraped" => Date.today.to_s,
      "date_received" => convert_date(application["posted"]),
      "on_notice_to" => convert_date(application["submissionClose"]),
      "latitude" => application["latitude"],
      "longitude" => application["longitude"]
    )
  end
  result["pageCount"]
end

def all(start_date, end_date)
  puts "Setting up search"
  search_id = setup_search(start_date, end_date)

  page = 1
  loop do
    puts "Getting page: #{page}"
    page_count = page(page, search_id) do |application|
      yield application
    end
    page += 1
    break if page > page_count
  end
end

# Get the applications from the last 28 days
all(Date.today - 28, Date.today) do |record|
  puts "Saving #{record['council_reference']}..."
  ScraperWiki.save_sqlite(["council_reference"], record)
end
