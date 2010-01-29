#!/usr/bin/env ruby
require 'test/unit'
require 'stringio'
load 'bf'

class TC_AbbrevHash < Test::Unit::TestCase
	def test_abbrev_hash
		c = AbbrevHash.new
		c['foo'] = 'a'
		c['bar'] = 'b'
		c['bazaar'] = 'z'

		assert_equal "a", c.abbrev('f')
		assert_equal "a", c.abbrev('fo')
		assert_equal "a", c.abbrev('foo')
		assert_equal "b", c.abbrev('bar')
		assert_equal "z", c.abbrev('baz')
		assert_nil c.abbrev('fskljl')
		assert_equal "b", c.abbrev('ba')
		assert_equal "z", c.abbrev('bazaar')
		assert_equal "z", c.abbrev('baz')
	end
end

class TC_BF_Container < Test::Unit::TestCase
	def test_tracker
		tr = Tracker.new
		c1 = Category.new("a")
		c2 = Category.new("b")
		tr.add_category(c1)
		tr.add_category(c2)
		assert_equal 2, tr.size
		tr.add_category(c1)
		tr.add_category(c2)
		assert_equal 2, tr.size
		assert_equal c1, tr[c1.name]
		assert_equal c2, tr[c2.name]
		assert_equal c1, tr[0]
		assert_equal c2, tr[1]
		tr.remove_category(c1)
		assert_equal 1, tr.size
		tr.remove_category(Category.new("c"))
		assert_equal 1, tr.size
		tr.remove_category(c2.name)
		assert_equal 0, tr.size
	end

	def test_category
		cat = Category.new("foo")
		b1 = Bug.new(0, "a")
		b2 = Bug.new(1, "b")
		cat.add_bug(b1)
		cat.add_bug(b2)
		assert_equal 2, cat.size
		cat.add_bug(b1)
		cat.add_bug(b2)
		assert_equal 2, cat.size
		assert_equal b1, cat[b1.id]
		assert_equal b2, cat[b2.id]
		cat.remove_bug(b1)
		assert_equal 1, cat.size
		cat.remove_bug(Bug.new(3, "c"))
		assert_equal 1, cat.size
		cat.remove_bug(b2.id)
		assert_equal 0, cat.size
	end
end

class TC_converting < Test::Unit::TestCase
	CONTENT1 = <<DONE
Category 1

   ( ) #0   10/10/10  Blablabla
   ( ) #1   15/12/10  It's a piece of cake to bake a pretty cake
   ( ) #2   15/12/10  You know you can't be lazy!


Category 2

   ( ) #0   10/10/10  Blablabla

DONE
	CONTENT2 = <<DONE
Category 1

   ( ) #0   10/10/10  Blablabla
   ( ) #2   15/12/10  You know you can't be lazy!


Category 2

   ( ) #0   10/10/10  Blablabla

DONE
	CONTENT3 = <<DONE
Category 1

   ( ) #2   15/12/10  You know you can't be lazy!

DONE
	def test_reading
		io = StringIO.new(CONTENT1)
		tr = Tracker.from_io(io)
		assert_equal 2, tr.size
		category = tr[0]
		assert_equal "Category 1", category.name
		assert_equal "Blablabla", category[0].txt
		assert_equal "It's a piece of cake to bake a pretty cake",
			category[1].txt
	end

	def test_staying_the_same
		io = StringIO.new(CONTENT1)
		tr = Tracker.from_io(io)
		new_content = StringIO.new()
		tr.to_io(new_content)
		assert_equal CONTENT1, new_content.string
	end

	def test_deleting
		io = StringIO.new(CONTENT1)
		tr = Tracker.from_io(io)

		tr[0].remove_bug(tr[0][1])
		new_content = StringIO.new()
		tr.to_io(new_content)
		assert_equal CONTENT2, new_content.string

		tr.remove_bug(tr[0][0])
		new_content = StringIO.new()
		tr.to_io(new_content)
		assert_equal CONTENT3, new_content.string
	end
end
