require 'nokogiri'

class BiblePage

	def initialize
		# ロガーの初期化
		@log = Logger.new(STDERR)
		@log.level=Logger::DEBUG
	end

	def check_and_get_child(node)
		if node.children.length == 1
			return node.child
		else
			raise "node '#{node.to_html}' has multiple children"
		end
	end

	def empty_text_node?(node)
		if node.name == "text"
			if node.inner_html == ""
				return true
			else
				raise 'Unknown text node'
			end
		end
		false
	end

	def ruby_process(verse_text)

		ruby_infos = []
		reading_text = verse_text.dup
		kakko_text = verse_text.dup

		ruby_reg = /<w s="([^"]+)">([^<]+)<\/w>/
		while pos = (verse_text =~ ruby_reg)
			furigana = $1
			ruby_text = $2

			verse_text.sub!(ruby_reg, ruby_text)
			reading_text.sub!(ruby_reg, furigana)
			kakko_text.sub!(ruby_reg, ruby_text + "（" + furigana+ "）")

			# ふりがな、ルビが振られているテキスト、テキスト上の位置、長さ
			ruby_info = {furigana: furigana, ruby_text: ruby_text, pos: pos, length: ruby_text.length}
			ruby_infos.push ruby_info
		end

		# 漢字混じりテキスト、よみ、カッコつきテキスト、詳細なルビ情報
		[verse_text, reading_text, kakko_text, ruby_infos]
	end

	def parse_contents(doc)
		book = doc/'book/@id'
		title = (doc/'title').inner_text
		@log.info("#{title} #{book}")

		infos = []
		chapters = doc/'chapter'
		chapters.each do |chapter|
			chap_html = chapter.inner_html
			verses = chap_html.scan(/<verse[^>]+>.+?<\/?verse[^>]*>/)
			verses.each do |verse|
				# 通常
				if verse =~ /<verse id="([^"]+)"+>(.+?)<\/?verse>/
					verse_id = $1
					verse_text = $2
				# タグが囲まれていないパターン
				elsif verse =~ /<verse sid="([^"]+)"><\/verse>(.+?)<verse eid="\1">/
					verse_id = $1
					verse_text = $2
					@log.debug("@@@@@@@@@@@@@@")
				else
					puts verse
					raise "unknown pattern"
				end

				chapter_num, verse_num = verse_id.split(":")
				@log.info("#{chapter_num}-#{verse_num}")

				verse_text = verse_text.gsub(/<\/?(l|lg)>/, "") # ルビ以外のタグを削除
				verse_text, reading_text, kakko_text, ruby_infos = ruby_process(verse_text)

				@log.debug(verse_text)
				@log.debug(reading_text)
				@log.debug(kakko_text)
				@log.debug(ruby_infos)

				info = {title: title, book: book.to_s, chapter: chapter_num, verse_num: verse_num, text: verse_text, reading: reading_text, kakko: kakko_text, ruby_infos: ruby_infos}
				infos.push info
			end
		end
		infos
	end
end