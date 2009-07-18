
class InternalError < Exception; end
class UserError < RuntimeError; end
class NotFound < UserError; end

A = 'a'
W = 'w'
R = 'r'

class Object
	def ensure_type(type, default)
		type === self ? self : default
	end
end

class Hash
	def sort!( &block )
		replace( self.class[self.sort( &block )] )
	end
	def reverse!
		replace( self.class[self.to_a.reverse] )
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

class Fixnum
	def spaces
		' ' * self
	end
end

def sentence range
	ARGV[range].join(" ")
end

if RUBY_VERSION >= '1.9'
	SortedHash = Hash
else
	## TODO
	abort "Sorry, but 'sorted hash' is not implemented in ruby 1.8.x.\nPlease use 1.9 until this issue is solved."
end

