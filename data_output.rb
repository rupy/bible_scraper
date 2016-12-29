require 'csv'

class DataOutput

	def initialize(config)
		# ロガーの初期化
		@log = Logger.new(STDERR)
		@log.level=Logger::DEBUG

		@config = config
	end

	def write_infos_to_csv(all_infos)

		output_csv_dir = @config['structure']['output_csv_dir']
		@log.info("writing csv")

		CSV.open(output_csv_dir + '/bible.csv', 'w') do |writer|
			CSV.open(output_csv_dir + '/ruby_bible.csv', 'w') do |ruby_writer|
				id = 0
				all_infos.each_with_index do |book_infos, title_id|
					book_infos.each_with_index do |infos, book_id|
						infos.each_with_index do |info, chapter_id|
							writer << [id, title_id, book_id, chapter_id, info[:title], info[:book], info[:chapter], info[:verse_num], info[:text], info[:reading], info[:kakko]]

							# ルビ
							ruby_infos = info[:ruby_infos]
							ruby_infos.each do |ruby_info|
								ruby_writer << [id, ruby_info[:furigana], ruby_info[:ruby_text], ruby_info[:pos], ruby_info[:length]]
							end

							id += 1
						end
					end
				end
			end
		end
	end


end