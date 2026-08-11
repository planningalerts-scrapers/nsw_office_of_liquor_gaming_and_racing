#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
Bundler.require

require "date"
require "json"

# Scrapes liquor and gaming application notices posted in the last 28 days
# from the NSW Liquor & Gaming noticeboard API and saves them with
# ScraperWiki.
class Scraper
  BASE_URL = "https://lngnoticeboard.onegov.nsw.gov.au"
  SEARCH_URL = "#{BASE_URL}/lngnoticeboard/v1/applicationsearch/perform".freeze
  PAGE_URL = "#{BASE_URL}/lngnoticeboard/v1/applicationsearch/page".freeze
  INFO_URL_PREFIX = "#{BASE_URL}/searchresult/details/".freeze
  SEARCH_WINDOW_DAYS = 28

  def scrape(start_date, end_date, &block)
    puts "Setting up search"
    search_id = setup_search(start_date, end_date)

    number = 1
    loop do
      page_count = fetch_page(number, search_id, &block)
      number += 1
      break if number > page_count
    end
  end

  # Get the applications from the last 28 days
  def run
    scrape(Date.today - SEARCH_WINDOW_DAYS, Date.today) do |record|
      puts "Saving #{record['council_reference']}..."
      ScraperWiki.save_sqlite(["council_reference"], record)
    end
  end

  private

  # Create the search and return its ID
  def setup_search(start_date, end_date)
    query = {
      paginationCriteria: {
        currentPage: 1,
        pageSize: 25,
      },
      type: "Advanced",
      criteria: [
        {
          type: "PostedDate",
          condition: {
            start: start_date.to_s,
            end: end_date.to_s,
          },
        },
      ],
    }

    result = HTTParty.post(
      SEARCH_URL,
      body: query.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    # Search ID needs to be a string for a later api call. So might as well
    # make it so here
    result["searchID"].to_s
  end

  # Yields the applications on one page of search results and returns the
  # total number of pages
  def fetch_page(number, search_id)
    result = HTTParty.post(
      PAGE_URL,
      body: { searchID: search_id, page: number }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
    result["results"].each do |application|
      yield record_for(application)
    end
    result["pageCount"]
  end

  def record_for(application)
    council_reference = application["application"]
    {
      "council_reference" => council_reference,
      "address" => application["address"],
      "description" => application["type"],
      "info_url" => "#{INFO_URL_PREFIX}#{council_reference}",
      "date_scraped" => Date.today.to_s,
      "date_received" => convert_date(application["posted"]),
      "on_notice_to" => convert_date(application["submissionClose"]),
      "latitude" => application["latitude"],
      "longitude" => application["longitude"],
    }
  end

  def convert_date(text)
    Date.strptime(text, "%d/%m/%Y").to_s
  end
end

Scraper.new.run if __FILE__ == $PROGRAM_NAME
