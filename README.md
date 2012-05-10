# Twitter CLI [![Build Status](https://secure.travis-ci.org/sferik/t.png?branch=master)][travis] [![Dependency Status](https://gemnasium.com/sferik/t.png?travis)][gemnasium] [![Click here to make a donation to T](http://www.pledgie.com/campaigns/17330.png)][pledgie] 

# [![Application icon](https://github.com/sferik/t/raw/master/cli-bird.png)][icon]

### A command-line power tool for Twitter.

The CLI takes syntactic cues from the [Twitter SMS commands][sms], however it
offers vastly more commands and capabilities than are available via SMS.

[travis]: http://travis-ci.org/sferik/t
[gemnasium]: https://gemnasium.com/sferik/t
[pledgie]: http://www.pledgie.com/campaigns/17330
[gem]: https://rubygems.org/gems/twitter
[sms]: https://support.twitter.com/articles/14020-twitter-sms-command

## Installation
    # Requires Ruby :)
    gem install t

## Configuration

Twitter requires OAuth for most of its functionality, so you'll need to
register a new application at <http://dev.twitter.com/apps/new>. Once you
create your application, make sure to set your application's Access Level to
"Read, Write and Access direct messages", otherwise you may receive an error
that looks something like this:

    Read-only application cannot POST

Once you've successfully registered your application, you'll be given a
consumer key and secret, which you can use to authorize your Twitter account.

    t authorize -c YOUR_CONSUMER_KEY -s YOUR_CONSUMER_SECRET

This command directs you to a URL where you can sign-in to Twitter and then
enter the returned PIN back into the terminal. If you type the PIN correctly,
you should now be authorized to use `t` as that user. To authorize multiple
accounts, simply repeat the last step, signing into Twitter as a different
user.

You can see a list of all the accounts you've authorized by typing the command:

    t accounts

The output of which will be structured like this:

    sferik
      UDfNTpOz5ZDG4a6w7dIWj
      uuP7Xbl2mEfGMiDu1uIyFN
    gem
      thG9EfWoADtIr6NjbL9ON (active)

**Note**: One of your authorized accounts (specifically, the last one
authorized) will be set as active. To change the active account, use the `set`
subcommand, passing either just a username, if it's unambiguous, or a username
and consumer key pair, like this:

    t set active sferik UDfNTpOz5ZDG4a6w7dIWj

Account information is stored in a YAML-formatted file located at `~/.trc`.

**Note**: Anyone with access to this file can masquerade as you on Twitter, so
it's important to keep it secure, just as you would treat your SSH private key.
For this reason, the file is hidden and has the permission bits set to `0600`.

## Usage Examples
Typing `t help` will list all the available commands. You can type `t help
TASK` to get help for a specific command.

    t help

### Update your status
    t update "I'm tweeting from the command line. Isn't that special?"

**Note**: If your tweet includes special characters (e.g. `!`), make sure to
wrap it in single quotes instead of double quotes, so those characters are not
interpreted by your shell. (However, if you use single quotes, your Tweet
obviously can't contain any apostrophes.)

### Retrieve detailed information about a Twitter user
    t whois @sferik

### Retrieve stats for multiple users
    t users -l @sferik @gem

### Follow users
    t follow @sferik @gem

### Check whether one user follows another
    t does_follow @ev @sferik

**Note**: If the first user does not follow the second, `t` will exit with a
non-zero exit code. This allows you to execute commands conditionally, for
example, send a user a direct message only if he already follows you:

    t does_follow @ev && t dm @ev "What's up, bro?"

### Create a list for everyone you're following
    t list create following-`date "+%Y-%m-%d"`

### Add everyone you're following to that list (up to 500 users)
    t followings | xargs t list add following-`date "+%Y-%m-%d"`

### List all the members of a list, in long format
    t list members -l following-`date "+%Y-%m-%d"`

### List all your lists, in long format
    t lists -l

### List all your friends, in long format, ordered by number of followers
    t friends -lf

### List all your leaders (people you follow who don't follow you back)
    t leaders -lf

### Unfollow everyone you follow who doesn't follow you back
    t leaders | xargs t unfollow

### Twitter roulette: randomly follow someone who follows you (who you don't already follow)
    t groupies | shuf | head -1 | xargs t follow

### Favorite the last 10 tweets that mention you
    t mentions -n 10 -l | awk '{print $1}' | xargs t favorite

### Output the last 200 tweets in your timeline to a CSV file
    t timeline -n 200 --csv > timeline.csv

### Start streaming your timeline (Control-C to stop)
    t stream timeline

### Count the number of employees who work for Twitter
    t list members twitter team | wc -l

### Search Twitter for the 20 most recent Tweets that match a specified query
    t search all "query"

### Download the latest Linux kernel via BitTorrent (possibly NSFW, depending where you work)
    t search all "lang:en filter:links linux torrent" -n 1 | grep -o "http://t.co/[0-9A-Za-z]*" | xargs open

### Search Tweets you've favorited that match a specified query
    t search favorites "query"

### Search Tweets mentioning you that match a specified query
    t search mentions "query"

### Search Tweets you've retweeted that match a specified query
    t search retweets "query"

### Search Tweets in your timeline that match a specified query
    t search timeline "query"

### Search Tweets in another user's timeline that match a specified query
    t search user @sferik "query"

## Features
* Deep search: Instead of using the Twitter Search API, [which only only goes
  back 6-9 days][index], `t search` fetches up to 3,200 tweets via the REST API
  and then checks each one against a regular expression.
* Multithreaded: Whenever possible, Twitter API requests are made in parallel,
  resulting in faster performance for bulk operations.
* Designed for Unix: Output is designed to be piped to other Unix utilities,
  like grep, cut, awk, bc, wc, and xargs for advanced text processing.
* Generate spreadsheets: Convert the output of any command to CSV format simply
  by adding the `--csv` flag.
* 95% C0 Code Coverage: Well tested, with a 2.5:1 test-to-code ratio.

[search]: https://dev.twitter.com/docs/using-search

# Using T for Backup

[@jphpsf][jphpsf] wrote a [blog post][blog] explaining how to use `t` to backup
your Twitter account.

[jphpsf]: https://github.com/jphpsf
[blog]: http://blog.jphpsf.com/2012/05/07/backing-up-your-twitter-account-with-t/

`t` was also mentioned on [an episode of the Ruby 5 podcast][ruby5].

[ruby5]: http://ruby5.envylabs.com/episodes/273-episode-269-may-4th-2012/stories/2400-t-command-line-power-tool-for-twitter

If you discuss `t` in a blog post or podcast, [let me know][email] and I'll
link it here.

[email]: mailto:sferik@gmail.com

## Relationship Terminology

There is some ambiguity in the terminology used to describe relationships on
Twitter. For example, some people use the term "friends" to mean everyone you
follow. In `t`, "friends" refers to just the subset of people who follow you
back (i.e., friendship is bidirectional). Here is the full table of terminology
used by `t`:

                               ___________________________________________________
                              |                         |                         |
                              |     YOU FOLLOW THEM     |  YOU DON'T FOLLOW THEM  |
     _________________________|_________________________|_________________________|_________________________
    |                         |                         |                         |                         |
    |     THEY FOLLOW YOU     |         friends         |        groupies         |        followers        |
    |_________________________|_________________________|_________________________|_________________________|
    |                         |                         |
    |  THEY DON'T FOLLOW YOU  |         leaders         |
    |_________________________|_________________________|
                              |                         |
                              |       followings        |
                              |_________________________|

## Screenshots
![Timeline](https://github.com/sferik/t/raw/master/screenshots/timeline.png)
![List](https://github.com/sferik/t/raw/master/screenshots/list.png)

## History
The [twitter gem][gem] previously contained a command-line interface, up until
version 0.5.0, when it was [removed][]. This project is offered as a sucessor
to that effort, however it is a clean room implementation that contains none of
the original code.

[removed]: https://github.com/jnunemaker/twitter/commit/dd2445e3e2c97f38b28a3f32ea902536b3897adf
![History](https://github.com/sferik/t/raw/master/screenshots/history.png)

## Contributing
In the spirit of [free software][free-sw], **everyone** is encouraged to help
improve this project.

[free-sw]: http://www.fsf.org/licensing/essays/free-sw.html

Here are some ways *you* can contribute:

* by using alpha, beta, and prerelease versions
* by reporting bugs
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (**no patch is too small**: fix typos, add comments, clean up
  inconsistent whitespace)
* by refactoring code
* by fixing [issues][]
* by reviewing patches
* [financially][pledgie]

[issues]: https://github.com/sferik/t/issues

## Submitting an Issue
We use the [GitHub issue tracker][issues] to track bugs and features. Before
submitting a bug report or feature request, check to make sure it hasn't
already been submitted. When submitting a bug report, please include a [Gist][]
that includes a stack trace and any details that may be necessary to reproduce
the bug, including your gem version, Ruby version, and operating system.
Ideally, a bug report should include a pull request with failing specs.

[gist]: https://gist.github.com/

## Submitting a Pull Request
1. [Fork the repository.][fork]
2. [Create a topic branch.][branch]
3. Add specs for your unimplemented feature or bug fix.
4. Run `bundle exec rake spec`. If your specs pass, return to step 3.
5. Implement your feature or bug fix.
6. Run `bundle exec rake spec`. If your specs fail, return to step 5.
7. Run `open coverage/index.html`. If your changes are not completely covered
   by your tests, return to step 3.
8. Add, commit, and push your changes.
9. [Submit a pull request.][pr]

[fork]: http://help.github.com/fork-a-repo/
[branch]: http://learn.github.com/p/branching.html
[pr]: http://help.github.com/send-pull-requests/

## Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.8.7
* Ruby 1.9.2
* Ruby 1.9.3

If something doesn't work on one of these Ruby versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Copyright
Copyright (c) 2011 Erik Michaels-Ober. See [LICENSE][] for details.  
Application icon by [@nvk][icon]. 
[license]: https://github.com/sferik/t/blob/master/LICENSE.md
[icon]: http://rodolfonovak.com
