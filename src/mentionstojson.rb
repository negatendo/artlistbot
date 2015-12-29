#!/usr/bin/ruby

# Utility file that grabs all mentions from specified ebooks json archive
# and then dumps them to a json file

require 'json'

file = File.read('/home/bretto/netartquotes.json')
data = JSON.parse(file)

usernames = Array.new()
data.each do |tweet|
  user = /@(.*)/.match(tweet['text'])
  usernames << user.to_s.downcase.strip
end
usernames = usernames.uniq

File.open('/home/bretto/users-scraped.json','w') do |f|
  f.write(JSON.pretty_generate(usernames))
end
