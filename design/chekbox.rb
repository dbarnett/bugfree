
module Design
	extend self

	def compile( hash )
		cats = {}
		for cat in hash[:categories]
			cats[cat] = Hash[hash.select do |id, bug|
#					p bug
					if bug.is_a? Bug
						bug.cat == cat
					else
						false
					end
				end
			]
		end

		content = ""
		for name, bugs in cats
			next if bugs.empty?
			content << name + "\n"
			for id, bug in bugs
				content << ("    [%s] #%d  %s  %s\n" % [
					(bug.open ? ' ' : 'x'), bug.id, bug.strftime, bug.txt ])
			end
		end

		return content
	end

	def extract( io )
		return nil
	end

end

