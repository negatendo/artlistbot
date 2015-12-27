#!/usr/bin/ruby

# This module:
#
# - new() Loads category and user data for assembling tweets (send me addtl users)
# - sort() Ranks and lists all users in all categories (happens with new())
# - add_user() add a new user and resort()
# - request_list() returns specified list info
# - request_user() returns specified user list info
# - get_tweet() returns a random list position as an assembled tweet
#
# More info on sort:
# - users have a random chance to be added to any list
# - users can only move up or down one position from a previous sort
# - the total number of lists = (??) the total number of people following the bot,
#   giving everyone a chance to be on a list?
# - users that are moved off the bottom of the list are removed from the list
# - TODO: have info on their previous position on the list too
#
# More info on assembled tweet:
# - combines superlative (chance of ) + adjuctive + noun + category
# - TODO: also include an image? would be cool if had arrow showing movement


