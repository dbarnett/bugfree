module Please
	extend self

	DB_BASENAME = 'TODO.yaml'
	DATEFORMAT = "%y/%m/%d"

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
				Say.create_overwrite?( DB_BASENAME )
			File.open('TODO.yaml', 'a')
		else
			Say.failure
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
				if Say.should_i_init?(why)
					init!
					find!
					unless found?
						Say.failure
						exit
					end
				else
					Say.help
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

		if bug = @hash[n]
			bug['task'] = task
			dump
			Say.ack
		else
			Say.no_such_id
		end
	end

	def add(cat, task)
		load "add a bug"

		id = find_next_id
		bug = Bug.new( task, cat, id )
		( @hash[bug.cat] ||= {} ) [id] = bug

		dump
		Say.added
	end

	def set_status(bug, open)
		load open ? "open a bug" : "close a bug"

		by_guess(bug).open = open
		dump
		Say.ack
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
		abort "bug with the ID #{n} not found."
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
					possible << bug
				end
				if bug.txt.downcase == hintdown
					exact << bug
				end
			end
		end

		case possible.size
		when 0
			abort "-- I can't figure out which bug you mean. Try to write the exact ID"
		when 1
			return possible.first
		else
			return exact.first if exact.size == 1
			abort "-- Your query was ambiguous. Can you be more specific please?"
		end

	end

	def delete(n)
		load "delete something"

		if by_id(n)
			for key, bugs in @hash
				for id, bug in bugs
					if id == n
						bugs.delete( id )
						break
					end
				end
			end
			dump
			Say.ack
		else
			Say.no_such_id
		end
	end

	def list
		load "list"
		if @hash.empty?
			Say "You are bugfree. Hopefully."
		else
			Say Design.compile( @hash )
#			@hash.each do |i, bug|
#				next if i == :categories
#				next if bug.nil?
#				p i, bug
#				
#				t = bug['time']
#				t &&= t.strftime( DATEFORMAT )
#				Say "%d, %s - %s; %s", i, t, bug['task'], bug['status']
#			end
		end
	end

	def find_cat(cat)
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

		return cat
	end
end

