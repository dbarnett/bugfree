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
$errors = []

##--------------------------------------------------
## require shit

require 'pathname'
require 'abbrev'

$:<< MYDIR=File.dirname(Pathname(__FILE__).realpath)
for file in Dir.glob( "#{MYDIR}/code/**/*.rb" )
	require file [MYDIR.size + 1 .. -4]
end

##--------------------------------------------------
## compile a list of unambiguous commands

commands = %w[
	add all
	close copy cp clear
	delete
	edit
	help 
	init 
	list less
	move modify mv
	open 
	rename refresh reorder
	sort
	version
]

not_wanted = %w[
	less clear
	cp mv
]
abbrev = ( commands - not_wanted ).abbrev

##--------------------------------------------------
## do stuff, depending on command
cmd, arg1, arg2 = ARGV
cmd = abbrev[cmd] if abbrev[cmd]

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
	
when 'delete', '-'
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

when 'modify'
	cry "what to modify?" unless arg1
	Please.modify arg1, sentence(2..-1)

when 'move', 'mv'
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

when 'copy', 'cp'
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
	say.help
	say.no_such_command(cmd)

## don't bother to print a stack trace for UserErrors,
## since they are raised only for the message
end rescue UserError===$! ? say( $!.message ) : raise


