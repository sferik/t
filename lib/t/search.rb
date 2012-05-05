require 'action_view'
require 'csv'
# 'fastercsv' required on Ruby versions < 1.9
require 'fastercsv' unless Array.new.respond_to?(:to_csv)
require 'htmlentities'
require 'retryable'
require 't/collectable'
require 't/printable'
require 't/rcfile'
require 't/requestable'
require 'thor'

module T
  class Search < Thor
    include ActionView::Helpers::DateHelper
    include T::Collectable
    include T::Printable
    include T::Requestable

    DEFAULT_NUM_RESULTS = 20
    MAX_NUM_RESULTS = 200
    MAX_SCREEN_NAME_SIZE = 20

    check_unknown_options!

    def initialize(*)
      super
      @rcfile = RCFile.instance
    end

    desc "all QUERY", "Returns the #{DEFAULT_NUM_RESULTS} most recent Tweets that match a specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    method_option "number", :aliases => "-n", :type => :numeric, :default => DEFAULT_NUM_RESULTS
    def all(query)
      count = options['number'] || DEFAULT_NUM_RESULTS
      statuses = collect_with_count(:search, count, {:args => [query], :count_key => :rpp})
      if options['csv']
        say ["ID", "Posted at", "Screen name", "Text"].to_csv unless statuses.empty?
        statuses.each do |status|
          say [status.id, status.created_at.utc.strftime("%Y-%m-%d %H:%M:%S %z"), status.from_user, HTMLEntities.new.decode(status.text)].to_csv
        end
      elsif options['long']
        array = statuses.map do |status|
          created_at = status.created_at > 6.months.ago ? status.created_at.strftime("%b %e %H:%M") : status.created_at.strftime("%b %e  %Y")
          [status.id, created_at, "@#{status.from_user}", HTMLEntities.new.decode(status.text).gsub(/\n+/, ' ')]
        end
        if STDOUT.tty?
          headings = ["ID", "Posted at", "Screen name", "Text"]
          array.unshift(headings) unless statuses.empty?
          print_table(array, :truncate => true)
        else
          print_table(array)
        end
      else
        say unless statuses.empty?
        statuses.each do |status|
          if STDOUT.tty? && !options['no-color']
            say("   #{Thor::Shell::Color::BOLD}@#{status.from_user}", :yellow)
            print_wrapped(HTMLEntities.new.decode(status.text), :indent => 3)
          else
            say("   @#{status.from_user}")
            print_wrapped(HTMLEntities.new.decode(status.text), :indent => 3)
          end
          say
        end
      end
    end

    desc "favorites QUERY", "Returns Tweets you've favorited that match a specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def favorites(query)
      opts = {:count => MAX_NUM_RESULTS}
      statuses = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.favorites(opts)
        end
      end.flatten.compact
      statuses = statuses.select do |status|
        /#{query}/i.match(status.text)
      end
      print_statuses(statuses)
    end
    map %w(faves) => :favorites

    desc "list [USER/]LIST QUERY", "Returns Tweets on a list that match specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "id", :aliases => "-i", :type => "boolean", :default => false, :desc => "Specify user via ID instead of screen name."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def list(list, query)
      owner, list = list.split('/')
      if list.nil?
        list = owner
        owner = @rcfile.active_profile[0]
      else
        owner = if options['id']
          owner.to_i
        else
          owner.strip_ats
        end
      end
      opts = {:count => MAX_NUM_RESULTS}
      statuses = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.list_timeline(owner, list, opts)
        end
      end.flatten.compact
      statuses = statuses.select do |status|
        /#{query}/i.match(status.text)
      end
      print_statuses(statuses)
    end

    desc "mentions QUERY", "Returns Tweets mentioning you that match a specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def mentions(query)
      opts = {:count => MAX_NUM_RESULTS}
      statuses = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.mentions(opts)
        end
      end.flatten.compact
      statuses = statuses.select do |status|
        /#{query}/i.match(status.text)
      end
      print_statuses(statuses)
    end
    map %w(replies) => :mentions

    desc "retweets QUERY", "Returns Tweets you've retweeted that match a specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def retweets(query)
      opts = {:count => MAX_NUM_RESULTS}
      statuses = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.retweeted_by(opts)
        end
      end.flatten.compact
      statuses = statuses.select do |status|
        /#{query}/i.match(status.text)
      end
      print_statuses(statuses)
    end
    map %w(rts) => :retweets

    desc "timeline QUERY", "Returns Tweets in your timeline that match a specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def timeline(query)
      opts = {:count => MAX_NUM_RESULTS}
      statuses = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.home_timeline(opts)
        end
      end.flatten.compact
      statuses = statuses.select do |status|
        /#{query}/i.match(status.text)
      end
      print_statuses(statuses)
    end
    map %w(tl) => :timeline

    desc "user USER QUERY", "Returns Tweets in a user's timeline that match a specified query."
    method_option "csv", :aliases => "-c", :type => :boolean, :default => false, :desc => "Output in CSV format."
    method_option "id", :aliases => "-i", :type => "boolean", :default => false, :desc => "Specify user via ID instead of screen name."
    method_option "long", :aliases => "-l", :type => :boolean, :default => false, :desc => "Output in long format."
    def user(user, query)
      user = if options['id']
        user.to_i
      else
        user.strip_ats
      end
      opts = {:count => MAX_NUM_RESULTS}
      statuses = collect_with_max_id do |max_id|
        opts[:max_id] = max_id unless max_id.nil?
        retryable(:tries => 3, :on => Twitter::Error::ServerError, :sleep => 0) do
          client.user_timeline(user, opts)
        end
      end.flatten.compact
      statuses = statuses.select do |status|
        /#{query}/i.match(status.text)
      end
      print_statuses(statuses)
    end

  end
end
