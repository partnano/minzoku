local lg = love.graphics
local lp = love.physics

local Entity = {
   id    = -1,
   --x, y  = 0, 0,
   r     = 10,
   speed = 20,

   move_vec = { x = 0, y = 0 },
   
   selected = false,

   body    = nil,
   shape   = nil,
   fixture = nil
}

function Entity:new (world, o)
   o = o or {}
   setmetatable (o, self)
   self.__index = self

   -- o.x and o.y are provided by spawn function in entity_manager !
   o.body    = lp.newBody (world, o.x, o.y, 'dynamic')
   o.shape   = lp.newCircleShape (o.r +3)
   o.fixture = lp.newFixture (o.body, o.shape)
   
   return o
end

function Entity:draw ()
   -- current x y
   local cx, cy = self:get_coords()
   
   lg.setColor ({ 255, 255, 255, 255 })
   lg.circle ('fill', cx, cy, self.r)

   if self.selected
   then
      lg.setColor ({100, 255, 100, 120})
      lg.circle ('line', cx, cy, self.r +2)
   end

   lg.setColor ({ 255, 255, 255, 255 })
end

-- simple point a to point b movement
-- returns boolean for if the goal is reached
function Entity:move (gx, gy, init)
   
   -- current x y
   local cx, cy = self:get_coords()
   
   if init then
      self.move_vec = self:prep_move (gx, gy)
      init = false
   end
   
   local delta_x, delta_y = cx - gx, cy - gy
   local abs_delta_x, abs_delta_y = math.abs (delta_x), math.abs (delta_y)

   if abs_delta_x >= self.move_vec.x then
      self.body:setX (cx + self.move_vec.x)
   end

   if abs_delta_y >= self.move_vec.y then
      self.body:setY (cy + self.move_vec.y)
   end

   if math.abs (cx - gx) < self.speed and math.abs (cy -gy) < self.speed then
      self.body:setX (gx)
      self.body:setY (gy)

      return true
   end
   
   return false -- still moving

end

function Entity:prep_move (gx, gy)

   -- current x y
   local cx, cy = self:get_coords()
   
   local move_vec = { x = gx - cx, y = gy - cy }
   local length   = math.sqrt (move_vec.x ^2 + move_vec.y ^2)

   -- normalize move vector and add entity speed
   move_vec = { x = move_vec.x / length, y = move_vec.y / length }
   move_vec = { x = move_vec.x * self.speed, y = move_vec.y * self.speed }

   return move_vec
   
end

function Entity:get_coords ()

   return self.body:getX(), self.body:getY()
   
end

return Entity
