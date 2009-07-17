#!/usr/bin/ruby1.9
##--------------------------------------------------
## bugfree (hopefully)
##--------------------------------------------------
Version = 'bf - *BugFree*, version 1.0.0'
Always_Dump = false
Breaks = true
USE_LESS = false
USE_BOLD = true

##--------------------------------------------------
## require shit

require 'pathname'
$: << MYDIR = File.dirname( Pathname( __FILE__ ).realpath )

for file in Dir.glob( "#{MYDIR}/code/**/*.rb" )
	require file [MYDIR.size + 1 ... -3]
end

##--------------------------------------------------
## do stuff, depending on command

cmd, arg1, arg2 = ARGV

case cmd
when 'init'
	Please.init!

when 'help', '--help', '-h', '-?'
	say.help( arg1 )

when 'version', '--version', '-v'
	say Version

when 'list'
	Please.list

when 'add'
	case ARGV.size
	when 1; say.help 'add'
	when 2; Please.add nil, ARGV[1]
	else Please.add Please.find_cat(ARGV[1]), sentence(2..-1)
	end
	
when 'del'
	Please.delete arg1

when 'close', 'open'
	if arg1
		Please.set_status(arg1, cmd == 'open')
	else
		Please.list(cmd)
	end
	
when 'clear'
	Please.clear

when 'mod'
	Please.modify arg1, sentence(2..-1)

when 'move'
	say.help('move') and cry("what to move?")  unless arg1
	cry "where to move it to?" unless arg2
	Please.move arg1, arg2

when 'rename'
	Please.rename_category(arg1, sentence(2..-1))
	
when 'reorder'
	Please.reorder_category(arg1, arg2)

when 'edit'
	Please.edit(arg1)

when 'refresh'
	Please.load "refresh"
	Please.dump
	ack

when /^(\d+)$/
	if arg1
		Please.modify( $1, sentence( 1..-1 ) )
	else
		Please.edit( $1 )
	end
	
when nil
	Please.find!
	if Please.found?
		Please.list
	else
		say.help
	end

else
	say.no_such_command(cmd)
	puts
	say.help

## don't bother to print a stack trace for UserErrors
end rescue UserError===$! ? say( $!.message ) : raise


