puts "Enter the title:\n"
title = gets.chomp

puts "Enter the author:\n"
bookAuthor = gets.chomp

puts "Would you recommend this book to a friend? (y/n)"
recommended = gets.chomp; recommended == "y" ? recommended = true : recommended = false

puts "Enter the format:\n1. Audiobook\n2. Book\n3. Kindle\n4. in-progress\n"
format = gets.chomp

if format.to_i == 1
  format = "audiobook"
elsif format.to_i == 2
  format = "book"
elsif format.to_i == 3
  format = "kindle"
else
  format = "in-progress"
end

puts "When did you read it? (YYYY-MM-DD):\n"
date = gets.chomp

puts "Amazon URL:\n"
url = gets.chomp

filename = "./_data/books.yml"

require 'yaml'
yaml_string = File.read filename
books = YAML.load yaml_string

puts books.count

book = {
  "title" => title,
  "bookAuthor" => bookAuthor,
  "format" => format,
  "recommended" => recommended,
  "date" =>  date,
  "amazonLink" =>  url,
}

books <<  book


# output = YAML.dump data
File.open(filename, 'w') {|f| f.write books.to_yaml }

