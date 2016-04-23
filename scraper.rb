require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

date_from = (Time.now - 7*86400).strftime("%Y-%m-%d")
date_to   = (Time.now - 1*86400).strftime("%Y-%m-%d")

query_url = "https://www.liquorandgaming.justice.nsw.gov.au/_api/search/query?querytext=%27%28%20NoticeboardDatePosted:#{date_from}..#{date_to}%29%20ContentSource:Notices%27&rowlimit=4000&selectproperties=%27NoticeboardApplicationNumber,NoticeboardApplicationType,NoticeboardCIS,NoticeboardDatePosted,NoticeboardDatePostedString,NoticeboardLGA,NoticeboardLIA,NoticeboardLPN,NoticeboardNotice,NoticeboardPostcode,NoticeboardPLN,NoticeboardSubmissionDate,NoticeboardSubmissionDateString,NoticeboardStreetAddress,NoticeboardSuburb,NoticeboardStatus,NoticeboardRST%27&sortlist=%27NoticeboardDatePosted:descending%27&QueryTemplatePropertiesUrl=%27spfile://webroot/queryparametertemplate.xml%27"

data = Nokogiri.parse(open(query_url).read, nil, 'utf-8')
cleaned_records = []
records = data.xpath('//d:Table/d:Rows/d:element[@m:type="SP.SimpleDataRow"]/d:Cells')
records.each do |record|
  cleaned_record = {}
  record.xpath('d:element[@m:type="SP.KeyValue"]').each do |cell|
    cleaned_record[cell.xpath('d:Key').text] = cell.xpath('d:Value').text
  end
  cleaned_records << cleaned_record
end

cleaned_records.each do |cleaned_record|
  address = "#{cleaned_record["NoticeboardStreetAddress"]}, #{cleaned_record["NoticeboardSuburb"]}, NSW"
  description = "#{cleaned_record["NoticeboardApplicationType"]} by #{cleaned_record["NoticeboardLPN"]}"
  date_posted = DateTime.strptime(cleaned_record["NoticeboardDatePosted"])
  on_notice_to = DateTime.strptime(cleaned_record["NoticeboardSubmissionDate"])

  info_url = "http://www.lgnoticeboardassets.justice.nsw.gov.au/liquor_applications/docs/#{council_reference}-Notice.pdf"

  comment_url = "http://www.liquorandgaming.justice.nsw.gov.au/pages/lg-forms/submissionform.aspx?"
  comment_url += "an=#{council_reference}"
  comment_url += "&at=#{URI.encode cleaned_record["NoticeboardApplicationType"]}"
  comment_url += "&dp=#{URI.encode cleaned_record["NoticeboardDatePostedString"]}" 
  comment_url += "&lga=#{URI.encode cleaned_record["NoticeboardLGA"]}" #Randwick%20City%20Council"
  comment_url += "&lpn=#{URI.encode cleaned_record["NoticeboardLPN"]}" #Bus%20Stop"
  comment_url += "&pc=#{URI.encode cleaned_record["NoticeboardPostcode"]}" #2031"
  comment_url += "&sd=#{URI.encode cleaned_record["NoticeboardSubmissionDateString"]}" #05/05/16"
  comment_url += "&sa=#{URI.encode cleaned_record["NoticeboardStreetAddress"]}" #80%20Clovelly%20Rd"
  comment_url += "&st=#{URI.encode cleaned_record["NoticeboardStatus"]}" #Under%20consideration"
  comment_url += "&su=#{URI.encode cleaned_record["NoticeboardSuburb"]}" #RANDWICK"

  record = {
    'council_reference' => cleaned_record["NoticeboardApplicationNumber"],
    'description'       => description,
    'date_received'     => date_posted,
    'address'           => address,
    'info_url'          => info_url,
    'comment_url'       => comment_url,
    'on_notice_to'      => on_notice_to,
    'date_scraped'      => Date.today.to_s
   }
  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
     puts "Skipping already saved record " + record['council_reference']
  end
end
