getgenv().hasName = "adminThreads"

local skkVersion = "0.53"
local start = tick()

local players = game:GetService("Players")
local coreGui = game:GetService("CoreGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local robloxReplicated = game:GetService("RobloxReplicatedStorage")
local runService = game:GetService("RunService")
local textChatService = game:GetService("TextChatService")
local uis = game:GetService("UserInputService")
local teleportService = game:GetService("TeleportService")
local tweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera

local chatEvents = replicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")

local textChannels = textChatService:FindFirstChild("TextChannels")
local rbxGeneral = (textChannels and textChannels:FindFirstChild("RBXGeneral"))

local localPlayer = players.LocalPlayer
-- tables
local api = {}
local tables = {
	whiteListed = {},
	commands = {},
	settings = {
		flySpeed = 15,
		prefix = ".",
		keyPrefix = Enum.KeyCode.Semicolon,
	},
	toggles = {},
}
-- check if any script had reexecute before.
if (getgenv().onReexecute) then
    getgenv().onReexecute()
    getgenv().onReexecute = nil
end
-- load gui
if (coreGui:FindFirstChild("superfehacks")) then
	coreGui.superfehacks:Destroy()
end
local gui = loadstring(game:HttpGet("https://raw.githubusercontent.com/ellieinsanity/skk/refs/heads/main/gui.luau"))()
gui.Name = "superfehacks"
gui.DisplayOrder = 9e9
-- thread/connection handler
local function stopThread(thread)
    warn("STOPPING!!!")
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
    warn("CREATING!!!")
	local tbl
	if (name) then
		warn("creating signal with name", name)
		tbl = { name = name, thread = connOrThread }
	else
		table.insert(threads, connOrThread)
	end
	if (tbl) then table.insert(threads, tbl) end
end
local function stopSignal(input)
	for i,v in threads do
	    if (typeof(v) == "table") and (v.name == input) then
			stopThread(v)
		elseif (v == input) then
		    stopThread(v)
		end
	end
end
local function findSignal(name)
	for i,v in threads do
		if (typeof(v) == "table" and v.name == name) then
			return v
		end
	end
end

if (getgenv().threads) then
	for _,v in getgenv().threads do
		stopThread(v)
	end
end
getgenv().threads = {}
-- hooks
local function unHookMethod(object, type)
	if (not savedHooks[object]) then
		return
	end
	local metatable = getrawmetatable(object)
	metatable[type] = savedHooks[object][type]
end
local function hookMethod(object, type, funct)
	local metatable = getrawmetatable(object)
	setreadonly(metatable, false)
	local oldFunct = metatable[type]
	metatable[type] = funct
	if (not savedHooks[object]) then
		savedHooks[object] = {}
	end
	savedHooks[object][type] = oldFunct
	--setreadonly(metatable, true)
	return oldFunct
end
if (getgenv().savedHooks) then
	for object, info in savedHooks do for i,v in info do unHookMethod(object, i) end end
	--for object, info in savedHFuncts do for i,v in info do unHookFunct(object, i) end end
end
getgenv().savedHooks = {}
-- fly (stolen from toolbox idc making my own lmao)
local velocity = Instance.new("BodyVelocity")
local gyro = Instance.new("BodyGyro")
local flying, wasFlying = false, false
local toggleFly
local function stopFly()
	wasFlying = false
	flying = false
	velocity.Parent = nil
	gyro.Parent = nil
	stopSignal("flySignal")
end
-- character added
if (getgenv().characterAdded) then
	getgenv().characterAdded:Destroy()
	getgenv().characterAdded = nil
end
local character, humanoid, rootPart
local function characterAdded(c)
	character = c
	humanoid = c:WaitForChild("Humanoid")
	rootPart = humanoid.RootPart
	if (humanoid.RigType.Name == "R15") then
		for _,v in character:WaitForChild("Animate"):getChildren() do
			--v:Destroy()
		end
	end
	local was = wasFlying
	warn(was)
	stopFly()
	if (was) then
		warn("toggling fly")
		toggleFly()
	else
		warn("wasnt ever on")
	end
	createSignal(humanoid.Died:connect(function()
		if (flying) then
			stopFly()
			wasFlying = true
		end
	end))
	if (api.characterAdded) then
		getgenv().characterAdded = api.characterAdded
		api.characterAdded:Fire(character, humanoid, rootPart)
	end
	warn("character added")
end
createSignal(localPlayer.CharacterAdded:connect(characterAdded))
if (localPlayer.Character) then
	task.defer(characterAdded, localPlayer.Character)
end
-- setup gyro&velocity
velocity.MaxForce = Vector3.new(1e8, 1e8, 1e8)
velocity.P = 2e4
gyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
gyro.D = 500
gyro.P = 3000
-- fly functs
local function convertCam()
	if (humanoid.MoveDirection == Vector3.zero) then
		return Vector3.zero
	end
	local ret = (camera.CFrame * CFrame.new((CFrame.new(camera.CFrame.p, camera.CFrame.p + Vector3.new(camera.CFrame.lookVector.x, 0, camera.CFrame.lookVector.z)):VectorToObjectSpace(humanoid.MoveDirection)))).p - camera.CFrame.p;
	if (ret == Vector3.zero) then
		return ret
	end
	return ret.unit
end
toggleFly = function()
	flying = not flying
	for _,state in {"Running", "GettingUp", "FallingDown", "Climbing"} do
		humanoid:SetStateEnabled(state, not flying)
	end
	if (flying and character.PrimaryPart) then
		wasFlying = true
		if (humanoid.SeatPart) then
			gyro.Parent = humanoid.SeatPart
			velocity.Parent = humanoid.SeatPart
		else
			gyro.Parent = character.PrimaryPart
			velocity.Parent = character.PrimaryPart
		end

		api.createSignal(runService.PreRender:connect(function()
			--humanoid:ChangeState(6)
			gyro.CFrame = camera.CFrame
			tweenService:Create(velocity, TweenInfo.new(0.3), { Velocity = convertCam() * (tables.settings.flySpeed*10) }):Play()
		end), "flySignal")
	else
		stopFly()
	end
end
-- important functions
local function compString(...)
	local t = {...}
	local c = ""
	for _,v in t do
		c = c..tostring(v).." "
	end
	return c:sub(0, -2)
end
local function findPlayer(player, text)
	if (api.teams and api.teams[text]) then
		return api.teams[text]:GetPlayers()
	end
	if (text == "me") or (not text) or (text == "") then return {player} end
	if (text == "all" or text == "others") then
		local allPlayers = players:GetPlayers()
		if (text == "others") then
			table.remove(allPlayers, table.find(allPlayers, player))
		end
		return allPlayers
	end
	local targets = {}
	for _,v in players:GetPlayers() do
		if (v.Name:lower():find(text) or v.DisplayName:lower():find(text)) then
			table.insert(targets, v)
		end
	end
	return targets
end
local function generateString(amount)
	local str = ""
	for i = 1, amount or 1 do
		str = str..string.char(math.floor(Random.new():NextNumber(("!"):byte(),("z"):byte())))
	end
	return str
end
local function chat(message)
	if (rbxGeneral) then
		return task.spawn(rbxGeneral.SendAsync, rbxGeneral, message)
	end
	chatEvents.SayMessageRequest:FireServer(message, "All")
end
getgenv().chat = chat

local function validCharacter(m, ff)
	return m and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m.PrimaryPart
end
local function getClosestTo(pos, mag)
	local found = {}
	for i,v in players:GetPlayers() do
		if (v ~= localPlayer) and (validCharacter(v.Character) and (v.Character.PrimaryPart.Position - pos).magnitude <= mag) then
			table.insert(found, v)
		end
	end
	return found
end
local function stealTool(tool)
	if (tool.Parent:FindFirstChildWhichIsA("Humanoid")) then
		return false
	end
	tool.Parent = workspace.Terrain
	humanoid:EquipTool(tool)
	tool:GetPropertyChangedSignal("Parent"):Wait()
	tool.Parent = localPlayer.Backpack
end
local function resetVelocity(model)
	for i,v in pairs(model:GetDescendants()) do
		if (v:IsA("BasePart")) then
			v.AssemblyLinearVelocity = Vector3.new()
			v.AssemblyAngularVelocity = Vector3.new()
		end
	end
end
-- command handler
local mainFrame, logFrame = gui:WaitForChild("main"), gui:WaitForChild("logs")
local suggest = mainFrame.suggest
local textBox = mainFrame.innerCmd.TextBox
local template = logFrame.template:Clone()

local commandCount = 0
local function addCommand(name, funct, settings)
	commandCount += 1
	local template = template:Clone()
	local tbl = { funct = funct or function() end, settings = settings, commandNum = commandCount, label = template }
	if (not tbl.settings) then tbl.settings = {} end
	template.Text = ("%d. %s"):format(commandCount, name)
	template.Parent = suggest
	suggest.CanvasSize = UDim2.fromOffset(0, suggest.UIListLayout.AbsoluteContentSize.Y)
	tables.commands[tostring(name)] = tbl
end
local function addToggle(name, funct, settings)
	if (typeof(funct or CFrame.new) == "table") then
		settings = funct
		funct = nil
	end
	tables.toggles[name] = {}
	local tbl = tables.toggles[name]
	if (not settings) then settings = {} end
	if (settings and settings.on) then
		tables.toggles[name][localPlayer] = true
	end
	local realName = (settings and settings.name or name)
	addCommand(name:lower(), function(context, ...)
		if (not tbl[context.player]) then
			tbl[context.player] = false
		end
		tbl[context.player] = not tbl[context.player]
		addLog(("%s is now %s"):format(realName, tbl[context.player] and "on" or "off"), Color3.new(0, 1, 0))
		local context = table.clone(context)
		context.on = tbl[context.player]
		if (funct) then funct(context, ...) end
	end, settings)
end
local function toggleOn(name, player)
	if (not player) then
		player = localPlayer
	end
	return tables.toggles[name][player]
end
local function addThreadCommand(name, funct, settings)
	local thread
	tables.toggles[name] = {}
	tables.toggles[name][localPlayer] = false
	addToggle(name:lower(), function(context, ...)
		if (context.on) then
			tables.toggles[name][context.player] = true
			thread = task.spawn(funct, context, ...)
			createSignal(thread)
		else
			tables.toggles[name][context.player] = false
			task.cancel(thread)
		end
	end, settings)
end
local function addPlayerCommand(name, funct, settings)
    addCommand(name, function(context, target, ...)
	    local targets = findPlayer(context.player, target)
		if (#targets <= 0) then
		    return addLog("no player found", Color3.new(1, 0, 0))
		end
		for _,v in targets do
			local suc, ret = pcall(function()
			    funct(context, v)
			end)
			if (not suc) then warn(ret) end
		end
	end, settings)
end
local function findCommand(name)
	local command = tables.commands[name]
	if (not command) then
		for i,v in tables.commands do
			if (table.find(v.settings.aliases or {}, name)) then
				command = v
				break
			end
		end
	end
	return command
end
local function executeCommand(player, text)
	if (text:sub(1, 1) ~= tables.settings.prefix) then
		return
	end
	text = text:lower()
	local split = text:split(" ")
	local commandName = split[1]:sub(#tables.settings.prefix+1)
	table.remove(split, 1)
	local context = {
		player = player,
		character = player.Character,
	}

	local command = findCommand(commandName)
	if (not command) then
		return addLog("command not found", Color3.new(1, 0, 0))
	end

	task.spawn(function()
		local succ, err = pcall(function()
			command.funct(context, table.unpack(split))
		end)
		if (err) then
			addLog("error happened while executing", Color3.new(1, 0, 0))
			warn(err)
		end
	end)
end
-- gui handler
local inputFocused, currentMatched = false, nil
template.Size = UDim2.new(1, 0, 0, 20)
logFrame.template.RichText = true
logFrame.template.Parent = nil
Instance.new("UIListLayout", logFrame)
Instance.new("UIListLayout", suggest)
function addLog(...)
    setthreadidentity(7)
	local args = {...}
	local str = compString(...)
	local colorArg = args[#args]
	if (typeof(colorArg) ~= "Color3") then
		colorArg = Color3.new(1, 1, 1)
	else
		args[#args] = nil
		str = compString(table.unpack(args))
	end
	local template = template:Clone()
	--template.TextTruncate = "None"
	template.TextColor3 = colorArg
	template.Text = str
	template.Parent = logFrame
	logFrame.CanvasSize = UDim2.fromOffset(0, logFrame.UIListLayout.AbsoluteContentSize.Y)
	logFrame.CanvasPosition = Vector2.new(0, 9e9)
end
local function focusBar()
	inputFocused = true
	textBox:CaptureFocus()
	textBox:GetPropertyChangedSignal("Text"):Wait()
	textBox.Text = ""
end
local function matches(text, name, info)
	local matched = name:match(text)
	if (not matched and info.settings.aliases) then
		for _,v in info.settings.aliases do
			if (v:match(text)) then
				matched = name
				break
			end
		end
	end
	return matched
end
local function autoComplete()
end
createSignal(textBox.FocusLost:connect(function(enter)
	inputFocused = false
	if (not enter) then return end
	executeCommand(localPlayer, tables.settings.prefix..textBox.Text)
	textBox.Text = ""
end))
createSignal(textBox:GetPropertyChangedSignal("Text"):connect(function()
	local text = textBox.Text:split(" ")[1]
	local matched
	suggest.CanvasPosition = Vector2.new()
	for name, info in tables.commands do
		local localMatched = matches(text, name, info)
		info.label.Visible = localMatched
		if (info.label.Visible) then
			currentMatched = localMatched
		end
	end
end))
createSignal(uis.InputBegan:connect(function(key, gpe)
	if (key.KeyCode == Enum.KeyCode.Tab and inputFocused) then
		--warn("tab pressed")
		return autoComplete()
	end
	if (key.KeyCode == tables.settings.keyPrefix and not gpe) then
		focusBar()
	end
end))
-- commands
addCommand("fly", function()
	toggleFly()
end)
addCommand("flyspeed", function(context, ...)
	tables.settings.flySpeed = tonumber(...)
end)
addToggle("noclip", function(context)
	if (not context.on) then
		return api.stopSignal("noclip")
	end
	api.createSignal(runService.RenderStepped:connect(function()
		for _,part in localPlayer.Character:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end), "noclip")
end)
addCommand("loseownership", function(context)
	character:PivotTo(CFrame.new(0, workspace.FallenPartsDestroyHeight, 0))
end)
addCommand("goto", function(context, targets)
	for _,v in findPlayer(context.player, targets) do
		character:PivotTo(v.Character:GetPivot())
	end
end, { aliases = {"to"} })
addCommand("respawn", function(context)
	api.respawn()
end)
addCommand("core", function(context, type)
	for _,v in Enum.CoreGuiType:GetEnumItems() do
		if (type:lower():match(v.Name:lower())) then

		end
	end
end)
addCommand("spam", function(context, ...)
	for i = 1, (chatEvents and 10 or 30) do
		local letter = generateString(1)
		chat(("%s (%s)"):format(..., letter))
	end
end)
addCommand("oldr15", function()
	character.Animate:ClearAllChildren()
end)
addCommand("rejoin", function(context)
	-- before you ask "who hosts on port 90" I DO !!!
	if (getgenv().scriptName) then
		queueonteleport(([[repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet("http://192.168.1.220:90/SelfGames/%s.lua"))()]]):format(getgenv().scriptName))
	else
		queueonteleport([[repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet("https://raw.githubusercontent.com/ellieinsanity/skk/refs/heads/main/admin.lua"))()]])
	end
	teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
end, { aliases = {"rj"} })

local function startTouchFling()
	api.createSignal(task.spawn(function()
		while true do
			if (humanoid and humanoid.Health > 0 and rootPart and character) then
				local vel = rootPart.Velocity
				rootPart.Velocity = vel * 99e9 + Vector3.new(99e9, 99e9, 99e9)
				runService.RenderStepped:wait()
				rootPart.Velocity = vel
				runService.Stepped:wait()
				rootPart.Velocity = vel + Vector3.new(0, 0.1, 0)
			end
			task.wait()
		end
	end), "touchFling")
end
local function touchFlingAction(context)
	local saved = localPlayer.Character:GetPivot()
	task.delay(0.1, resetVelocity, localPlayer.Character)
	task.delay(0.1, localPlayer.Character.PivotTo, localPlayer.Character, saved)
	startTouchFling()
end
addToggle("touchfling", function(context)
	if (context.on) then
		touchFlingAction(context)
	else
		api.stopSignal("touchFling")
		local saved = localPlayer.Character:GetPivot()
		repeat runService.PreRender:wait()
			resetVelocity(localPlayer.Character)
			localPlayer.Character:PivotTo(saved)
		until (character.PrimaryPart.Position - saved.p).magnitude <= 20
	end
end, { aliases = {"tf"} })
addPlayerCommand("view", function(context, player)
	addLog(("viewing %s"):format(player.Name))
	createSignal(task.spawn(function()
		while task.wait() do
			if (player.Character) then
				local humanoid = player.Character:FindFirstChild("Humanoid")
				if (humanoid) and (player.Character.PrimaryPart) then
					camera.CameraSubject = player.Character.Humanoid
				else
					local hat = player.Character:FindFirstChildWhichIsA("Accoutrement")
					if (hat) and (hat:FindFirstChild("Handle")) then
						camera.CameraSubject = hat.Handle
					end
				end
			end
		end
	end), "viewingSignal")
	createSignal(players.PlayerRemoving:connect(function(t)
		if (player == t) then
			stopSignal("viewingSignal")
			camera.CameraSubject = humanoid
			stopSignal("viewingRemovalSignal")
			addLog("player left")
		end
	end), "viewingRemovalSignal")
end)
addCommand("unview", function(context)
	stopSignal("viewingSignal")
	camera.CameraSubject = humanoid
	stopSignal("viewingRemovalSignal")
end)
addCommand("hipheight", function(context, num)
	humanoid.HipHeight = tonumber(num)
end, { aliases = {"hh"} })
addCommand("walkspeed", function(context, speed)
	if (not speed) then
		speed = 16
	end
	humanoid.WalkSpeed = tonumber(speed) or 16
end, { aliases = {"speed", "ws"} })
addThreadCommand("follow", function(context, target)
	local player = findPlayer(context.player, target)[1]
	if (not player) then return addLog("player not found") end
	while task.wait() do
		humanoid:MoveTo(player.Character:GetPivot().p)
	end
end)
addCommand("goposition", function(context, x, y, z)
	character:PivotTo(CFrame.new(tonumber(x), tonumber(y), tonumber(z)))
end, { aliases = {"pos", "gotopos"} })

local function deleteTool(tool)
	task.spawn(function()
		if (humanoid.RigType.Name == "R15") then
			grip = character.RightHand.ChildAdded:wait()
		else
			grip = character["Right Arm"].ChildAdded:wait()
		end
		grip.Part0 = nil
	end)
	tool.Parent = character
	local grip
	repeat task.wait() until tool.Parent == nil
end

addCommand("god", function()
	humanoid:SetStateEnabled("Dead", false)
	replicatesignal(localPlayer.Kill)
end)
addCommand("deletetool", function()
	local tool = character:FindFirstChildWhichIsA("Tool")
	if (not tool) then
		return addLog("no tool found. equip the tool.")
	end
	tool.Parent = localPlayer.Backpack
	deleteTool(tool)
end, { aliases = {"deltool"} })
addCommand("deletetools", function()
	for _,tool in localPlayer.Backpack:GetChildren() do
		if tool:IsA("Tool") then
			if tool:FindFirstChildWhichIsA("LocalScript") then
				tool:FindFirstChildWhichIsA("LocalScript").Disabled = true
			end
			tool.Parent = localPlayer.Character
			for _,grip in localPlayer.Character:GetDescendants() do
				if (grip.Name == "RightGrip" and grip:IsA("Weld")) then
					grip.Part0 = nil
				end
			end
		end
	end
end)

addToggle("spin", function(context, amount)
	local amount = tonumber(amount) or 10
	if (context.on) then
		local bav = Instance.new("BodyAngularVelocity")
		bav.Parent = character.PrimaryPart
		bav.P = math.huge
		bav.AngularVelocity = Vector3.new(amount, amount, amount)
		bav.MaxTorque = Vector3.new(0, math.huge, 0)
	else
		local bav = character.PrimaryPart:findFirstChild("BodyAngularVelocity")
		if (bav) then bav:Destroy() end
	end
end)
addCommand("motor", function()
	local pos = character:GetPivot()
	localPlayer.Character:BreakJoints()
	localPlayer.CharacterAdded:wait()
	local character = localPlayer.Character
	character:WaitForChild("Animate").Disabled = true
	task.wait(localPlayer:GetNetworkPing()*4.5)
	character:PivotTo(pos)
	api.createSignal(task.spawn(function()
		while runService.PreRender:wait() do
			character:PivotTo(character:GetPivot()*CFrame.Angles(math.rad(0.005), 0, 0))
			runService.PreRender:wait()
			character:PivotTo(character:GetPivot()*CFrame.Angles(math.rad(-0.005), 0, 0))
		end
	end), "reAnim")
	api.createSignal(character.Humanoid.Died:connect(function()
		api.stopSignal("reAnim")
	end))
end)

--[[
addCommand("stealtools", function(context, ...)
	if (not ...) then
		for i,v in next,players:GetPlayers() do
			if (v:FindFirstChild("Backpack")) then
				for i2, v2 in v.Backpack:GetChildren() do stealTool(v2) end
			end
		end
	else
		for i,v in api.findPlayer(context.player, ...) do
			if (v:FindFirstChild("Backpack")) then
				for i2, v2 in v.Backpack:GetChildren() do stealTool(v2) end
			end
		end
	end
end)
--]]
addCommand("explorer", function()
	 loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)
-- duping tools
-- anti fling
createSignal(runService.RenderStepped:connect(function()
	for _,player in pairs(players:GetPlayers()) do
		if (player.Character and player.Character ~= character) then
			for _,part in pairs({"Head", "Torso", "HumanoidRootPart"}) do
				local part = player.Character:FindFirstChild(part)
				if (part) and (part:IsA("BasePart")) then
					part.AssemblyLinearVelocity = Vector3.new()
					part.AssemblyAngularVelocity = Vector3.new()
				end
			end
		end
	end
end))

local deb = 0
createSignal(localPlayer.Chatted:connect(function(message)
	if (message:sub(1, 1) ~= tables.settings.prefix) or (tick() - deb) < 1 then
		return
	end
	deb = tick()
	executeCommand(localPlayer, message)
end))
-- for motor 6d shit
-- init
addLog(("loaded skk v%.1f"):format(skkVersion), Color3.new(0, 1, 0))
addLog("took "..tick()-start.."s")
-- return api
api.addLog = addLog
api.executeCommand = executeCommand
api.createSignal = createSignal
api.addCommand = addCommand
api.addToggle = addToggle
api.addThreadCommand = addThreadCommand
api.addPlayerCommand = addPlayerCommand

api.compString = compString
api.findPlayer = findPlayer
api.respawn = function(context)
	local saved = character:GetPivot()
	replicatesignal(humanoid.ServerBreakJoints)
	--character:BreakJoints()
	localPlayer.CharacterAdded:wait()
	task.wait(localPlayer:GetNetworkPing()*4.5)
	character:PivotTo(saved)
end
api.getClosestTo = getClosestTo
api.toggleOn = toggleOn
api.tables = tables
api.validCharacter = validCharacter
api.generateString = generateString
api.stopSignal = stopSignal
api.findSignal = findSignal
api.chat = chat
api.startTouchFling = startTouchFling

api.unHookMethod = unHookMethod
api.hookMethod = hookMethod

return api
