# Completion for Fish.
# Source from somewhere in your config.fish

function __fish_t_needs_command
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 1 -a $cmd[1] = 't' ]
    return 0
  end
  return 1
end

function __fish_t_using_command
  set cmd (commandline -opc)
  if [ (count $cmd) -gt 1 ]
    if [ $argv[1] = $cmd[2] ]
      return 0
    end
  end
  return 1
end

complete -c -t -f

# general options
complete -r -f -c t -n 'not __fish_t_needs_command' -s H -l host -d 'Twitter API server'
complete -r -f -c t -n 'not __fish_t_needs_command' -s C -l color -d 'Control how color is used in output' -a "auto never"
complete -f -c t -n 'not __fish_t_needs_command' -s U -l no-ssl -d 'Disable SSL'
complete -r -c t -n 'not __fish_t_needs_command' -s P -l profile -d 'Path to RC file'

complete -f -c t -n '__fish_t_needs_command' -a accounts -d 'List accounts'
complete -f -c t -n '__fish_t_using_command accounts' -s q -l quiet -d 'Be quiet'

complete -f -c t -n '__fish_t_needs_command' -a authorize -d "Allows an application to request user authorization"
complete -f -c t -n '__fish_t_using_command authorize' -s d -l display-uri -d "Display the authorization URL instead of attempting to open it."

complete -f -c t -n '__fish_t_needs_command' -a block -d "Block users."
complete -f -c t -n '__fish_t_using_command block' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."

complete -f -c t -n '__fish_t_needs_command' -a direct_messages -d "Returns the 20 most recent Direct Messages sent to you."
complete -f -c t -n '__fish_t_using_command direct_messages' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command direct_messages' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command direct_messages' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command direct_messages' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command direct_messages' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command direct_messages' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command direct_messages' -s d -l decode_uris -d "Output in CSV format."

complete -f -c t -n '__fish_t_needs_command' -a direct_messages_sent -d "Returns the 20 most recent Direct Messages you\'ve sent."
complete -f -c t -n '__fish_t_using_command direct_messages_sent' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command direct_messages_sent' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command direct_messages_sent' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command direct_messages_sent' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command direct_messages_sent' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command direct_messages_sent' -s r -l reverse -d "Reverse the order of the sort."

complete -f -c t -n '__fish_t_needs_command' -a dm -d "Sends that person a Direct Message."
complete -f -c t -n '__fish_t_using_command dm' -s i -l id -d "Specify user via ID instead of screen name."

complete -f -c t -n '__fish_t_needs_command' -a does_contain -d "Find out whether a list contains a user."
complete -f -c t -n '__fish_t_using_command does_contain' -s i -l id -d "Specify user via ID instead of screen name."

complete -f -c t -n '__fish_t_needs_command' -a does_follow -d "Find out whether one user follows another."
complete -f -c t -n '__fish_t_using_command does_follow' -s i -l id -d "Specify user via ID instead of screen name."

complete -f -c t -n '__fish_t_needs_command' -a favorite -d "Marks Tweets as favorites."
complete -f -c t -n '__fish_t_needs_command' -a favorites -d "Returns the 20 most recent Tweets you favorited."
complete -f -c t -n '__fish_t_using_command favorites' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command favorites' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command favorites' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command favorites' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command favorites' -s m -l max_id -d "Returns only the results with an ID less than the specified ID."
complete -f -c t -n '__fish_t_using_command favorites' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command favorites' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command favorites' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command favorites' -s s -l since_id -d "Returns only the results with an ID greater than the specified ID."

complete -f -c t -n '__fish_t_needs_command' -a follow -d "Allows you to start following users."
complete -f -c t -n '__fish_t_using_command follow' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."

complete -f -c t -n '__fish_t_needs_command' -a followings -d "Returns a list of the people you follow on Twitter."
complete -f -c t -n '__fish_t_using_command followings' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command followings' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command followings' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command followings' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command followings' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command followings' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command followings' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a followings_following -d "Displays your friends who follow the specified user."
complete -f -c t -n '__fish_t_using_command followings_following' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command followings_following' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."
complete -f -c t -n '__fish_t_using_command followings_following' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command followings_following' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command followings_following' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command followings_following' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command followings_following' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a followers -d "Returns a list of the people who follow you on Twitter."
complete -f -c t -n '__fish_t_using_command followers' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command followers' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command followers' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command followers' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command followers' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command followers' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command followers' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a friends -d "Returns the list of people who you follow and follow you back."
complete -f -c t -n '__fish_t_using_command friends' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command friends' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command friends' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command friends' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command friends' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command friends' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command friends' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a groupies -d "Returns the list of people who follow you but you don\'t follow back."
complete -f -c t -n '__fish_t_using_command groupies' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command groupies' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command groupies' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command groupies' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command groupies' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command groupies' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command groupies' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a intersection -d "Displays the intersection of users followed by the specified users."
complete -f -c t -n '__fish_t_using_command intersection' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command intersection' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."
complete -f -c t -n '__fish_t_using_command intersection' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command intersection' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command intersection' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command intersection' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command intersection' -s t -l type -d "Specify the type of intersection."
complete -f -c t -n '__fish_t_using_command intersection' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a leaders -d "Returns the list of people who you follow but don\'t follow you back."
complete -f -c t -n '__fish_t_using_command leaders' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command leaders' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command leaders' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command leaders' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command leaders' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command leaders' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command leaders' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a lists -d "Returns the lists created by a user."
complete -f -c t -n '__fish_t_using_command lists' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command lists' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command lists' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command lists' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command lists' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command lists' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command lists' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a matrix -d "Unfortunately, no one can be told what the Matrix is. You have to see it for yourself."

complete -f -c t -n '__fish_t_needs_command' -a mentions -d "Returns the 20 most recent Tweets mentioning you."
complete -f -c t -n '__fish_t_using_command mentions' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command mentions' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command mentions' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command mentions' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command mentions' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command mentions' -s r -l reverse -d "Reverse the order of the sort."

complete -f -c t -n '__fish_t_needs_command' -a mute -d "Mute users."
complete -f -c t -n '__fish_t_using_command mute' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."

complete -f -c t -n '__fish_t_needs_command' -a muted -d "Returns a list of the people you have muted on Twitter."
complete -f -c t -n '__fish_t_using_command muted' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command muted' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command muted' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command muted' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command muted' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command muted' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a open -d "Opens that user\'s profile in a web browser."
complete -f -c t -n '__fish_t_using_command open' -s d -l display-url -d "Display the requested URL instead of attempting to open it."
complete -f -c t -n '__fish_t_using_command open' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command open' -s s -l status -d "Specify input as a Twitter status ID instead of a screen name."

complete -f -c t -n '__fish_t_needs_command' -a reach -d "Shows the maximum number of people who may have seen the specified tweet in their timeline."

complete -f -c t -n '__fish_t_needs_command' -a reply -d "Post your Tweet as a reply directed at another person."
complete -f -c t -n '__fish_t_using_command reply' -s a -l all -d "Reply to all users mentioned in the Tweet."
complete -f -c t -n '__fish_t_using_command reply' -s l -l location -d "Add location information. If the optional \'latitude,longitude\' parameter is not supplied, looks up location by IP address."
complete -f -c t -n '__fish_t_using_command reply' -s f -l file -d "The path to an image to attach to your tweet."

complete -f -c t -n '__fish_t_needs_command' -a report_spam -d "Report users for spam."
complete -f -c t -n '__fish_t_using_command report_spam' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."

complete -f -c t -n '__fish_t_needs_command' -a retweet -d "Sends Tweets to your followers."

complete -f -c t -n '__fish_t_needs_command' -a retweets -d "Returns the 20 most recent Retweets by a user."
complete -f -c t -n '__fish_t_using_command retweets' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command retweets' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command retweets' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command retweets' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command retweets' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command retweets' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command retweets' -s r -l reverse -d "Reverse the order of the sort."

complete -f -c t -n '__fish_t_needs_command' -a retweets_of_me -d "Returns the 20 most recent Tweets of the authenticated user that have been retweeted by others."
complete -f -c t -n '__fish_t_using_command retweets_of_me' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command retweets_of_me' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command retweets_of_me' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command retweets_of_me' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command retweets_of_me' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command retweets_of_me' -s r -l reverse -d "Reverse the order of the sort."

complete -f -c t -n '__fish_t_needs_command' -a ruler -d "Prints a 140-character ruler"
complete -f -c t -n '__fish_t_using_command ruler' -s i -l indent -d "The number of spaces to print before the ruler."

complete -f -c t -n '__fish_t_needs_command' -a status -d "Retrieves detailed information about a Tweet."
complete -f -c t -n '__fish_t_using_command status' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command status' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command status' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command status' -s a -l relative_dates -d "Show relative dates."

complete -f -c t -n '__fish_t_needs_command' -a timeline -d "Returns the 20 most recent Tweets posted by a user."
complete -f -c t -n '__fish_t_using_command timeline' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command timeline' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command timeline' -s e -l exclude -d "Exclude certain types of Tweets from the results."
complete -f -c t -n '__fish_t_using_command timeline' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command timeline' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command timeline' -s m -l max_id -d "Returns only the results with an ID less than the specified ID."
complete -f -c t -n '__fish_t_using_command timeline' -s n -l number -d "Limit the number of results."
complete -f -c t -n '__fish_t_using_command timeline' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command timeline' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command timeline' -s s -l since_id -d "Returns only the results with an ID greater than the specified ID."

complete -f -c t -n '__fish_t_needs_command' -a trends -d "Returns the top 10 trending topics."
complete -f -c t -n '__fish_t_using_command trends' -s x -l exclude-hashtags -d "Remove all hashtags from the trends list."

complete -f -c t -n '__fish_t_needs_command' -a trend_locations -d "Returns the locations for which Twitter has trending topic information."
complete -f -c t -n '__fish_t_using_command trend_locations' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command trend_locations' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command trend_locations' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command trend_locations' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command trend_locations' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command trend_locations' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a unfollow -d "Allows you to stop following users."
complete -f -c t -n '__fish_t_using_command unfollow' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."

complete -f -c t -n '__fish_t_needs_command' -a update -d "Post a Tweet."
complete -f -c t -n '__fish_t_using_command direct_messages' -s l -l location -d "Add location information. If the optional \'latitude,longitude\' parameter is not supplied, looks up location by IP address."
complete -f -c t -n '__fish_t_using_command direct_messages' -s f -l file -d "The path to an image to attach to your tweet."

complete -f -c t -n '__fish_t_needs_command' -a users -d "Returns a list of users you specify."
complete -f -c t -n '__fish_t_using_command users' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command users' -s i -l id -d "Specify input as Twitter user IDs instead of screen names."
complete -f -c t -n '__fish_t_using_command users' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command users' -s a -l relative_dates -d "Show relative dates."
complete -f -c t -n '__fish_t_using_command users' -s r -l reverse -d "Reverse the order of the sort."
complete -f -c t -n '__fish_t_using_command users' -s s -l sort -d "Specify the order of the results."
complete -f -c t -n '__fish_t_using_command users' -s u -l unsorted -d "Output is not sorted."

complete -f -c t -n '__fish_t_needs_command' -a version -d "Show version."
complete -f -c t -n '__fish_t_needs_command' -a whois -d "Retrieves profile information for the user."
complete -f -c t -n '__fish_t_using_command whois' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command whois' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command whois' -s i -l id -d "Specify user via ID instead of screen name."
complete -f -c t -n '__fish_t_using_command whois' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command whois' -s a -l relative_dates -d "Show relative dates."

complete -f -c t -n '__fish_t_needs_command' -a whoami -d "Retrieves profile information for the authenticated user."
complete -f -c t -n '__fish_t_using_command whoami' -s c -l csv -d "Output in CSV format."
complete -f -c t -n '__fish_t_using_command whoami' -s d -l decode_uris -d "Decodes t.co URLs into their original form."
complete -f -c t -n '__fish_t_using_command whoami' -s l -l long -d "Output in long format."
complete -f -c t -n '__fish_t_using_command whoami' -s a -l relative_dates -d "Show relative dates."

complete -f -c t -n '__fish_t_needs_command' -a delete -d "Delete Tweets, Direct Messages, etc."
complete -f -c t -n '__fish_t_using_command delete' -a block
complete -f -c t -n '__fish_t_using_command delete' -a dm
complete -f -c t -n '__fish_t_using_command delete' -a favorite
complete -f -c t -n '__fish_t_using_command delete' -a list
complete -f -c t -n '__fish_t_using_command delete' -a mute
complete -f -c t -n '__fish_t_using_command delete' -a account
complete -f -c t -n '__fish_t_using_command delete' -a status
complete -f -c t -n '__fish_t_using_command delete' -a help

complete -f -c t -n '__fish_t_needs_command' -a list -d "Do various things with lists."
complete -f -c t -n '__fish_t_using_command list' -a add
complete -f -c t -n '__fish_t_using_command list' -a create
complete -f -c t -n '__fish_t_using_command list' -a information
complete -f -c t -n '__fish_t_using_command list' -a members
complete -f -c t -n '__fish_t_using_command list' -a remove
complete -f -c t -n '__fish_t_using_command list' -a timeline
complete -f -c t -n '__fish_t_using_command list' -a help

complete -f -c t -n '__fish_t_needs_command' -a search -d "Search through Tweets."
complete -f -c t -n '__fish_t_using_command search' -a all
complete -f -c t -n '__fish_t_using_command search' -a favorites
complete -f -c t -n '__fish_t_using_command search' -a list
complete -f -c t -n '__fish_t_using_command search' -a mentions
complete -f -c t -n '__fish_t_using_command search' -a retweets
complete -f -c t -n '__fish_t_using_command search' -a timeline
complete -f -c t -n '__fish_t_using_command search' -a users
complete -f -c t -n '__fish_t_using_command search' -a help

complete -f -c t -n '__fish_t_needs_command' -a set -d "Change various account settings."
complete -f -c t -n '__fish_t_using_command set' -a active
complete -f -c t -n '__fish_t_using_command set' -a bio
complete -f -c t -n '__fish_t_using_command set' -a language
complete -f -c t -n '__fish_t_using_command set' -a location
complete -f -c t -n '__fish_t_using_command set' -a name
complete -f -c t -n '__fish_t_using_command set' -a profile_background_image
complete -f -c t -n '__fish_t_using_command set' -a profile_image
complete -f -c t -n '__fish_t_using_command set' -a website
complete -f -c t -n '__fish_t_using_command set' -a help

complete -f -c t -n '__fish_t_needs_command' -a stream -d "Commands for streaming Tweets."
complete -f -c t -n '__fish_t_using_command stream' -a all
complete -f -c t -n '__fish_t_using_command stream' -a list
complete -f -c t -n '__fish_t_using_command stream' -a matrix
complete -f -c t -n '__fish_t_using_command stream' -a search
complete -f -c t -n '__fish_t_using_command stream' -a timeline
complete -f -c t -n '__fish_t_using_command stream' -a users
complete -f -c t -n '__fish_t_using_command stream' -a help

