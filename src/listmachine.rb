#!/usr/bin/ruby
# encoding: UTF-8

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
# - rank() Ranks and lists all users in all categories (happens with new()). do this to "rerank" everyone. this should be called on a schedule,
#   with maybe create_tweet() happening after
# - add_user(username) add a new user to an existing list and sort(), giving them chance to be added to the bottom of all existing lists
#   this should be called when a new user follows the bot. you can use create_tweet(username) to get a ranking they achieve for a tweet
# - create_tweet(username) returns list position information for a random list for the specified user, or a random user if no one is specified.
#   if the user is not on a list returns nil.

# this is an estimate for the maximum length of a list name. expects usernames and superlatives to be added to form 140 characters
$max_list_name_length = 85
# general number of times it will attempt to generate conforming lists, tweets, or other retry actions
$global_num_retries = 5

#unicode symbols (emoji) for our tweets
$up_symbol = "\u{23EC}"
$neutral_symbol = "\u{2796}"
$down_symbol  = "\u{23EB}"

class ListMachine

  attr_reader :users, :lists, :rankings, :num_lists, :list_size
  attr_accessor :events

  def initialize(num_lists = 50, list_size = 10, addtl_followers = nil)
    #carry these trhue
    @num_lists = num_lists
    @list_size = list_size

    #events is array of possible tweets
    @events = Array.new

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
    @lists = self.generate_lists()

    # setup our initial rankings inside each list
    @rankings = {}
    self.rank()
  end

  def add_user(username)
    @users << username
    @users.uniq
  end

  def generate_lists()
    lists = Array.new()
    num_created = 0
    while num_created < @num_lists do
      lists << self.generate_list_name()
      num_created += 1
    end
    return lists
  end

  def generate_list_name()
    # Samples a list name!
    num_retries = 0
    str = nil
    while num_retries <= $global_num_retries do
      adj = $imported_categories['adjectives'].sample
      noun = $imported_categories['nouns'].sample
      cat = $imported_categories['categories'].sample
      str = adj + " " + noun + " " + cat
      if (str.length <= $max_list_name_length)
        str = str.titleize
        break
      else
        num_retries += 1
      end
    end
    return str
  end

  def rank()
    # Get our lists
    # Here is what our list hash looks like
    # rankings {
    #   "list_name" => {
    #     "current" => [] #ordered array of usernames
    #     "previous" => []
    #    }
    # }
    @lists.each do |list|
      # Does this list exist in rankings?
      if @rankings.include? list
        # remember last rankings
        @rankings[list]["previous"] = @rankings[list]["current"]
        # reshuffle
        @rankings[list]["current"] = @rankings[list]["current"].shuffle
        # find someone not on the list and give them a chance to replace bottom
        user = @users.sample
        num_retries = 0
        while num_retries <= $global_num_retries
          if !@rankings[list]["current"].include? user
            # coinflip!
            roll = rand(0.5)
            if roll >= 0.5
              #success! knock out the bottom
              @events << "#{user} just made #{list}!"
              @rankings[list]["current"][0] = user
            end
          end
          num_retries += 1
        end
      else
        # Setup inital rankings by just random sample people until full
        @rankings[list] = { "current" => [], "previous" => [] }
        while @rankings[list]["current"].size <= @list_size - 1 do
          user = @users.sample
          #make sure they're not already on it and add
          if !@rankings[list]["current"].include? user
            @rankings[list]["current"] << user
          end
        end
      end
    end
  end

  def get_tweet(username = nil)

    category = false

    if username
      #get a list that features this user
      #haha so inneficentttt
      found_user = false
      @rankings.each do |key, v|
        this_list = v['current']
        if this_list.include? (username)
          category = key
          break
        end
      end
    end

    if !category
      #get a random list
      list = @rankings.to_a.sample
      category = list[0]
    end

    #setup some list related vars
    full_data = @rankings[category]
    curr_users = full_data["current"]
    prev_users = full_data["previous"]

    if username
      #get our specific user from the list
      username = username
    else
      #get random user from list
      #reminder: rank still starts a 0 right now
      username = curr_users.sample
    end

    #get current rank in list
    curr_rank = curr_users.index(username.to_s).to_i + 1

    #set default ranking symbol and verb
    direction = 'neutral'
    symbol = $neutral_symbol
    verb = $imported_categories['neutral_verbs'].sample.to_s

    #add 1 because rankings start at 0
    prev_rank = prev_users.index(username.to_s).to_i + 1
    if !prev_rank
      prev_rank = curr_rank
    end
    rank_str = "rank #" + curr_rank.to_s
    if prev_rank != curr_rank
      rank_str = "from #" + prev_rank.to_s + " "
      rank_str += "to #" + curr_rank.to_s
    end

    #determine direction from previous rank
    if prev_rank != curr_rank
      if curr_rank < prev_rank then #on this kind of list a lower number is better!
        direction = 'up'
        symbol = $down_symbol
        verb = $imported_categories['upward_verbs'].sample.to_s
      elsif curr_rank > prev_rank
        direction = 'down'
        symbol = $up_symbol
        verb = $imported_categories['downward_verbs'].sample.to_s
      end
    end

    #assemble our tweet (140 character w/ retries)
    num_retries = 0
    while num_retries <= $global_num_retries do
      #random chance of superlative
      superlative = ""
      if rand(0.5) > 0.5
        superlative = " " + $imported_categories['superlatives'].sample.to_s
      end
      name_for_list = $imported_categories['names_for_lists'].sample.to_s
      str = symbol + superlative + " %" + username + " " + verb + " " + rank_str + " " + name_for_list + " " + category
      if str.length <= 140
        return str
        break
      end
      num_retries += 1
    end
  end

end

# TESTING STUFF
# poc: create 10 lists of 5 members each, output 100 tweets
#x = ListMachine.new(num_lists = 100, list_size = 10)
#x.add_user('negatendo')
#x.rank()
#puts x.get_tweet('negatendo')

