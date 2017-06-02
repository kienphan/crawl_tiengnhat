require 'nokogiri'
require 'open-uri'
require 'mechanize'

AGENT = Mechanize.new
BASE_URL = 'https://yomikatawa.com/kanji/'

def to_hiragana(kanji)
  AGENT.get(BASE_URL + kanji).search('#content p').first.inner_text
end

def to_romaji(kanji)
  AGENT.get(BASE_URL + kanji).search('#content p')[1].inner_text
end

# 検索結果が正しくない可能性がある時、alertがでるのでそれを所得するメソッド
# ひらがな所得時に確実性をもたせたい時に使う。
def certain?(kanji)
  AGENT.get(BASE_URL + kanji).search('.alert').empty?
end

CRAWLED_HOST = "http://tuhoconline.net/tu-vung-tieng-nhat-n2-luyen-thi-n2.html"
MAX_PAGE = 17

results = []
file1 = File.new("/Users/phankien/work/hapo/tiengnhatmoingay/db/fixtures/lesson.yml", "w+")
file2 = File.new("/Users/phankien/work/hapo/tiengnhatmoingay/db/fixtures/word.yml", "w+")

1.upto(MAX_PAGE) do |i|
# i = 1
  doc = Nokogiri::HTML(open("#{CRAWLED_HOST}/#{i}"))
  doc.search("div .entry-content").each do |item|
    lessons = item.search("h3:contains('Từ vựng tiếng Nhật N2 Ngày')")
    lessons.each do |lesson|
      day_order = lesson.previous_sibling.previous_sibling.content.gsub!('.','')
      if day_order.nil?
        day_order = lesson.previous_sibling.previous_sibling.previous_sibling.previous_sibling.content.gsub!('.','')
      end
      entry = lesson.next_sibling.next_sibling.content

      file1.write "\n"
      file1.write "soumatome_n2_#{i}#{day_order}: \n"
      file1.write "  id: #{i}#{day_order}\n"
      file1.write "  name: 第#{i}週・#{day_order}日目\n"
      file1.write "  content: #{lesson.content}\n"
      file1.write "  book_id: 2\n"

      words_ary = entry.split(/\n/)
      words_ary.each do |word|
        word_parts = word.split(/[.d+():]/).collect(&:strip).reject(&:empty?)
        file2.write "\n"
        file2.write "soumatome_n2_#{i}#{day_order}_#{word_parts[0]}: \n"
        file2.write "  lesson_id: #{i}#{day_order}\n"
        file2.write "  name: #{word_parts[1]}\n"
        file2.write "  hiragana: #{to_hiragana(word_parts[1])}\n"
        file2.write "  meaning: #{word_parts[3]}"

        # file.write "\"#{word_parts[0]}\",\"#{word_parts[1]}\",\"#{word_parts[2]}\",\"#{word_parts[3]}\"\n"
      end
    end
  end
end

file1.close
file2.close
