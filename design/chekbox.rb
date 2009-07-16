
module Design
	extend self

	def compile( hash )
		content = ""
		for name, bugs in hash
			next if bugs.empty?
			content << "\n" unless content.empty?
			content << name + "\n"
			for id, bug in bugs
#				content << ("    [%s] #%d  %s  %s\n" % [
#					(bug.open ? ' ' : 'x'), bug.id, bug.strftime, bug.txt ])
				content << ("   (%s) %-3d %s  %s\n" % [
					(bug.open ? ' ' : 'X'), bug.id, bug.strftime, bug.txt ])
			end
		end

		return content
	end

	def extract( io )
		content = io.read
		cat = nil
		current = nil
		hash = {}

		for line in content.each_line
			if line !~ /^\s\s\s/
				cat = line.strip
				hash[ cat ] = {}
				current = hash[ cat ]
			else
				if bug = line_to_bug( line, cat )
					current[bug.id] = bug
				end
			end
		end

		return hash
	end

	def line_to_bug( line, cat )
#		if line =~ /^    \[([x ])\]\s+#(\d+)\s+(\d\d)\/(\d\d)\/(\d\d)\s+(.+)$/
		if line =~ /^
				\s+ [<\[(] ([xX ]) [>\])]
				\s+ (\d+)
				\s+ (\d\d) \/ (\d\d) \/ (\d\d)
				\s+ (.+) $/x
#			puts "match!!"
			open = $1 == ' ' 
			id = $2.to_i
			time = Time.local("20#{$3}".to_i, $4.to_i, $5.to_i)
#			time = Time.local("20#{$2}".to_i, $3.to_i, $4.to_i)
			txt = $6
			bug = Bug.new( txt, cat, id, time, open )
		else
#			puts "no match for #{line}"
			return nil
		end
	end

end

