module T
  module Printable
    LIST_HEADINGS = ['ID', 'Created at', 'Screen name', 'Slug', 'Members', 'Subscribers', 'Mode', 'Description']
    TWEET_HEADINGS = ['ID', 'Posted at', 'Screen name', 'Text']
    USER_HEADINGS = ['ID', 'Since', 'Last tweeted at', 'Tweets', 'Favorites', 'Listed', 'Following', 'Followers', 'Screen name', 'Name', 'Verified', 'Protected', 'Bio', 'Status', 'Location', 'URL']
    MONTH_IN_SECONDS = 2_592_000

    TWEET_WITH_USER_HEADINGS = ['ID', 'Posted at', 'Screen name', 'Text', 
        'User ID', 'Since', 'Last tweeted at', 'Tweets', 'Favorites', 'Listed', 'Following', 'Followers', 'Name', 'Verified', 'Protected', 'Bio', 'Location', 'URL'
    ]

  private

    def build_long_list(list)
      [list.id, ls_formatted_time(list), "@#{list.user.screen_name}", list.slug, list.member_count, list.subscriber_count, list.mode, list.description]
    end

    def build_long_tweet(tweet)
      [tweet.id, ls_formatted_time(tweet), "@#{tweet.user.screen_name}", decode_full_text(tweet, options['decode_uris']).gsub(/\n+/, ' ')]
    end

    def build_long_user(user)
      [user.id, ls_formatted_time(user), ls_formatted_time(user.status), user.statuses_count, user.favorites_count, user.listed_count, user.friends_count, user.followers_count, "@#{user.screen_name}", user.name, user.verified? ? 'Yes' : 'No', user.protected? ? 'Yes' : 'No', user.description.gsub(/\n+/, ' '), user.status? ? decode_full_text(user.status, options['decode_uris']).gsub(/\n+/, ' ') : nil, user.location, user.website.to_s]
    end

    def build_long_tweet_with_user(tweet)
      user = tweet.user

      build_long_tweet(tweet) + 
            [user.id, ls_formatted_time(user), ls_formatted_time(user.status), user.statuses_count, user.favorites_count, user.listed_count, user.friends_count, user.followers_count, user.name, user.verified? ? 'Yes' : 'No', user.protected? ? 'Yes' : 'No', user.description.gsub(/\n+/, ' '), user.location, user.website.to_s]
    end

    def csv_formatted_time(object, key = :created_at)
      return nil if object.nil?
      time = object.send(key.to_sym).dup
      time.utc.strftime('%Y-%m-%d %H:%M:%S %z')
    end

    def ls_formatted_time(object, key = :created_at, allow_relative = true)
      return '' if object.nil?
      time = T.local_time(object.send(key.to_sym))
      if allow_relative && options['relative_dates']
        distance_of_time_in_words(time) + ' ago'
      elsif time > Time.now - MONTH_IN_SECONDS * 6
        time.strftime('%b %e %H:%M')
      else
        time.strftime('%b %e  %Y')
      end
    end

    def print_csv_list(list)
      require 'csv'
      say [list.id, csv_formatted_time(list), list.user.screen_name, list.slug, list.member_count, list.subscriber_count, list.mode, list.description].to_csv
    end

    def print_csv_tweet(tweet)
      require 'csv'
      say [tweet.id, csv_formatted_time(tweet), tweet.user.screen_name, decode_full_text(tweet, options['decode_uris'])].to_csv
    end

    def print_csv_user(user)
      require 'csv'
      say [user.id, csv_formatted_time(user), csv_formatted_time(user.status), user.statuses_count, user.favorites_count, user.listed_count, user.friends_count, user.followers_count, user.screen_name, user.name, user.verified?, user.protected?, user.description, user.status? ? user.status.full_text : nil, user.location, user.website].to_csv
    end

    def print_csv_tweet_with_user(tweet)
      require 'csv'
      user = tweet.user
      arr = [tweet.id, csv_formatted_time(tweet), user.screen_name, decode_full_text(tweet, options['decode_uris'])] \
              + \
             [user.id, csv_formatted_time(user), csv_formatted_time(user.status), user.statuses_count, user.favorites_count, user.listed_count, user.friends_count, user.followers_count, user.name, user.verified?, user.protected?, user.description, user.location, user.website]

      say arr.to_csv
    end

    def print_lists(lists)
      lists = case options['sort']
      when 'members'
        lists.sort_by { |user| user.member_count }
      when 'mode'
        lists.sort_by { |user| user.mode }
      when 'since'
        lists.sort_by { |user| user.created_at }
      when 'subscribers'
        lists.sort_by { |user| user.subscriber_count }
      else
        lists.sort_by { |list| list.slug.downcase }
      end unless options['unsorted']
      lists.reverse! if options['reverse']
      if options['csv']
        require 'csv'
        say LIST_HEADINGS.to_csv unless lists.empty?
        lists.each do |list|
          print_csv_list(list)
        end
      elsif options['long']
        array = lists.collect do |list|
          build_long_list(list)
        end
        format = options['format'] || LIST_HEADINGS.size.times.collect { '%s' }
        print_table_with_headings(array, LIST_HEADINGS, format)
      else
        print_attribute(lists, :full_name)
      end
    end

    def print_attribute(array, attribute)
      if STDOUT.tty?
        print_in_columns(array.collect(&attribute.to_sym))
      else
        array.each do |element|
          say element.send(attribute.to_sym)
        end
      end
    end

    def print_table_with_headings(array, headings, format)
      return if array.flatten.empty?
      if STDOUT.tty?
        array.unshift(headings)
        require 't/core_ext/kernel'
        array.collect! do |row|
          row.each_with_index.collect do |element, index|
            Kernel.send(element.class.name.to_sym, format[index] % element)
          end
        end
        print_table(array, :truncate => true)
      else
        print_table(array)
      end
    end

    def print_message(from_user, message)
      case options['color']
      when 'auto'
        say("   @#{from_user}", [:bold, :yellow])
      else
        say("   @#{from_user}")
      end
      require 'htmlentities'
      print_wrapped(HTMLEntities.new.decode(message), :indent => 3)
      say
    end


    #  The tweets that are passed in have the :user object, since
    #  :trim_user was set to false
    def print_tweets_with_users(tweets)
      tweets.reverse! if options['reverse']
      if options['csv']
        require 'csv'
        say TWEET_WITH_USER_HEADINGS.to_csv unless tweets.empty?
        tweets.each do |tweet|
          print_csv_tweet_with_user(tweet)
        end
      else 
      # Currently, there is no "short" format for tweet + user, so the default
      # is to output the long format
        array = tweets.map do |tweet|
          build_long_tweet_with_user(tweet)
        end
        format = options['format'] || TWEET_WITH_USER_HEADINGS.size.times.map{ '%s'}
        print_table_with_headings(array, TWEET_WITH_USER_HEADINGS, format)
      end
    end

    def print_tweets(tweets)
      tweets.reverse! if options['reverse']
      if options['csv']
        require 'csv'
        say TWEET_HEADINGS.to_csv unless tweets.empty?
        tweets.each do |tweet|
          print_csv_tweet(tweet)
        end
      elsif options['long']
        array = tweets.collect do |tweet|
          build_long_tweet(tweet)
        end
        format = options['format'] || TWEET_HEADINGS.size.times.collect { '%s' }
        print_table_with_headings(array, TWEET_HEADINGS, format)
      else
        tweets.each do |tweet|
          print_message(tweet.user.screen_name, decode_uris(tweet.full_text, options['decode_uris'] ? tweet.uris : nil))
        end
      end
    end

    def print_users(users) # rubocop:disable CyclomaticComplexity
      users = case options['sort']
      when 'favorites'
        users.sort_by { |user| user.favorites_count.to_i }
      when 'followers'
        users.sort_by { |user| user.followers_count.to_i }
      when 'friends'
        users.sort_by { |user| user.friends_count.to_i }
      when 'listed'
        users.sort_by { |user| user.listed_count.to_i }
      when 'since'
        users.sort_by { |user| user.created_at }
      when 'tweets'
        users.sort_by { |user| user.statuses_count.to_i }
      when 'tweeted'
        users.sort_by { |user| user.status? ? user.status.created_at : Time.at(0) }
      else
        users.sort_by { |user| user.screen_name.downcase }
      end unless options['unsorted']
      users.reverse! if options['reverse']
      if options['csv']
        require 'csv'
        say USER_HEADINGS.to_csv unless users.empty?
        users.each do |user|
          print_csv_user(user)
        end
      elsif options['long']
        array = users.collect do |user|
          build_long_user(user)
        end
        format = options['format'] || USER_HEADINGS.size.times.collect { '%s' }
        print_table_with_headings(array, USER_HEADINGS, format)
      else
        print_attribute(users, :screen_name)
      end
    end
  end
end
