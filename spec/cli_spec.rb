# encoding: utf-8
require 'helper'

describe T::CLI do

  before :all do
    Timecop.freeze(Time.utc(2011, 11, 24, 16, 20, 0))
    T.utc_offset = 'PST'
  end

  after :all do
    T.utc_offset = nil
    Timecop.return
  end

  before :each do
    T::RCFile.instance.path = fixture_path + "/.trc"
    @cli = T::CLI.new
    @old_stderr = $stderr
    $stderr = StringIO.new
    @old_stdout = $stdout
    $stdout = StringIO.new
  end

  after :each do
    T::RCFile.instance.reset
    $stderr = @old_stderr
    $stdout = @old_stdout
  end

  describe "#account" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
    end
    it "has the correct output" do
      @cli.accounts
      expect($stdout.string).to eq <<-eos
testcli
  abc123 (active)
      eos
    end
  end

  describe "#authorize" do
    before do
      @cli.options = @cli.options.merge("profile" => project_path + "/tmp/authorize", "display-url" => true)
      stub_post("/oauth/request_token").to_return(:body => fixture("request_token"))
      stub_post("/oauth/access_token").to_return(:body => fixture("access_token"))
      stub_get("/1.1/account/verify_credentials.json").with(:query => {:include_entities => "false", :skip_status => "true"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      $stdout.should_receive(:print)
      $stdin.should_receive(:gets).and_return("\n")
      $stdout.should_receive(:print).with("Enter your consumer key: ")
      $stdin.should_receive(:gets).and_return("abc123")
      $stdout.should_receive(:print).with("Enter your consumer secret: ")
      $stdin.should_receive(:gets).and_return("asdfasd223sd2")
      $stdout.should_receive(:print).with("Press [Enter] to open the Twitter app authorization page. ")
      $stdin.should_receive(:gets).and_return("\n")
      $stdout.should_receive(:print).with("Enter the supplied PIN: ")
      $stdin.should_receive(:gets).and_return("1234567890")
      @cli.authorize
      expect(a_post("/oauth/request_token")).to have_been_made
      expect(a_post("/oauth/access_token")).to have_been_made
      expect(a_get("/1.1/account/verify_credentials.json").with(:query => {:include_entities => "false", :skip_status => "true"})).to have_been_made
    end
    it "does not raise error" do
      expect do
        $stdout.should_receive(:print)
        $stdin.should_receive(:gets).and_return("\n")
        $stdout.should_receive(:print).with("Enter your consumer key: ")
        $stdin.should_receive(:gets).and_return("abc123")
        $stdout.should_receive(:print).with("Enter your consumer secret: ")
        $stdin.should_receive(:gets).and_return("asdfasd223sd2")
        $stdout.should_receive(:print).with("Press [Enter] to open the Twitter app authorization page. ")
        $stdin.should_receive(:gets).and_return("\n")
        $stdout.should_receive(:print).with("Enter the supplied PIN: ")
        $stdin.should_receive(:gets).and_return("1234567890")
        @cli.authorize
      end.not_to raise_error
    end
    context "empty RC file" do
      before do
        @cli.options = @cli.options.merge("profile" => project_path + "/tmp/empty", "display-url" => true)
      end
      after do
        File.delete(project_path + "/tmp/empty")
      end
      it "requests the correct resource" do
        $stdout.should_receive(:print)
        $stdin.should_receive(:gets).and_return("\n")
        $stdout.should_receive(:print).with("Enter your consumer key: ")
        $stdin.should_receive(:gets).and_return("abc123")
        $stdout.should_receive(:print).with("Enter your consumer secret: ")
        $stdin.should_receive(:gets).and_return("asdfasd223sd2")
        $stdout.should_receive(:print).with("Press [Enter] to open the Twitter app authorization page. ")
        $stdin.should_receive(:gets).and_return("\n")
        $stdout.should_receive(:print).with("Enter the supplied PIN: ")
        $stdin.should_receive(:gets).and_return("1234567890")
        @cli.authorize
        expect(a_post("/oauth/request_token")).to have_been_made
        expect(a_post("/oauth/access_token")).to have_been_made
        expect(a_get("/1.1/account/verify_credentials.json").with(:query => {:include_entities => "false", :skip_status => "true"})).to have_been_made
      end
      it "does not raise error" do
        expect do
          $stdout.should_receive(:print)
          $stdin.should_receive(:gets).and_return("\n")
          $stdout.should_receive(:print).with("Enter your consumer key: ")
          $stdin.should_receive(:gets).and_return("abc123")
          $stdout.should_receive(:print).with("Enter your consumer secret: ")
          $stdin.should_receive(:gets).and_return("asdfasd223sd2")
          $stdout.should_receive(:print).with("Press [Enter] to open the Twitter app authorization page. ")
          $stdin.should_receive(:gets).and_return("\n")
          $stdout.should_receive(:print).with("Enter the supplied PIN: ")
          $stdin.should_receive(:gets).and_return("1234567890")
          @cli.authorize
        end.not_to raise_error
      end
    end
  end

  describe "#block" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1.1/blocks/create.json").with(:body => {:screen_name => "sferik"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.block("sferik")
      expect(a_post("/1.1/blocks/create.json").with(:body => {:screen_name => "sferik"})).to have_been_made
    end
    it "has the correct output" do
      @cli.block("sferik")
      expect($stdout.string).to match /^@testcli blocked 1 user/
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_post("/1.1/blocks/create.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.block("7505382")
        expect(a_post("/1.1/blocks/create.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
    end
  end

  describe "#direct_messages" do
    before do
      stub_get("/1.1/direct_messages.json").with(:query => {:count => "20"}).to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1.1/direct_messages.json").with(:query => {:count => "10", "max_id" => "1624782205"}).to_return(:body => fixture("empty_array.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.direct_messages
      expect(a_get("/1.1/direct_messages.json").with(:query => {:count => "20"})).to have_been_made
    end
    it "has the correct output" do
      @cli.direct_messages
      expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @sferik\e[0m
   Sounds good. Meeting Tuesday is fine.

\e[1m\e[33m   @sferik\e[0m
   That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does 
   that work for you?

\e[1m\e[33m   @sferik\e[0m
   I asked Yehuda about the stipend. I believe it has already been sent. Glad 
   you're feeling better.

\e[1m\e[33m   @sferik\e[0m
   Just checking in. How's everything going?

\e[1m\e[33m   @sferik\e[0m
   Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think 
   you'll be able to finish up your work on graphs this weekend?

\e[1m\e[33m   @sferik\e[0m
   How are the graph enhancements coming?

\e[1m\e[33m   @sferik\e[0m
   How are the graphs coming? I'm really looking forward to seeing what you do 
   with Raphaël.

\e[1m\e[33m   @sferik\e[0m
   Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?

\e[1m\e[33m   @sferik\e[0m
   I just committed a bunch of cleanup and fixes to RailsAdmin that touched many 
   of files. Make sure you pull to avoid conflicts.

\e[1m\e[33m   @sferik\e[0m
   I'm trying to debug the issue you were having with the Bundler Gemfile.lock 
   shortref. What version of Ruby and RubyGems are you running?

      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.direct_messages
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text
1773478249,2010-10-17 20:48:55 +0000,sferik,Sounds good. Meeting Tuesday is fine.
1762960771,2010-10-14 21:43:30 +0000,sferik,That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you?
1711812216,2010-10-01 15:07:12 +0000,sferik,I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better.
1711417617,2010-10-01 13:09:27 +0000,sferik,Just checking in. How's everything going?
1653301471,2010-09-16 16:13:27 +0000,sferik,Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend?
1645324992,2010-09-14 18:44:10 +0000,sferik,How are the graph enhancements coming?
1632933616,2010-09-11 17:45:46 +0000,sferik,How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël.
1629239903,2010-09-10 18:21:36 +0000,sferik,Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?
1629166212,2010-09-10 17:56:53 +0000,sferik,I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts.
1624782206,2010-09-09 18:11:48 +0000,sferik,I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running?
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.direct_messages
        expect($stdout.string).to eq <<-eos
Id          Posted at     Screen name  Text
1773478249  Oct 17  2010  @sferik      Sounds good. Meeting Tuesday is fine.
1762960771  Oct 14  2010  @sferik      That's great news! Let's plan to chat ...
1711812216  Oct  1  2010  @sferik      I asked Yehuda about the stipend. I be...
1711417617  Oct  1  2010  @sferik      Just checking in. How's everything going?
1653301471  Sep 16  2010  @sferik      Not sure about the payment. Feel free ...
1645324992  Sep 14  2010  @sferik      How are the graph enhancements coming?
1632933616  Sep 11  2010  @sferik      How are the graphs coming? I'm really ...
1629239903  Sep 10  2010  @sferik      Awesome! Any luck duplicating the Gemf...
1629166212  Sep 10  2010  @sferik      I just committed a bunch of cleanup an...
1624782206  Sep  9  2010  @sferik      I'm trying to debug the issue you were...
        eos
      end
    end
    context "--number" do
      before do
        stub_get("/1.1/direct_messages.json").with(:query => {:count => "1"}).to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/direct_messages.json").with(:query => {:count => "200"}).to_return(:body => fixture("200_direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/direct_messages.json").with(:query => {:count => "1", :max_id => "235851563443306495"}).to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "limits the number of results to 1" do
        @cli.options = @cli.options.merge("number" => 1)
        @cli.direct_messages
        expect(a_get("/1.1/direct_messages.json").with(:query => {:count => "1"})).to have_been_made
      end
      it "limits the number of results to 201" do
        @cli.options = @cli.options.merge("number" => 201)
        @cli.direct_messages
        expect(a_get("/1.1/direct_messages.json").with(:query => {:count => "200"})).to have_been_made
        expect(a_get("/1.1/direct_messages.json").with(:query => {:count => "1", :max_id => "235851563443306495"})).to have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.direct_messages
        expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @sferik\e[0m
   I'm trying to debug the issue you were having with the Bundler Gemfile.lock 
   shortref. What version of Ruby and RubyGems are you running?

\e[1m\e[33m   @sferik\e[0m
   I just committed a bunch of cleanup and fixes to RailsAdmin that touched many 
   of files. Make sure you pull to avoid conflicts.

\e[1m\e[33m   @sferik\e[0m
   Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?

\e[1m\e[33m   @sferik\e[0m
   How are the graphs coming? I'm really looking forward to seeing what you do 
   with Raphaël.

\e[1m\e[33m   @sferik\e[0m
   How are the graph enhancements coming?

\e[1m\e[33m   @sferik\e[0m
   Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think 
   you'll be able to finish up your work on graphs this weekend?

\e[1m\e[33m   @sferik\e[0m
   Just checking in. How's everything going?

\e[1m\e[33m   @sferik\e[0m
   I asked Yehuda about the stipend. I believe it has already been sent. Glad 
   you're feeling better.

\e[1m\e[33m   @sferik\e[0m
   That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does 
   that work for you?

\e[1m\e[33m   @sferik\e[0m
   Sounds good. Meeting Tuesday is fine.

        eos
      end
    end
  end

  describe "#direct_messages_sent" do
    before do
      stub_get("/1.1/direct_messages/sent.json").with(:query => {:count => "20"}).to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1.1/direct_messages/sent.json").with(:query => {:count => "10", "max_id" => "1624782205"}).to_return(:body => fixture("empty_array.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.direct_messages_sent
      expect(a_get("/1.1/direct_messages/sent.json").with(:query => {:count => "20"})).to have_been_made
    end
    it "has the correct output" do
      @cli.direct_messages_sent
      expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @hurrycane\e[0m
   Sounds good. Meeting Tuesday is fine.

\e[1m\e[33m   @hurrycane\e[0m
   That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does 
   that work for you?

\e[1m\e[33m   @hurrycane\e[0m
   I asked Yehuda about the stipend. I believe it has already been sent. Glad 
   you're feeling better.

\e[1m\e[33m   @hurrycane\e[0m
   Just checking in. How's everything going?

\e[1m\e[33m   @hurrycane\e[0m
   Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think 
   you'll be able to finish up your work on graphs this weekend?

\e[1m\e[33m   @hurrycane\e[0m
   How are the graph enhancements coming?

\e[1m\e[33m   @hurrycane\e[0m
   How are the graphs coming? I'm really looking forward to seeing what you do 
   with Raphaël.

\e[1m\e[33m   @hurrycane\e[0m
   Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?

\e[1m\e[33m   @hurrycane\e[0m
   I just committed a bunch of cleanup and fixes to RailsAdmin that touched many 
   of files. Make sure you pull to avoid conflicts.

\e[1m\e[33m   @hurrycane\e[0m
   I'm trying to debug the issue you were having with the Bundler Gemfile.lock 
   shortref. What version of Ruby and RubyGems are you running?

      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.direct_messages_sent
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text
1773478249,2010-10-17 20:48:55 +0000,hurrycane,Sounds good. Meeting Tuesday is fine.
1762960771,2010-10-14 21:43:30 +0000,hurrycane,That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you?
1711812216,2010-10-01 15:07:12 +0000,hurrycane,I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better.
1711417617,2010-10-01 13:09:27 +0000,hurrycane,Just checking in. How's everything going?
1653301471,2010-09-16 16:13:27 +0000,hurrycane,Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend?
1645324992,2010-09-14 18:44:10 +0000,hurrycane,How are the graph enhancements coming?
1632933616,2010-09-11 17:45:46 +0000,hurrycane,How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël.
1629239903,2010-09-10 18:21:36 +0000,hurrycane,Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?
1629166212,2010-09-10 17:56:53 +0000,hurrycane,I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts.
1624782206,2010-09-09 18:11:48 +0000,hurrycane,I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running?
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.direct_messages_sent
        expect($stdout.string).to eq <<-eos
Id          Posted at     Screen name  Text
1773478249  Oct 17  2010  @hurrycane   Sounds good. Meeting Tuesday is fine.
1762960771  Oct 14  2010  @hurrycane   That's great news! Let's plan to chat ...
1711812216  Oct  1  2010  @hurrycane   I asked Yehuda about the stipend. I be...
1711417617  Oct  1  2010  @hurrycane   Just checking in. How's everything going?
1653301471  Sep 16  2010  @hurrycane   Not sure about the payment. Feel free ...
1645324992  Sep 14  2010  @hurrycane   How are the graph enhancements coming?
1632933616  Sep 11  2010  @hurrycane   How are the graphs coming? I'm really ...
1629239903  Sep 10  2010  @hurrycane   Awesome! Any luck duplicating the Gemf...
1629166212  Sep 10  2010  @hurrycane   I just committed a bunch of cleanup an...
1624782206  Sep  9  2010  @hurrycane   I'm trying to debug the issue you were...
        eos
      end
    end
    context "--number" do
      before do
        stub_get("/1.1/direct_messages/sent.json").with(:query => {:count => "1"}).to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/direct_messages/sent.json").with(:query => {:count => "200"}).to_return(:body => fixture("200_direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/direct_messages/sent.json").with(:query => {:count => "1", :max_id => "235851563443306495"}).to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "limits the number of results 1" do
        @cli.options = @cli.options.merge("number" => 1)
        @cli.direct_messages_sent
        expect(a_get("/1.1/direct_messages/sent.json").with(:query => {:count => "1"})).to have_been_made
      end
      it "limits the number of results to 201" do
        @cli.options = @cli.options.merge("number" => 201)
        @cli.direct_messages_sent
        expect(a_get("/1.1/direct_messages/sent.json").with(:query => {:count => "200"})).to have_been_made
        expect(a_get("/1.1/direct_messages/sent.json").with(:query => {:count => "1", :max_id => "235851563443306495"})).to have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.direct_messages_sent
        expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @hurrycane\e[0m
   I'm trying to debug the issue you were having with the Bundler Gemfile.lock 
   shortref. What version of Ruby and RubyGems are you running?

\e[1m\e[33m   @hurrycane\e[0m
   I just committed a bunch of cleanup and fixes to RailsAdmin that touched many 
   of files. Make sure you pull to avoid conflicts.

\e[1m\e[33m   @hurrycane\e[0m
   Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?

\e[1m\e[33m   @hurrycane\e[0m
   How are the graphs coming? I'm really looking forward to seeing what you do 
   with Raphaël.

\e[1m\e[33m   @hurrycane\e[0m
   How are the graph enhancements coming?

\e[1m\e[33m   @hurrycane\e[0m
   Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think 
   you'll be able to finish up your work on graphs this weekend?

\e[1m\e[33m   @hurrycane\e[0m
   Just checking in. How's everything going?

\e[1m\e[33m   @hurrycane\e[0m
   I asked Yehuda about the stipend. I believe it has already been sent. Glad 
   you're feeling better.

\e[1m\e[33m   @hurrycane\e[0m
   That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does 
   that work for you?

\e[1m\e[33m   @hurrycane\e[0m
   Sounds good. Meeting Tuesday is fine.

        eos
      end
    end
  end

  describe "#groupies" do
    before do
      stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "213747670,428004849"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.groupies
      expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "213747670,428004849"})).to have_been_made
    end
    it "has the correct output" do
      @cli.groupies
      expect($stdout.string.chomp).to eq "pengwynn  sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.groupies
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
14100886,2008-03-08 16:34:22 +0000,2012-07-07 20:33:19 +0000,6940,192,358,3427,5457,pengwynn,Wynn Netherland ⚡,false,"Christian, husband, father, GitHubber, Co-host of @thechangelog, Co-author of Sass, Compass, #CSS book  http://wynn.fm/sass-meap",@akosmasoftware Sass book! @hcatlin @nex3 are the brains behind Sass. :-),"Denton, TX",http://wynnnetherland.com
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.groupies
        expect($stdout.string).to eq <<-eos
Id        Since         Last tweeted at  Tweets  Favorites  Listed  Following...
14100886  Mar  8  2008  Jul  7 12:33       6940        192     358       3427...
 7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212...
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=favorites" do
      before do
        @cli.options = @cli.options.merge("sort" => "favorites")
      end
      it "sorts by number of favorites" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=followers" do
      before do
        @cli.options = @cli.options.merge("sort" => "followers")
      end
      it "sorts by number of followers" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=friends" do
      before do
        @cli.options = @cli.options.merge("sort" => "friends")
      end
      it "sorts by number of friends" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=listed" do
      before do
        @cli.options = @cli.options.merge("sort" => "listed")
      end
      it "sorts by number of list memberships" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=since" do
      before do
        @cli.options = @cli.options.merge("sort" => "since")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=tweets" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweets")
      end
      it "sorts by number of Tweets" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=tweeted" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweeted")
      end
      it "sorts by the time of the last Tweet" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.groupies
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.groupies("sferik")
        expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "213747670,428004849"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.groupies("7505382")
          expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "213747670,428004849"})).to have_been_made
        end
      end
    end
  end

  describe "#dm" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1.1/direct_messages/new.json").with(:body => {:screen_name => "pengwynn", :text => "Creating a fixture for the Twitter gem"}).to_return(:body => fixture("direct_message.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.dm("pengwynn", "Creating a fixture for the Twitter gem")
      expect(a_post("/1.1/direct_messages/new.json").with(:body => {:screen_name => "pengwynn", :text => "Creating a fixture for the Twitter gem"})).to have_been_made
    end
    it "has the correct output" do
      @cli.dm("pengwynn", "Creating a fixture for the Twitter gem")
      expect($stdout.string.chomp).to eq "Direct Message sent from @testcli to @pengwynn."
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_post("/1.1/direct_messages/new.json").with(:body => {:user_id => "14100886", :text => "Creating a fixture for the Twitter gem"}).to_return(:body => fixture("direct_message.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.dm("14100886", "Creating a fixture for the Twitter gem")
        expect(a_post("/1.1/direct_messages/new.json").with(:body => {:user_id => "14100886", :text => "Creating a fixture for the Twitter gem"})).to have_been_made
      end
    end
  end

  describe "#does_contain" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_get("/1.1/lists/members/show.json").with(:query => {:owner_screen_name => "testcli", :screen_name => "testcli", :slug => "presidents"}).to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.does_contain("presidents")
      expect(a_get("/1.1/lists/members/show.json").with(:query => {:owner_screen_name => "testcli", :screen_name => "testcli", :slug => "presidents"})).to have_been_made
    end
    it "has the correct output" do
      @cli.does_contain("presidents")
      expect($stdout.string.chomp).to eq "Yes, presidents contains @testcli."
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_get("/1.1/users/show.json").with(:query => {:user_id => "7505382"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/lists/members/show.json").with(:query => {:owner_screen_name => "testcli", :screen_name => "sferik", :slug => "presidents"}).to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.does_contain("presidents", "7505382")
        expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "7505382"})).to have_been_made
        expect(a_get("/1.1/lists/members/show.json").with(:query => {:owner_screen_name => "testcli", :screen_name => "sferik", :slug => "presidents"})).to have_been_made
      end
    end
    context "with an owner passed" do
      it "has the correct output" do
        @cli.does_contain("testcli/presidents", "testcli")
        expect($stdout.string.chomp).to eq "Yes, presidents contains @testcli."
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/users/show.json").with(:query => {:user_id => "7505382"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/lists/members/show.json").with(:query => {:owner_id => "7505382", :screen_name => "sferik", :slug => "presidents"}).to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.does_contain("7505382/presidents", "7505382")
          expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "7505382"})).to have_been_made
          expect(a_get("/1.1/lists/members/show.json").with(:query => {:owner_id => "7505382", :screen_name => "sferik", :slug => "presidents"})).to have_been_made
        end
      end
    end
    context "with a user passed" do
      it "has the correct output" do
        @cli.does_contain("presidents", "testcli")
        expect($stdout.string.chomp).to eq "Yes, presidents contains @testcli."
      end
    end
    context "false" do
      before do
        stub_get("/1.1/lists/members/show.json").with(:query => {:owner_screen_name => "testcli", :screen_name => "testcli", :slug => "presidents"}).to_return(:body => fixture("not_found.json"), :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "exits" do
        expect do
          @cli.does_contain("presidents")
        end.to raise_error(SystemExit)
        expect(a_get("/1.1/lists/members/show.json").with(:query => {:owner_screen_name => "testcli", :screen_name => "testcli", :slug => "presidents"})).to have_been_made
      end
    end
  end

  describe "#does_follow" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "ev", :target_screen_name => "testcli"}).to_return(:body => fixture("following.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.does_follow("ev")
      expect(a_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "ev", :target_screen_name => "testcli"})).to have_been_made
    end
    it "has the correct output" do
      @cli.does_follow("ev")
      expect($stdout.string.chomp).to eq "Yes, @ev follows @testcli."
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_get("/1.1/users/show.json").with(:query => {:user_id => "20"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "sferik", :target_screen_name => "testcli"}).to_return(:body => fixture("following.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.does_follow("20")
        expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "20"})).to have_been_made
        expect(a_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "sferik", :target_screen_name => "testcli"})).to have_been_made
      end
      it "has the correct output" do
        @cli.does_follow("20")
        expect($stdout.string.chomp).to eq "Yes, @sferik follows @testcli."
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "ev", :target_screen_name => "sferik"}).to_return(:body => fixture("following.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.does_follow("ev", "sferik")
        expect(a_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "ev", :target_screen_name => "sferik"})).to have_been_made
      end
      it "has the correct output" do
        @cli.does_follow("ev", "sferik")
        expect($stdout.string.chomp).to eq "Yes, @ev follows @sferik."
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/users/show.json").with(:query => {:user_id => "20"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/users/show.json").with(:query => {:user_id => "428004849"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "sferik", :target_screen_name => "sferik"}).to_return(:body => fixture("following.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.does_follow("20", "428004849")
          expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "20"})).to have_been_made
          expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "428004849"})).to have_been_made
          expect(a_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "sferik", :target_screen_name => "sferik"})).to have_been_made
        end
        it "has the correct output" do
          @cli.does_follow("20", "428004849")
          expect($stdout.string.chomp).to eq "Yes, @sferik follows @sferik."
        end
      end
    end
    context "false" do
      before do
        stub_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "ev", :target_screen_name => "testcli"}).to_return(:body => fixture("not_following.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "exits" do
        expect do
          @cli.does_follow("ev")
        end.to raise_error(SystemExit)
        expect(a_get("/1.1/friendships/show.json").with(:query => {:source_screen_name => "ev", :target_screen_name => "testcli"})).to have_been_made
      end
    end
  end

  describe "#favorite" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1.1/favorites/create.json").with(:body => {:id => "26755176471724032"}).to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.favorite("26755176471724032")
      expect(a_post("/1.1/favorites/create.json").with(:body => {:id => "26755176471724032"})).to have_been_made
    end
    it "has the correct output" do
      @cli.favorite("26755176471724032")
      expect($stdout.string).to match /^@testcli favorited 1 tweet.$/
    end
  end

  describe "#favorites" do
    before do
      stub_get("/1.1/favorites/list.json").with(:query => {:count => "20"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.favorites
      expect(a_get("/1.1/favorites/list.json").with(:query => {:count => "20"})).to have_been_made
    end
    it "has the correct output" do
      @cli.favorites
      expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @mutgoff\e[0m
   Happy Birthday @imdane. Watch out for those @rally pranksters!

\e[1m\e[33m   @ironicsans\e[0m
   If you like good real-life stories, check out @NarrativelyNY's just-launched 
   site http://t.co/wiUL07jE (and also visit http://t.co/ZoyQxqWA)

\e[1m\e[33m   @pat_shaughnessy\e[0m
   Something else to vote for: "New Rails workshops to bring more women into the 
   Boston software scene" http://t.co/eNBuckHc /cc @bostonrb

\e[1m\e[33m   @calebelston\e[0m
   Pushing the button to launch the site. http://t.co/qLoEn5jG

\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @fivethirtyeight\e[0m
   The Weatherman is Not a Moron: http://t.co/ZwL5Gnq5. An excerpt from my book, 
   THE SIGNAL AND THE NOISE (http://t.co/fNXj8vCE)

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

\e[1m\e[33m   @fbjork\e[0m
   RT @jondot: Just published: "Pragmatic Concurrency With #Ruby" 
   http://t.co/kGEykswZ /cc @JRuby @headius

\e[1m\e[33m   @mbostock\e[0m
   If you are wondering how we computed the split bubbles: http://t.co/BcaqSs5u

\e[1m\e[33m   @FakeDorsey\e[0m
   “Write drunk. Edit sober.”—Ernest Hemingway

\e[1m\e[33m   @al3x\e[0m
   RT @wcmaier: Better banking through better ops: build something new with us 
   @Simplify (remote, PDX) http://t.co/8WgzKZH3

\e[1m\e[33m   @calebelston\e[0m
   We just announced Mosaic, what we've been working on since the Yobongo 
   acquisition. My personal post, http://t.co/ELOyIRZU @heymosaic

\e[1m\e[33m   @BarackObama\e[0m
   Donate $10 or more --> get your favorite car magnet: http://t.co/NfRhl2s2 
   #Obama2012

\e[1m\e[33m   @JEG2\e[0m
   RT @tenderlove: If corporations are people, can we use them to drive in the 
   carpool lane?

\e[1m\e[33m   @eveningedition\e[0m
   LDN—Obama's nomination; Putin woos APEC; Bombs hit Damascus; Quakes shake 
   China; Canada cuts Iran ties; weekend read: http://t.co/OFs6dVW4

\e[1m\e[33m   @dhh\e[0m
   RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest 
   achievement: why this goulish jingoism is so warped http://t.co/kood278s

\e[1m\e[33m   @jasonfried\e[0m
   The story of Mars Curiosity's gears, made by a factory in Rockford, IL: 
   http://t.co/MwCRsHQg

\e[1m\e[33m   @sferik\e[0m
   @episod @twitterapi now https://t.co/I17jUTu2 and https://t.co/deDu4Hgw seem 
   to be missing "1.1" from the URL.

\e[1m\e[33m   @sferik\e[0m
   @episod @twitterapi Did you catch https://t.co/VHsQvZT0 as well?

\e[1m\e[33m   @dwiskus\e[0m
   Gentlemen, you can't fight in here! This is the war room! 
   http://t.co/kMxMYyqF

      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.favorites
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text
4611686018427387904,2012-09-07 16:35:24 +0000,mutgoff,Happy Birthday @imdane. Watch out for those @rally pranksters!
244111183165157376,2012-09-07 16:33:36 +0000,ironicsans,"If you like good real-life stories, check out @NarrativelyNY's just-launched site http://t.co/wiUL07jE (and also visit http://t.co/ZoyQxqWA)"
244110336414859264,2012-09-07 16:30:14 +0000,pat_shaughnessy,"Something else to vote for: ""New Rails workshops to bring more women into the Boston software scene"" http://t.co/eNBuckHc /cc @bostonrb"
244109797308379136,2012-09-07 16:28:05 +0000,calebelston,Pushing the button to launch the site. http://t.co/qLoEn5jG
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107890632294400,2012-09-07 16:20:31 +0000,fivethirtyeight,"The Weatherman is Not a Moron: http://t.co/ZwL5Gnq5. An excerpt from my book, THE SIGNAL AND THE NOISE (http://t.co/fNXj8vCE)"
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
244107236262170624,2012-09-07 16:17:55 +0000,fbjork,"RT @jondot: Just published: ""Pragmatic Concurrency With #Ruby"" http://t.co/kGEykswZ   /cc @JRuby @headius"
244106476048764928,2012-09-07 16:14:53 +0000,mbostock,If you are wondering how we computed the split bubbles: http://t.co/BcaqSs5u
244105599351148544,2012-09-07 16:11:24 +0000,FakeDorsey,“Write drunk. Edit sober.”—Ernest Hemingway
244104558433951744,2012-09-07 16:07:16 +0000,al3x,"RT @wcmaier: Better banking through better ops: build something new with us @Simplify (remote, PDX) http://t.co/8WgzKZH3"
244104146997870594,2012-09-07 16:05:38 +0000,calebelston,"We just announced Mosaic, what we've been working on since the Yobongo acquisition. My personal post, http://t.co/ELOyIRZU @heymosaic"
244103057175113729,2012-09-07 16:01:18 +0000,BarackObama,Donate $10 or more --> get your favorite car magnet: http://t.co/NfRhl2s2 #Obama2012
244102834398851073,2012-09-07 16:00:25 +0000,JEG2,"RT @tenderlove: If corporations are people, can we use them to drive in the carpool lane?"
244102741125890048,2012-09-07 16:00:03 +0000,eveningedition,LDN—Obama's nomination; Putin woos APEC; Bombs hit Damascus; Quakes shake China; Canada cuts Iran ties; weekend read: http://t.co/OFs6dVW4
244102729860009984,2012-09-07 16:00:00 +0000,dhh,RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest achievement: why this goulish jingoism is so warped http://t.co/kood278s
244102490646278146,2012-09-07 15:59:03 +0000,jasonfried,"The story of Mars Curiosity's gears, made by a factory in Rockford, IL: http://t.co/MwCRsHQg"
244102209942458368,2012-09-07 15:57:56 +0000,sferik,"@episod @twitterapi now https://t.co/I17jUTu2 and https://t.co/deDu4Hgw seem to be missing ""1.1"" from the URL."
244100411563339777,2012-09-07 15:50:47 +0000,sferik,@episod @twitterapi Did you catch https://t.co/VHsQvZT0 as well?
244099460672679938,2012-09-07 15:47:01 +0000,dwiskus,"Gentlemen, you can't fight in here! This is the war room! http://t.co/kMxMYyqF"
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.favorites
        expect($stdout.string).to eq <<-eos
Id                   Posted at     Screen name       Text
4611686018427387904  Sep  7 08:35  @mutgoff          Happy Birthday @imdane. ...
 244111183165157376  Sep  7 08:33  @ironicsans       If you like good real-li...
 244110336414859264  Sep  7 08:30  @pat_shaughnessy  Something else to vote f...
 244109797308379136  Sep  7 08:28  @calebelston      Pushing the button to la...
 244108728834592770  Sep  7 08:23  @calebelston      RT @olivercameron: Mosai...
 244107890632294400  Sep  7 08:20  @fivethirtyeight  The Weatherman is Not a ...
 244107823733174272  Sep  7 08:20  @codeforamerica   RT @randomhacks: Going t...
 244107236262170624  Sep  7 08:17  @fbjork           RT @jondot: Just publish...
 244106476048764928  Sep  7 08:14  @mbostock         If you are wondering how...
 244105599351148544  Sep  7 08:11  @FakeDorsey       “Write drunk. Edit sober...
 244104558433951744  Sep  7 08:07  @al3x             RT @wcmaier: Better bank...
 244104146997870594  Sep  7 08:05  @calebelston      We just announced Mosaic...
 244103057175113729  Sep  7 08:01  @BarackObama      Donate $10 or more --> g...
 244102834398851073  Sep  7 08:00  @JEG2             RT @tenderlove: If corpo...
 244102741125890048  Sep  7 08:00  @eveningedition   LDN—Obama's nomination; ...
 244102729860009984  Sep  7 08:00  @dhh              RT @ggreenwald: Democrat...
 244102490646278146  Sep  7 07:59  @jasonfried       The story of Mars Curios...
 244102209942458368  Sep  7 07:57  @sferik           @episod @twitterapi now ...
 244100411563339777  Sep  7 07:50  @sferik           @episod @twitterapi Did ...
 244099460672679938  Sep  7 07:47  @dwiskus          Gentlemen, you can't fig...
        eos
      end
      context "--reverse" do
        before do
          @cli.options = @cli.options.merge("reverse" => true)
        end
        it "reverses the order of the sort" do
          @cli.favorites
          expect($stdout.string).to eq <<-eos
Id                   Posted at     Screen name       Text
 244099460672679938  Sep  7 07:47  @dwiskus          Gentlemen, you can't fig...
 244100411563339777  Sep  7 07:50  @sferik           @episod @twitterapi Did ...
 244102209942458368  Sep  7 07:57  @sferik           @episod @twitterapi now ...
 244102490646278146  Sep  7 07:59  @jasonfried       The story of Mars Curios...
 244102729860009984  Sep  7 08:00  @dhh              RT @ggreenwald: Democrat...
 244102741125890048  Sep  7 08:00  @eveningedition   LDN—Obama's nomination; ...
 244102834398851073  Sep  7 08:00  @JEG2             RT @tenderlove: If corpo...
 244103057175113729  Sep  7 08:01  @BarackObama      Donate $10 or more --> g...
 244104146997870594  Sep  7 08:05  @calebelston      We just announced Mosaic...
 244104558433951744  Sep  7 08:07  @al3x             RT @wcmaier: Better bank...
 244105599351148544  Sep  7 08:11  @FakeDorsey       “Write drunk. Edit sober...
 244106476048764928  Sep  7 08:14  @mbostock         If you are wondering how...
 244107236262170624  Sep  7 08:17  @fbjork           RT @jondot: Just publish...
 244107823733174272  Sep  7 08:20  @codeforamerica   RT @randomhacks: Going t...
 244107890632294400  Sep  7 08:20  @fivethirtyeight  The Weatherman is Not a ...
 244108728834592770  Sep  7 08:23  @calebelston      RT @olivercameron: Mosai...
 244109797308379136  Sep  7 08:28  @calebelston      Pushing the button to la...
 244110336414859264  Sep  7 08:30  @pat_shaughnessy  Something else to vote f...
 244111183165157376  Sep  7 08:33  @ironicsans       If you like good real-li...
4611686018427387904  Sep  7 08:35  @mutgoff          Happy Birthday @imdane. ...
          eos
        end
      end
    end
    context "--number" do
      before do
        stub_get("/1.1/favorites/list.json").with(:query => {:count => "1"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/favorites/list.json").with(:query => {:count => "200"}).to_return(:body => fixture("200_statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/favorites/list.json").with(:query => {:count => "1", :max_id => "265500541700956160"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "limits the number of results to 1" do
        @cli.options = @cli.options.merge("number" => 1)
        @cli.favorites
        expect(a_get("/1.1/favorites/list.json").with(:query => {:count => "1"})).to have_been_made
      end
      it "limits the number of results to 201" do
        @cli.options = @cli.options.merge("number" => 201)
        @cli.favorites
        expect(a_get("/1.1/favorites/list.json").with(:query => {:count => "200"})).to have_been_made
        expect(a_get("/1.1/favorites/list.json").with(:query => {:count => "1", :max_id => "265500541700956160"})).to have_been_made
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/favorites/list.json").with(:query => {:count => "20", :screen_name => "sferik"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.favorites("sferik")
        expect(a_get("/1.1/favorites/list.json").with(:query => {:count => "20", :screen_name => "sferik"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/favorites/list.json").with(:query => {:user_id => "7505382", :count => "20"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.favorites("7505382")
          expect(a_get("/1.1/favorites/list.json").with(:query => {:user_id => "7505382", :count => "20"})).to have_been_made
        end
      end
    end
  end

  describe "#follow" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
    end
    context "one user" do
      before do
        stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_post("/1.1/users/lookup.json").with(:body => {:screen_name => "sferik,pengwynn"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_post("/1.1/friendships/create.json").with(:body => {:user_id => "14100886"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.follow("sferik", "pengwynn")
        expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:screen_name => "sferik,pengwynn"})).to have_been_made
        expect(a_post("/1.1/friendships/create.json").with(:body => {:user_id => "14100886"})).to have_been_made
      end
      it "has the correct output" do
        @cli.follow("sferik", "pengwynn")
        expect($stdout.string).to match /^@testcli is now following 1 more user\.$/
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382,14100886"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_post("/1.1/friendships/create.json").with(:body => {:user_id => "14100886"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.follow("7505382", "14100886")
          expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
          expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382,14100886"})).to have_been_made
          expect(a_post("/1.1/friendships/create.json").with(:body => {:user_id => "14100886"})).to have_been_made
        end
      end
      context "Twitter is down" do
        it "retries 3 times and then raise an error" do
          stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_post("/1.1/users/lookup.json").with(:body => {:screen_name => "sferik,pengwynn"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_post("/1.1/friendships/create.json").with(:body => {:user_id => "14100886"}).to_return(:status => 502)
          expect do
            @cli.follow("sferik", "pengwynn")
          end.to raise_error("Twitter is down or being upgraded.")
          expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made.times(3)
          expect(a_post("/1.1/users/lookup.json").with(:body => {:screen_name => "sferik,pengwynn"})).to have_been_made.times(3)
          expect(a_post("/1.1/friendships/create.json").with(:body => {:user_id => "14100886"})).to have_been_made.times(3)
        end
      end
    end
  end

  describe "#followings" do
    before do
      stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.followings
      expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
    end
    it "has the correct output" do
      @cli.followings
      expect($stdout.string.chomp).to eq "pengwynn  sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.followings
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
14100886,2008-03-08 16:34:22 +0000,2012-07-07 20:33:19 +0000,6940,192,358,3427,5457,pengwynn,Wynn Netherland ⚡,false,"Christian, husband, father, GitHubber, Co-host of @thechangelog, Co-author of Sass, Compass, #CSS book  http://wynn.fm/sass-meap",@akosmasoftware Sass book! @hcatlin @nex3 are the brains behind Sass. :-),"Denton, TX",http://wynnnetherland.com
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.followings
        expect($stdout.string).to eq <<-eos
Id        Since         Last tweeted at  Tweets  Favorites  Listed  Following...
14100886  Mar  8  2008  Jul  7 12:33       6940        192     358       3427...
 7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212...
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.followings
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=favorites" do
      before do
        @cli.options = @cli.options.merge("sort" => "favorites")
      end
      it "sorts by number of favorites" do
        @cli.followings
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=followers" do
      before do
        @cli.options = @cli.options.merge("sort" => "followers")
      end
      it "sorts by number of followers" do
        @cli.followings
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=friends" do
      before do
        @cli.options = @cli.options.merge("sort" => "friends")
      end
      it "sorts by number of friends" do
        @cli.followings
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=listed" do
      before do
        @cli.options = @cli.options.merge("sort" => "listed")
      end
      it "sorts by number of list memberships" do
        @cli.followings
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=since" do
      before do
        @cli.options = @cli.options.merge("sort" => "since")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.followings
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=tweets" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweets")
      end
      it "sorts by number of Tweets" do
        @cli.followings
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=tweeted" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweeted")
      end
      it "sorts by the time of the last Tweet" do
        @cli.followings
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.followings
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.followings("sferik")
        expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.followings("7505382")
        expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
    end
  end

  describe "#followers" do
    before do
      stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.followers
      expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
    end
    it "has the correct output" do
      @cli.followers
      expect($stdout.string.chomp).to eq "pengwynn  sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.followers
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
14100886,2008-03-08 16:34:22 +0000,2012-07-07 20:33:19 +0000,6940,192,358,3427,5457,pengwynn,Wynn Netherland ⚡,false,"Christian, husband, father, GitHubber, Co-host of @thechangelog, Co-author of Sass, Compass, #CSS book  http://wynn.fm/sass-meap",@akosmasoftware Sass book! @hcatlin @nex3 are the brains behind Sass. :-),"Denton, TX",http://wynnnetherland.com
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.followers
        expect($stdout.string).to eq <<-eos
Id        Since         Last tweeted at  Tweets  Favorites  Listed  Following...
14100886  Mar  8  2008  Jul  7 12:33       6940        192     358       3427...
 7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212...
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.followers
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=favorites" do
      before do
        @cli.options = @cli.options.merge("sort" => "favorites")
      end
      it "sorts by number of favorites" do
        @cli.followers
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=followers" do
      before do
        @cli.options = @cli.options.merge("sort" => "followers")
      end
      it "sorts by number of followers" do
        @cli.followers
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=friends" do
      before do
        @cli.options = @cli.options.merge("sort" => "friends")
      end
      it "sorts by number of friends" do
        @cli.followers
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=listed" do
      before do
        @cli.options = @cli.options.merge("sort" => "listed")
      end
      it "sorts by number of list memberships" do
        @cli.followers
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=since" do
      before do
        @cli.options = @cli.options.merge("sort" => "since")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.followers
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=tweets" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweets")
      end
      it "sorts by number of Tweets" do
        @cli.followers
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=tweeted" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweeted")
      end
      it "sorts by the time of the last Tweet" do
        @cli.followers
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.followers
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "213747670,428004849"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.followers("sferik")
        expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.followers("7505382")
          expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
        end
      end
    end
  end

  describe "#friends" do
    before do
      stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.friends
      expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
    end
    it "has the correct output" do
      @cli.friends
      expect($stdout.string.chomp).to eq "pengwynn  sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.friends
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
14100886,2008-03-08 16:34:22 +0000,2012-07-07 20:33:19 +0000,6940,192,358,3427,5457,pengwynn,Wynn Netherland ⚡,false,"Christian, husband, father, GitHubber, Co-host of @thechangelog, Co-author of Sass, Compass, #CSS book  http://wynn.fm/sass-meap",@akosmasoftware Sass book! @hcatlin @nex3 are the brains behind Sass. :-),"Denton, TX",http://wynnnetherland.com
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.friends
        expect($stdout.string).to eq <<-eos
Id        Since         Last tweeted at  Tweets  Favorites  Listed  Following...
14100886  Mar  8  2008  Jul  7 12:33       6940        192     358       3427...
 7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212...
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.friends
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=favorites" do
      before do
        @cli.options = @cli.options.merge("sort" => "favorites")
      end
      it "sorts by number of favorites" do
        @cli.friends
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=followers" do
      before do
        @cli.options = @cli.options.merge("sort" => "followers")
      end
      it "sorts by number of followers" do
        @cli.friends
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=friends" do
      before do
        @cli.options = @cli.options.merge("sort" => "friends")
      end
      it "sorts by number of friends" do
        @cli.friends
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=listed" do
      before do
        @cli.options = @cli.options.merge("sort" => "listed")
      end
      it "sorts by number of list memberships" do
        @cli.friends
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=since" do
      before do
        @cli.options = @cli.options.merge("sort" => "since")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.friends
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=tweets" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweets")
      end
      it "sorts by number of Tweets" do
        @cli.friends
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=tweeted" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweeted")
      end
      it "sorts by the time of the last Tweet" do
        @cli.friends
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.friends
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.friends("sferik")
        expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.friends("7505382")
          expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
        end
      end
    end
  end

  describe "#leaders" do
    before do
      stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"}).to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.leaders
      expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1"})).to have_been_made
      expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
    end
    it "has the correct output" do
      @cli.leaders
      expect($stdout.string.chomp).to eq "pengwynn  sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.leaders
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
14100886,2008-03-08 16:34:22 +0000,2012-07-07 20:33:19 +0000,6940,192,358,3427,5457,pengwynn,Wynn Netherland ⚡,false,"Christian, husband, father, GitHubber, Co-host of @thechangelog, Co-author of Sass, Compass, #CSS book  http://wynn.fm/sass-meap",@akosmasoftware Sass book! @hcatlin @nex3 are the brains behind Sass. :-),"Denton, TX",http://wynnnetherland.com
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.leaders
        expect($stdout.string).to eq <<-eos
Id        Since         Last tweeted at  Tweets  Favorites  Listed  Following...
14100886  Mar  8  2008  Jul  7 12:33       6940        192     358       3427...
 7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212...
         eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=favorites" do
      before do
        @cli.options = @cli.options.merge("sort" => "favorites")
      end
      it "sorts by number of favorites" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=followers" do
      before do
        @cli.options = @cli.options.merge("sort" => "followers")
      end
      it "sorts by number of followers" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=friends" do
      before do
        @cli.options = @cli.options.merge("sort" => "friends")
      end
      it "sorts by number of friends" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=listed" do
      before do
        @cli.options = @cli.options.merge("sort" => "listed")
      end
      it "sorts by number of list memberships" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=since" do
      before do
        @cli.options = @cli.options.merge("sort" => "since")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=tweets" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweets")
      end
      it "sorts by number of Tweets" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=tweeted" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweeted")
      end
      it "sorts by the time of the last Tweet" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.leaders
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"}).to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.leaders("sferik")
        expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :screen_name => "sferik"})).to have_been_made
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"}).to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.leaders("7505382")
          expect(a_get("/1.1/friends/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_get("/1.1/followers/ids.json").with(:query => {:cursor => "-1", :user_id => "7505382"})).to have_been_made
          expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382"})).to have_been_made
        end
      end
    end
  end

  describe "#lists" do
    before do
      stub_get("/1.1/lists/list.json").to_return(:body => fixture("lists.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.lists
      expect(a_get("/1.1/lists/list.json")).to have_been_made
    end
    it "has the correct output" do
      @cli.lists
      expect($stdout.string.chomp).to eq "@pengwynn/rubyists  @twitter/team       @sferik/test"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.lists
        expect($stdout.string).to eq <<-eos
Id,Created at,Screen name,Slug,Members,Subscribers,Mode,Description
1129440,2009-10-30 14:39:25 +0000,pengwynn,rubyists,499,39,public,""
574,2009-09-23 01:18:01 +0000,twitter,team,1199,78078,public,""
73546689,2012-07-08 22:19:05 +0000,sferik,test,2,0,private,""
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.lists
        expect($stdout.string).to eq <<-eos
Id        Created at    Screen name  Slug      Members  Subscribers  Mode    ...
 1129440  Oct 30  2009  @pengwynn    rubyists      499           39  public   
     574  Sep 22  2009  @twitter     team         1199        78078  public   
73546689  Jul  8 14:19  @sferik      test            2            0  private  
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.lists
        expect($stdout.string.chomp).to eq "@sferik/test        @twitter/team       @pengwynn/rubyists"
      end
    end
    context "--sort=members" do
      before do
        @cli.options = @cli.options.merge("sort" => "members")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.lists
        expect($stdout.string.chomp).to eq "@sferik/test        @pengwynn/rubyists  @twitter/team"
      end
    end
    context "--sort=mode" do
      before do
        @cli.options = @cli.options.merge("sort" => "mode")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.lists
        expect($stdout.string.chomp).to eq "@sferik/test        @twitter/team       @pengwynn/rubyists"
      end
    end
    context "--sort=posted" do
      before do
        @cli.options = @cli.options.merge("sort" => "posted")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.lists
        expect($stdout.string.chomp).to eq "@twitter/team       @pengwynn/rubyists  @sferik/test"
      end
    end
    context "--sort=subscribers" do
      before do
        @cli.options = @cli.options.merge("sort" => "subscribers")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.lists
        expect($stdout.string.chomp).to eq "@sferik/test        @pengwynn/rubyists  @twitter/team"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.lists
        expect($stdout.string.chomp).to eq "@pengwynn/rubyists  @twitter/team       @sferik/test"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/lists/list.json").with(:query => {:screen_name => "sferik"}).to_return(:body => fixture("lists.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.lists("sferik")
        expect(a_get("/1.1/lists/list.json").with(:query => {:screen_name => "sferik"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/lists/list.json").with(:query => {:user_id => "7505382"}).to_return(:body => fixture("lists.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.lists("7505382")
          expect(a_get("/1.1/lists/list.json").with(:query => {:user_id => "7505382"})).to have_been_made
        end
      end
    end
  end

  describe "#mentions" do
    before do
      stub_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "20"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.mentions
      expect(a_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "20"})).to have_been_made
    end
    it "has the correct output" do
      @cli.mentions
      expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @mutgoff\e[0m
   Happy Birthday @imdane. Watch out for those @rally pranksters!

\e[1m\e[33m   @ironicsans\e[0m
   If you like good real-life stories, check out @NarrativelyNY's just-launched 
   site http://t.co/wiUL07jE (and also visit http://t.co/ZoyQxqWA)

\e[1m\e[33m   @pat_shaughnessy\e[0m
   Something else to vote for: "New Rails workshops to bring more women into the 
   Boston software scene" http://t.co/eNBuckHc /cc @bostonrb

\e[1m\e[33m   @calebelston\e[0m
   Pushing the button to launch the site. http://t.co/qLoEn5jG

\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @fivethirtyeight\e[0m
   The Weatherman is Not a Moron: http://t.co/ZwL5Gnq5. An excerpt from my book, 
   THE SIGNAL AND THE NOISE (http://t.co/fNXj8vCE)

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

\e[1m\e[33m   @fbjork\e[0m
   RT @jondot: Just published: "Pragmatic Concurrency With #Ruby" 
   http://t.co/kGEykswZ /cc @JRuby @headius

\e[1m\e[33m   @mbostock\e[0m
   If you are wondering how we computed the split bubbles: http://t.co/BcaqSs5u

\e[1m\e[33m   @FakeDorsey\e[0m
   “Write drunk. Edit sober.”—Ernest Hemingway

\e[1m\e[33m   @al3x\e[0m
   RT @wcmaier: Better banking through better ops: build something new with us 
   @Simplify (remote, PDX) http://t.co/8WgzKZH3

\e[1m\e[33m   @calebelston\e[0m
   We just announced Mosaic, what we've been working on since the Yobongo 
   acquisition. My personal post, http://t.co/ELOyIRZU @heymosaic

\e[1m\e[33m   @BarackObama\e[0m
   Donate $10 or more --> get your favorite car magnet: http://t.co/NfRhl2s2 
   #Obama2012

\e[1m\e[33m   @JEG2\e[0m
   RT @tenderlove: If corporations are people, can we use them to drive in the 
   carpool lane?

\e[1m\e[33m   @eveningedition\e[0m
   LDN—Obama's nomination; Putin woos APEC; Bombs hit Damascus; Quakes shake 
   China; Canada cuts Iran ties; weekend read: http://t.co/OFs6dVW4

\e[1m\e[33m   @dhh\e[0m
   RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest 
   achievement: why this goulish jingoism is so warped http://t.co/kood278s

\e[1m\e[33m   @jasonfried\e[0m
   The story of Mars Curiosity's gears, made by a factory in Rockford, IL: 
   http://t.co/MwCRsHQg

\e[1m\e[33m   @sferik\e[0m
   @episod @twitterapi now https://t.co/I17jUTu2 and https://t.co/deDu4Hgw seem 
   to be missing "1.1" from the URL.

\e[1m\e[33m   @sferik\e[0m
   @episod @twitterapi Did you catch https://t.co/VHsQvZT0 as well?

\e[1m\e[33m   @dwiskus\e[0m
   Gentlemen, you can't fight in here! This is the war room! 
   http://t.co/kMxMYyqF

      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.mentions
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text
4611686018427387904,2012-09-07 16:35:24 +0000,mutgoff,Happy Birthday @imdane. Watch out for those @rally pranksters!
244111183165157376,2012-09-07 16:33:36 +0000,ironicsans,"If you like good real-life stories, check out @NarrativelyNY's just-launched site http://t.co/wiUL07jE (and also visit http://t.co/ZoyQxqWA)"
244110336414859264,2012-09-07 16:30:14 +0000,pat_shaughnessy,"Something else to vote for: ""New Rails workshops to bring more women into the Boston software scene"" http://t.co/eNBuckHc /cc @bostonrb"
244109797308379136,2012-09-07 16:28:05 +0000,calebelston,Pushing the button to launch the site. http://t.co/qLoEn5jG
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107890632294400,2012-09-07 16:20:31 +0000,fivethirtyeight,"The Weatherman is Not a Moron: http://t.co/ZwL5Gnq5. An excerpt from my book, THE SIGNAL AND THE NOISE (http://t.co/fNXj8vCE)"
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
244107236262170624,2012-09-07 16:17:55 +0000,fbjork,"RT @jondot: Just published: ""Pragmatic Concurrency With #Ruby"" http://t.co/kGEykswZ   /cc @JRuby @headius"
244106476048764928,2012-09-07 16:14:53 +0000,mbostock,If you are wondering how we computed the split bubbles: http://t.co/BcaqSs5u
244105599351148544,2012-09-07 16:11:24 +0000,FakeDorsey,“Write drunk. Edit sober.”—Ernest Hemingway
244104558433951744,2012-09-07 16:07:16 +0000,al3x,"RT @wcmaier: Better banking through better ops: build something new with us @Simplify (remote, PDX) http://t.co/8WgzKZH3"
244104146997870594,2012-09-07 16:05:38 +0000,calebelston,"We just announced Mosaic, what we've been working on since the Yobongo acquisition. My personal post, http://t.co/ELOyIRZU @heymosaic"
244103057175113729,2012-09-07 16:01:18 +0000,BarackObama,Donate $10 or more --> get your favorite car magnet: http://t.co/NfRhl2s2 #Obama2012
244102834398851073,2012-09-07 16:00:25 +0000,JEG2,"RT @tenderlove: If corporations are people, can we use them to drive in the carpool lane?"
244102741125890048,2012-09-07 16:00:03 +0000,eveningedition,LDN—Obama's nomination; Putin woos APEC; Bombs hit Damascus; Quakes shake China; Canada cuts Iran ties; weekend read: http://t.co/OFs6dVW4
244102729860009984,2012-09-07 16:00:00 +0000,dhh,RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest achievement: why this goulish jingoism is so warped http://t.co/kood278s
244102490646278146,2012-09-07 15:59:03 +0000,jasonfried,"The story of Mars Curiosity's gears, made by a factory in Rockford, IL: http://t.co/MwCRsHQg"
244102209942458368,2012-09-07 15:57:56 +0000,sferik,"@episod @twitterapi now https://t.co/I17jUTu2 and https://t.co/deDu4Hgw seem to be missing ""1.1"" from the URL."
244100411563339777,2012-09-07 15:50:47 +0000,sferik,@episod @twitterapi Did you catch https://t.co/VHsQvZT0 as well?
244099460672679938,2012-09-07 15:47:01 +0000,dwiskus,"Gentlemen, you can't fight in here! This is the war room! http://t.co/kMxMYyqF"
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.mentions
        expect($stdout.string).to eq <<-eos
Id                   Posted at     Screen name       Text
4611686018427387904  Sep  7 08:35  @mutgoff          Happy Birthday @imdane. ...
 244111183165157376  Sep  7 08:33  @ironicsans       If you like good real-li...
 244110336414859264  Sep  7 08:30  @pat_shaughnessy  Something else to vote f...
 244109797308379136  Sep  7 08:28  @calebelston      Pushing the button to la...
 244108728834592770  Sep  7 08:23  @calebelston      RT @olivercameron: Mosai...
 244107890632294400  Sep  7 08:20  @fivethirtyeight  The Weatherman is Not a ...
 244107823733174272  Sep  7 08:20  @codeforamerica   RT @randomhacks: Going t...
 244107236262170624  Sep  7 08:17  @fbjork           RT @jondot: Just publish...
 244106476048764928  Sep  7 08:14  @mbostock         If you are wondering how...
 244105599351148544  Sep  7 08:11  @FakeDorsey       “Write drunk. Edit sober...
 244104558433951744  Sep  7 08:07  @al3x             RT @wcmaier: Better bank...
 244104146997870594  Sep  7 08:05  @calebelston      We just announced Mosaic...
 244103057175113729  Sep  7 08:01  @BarackObama      Donate $10 or more --> g...
 244102834398851073  Sep  7 08:00  @JEG2             RT @tenderlove: If corpo...
 244102741125890048  Sep  7 08:00  @eveningedition   LDN—Obama's nomination; ...
 244102729860009984  Sep  7 08:00  @dhh              RT @ggreenwald: Democrat...
 244102490646278146  Sep  7 07:59  @jasonfried       The story of Mars Curios...
 244102209942458368  Sep  7 07:57  @sferik           @episod @twitterapi now ...
 244100411563339777  Sep  7 07:50  @sferik           @episod @twitterapi Did ...
 244099460672679938  Sep  7 07:47  @dwiskus          Gentlemen, you can't fig...
        eos
      end
      context "--reverse" do
        before do
          @cli.options = @cli.options.merge("reverse" => true)
        end
        it "reverses the order of the sort" do
          @cli.mentions
          expect($stdout.string).to eq <<-eos
Id                   Posted at     Screen name       Text
 244099460672679938  Sep  7 07:47  @dwiskus          Gentlemen, you can't fig...
 244100411563339777  Sep  7 07:50  @sferik           @episod @twitterapi Did ...
 244102209942458368  Sep  7 07:57  @sferik           @episod @twitterapi now ...
 244102490646278146  Sep  7 07:59  @jasonfried       The story of Mars Curios...
 244102729860009984  Sep  7 08:00  @dhh              RT @ggreenwald: Democrat...
 244102741125890048  Sep  7 08:00  @eveningedition   LDN—Obama's nomination; ...
 244102834398851073  Sep  7 08:00  @JEG2             RT @tenderlove: If corpo...
 244103057175113729  Sep  7 08:01  @BarackObama      Donate $10 or more --> g...
 244104146997870594  Sep  7 08:05  @calebelston      We just announced Mosaic...
 244104558433951744  Sep  7 08:07  @al3x             RT @wcmaier: Better bank...
 244105599351148544  Sep  7 08:11  @FakeDorsey       “Write drunk. Edit sober...
 244106476048764928  Sep  7 08:14  @mbostock         If you are wondering how...
 244107236262170624  Sep  7 08:17  @fbjork           RT @jondot: Just publish...
 244107823733174272  Sep  7 08:20  @codeforamerica   RT @randomhacks: Going t...
 244107890632294400  Sep  7 08:20  @fivethirtyeight  The Weatherman is Not a ...
 244108728834592770  Sep  7 08:23  @calebelston      RT @olivercameron: Mosai...
 244109797308379136  Sep  7 08:28  @calebelston      Pushing the button to la...
 244110336414859264  Sep  7 08:30  @pat_shaughnessy  Something else to vote f...
 244111183165157376  Sep  7 08:33  @ironicsans       If you like good real-li...
4611686018427387904  Sep  7 08:35  @mutgoff          Happy Birthday @imdane. ...
          eos
        end
      end
    end
    context "--number" do
      before do
        stub_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "1"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "200"}).to_return(:body => fixture("200_statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "1", :max_id => "265500541700956160"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "limits the number of results to 1" do
        @cli.options = @cli.options.merge("number" => 1)
        @cli.mentions
        expect(a_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "1"})).to have_been_made
      end
      it "limits the number of results to 201" do
        @cli.options = @cli.options.merge("number" => 201)
        @cli.mentions
        expect(a_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "200"})).to have_been_made
        expect(a_get("/1.1/statuses/mentions_timeline.json").with(:query => {:count => "1", :max_id => "265500541700956160"})).to have_been_made
      end
    end
  end

  describe "#open" do
    before do
      @cli.options = @cli.options.merge("display-url" => true)
    end
    it "has the correct output" do
      expect do
        @cli.open("sferik")
      end.not_to raise_error
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_get("/1.1/users/show.json").with(:query => {:user_id => "420"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.open("420")
        expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "420"})).to have_been_made
      end
    end
    context "--status" do
      before do
        @cli.options = @cli.options.merge("status" => true)
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.open("55709764298092545")
        expect(a_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"})).to have_been_made
      end
      it "has the correct output" do
        expect do
          @cli.open("55709764298092545")
        end.not_to raise_error
      end
    end
  end

  describe "#reply" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc", "location" => true)
      stub_get("/1.1/statuses/show/263813522369159169.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_with_mention.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1.1/statuses/update.json").with(:body => {:in_reply_to_status_id => "263813522369159169", :status => "@joshfrench Testing", :lat => "37.76969909668", :long => "-122.39330291748", :trim_user => "true"}).to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_request(:get, "http://checkip.dyndns.org/").to_return(:body => fixture("checkip.html"), :headers => {:content_type => "text/html"})
      stub_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").to_return(:body => fixture("geoplugin.xml"), :headers => {:content_type => "application/xml"})
    end
    it "requests the correct resource" do
      @cli.reply("263813522369159169", "Testing")
      expect(a_get("/1.1/statuses/show/263813522369159169.json").with(:query => {:include_my_retweet => "false"})).to have_been_made
      expect(a_post("/1.1/statuses/update.json").with(:body => {:in_reply_to_status_id => "263813522369159169", :status => "@joshfrench Testing", :lat => "37.76969909668", :long => "-122.39330291748", :trim_user => "true"})).to have_been_made
      expect(a_request(:get, "http://checkip.dyndns.org/")).to have_been_made
      expect(a_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169")).to have_been_made
    end
    it "has the correct output" do
      @cli.reply("263813522369159169", "Testing")
      expect($stdout.string.split("\n").first).to eq "Reply posted by @testcli to @joshfrench."
    end
    context "--all" do
      before do
        @cli.options = @cli.options.merge("all" => true)
        stub_post("/1.1/statuses/update.json").with(:body => {:in_reply_to_status_id => "263813522369159169", :status => "@joshfrench @sferik Testing", :lat => "37.76969909668", :long => "-122.39330291748", :trim_user => "true"}).to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.reply("263813522369159169", "Testing")
        expect(a_get("/1.1/statuses/show/263813522369159169.json").with(:query => {:include_my_retweet => "false"})).to have_been_made
        expect(a_post("/1.1/statuses/update.json").with(:body => {:in_reply_to_status_id => "263813522369159169", :status => "@joshfrench @sferik Testing", :lat => "37.76969909668", :long => "-122.39330291748", :trim_user => "true"})).to have_been_made
        expect(a_request(:get, "http://checkip.dyndns.org/")).to have_been_made
        expect(a_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169")).to have_been_made
      end
      it "has the correct output" do
        @cli.reply("263813522369159169", "Testing")
        expect($stdout.string.split("\n").first).to eq "Reply posted by @testcli to @joshfrench @sferik."
      end
    end
  end

  describe "#report_spam" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1.1/users/report_spam.json").with(:body => {:screen_name => "sferik"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.report_spam("sferik")
      expect(a_post("/1.1/users/report_spam.json").with(:body => {:screen_name => "sferik"})).to have_been_made
    end
    it "has the correct output" do
      @cli.report_spam("sferik")
      expect($stdout.string).to match /^@testcli reported 1 user/
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_post("/1.1/users/report_spam.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.report_spam("7505382")
        expect(a_post("/1.1/users/report_spam.json").with(:body => {:user_id => "7505382"})).to have_been_made
      end
    end
  end

  describe "#retweet" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1.1/statuses/retweet/26755176471724032.json").to_return(:body => fixture("retweet.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.retweet("26755176471724032")
      expect(a_post("/1.1/statuses/retweet/26755176471724032.json")).to have_been_made
    end
    it "has the correct output" do
      @cli.retweet("26755176471724032")
      expect($stdout.string).to match /^@testcli retweeted 1 tweet.$/
    end
  end

  describe "#retweets" do
    before do
      stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :max_id => "244102729860009983"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    context "without arguments" do
      it "requests the correct resource" do
        @cli.retweets
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true"})).to have_been_made
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :max_id => "244102729860009983"})).to have_been_made.times(3)
      end
      it "has the correct output" do
        @cli.retweets
        expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

\e[1m\e[33m   @fbjork\e[0m
   RT @jondot: Just published: "Pragmatic Concurrency With #Ruby" 
   http://t.co/kGEykswZ /cc @JRuby @headius

\e[1m\e[33m   @al3x\e[0m
   RT @wcmaier: Better banking through better ops: build something new with us 
   @Simplify (remote, PDX) http://t.co/8WgzKZH3

\e[1m\e[33m   @JEG2\e[0m
   RT @tenderlove: If corporations are people, can we use them to drive in the 
   carpool lane?

\e[1m\e[33m   @dhh\e[0m
   RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest 
   achievement: why this goulish jingoism is so warped http://t.co/kood278s

\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

\e[1m\e[33m   @fbjork\e[0m
   RT @jondot: Just published: "Pragmatic Concurrency With #Ruby" 
   http://t.co/kGEykswZ /cc @JRuby @headius

\e[1m\e[33m   @al3x\e[0m
   RT @wcmaier: Better banking through better ops: build something new with us 
   @Simplify (remote, PDX) http://t.co/8WgzKZH3

\e[1m\e[33m   @JEG2\e[0m
   RT @tenderlove: If corporations are people, can we use them to drive in the 
   carpool lane?

\e[1m\e[33m   @dhh\e[0m
   RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest 
   achievement: why this goulish jingoism is so warped http://t.co/kood278s

\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

\e[1m\e[33m   @fbjork\e[0m
   RT @jondot: Just published: "Pragmatic Concurrency With #Ruby" 
   http://t.co/kGEykswZ /cc @JRuby @headius

\e[1m\e[33m   @al3x\e[0m
   RT @wcmaier: Better banking through better ops: build something new with us 
   @Simplify (remote, PDX) http://t.co/8WgzKZH3

\e[1m\e[33m   @JEG2\e[0m
   RT @tenderlove: If corporations are people, can we use them to drive in the 
   carpool lane?

\e[1m\e[33m   @dhh\e[0m
   RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest 
   achievement: why this goulish jingoism is so warped http://t.co/kood278s

\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

        eos
      end
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.retweets
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
244107236262170624,2012-09-07 16:17:55 +0000,fbjork,"RT @jondot: Just published: ""Pragmatic Concurrency With #Ruby"" http://t.co/kGEykswZ   /cc @JRuby @headius"
244104558433951744,2012-09-07 16:07:16 +0000,al3x,"RT @wcmaier: Better banking through better ops: build something new with us @Simplify (remote, PDX) http://t.co/8WgzKZH3"
244102834398851073,2012-09-07 16:00:25 +0000,JEG2,"RT @tenderlove: If corporations are people, can we use them to drive in the carpool lane?"
244102729860009984,2012-09-07 16:00:00 +0000,dhh,RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest achievement: why this goulish jingoism is so warped http://t.co/kood278s
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
244107236262170624,2012-09-07 16:17:55 +0000,fbjork,"RT @jondot: Just published: ""Pragmatic Concurrency With #Ruby"" http://t.co/kGEykswZ   /cc @JRuby @headius"
244104558433951744,2012-09-07 16:07:16 +0000,al3x,"RT @wcmaier: Better banking through better ops: build something new with us @Simplify (remote, PDX) http://t.co/8WgzKZH3"
244102834398851073,2012-09-07 16:00:25 +0000,JEG2,"RT @tenderlove: If corporations are people, can we use them to drive in the carpool lane?"
244102729860009984,2012-09-07 16:00:00 +0000,dhh,RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest achievement: why this goulish jingoism is so warped http://t.co/kood278s
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
244107236262170624,2012-09-07 16:17:55 +0000,fbjork,"RT @jondot: Just published: ""Pragmatic Concurrency With #Ruby"" http://t.co/kGEykswZ   /cc @JRuby @headius"
244104558433951744,2012-09-07 16:07:16 +0000,al3x,"RT @wcmaier: Better banking through better ops: build something new with us @Simplify (remote, PDX) http://t.co/8WgzKZH3"
244102834398851073,2012-09-07 16:00:25 +0000,JEG2,"RT @tenderlove: If corporations are people, can we use them to drive in the carpool lane?"
244102729860009984,2012-09-07 16:00:00 +0000,dhh,RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest achievement: why this goulish jingoism is so warped http://t.co/kood278s
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
       eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.retweets
        expect($stdout.string).to eq <<-eos
Id                  Posted at     Screen name      Text
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244107236262170624  Sep  7 08:17  @fbjork          RT @jondot: Just published...
244104558433951744  Sep  7 08:07  @al3x            RT @wcmaier: Better bankin...
244102834398851073  Sep  7 08:00  @JEG2            RT @tenderlove: If corpora...
244102729860009984  Sep  7 08:00  @dhh             RT @ggreenwald: Democrats ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244107236262170624  Sep  7 08:17  @fbjork          RT @jondot: Just published...
244104558433951744  Sep  7 08:07  @al3x            RT @wcmaier: Better bankin...
244102834398851073  Sep  7 08:00  @JEG2            RT @tenderlove: If corpora...
244102729860009984  Sep  7 08:00  @dhh             RT @ggreenwald: Democrats ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244107236262170624  Sep  7 08:17  @fbjork          RT @jondot: Just published...
244104558433951744  Sep  7 08:07  @al3x            RT @wcmaier: Better bankin...
244102834398851073  Sep  7 08:00  @JEG2            RT @tenderlove: If corpora...
244102729860009984  Sep  7 08:00  @dhh             RT @ggreenwald: Democrats ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
        eos
      end
      context "--reverse" do
        before do
          @cli.options = @cli.options.merge("reverse" => true)
        end
        it "reverses the order of the sort" do
          @cli.retweets
          expect($stdout.string).to eq <<-eos
Id                  Posted at     Screen name      Text
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244102729860009984  Sep  7 08:00  @dhh             RT @ggreenwald: Democrats ...
244102834398851073  Sep  7 08:00  @JEG2            RT @tenderlove: If corpora...
244104558433951744  Sep  7 08:07  @al3x            RT @wcmaier: Better bankin...
244107236262170624  Sep  7 08:17  @fbjork          RT @jondot: Just published...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244102729860009984  Sep  7 08:00  @dhh             RT @ggreenwald: Democrats ...
244102834398851073  Sep  7 08:00  @JEG2            RT @tenderlove: If corpora...
244104558433951744  Sep  7 08:07  @al3x            RT @wcmaier: Better bankin...
244107236262170624  Sep  7 08:17  @fbjork          RT @jondot: Just published...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
244102729860009984  Sep  7 08:00  @dhh             RT @ggreenwald: Democrats ...
244102834398851073  Sep  7 08:00  @JEG2            RT @tenderlove: If corpora...
244104558433951744  Sep  7 08:07  @al3x            RT @wcmaier: Better bankin...
244107236262170624  Sep  7 08:17  @fbjork          RT @jondot: Just published...
244107823733174272  Sep  7 08:20  @codeforamerica  RT @randomhacks: Going to ...
244108728834592770  Sep  7 08:23  @calebelston     RT @olivercameron: Mosaic ...
          eos
        end
      end
    end
    context "--number" do
      before do
        stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :max_id => "244107823733174271"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "limits the number of results to 1" do
        @cli.options = @cli.options.merge("number" => 1)
        @cli.retweets
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true"})).to have_been_made
      end
      it "limits the number of results to 201" do
        @cli.options = @cli.options.merge("number" => 201)
        @cli.retweets
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true"})).to have_been_made
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :max_id => "244107823733174271"})).to have_been_made
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :screen_name => "sferik"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :screen_name => "sferik", :max_id => "244102729860009983"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.retweets("sferik")
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :screen_name => "sferik"})).to have_been_made
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :screen_name => "sferik", :max_id => "244102729860009983"})).to have_been_made.times(3)
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :user_id => "7505382"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :user_id => "7505382", :max_id => "244102729860009983"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.retweets("7505382")
          expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :user_id => "7505382"})).to have_been_made
          expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :include_rts => "true", :user_id => "7505382", :max_id => "244102729860009983"})).to have_been_made.times(3)
        end
      end
    end
  end

  describe "#ruler" do
    it "has the correct output" do
      @cli.ruler
      expect($stdout.string.chomp.size).to eq 140
      expect($stdout.string.chomp).to eq "----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|"
    end
    context "with indentation" do
      before do
        @cli.options = @cli.options.merge("indent" => 2)
      end
      it "has the correct output" do
        @cli.ruler
        expect($stdout.string.chomp.size).to eq 142
        expect($stdout.string.chomp).to eq "  ----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|"
      end
    end
  end

  describe "#status" do
    before do
      stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/i/statuses/55709764298092545/activity/summary.json").to_return(:body => fixture("activity_summary.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resources" do
      @cli.status("55709764298092545")
      expect(a_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"})).to have_been_made
      expect(a_get("/i/statuses/55709764298092545/activity/summary.json")).to have_been_made
    end
    it "has the correct output" do
      @cli.status("55709764298092545")
      expect($stdout.string).to eq <<-eos
Id           55709764298092545
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     Blowfish Sushi To Die For, 2170 Bryant St, San Francisco, California, United States
      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text,Retweets,Favorites,Replies,Source,Location
55709764298092545,2011-04-06 19:13:37 +0000,sferik,The problem with your code is that it's doing exactly what you told it to do.,320,2,1,Twitter for iPhone,"Blowfish Sushi To Die For, 2170 Bryant St, San Francisco, California, United States"
        eos
      end
    end
    context "with no street address" do
      before do
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_street_address.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id           55709764298092550
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     Blowfish Sushi To Die For, San Francisco, California, United States
        eos
      end
    end
    context "with no locality" do
      before do
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_locality.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id           55709764298092549
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     Blowfish Sushi To Die For, San Francisco, California, United States
        eos
      end
    end
    context "with no attributes" do
      before do
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_attributes.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id           55709764298092546
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     Blowfish Sushi To Die For, San Francisco, United States
        eos
      end
    end
    context "with no country" do
      before do
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_country.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id           55709764298092547
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     Blowfish Sushi To Die For, San Francisco
        eos
      end
    end
    context "with no full name" do
      before do
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_full_name.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id           55709764298092548
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     Blowfish Sushi To Die For
        eos
      end
    end
    context "with no place" do
      before do
        stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_place.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_request(:get, "http://maps.google.com/maps/geo").with(:query => hash_including({:key => "REPLACE_WITH_YOUR_GOOGLE_KEY", :oe => "utf-8", :output => "xml"})).to_return(:body => fixture("geo.kml"), :headers => {:content_type => "text/xml; charset=UTF-8"})
      end
      it "has the correct output" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id           55709764298092551
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     San Francisco, CA, USA
        eos
      end
      context "with no city" do
        before do
          stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_place.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_request(:get, "http://maps.google.com/maps/geo").with(:query => hash_including({:key => "REPLACE_WITH_YOUR_GOOGLE_KEY", :oe => "utf-8", :output => "xml"})).to_return(:body => fixture("geo_no_city.kml"), :headers => {:content_type => "text/xml; charset=UTF-8"})
        end
        it "has the correct output" do
          @cli.status("55709764298092545")
          expect($stdout.string).to eq <<-eos
Id           55709764298092551
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     CA, USA
          eos
        end
      end
      context "with no state" do
        before do
          stub_get("/1.1/statuses/show/55709764298092545.json").with(:query => {:include_my_retweet => "false"}).to_return(:body => fixture("status_no_place.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_request(:get, "http://maps.google.com/maps/geo").with(:query => hash_including({:key => "REPLACE_WITH_YOUR_GOOGLE_KEY", :oe => "utf-8", :output => "xml"})).to_return(:body => fixture("geo_no_state.kml"), :headers => {:content_type => "text/xml; charset=UTF-8"})
        end
        it "has the correct output" do
          @cli.status("55709764298092545")
          expect($stdout.string).to eq <<-eos
Id           55709764298092551
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011 (8 months ago)
Retweets     320
Favorites    2
Replies      1
Source       Twitter for iPhone
Location     USA
          eos
        end
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.status("55709764298092545")
        expect($stdout.string).to eq <<-eos
Id                 Posted at     Screen name  Text                           ...
55709764298092545  Apr  6  2011  @sferik      The problem with your code is t...
        eos
      end
    end
  end

  describe "#timeline" do
    before do
      stub_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "20"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    context "without user" do
      it "requests the correct resource" do
        @cli.timeline
        expect(a_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "20"})).to have_been_made
      end
      it "has the correct output" do
        @cli.timeline
        expect($stdout.string).to eq <<-eos
\e[1m\e[33m   @mutgoff\e[0m
   Happy Birthday @imdane. Watch out for those @rally pranksters!

\e[1m\e[33m   @ironicsans\e[0m
   If you like good real-life stories, check out @NarrativelyNY's just-launched 
   site http://t.co/wiUL07jE (and also visit http://t.co/ZoyQxqWA)

\e[1m\e[33m   @pat_shaughnessy\e[0m
   Something else to vote for: "New Rails workshops to bring more women into the 
   Boston software scene" http://t.co/eNBuckHc /cc @bostonrb

\e[1m\e[33m   @calebelston\e[0m
   Pushing the button to launch the site. http://t.co/qLoEn5jG

\e[1m\e[33m   @calebelston\e[0m
   RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k

\e[1m\e[33m   @fivethirtyeight\e[0m
   The Weatherman is Not a Moron: http://t.co/ZwL5Gnq5. An excerpt from my book, 
   THE SIGNAL AND THE NOISE (http://t.co/fNXj8vCE)

\e[1m\e[33m   @codeforamerica\e[0m
   RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, 
   Sep 8 http://t.co/Sk5BM7U3 We'll see y'all there! #rhok @codeforamerica 
   @TheaClay

\e[1m\e[33m   @fbjork\e[0m
   RT @jondot: Just published: "Pragmatic Concurrency With #Ruby" 
   http://t.co/kGEykswZ /cc @JRuby @headius

\e[1m\e[33m   @mbostock\e[0m
   If you are wondering how we computed the split bubbles: http://t.co/BcaqSs5u

\e[1m\e[33m   @FakeDorsey\e[0m
   “Write drunk. Edit sober.”—Ernest Hemingway

\e[1m\e[33m   @al3x\e[0m
   RT @wcmaier: Better banking through better ops: build something new with us 
   @Simplify (remote, PDX) http://t.co/8WgzKZH3

\e[1m\e[33m   @calebelston\e[0m
   We just announced Mosaic, what we've been working on since the Yobongo 
   acquisition. My personal post, http://t.co/ELOyIRZU @heymosaic

\e[1m\e[33m   @BarackObama\e[0m
   Donate $10 or more --> get your favorite car magnet: http://t.co/NfRhl2s2 
   #Obama2012

\e[1m\e[33m   @JEG2\e[0m
   RT @tenderlove: If corporations are people, can we use them to drive in the 
   carpool lane?

\e[1m\e[33m   @eveningedition\e[0m
   LDN—Obama's nomination; Putin woos APEC; Bombs hit Damascus; Quakes shake 
   China; Canada cuts Iran ties; weekend read: http://t.co/OFs6dVW4

\e[1m\e[33m   @dhh\e[0m
   RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest 
   achievement: why this goulish jingoism is so warped http://t.co/kood278s

\e[1m\e[33m   @jasonfried\e[0m
   The story of Mars Curiosity's gears, made by a factory in Rockford, IL: 
   http://t.co/MwCRsHQg

\e[1m\e[33m   @sferik\e[0m
   @episod @twitterapi now https://t.co/I17jUTu2 and https://t.co/deDu4Hgw seem 
   to be missing "1.1" from the URL.

\e[1m\e[33m   @sferik\e[0m
   @episod @twitterapi Did you catch https://t.co/VHsQvZT0 as well?

\e[1m\e[33m   @dwiskus\e[0m
   Gentlemen, you can't fight in here! This is the war room! 
   http://t.co/kMxMYyqF

        eos
      end
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.timeline
        expect($stdout.string).to eq <<-eos
Id,Posted at,Screen name,Text
4611686018427387904,2012-09-07 16:35:24 +0000,mutgoff,Happy Birthday @imdane. Watch out for those @rally pranksters!
244111183165157376,2012-09-07 16:33:36 +0000,ironicsans,"If you like good real-life stories, check out @NarrativelyNY's just-launched site http://t.co/wiUL07jE (and also visit http://t.co/ZoyQxqWA)"
244110336414859264,2012-09-07 16:30:14 +0000,pat_shaughnessy,"Something else to vote for: ""New Rails workshops to bring more women into the Boston software scene"" http://t.co/eNBuckHc /cc @bostonrb"
244109797308379136,2012-09-07 16:28:05 +0000,calebelston,Pushing the button to launch the site. http://t.co/qLoEn5jG
244108728834592770,2012-09-07 16:23:50 +0000,calebelston,RT @olivercameron: Mosaic looks cool: http://t.co/A8013C9k
244107890632294400,2012-09-07 16:20:31 +0000,fivethirtyeight,"The Weatherman is Not a Moron: http://t.co/ZwL5Gnq5. An excerpt from my book, THE SIGNAL AND THE NOISE (http://t.co/fNXj8vCE)"
244107823733174272,2012-09-07 16:20:15 +0000,codeforamerica,"RT @randomhacks: Going to Code Across Austin II: Y'all Come Hack Now, Sat, Sep 8 http://t.co/Sk5BM7U3  We'll see y'all there! #rhok @codeforamerica @TheaClay"
244107236262170624,2012-09-07 16:17:55 +0000,fbjork,"RT @jondot: Just published: ""Pragmatic Concurrency With #Ruby"" http://t.co/kGEykswZ   /cc @JRuby @headius"
244106476048764928,2012-09-07 16:14:53 +0000,mbostock,If you are wondering how we computed the split bubbles: http://t.co/BcaqSs5u
244105599351148544,2012-09-07 16:11:24 +0000,FakeDorsey,“Write drunk. Edit sober.”—Ernest Hemingway
244104558433951744,2012-09-07 16:07:16 +0000,al3x,"RT @wcmaier: Better banking through better ops: build something new with us @Simplify (remote, PDX) http://t.co/8WgzKZH3"
244104146997870594,2012-09-07 16:05:38 +0000,calebelston,"We just announced Mosaic, what we've been working on since the Yobongo acquisition. My personal post, http://t.co/ELOyIRZU @heymosaic"
244103057175113729,2012-09-07 16:01:18 +0000,BarackObama,Donate $10 or more --> get your favorite car magnet: http://t.co/NfRhl2s2 #Obama2012
244102834398851073,2012-09-07 16:00:25 +0000,JEG2,"RT @tenderlove: If corporations are people, can we use them to drive in the carpool lane?"
244102741125890048,2012-09-07 16:00:03 +0000,eveningedition,LDN—Obama's nomination; Putin woos APEC; Bombs hit Damascus; Quakes shake China; Canada cuts Iran ties; weekend read: http://t.co/OFs6dVW4
244102729860009984,2012-09-07 16:00:00 +0000,dhh,RT @ggreenwald: Democrats parade Osama bin Laden's corpse as their proudest achievement: why this goulish jingoism is so warped http://t.co/kood278s
244102490646278146,2012-09-07 15:59:03 +0000,jasonfried,"The story of Mars Curiosity's gears, made by a factory in Rockford, IL: http://t.co/MwCRsHQg"
244102209942458368,2012-09-07 15:57:56 +0000,sferik,"@episod @twitterapi now https://t.co/I17jUTu2 and https://t.co/deDu4Hgw seem to be missing ""1.1"" from the URL."
244100411563339777,2012-09-07 15:50:47 +0000,sferik,@episod @twitterapi Did you catch https://t.co/VHsQvZT0 as well?
244099460672679938,2012-09-07 15:47:01 +0000,dwiskus,"Gentlemen, you can't fight in here! This is the war room! http://t.co/kMxMYyqF"
        eos
      end
    end
    context "--exclude=replies" do
      before do
        @cli.options = @cli.options.merge("exclude" => "replies")
        stub_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "20", :exclude_replies => "true"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "excludes replies" do
        @cli.timeline
        expect(a_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "20", :exclude_replies => "true"})).to have_been_made
      end
    end
    context "--exclude=retweets" do
      before do
        @cli.options = @cli.options.merge("exclude" => "retweets")
        stub_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "20", :include_rts => "false"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "excludes retweets" do
        @cli.timeline
        expect(a_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "20", :include_rts => "false"})).to have_been_made
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.timeline
        expect($stdout.string).to eq <<-eos
Id                   Posted at     Screen name       Text
4611686018427387904  Sep  7 08:35  @mutgoff          Happy Birthday @imdane. ...
 244111183165157376  Sep  7 08:33  @ironicsans       If you like good real-li...
 244110336414859264  Sep  7 08:30  @pat_shaughnessy  Something else to vote f...
 244109797308379136  Sep  7 08:28  @calebelston      Pushing the button to la...
 244108728834592770  Sep  7 08:23  @calebelston      RT @olivercameron: Mosai...
 244107890632294400  Sep  7 08:20  @fivethirtyeight  The Weatherman is Not a ...
 244107823733174272  Sep  7 08:20  @codeforamerica   RT @randomhacks: Going t...
 244107236262170624  Sep  7 08:17  @fbjork           RT @jondot: Just publish...
 244106476048764928  Sep  7 08:14  @mbostock         If you are wondering how...
 244105599351148544  Sep  7 08:11  @FakeDorsey       “Write drunk. Edit sober...
 244104558433951744  Sep  7 08:07  @al3x             RT @wcmaier: Better bank...
 244104146997870594  Sep  7 08:05  @calebelston      We just announced Mosaic...
 244103057175113729  Sep  7 08:01  @BarackObama      Donate $10 or more --> g...
 244102834398851073  Sep  7 08:00  @JEG2             RT @tenderlove: If corpo...
 244102741125890048  Sep  7 08:00  @eveningedition   LDN—Obama's nomination; ...
 244102729860009984  Sep  7 08:00  @dhh              RT @ggreenwald: Democrat...
 244102490646278146  Sep  7 07:59  @jasonfried       The story of Mars Curios...
 244102209942458368  Sep  7 07:57  @sferik           @episod @twitterapi now ...
 244100411563339777  Sep  7 07:50  @sferik           @episod @twitterapi Did ...
 244099460672679938  Sep  7 07:47  @dwiskus          Gentlemen, you can't fig...
        eos
      end
      context "--reverse" do
        before do
          @cli.options = @cli.options.merge("reverse" => true)
        end
        it "reverses the order of the sort" do
          @cli.timeline
          expect($stdout.string).to eq <<-eos
Id                   Posted at     Screen name       Text
 244099460672679938  Sep  7 07:47  @dwiskus          Gentlemen, you can't fig...
 244100411563339777  Sep  7 07:50  @sferik           @episod @twitterapi Did ...
 244102209942458368  Sep  7 07:57  @sferik           @episod @twitterapi now ...
 244102490646278146  Sep  7 07:59  @jasonfried       The story of Mars Curios...
 244102729860009984  Sep  7 08:00  @dhh              RT @ggreenwald: Democrat...
 244102741125890048  Sep  7 08:00  @eveningedition   LDN—Obama's nomination; ...
 244102834398851073  Sep  7 08:00  @JEG2             RT @tenderlove: If corpo...
 244103057175113729  Sep  7 08:01  @BarackObama      Donate $10 or more --> g...
 244104146997870594  Sep  7 08:05  @calebelston      We just announced Mosaic...
 244104558433951744  Sep  7 08:07  @al3x             RT @wcmaier: Better bank...
 244105599351148544  Sep  7 08:11  @FakeDorsey       “Write drunk. Edit sober...
 244106476048764928  Sep  7 08:14  @mbostock         If you are wondering how...
 244107236262170624  Sep  7 08:17  @fbjork           RT @jondot: Just publish...
 244107823733174272  Sep  7 08:20  @codeforamerica   RT @randomhacks: Going t...
 244107890632294400  Sep  7 08:20  @fivethirtyeight  The Weatherman is Not a ...
 244108728834592770  Sep  7 08:23  @calebelston      RT @olivercameron: Mosai...
 244109797308379136  Sep  7 08:28  @calebelston      Pushing the button to la...
 244110336414859264  Sep  7 08:30  @pat_shaughnessy  Something else to vote f...
 244111183165157376  Sep  7 08:33  @ironicsans       If you like good real-li...
4611686018427387904  Sep  7 08:35  @mutgoff          Happy Birthday @imdane. ...
          eos
        end
      end
    end
    context "--number" do
      before do
        stub_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "1"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "200"}).to_return(:body => fixture("200_statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "1", :max_id => "265500541700956160"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "limits the number of results to 1" do
        @cli.options = @cli.options.merge("number" => 1)
        @cli.timeline
        expect(a_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "1"})).to have_been_made
      end
      it "limits the number of results to 201" do
        @cli.options = @cli.options.merge("number" => 201)
        @cli.timeline
        expect(a_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "200"})).to have_been_made
        expect(a_get("/1.1/statuses/home_timeline.json").with(:query => {:count => "1", :max_id => "265500541700956160"})).to have_been_made
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "20", :screen_name => "sferik"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.timeline("sferik")
        expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "20", :screen_name => "sferik"})).to have_been_made
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "20", :user_id => "7505382"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.timeline("7505382")
          expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "20", :user_id => "7505382"})).to have_been_made
        end
      end
      context "--number" do
        before do
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "1", :screen_name => "sferik"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :screen_name => "sferik"}).to_return(:body => fixture("200_statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "1", :screen_name => "sferik", :max_id => "265500541700956160"}).to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "limits the number of results to 1" do
          @cli.options = @cli.options.merge("number" => 1)
          @cli.timeline("sferik")
          expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "1", :screen_name => "sferik"})).to have_been_made
        end
        it "limits the number of results to 201" do
          @cli.options = @cli.options.merge("number" => 201)
          @cli.timeline("sferik")
          expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "200", :screen_name => "sferik"})).to have_been_made
          expect(a_get("/1.1/statuses/user_timeline.json").with(:query => {:count => "1", :screen_name => "sferik", :max_id => "265500541700956160"})).to have_been_made
        end
      end
    end
  end

  describe "#trends" do
    before do
      stub_get("/1.1/trends/place.json").with(:query => {:id => "1"}).to_return(:body => fixture("trends.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.trends
      expect(a_get("/1.1/trends/place.json").with(:query => {:id => "1"})).to have_been_made
    end
    it "has the correct output" do
      @cli.trends
      expect($stdout.string.chomp).to eq "#sevenwordsaftersex  Walkman              Allen Iverson"
    end
    context "--exclude-hashtags" do
      before do
        @cli.options = @cli.options.merge("exclude-hashtags" => true)
        stub_get("/1.1/trends/place.json").with(:query => {:id => "1", :exclude => "hashtags"}).to_return(:body => fixture("trends.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.trends
        expect(a_get("/1.1/trends/place.json").with(:query => {:id => "1", :exclude => "hashtags"})).to have_been_made
      end
      it "has the correct output" do
        @cli.trends
        expect($stdout.string.chomp).to eq "#sevenwordsaftersex  Walkman              Allen Iverson"
      end
    end
    context "with a WOEId passed" do
      before do
        stub_get("/1.1/trends/place.json").with(:query => {:id => "2487956"}).to_return(:body => fixture("trends.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.trends("2487956")
        expect(a_get("/1.1/trends/place.json").with(:query => {:id => "2487956"})).to have_been_made
      end
      it "has the correct output" do
        @cli.trends("2487956")
        expect($stdout.string.chomp).to eq "#sevenwordsaftersex  Walkman              Allen Iverson"
      end
    end
  end

  describe "#trend_locations" do
    before do
      stub_get("/1.1/trends/available.json").to_return(:body => fixture("locations.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.trend_locations
      expect(a_get("/1.1/trends/available.json")).to have_been_made
    end
    it "has the correct output" do
      @cli.trend_locations
      expect($stdout.string.chomp).to eq "Boston         New York       San Francisco  United States  Worldwide"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq <<-eos.chomp
WOEID,Parent ID,Type,Name,Country
2367105,,Town,Boston,United States
2459115,,Town,New York,United States
2487956,,Town,San Francisco,United States
23424977,,Country,United States,United States
1,,Supername,Worldwide,""
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq <<-eos.chomp
WOEID     Parent ID  Type       Name           Country
 2367105             Town       Boston         United States
 2459115             Town       New York       United States
 2487956             Town       San Francisco  United States
23424977             Country    United States  United States
       1             Supername  Worldwide      
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq "Worldwide      United States  San Francisco  New York       Boston"
      end
    end
    context "--sort=country" do
      before do
        @cli.options = @cli.options.merge("sort" => "country")
      end
      it "sorts by number of favorites" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq "Worldwide      New York       Boston         United States  San Francisco"
      end
    end
    context "--sort=parent" do
      before do
        @cli.options = @cli.options.merge("sort" => "parent")
      end
      it "sorts by number of favorites" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq "Boston         Worldwide      New York       United States  San Francisco"
      end
    end
    context "--sort=type" do
      before do
        @cli.options = @cli.options.merge("sort" => "type")
      end
      it "sorts by number of favorites" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq "United States  Worldwide      New York       Boston         San Francisco"
      end
    end
    context "--sort=woeid" do
      before do
        @cli.options = @cli.options.merge("sort" => "woeid")
      end
      it "sorts by number of favorites" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq "Worldwide      Boston         New York       San Francisco  United States"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.trend_locations
        expect($stdout.string.chomp).to eq "Boston         Worldwide      New York       United States  San Francisco"
      end
    end
  end

  describe "#unfollow" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc")
    end
    context "one user" do
      it "requests the correct resource" do
        stub_post("/1.1/friendships/destroy.json").with(:body => {:screen_name => "sferik"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        @cli.unfollow("sferik")
        expect(a_post("/1.1/friendships/destroy.json").with(:body => {:screen_name => "sferik"})).to have_been_made
      end
      it "has the correct output" do
        stub_post("/1.1/friendships/destroy.json").with(:body => {:screen_name => "sferik"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        @cli.unfollow("sferik")
        expect($stdout.string).to match /^@testcli is no longer following 1 user\.$/
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge("id" => true)
          stub_post("/1.1/friendships/destroy.json").with(:body => {:user_id => "7505382"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "requests the correct resource" do
          @cli.unfollow("7505382")
          expect(a_post("/1.1/friendships/destroy.json").with(:body => {:user_id => "7505382"})).to have_been_made
        end
      end
      context "Twitter is down" do
        it "retries 3 times and then raise an error" do
          stub_post("/1.1/friendships/destroy.json").with(:body => {:screen_name => "sferik"}).to_return(:status => 502)
          expect do
            @cli.unfollow("sferik")
          end.to raise_error("Twitter is down or being upgraded.")
          expect(a_post("/1.1/friendships/destroy.json").with(:body => {:screen_name => "sferik"})).to have_been_made.times(3)
        end
      end
    end
  end

  describe "#update" do
    before do
      @cli.options = @cli.options.merge("profile" => fixture_path + "/.trc", "location" => true)
      stub_post("/1.1/statuses/update.json").with(:body => {:status => "Testing", :lat => "37.76969909668", :long => "-122.39330291748", :trim_user => "true"}).to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_request(:get, "http://checkip.dyndns.org/").to_return(:body => fixture("checkip.html"), :headers => {:content_type => "text/html"})
      stub_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").to_return(:body => fixture("geoplugin.xml"), :headers => {:content_type => "application/xml"})
    end
    it "requests the correct resource" do
      @cli.update("Testing")
      expect(a_post("/1.1/statuses/update.json").with(:body => {:status => "Testing", :lat => "37.76969909668", :long => "-122.39330291748", :trim_user => "true"})).to have_been_made
      expect(a_request(:get, "http://checkip.dyndns.org/")).to have_been_made
      expect(a_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169")).to have_been_made
    end
    it "has the correct output" do
      @cli.update("Testing")
      expect($stdout.string.split("\n").first).to eq "Tweet posted by @testcli."
    end
    context "with file" do
      before do
        @cli.options = @cli.options.merge("file" => fixture_path + "/long.png")
        stub_post("/1.1/statuses/update_with_media.json").to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.update("Testing")
        expect(a_post("/1.1/statuses/update_with_media.json")).to have_been_made
      end
      it "has the correct output" do
        @cli.update("Testing")
        expect($stdout.string.split("\n").first).to eq "Tweet posted by @testcli."
      end
    end
  end

  describe "#users" do
    before do
      stub_post("/1.1/users/lookup.json").with(:body => {:screen_name => "sferik,pengwynn"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.users("sferik", "pengwynn")
      expect(a_post("/1.1/users/lookup.json").with(:body => {:screen_name => "sferik,pengwynn"})).to have_been_made
    end
    it "has the correct output" do
      @cli.users("sferik", "pengwynn")
      expect($stdout.string.chomp).to eq "pengwynn  sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "outputs in CSV format" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
14100886,2008-03-08 16:34:22 +0000,2012-07-07 20:33:19 +0000,6940,192,358,3427,5457,pengwynn,Wynn Netherland ⚡,false,"Christian, husband, father, GitHubber, Co-host of @thechangelog, Co-author of Sass, Compass, #CSS book  http://wynn.fm/sass-meap",@akosmasoftware Sass book! @hcatlin @nex3 are the brains behind Sass. :-),"Denton, TX",http://wynnnetherland.com
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string).to eq <<-eos
Id        Since         Last tweeted at  Tweets  Favorites  Listed  Following...
14100886  Mar  8  2008  Jul  7 12:33       6940        192     358       3427...
 7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212...
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge("reverse" => true)
      end
      it "reverses the order of the sort" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=favorites" do
      before do
        @cli.options = @cli.options.merge("sort" => "favorites")
      end
      it "sorts by number of favorites" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=followers" do
      before do
        @cli.options = @cli.options.merge("sort" => "followers")
      end
      it "sorts by number of followers" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=friends" do
      before do
        @cli.options = @cli.options.merge("sort" => "friends")
      end
      it "sorts by number of friends" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382,14100886"}).to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.users("7505382", "14100886")
        expect(a_post("/1.1/users/lookup.json").with(:body => {:user_id => "7505382,14100886"})).to have_been_made
      end
    end
    context "--sort=listed" do
      before do
        @cli.options = @cli.options.merge("sort" => "listed")
      end
      it "sorts by number of list memberships" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=since" do
      before do
        @cli.options = @cli.options.merge("sort" => "since")
      end
      it "sorts by the time when Twitter acount was created" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "sferik    pengwynn"
      end
    end
    context "--sort=tweets" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweets")
      end
      it "sorts by number of Tweets" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--sort=tweeted" do
      before do
        @cli.options = @cli.options.merge("sort" => "tweeted")
      end
      it "sorts by the time of the last Tweet" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge("unsorted" => true)
      end
      it "is not sorted" do
        @cli.users("sferik", "pengwynn")
        expect($stdout.string.chomp).to eq "pengwynn  sferik"
      end
    end
  end

  describe "#version" do
    it "has the correct output" do
      @cli.version
      expect($stdout.string.chomp).to eq T::Version.to_s
    end
  end

  describe "#whois" do
    before do
      stub_get("/1.1/users/show.json").with(:query => {:screen_name => "sferik"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "requests the correct resource" do
      @cli.whois("sferik")
      expect(a_get("/1.1/users/show.json").with(:query => {:screen_name => "sferik"})).to have_been_made
    end
    it "has the correct output" do
      @cli.whois("sferik")
      expect($stdout.string).to eq <<-eos
Id           7505382
Since        Jul 16  2007 (4 years ago)
Last update  @goldman You're near my home town! Say hi to Woodstock for me. (7 months ago)
Screen name  @sferik
Name         Erik Michaels-Ober
Tweets       7,890
Favorites    3,755
Listed       118
Following    212
Followers    2,262
Bio          Vagabond.
Location     San Francisco
URL          https://github.com/sferik
      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge("csv" => true)
      end
      it "has the correct output" do
        @cli.whois("sferik")
        expect($stdout.string).to eq <<-eos
Id,Since,Last tweeted at,Tweets,Favorites,Listed,Following,Followers,Screen name,Name,Verified,Bio,Status,Location,URL
7505382,2007-07-16 12:59:01 +0000,2012-07-08 18:29:20 +0000,7890,3755,118,212,2262,sferik,Erik Michaels-Ober,false,Vagabond.,@goldman You're near my home town! Say hi to Woodstock for me.,San Francisco,https://github.com/sferik
        eos
      end
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge("id" => true)
        stub_get("/1.1/users/show.json").with(:query => {:user_id => "7505382"}).to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "requests the correct resource" do
        @cli.whois("7505382")
        expect(a_get("/1.1/users/show.json").with(:query => {:user_id => "7505382"})).to have_been_made
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge("long" => true)
      end
      it "outputs in long format" do
        @cli.whois("sferik")
        expect($stdout.string).to eq <<-eos
Id       Since         Last tweeted at  Tweets  Favorites  Listed  Following ...
7505382  Jul 16  2007  Jul  8 10:29       7890       3755     118        212 ...
        eos
      end
    end
  end

end
