module Design
	extend self

	def compile_colorful( hash )
		content = ""
		for name, bugs in hash
			next if bugs.empty?
			content << "\n\n" unless content.empty?
			content << "#{blue}#{name}#{no_attr}\n\n"
			for id, bug in bugs
#				t = bug.strftime.gsub( /([^\d\w]+)/, "#{cyan}\\1#{no_attr}" )
				t = bug.strftime.gsub( /([\d\w]+)/, "#{cyan}\\1#{no_attr}" )
#				t = cyan + bug.strftime + no_attr
				content << ("   (%s) #{magenta}#%-3d#{no_attr} %s  %s\n" % [
					(bug.open ? ' ' : "#{green}X#{no_attr}"), bug.id, t, bug.txt ])
				unless bug.more.empty?
					bug.more.each_line do |line|
						content << "#{ 10.spaces }#{magenta}>#{no_attr} #{ line }"
					end
				end
			end
		end

		return content
	end

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
		allbugs = {}

		for line in content.each_line
			next if line.strip.empty?
			if line !~ /^\s\s\s/
				$errors += 1 if current && current.size == 0
				cat = line.strip
				hash[ cat ] = {}
				current = hash[ cat ]
			else
				if bug = line_to_bug( line )

					bug = allbugs[bug.id] if allbugs[bug.id]
					current[bug.id] = bug
					allbugs[bug.id] = bug
					lastbug = bug

					bug.n += 1
					bug.cat << cat
					bug.cat.uniq!

				elsif lastbug and lastbug.n == 1 and line =~ / {10}> (.+)$/
					lastbug.more += $1 + "\n"
				else
					$errors += 1
				end
			end
		end

		return hash
	end

	def line_to_bug( line )
		if line =~ /^
				\s+ [<\[(] ([xX ]) [>\])]
				\s+ \# (\d+)
				\s+ #{Please::DATEFORMAT_REGEXP}
				\s+ (.+) $/x

			open = $1 == ' ' 
			id = $2.to_i
			time = Please::PARSE_DATEFORMAT.call( $3 )
			txt = $4
			bug = Bug.new( id, txt, time, open )
		else
			return nil
		end
	end

end

