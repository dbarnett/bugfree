#!/usr/bin/ruby1.9
##--------------------------------------------------
## bugfree (hopefully)
##--------------------------------------------------
Version = 'bf - *BugFree*, version 0.0.0'
Debug = true

##--------------------------------------------------
## require shit

require 'pathname'
$: << MYDIR = File.dirname(Pathname(__FILE__).realpath)

for file in Dir.glob "#{MYDIR}/code/**/*.rb"
	require file [MYDIR.size + 1 ... -3]
end

require 'design/chekbox'

##--------------------------------------------------
## do stuff, depending on command

cmd, arg1 = ARGV

case cmd
when 'init'
	Please.init!

when 'help', '--help', '-h', '-?'
	Say.help( arg1 )

when 'version', '--version', '-v'
	Say Version

when 'list'
	Please.list

when 'add'
	case ARGV.size
	when 1; Say.help 'add'
	when 2; Please.add nil, ARGV[1]
	else Please.add Please.find_cat(ARGV[1]), ARGV[2..-1].join( ' ' )
	end
	
when 'del'
	Please.delete ARGV[1].to_i
	
when 'clear'
	Please.clear

when 'mod'
	Please.modify arg1.to_i, ARGV[2..-1].join(' ')
	
when nil
	Please.find!
	if Please.found?
		Please.list
	else
		Say.help
	end

else
	Say.no_such_command(cmd)
	Say.help

end

