class Bug < Struct.new(:txt, :cat, :id, :time, :open)
	NO_TIME = Time.at(0)
	NO_CAT = "General"
	NO_TXT = "no text"

	def initialize(txt, cat, id, time=nil, open=true)
		super(txt, cat, id, time||Time.now, open)
	end

	def strftime; time.strftime(Please::DATEFORMAT) end

	## make sure the types are correct
	def time; super.ensure_type Time,     NO_TIME  end
	def cat;  super.ensure_type String,   NO_CAT   end
	def txt;  super.ensure_type String,   NO_TXT   end
	def id;   super.ensure_type Integer,  0        end
	def open; (TrueClass === super or FalseClass === super) ? super : true end
end

#bug = Bug.new
#p bug.id
#bug.id += 1
#p bug.id

