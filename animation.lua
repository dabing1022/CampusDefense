require 'middleclass'

Animation = class 'Animation'

Animation.DONE = 'done'
Animation.RUNNING = 'running'

function Animation:initialize(name)
	self.name = name
end

-- WalkAnimation

WalkAnimation = Animation:subclass 'WalkAnimation'

WalkAnimation.FRAMES = {0, 1, 2, 1}
WalkAnimation.FRAMERATE = 4  -- frame per second
WalkAnimation.FACE2NUMBER = {
	south = 0,
	west = 1,
	east = 2,
	north = 3
}

function WalkAnimation:initialize(fighter, fighterOrigin)
	Animation.initialize(self, 'walk')

	self.fighter = fighter
	self.fighterOrigin = fighterOrigin
	self.elapsed = 0
	self.frame = 0
	self.face = fighter.face
end

function WalkAnimation:update(dt)
	local updateQuad = false

	if self.fighter.isMoving then
		self.elapsed = self.elapsed + dt

		local frameIndex = (math.floor(self.elapsed * WalkAnimation.FRAMERATE) % 4) + 1
		local frame = WalkAnimation.FRAMES[frameIndex]

		if self.frame ~= frame then
			self.frame = frame
			updateQuad = true
		end
	end

	if self.face ~= self.fighter.face then
		self.face = self.fighter.face
		updateQuad = true
	end

	if updateQuad then
		local x = self.frame * self.fighter.width + self.fighterOrigin.x
		local y = WalkAnimation.FACE2NUMBER[self.face] * self.fighter.height + self.fighterOrigin.y

		self.fighter.quad = love.graphics.newQuad(x, y, 
			self.fighter.width, self.fighter.height, 
			self.fighter.image:getWidth(), self.fighter.image:getHeight())
	end

	return Animation.RUNNING
end

-- Move Animation

MoveAnimation = Animation:subclass 'MoveAnimation'
MoveAnimation.SPEED = 200
MoveAnimation.STEP_TIME = tilewidth / MoveAnimation.SPEED

function MoveAnimation:initialize(fighter)
	Animation.initialize(self, 'move')

	self.fighter = fighter
	self.elapsed = 0

	fighter.isMoving = true
end

function MoveAnimation:update(dt)
	self.elapsed = self.elapsed + dt
	local step = math.ceil(self.elapsed / MoveAnimation.STEP_TIME)

	local fighter = self.fighter

	if step >= #fighter.path then
		fighter.isMoving = false

		Fighter.set(fighter.pos, nil)
		fighter.pos = fighter.path[#fighter.path]
		Fighter.set(fighter.pos, fighter)
		
		fighter.path = nil
		fighter.offset:reset()

		return Animation.DONE
	end

	local from = fighter.path[step]
	local to = fighter.path[step + 1]

	if self.step ~= step then
		self.step = step
		fighter.face = from:direction(to)
	end

	local smallElapsed = self.elapsed - MoveAnimation.STEP_TIME * (step - 1)
	local smallOffset = (to - from) * smallElapsed * MoveAnimation.SPEED

	local x = (from.x - fighter.pos.x) * tilewidth + smallOffset.x
	local y = (from.y - fighter.pos.y) * tileheight + smallOffset.y

	fighter.offset:set(x,y)

	return Animation.RUNNING
end

