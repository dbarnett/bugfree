require 'yaml'

module Design
	extend self

	def compile( hash )
		return YAML.dump( hash )
	end

	def extract( io )
		return YAML.load( io )
	end

end

