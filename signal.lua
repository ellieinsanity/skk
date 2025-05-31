-- thread/connection handler
local localThreads = (getgenv().hasName) and getgenv()[hasName] or threads
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
		table.insert(localThreads, connOrThread) 
	end
	if (tbl) then 
		table.insert(localThreads, tbl) 
	end
end
local function stopSignal(name)
	for i,v in localThreads do
		if (typeof(v) == "table" and v.name == name) then
			warn(v)
			stopThread(v)
		end
	end
end

if (localThreads) then
	for _,v in localThreads do
		stopThread(v)
	end
end
if (not getgenv().hasName) then
	getgenv().threads = {}
end

return { stopThread = stopThread, stopSignal = stopSignal, createSignal = createSignal }
