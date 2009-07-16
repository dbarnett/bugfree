module Please
	extend self

	DB_BASENAME = 'TODO.txt'
	DATEFORMAT = "%y/%m/%d"
	DATEFORMAT_REGEXP = '(\d\d/\d\d/\d\d)'
	PARSE_DATEFORMAT = lambda do |str|
		if str =~ %r'(\d\d)/(\d\d)/(\d\d)'
			return Time.local( "20#$1".to_i, $2.to_i, $3.to_i )
		end
		return Time.at( 0 )
	end
	EDITOR = ENV['EDITOR'] || 'nano'

	def find!
		directory = "."
		@db_filename = nil

		10.times do
			if File.exists?( fn = File.join( directory, DB_BASENAME ) )
				@db_filename = fn
				break
			end
			directory = File.join( directory, '..' )
		end
	end

	def init!
		do_it = false
		if not File.exists?( DB_BASENAME ) or
				say.create_overwrite?( DB_BASENAME )
			File.open(DB_BASENAME, 'a')
		else
			say.failure
		end
	end

	def found?
		not @db_filename.nil?
	end

	def clear
		find!
		if found?
			File.delete(@db_filename)
		end
	end

	def load(why = 'load')
		## do not load twice
		return if defined? @hash

		## make sure there's a database
		unless found?
			find!
			unless found?
				if say.should_i_init?(why)
					init!
					find!
					unless found?
						say.failure
						exit
					end
				else
					say.help
					exit
				end
			end
		end

		## actually load
		@hash = nil
		File.open( @db_filename, 'r' ) do |f|
			@hash = Design.extract( f )
		end

		## make sure its a hash with at least 1 category
		unless @hash.is_a? Hash
			@hash = {}
		end

		if @hash.empty?
			@hash[Bug::NO_CAT] = {}
		end

		return @hash
	end

	def dump
		content = Design.compile( @hash )

		puts content if Always_Dump
		File.open( @db_filename, 'w' ) do |io| io.write( content ) end
	end

	def modify(n, task)
		load "modify a bug"

		by_guess(n).txt = task
		dump
		ack
	end

	def add(cat, task)
		load "add a bug"

		id = find_next_id
		bug = Bug.new( task, cat, id )
		( @hash[bug.cat] ||= {} ) [id] = bug

		dump & ack
	end

	def set_status(bug, open)
		load open ? "open a bug" : "close a bug"

		by_guess(bug).open = open
		dump
		ack
	end

	def find_next_id
		max = -1
		for key, bugs in @hash
			for id, bug in bugs
				max = id if max < id
			end
		end
		return max + 1
	end

	def by_id( n )
		@hash.each {|key,bugs| bugs.each {|id,bug| return bug if id==n }}
		cry "bug with the ID #{n} not found."
	end

	def by_guess( hint )
		load "find a bug"

		if hint =~ /^\d+$/
			return by_id( hint.to_i )
		end

		hintdown = hint.downcase
		partial, exact = [], []
		for key, bugs in @hash
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
		when 0
			cry "I can't figure out which bug you mean. \
Try to write the exact ID?"
		when 1
			return partial.first
		else
			return exact.first if exact.size == 1
			cry "Your query was ambiguous. Can you be more specific please?"
		end

	end

	def delete(n)
		load "delete something"

		myid = by_guess( n ).id

		for key, bugs in @hash
			for id, bug in bugs
				if id == myid
					bugs.delete( id )
					break
				end
			end
		end
		dump
		ack
	end

	def edit(what)
		bug = by_guess( what )

		## Create a temporary file and fill it with the data
		filename = "/tmp/bf.#{ Process.pid }.#{ rand 1000000 }"
		file = File.new( filename, 'w' )
		file.write( "##{ bug.txt }\n" )
		file.write( bug.more ) unless bug.more.empty?
		file.close

		system("#{ EDITOR } #{ filename }")

		bug.more = File.read( filename )
		File.delete( filename )

		if bug.more[0] == ?#
			bug.txt = bug.more[1, bug.more.index( "\n" ) - 1]
		end
		bug.more = bug.more.each_line.to_a.select {|x| x[0] != ?#}.join

		dump
		ack
	end

	def move(what, to)
		bug = by_guess( what )
		cat = find_cat( to )

#		p bug
#		p cat
		cry "the bug is already in that category" if bug.cat == cat

		oldcat, bug.cat = bug.cat, cat
		@hash[oldcat].delete( bug.id )
		( @hash[cat] ||= {} )[bug.id] = bug

		dump
		ack
	end

	def list(what='all')
		load "list"
		for key, bugs in @hash
			bugs.delete_if do |id, bug|
				bug.open == (what != 'open')
			end
		end if %w[open close].include? what
		@hash.delete_if {|name, bugs| bugs.empty?}

		if @hash.empty?
			if what=='close'
				say "Sorry, there are no closed bugs."
			else
				say "You are bugfree. Hopefully."
			end
		else
			puts Design.compile( @hash )
			puts
		end
	end

	def rename_category(which, newname)
		load "rename category"
		cat = find_cat!(which)
		cry "the names are the same" if cat == newname
		@hash[newname] = @hash[cat]
		@hash.delete(cat)
		dump
		ack
	end

	def reorder_category(which, newi)
		load "reorder category"
		cat = find_cat!(which)
		newi = newi.to_i

		hash, i, added = {}, 0, false
		for name, bugs in @hash
			if (!added) and (i == newi)
				hash[cat] = @hash[cat]
				added = true
			end
			if name != cat
				hash[name] = bugs
			end
			i += 1
		end

		unless added
			puts "x."
			hash[cat] = @hash[cat]
		end
		@hash = hash

		dump
		ack
	end

	def find_cat(cat)
		find_cat!(cat) rescue cat
	end

	def find_cat!(cat)
		load "find a category"

		if cat =~ /^\d+$/
			return @hash.keys[$1.to_i]
		end

		catd = cat.downcase
		for key in @hash.keys
			if key.downcase.include? catd
				return key
			end
		end

		cry "this category was not found"
	end
end

