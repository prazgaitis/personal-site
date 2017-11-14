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

filename = "./_posts/#{date}-#{title.gsub(' ', '-')}.markdown"

IO.popen("pbcopy", "w") { |pipe| pipe.puts "#{title} #{bookAuthor}" }

open(filename, 'w') { |f|
  f << "---\n"
  f << "title: \"#{title}\"\n"
  f << "bookAuthor: \"#{bookAuthor}\"\n"
  f << "layout: book\n"
  f << "format: \"#{format}\"\n"
  f << "recommended: \"#{recommended}\"\n"
  f << "date: \"#{date}\"\n"
  f << "tag: book\n"
  f << "projects: false\n"
  f << "books: true\n"
  f << "hidden: false\n"
  f << "category: book\n"
  f << "amazonLink: \"#{url}\"\n"
  f << "---"
}
