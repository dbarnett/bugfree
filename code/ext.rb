
class Object
	def ensure_type(type, default)
		type === self ? self : default
	end unless defined? ensure_type
end

if RUBY_VERSION >= '1.9'
	SortedHash = Hash
else
	## TODO
	abort "Sorry, but 'sorted hash' is not implemented in ruby 1.8.x.\nPlease use 1.9 until this issue is solved."
end

