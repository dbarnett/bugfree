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

		unless @hash[:categories].is_a? Array
			@hash[:categories] = [Bug::NO_CAT]
		end

		return @hash
	end

	def dump
		content = Design.compile( @hash )

		if Debug
			puts content
		else
			File.open( fname, 'w' ) do |io| io.write( content ) end
		end
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

		id = @hash.keys.sort[-2].to_i + 1
		@hash[id] = Bug.new( task, cat, id )

		dump
#		Say.added
	end

	def delete(n)
		load "delete something"

		if @hash[n]
			@hash.delete n
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
			@hash.each do |i, bug|
				next if i == :categories
				next if bug.nil?
				p i, bug
				
				t = bug['time']
				t &&= t.strftime( DATEFORMAT )
				Say "%d, %s - %s; %s", i, t, bug['task'], bug['status']
			end
		end
	end

	def find_cat(cat)
		load "find a category"

		if cat =~ /^\d+$/
			return @hash.keys[$1.to_i]
		end
	end
end

