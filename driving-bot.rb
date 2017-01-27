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

SESSION_TIMINGS = ['07:30-09:10', '09:20-11:00', '11:30-13:10', '13:20-15:00',
  '15:20-17:00', '17:10-18:50', '7', '8']
MONTHS_TO_SEARCH = ['Jan/2017', 'Feb/2017']

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
page2 = mechanize.get('https://www.bbdc.sg/bbdc/b-3c-pLessonBooking.asp?limit=pl')
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
  # column 2-9 are the session checkboxes
  date = rows[i].children[0].children[0].text
  day = rows[i].children[0].children[2].text
  sessions_available = []
  2.upto(9) do |s|
    sessions_available[s-2] = rows[i].children[s].children.length == 1
    if sessions_available[s-2]
      results << "#{date} #{day} - #{SESSION_TIMINGS[s-2]}"
    end
  end
end

puts results.join("\n") if not results.empty?
