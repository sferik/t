require 'thor'
require 'twitter'
require 't/collectable'
require 't/printable'
require 't/rcfile'
require 't/requestable'
require 't/utils'

module T
  class Search < Thor
    include T::Collectable
    include T::Printable
    include T::Requestable
    include T::Utils

    DEFAULT_NUM_RESULTS = 20
    MAX_NUM_RESULTS = 200

    check_unknown_options!

    class_option "host", :aliases => "-H", :type => :string, :default => T::Requestable::DEFAULT_HOST, :desc => "Twitter API server"
    class_option "no-color", :aliases => "-N", :type => :boolean, :desc => "Disable colorization in output"
    class_option "no-ssl", :aliases => "-U", :type => :boolean, :default => false, :desc => "Disable SSL"
    class_option "profile", :aliases => "-P", :type => :string, :default => File.join(File.expand_path("~"), T::RCFile::FILE_NAME), :desc => "Path to RC file", :banner => "FILE"

    def initialize(*)
      @rcfile = T::RCFile.instance
      super
    end

    desc "all QUERY", "Returns the #{DEFAULT_NUM_RESULTS} most recent Tweets that match the specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "decode_urls", :aliases => "-d", :type => :boolean, :default => false, :desc => "Decodes t.co URLs into their original form."
    method_option "number", :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS
    def all(query)
      rpp = options['number'] || DEFAULT_NUM_RESULTS
      tweets = collect_with_rpp(rpp) do |opts|
        opts[:include_entities] = 1 if options['decode_urls']
        client.search(query, opts).results
      end
      tweets.reverse! if options['reverse']
      require 'htmlentities'
      if options['csv']
        require 'csv'
        require 'fastercsv' unless Array.new.respond_to?(:to_csv)
        say TWEET_HEADINGS.to_csv unless tweets.empty?
        tweets.each do |tweet|
          say [tweet.id, csv_formatted_time(tweet), tweet.from_user, decode_full_text(tweet)].to_csv
        end
      elsif options['long']
        array = tweets.map do |tweet|
          [tweet.id, ls_formatted_time(tweet), "@#{tweet.from_user}", decode_full_text(tweet, options['decode_urls']).gsub(/\n+/, ' ')]
        end
        format = options['format'] || TWEET_HEADINGS.size.times.map{"%s"}
        print_table_with_headings(array, TWEET_HEADINGS, format)
      else
        say unless tweets.empty?
        tweets.each do |tweet|
          print_message(tweet.from_user, decode_full_text(tweet, options['decode_urls']))
        end
      end
    end

    desc "favorites [USER] QUERY", "Returns Tweets you've favorited that match the specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "id", :aliases => "-i", :type => :boolean, :default => false, :desc => "Specify user via ID instead of screen name."
    method_option "decode_urls", :aliases => "-d", :type => :boolean, :default => false, :desc => "Decodes t.co URLs into their original form."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def favorites(*args)
      opts = {:count => MAX_NUM_RESULTS}
      query = args.pop
      user = args.pop
      opts[:include_entities] = 1 if options['decode_urls']
      if user
        require 't/core_ext/string'
        user = if options['id']
          user.to_i
        else
          user.strip_ats
        end
        tweets = collect_with_max_id do |max_id|
          opts[:max_id] = max_id unless max_id.nil?
          client.favorites(user, opts)
        end
      else
        tweets = collect_with_max_id do |max_id|
          opts[:max_id] = max_id unless max_id.nil?
          client.favorites(opts)
        end
      end
      tweets = tweets.select do |tweet|
        /#{query}/i.match(tweet.full_text)
      end
      print_tweets(tweets)
    end
    map %w(faves) => :favorites

    desc "list [USER/]LIST QUERY", "Returns Tweets on a list that match specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "id", :aliases => "-i", :type => :boolean, :default => false, :desc => "Specify user via ID instead of screen name."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "decode_urls", :aliases => "-d", :type => :boolean, :default => false, :desc => "Decodes t.co URLs into their original form."
    def list(list, query)
      owner, list = extract_owner(list, options)
      opts = {:count => MAX_NUM_RESULTS}
      opts[:include_entities] = 1 if options['decode_urls']
      tweets = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        client.list_timeline(owner, list, opts)
      end
      tweets = tweets.select do |tweet|
        /#{query}/i.match(tweet.full_text)
      end
      print_tweets(tweets)
    end

    desc "mentions QUERY", "Returns Tweets mentioning you that match the specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "decode_urls", :aliases => "-d", :type => :boolean, :default => false, :desc => "Decodes t.co URLs into their original form."
    def mentions(query)
      opts = {:count => MAX_NUM_RESULTS}
      opts[:include_entities] = 1 if options['decode_urls']
      tweets = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        client.mentions(opts)
      end
      tweets = tweets.select do |tweet|
        /#{query}/i.match(tweet.full_text)
      end
      print_tweets(tweets)
    end
    map %w(replies) => :mentions

    desc "retweets [USER] QUERY", "Returns Tweets you've retweeted that match the specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "id", :aliases => "-i", :type => :boolean, :default => false, :desc => "Specify user via ID instead of screen name."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "decode_urls", :aliases => "-d", :type => :boolean, :default => false, :desc => "Decodes t.co URLs into their original form."
    def retweets(*args)
      opts = {:count => MAX_NUM_RESULTS}
      query = args.pop
      user = args.pop
      opts[:include_entities] = 1 if options['decode_urls']
      if user
        require 't/core_ext/string'
        user = if options['id']
          user.to_i
        else
          user.strip_ats
        end
        tweets = collect_with_max_id do |max_id|
          opts[:max_id] = max_id unless max_id.nil?
          client.retweeted_by_user(user, opts)
        end
      else
        tweets = collect_with_max_id do |max_id|
          opts[:max_id] = max_id unless max_id.nil?
          client.retweeted_by_me(opts)
        end
      end
      tweets = tweets.select do |tweet|
        /#{query}/i.match(tweet.full_text)
      end
      print_tweets(tweets)
    end
    map %w(rts) => :retweets

    desc "timeline [USER] QUERY", "Returns Tweets in your timeline that match the specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "exclude", :aliases => "-e", :type => :string, :enum => %w(replies retweets), :desc => "Exclude certain types of Tweets from the results.", :banner => "TYPE"
    method_option "id", :aliases => "-i", :type => :boolean, :default => false, :desc => "Specify user via ID instead of screen name."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "decode_urls", :aliases => "-d", :type => :boolean, :default => false, :desc => "Decodes t.co URLs into their original form."
    def timeline(*args)
      opts = {:count => MAX_NUM_RESULTS}
      query = args.pop
      user = args.pop
      opts[:include_entities] = 1 if options['decode_urls']
      exclude_opts = case options['exclude']
      when 'replies'
        {:exclude_replies => true}
      when 'retweets'
        {:include_rts => false}
      else
        {}
      end
      if user
        require 't/core_ext/string'
        user = if options['id']
          user.to_i
        else
          user.strip_ats
        end
        tweets = collect_with_max_id do |max_id|
          opts[:max_id] = max_id unless max_id.nil?
          client.user_timeline(user, opts.merge(exclude_opts))
        end
      else
        tweets = collect_with_max_id do |max_id|
          opts[:max_id] = max_id unless max_id.nil?
          client.home_timeline(opts.merge(exclude_opts))
        end
      end
      tweets = tweets.select do |tweet|
        /#{query}/i.match(tweet.full_text)
      end
      print_tweets(tweets)
    end
    map %w(tl) => :timeline

    desc "users QUERY", "Returns users that match the specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "reverse", :aliases => "-r", :type => :boolean, :default => false, :desc => "Reverse the order of the sort."
    method_option "sort", :aliases => "-s", :type => :string, :enum => %w(favorites followers friends listed screen_name since tweets tweeted), :default => "screen_name", :desc => "Specify the order of the results.", :banner => "ORDER"
    method_option "unsorted", :aliases => "-u", :type => :boolean, :default => false, :desc => "Output is not sorted."
    def users(query)
      users = collect_with_page do |page|
        client.user_search(query, :page => page)
      end
      print_users(users)
    end

  end
end
