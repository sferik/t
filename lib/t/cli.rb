require 'action_view'
require 'active_support/core_ext/array/grouping'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/numeric/time'
require 'geokit'
require 'launchy'
require 'oauth'
require 'open-uri'
require 't/collectable'
require 't/core_ext/string'
require 't/delete'
require 't/list'
require 't/printable'
require 't/rcfile'
require 't/requestable'
require 't/search'
require 't/set'
require 't/version'
require 'thor'
require 'time'
require 'twitter'
require 'yaml'

module T
  class CLI < Thor
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper
    include T::Collectable
    include T::Printable
    include T::Requestable

    DEFAULT_NUM_RESULTS = 20
    MAX_SCREEN_NAME_SIZE = 20
    MAX_USERS_PER_REQUEST = 100

    check_unknown_options!

    option :host, :aliases => "-H", :type => :string, :default => DEFAULT_HOST, :desc => "Twitter API server"
    option :no_ssl, :aliases => "-U", :type => :boolean, :default => false, :desc => "Disable SSL"
    option :profile, :aliases => "-P", :type => :string, :default => File.join(File.expand_path("~"), RCFile::FILE_NAME), :desc => "Path to RC file", :banner => "FILE"

    def initialize(*)
      super
      @rcfile = RCFile.instance
    end

    desc "accounts", "List accounts"
    def accounts
      @rcfile.path = options['profile'] if options['profile']
      @rcfile.profiles.each do |profile|
        say profile[0]
        profile[1].keys.each do |key|
          say "  #{key}#{@rcfile.default_profile[0] == profile[0] && @rcfile.default_profile[1] == key ? " (default)" : nil}"
        end
      end
    end

    desc "authorize", "Allows an application to request user authorization"
    method_option :consumer_key, :aliases => "-c", :required => true
    method_option :consumer_secret, :aliases => "-s", :required => true
    method_option :prompt, :aliases => "-p", :type => :boolean, :default => true
    method_option :dry_run, :type => :boolean
    method_option :display_url, :type => :boolean
    def authorize
      request_token = consumer.get_request_token
      url = generate_authorize_url(request_token)
      if options['prompt']
        say "In a moment, your web browser will open to the Twitter app authorization page."
        say "Perform the following steps to complete the authorization process:"
        say "  1. Sign in to Twitter"
        say "  2. Press \"Authorize app\""
        say "  3. Copy or memorize the supplied PIN"
        say "  4. Return to the terminal to enter the PIN"
        say
        unless options['display_url']
          ask "Press [Enter] to open the Twitter app authorization page."
        else
          ask "Press [Enter] to display the URL you need to visit in your browser."
        end
        say
      end
      unless options['display_url']
        Launchy.open(url, :dry_run => options.fetch('dry_run', false))
      else
        say "Please navigate to the following URL to retrieve your PIN:"
        say url
        say
      end
      pin = ask "Paste in the supplied PIN:"
      access_token = request_token.get_access_token(:oauth_verifier => pin.chomp)
      oauth_response = access_token.get('/1/account/verify_credentials.json')
      screen_name = oauth_response.body.match(/"screen_name"\s*:\s*"(.*?)"/).captures.first
      @rcfile.path = options['profile'] if options['profile']
      @rcfile[screen_name] = {
        options['consumer_key'] => {
          'username' => screen_name,
          'consumer_key' => options['consumer_key'],
          'consumer_secret' => options['consumer_secret'],
          'token' => access_token.token,
          'secret' => access_token.secret,
        }
      }
      @rcfile.default_profile = {'username' => screen_name, 'consumer_key' => options['consumer_key']}
      say "Authorization successful."
    end

    desc "block SCREEN_NAME [SCREEN_NAME...]", "Block users."
    def block(screen_name, *screen_names)
      screen_names.unshift(screen_name)
      screen_names.map!(&:strip_ats)
      screen_names.threaded_each do |screen_name|
        screen_name.strip_ats
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.block(screen_name, :include_entities => false)
        end
      end
      number = screen_names.length
      say "@#{@rcfile.default_profile[0]} blocked #{number} #{number == 1 ? 'user' : 'users'}."
      say
      say "Run `#{File.basename($0)} delete block #{screen_names.map{|screen_name| "@#{screen_name}"}.join(' ')}` to unblock."
    end

    desc "direct_messages", "Returns the #{DEFAULT_NUM_RESULTS} most recent Direct Messages sent to you."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    def direct_messages
      count = options['number'] || DEFAULT_NUM_RESULTS
      direct_messages = client.direct_messages(:count => count, :include_entities => false)
      direct_messages.reverse! if options['reverse']
      if options['long']
        array = direct_messages.map do |direct_message|
          created_at = direct_message.created_at > 6.months.ago ? direct_message.created_at.strftime("%b %e %H:%M") : direct_message.created_at.strftime("%b %e  %Y")
          [direct_message.id.to_s, created_at, "@#{direct_message.sender.screen_name}", direct_message.text.gsub(/\n+/, ' ')]
        end
        if STDOUT.tty?
          headings = ["ID", "Posted at", "Screen name", "Text"]
          array.unshift(headings) unless direct_messages.empty?
        end
        print_table(array)
      else
        direct_messages.each do |direct_message|
          say "#{direct_message.sender.screen_name.rjust(MAX_SCREEN_NAME_SIZE)}: #{direct_message.text.gsub(/\n+/, ' ')} (#{time_ago_in_words(direct_message.created_at)} ago)"
        end
      end
    end
    map %w(dms) => :direct_messages

    desc "direct_messages_sent", "Returns the #{DEFAULT_NUM_RESULTS} most recent Direct Messages sent to you."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    def direct_messages_sent
      count = options['number'] || DEFAULT_NUM_RESULTS
      direct_messages = client.direct_messages_sent(:count => count, :include_entities => false)
      direct_messages.reverse! if options['reverse']
      if options['long']
        array = direct_messages.map do |direct_message|
          created_at = direct_message.created_at > 6.months.ago ? direct_message.created_at.strftime("%b %e %H:%M") : direct_message.created_at.strftime("%b %e  %Y")
          [direct_message.id.to_s, created_at, "@#{direct_message.recipient.screen_name}", direct_message.text.gsub(/\n+/, ' ')]
        end
        if STDOUT.tty?
          headings = ["ID", "Posted at", "Screen name", "Text"]
          array.unshift(headings) unless direct_messages.empty?
        end
        print_table(array)
      else
        direct_messages.each do |direct_message|
          say "#{direct_message.recipient.screen_name.rjust(MAX_SCREEN_NAME_SIZE)}: #{direct_message.text.gsub(/\n+/, ' ')} (#{time_ago_in_words(direct_message.created_at)} ago)"
        end
      end
    end
    map %w(sent_messages sms) => :direct_messages_sent

    desc "disciples", "Returns the list of people who follow you but you don't follow back."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def disciples
      follower_ids = collect_with_cursor do |cursor|
        client.follower_ids(:cursor => cursor)
      end
      following_ids = collect_with_cursor do |cursor|
        client.friend_ids(:cursor => cursor)
      end
      disciple_ids = (follower_ids - following_ids)
      users = disciple_ids.in_groups_of(MAX_USERS_PER_REQUEST, false).threaded_map do |disciple_id_group|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.users(disciple_id_group, :include_entities => false)
        end
      end.flatten
      print_user_list(users)
    end

    desc "dm SCREEN_NAME MESSAGE", "Sends that person a Direct Message."
    def dm(screen_name, message)
      screen_name = screen_name.strip_ats
      direct_message = client.direct_message_create(screen_name, message, :include_entities => false)
      say "Direct Message sent from @#{@rcfile.default_profile[0]} to @#{direct_message.recipient.screen_name} (#{time_ago_in_words(direct_message.created_at)} ago)."
    end
    map %w(d m) => :dm

    desc "favorite STATUS_ID [STATUS_ID...]", "Marks Tweets as favorites."
    def favorite(status_id, *status_ids)
      status_ids.unshift(status_id)
      status_ids.map!(&:strip_commas).map!(&:to_i)
      favorites = status_ids.threaded_map do |status_id|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.favorite(status_id, :include_entities => false)
        end
      end
      number = favorites.length
      say "@#{@rcfile.default_profile[0]} favorited #{number} #{number == 1 ? 'tweet' : 'tweets'}."
      say
      say "Run `#{File.basename($0)} delete favorite #{status_ids.join(' ')}` to unfavorite."
    end
    map %w(fave) => :favorite

    desc "favorites", "Returns the #{DEFAULT_NUM_RESULTS} most recent Tweets you favorited."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    def favorites
      count = options['number'] || DEFAULT_NUM_RESULTS
      statuses = client.favorites(:count => count, :include_entities => false)
      print_status_list(statuses)
    end
    map %w(faves) => :favorites

    desc "follow SCREEN_NAME [SCREEN_NAME...]", "Allows you to start following users."
    def follow(screen_name, *screen_names)
      screen_names.unshift(screen_name)
      screen_names.map!(&:strip_ats)
      screen_names.threaded_each do |screen_name|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.follow(screen_name, :include_entities => false)
        end
      end
      number = screen_names.length
      say "@#{@rcfile.default_profile[0]} is now following #{number} more #{number == 1 ? 'user' : 'users'}."
      say
      say "Run `#{File.basename($0)} unfollow #{screen_names.map{|screen_name| "@#{screen_name}"}.join(' ')}` to stop."
    end

    desc "followings", "Returns a list of the people you follow on Twitter."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def followings
      following_ids = collect_with_cursor do |cursor|
        client.friend_ids(:cursor => cursor)
      end
      users = following_ids.in_groups_of(MAX_USERS_PER_REQUEST, false).threaded_map do |following_id_group|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.users(following_id_group, :include_entities => false)
        end
      end.flatten
      print_user_list(users)
    end

    desc "followers", "Returns a list of the people who follow you on Twitter."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def followers
      follower_ids = collect_with_cursor do |cursor|
        client.follower_ids(:cursor => cursor)
      end
      users = follower_ids.in_groups_of(MAX_USERS_PER_REQUEST, false).threaded_map do |follower_id_group|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.users(follower_id_group, :include_entities => false)
        end
      end.flatten
      print_user_list(users)
    end

    desc "friends", "Returns the list of people who you follow and follow you back."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def friends
      following_ids = collect_with_cursor do |cursor|
        client.friend_ids(:cursor => cursor)
      end
      follower_ids = collect_with_cursor do |cursor|
        client.follower_ids(:cursor => cursor)
      end
      friend_ids = (following_ids & follower_ids)
      users = friend_ids.in_groups_of(MAX_USERS_PER_REQUEST, false).threaded_map do |friend_id_group|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.users(friend_id_group, :include_entities => false)
        end
      end.flatten
      print_user_list(users)
    end

    desc "leaders", "Returns the list of people who you follow but don't follow you back."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def leaders
      following_ids = collect_with_cursor do |cursor|
        client.friend_ids(:cursor => cursor)
      end
      follower_ids = collect_with_cursor do |cursor|
        client.follower_ids(:cursor => cursor)
      end
      leader_ids = (following_ids - follower_ids)
      users = leader_ids.in_groups_of(MAX_USERS_PER_REQUEST, false).threaded_map do |leader_id_group|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.users(leader_id_group, :include_entities => false)
        end
      end.flatten
      print_user_list(users)
    end

    desc "mentions", "Returns the #{DEFAULT_NUM_RESULTS} most recent Tweets mentioning you."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    def mentions
      count = options['number'] || DEFAULT_NUM_RESULTS
      statuses = client.mentions(:count => count, :include_entities => false)
      print_status_list(statuses)
    end
    map %w(replies) => :mentions

    desc "open SCREEN_NAME", "Opens that user's profile in a web browser."
    method_option :dry_run, :type => :boolean
    def open(screen_name)
      screen_name = screen_name.strip_ats
      Launchy.open("https://twitter.com/#{screen_name}", :dry_run => options.fetch('dry_run', false))
    end

    desc "reply STATUS_ID MESSAGE", "Post your Tweet as a reply directed at another person."
    method_option :location, :aliases => "-l", :type => :boolean, :default => false
    def reply(status_id, message)
      status_id = status_id.strip_commas
      status = client.status(status_id, :include_entities => false, :include_my_retweet => false)
      opts = {:in_reply_to_status_id => status.id, :include_entities => false, :trim_user => true}
      opts.merge!(:lat => location.lat, :long => location.lng) if options['location']
      reply = client.update("@#{status.user.screen_name} #{message}", opts)
      say "Reply created by @#{@rcfile.default_profile[0]} to @#{status.user.screen_name} (#{time_ago_in_words(reply.created_at)} ago)."
      say
      say "Run `#{File.basename($0)} delete status #{reply.id}` to delete."
    end

    desc "report_spam SCREEN_NAME [SCREEN_NAME...]", "Report users for spam."
    def report_spam(screen_name, *screen_names)
      screen_names.unshift(screen_name)
      screen_names.map!(&:strip_ats)
      screen_names.threaded_each do |screen_name|
        screen_name.strip_ats
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.report_spam(screen_name, :include_entities => false)
        end
      end
      number = screen_names.length
      say "@#{@rcfile.default_profile[0]} reported #{number} #{number == 1 ? 'user' : 'users'}."
    end
    map %w(report spam) => :report_spam

    desc "retweet STATUS_ID [STATUS_ID...]", "Sends Tweets to your followers."
    def retweet(status_id, *status_ids)
      status_ids.unshift(status_id)
      status_ids.map!(&:strip_commas).map!(&:to_i)
      retweets = status_ids.threaded_map do |status_id|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.retweet(status_id, :include_entities => false, :trim_user => true)
        end
      end
      number = retweets.length
      say "@#{@rcfile.default_profile[0]} retweeted #{number} #{number == 1 ? 'tweet' : 'tweets'}."
      say
      say "Run `#{File.basename($0)} delete status #{status_ids.join(' ')}` to undo."
    end
    map %w(rt) => :retweet

    desc "retweets [SCREEN_NAME]", "Returns the #{DEFAULT_NUM_RESULTS} most recent Retweets by a user."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    def retweets(screen_name=nil)
      screen_name = screen_name.strip_ats if screen_name
      count = options['number'] || DEFAULT_NUM_RESULTS
      statuses = client.retweeted_by(screen_name, :count => count, :include_entities => false)
      print_status_list(statuses)
    end
    map %w(rts) => :retweets

    desc "status STATUS_ID", "Retrieves detailed information about a Tweet."
    def status(status_id)
      status_id = status_id.strip_commas
      status = client.status(status_id, :include_entities => false, :include_my_retweet => false)
      created_at = status.created_at > 6.months.ago ? status.created_at.strftime("%b %e %H:%M") : status.created_at.strftime("%b %e  %Y")
      array = []
      array << ["ID", status.id.to_s]
      array << ["Text", status.text.gsub(/\n+/, ' ')]
      array << ["Screen name", "@#{status.user.screen_name}"]
      array << ["Posted at", created_at]
      unless status.geo.nil?
        location = Geokit::Geocoders::MultiGeocoder.reverse_geocode(status.geo.coordinates)
        if location.city && location.state && location.country
          array << ["Location", [location.city, location.state, location.country].join(", ")]
        elsif location.state && location.country
          array << ["Location", [location.state, location.country].join(", ")]
        elsif location.country
          array << ["Location", location.country]
        end
      end
      array << ["Retweets", number_with_delimiter(status.retweet_count)] unless status.retweet_count.zero?
      array << ["Source", strip_tags(status.source)]
      array << ["URL", "https://twitter.com/#{status.user.screen_name}/status/#{status.id}"]
      print_table(array)
    end

    desc "suggest", "This command returns a listing of Twitter users' accounts we think you might enjoy following."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def suggest
      limit = options['number'] || DEFAULT_NUM_RESULTS
      users = client.recommendations(:limit => limit, :include_entities => false)
      print_user_list(users)
    end

    desc "timeline [SCREEN_NAME]", "Returns the #{DEFAULT_NUM_RESULTS} most recent Tweets posted by a user."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :number, :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS, :desc => "Limit the number of results."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    def timeline(screen_name=nil)
      count = options['number'] || DEFAULT_NUM_RESULTS
      if screen_name
        screen_name = screen_name.strip_ats
        statuses = client.user_timeline(screen_name, :count => count, :include_entities => false)
      else
        statuses = client.home_timeline(:count => count, :include_entities => false)
      end
      print_status_list(statuses)
    end
    map %w(tl) => :timeline

    desc "unfollow SCREEN_NAME [SCREEN_NAME...]", "Allows you to stop following users."
    def unfollow(screen_name, *screen_names)
      screen_names.unshift(screen_name)
      screen_names.map!(&:strip_ats)
      screen_names.threaded_each do |screen_name|
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.unfollow(screen_name, :include_entities => false)
        end
      end
      number = screen_names.length
      say "@#{@rcfile.default_profile[0]} is no longer following #{number} #{number == 1 ? 'user' : 'users'}."
      say
      say "Run `#{File.basename($0)} follow #{screen_names.map{|screen_name| "@#{screen_name}"}.join(' ')}` to follow again."
    end

    desc "update MESSAGE", "Post a Tweet."
    method_option :location, :aliases => "-l", :type => :boolean, :default => false
    def update(message)
      opts = {:include_entities => false, :trim_user => true}
      opts.merge!(:lat => location.lat, :long => location.lng) if options['location']
      status = client.update(message, opts)
      say "Tweet created by @#{@rcfile.default_profile[0]} (#{time_ago_in_words(status.created_at)} ago)."
      say
      say "Run `#{File.basename($0)} delete status #{status.id}` to delete."
    end
    map %w(post tweet) => :update

    desc "users SCREEN_NAME [SCREEN_NAME...]", "Returns a list of users you specify."
    method_option :created, :aliases => "-c", :type => :boolean, :default => false, :desc => "Sort by the time when Twitter acount was created."
    method_option :favorites, :aliases => "-v", :type => :boolean, :default => false, :desc => "Sort by number of favorites."
    method_option :followers, :aliases => "-f", :type => :boolean, :default => false, :desc => "Sort by number of followers."
    method_option :friends, :aliases => "-d", :type => :boolean, :default => false, :desc => "Sort by number of friends."
    method_option :listed, :aliases => "-i", :type => :boolean, :default => false, :desc => "Sort by number of list memberships."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    method_option :reverse, :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option :tweets, :aliases => "-t", :type => :boolean, :default => false, :desc => "Sort by number of Tweets."
    method_option :unsorted, :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def users(screen_name, *screen_names)
      screen_names.unshift(screen_name)
      screen_names.map!(&:strip_ats)
      users = client.users(screen_names, :include_entities => false)
      print_user_list(users)
    end
    map %w(stats) => :users

    desc "version", "Show version."
    def version
      say T::Version
    end
    map %w(-v --version) => :version

    desc "whois SCREEN_NAME", "Retrieves profile information for the user."
    def whois(screen_name)
      screen_name = screen_name.strip_ats
      user = client.user(screen_name, :include_entities => false)
      array = []
      name_label = user.verified ? "Name (Verified)" : "Name"
      array << ["ID", user.id.to_s]
      array << [name_label, user.name] unless user.name.nil?
      array << ["Bio", user.description.gsub(/\n+/, ' ')] unless user.description.nil?
      array << ["Location", user.location] unless user.location.nil?
      array << ["URL", user.url] unless user.url.nil?
      following = user.following ? "Following" : "Not following"
      array << ["Status", following] unless user.following.nil?
      array << ["Last update", "#{user.status.text.gsub(/\n+/, ' ')} (#{time_ago_in_words(user.status.created_at)} ago)"] unless user.status.nil?
      created_at = user.created_at > 6.months.ago ? user.created_at.strftime("%b %e %H:%M") : user.created_at.strftime("%b %e  %Y")
      array << ["Since", created_at]
      array << ["Tweets", number_with_delimiter(user.statuses_count)]
      array << ["Favorites", number_with_delimiter(user.favourites_count)]
      array << ["Listed", number_with_delimiter(user.listed_count)]
      array << ["Following", number_with_delimiter(user.friends_count)]
      array << ["Followers", number_with_delimiter(user.followers_count)]
      print_table(array)
    end

    desc "delete SUBCOMMAND ...ARGS", "Delete Tweets, Direct Messages, etc."
    method_option :force, :aliases => "-f", :type => :boolean, :default => false
    subcommand 'delete', T::Delete

    desc "list SUBCOMMAND ...ARGS", "Do various things with lists."
    subcommand 'list', T::List

    desc "search SUBCOMMAND ...ARGS", "Search through Tweets."
    method_option :long, :aliases => "-l", :type => :boolean, :default => false, :desc => "List in long format."
    subcommand 'search', T::Search

    desc "set SUBCOMMAND ...ARGS", "Change various account settings."
    subcommand 'set', T::Set

  private

    def consumer
      OAuth::Consumer.new(
        options['consumer_key'],
        options['consumer_secret'],
        :site => base_url
      )
    end

    def generate_authorize_url(request_token)
      request = consumer.create_signed_request(:get, consumer.authorize_path, request_token, pin_auth_parameters)
      params = request['Authorization'].sub(/^OAuth\s+/, '').split(/,\s+/).map do |param|
        key, value = param.split('=')
        value =~ /"(.*?)"/
        "#{key}=#{CGI::escape($1)}"
      end.join('&')
      "#{base_url}#{request.path}?#{params}"
    end

    def location
      return @location if @location
      ip_address = Kernel::open("http://checkip.dyndns.org/") do |body|
        /(?:\d{1,3}\.){3}\d{1,3}/.match(body.read)[0]
      end
      @location = Geokit::Geocoders::MultiGeocoder.geocode(ip_address)
    end

    def pin_auth_parameters
      {:oauth_callback => 'oob'}
    end

  end
end
