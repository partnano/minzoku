local NetworkManager = {
   input_manager = nil,
   action_manager = nil,
   
   socket = require 'socket',
   conn = nil,

   address = 'localhost',
   port = 11111,

   updaterate = 0.1,
   start_time = nil,
   elapsed_time = nil,
   current_step = 0,

   last_update_time = nil
}

function NetworkManager:load ()
   self.conn = socket.udp()
   self.conn:settimeout(0)
   self.conn:setpeername(self.address, self.port)

   self.conn:send("auth")

   self.last_update_time = self.socket.gettime()
end

function NetworkManager:update_time ()
   -- elapsed time is for input / action management
   if self.start_time then
      self.elapsed_time = self.socket.gettime() - self.start_time
   end

end

function NetworkManager:update_server ()
   local inputs = self.input_manager.inputs_to_send

   if client_id and #inputs > 0 then

      -- time diff via socket time
      -- NOTE: networking should only use sockettime
      local now = self.socket.gettime()
      if now - self.last_update_time > self.updaterate then

	 for _, input in pairs (inputs) do
	    --print(packer.to_string(input))
	    print("sending...", now - self.last_update_time,
		  self.updaterate, input.serial)
	    
	    self.conn:send (packer.to_string(input))
	 end
	 
	 self.last_update_time = now
      end
   end
end

function NetworkManager:quit ()

   local msg = packer.to_string ({ packet_type = 'quit' })
   self.conn:send (msg)
   
end

function NetworkManager:receive ()

   repeat
      local data, msg = self.conn:receive()

      if data then
	 rec_data = packer.to_table (data)

	 -- NOTE: debug
	 -- print("\n---- rec_data")
	 -- packer.print_table(rec_data)
	 -- print("---- \n")
	 
	 if rec_data.cmd == 'auth' then
	    self.start_time   = self.socket.gettime()
	    self.elapsed_time = 0

	    local id = tonumber (rec_data.id)

	    if id then
	       client_id = id
	       print ("Successfully authenticated, start time: " .. self.start_time,
		      "id: " .. client_id)

	       local msg = { packet_type = 'ack',
			     ack_type    = 'auth',
			     client_id   = client_id }

	       self.conn:send (packer.to_string (msg))
	       
	    else
	       error ("Authentication id faulty!")
	    end
            
	 elseif rec_data.cmd == 'ack' then

	    local s = tonumber (rec_data.serial)
	    if s then self.input_manager:remove_input_to_send (s) end

	 elseif rec_data.cmd == 'step' then

	    local old_step = self.current_step
	    
	    local t = tonumber(rec_data.step)
	    if t then self.current_step = t end

	    print ("- Step " .. self.current_step .. " -\n")
	    
	    self.action_manager:step (self.current_step - old_step)
	    
	 elseif rec_data.cmd == 'actions' then
	    
	    if rec_data.inputs and rec_data.serial then

	       -- NOTE: debug
	       print("-- BEGIN RECEIVED ACTIONS")
	       for id, input in pairs(rec_data.inputs) do
		  print("Client " .. input.client_id,
			"#" .. input.serial,
			"Supposed Step: " .. input.exec_step,
			"Command: " .. input.cmd)
	       end
	       print("-- END RECEIVED ACTIONS\n")
	       -- NOTE: debug end

	       local msg = { packet_type = 'ack',
			     ack_type    = 'actions',
			     serial      = rec_data.serial,
			     client_id   = client_id }
	       
	       self.conn:send (packer.to_string (msg))

	       for _, input in pairs (rec_data.inputs) do
		  table.insert (self.action_manager.actions, input)
	       end
	    end

	 elseif rec_data.cmd == 'quit' then
	    love.event.quit()
	    
	 else
	    print("Unknown command: ", data.cmd)
	 end

      elseif msg ~= 'timeout' then
	 error("Network error: " .. tostring(msg))
      end

      ::cont::
   until not data

end

return NetworkManager
