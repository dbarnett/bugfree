#!/usr/bin/env ruby
# bugfree (hopefully)
VERSION = 'bugfree version 3.14.159'

require 'tempfile'
require 'set'

# Constants {{{
$spaces = false
class UserError < RuntimeError; end
DB_BASENAMES = %w[TODO TODO.TXT .TODO .TODO.TXT BUGS BUGS.TXT .ASDF]
EDITOR = ENV['EDITOR'] || 'nano'
PAGER = "less -XF"
DATEFORMAT = "%y/%m/%d"
DATEFORMAT_REGEXP = '(\d\d/\d\d/\d\d)'
PARSE_DATEFORMAT = lambda do |str|
	if str =~ %r'(\d\d)/(\d\d)/(\d\d)'
		return Time.local("20#$1".to_i, $2.to_i, $3.to_i)
	end
	return Time.at(0)
end
DEFAULT_CATEGORY = 'General'
HELP = <<DONE
usage: bf [OPTIONS] COMMAND [ARGS]
options:
   --help     Prints this help. use --help COMMAND for specific help
   --version  Displays the version
commands:
   init    Create an empty todo file
   list    List all bugs. (Default if a database was found)
   edit    Edits the bug or the whole database in an external editor
   open    Open a bug, or list all opened bugs
   close   Close a bug, or list all closed bugs
   sort    Sort by id, time, text, open, close, reverse
   move    Move a bug to a different category
   add     Add a bug
   remove  Delete a bug
   set     Modify the text of a bug
All commands can be abbreviated.
DONE
#}}}
# Functions {{{
def bold;     "\033[1m" end
def no_attr;  "\033[0m" end

def black;    "\033[0;30m" end
def red;      "\033[0;31m" end
def green;    "\033[0;32m" end
def yellow;   "\033[0;33m" end
def blue;     "\033[0;34m" end
def magenta;  "\033[0;35m" end
def cyan;     "\033[0;36m" end
def white;    "\033[0;37m" end

def pager(&block)
	IO.popen(PAGER, 'w', &block)
end

def say(*args)
	pager do |io|
		io.write(args.join(' '))
	end
end

def cry(str, *args)
	raise UserError, str % args, caller( 1 )
end
#}}}
# Extensions for builtin classes {{{
class Hash
	def sort!( &block )
		replace( Hash[self.sort( &block )] )
	end
	def reverse!
		replace( Hash[self.to_a.reverse] )
	end
end

class TrueClass
	def to_i
		1
	end
end

class FalseClass
	def to_i
		0
	end
end
#}}}
class AbbrevHash < Hash #{{{
	def abbrev(name)
		for key, value in self
			return value if key.start_with?(name)
		end
		return nil
	end
end #}}}
class Tracker < Hash #{{{
	attr_accessor :categories
	def initialize
		@categories = SortedSet.new
	end
	alias getitem []
	def [](x)
		if x.is_a? Integer
			self[@categories.to_a[x]]
		else
			getitem(x)
		end
	end
	def add_category(cat)
		@categories << cat.name
		self[cat.name] = cat
	end
	def remove_category(cat)
		if cat.is_a? Category
			cat = cat.name
		end
		@categories.delete(cat)
		self.delete(cat)
	end
	def remove_bug(bugid)
		if bugid.is_a? Bug
			bugid = bugid.id
		end
		for name, cat in self
			cat.remove_bug(bugid)
		end
	end
	def find_category(hint, create=false)
		cat = _find_category(hint)
		if cat.nil?
			if create
				cat = Category.new(hint.to_s)
				add_category(cat)
			else
				if not self.include? DEFAULT_CATEGORY
					cat = Category.new(DEFAULT_CATEGORY)
					self.add_category(cat)
				else
					cat = self[DEFAULT_CATEGORY]
				end
			end
		end
		return cat
	end
	def _find_category(hint)
		if hint.nil?
			return nil
		end
		if hint.is_a? Category
			return self[hint.name]
		end
		if hint =~ /^\d+$/
			return self[$1.to_i]
		end

		hint_downcase = hint.downcase
		for catname, cat in self
			if catname.downcase.include? hint_downcase
				return cat
			end
		end
		return nil
	end
	def get_next_id
		max = -1
		for catname, cat in self
			for id, bug in cat
				max = id if id > max
			end
		end
		return max + 1
	end
	def clone
		tr = Tracker.new
		tr.categories = SortedSet.new(@categories)
		tr.replace self
		return tr
	end
	# converting {{{
	def to_io(io, format=false)
		start = true
		spaces = (format == false) || $spaces
		for cat in self.values
			next if cat.empty?
			if start
				start = false
			else
				if spaces then io.write("\n\n") end
			end
			if format
				io.write("#{bold}#{cat.name}#{no_attr}\n")
			else
				io.write(cat.name + "\n")
			end
			if spaces then io.write("\n") end
			for id, bug in cat
				if format
					io.write("#{bug.open ? red : no_attr}%s#{no_attr} %s\n" \
							 % [ "##{bug.id}".rjust(5), bug.txt ])
				else
					io.write("   (%s) #%-3d %s  %s\n" % [
						(bug.open ? ' ' : 'X'), bug.id,
						bug.strftime, bug.txt ])
				end
				unless bug.more.empty?
					bug.more.each_line do |line|
						io.write("#{' '*10}#{line}")
					end
				end
			end
		end
		if spaces then io.write("\n") end
	end
	def Tracker.from_io(io)
		tr = new
		all_bugs = Category.new('')
		cat = nil
		lastbug = nil
		for line in io.each_line
			next if line.strip.empty?
			if line !~ /^\s\s\s/
				cat = Category.new(line.strip)
				tr.add_category(cat)
			elsif cat and bug = Bug.from_line(line)
				if bug
					bug = all_bugs[bug.id] || bug
					cat.add_bug(bug)
					all_bugs.add_bug(bug)
					lastbug = bug
					bug.n += 1
				end
			elsif lastbug and line =~ /\s{5}\s+(.+)$/
				lastbug.more += $1 + "\n" if lastbug.n == 1
			end
		end
		return tr
	end #}}}
end #}}}
class Category < Hash #{{{
	attr_accessor :name
	def initialize(name)
		@name = name
	end
	def add_bug(bug)
		self[bug.id] = bug
	end
	def remove_bug(bug)
		if bug.is_a? Bug
			bug = bug.id
		end
		self.delete(bug)
	end
end #}}}
class Bug < Struct.new(:id, :txt, :time, :open, :more, :n) #{{{
	def initialize(id, txt, time=nil, open=true, more='', n=0)
		super(id, txt, time||Time.now, open, more, n)
	end
	def strftime
		time.strftime(DATEFORMAT)
	end
	def Bug.from_line(line)
		if line =~ /^
				\s+ [<\[(] ([xX ]) [>\])]
				\s+ \# (\d+)
				\s+ #{DATEFORMAT_REGEXP}
				\s+ (.+) $/x
			open = $1 == ' ' 
			id = $2.to_i
			time = PARSE_DATEFORMAT.call($3)
			txt = $4
			new(id, txt, time, open)
		else
			return nil
		end
	end
end #}}}
class Bf #{{{
	def initialize
		@commands = nil
		@dbfile = nil
		@tracker = nil
		init_commands!
	end
	def main(*argv)
		cmdname = argv.shift
		begin
			if cmdname
				if process = @commands.abbrev(cmdname)
					process.call(argv)
				else
					main('help')
				end
			else
				begin
					find_db!
				rescue UserError
					main('help')
				else
					main('list', 'open')
				end
			end
		rescue UserError
			STDERR.puts $!.message
			exit(1)
		end
	end
	def init_commands! #{{{
		return if @commands
		@commands = AbbrevHash.new
		on "init" do |args|
			find! or init!
			init!
			puts "foo"
		end
		on 'edit' do |args|
			if args.empty?
				edit!
			else
				edit_bug! args.join(' ')
			end
		end
		on 'sort' do |args| sort!(*args) end
		on 'add', '+', '=' do |args|
			case args.size
			when 0
				cry "Add what?"
			when 1
				add! nil, args[0]
				dump!
			else
				cat = args.shift
				read!
				add!(@tracker.find_category(cat, true), args.join(' '))
				dump!
			end
		end
		on 'list', 'all' do |args| list!(*args) end
		on 'open' do |args|
			if args.empty?
				list! 'open'
			else
				set_status!(args[0], true)
			end
		end
		on 'close' do |args|
			if args.empty?
				list! 'close'
			else
				set_status!(args[0], false)
			end
		end
		on 'set' do |args|
			if args.size.between? 0, 1
				cry 'Syntax: bf set <bug id> <new text>'
			else
				bug = args.shift
				read!
				find_bug(bug).txt = args.join(' ')
				dump!
			end
		end
		on 'move', 'mv' do |args|
			if args.size.between? 0, 1
				cry 'Syntax: bf move <bug id> <new category>'
			else
				read!
				bug = find_bug(args.shift)
				cat = @tracker.find_category(args.join(' '), true)
				cry "Bug is already in that category!" if cat[bug.id]
				@tracker.remove_bug(bug)
				cat.add_bug(bug)
				dump!
			end
		end
		on 'delete', 'remove', 'rm', '-' do |args|
			if args.empty?
				cry 'Delete what?'
			else
				read!
				@tracker.remove_bug(find_bug(args.join(' ')))
				dump!
			end
		end
		on 'version', '--version' do puts VERSION end
		on 'help', '-h', '--help' do puts HELP end
	end #}}}
	# actions {{{
	def find_db!
		return if @dbfile
		directory = '.'
		10.times do
			for fname in Dir.entries(directory)
				for todoname in DB_BASENAMES
					if fname.upcase == todoname
						return @dbfile = File.join(directory, fname)
					end
				end
			end
			directory = File.join(directory, '..')
		end
		cry "There is no database!"
	end
	def read!
		return if @tracker
		find_db!
		@tracker = Tracker.from_io(File.open(@dbfile, 'r'))
	end
	def add!(category, text)
		read!
		id = @tracker.get_next_id
		bug = Bug.new(id, text)
		@tracker.find_category(category).add_bug(bug)
	end
	def dump!
		return if not @tracker
		find_db!
		File.open(@dbfile, 'w') do |f|
			@tracker.to_io(f)
		end
	end
	def edit!
		find_db!
		system("#{EDITOR} #{@dbfile}")
	end
	def edit_bug!(hint)
		bug = find_bug(hint)
		file = Tempfile.new('bf')
		file.open()
		file.write("#{bug.txt}\n")
		file.write(bug.more) unless bug.more.empty?
		file.close()
		system("#{EDITOR} #{file.path}")

		file.open()
		new_content = file.readlines
		file.close()
		file.unlink()

		unless new_content.empty?
			bug.txt = new_content.shift
			bug.more = new_content.join("")
			dump!
		end
	end
	def sort!(*args)
		read!
		actions = AbbrevHash.new
		add = lambda do |*args, &block|
			args.each{|arg| actions[arg] = block}
		end
		add.call 'id', 'index' do sort_by{|a, b| a.id <=> b.id} end
		add.call 'text', 'alphabetical' do sort_by{|a, b| a.txt <=> b.txt} end
		add.call 'date', 'time' do sort_by{|a, b| a.time <=> b.time} end
		add.call 'closed' do sort_by{|a, b| a.open.to_i <=> b.open.to_i} end
		add.call 'open' do sort_by{|a, b| b.open.to_i <=> a.open.to_i} end
		add.call 'reversed' do @tracker.each{|x| x[1].reverse!} end

		if args.empty?
			args = ['id']
		end

		for arg in args
			action = actions.abbrev(arg)
			action.call() if action
		end
		dump!
	end
	def list!(what=nil)
		read!
		tracker = @tracker.clone

		what ||= 'all'
		for catname, category in tracker
			category.delete_if do |id, bug|
				bug.open == (what != 'open')
			end
		end if %w[open close].include? what
		tracker.delete_if {|name, category| category.empty?}
		if tracker.empty?
			say "You are bugfree." if what != 'close'
		else
			pager do |io|
				tracker.to_io(io, format=true)
			end
		end
	end
	def set_status!(bug, open)
		read!
		bug = find_bug(bug)
		if bug.open != open
			bug.open = open
			dump!
		end
	end
	def by_id(id)
		read!
		for name, cat in @tracker
			for bugid, bug in cat
				return bug if bugid == id
			end
		end
		cry "No bug with id #{id}!"
	end
	def find_bug(hint)
		read!

		return by_id(hint.to_i) if hint =~ /^\d+$/

		hintdown = hint.downcase
		partial, exact = [], []
		for key, bugs in @tracker
			for id, bug in bugs
				if bug.txt.downcase.include? hintdown
					partial << bug
				end
				if bug.txt.downcase == hintdown
					exact << bug
				end
			end
		end

		case partial.size
		when 0; cry "No such bug!"
		when 1; return partial.first
		else
			return exact.first if exact.size == 1
			cry "Ambiguous query, please be more precise."
		end
	end
	# }}}
	private #{{{
	def on(*names, &block)
		for name in names
			@commands[name] = block
		end
	end
	def sort_by
		for cat, bugs in @tracker
			bugs.sort! do |a, b| yield a[1], b[1] end
		end
	end
	#}}}
end #}}}

Bf.new.main(*ARGV) if __FILE__ == $0
