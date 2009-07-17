class Bug < Struct.new(:id, :txt, :cat, :time, :open, :more, :n)
	NO_TIME = Time.at(0)
	NO_CAT = "General"
	NO_TXT = "no text"
	NO_MORE = ""

	def initialize(id, txt, time=nil, open=true, more='', cat=[], n=0)
		super(id, txt, cat, time||Time.now, open, more, n)
	end

	## extra functions
	def strftime; time.strftime(Please::DATEFORMAT) end
	def in_cat?( c ) cat.include?( c ) end

	## make sure the types are correct
	def time; super.ensure_type Time,     NO_TIME  end
	def cat;  super.ensure_type Array,   [NO_CAT]  end
	def more; super.ensure_type String,   NO_MORE  end
	def txt;  super.ensure_type String,   NO_TXT   end
	def id;   super.ensure_type Integer,  0        end
	def n;    super.ensure_type Integer,  1        end
	def open; (TrueClass === super or FalseClass === super) ? super : true end
end

#bug = Bug.new
#p bug.id
#bug.id += 1
#p bug.id

