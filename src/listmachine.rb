#!/usr/bin/ruby

require 'json'
require 'pry'
require 'titleize'

# Bring in our arrays of hardcoded usernames and category parts
require_relative '../data/users.rb'
require_relative '../data/categories.rb'

# This module:
#
# - new(num_lists,list_size,addtl_followers) Loads category and user data for assembling tweets, creating the specified number of random lists
#   list_size is how many users per list and additional_followers can be an array of other users to list in addition to those in users.json
#   DO NOT INCLUDE THE @ SYMBOL WITH USERNAMES - we will do that as a part of character counting
# - rank() Ranks and lists all users in all categories (happens with new()). do this to "rerank" everyone.
#   if someone is ranked lower than list_size, they are out and a new username is added to bottom?
#   this should be called on a schedule, with maybe create_tweet() happening after
# - add_user(username) add a new user to an existing list and sort(), giving them chance to be added to the bottom of all existing lists
#   this should be called when a new user follows the bot.
# - create_tweet(username) returns list position information for a random list for the specified user, or a random user if no one is specified.
#   if the user is not on a list returns nil.

# this is an estimate for the maximum length of a list name. expects usernames and superlatives to be added to form 140 characters
$max_list_name_length = 85
# number of times it will attempt to generate conforming lists before giving up
$list_name_retries = 5
# number of times create_tweet() will attempt to return a valid tweet before giving up
$valid_tweet_retries = 5


class ListMachine

  attr_reader :users, :lists, :rankings

  def initialize(num_lists = 50, list_size = 10, addtl_followers = nil)

    # Set up our users array
    import = Array.new
    addtl = Array.new
    # combine followers and downcase all usernames
    $imported_users.each do |user|
      import << user.downcase
    end
    if addtl_followers
      addtl_followers.each do |follower|
        import << follower.downcase
      end
    end
    @users = import + addtl
    # ensure uniquenes
    @users = @users.uniq

    # setup our specified number of lists
    @lists = self.generate_lists(num_lists)

    # setup our initial rankings inside each list
    self.rank()
  end

  def generate_lists(num_lists)
    # keep retrying until
    lists = Array.new()
    num_created = 0
    num_retries = 0
    while num_lists <= num_created or num_retries <= $list_name_retries do
      list = self.generate_list_name()
      puts list
      if (list.length <= $max_list_name_length and !lists.include? list)
        puts "adding"
        lists << list
        num_retries = 0 #reset retries
        num_created += 1
      else
        num_retries += 1
      end
    end
    return lists
  end

  def generate_list_name()
    # Samples a list name!
    adj = $imported_categories['adjectives'].sample
    noun = $imported_categories['nouns'].sample
    cat = $imported_categories['categories'].sample
    str = adj + " " + noun + " " + cat
    return str.titleize
  end

  def rank()
    # Get our lists
    # Here is what our list hash looks like
    # rankings {
    #   "list_name" => {
    #     "current_rankings" => [] #ordered array
    #     "previous_rankings" => [] #ordered array
    #    }
    # }
    @lists.each do |list|
      # Does this list exist?
      if @rankings
      # Does it already have ranked people?
        # reposition peopole
        # give someone a chance to knock out bottom
        # surviors need to remember their last rank for tweet
      # Set rankings array
    end
  end

  def create_tweet()
    #TODO remember retries!
    return "tweet"
  end

end

# TESTING STUFF
# poc: create 10 lists of 5 members each, output 100 tweets
x = ListMachine.new(10,5)
#i = 0
#while i <= 10 do
  #puts x.create_tweet()
#  i += i
#end

