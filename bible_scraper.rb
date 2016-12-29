require 'logger'
require 'kconv'
require './web_fetcher'
require './bible_page'
require './data_output'

class BibleScraper

	TARGETS = ["old", 'new']
	def initialize(title_id = 0)

		# ロガーの初期化
		@log = Logger.new(STDERR)
		@log.level=Logger::DEBUG
		@log.debug('Initilizing instance')

		@config = YAML.load_file('config/config.yml')

		@web_fetcher = WebFetcher.new @config
		@data_output = DataOutput.new @config
	end

	def scrape_scriptures

		@log.info("start parsing")

		@web_fetcher.fetch_and_store_web_pages

		all_infos = []
		# titleに対して
		TARGETS.each_with_index do |target, title_id|

			all_infos_in_book = []

			# bookに対して
			@book_names = @web_fetcher.get_book_names title_id
			@book_names.each_with_index do |book_name, book_id|
				@log.info("*** #{book_id} #{book_name} ***")
				web_data = @web_fetcher.read_web_data title_id, book_id
				bible_page = BiblePage.new
				doc = Nokogiri::XML.parse(web_data)
				infos = bible_page.parse_contents doc
				all_infos_in_book.push infos
			end
			all_infos.push all_infos_in_book
		end
		@data_output.write_infos_to_csv(all_infos)
	end
end

