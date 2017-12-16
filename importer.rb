require 'yaml'
require 'json'

books = []
i = 0
Dir.glob('_posts/*markdown') do |item|
  next if !(File.readlines(item)[11].include? "book")

  i += 1
  book = {}
  File.readlines(item).each do |line|
    next if line.include? "---"
    k, v = line.split(": ")
    book[k] = v.chomp.gsub("\"", "")
  end

  book.keep_if { |k,v| %w(title bookAuthor format recommended data amazonLink).include? k }

  books << book

  filename = "./_data/books.yml"

  File.open(filename, 'w') {|f| f.write YAML.dump(books) }
end
