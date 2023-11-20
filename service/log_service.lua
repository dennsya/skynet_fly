local skynet = require "skynet"
local skynet_util = require "skynet_util"
local file_util = require "file_util"
require "skynet.manager"

local os = os
local io = io
local error = error
local assert = assert
local print = print
local string = string
local type = type
local table = table

local SELF_ADDRESS = skynet.self()

local file = nil
local file_path = skynet.getenv('logpath')
local file_name = skynet.getenv('logfilename')
local daemon = skynet.getenv('daemon')
local hook_hander_list = {}

local function open_file()
    if not daemon then
        return
    end
    if file then
        file:close()
    end
    print(file_path,file_name)
    os.execute('mkdir -p ' .. file_path)
    if not os.execute("mkdir -p " .. file_path) then
        error("create dir err")
    end
    local file_p = file_util.path_join(file_path,file_name)
    file = io.open(file_p, 'a+')
    assert(file, "can`t open file " .. file_p)
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
        if file then
            file:write(msg .. '\n')
            file:flush()
        else
            print(msg)
        end

        if address ~= SELF_ADDRESS then
            for i = 1,#hook_hander_list do
                hook_hander_list[i](msg)
            end
        end
	end
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function()
		-- reopen signal
        open_file()
	end
}

local CMD = {}

function CMD.add_hook(file_name)
    local func = require(file_name)
    assert(type(func) == 'function', "err file " .. file_name)
    table.insert(hook_hander_list, func)
    return true
end

skynet.start(function()
    open_file()
    skynet_util.lua_dispatch(CMD,{})
end)