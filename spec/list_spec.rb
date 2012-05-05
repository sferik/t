# encoding: utf-8
require 'helper'

describe T::List do

  before do
    rcfile = RCFile.instance
    rcfile.path = fixture_path + "/.trc"
    @list = T::List.new
    @old_stderr = $stderr
    $stderr = StringIO.new
    @old_stdout = $stdout
    $stdout = StringIO.new
    Timecop.freeze(Time.utc(2011, 11, 24, 16, 20, 0))
  end

  after do
    Timecop.return
    $stderr = @old_stderr
    $stdout = @old_stdout
  end

  describe "#add" do
    before do
      @list.options = @list.options.merge("profile" => fixture_path + "/.trc")
      stub_get("/1/account/verify_credentials.json").
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1/lists/members/create_all.json").
        with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
        to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @list.add("presidents", "BarackObama")
      a_get("/1/account/verify_credentials.json").
        should have_been_made
      a_post("/1/lists/members/create_all.json").
        with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
        should have_been_made
    end
    it "should have the correct output" do
      @list.add("presidents", "BarackObama")
      $stdout.string.should =~ /@testcli added 1 member to the list "presidents"\./
    end
    context "--id" do
      before do
        @list.options = @list.options.merge("id" => true)
        stub_post("/1/lists/members/create_all.json").
          with(:body => {:user_id => "7505382", :slug => "presidents", :owner_screen_name => "sferik"}).
          to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @list.add("presidents", "7505382")
        a_get("/1/account/verify_credentials.json").
          should have_been_made
        a_post("/1/lists/members/create_all.json").
          with(:body => {:user_id => "7505382", :slug => "presidents", :owner_screen_name => "sferik"}).
          should have_been_made
      end
    end
    context "Twitter is down" do
      it "should retry 3 times and then raise an error" do
        stub_post("/1/lists/members/create_all.json").
          with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
          to_return(:status => 502)
        lambda do
          @list.add("presidents", "BarackObama")
        end.should raise_error("Twitter is down or being upgraded.")
        a_post("/1/lists/members/create_all.json").
          with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
          should have_been_made.times(3)
      end
    end
  end

  describe "#create" do
    before do
      @list.options = @list.options.merge("profile" => fixture_path + "/.trc")
      stub_post("/1/lists/create.json").
        with(:body => {:name => "presidents"}).
        to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @list.create("presidents")
      a_post("/1/lists/create.json").
        with(:body => {:name => "presidents"}).
        should have_been_made
    end
    it "should have the correct output" do
      @list.create("presidents")
      $stdout.string.chomp.should == "@testcli created the list \"presidents\"."
    end
  end

  describe "#information" do
    before do
      @list.options = @list.options.merge("profile" => fixture_path + "/.trc")
      stub_get("/1/lists/show.json").
        with(:query => {:owner_screen_name => "testcli", :slug => "presidents"}).
        to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @list.information("presidents")
      a_get("/1/lists/show.json").
        with(:query => {:owner_screen_name => "testcli", :slug => "presidents"}).
        should have_been_made
    end
    it "should have the correct output" do
      @list.information("presidents")
      $stdout.string.should == <<-eos
ID           8863586
Description  Presidents of the United States of America
Slug         presidents
Screen name  @sferik
Created at   Mar 15  2010
Members      2
Subscribers  1
Status       Not following
Mode         public
URL          https://twitter.com/sferik/presidents
      eos
    end
    context "with a user passed" do
      it "should request the correct resource" do
        @list.information("testcli/presidents")
        a_get("/1/lists/show.json").
          with(:query => {:owner_screen_name => "testcli", :slug => "presidents"}).
          should have_been_made
      end
      context "--id" do
        before do
          @list.options = @list.options.merge("id" => true)
          stub_get("/1/lists/show.json").
            with(:query => {:owner_id => "7505382", :slug => "presidents"}).
            to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @list.information("7505382/presidents")
          a_get("/1/lists/show.json").
            with(:query => {:owner_id => "7505382", :slug => "presidents"}).
            should have_been_made
        end
      end
    end
    context "--csv" do
      before do
        @list.options = @list.options.merge("csv" => true)
      end
      it "should have the correct output" do
        @list.information("presidents")
        $stdout.string.should == <<-eos
ID,Description,Slug,Screen name,Created at,Members,Subscribers,Following,Mode,URL
8863586,Presidents of the United States of America,presidents,sferik,2010-03-15 12:10:13 +0000,2,1,false,public,https://twitter.com/sferik/presidents
        eos
      end
    end
  end

  describe "#members" do
    before do
      stub_get("/1/lists/members.json").
        with(:query => {:cursor => "-1", :owner_screen_name => "testcli", :skip_status => "true", :slug => "presidents"}).
        to_return(:body => fixture("users_list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @list.members("presidents")
      a_get("/1/lists/members.json").
        with(:query => {:cursor => "-1", :owner_screen_name => "testcli", :skip_status => "true", :slug => "presidents"}).
        should have_been_made
    end
    it "should have the correct output" do
      @list.members("presidents")
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @list.options = @list.options.merge("csv" => true)
      end
      it "should output in CSV format" do
        @list.members("presidents")
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @list.options = @list.options.merge("favorites" => true)
      end
      it "should sort by number of favorites" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @list.options = @list.options.merge("followers" => true)
      end
      it "should sort by number of followers" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @list.options = @list.options.merge("friends" => true)
      end
      it "should sort by number of friends" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--listed" do
      before do
        @list.options = @list.options.merge("listed" => true)
      end
      it "should sort by number of list memberships" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @list.options = @list.options.merge("long" => true)
      end
      it "should output in long format" do
        @list.members("presidents")
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Scre...
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pen...
 7505382  Jul 16  2007  2,962   727        29      88         898        @sfe...
        eos
      end
    end
    context "--posted" do
      before do
        @list.options = @list.options.merge("posted" => true)
      end
      it "should sort by the time wshen Twitter account was created" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @list.options = @list.options.merge("reverse" => true)
      end
      it "should reverse the order of the sort" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @list.options = @list.options.merge("tweets" => true)
      end
      it "should sort by number of Tweets" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @list.options = @list.options.merge("unsorted" => true)
      end
      it "should not be sorted" do
        @list.members("presidents")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "with a user passed" do
      it "should request the correct resource" do
        @list.members("testcli/presidents")
        a_get("/1/lists/members.json").
          with(:query => {:cursor => "-1", :owner_screen_name => "testcli", :skip_status => "true", :slug => "presidents"}).
          should have_been_made
      end
      context "--id" do
        before do
          @list.options = @list.options.merge("id" => true)
          stub_get("/1/lists/members.json").
            with(:query => {:cursor => "-1", :owner_id => "7505382", :skip_status => "true", :slug => "presidents"}).
            to_return(:body => fixture("users_list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @list.members("7505382/presidents")
          a_get("/1/lists/members.json").
            with(:query => {:cursor => "-1", :owner_id => "7505382", :skip_status => "true", :slug => "presidents"}).
            should have_been_made
        end
      end
    end
  end

  describe "#remove" do
    before do
      @list.options = @list.options.merge("profile" => fixture_path + "/.trc")
      stub_get("/1/account/verify_credentials.json").
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      stub_post("/1/lists/members/destroy_all.json").
        with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
        to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      @list.remove("presidents", "BarackObama")
      a_get("/1/account/verify_credentials.json").
        should have_been_made
      a_post("/1/lists/members/destroy_all.json").
        with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
        should have_been_made
    end
    it "should have the correct output" do
      stub_post("/1/lists/members/destroy_all.json").
        with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
        to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      @list.remove("presidents", "BarackObama")
      $stdout.string.should =~ /@testcli removed 1 member from the list "presidents"\./
    end
    context "--id" do
      before do
        @list.options = @list.options.merge("id" => true)
        stub_post("/1/lists/members/destroy_all.json").
          with(:body => {:user_id => "7505382", :slug => "presidents", :owner_screen_name => "sferik"}).
          to_return(:body => fixture("list.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @list.remove("presidents", "7505382")
        a_get("/1/account/verify_credentials.json").
          should have_been_made
        a_post("/1/lists/members/destroy_all.json").
          with(:body => {:user_id => "7505382", :slug => "presidents", :owner_screen_name => "sferik"}).
          should have_been_made
      end
    end
    context "Twitter is down" do
      it "should retry 3 times and then raise an error" do
        stub_post("/1/lists/members/destroy_all.json").
          with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
          to_return(:status => 502)
        lambda do
          @list.remove("presidents", "BarackObama")
        end.should raise_error("Twitter is down or being upgraded.")
        a_post("/1/lists/members/destroy_all.json").
          with(:body => {:screen_name => "BarackObama", :slug => "presidents", :owner_screen_name => "sferik"}).
          should have_been_made.times(3)
      end
    end
  end

  describe "#timeline" do
    before do
      stub_get("/1/lists/statuses.json").
        with(:query => {:owner_screen_name => "testcli", :per_page => "20", :slug => "presidents"}).
        to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @list.timeline("presidents")
      a_get("/1/lists/statuses.json").
        with(:query => {:owner_screen_name => "testcli", :per_page => "20", :slug => "presidents"}).
        should have_been_made
    end
    it "should have the correct output" do
      @list.timeline("presidents")
      $stdout.string.should =~ /@natevillegas/
      $stdout.string.should =~ /RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history\. Tomorrow is a /
      $stdout.string.should =~ /mystery\. Today is a gift\. That's why it's called the present\./
    end
    context "--csv" do
      before do
        @list.options = @list.options.merge("csv" => true)
      end
      it "should output in long format" do
        @list.timeline("presidents")
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
194548121416630272,2011-04-23 22:07:41 +0000,natevillegas,RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976,2011-04-23 22:07:10 +0000,TD,@kelseysilver how long will you be in town?
194547987593183233,2011-04-23 22:07:09 +0000,rusashka,@maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888,2011-04-23 22:06:30 +0000,fat,@stevej @xc i'm going to picket when i get back.
194547658562605057,2011-04-23 22:05:51 +0000,wil,@0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344,2011-04-23 22:05:19 +0000,wangtian,"@tianhonghe @xiangxin72 oh, you can even order specific items?"
194547402550689793,2011-04-23 22:04:49 +0000,shinypb,"@kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird"
194547260233760768,2011-04-23 22:04:16 +0000,0x9900,@wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544,2011-04-23 22:03:34 +0000,kpk,@shinypb @skilldrick @hoverbird invented it
194546876782092291,2011-04-23 22:02:44 +0000,skilldrick,@shinypb Well played :) @hoverbird
194546811480969217,2011-04-23 22:02:29 +0000,sam,"Can someone project the date that I'll get a 27"" retina display?"
194546738810458112,2011-04-23 22:02:11 +0000,shinypb,"@skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain."
194546727670390784,2011-04-23 22:02:09 +0000,bartt,"@noahlt @gaarf Yup, now owning @twitter -> FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come."
194546649203347456,2011-04-23 22:01:50 +0000,skilldrick,"@hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all."
194546583608639488,2011-04-23 22:01:34 +0000,sean,@mep Thanks for coming by. Was great to have you.
194546388707717120,2011-04-23 22:00:48 +0000,hoverbird,"@shinypb @trammell it's all suck a ""duck blur"" sometimes."
194546264212385793,2011-04-23 22:00:18 +0000,kelseysilver,San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--long" do
      before do
        @list.options = @list.options.merge("long" => true)
      end
      it "should output in long format" do
        @list.timeline("presidents")
        $stdout.string.should == <<-eos
ID                  Posted at     Screen name    Text
194548121416630272  Apr 23  2011  @natevillegas  RT @gelobautista #riordan RT...
194547993607806976  Apr 23  2011  @TD            @kelseysilver how long will ...
194547987593183233  Apr 23  2011  @rusashka      @maciej hahaha :) @gpena tog...
194547824690597888  Apr 23  2011  @fat           @stevej @xc i'm going to pic...
194547658562605057  Apr 23  2011  @wil           @0x9900 @paulnivin http://t....
194547528430137344  Apr 23  2011  @wangtian      @tianhonghe @xiangxin72 oh, ...
194547402550689793  Apr 23  2011  @shinypb       @kpk Pfft, I think you're fo...
194547260233760768  Apr 23  2011  @0x9900        @wil @paulnivin if you want ...
194547084349804544  Apr 23  2011  @kpk           @shinypb @skilldrick @hoverb...
194546876782092291  Apr 23  2011  @skilldrick    @shinypb Well played :) @hov...
194546811480969217  Apr 23  2011  @sam           Can someone project the date...
194546738810458112  Apr 23  2011  @shinypb       @skilldrick @hoverbird Wow, ...
194546727670390784  Apr 23  2011  @bartt         @noahlt @gaarf Yup, now owni...
194546649203347456  Apr 23  2011  @skilldrick    @hoverbird @shinypb You guys...
194546583608639488  Apr 23  2011  @sean          @mep Thanks for coming by. W...
194546388707717120  Apr 23  2011  @hoverbird     @shinypb @trammell it's all ...
194546264212385793  Apr 23  2011  @kelseysilver  San Francisco here I come! (...
        eos
      end
      context "--reverse" do
        before do
          @list.options = @list.options.merge("reverse" => true)
        end
        it "should reverse the order of the sort" do
          @list.timeline("presidents")
          $stdout.string.should == <<-eos
ID                  Posted at     Screen name    Text
194546264212385793  Apr 23  2011  @kelseysilver  San Francisco here I come! (...
194546388707717120  Apr 23  2011  @hoverbird     @shinypb @trammell it's all ...
194546583608639488  Apr 23  2011  @sean          @mep Thanks for coming by. W...
194546649203347456  Apr 23  2011  @skilldrick    @hoverbird @shinypb You guys...
194546727670390784  Apr 23  2011  @bartt         @noahlt @gaarf Yup, now owni...
194546738810458112  Apr 23  2011  @shinypb       @skilldrick @hoverbird Wow, ...
194546811480969217  Apr 23  2011  @sam           Can someone project the date...
194546876782092291  Apr 23  2011  @skilldrick    @shinypb Well played :) @hov...
194547084349804544  Apr 23  2011  @kpk           @shinypb @skilldrick @hoverb...
194547260233760768  Apr 23  2011  @0x9900        @wil @paulnivin if you want ...
194547402550689793  Apr 23  2011  @shinypb       @kpk Pfft, I think you're fo...
194547528430137344  Apr 23  2011  @wangtian      @tianhonghe @xiangxin72 oh, ...
194547658562605057  Apr 23  2011  @wil           @0x9900 @paulnivin http://t....
194547824690597888  Apr 23  2011  @fat           @stevej @xc i'm going to pic...
194547987593183233  Apr 23  2011  @rusashka      @maciej hahaha :) @gpena tog...
194547993607806976  Apr 23  2011  @TD            @kelseysilver how long will ...
194548121416630272  Apr 23  2011  @natevillegas  RT @gelobautista #riordan RT...
          eos
        end
      end
    end
    context "--number" do
      before do
        stub_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "1", :slug => "presidents"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "200", :slug => "presidents"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "145", :max_id => "194546264212385792", :slug => "presidents"}).
          to_return(:body => fixture("empty_array.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results to 1" do
        @list.options = @list.options.merge("number" => 1)
        @list.timeline("presidents")
        a_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "1", :slug => "presidents"}).
          should have_been_made
      end
      it "should limit the number of results to 345" do
        @list.options = @list.options.merge("number" => 345)
        @list.timeline("presidents")
        a_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "200", :slug => "presidents"}).
          should have_been_made
        a_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "145", :max_id => "194546264212385792", :slug => "presidents"}).
          should have_been_made
      end
    end
    context "with a user passed" do
      it "should request the correct resource" do
        @list.timeline("testcli/presidents")
        a_get("/1/lists/statuses.json").
          with(:query => {:owner_screen_name => "testcli", :per_page => "20", :slug => "presidents"}).
          should have_been_made
      end
      context "--id" do
        before do
          @list.options = @list.options.merge("id" => true)
          stub_get("/1/lists/statuses.json").
            with(:query => {:owner_id => "7505382", :per_page => "20", :slug => "presidents"}).
            to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @list.timeline("7505382/presidents")
          a_get("/1/lists/statuses.json").
            with(:query => {:owner_id => "7505382", :per_page => "20", :slug => "presidents"}).
            should have_been_made
        end
      end
    end
  end

end
