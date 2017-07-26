-- globals
lg = love.graphics
lt = love.timer

client_id = nil

-- general libs
packer = require 'libs.packer'

-- managers
local input_manager = require 'src.input_manager'
local network_manager = require 'src.network_manager'

function love.load ()
   input_manager.network_manager = network_manager
   network_manager.input_manager = input_manager
   
   network_manager:load()
end

function love.mousepressed (x, y, button)
   input_manager:mousepressed(x, y, button)
end

function love.mousereleased (x, y, button)
   input_manager:mousereleased(x, y, button)
end

function love.keypressed (key, scancode, isrepeat)
   input_manager:keypressed(x, y, button)
end

function love.keyreleased (key, scancode)
   input_manager:keyreleased(x, y, button)
end

function love.update (dt)

   -- update elapsed time
   network_manager:update_time()
   
   -- send stuff
   network_manager:update_server()

   -- receive stuff
   network_manager:receive()
   
end

function love.draw () 
   lg.print("FPS: " .. lt.getFPS(), 10, 10)
end
