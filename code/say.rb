module Kernel
	def Say(*args)
		Say.sayl(*args)
	end
end

module Say
	USE_BOLD = true

	def help(about=nil)
		sayl HELP_ABOUT[about] || HELP
	end

	def failure
		conv
		sayl FAILURE
	end

	def create_overwrite?(file=nil)
		conv
		say OVERWRITE, file ? "the file \"#{file}\"" : "a file"
		yes?
	end

	def no_such_command(which)
		conv
		sayl NOCMD, which
		puts
	end

	def should_i_init?(why)
		conv
		say SHOULDIINIT, why
		yes?
	end
	
	def no_such_id
		conv
		sayl "there is no such ID to delete. Please use 'bf list' and pick\nan existing ID :)"
	end
	
	def added
		conv
		sayl ADDED
	end
	
	def ack
		conv
		sayl ACK
	end

	## bla bla bla {{{
	HELP =
"usage: bf *command* [options]
the commands are:
   init
   help
   version
   list

for more information on a command, type: bf help COMMAND"

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
"I was going to create %s, but it does already exist.
Do you want me to *overwrite* it? [yn] "

	FAILURE =
"I'm afraid that *something went wrong*.
For help, read the source code."

	SHOULDIINIT =
"You're trying to %s, but I can't find a todo-file here.
It is required for me to work. Should i create one? [yn] "

	ADDED =
"acknowledged"

	ACK = "done"

	NOCMD =
"Pardon? I know of *no such command*: %s"

	## }}}

	## stuff {{{
	def say(str, *args)
		str = str.to_s
		if USE_BOLD
			$stdout.write boldize(str) % args
		else
			$stdout.write str % args
		end
	end

	def sayl(str, *args)
		say(str, *args)
		puts
	end

	def conv
		say Time.now.strftime("-- ")
	end

	def yes?
		%w[y yes].include?($stdin.gets.strip.downcase)
	end

	def boldize(str)
		str.gsub(/\*([^*]+)\*/, "\033[1m\\1\033[0m")
	end

	extend self
	## }}}
end

