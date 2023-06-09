local skynet = require "skynet.manager"
local assert = assert
local ipairs = ipairs
local table = table

local g_module_id_list_map = {}

local CMD = {}

function CMD.load_module(module_name,launch_num)
	assert(module_name,'not module_name')
	assert(launch_num and launch_num > 0,"launch_num err")

	local id_list = {}
	for i = 1,launch_num do
		local server_id = skynet.newservice('hot_container',module_name)
		skynet.call(server_id,'lua','start')
		table.insert(id_list,server_id)
	end

	local old_id_list = g_module_id_list_map[module_name] or {}
	for _,id in ipairs(old_id_list) do
		skynet.send(id,'lua','exit')
	end

	g_module_id_list_map[module_name] = id_list

	return id_list
end

function CMD.register(module_name,id_list)
	assert(module_name,'not module_name')

	local old_id_list = g_module_id_list_map[module_name] or {}
	for _,id in ipairs(old_id_list) do
		skynet.send('lua','exit',id_list)
	end
	g_module_id_list_map[module_name] = id_list
end

function CMD.query(module_name)
	assert(module_name,'not module_name')
	return g_module_id_list_map[module_name]
end

skynet.start(function()
	skynet.register('.contriner_mgr')
	skynet.dispatch('lua',function(session,source,cmd,...)
		local f = CMD[cmd]
		assert(f,'cmd no found :'..cmd)

		if session == 0 then
			f(...)
		else
			skynet.retpack(f(...))
		end
	end)
end)