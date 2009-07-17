
module Say
	extend self

	def help(about=nil)
		puts boldize(HELP_ABOUT[about] || HELP)
	end

	def failure
		say FAILURE
	end

	def create_overwrite?(file=nil)
		ask OVERWRITE, file ? "the file \"#{file}\"" : "a file"
		yes?
	end

	def no_such_command(which)
		say NOCMD, which
	end

	def should_i_init?(why)
		ask SHOULDIINIT, why
		yes?
	end
	
	def no_such_id
		say "there is no such ID to delete.  Please use 'bf list' and pick\nan existing ID :)"
	end
	
	def added
		say ADDED
	end
	
	## bla bla bla {{{
	HELP =
"usage: bf *command* [options]
the commands are:
   *init*      create an empty todo file
   *help*      use 'bf help COMMAND' for more info about a command
   *version*   print the version
   *list*      list all bugs. default action if a todo file exists
   *move*      move a bug to a different category
   *reorder*   move a category to the specified place (number)
   *rename*    rename a category
   *mod*       modify the message of a bug
   *clear*     remove the todo file to clear all records
   *close*     close a bug, or list all closed bugs
   *open*      open a bug, or list all opened bugs
   *del*       delete a bug

"

	HELP_ABOUT = {
		'init' => "lol wtfq",
		'add' =>
"usage: bf *add* [category] word1 word2 word3...
category may be abbreviated or specified by the index.
Examples:
    bf *add* general this is a first test
    bf *add* 3 bla bla bla
    bf *add* 'severe bugs' 'the program smells' "
	}

	OVERWRITE =
"I was going to create %s, but it does already exist.  Do you want me to *overwrite* it? [yn] "

	FAILURE =
"I'm afraid that *something went wrong*.  For help, read the source code."

	SHOULDIINIT =
"You're trying to %s, but I can't find a todo-file here.  It is required for me to work.  Should i create one? [yn] "

	ADDED =
"acknowledged"

	ACK = "done"

	NOCMD =
"Pardon? I know of *no such command*: %s"

	## }}}
end

def error( str, *args )
	raise InternalError, str % args, caller( 1 )
end

def cry( str, *args )
	raise UserError, str % args, caller( 1 )
end

def boldize(str)
	return str unless USE_BOLD
	str.gsub(/\*([^*]+)\*/, "\033[1m\\1\033[0m")
end

def number_of_rows
	`stty size`.scan(/\d+/).first.to_i rescue 24
end

def number_of_columns
	`stty size`.scan(/\d+/).last.to_i rescue 80
end

def break_on_nl(str)
	return str unless Breaks
	return str unless (c = number_of_columns - 3) > 10
	
	newstr = ""
	first = true
	until str.size < c
		n = str[0, c].index("\n")
		s = str.rindex(/\s/, c)
		dot = str.rindex(/\.\s/, c)

		if !n
			if dot and (c - dot) < 20
				p "YEAH"
				newstr << uhmm(first) + str.slice!(0, dot+1) + "\n"
				str.lstrip!
			else
				newstr << uhmm(first) + str.slice!(0, s) + "\n"
				str.lstrip!
			end
		else
			newstr << uhmm(first) + str.slice!(0, n+1)
		end
		first = false
	end
	newstr << uhmm(first) + str
#	newstr = newstr.gsub(" ", "-").gsub("\n","$\n")
	return newstr
end

def ask( str, *args )
	str = str.to_s
	$stdout.write( boldize( break_on_nl( str % args ) ) )
	return 1
end

def say( *args )
	return Say if args.empty?
	str = args.shift
	ask( "#{str}\n", *args )
end

def yes?
	%w[y yes].include?( $stdin.gets.strip.downcase )
end

def ask_for( &block )
	error "i need a block please!" unless block_given?
	str = $stdin.gets.strip.downcase
	yield( str ) && str
end

def uhmm(first=false)
	first ? "> " : "  "
end

def ack
	ask ACKS[ rand ACKS.size ]
end

ACKS = (<<END #{{{
mkay
i made it so.
ack
i did.
ok
done
no problem.
np
k
END
).each_line.to_a #}}}


