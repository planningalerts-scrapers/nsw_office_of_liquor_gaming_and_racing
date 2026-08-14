# frozen_string_literal: true

RSpec.describe Scraper do
  # The search request embeds today's date, so freeze time to keep requests
  # identical to the recorded cassettes.
  before { Timecop.freeze(Time.parse("2026-08-11 12:00:00 +10:00")) }

  after { Timecop.return }

  describe "#scrape", :vcr do
    subject(:records) do
      [].tap do |collected|
        described_class.new.scrape(Date.today - 28, Date.today) do |record|
          collected << record
        end
      end
    end

    it "finds at least one application notice" do
      expect(records.size).to be_positive
    end

    it "paginates through more than one page of results" do
      expect(records.size).to be > 25
    end

    it "returns records with all the expected fields" do
      expect(records).to all(
        match(
          "council_reference" => match(/\A\S+\z/),
          "address" => be_a(String),
          "description" => match(/\S/),
          "info_url" => match(%r{\Ahttps://lngnoticeboard\.onegov\.nsw\.gov\.au/searchresult/details/\S+\z}),
          "date_scraped" => Date.today.to_s,
          "date_received" => match(/\A\d{4}-\d{2}-\d{2}\z/),
          "on_notice_to" => match(/\A\d{4}-\d{2}-\d{2}\z/),
          "latitude" => be_a(Numeric).or(be_a(String)).or(be_nil),
          "longitude" => be_a(Numeric).or(be_a(String)).or(be_nil)
        )
      )
    end

    it "returns posted dates within the 28 day search window" do
      dates = records.map { |record| Date.parse(record["date_received"]) }
      expect(dates).to all(be_between(Date.today - 28, Date.today))
    end
  end

  describe "#run", :vcr do
    it "saves each scraped record with ScraperWiki" do
      saved = []
      allow(ScraperWiki).to receive(:save_sqlite) { |keys, record| saved << [keys, record] }

      expect { described_class.new.run }.to output(/Setting up search/).to_stdout

      expect(saved.size).to be_positive
      expect(saved).to all(match([["council_reference"], be_a(Hash)]))
    end
  end
end
