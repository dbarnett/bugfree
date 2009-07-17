#!/usr/bin/ruby1.9
##--------------------------------------------------
## bugfree (hopefully)
##--------------------------------------------------
Version = 'bf - *BugFree*, version 1.0.0'

##--------------------------------------------------
## initialize constants and globals
Always_Dump = false
Breaks = true
USE_LESS = false
USE_BOLD = true
COLORFUL = true
$errors = 0

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

when 'list', 'all'
	Please.list

when 'add', '+'
	case ARGV.size
	when 1; say.help 'add'
	when 2; Please.add nil, ARGV[1]
	else Please.add Please.find_cat(ARGV[1]), sentence(2..-1)
	end
	
when 'del', '-'
	cry "what to delete?" unless arg1
	Please.delete arg1, arg2

when 'close', 'open'
	if arg1
		Please.set_status(arg1, cmd == 'open')
	else
		Please.list(cmd)
	end
	
when 'clear'
	Please.clear

when 'mod'
	cry "what to modify?" unless arg1
	Please.modify arg1, sentence(2..-1)

when 'move'
	say.help('move') and cry("what to move?")  unless arg1
	cry "where to move it to?" unless arg2
	Please.move arg1, arg2

when 'rename'
	say.help('rename') and cry("which category to rename?")  unless arg1
	cry "what to rename it to?" unless arg2
	Please.rename_category(arg1, sentence(2..-1))
	
when 'reorder'
	say.help('reorder') and cry("which category to reorder?")  unless arg1
	cry "what to reorder it to?" unless arg2
	Please.reorder_category(arg1, arg2)

when 'edit'
	if arg1
		Please.edit arg1
	else
		Please.edit_all
	end

when 'copy'
	say.help('copy') and cry("what to copy?")  unless arg1
	cry "where to copy it to?"  unless arg2
	Please.copy( arg1, arg2 )


when 'refresh'
	Please.load "refresh"
	Please.dump
	ack

when 'less'
	Please.list(arg1, true)

when 'sort'
	Please.sort(arg1, arg2 == 'rev')

when /^(\d+)$/
	if arg1
		Please.modify( $1, sentence( 1..-1 ) )
	else
		Please.edit( $1 )
	end
	
when nil
	begin
		Please.find!
		Please.list('open')
	rescue NotFound
		say.help
	end

else
	say.no_such_command(cmd)
	puts
	say.help

## don't bother to print a stack trace for UserErrors,
## since users are usually too stupid anyway to make use of them.
end rescue UserError===$! ? say( $!.message ) : raise


