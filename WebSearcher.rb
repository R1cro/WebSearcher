require 'nokogiri'
require 'open-uri'
require 'csv'
require 'certified'
require 'open_uri_redirections'
require 'thread'
#require 'pp'

CSV_HEADER = %w(Link Count) 	

class WebSearcher
  
  attr_reader :term

  def initialize(term)
  	@term = term
  end

 #  def frequencies(words) 
 #    Hash[
 #    	 words.group_by(&:downcase).map{ |word,instances|
 #       [word,instances.length]
 #     	 }.sort_by(&:last).reverse
 #    ]
 #  end

  def find_term(page)
    html = Nokogiri::HTML(open(page, :allow_redirections => :all))
    html.css('script').remove
    preview = html.at('html').inner_text.scan(/\w+/)
    words = html.at('html').inner_text
    @count_term = count_term(words, term).to_s
  end

  def count_term(words, term)
    words.chars.each_cons(term.size).map(&:join).count(term)
  end

  def read_csv
    csv_text = File.read('urls.csv')
    csv_input = CSV.parse(csv_text, :headers => true)
  end

  def save_to_result
    started_at = Time.now
    CSV.open('results.txt', 'wb') do |csv_output|  
      csv_output << CSV_HEADER 
      work_q = Queue.new
      read_csv.each { |row| work_q <<  'https://www.' + row[1] }
      workers = (0...26).map do
        Thread.new do
          begin 
            while page = work_q.pop('true')
              retries = 1
              begin
                find_term(page) 
                puts page + ': ' + @count_term + ' found.' 
                csv_output << [ page, @count_term ] 
              rescue StandardError=>e
                puts "#{page}: #{e}"
                if retries > 0
                  puts "Retrying #{retries} more times"
                  retries -= 1
                  sleep 3
                  retry
                end
                else
              	  sleep 2.0 + rand * 2
                end
              end
          rescue ThreadError
          end
        end #begin_end
      end #workers
      workers.map(&:join);
      puts "Task made in " + (Time.now - started_at).inspect + ' seconds.'
    end #csv_output
  end #def

end #class

web_searcher = WebSearcher.new(ARGV[0])
web_searcher.save_to_result




 



 
