# NSW Office of Liquor, Gaming and Racing

This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

It scrapes liquor and gaming application notices posted in the last 28 days
from the [NSW Liquor & Gaming noticeboard](https://lngnoticeboard.onegov.nsw.gov.au).

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## To run the scraper

    bundle exec ruby scraper.rb

### Expected output

    Setting up search
    Saving SR0001553543...
    Saving SR0001553544...
    ...
    Saving SR0001553601...
    Finished - added 59 records

Execution time under a minute

## To run style and coding checks

    bundle exec rubocop

## To run the tests

    bundle exec rspec

## To check for security updates

    gem install bundler-audit
    bundle-audit
