class Timer
	constructor: (@time, @cb) ->
	update: (dt) -> @cb() if (@time -= dt) < 0

class Collection
	constructor: ->
		@items = {}
		@nextId = 0

	add: (item) -> @items[@nextId] = item; item.__collection_id = @nextId++
	remove: (item) -> delete @items[item.__collection_id]
	each: (f) -> f(v,id) for id,v of @items

isConnectedTo = (b1, b2) ->
	flagged = [b1]
	b1._flagged = true
	found = false
	b1.eachArbiter (arb) ->
		return if found or arb.getB().body._flagged
		b = arb.getB().body
		if b == b2
			found = true
			return
		b._flagged = true
		flagged.push b
		found = isConnectedTo b, b2
	delete b._flagged for b in flagged
	return found


removeFromList = (l, o) ->
	i = l.indexOf o
	l[i] = l[l.length - 1]
	l.length--


class Juggle extends Demo
	constructor: ->
		super
		@space.gravity = v(0, -40)
		@space.sleepTimeThreshold = 0.5
		@space.collisionSlop = 0.5

		@addFloor()
		@addWalls()

		@objects = []
		@timers = new Collection

		@pistons = []
		for [1..5]
			b = new cp.Body(30, cp.momentForBox(30, 128, 200))
			s = new cp.BoxShape b, 128, 200
			@space.addShape s
			@pistons.push b

		@canvas.onmousedown = (e) =>
			rightclick = e.which == 3 # or e.button === 2

			if !rightclick && !self.mouseJoint
				point = @canvas2point(e.clientX, e.clientY)

				shape = @space.pointQueryFirst(point, GRABABLE_MASK_BIT, cp.NO_GROUP)
				if shape
					body = shape.body
					r = v.sub(point, body.p)
					d = v.mult(v.normalize(r), -500)
					body.applyImpulse(d,r)
					body.applyImpulse(v(0,1000),r)

		@in 1, => @drop()

	in: (secs, cb) ->
		@timers.add(t = new Timer secs, => @timers.remove t; cb())

	drop: ->
		mass = 15
		body = @space.addBody(new cp.Body(mass, cp.momentForBox(mass, 100, 40)))
		body.setPos(v(320, 480))

		shape = @space.addShape(new cp.BoxShape(body, 100, 40))
		shape.setElasticity(0)
		shape.setFriction(0.9)

		@objects.push body
		body.life = 10 - Math.random()*5
		body.alive = 0
		@in Math.random()*4+1, => @drop()

	update: (dt) ->
		super dt
		@timers.each (t) -> t.update dt
		toRemove = []
		for o,i in @objects
			if isConnectedTo o, @floor.body
				o.shapeList[0].style = -> 'black'
				o.alive = 0
			else
				delete o.shapeList[0].style
				o.alive += dt
				if o.alive >= o.life
					@space.removeBody o
					for s in o.shapeList
						@space.removeShape s
					toRemove.push o
		for o in toRemove
			removeFromList @objects, o

game = new Juggle
game.run()
