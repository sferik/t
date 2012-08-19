# encoding: utf-8
require 'helper'

describe T::Set do

  before :each do
    T::RCFile.instance.path = fixture_path + "/.trc"
    @set = T::Set.new
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

  describe "#active" do
    before do
      @set.options = @set.options.merge("profile" => fixture_path + "/.trc_set")
    end
    it "should have the correct output" do
      @set.active("testcli", "abc123")
      $stdout.string.chomp.should == "Active account has been updated to testcli."
    end
    it "should accept an account name without a consumer key" do
      @set.active("testcli")
      $stdout.string.chomp.should == "Active account has been updated to testcli."
    end
    it "should be case insensitive" do
      @set.active("TestCLI", "abc123")
      $stdout.string.chomp.should == "Active account has been updated to testcli."
    end
    it "should raise an error if username is ambiguous" do
      lambda do
        @set.active("test", "abc123")
      end.should raise_error(ArgumentError, /Username test is ambiguous/)
    end
    it "should raise an error if the username is not found" do
      lambda do
        @set.active("clitest")
      end.should raise_error(ArgumentError, /Username clitest is not found/)
    end
  end

  describe "#bio" do
    before do
      @set.options = @set.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1/account/update_profile.json").
        with(:body => {:description => "Vagabond."}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @set.bio("Vagabond.")
      a_post("/1/account/update_profile.json").
        with(:body => {:description => "Vagabond."}).
        should have_been_made
    end
    it "should have the correct output" do
      @set.bio("Vagabond.")
      $stdout.string.chomp.should == "@testcli's bio has been updated."
    end
  end

  describe "#language" do
    before do
      @set.options = @set.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1/account/settings.json").
        with(:body => {:lang => "en"}).
        to_return(:body => fixture("settings.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @set.language("en")
      a_post("/1/account/settings.json").
        with(:body => {:lang => "en"}).
        should have_been_made
    end
    it "should have the correct output" do
      @set.language("en")
      $stdout.string.chomp.should == "@testcli's language has been updated."
    end
  end

  describe "#location" do
    before do
      @set.options = @set.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1/account/update_profile.json").
        with(:body => {:location => "San Francisco"}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @set.location("San Francisco")
      a_post("/1/account/update_profile.json").
        with(:body => {:location => "San Francisco"}).
        should have_been_made
    end
    it "should have the correct output" do
      @set.location("San Francisco")
      $stdout.string.chomp.should == "@testcli's location has been updated."
    end
  end

  describe "#name" do
    before do
      @set.options = @set.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1/account/update_profile.json").
        with(:body => {:name => "Erik Michaels-Ober"}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @set.name("Erik Michaels-Ober")
      a_post("/1/account/update_profile.json").
        with(:body => {:name => "Erik Michaels-Ober"}).
        should have_been_made
    end
    it "should have the correct output" do
      @set.name("Erik Michaels-Ober")
      $stdout.string.chomp.should == "@testcli's name has been updated."
    end
  end

  describe "#url" do
    before do
      @set.options = @set.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1/account/update_profile.json").
        with(:body => {:url => "https://github.com/sferik"}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @set.url("https://github.com/sferik")
      a_post("/1/account/update_profile.json").
        with(:body => {:url => "https://github.com/sferik"}).
        should have_been_made
    end
    it "should have the correct output" do
      @set.url("https://github.com/sferik")
      $stdout.string.chomp.should == "@testcli's URL has been updated."
    end
  end

end
