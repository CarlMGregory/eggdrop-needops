##
# Need Ops v1.0, for eggdrop version 1.5.4 or greater
#  Coded by:
#   guppy - Jeff Fisher <email: guppy@techmonkeys.org>
#   MC_8 - Carl M. Gregory <email: mc8@purehype.net>
##

##
# Script information
##
# First of all, if your reading this in an editor that does word wrapping such as 
# 'pico', please disable it -- if you save it as wrapped it may mess the script up.
# For pico, you can do this without word wrapping by typing 'pico -w needops.tcl'.
#
# This script is used for bots to request ops from one another via the botnet, which
# is a spin-off of GetOps v2.6.  I, MC_8, rewrote 2.6 in hopes of continue'n the 
# getops tradition of a quality botnet opping script, but discovered that the 
# architecture of getops was just too restrictive.  This script is every bit as
# secure as was getops but better, such as 'reverse op requesting' proposed by guppy.
#
# As was getops -- this script is not owned by anyone and is open source to be
# republished.
#
# If your replacing GetOps with this script, you may get some errors such as:
#   <Bot> [00:01] Tcl error in script for 'need-op':
#   <Bot> [00:01] invalid command name "gain_entrance"
# To fix such problems, you will need to perform this dcc command:
#   .chanset #channel need-op ""
# Do this for every channel.  Other need-'s that will give errors are need-key, 
# need-limit and need-invite.
#
# In addition, this script can work with getops.tcl and botnetop.tcl to obtain ops
# over the botnet -- however it is recomended you use needops.tcl on all bots
# whenever possible.
#
# For this to work, you will need:
#   o  Bots must be linked together (see doc/BOTNET for linking instructions).
#   o  Every bot that is to utalize this should have this script loaded.
#   o  Ensure the bots that are to be opped have the 'o' (op) flag either globally or 
#      channel specific.
#
# The security of this relies on:
#   o  Bots have to be linked (which requires a password).
#   o  Must have the 'o' (op) flag, either globally or channel specific.
#   o  Must match the hostmask that is stored in each bots userfile.
#
# Previous coders of GetOps v1.0-v2.6:
#   o  aerosoul
#   o  beldin
#   o  Cron - Arkadiusz Miskiewicz <email: misiek@zsz2.starachowice.pl>
#   o  DarkDruid
#   o  dtM
#   o  Ernst
#   o  fantomas
#   o  Flash - Julien Wajsberg <email: flash@minet.net>
#   o  poptix
#   o  The_O
##

##
# History - (added by - found by - information)
##
# v1.0 [04.03.02]
#  MC_8 - guppy - Recoded GetOps totally, changed the name to needops because it's 
#                 not backwards compatable.  Because it is recoded totally, I will 
#                 not include the version history (witch was about 2 pages of update 
#                 to getops before I recoded it into needops) of what I changed from 
#                 getops v2.6 to needops v1.0.
##

##
# Configuration
##

# What log level do you want the script's output to be posted on?  Normal is "o" for 
# other.  I like to set mine to "d" (debug) since I have a large botnet and don't 
# want to see all 'requesting' output.  See '.help console'.
set nops(show_console) "o"

# [0=no/1=yes] Do you want the script show botnet request of unauthorized bots or for 
# invalid/unsupported channels?
set nops(show_unauth) 1

# [0=no/1=yes] Do you want to process 'GetOps.tcl' requests, so other bots using 
# GetOps can function properly with this script?  I strongly recomend you set this to
# 0 and ensure all the bot's run needops.tcl  -- getops doesn't support reverse 
# botnet opping and can be a pain in the ass on such irc servers such as EfNet.
set nops(getops) 0

# [0=no/1=yes] Do you want to process 'botnetop.tcl' requests, so other bots using 
# botnetop can function properly with this script?
set nops(botnetop) 0

# [0=no/1=yes] Upon the bot connecting to an irc server, do you want it to auto 
# update it's own host?  This is a wonderfull one of guppy's ideas, it will ensure 
# the bot's host is always current.  Due to security reasons, if this is set, the bot 
# will only update it's own userfile of it's host -- now if other bot's are sharing 
# then the share module will cause the shared bots to update too, that's is safe and 
# secure.
set nops(auto_update_host) 1


##
# Done with configuration, do not edit past here unless you know TCL.
##

set nops(loaded)     0
set nops(script)     "Need Ops"
set nops(version)    "v1.0"
set nops(numversion) 001000000000

if {$numversion < "1050400"} {
 putlog "$nops(script) $nops(version) will only work on eggdrop 1.5.4 or greater."
 putlog "$nops(script) $nops(version)  will not work with eggdrop $version."
 putlog "$nops(script) $nops(version)  not loaded."
 return 1
}

bind join - * nops:join
proc nops:join {nick uhost hand chan} {
 if {[isbotnick $nick]} {
  global nops; set nops([list :: gonnaop [string tolower $chan]]) ""
 } elseif {([botisop $chan]) &&
           ([nops:is_valid_bot $nick $uhost $hand $chan] == "1")} {
  nops:ask_if_want_op all $nick $hand $chan
 }
}

bind mode - "% -o" nops:deop
proc nops:deop {nick uhost hand chan mc vict} {
 set vuhost [getchanhost $vict $chan]; set vhand [nick2hand $vict $chan]
 if {(![botisop $chan]) || ($nick == $vict) ||
     ([nops:is_valid_bot $vict $vuhost $vhand $chan] != "1")} {return 0}
 nops:ask_if_want_op all $vict $vhand $chan
}

bind mode - "% +o" nops:op
proc nops:op {nick uhost hand chan mc vict} {
 global nops botname botnick
 if {![info exists nops([list :: gonnaop [string tolower $chan]])]} {
  set nops([list :: gonnaop [string tolower $chan]]) ""
 }
 set vuhost [getchanhost $vict $chan]; set vhand [nick2hand $vict $chan]
 if {([botisop $chan]) ||
     ([nops:is_valid_bot $vict $vuhost $vhand $chan] != "1") ||
     ($nops([list :: gonnaop [string tolower $chan]]) != "")} {return 0}
 putbot $vhand [list nops 001 $chan $botname]
 if {$nops(botnetop)} {putbot $vhand [list reqops $chan $botnick]}
 if {$nops(getops)} {putbot $vhand [list gop op $chan $botnick]}
 if {$vict == $vhand} {set x ""} else {set x " (irc nick: $vict)"}
 nops:putlog 1 "Asking $vhand$x for ops on $chan."
}

bind bot - gop nops:bot:gop
proc nops:bot:gop {bot command arg} {
 global nops
 if {!$nops(getops)} {return 0}
 set cmd [lindex [split $arg] 0]
 set chan [lindex [split $arg] 1]
 set nfo [lindex [split $arg] 2]
 if {(![validchan $chan]) ||
     ([lsearch -exact [string tolower [channel info $chan]] +inactive] != "-1")} {
  nops:putlog 0 "Invalid channel referance, $chan, from $bot."
  return 0
 }
 set uhost [getchanhost $nfo $chan]
 switch -- $cmd {
  op {nops:bot $bot gop [list 200 $chan $nfo!$uhost]}
  limit {nops:bot $bot gop [list 002 $chan $nfo!$uhost]}
  invite {nops:bot $bot gop [list 003 $chan $nfo!$uhost]}
  unban {nops:bot $bot gop [list 004 $chan $nfo]}
  key {nops:bot $bot gop [list 005 $chan $nfo!$uhost]}
  takekey {nops:bot $bot gop [list 240 $chan $nfo]}
 }
}

bind bot - gop_resp nops:bot:gop_resp
proc nops:bot:gop_resp {bot command arg} {
 global nops
 if {$nops(getops)} {nops:putlog 1 "GetOps response from $bot: $arg"}
}

bind bot - doyawantops nops:bot:botnetop
bind bot - yesiwantops nops:bot:botnetop
bind bot - reqops nops:bot:botnetop
bind bot - wantkey nops:bot:botnetop
bind bot - wantinvite nops:bot:botnetop
bind bot - wantlimit nops:bot:botnetop
bind bot - wantunban nops:bot:botnetop
proc nops:bot:botnetop {bot command arg} {
 global nops
 if {!$nops(botnetop)} {return 0}
 set chan [lindex [split $arg] 0]
 set nick [lindex [split $arg] 1]
 if {(![validchan $chan]) ||
     ([lsearch -exact [string tolower [channel info $chan]] +inactive] != "-1")} {
  nops:putlog 0 "Invalid channel referance, $chan, from $bot."
  return 0
 }
 set uhost [getchanhost $nick $chan]
 switch -- $command {
  doyawantops {nops:bot $bot botnetop [list 100 $chan]}
  yesiwantops {nops:bot $bot botnetop [list 200 $chan $nick![lindex [split $arg] 2]]}
  reqops {nops:bot $bot botnetop [list 001 $chan $nick!$uhost]}
  wantkey {nops:bot $bot botnetop [list 005 $chan $nick!$uhost]}
  wantinvite {nops:bot $bot botnetop [list 003 $chan $nick!$uhost]}
  wantlimit {nops:bot $bot botnetop [list 002 $chan $nick!$uhost]}
  wantunban {nops:bot $bot botnetop [list 004 $chan $nick!$uhost]}
 }
}

bind bot - nops nops:bot
proc nops:bot {bot command arg} {
 global nops botname botnick
 set rfc [lindex $arg 0]
 set chan [lindex $arg 1]
 if {$rfc == "240"} {set key [lindex $arg 2]} \
 elseif {$rfc == "205"} {set finduser [lindex $arg 2]} \
 else {
  set nick [lindex [split [lindex $arg 2] !] 0]
  set uhost [join [lrange [split [lindex $arg 2] !] 1 end] !]
 }
 if {![info exists nops([list :: gonnaop [string tolower $chan]])]} {
  set nops([list :: gonnaop [string tolower $chan]]) ""
 }
 set array_name [list :ignore: $bot $rfc [string tolower $chan]]
 if {[info exists nops($array_name)]} {return 0}
 set nops($array_name) [clock seconds]
 utimer 5 [list unset nops($array_name)]
 if {(![validchan $chan]) ||
     ([lsearch -exact [string tolower [channel info $chan]] +inactive] != "-1")} {
#  nops:putlog 0 "Invalid channel referance, $chan, from $bot."
  return 0
 }
 switch -- $rfc {
  001 {
   #need someone to ask if needs ops.
   if {$bot == $nick} {set x "$bot"} else {set x "$bot (irc nick: $nick)"}
   set msg01 "Ignored request from $x for ops in $chan"
   set msg02 "Ignored unauthorized request from $x for ops in $chan"
   if {![onchan $nick $chan]} {
    nops:putlog 1 "$msg01, user not in channel."
    return 0
   }
   if {[isop $nick $chan]} {
    nops:putlog 1 "$msg01, user already opped."
    return 0
   }; set return 1
   switch -- [nops:is_valid_bot $nick $uhost $bot $chan] {
     1 {set return 0}
    -1 {}
    -2 {nops:putlog 0 "$msg02. (unknown bot)"}
    -3 {nops:putlog 0 "$msg02. (not a bot)"}
    -4 {
     if {$command == "nops"} {putbot $bot [list nops 203 $chan]}
     nops:putlog 0 "$msg02. (no op flag)"
    }
    -5 {
     if {$command == "nops"} {putbot $bot [list nops 204 $chan]}
     nops:putlog 0 "$msg02. (has deop flag)"
    }
    -6 {}
    -7 {
     if {([set finduser [finduser $nick!$uhost]] == "*") || ($finduser == "")} {
      set y "invalid ident $nick!$uhost"
      set z ""
     } else {set y "ident $nick!$uhost matches $finduser"; set z $finduser}
     if {$command == "nops"} {putbot $bot [list nops 205 $chan $z]}
     nops:putlog 1 "$msg01, $y."
    }
   }; if {$return} {return 0}
   if {![botisop $chan]} {
    nops:putlog 1 "$msg01, I'm not opped."
    return 0
   }; nops:ask_if_want_op $command $nick $bot $chan
  }
  002 {
   #need someone to ask if needs limit.
   if {$bot == $nick} {set x "$bot"} else {set x "$bot (irc nick: $nick)"}
   set msg00 "due to limit restriction"
   set msg01 "Ignored request from $x for invite to $chan $msg00"
   set msg02 "Ignored unauthorized request from $x for invite to $chan $msg00"
   set msg03 "Rejected for $chan,"

   # If your reading this, you may be asking why I'm chopping all this stuff up
   # like I am, well... guppy told me to :)  Trying to make the script fit within
   # an editor with only 85 characters accross (as so it doesn't word wrap and
   # screw up the script for newbies).

   if {[onchan $nick $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 your already there."
    }
    nops:putlog 1 "$msg01, user already there."
    return 0
   }
   set return 1
   switch -- [nops:is_valid_bot $nick $uhost $bot $chan] {
     1 {set return 0}
    -1 {}
    -2 {nops:putlog 0 "$msg02. (unknown bot)"}
    -3 {nops:putlog 0 "$msg02. (not a bot)"}
    -4 {
     if {$command == "nops"} {putbot $bot [list nops 203 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you don't have the op flag."
     }
     nops:putlog 0 "$msg02. (no op flag)"
    }
    -5 {
     if {$command == "nops"} {putbot $bot [list nops 204 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you have the deop flag."
     }
     nops:putlog 0 "$msg02. (has deop flag)"
    }
    -6 {}
    -7 {
     if {([set finduser [finduser $nick!$uhost]] == "*") || ($finduser == "")} {
      set y "invalid ident $nick!$uhost"
      set z ""
     } else {set y "ident $nick!$uhost matches $finduser"; set z $finduser}
     if {$command == "nops"} {putbot $bot [list nops 205 $chan $z]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 $y."
     }
     nops:putlog 1 "$msg01, $y."
    }
   }; if {$return} {return 0}
   if {![botisop $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 I'm not opped."
    }
    nops:putlog 1 "$msg01, I'm not opped."
    return 0
   }
   nops:putlog 1 "$bot requested an invite to $chan$x $msg00, inviting."
   putserv "INVITE $nick $chan"
  }
  003 {
   #need someone to ask if needs invite.
   if {$bot == $nick} {set x "$bot"} else {set x "$bot (irc nick: $nick)"}
   set msg01 "Ignored request from $x for invite to $chan"
   set msg02 "Ignored unauthorized request from $x for invite to $chan"
   set msg03 "Rejected for $chan,"

   if {[onchan $nick $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 your already there."
    }
    nops:putlog 1 "$msg01, user already there."
    return 0
   }
   set return 1
   switch -- [nops:is_valid_bot $nick $uhost $bot $chan] {
     1 {set return 0}
    -1 {}
    -2 {nops:putlog 0 "$msg02. (unknown bot)"}
    -3 {nops:putlog 0 "$msg02. (not a bot)"}
    -4 {
     if {$command == "nops"} {putbot $bot [list nops 203 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you don't have the op flag."
     }
     nops:putlog 0 "$msg02. (no op flag)"
    }
    -5 {
     if {$command == "nops"} {putbot $bot [list nops 204 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you have the deop flag."
     }
     nops:putlog 0 "$msg02. (has deop flag)"
    }
    -6 {}
    -7 {
     if {([set finduser [finduser $nick!$uhost]] == "*") || ($finduser == "")} {
      set y "invalid ident $nick!$uhost"
      set z ""
     } else {set y "ident $nick!$uhost matches $finduser"; set z $finduser}
     if {$command == "nops"} {putbot $bot [list nops 205 $chan $z]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 $y."
     }
     nops:putlog 1 "$msg01, $y."
    }
   }; if {$return} {return 0}
   if {![botisop $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 I'm not opped."
    }
    nops:putlog 1 "$msg01, I'm not opped."
    return 0
   }
   nops:putlog 1 "$x requested an invite to $chan, inviting."
   putserv "INVITE $nick $chan"
  }
  004 {
   #need someone to ask if needs unban.
   if {$bot == $nick} {set x "$bot"} else {set x "$bot (irc nick: $nick)"}
   set msg00 "due to ban restriction"
   set msg01 "Ignored request from $x for invite to $chan $msg00"
   set msg02 "Ignored unauthorized request from $x for invite to $chan $msg00"
   set msg03 "Rejected for $chan,"

   if {[onchan $nick $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 your already there."
    }
    nops:putlog 1 "$msg01, user already there."
    return 0
   }
   set return 1
   switch -- [nops:is_valid_bot $nick $uhost $bot $chan] {
     1 {set return 0}
    -1 {}
    -2 {nops:putlog 0 "$msg02. (unknown bot)"}
    -3 {nops:putlog 0 "$msg02. (not a bot)"}
    -4 {
     if {$command == "nops"} {putbot $bot [list nops 203 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you don't have the op flag."
     }
     nops:putlog 0 "$msg02. (no op flag)"
    }
    -5 {
     if {$command == "nops"} {putbot $bot [list nops 204 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you have the deop flag."
     }
     nops:putlog 0 "$msg02. (has deop flag)"
    }
    -6 {}
    -7 {
     if {([set finduser [finduser $nick!$uhost]] == "*") || ($finduser == "")} {
      set y "invalid ident $nick!$uhost"
      set z ""
     } else {set y "ident $nick!$uhost matches $finduser"; set z $finduser}
     if {$command == "nops"} {putbot $bot [list nops 205 $chan $z]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 $y."
     }
     nops:putlog 1 "$msg01, $y."
    }
   }; if {$return} {return 0}
   if {![botisop $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 I'm not opped."
    }
    nops:putlog 1 "$msg01, I'm not opped."
    return 0
   }
   nops:putlog 1 "$x requested an invite to $chan $msg00, inviting."
   putserv "INVITE $nick $chan"
  }
  005 {
   #need someone to ask if needs key.
   if {$bot == $nick} {set x "$bot"} else {set x "$bot (irc nick: $nick)"}
   set msg01 "Ignored request from $x for key to $chan"
   set msg02 "Ignored unauthorized request from $x for key to $chan"
   set msg03 "Rejected for $chan,"

   if {[onchan $nick $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 your already there."
    }
    nops:putlog 1 "$msg01, user already there."
    return 0
   }
   set return 1
   switch -- [nops:is_valid_bot $nick $uhost $bot $chan] {
     1 {set return 0}
    -1 {}
    -2 {nops:putlog 0 "$msg02. (unknown bot)"}
    -3 {nops:putlog 0 "$msg02. (not a bot)"}
    -4 {
     if {$command == "nops"} {putbot $bot [list nops 203 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you don't have the op flag."
     } else
     nops:putlog 0 "$msg02. (no op flag)"
    }
    -5 {
     if {$command == "nops"} {putbot $bot [list nops 204 $chan]} \
     elseif {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you have the deop flag."
     }
     nops:putlog 0 "$msg02. (has deop flag)"
    }
    -6 {}
    -7 {
     if {([set finduser [finduser $nick!$uhost]] == "*") || ($finduser == "")} {
      set y "invalid ident $nick!$uhost"
      set z ""
     } else {set y "ident $nick!$uhost matches $finduser"; set z $finduser}
    if {$command == "nops"} {putbot $bot [list nops 205 $chan $z]} \
    elseif {$command == "gop"} {putbot $bot "gop_resp $nops(script):  $msg03 $y."}
     nops:putlog 1 "$msg01, $y."
    }
   }; if {$return} {return 0}
   if {![botisop $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 I'm not opped."
    }
    nops:putlog 1 "$msg01, I'm not opped."
    return 0
   }
   set key [lindex [split [getchanmode $chan]] 1]
   if {$command == "gop"} {putbot $bot "gop takekey $chan $key"} \
   elseif {$command == "nops"} {putbot $bot [list nops 240 $chan $key]} \
   elseif {$command == "botnetop"} {putbot $bot "thekey $chan $key"}
   nops:putlog 1 "$x requested the key for $chan, sending."
  }
  100 {
   #asked if want ops.
   set msg01 "$bot asked if I need ops in $chan"

   if {[botisop $chan]} {
    if {$command == "nops"} {putbot $bot [list nops 201 $chan]}
    nops:putlog 1 "$msg01.  I don't, already opped."
   } elseif {[set gonnaop $nops([list :: gonnaop [string tolower $chan]])] != ""} {
    if {$command == "nops"} {putbot $bot [list nops 202 $chan $botname]}
    nops:putlog 1 "$msg01.  I don't, awaiting $gonnaop to op me."
   } else {
    if {$command == "botnetop"} {
     set temp(uhost) [join [lrange [split $botname !] 1 end] !]
     regexp -- {^~?(.*)$} $temp(uhost) dummy temp(uhost)
     putbot $bot [list yesiwantops $chan $botnick $temp(uhost)]
    } elseif {$command == "nops"} {
     putbot $bot [list nops 200 $chan $botname]
    }
    nops:putlog 1 "$msg01.  I do, having him/her op me."
    set nops([list :: gonnaop [string tolower $chan]]) $bot
    utimer 10 [list set nops([list :: gonnaop [string tolower $chan]]) ""]
   }
  }
  101 {
   #reply to reply from wanting ops being yes, cannot op now -- isn't opped.
   if {$nops([list :: gonnaop [string tolower $chan]]) != $bot} {return 0}
   nops:putlog 1 "$bot was going to op me on $chan, but he lost ops himself."
   set nops([list :: gonnaop [string tolower $chan]]) ""
   while {1} {
    set utimers [utimers]
    set lutimers [string tolower $utimers]
    set array_name [list :: gonnaop [string tolower $chan]]
    set lfilt [string tolower [nops:filt [list set nops($array_name) ""]]]
    set index [lsearch -glob $lutimers *$lfilt*]
    if {$index == "-1"} {break}
    killutimer [lindex [lindex $utimers $index] 2]
   }
  }
  200 {
   #replied to want ops, yes.
   if {$nick == $bot} {set x "$bot"} else {set x "$bot (irc nick: $nick)"}
   set msg01 "Ignored request from $x for op in $chan"
   set msg02 "Ignored unauthorized request from $x for op in $chan"
   set msg03 "Rejected for $chan,"

   if {![onchan $nick $chan]} {
    nops:putlog 1 "$msg01, user not in channel."
    return 0
   }
   if {[isop $nick $chan]} {
    nops:putlog 1 "$msg01, user already opped."
    return 0
   }; set return 1
   switch -- [nops:is_valid_bot $nick $uhost $bot $chan] {
     1 {set return 0}
    -1 {}
    -2 {nops:putlog 0 "$msg02. (unknown bot)"}
    -3 {nops:putlog 0 "$msg02. (not a bot)"}
    -4 {
     if {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you don't have the op flag."
     } elseif {$command == "nops"} {
      putbot $bot [list nops 203 $chan]
     }
     nops:putlog 0 "$msg02. (no op flag)"
    }
    -5 {
     if {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 you have the deop flag."
     } elseif {$command == "nops"} {
      putbot $bot [list nops 204 $chan]
     }
     nops:putlog 0 "$msg02. (has deop flag)"
    }
    -6 {}
    -7 {
     if {([set finduser [finduser $nick!$uhost]] == "*") || ($finduser == "")} {
      set y "invalid ident $nick!$uhost"
      set z ""
     } else {set y "ident $nick!$uhost matches $finduser"; set z $finduser}
     if {$command == "gop"} {
      putbot $bot "gop_resp $nops(script):  $msg03 $y."
     } elseif {$command == "nops"} {
      putbot $bot [list nops 205 $chan $z]
     }
     nops:putlog 1 "$msg01, $y."
    }
   }; if {$return} {return 0}
   if {![botisop $chan]} {
    if {$command == "gop"} {
     putbot $bot "gop_resp $nops(script):  $msg03 I'm not opped."
    } elseif {$command == "nops"} {
     putbot $bot [list nops 101 $chan]
    }
    nops:putlog 1 "$x wanted ops in $chan, but I'm not opped."
   } else {
    nops:putlog 1 "Opping $x on $chan."
    pushmode $chan +o $nick
   }
  }
  201 {
   #replied to want ops, no -- already opped.
   nops:putlog 1 "$bot refused ops for $chan, someone else already opped him."
  }
  202 {
   #replied to want ops, no -- waiting for someone else to op.
   if {(![botisop $chan]) || ([nops:is_valid_bot $nick $uhost $bot $chan] != "1")} {
    return 0
   }; utimer 10 [list nops:ask_if_want_op $command $nick $bot $chan]
   nops:putlog 1 "$bot refused ops for $chan, someone else is going to op him."
  }
  203 {
   #reply, no op flag
   nops:putlog 1 "$bot says I don't have the op flag for $chan (nor globally)."
  }
  204 {
   #reply, has deop flag
   nops:putlog 1 "$bot says I have the deop flag for $chan (or globally)."
  }
  205 {
   #reply, invalid ident
   if {$finduser != ""} {set finduser ", mine matches $finduser"}
   nops:putlog 1 "$bot states I have an invalid ident$finduser."
  }
  240 {
   #sent key.
   if {[botonchan $chan]} {return 0}
   nops:putlog 1 "$bot gave me the key to $chan ($key), joinning."
   putserv "JOIN $chan $key"
  }
 }
}

bind need - * nops:need
proc nops:need {chan type} {
 global botname nops botnick
 if {![info exists nops([list :: gonnaop [string tolower $chan]])]} {
  set nops([list :: gonnaop [string tolower $chan]]) ""
 }
 nops:auto_update_self_host
 switch -- $type {
  op {
   if {$nops([list :: gonnaop [string tolower $chan]]) == ""} {
    if {![nops:hasops $chan]} {
     nops:putlog 1 "No ops in $chan, cannot broadcast for ops."
    } elseif {![llength [set valid_bots [nops:valid_bots $chan $type]]]} {
     nops:putlog 1 "No valid bot's on the botnet, cannot broadcast for ops on $chan."
    } else {
     foreach bot $valid_bots {
      putbot $bot [list nops 001 $chan $botname]
      if {$nops(botnetop)} {putbot $bot [list reqops $chan $botnick]}
      if {$nops(getops)} {putbot $bot [list gop op $chan $botnick]}
     }; nops:putlog 1 "Asking for ops on $chan from [join $valid_bots ", "]."
    }
   }
  }
  limit {
   set msg01 "for invite to $chan due to limit restriction"
   if {![llength [set valid_bots [nops:valid_bots $chan $type]]]} {
    nops:putlog 1 "No valid bot's on the botnet, cannot broadcast $msg01."
   } else {
    foreach bot $valid_bots {
     putbot $bot [list nops 002 $chan $botname]
     if {$nops(botnetop)} {putbot $bot [list wantlimit $chan $botnick]}
     if {$nops(getops)} {putbot $bot [list gop limit $chan $botnick]}
    }; nops:putlog 1 "Asking $msg01 from [join $valid_bots ", "]."
   }
  }
  invite {
   if {![llength [set valid_bots [nops:valid_bots $chan $type]]]} {
   nops:putlog 1 "No valid bots on the botnet, cannot broadcast for invite to $chan."
   } else {
    foreach bot $valid_bots {
     putbot $bot [list nops 003 $chan $botname]
     if {$nops(botnetop)} {putbot $bot [list wantinvite $chan $botnick]}
     if {$nops(getops)} {putbot $bot [list gop invite $chan $botnick]}
    }; nops:putlog 1 "Asking for invite to $chan from [join $valid_bots ", "]."
   }
  }
  unban {
   set msg01 "for invite to $chan due to ban restriction"
   if {![llength [set valid_bots [nops:valid_bots $chan $type]]]} {
    nops:putlog 1 "No valid bots on the botnet, cannot broadcast $msg01."
   } else {
    foreach bot $valid_bots {
     putbot $bot [list nops 004 $chan $botname]
     if {$nops(botnetop)} {putbot $bot [list wantunban $chan $botnick $botname]}
     if {$nops(getops)} {putbot $bot [list gop unban $chan $botname]}
    }; nops:putlog 1 "Asking $msg01 from [join $valid_bots ", "]."
   }
  }
  key {
   if {![llength [set valid_bots [nops:valid_bots $chan $type]]]} {
    nops:putlog 1 "No valid bots on the botnet, cannot broadcast for key to $chan."
   } else {
    foreach bot $valid_bots {
     putbot $bot [list nops 005 $chan $botname]
     if {$nops(botnetop)} {putbot $bot [list wantkey $chan $botnick]}
     if {$nops(getops)} {putbot $bot [list gop key $chan $botnick]}
    }; nops:putlog 1 "Asking for key to $chan from [join $valid_bots ", "]."
   }
  }
 }
}

proc nops:ask_if_want_op {command nick hand chan} {
 global nops botnick
 while {1} {
  set utimers [utimers]
  set lutimers [string tolower $utimers]
  set filt [nops:filt [list nops:ask_if_want_op $command $nick $hand $chan]]
  set lfilt [string tolower $filt]
  set index [lsearch -glob $lutimers *$lfilt*]
  if {$index == "-1"} {break}
  killutimer [lindex [lindex $utimers $index] 2]
 }
 if {[isop $nick $chan]} {return 0}
 if {$hand == $nick} {set x ""} else {set x " (irc nick: $nick)"}
 nops:putlog 1 "Asking $hand$x if he wants ops in $chan."
 if {[regexp -- {^(all|nops)$} $command]} {putbot $hand [list nops 100 $chan]}
 if {[regexp -- {^(all|botnetop)$} $command] && $nops(botnetop)} {
  putbot $hand [list doyawantops $chan $botnick]
 }
 if {[regexp -- {^(all|gop)$} $command] && $nops(getops)} {}
}

proc nops:putlog {auth arg} {
 global nops
 if {!$auth && !$nops(show_unauth)} {return 0}
 putloglev $nops(show_console) * "$nops(script):  $arg"
}

proc nops:hasops {chan} {
 foreach user [chanlist $chan] {if {[isop $user $chan]} {return 1}}; return 0
}

proc nops:filt {text} {
 regsub -all -- {([\\\{\}\[\]\"])} $text {\\\1} text; return $text
}

proc nops:is_valid_bot {nick uhost hand chan} {
 global nops
 if {[isbotnick $nick]} {return -1}
 if {($hand == "*") || ($hand == "")} {return -2}
 if {![matchattr $hand b|]} {return -3}
 if {![matchattr $hand o|o $chan]} {return -4}
 if {[matchattr $hand d|d $chan]} {return -5}
 if {![islinked $hand]} {return -6}
 if {[string tolower [finduser $nick!$uhost]] != [string tolower $hand]} {return -7}
 return 1
}

proc nops:valid_bots {chan type} {
 set return ""
 foreach bot [bots] {
  if {![matchattr $bot b|] || ![matchattr $bot o|o $chan] ||
      [matchattr $bot d|d $chan]} {continue}
  if {$type == "op"} {
   set nick [hand2nick $bot $chan]
   if {![isop $nick $chan]} {continue}
   set uhost [getchanhost $nick $chan]
   if {[string tolower [finduser $nick!$uhost]] != [string tolower $bot]} {continue}
  }; lappend return $bot
 }; return $return
}

proc nops:auto_update_self_host {} {
 global nops botname botnet-nick server strict-host
 if {!$nops(auto_update_host) || ![validuser ${botnet-nick}] || ($server == "") || 
     [isbotnick $botname] || (([finduser $botname] != "*") &&
     ([llength [getuser ${botnet-nick} HOSTS]] == "1"))} {return 0}
 set hostname $botname
 if {!${strict-host}} {
  set nick [lindex [split $hostname !] 0]
  set uhost [join [lrange [split $hostname !] 1 end] !]
  regexp -- {^~?(.*)$} $uhost dummy uhost
  set hostname $nick!$uhost
 }
 setuser ${botnet-nick} HOSTS
 setuser ${botnet-nick} HOSTS $hostname
}

set nops(loaded) 1

putlog "$nops(script) $nops(version) loaded."
