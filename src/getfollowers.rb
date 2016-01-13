#!/usr/bin/ruby

# Utility that turns a twitter users followers into datas

require 'json'
require 'pstore'
require_relative '../rubybottools/followerthing.rb'

def save(store, all_followers)
  puts "Saving..."
  store.transaction do
    store[:all_followers] = all_followers
  end
end


all_followers = []
store = PStore.new('getfollowers.store')
store_data = false
store.transaction(true) do
  if store[:all_followers]
    store_data = store[:all_followers]
    puts "$netartistdaily_followers = ["
    store_data.each do |x|
      puts "'#{x}',"
    end
    puts "]"
    exit
  end
end

account = TwurlrcReader.new('MarbleckaeYumte','lN1fHeFIm7LTAKQYV03DDpVNO')

client = account.get_rest_client()

client.followers('netartistdaily').each do |x|
  if store_data
    puts store_data
    exit
  end
  puts "Info: followed by #{x.screen_name}"
  all_followers << x.screen_name
  save(store, all_followers)
  sleep(20)
end


