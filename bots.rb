require 'twitter_ebooks'

require_relative 'rubybottools/twurlrc-reader.rb'
require_relative 'rubybottools/twittersession.rb'

require_relative 'src/listmachine.rb'

$bot_username = 'MarbleckaeYumte'
$bot_consumer_key ='crsG1CviUk0rIyrBGDO88JpdJ'

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

    @listmachine = ListMachine.new(list_size = 10)

    @session = TwitterSession.new('artlistbot')
  end

  def on_startup
    #TODO parse follower list and update listmachine on startup
    self.log "Starting up!"

    scheduler.every '1h' do
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

    scheduler.every '3d' do
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

    # to do new follower tweet must have a tweet as well as applicable session state
    do_new_follower_tweet = false
    if tweet
      self.log "Got a new user tweet here!"
      self.log "checking last interaction"
      time = if @session.get_user(username).last_interaction_time.nil?
        self.log "never interacted"
        do_new_follower_tweet = true
      else
        # max 1 per hr followback interaction
        if (Time.now.to_i - @session.get_user(username).last_interaction_time >= 3600)
          self.log "interacted long enough ago"
          do_new_follower_tweet = true
        else
          self.log "user #{username} already interacted with the bot recently"
        end
      end
      # log last interaction time to prevent exploit of follow/unfollow mentions
      @session.log_user_interaction(username)
    else
      self.log "failed to come up with a tweet"
      do_new_follower_tweet = false
    end

    #do new follower tweet
    if do_new_follower_tweet
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
