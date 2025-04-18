-- thread/connection handler
local function stopThread(thread)
	if (typeof(thread) == "table") then
		return stopThread(thread.thread)
	end
	if (typeof(thread) == "thread") then
		return task.cancel(thread)
	else
		thread:Disconnect()
	end
end
local function createSignal(connOrThread, name)
	local tbl
	if (name) then
		tbl = { name = name, thread = connOrThread }
	else
		table.insert(threads, connOrThread)
	end
	if (tbl) then table.insert(threads, tbl) end
end
local function stopSignal(name)
	for i,v in threads do
		if (typeof(v) == "table" and v.name == name) then
			warn(v)
			stopThread(v)
		end
	end
end

if (threads) then
	for _,v in threads do
		stopThread(v)
	end
end
getgenv().threads = {}

return { stopThread = stopThread, stopSignal = stopSignal, createSignal = createSignal }
