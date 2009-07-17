module Design
	extend self

	def compile( hash )
		content = ""
		for name, bugs in hash
			next if bugs.empty?
			content << "\n\n" unless content.empty?
			content << name + "\n\n"
			for id, bug in bugs
				content << ("   (%s) #%-3d %s  %s\n" % [
					(bug.open ? ' ' : 'X'), bug.id, bug.strftime, bug.txt ])
				unless bug.more.empty?
					bug.more.each_line do |line|
						content << "#{ 10.spaces }> #{ line }"
					end
				end
			end
		end

		return content
	end

	def extract( io )
		content = io.read
		cat = nil
		current = nil
		hash = {}
		lastbug = nil

		for line in content.each_line
			if line !~ /^\s\s\s/
				cat = line.strip
				unless cat.empty?
					hash[ cat ] = {}
					current = hash[ cat ]
				end
			else
				if bug = line_to_bug( line, cat )
					current[bug.id] = bug
					lastbug = bug
				elsif lastbug and line =~ / {10}> (.+)$/
					lastbug.more += $1 + "\n"
				end
			end
		end

		return hash
	end

	def line_to_bug( line, cat )
		if line =~ /^
				\s+ [<\[(] ([xX ]) [>\])]
				\s+ \# (\d+)
				\s+ #{Please::DATEFORMAT_REGEXP}
				\s+ (.+) $/x

			open = $1 == ' ' 
			id = $2.to_i
			time = Please::PARSE_DATEFORMAT.call( $3 )
			txt = $4
			bug = Bug.new( txt, cat, id, time, open )
		else
			return nil
		end
	end

end

