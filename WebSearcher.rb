require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'certified'
#require 'pp'
require 'open_uri_redirections'
#require 'concurrent'
require 'thread'

CSV_HEADER = %w(Link Count) 	

class WebSearcher
  
  attr_reader :term

  def initialize(term)
  	@term = term
  end

 # Show and count all terms on page.
 #  def frequencies(words) 
 #    Hash[
 #    	 words.group_by(&:downcase).map{ |word,instances|
 #       [word,instances.length]
 #     	 }.sort_by(&:last).reverse
 #    ]
 #  end

 def count_term(words, term)
   words.chars.each_cons(term.size).map(&:join).count(term)
 end

 def save_to_csv
   started_at = Time.now
   CSV.open('results.txt', 'wb') do |csv_output|  
     csv_output << CSV_HEADER 
     csv_text = File.read('urls.csv')
     csv_input = CSV.parse(csv_text, :headers => true)
     work_q = Queue.new
     csv_input.each { |row| work_q <<  'https://www.' + row[1]  }
     workers = (0...5).map do
       Thread.new do
         begin 
           while page = work_q.pop('true')
             retries = 1
             begin
               html = Nokogiri::HTML(open(page, :allow_redirections => :all))
               html.css('script').remove
               preview = html.at('html').inner_text.downcase.scan(/\w+/)
               words = html.at('html').inner_text.downcase
               count_term = count_term(words, term.downcase).to_s
               puts page + ': ' + count_term + ' found.' 
               csv_output << [ page, count_term ] 
             rescue StandardError=>e
               puts "#{page}: #{e}"
               if retries > 0
                 puts "Retrying #{retries} more times"
                 retries -= 1
                 sleep 1
                 retry
               end
               else
              	 sleep 1.0 + rand * 1.0
               end
             end
             rescue ThreadError
           end
         end
       end
       workers.map(&:join);
       puts "Task made in " + (Time.now - started_at).inspect + ' seconds.'
     end #workers
   end #def 
end #class

web_searcher = WebSearcher.new(ARGV[0])
web_searcher.save_to_csv



 



 
