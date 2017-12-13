require 'rubygems'
require 'bundler/setup'

require 'mechanize'
require 'dotenv'

Dotenv.load

if ENV['USERNAME'].nil? || ENV['PASSWORD'].nil?
  puts 'Please set the USERNAME and PASSWORD environment variables, or provide'
  puts 'them in the .env file. See .env.example for an example.'
  exit 1
end

# test timings
# 01 08:25
# 02 09:15
# 03 10:15
# 04 11:00
# 05 11:45
# 06 13:55
# 07 14:45
# 08 15:45
# 09 16:30
SESSION_TIMINGS = ['01 - 07:25 08:25-08:55', '02 - 08:15 09:15-09:45',
  '03 - 09:10 10:15-10:45', '04 - 10:00 11:00-11:30', '05 - 10:45 11:45-12:15',
  '06 - 12:30 13:55-14:25', '07 - 13:25 14:45-15:15', '08 - 14:20 15:45-16:15',
  '09 - 15:15 16:30-17:00']
MONTHS_TO_SEARCH = ['Jan/2018', 'Feb/2018', 'Mar/2018']

# hack since the webserver doesn't support any modern secure ciphers
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers] += ':RC4-SHA'

mechanize = Mechanize.new
# hack since the webserver doesn't send the thawte intermediate certificate
mechanize.verify_mode = OpenSSL::SSL::VERIFY_NONE

# login
page = mechanize.get('https://www.bbdc.sg/bbdc/bbdc_web/newheader.asp')
login_form = page.form()
login_form.txtNRIC = ENV['USERNAME']
login_form.txtPassword = ENV['PASSWORD']
page_mainframe = mechanize.submit(login_form, login_form.buttons.first)

# booking search form
page2 = mechanize.get('https://www.bbdc.sg/bbdc/b-3c-SelectPracticalTestBooking.asp?+3')
search_form = page2.form()
MONTHS_TO_SEARCH.each do |m|
  search_form.checkbox_with(:value => m).check
end
search_form.checkboxes_with(:name => 'Session').each { |f| f.check }
search_form.checkboxes_with(:name => 'Day').each { |f| f.check }
page3 = mechanize.submit(search_form, search_form.buttons.first)

# booking search results
rows = page3.search('form table table tr')
results = []
# ignore rows 0 and 1
2.upto(rows.length-1) do |i|
  # column 0 is the date and day
  # column 1 is 'BBDC'
  # column 2-10+ are the session checkboxes
  date = rows[i].children[0].children[0].text
  day = rows[i].children[0].children[2].text
  sessions_available = []
  2.upto(10) do |s|
    sessions_available[s-2] = rows[i].children[s].children.length > 0
    if sessions_available[s-2]
      results << "#{date} #{day} - #{SESSION_TIMINGS[s-2]}"
    end
  end
end

puts results.join("\n") if not results.empty?
