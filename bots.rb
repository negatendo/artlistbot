require 'twitter_ebooks'

require_relative 'rubybottools/twurlrc-reader.rb'

require_relative 'src/listmachine.rb'

$bot_username = 'MarbleckaeYumte'
$bot_consumer_key ='lN1fHeFIm7LTAKQYV03DDpVNO'

class MyBot < Ebooks::Bot
  attr_accessor :listmachine

  def configure
    account = TwurlrcReader.new($bot_username,$bot_consumer_key)

    self.consumer_key = account.consumer_key
    self.consumer_secret = account.consumer_secret
    self.access_token = account.access_token
    self.access_token_secret = account.access_token_secret

    # Users to block instead of interacting with
    self.blacklist = ['tnietzschequote']

    @listmachine = ListMachine.new(num_lists = 1000, list_size = 10)
  end

  def on_startup
    #TODO parse follower list and update listmachine on startup
    self.log "Starting up!"

    scheduler.every '10m' do
      # Tweet a random list position
      self.log "Going to tweet!"
      num_retries = 0
      max_num_retries = 5
      while num_retries < max_num_retries
        tweet = @listmachine.get_tweet()
        if tweet
          tweet(tweet)
          break
        else
          num_retries += 1
        end
      end
    end

    scheduler.every '5h' do
      self.log "Running ranks!"
      # resort lists (adds new people too) if
      # not already sorted
      @listmachine.rank()
    end

  end

  def on_message(dm)
    # Reply to a DM
    # reply(dm, "secret secrets")
  end

  def on_follow(user)
    # Add a user to the list machine, resort
    # and announce
    username = user.screen_name
    @listmachine.add_user(username)
    @listmachine.rank()
    tweet = @listmachine.get_tweet(username)
    if tweet
      self.log "Got a new user tweet here!"
      sleep 10
      tweet(tweet)
    end
  end

  def on_mention(tweet)
    # Reply to a mention
    # reply(tweet, "oh hullo")
  end

  def on_timeline(tweet)
    # Reply to a tweet in the bot's timeline
    # reply(tweet, "nice tweet")
  end

  def on_favorite(user, tweet)
    # Follow user who just favorited bot's tweet
    # follow(user.screen_name)
  end
end

MyBot.new($bot_username) do |bot|
end
