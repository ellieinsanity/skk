local RunService = game:GetService("RunService")

local Animator = {}
Animator.__index = Animator

local AnimationMode = {
	Transform = 0,
	C0 = 1,
	Combined = 2
}

local AnimationTrack
do
	local TweenService = game:GetService("TweenService")
	local Signal
	do
		Signal = {}
		local Connection = {}
		Signal.__index = Signal
		Connection.__index = Connection

		Signal.__tostring = function(self)
			if self._name then
				return `Signal {self._name}`
			end
			return "Signal"
		end

		Connection.__tostring = function()
			return "RBXScriptConnection"
		end

		function Connection:Disconnect()
			self.Connected = false
			table.remove(self._parent._connections, table.find(self._parent._connections, self))
		end

		Connection.disconnect = Connection.Disconnect

		function Connection.new(parent, callback)
			local self = setmetatable({}, Connection)
			self.Connected = true
			self._callback = callback
			self._parent = parent
			self._once = false
			table.insert(parent._connections, self)
			return self
		end

		function Signal:Connect(callback)
			assert(type(callback) == "function", "callback must be a function")
			return Connection.new(self, callback)
		end

		function Signal:Once(callback)
			assert(type(callback) == "function", "callback must be a function")
			local connection = Connection.new(self, callback)
			connection._once = true
			return callback
		end

		function Signal:Wait()
			local thread = coroutine.running()
			table.insert(self._waitingThreads, thread)
			return coroutine.yield()
		end

		function Signal:Fire(...)
			for _, connection in self._connections do
				coroutine.wrap(connection._callback)(...)
				if connection._once then
					connection:Disconnect()
				end
			end
			for _, thread in self._waitingThreads do
				coroutine.resume(thread, ...)
			end
			table.clear(self._waitingThreads)
		end

		function Signal:Destroy()
			for _, connection in self._connections do
				connection:Disconnect()
			end
			for _, thread in self._waitingThreads do
				coroutine.resume(thread)
			end
			table.clear(self._waitingThreads)
		end

		function Signal.new(name)
			local self = setmetatable({}, Signal)
			self._waitingThreads = {}
			self._connections = {}
			self._name = name
			return self
		end
	end
	local getLerpAlpha
	do
		local round = math.round
		local getValue = TweenService.GetValue
		local easingDirections = Enum.EasingDirection:GetEnumItems()

		local easingFuncs = {}

		for _, poseEasingStyle in Enum.PoseEasingStyle:GetEnumItems() do
			if poseEasingStyle == Enum.PoseEasingStyle.Constant then
				continue
			end
			local directions = {}
			local easingStyle
			if (poseEasingStyle.Name == "CubicV2") then
				easingStyle = Enum.EasingStyle.Cubic
			else
				easingStyle = Enum.EasingStyle[poseEasingStyle.Name]
			end
			for _, direction in easingDirections do

				directions[direction.Value] = function(a)
					return getValue(TweenService, a, easingStyle, direction)
				end
			end
			easingFuncs[poseEasingStyle.Value] = directions
		end

		easingFuncs[Enum.PoseEasingStyle.Constant.Value] = {
			[0] = round,
			[1] = round,
			[2] = round,
		}

		getLerpAlpha = function(a, poseEasingStyleValue, poseEasingDirectionValue)
			return easingFuncs[poseEasingStyleValue][poseEasingDirectionValue](a)
		end
	end

	AnimationTrack = {}
	AnimationTrack.__index = AnimationTrack

	function AnimationTrack:AdjustSpeed(speed)
		self.Speed = speed
	end

	function AnimationTrack:AdjustWeight(weight, fadeTime)
		self.Weight = weight
	end

	function AnimationTrack:GetMarkerReachedSignal(name)
		local event = self._markerReachedSignals[name]
		if not event then
			event = Signal.new("MarkerReached")
			self._markerReachedSignals[name] = event
		end
		return event
	end
	function AnimationTrack:GetTimeOfKeyframe(keyframeName)
		return self._keyframeTimes[keyframeName] or error("ХЗ")
	end

	local DEFAULT_POSE = {
		Time = 0,
		CFrame = CFrame.identity,
		EasingDirection = Enum.PoseEasingDirection.In.Value,
		EasingStyle = Enum.PoseEasingStyle.Linear.Value,
		Weight = 0
	}

	local clock = os.clock
	local min = math.min
	local tclear = table.clear
	local cframeIdentity = CFrame.identity

	function AnimationTrack:Play(fadeTime, weight, speed)

		fadeTime = fadeTime or 0.1
		speed = speed or 1
		self.Speed = speed

		local keyframes = self._keyframes
		local keyframeTimes = self._keyframeTimes
		local markerTimes = self._markerTimes
		local markerReachedSignals = self._markerReachedSignals
		local transforms = table.clone(self._parent._transforms)
		local jointNames = self._jointNames
		local passedKeyframes = {}
		local passedMarkers = {}

		local didLoopEvent = self.DidLoop
		local keyframeReachedEvent = self.KeyframeReached

		self._transforms = transforms

		local startTime = clock()
		local last = clock()
		local length = self.Length
		local timePosition = 0
		local lerpAlpha = 0

		local poseIndexes = {}
		local nextPoseIndexes = {}
		local lastPoses = {}
		local nextPoses = {}
		local jointNames = self._jointNames

		local function reset()
			for _, jointName in ipairs(jointNames) do
				lastPoses[jointName] = keyframes[jointName][1]
				nextPoses[jointName] = keyframes[jointName][2]
				poseIndexes[jointName] = 1
				nextPoseIndexes[jointName] = 2
			end
			tclear(passedKeyframes)
			tclear(passedMarkers)
		end

		self._startTime = startTime
		reset()
		local function step()
			debug.profilebegin("animationProcess")

			local now = clock()
			local weight = min((now - startTime)/fadeTime, 1)
			if length == 0 then
				for _, jointName in ipairs(jointNames) do
					local pose = keyframes[jointName][1]
					transforms[jointName] = pose and pose.CFrame or cframeIdentity
				end
				return transforms, weight
			end

			local delta = now - last
			last = now
			timePosition += delta*self.Speed
			lerpAlpha = min(lerpAlpha + delta, 1)

			if timePosition > length then
				if self.Looped then
					timePosition %= length
					tclear(passedKeyframes)
					tclear(passedMarkers)
					reset()
					didLoopEvent:Fire()
				else
					self.TimePosition = 0
					self:Stop(0.5)
					return
				end
			end
			self.TimePosition = timePosition

			for name, time in keyframeTimes do
				if passedKeyframes[name] then
					continue
				end
				if timePosition >= time then
					passedKeyframes[name] = true
					keyframeReachedEvent:Fire(name)
				end
			end
			for name, time in markerTimes do
				if passedMarkers[name] then
					continue
				end
				if timePosition >= time then
					passedMarkers[name] = true
					local event = markerReachedSignals[name]
					if event then
						event:Fire()
					end
				end
			end

			for _, jointName in ipairs(jointNames) do
				local poses = keyframes[jointName]
				if #poses == 0 then
					transforms[jointName] = cframeIdentity
					continue
				end

				local lastPose = lastPoses[jointName]
				local nextPose = nextPoses[jointName]
				local poseIdx = poseIndexes[jointName]
				local nextPoseIdx = nextPoseIndexes[jointName]
				local numPoses = #poses

				if nextPose and timePosition > nextPose.time then
					repeat
						poseIdx = nextPoseIdx
						nextPoseIdx += 1
					until not poses[nextPoseIdx] or poses[nextPoseIdx].time >= timePosition
					lastPose = poses[poseIdx]
					nextPose = poses[nextPoseIdx]
					lastPoses[jointName] = lastPose
					nextPoses[jointName] = nextPose
					poseIndexes[jointName] = poseIdx
					nextPoseIndexes[jointName] = nextPoseIdx
				end
				if not nextPose or lastPose == nextPose then
					transforms[jointName] = lastPose.cframe
				else
					local dt = (timePosition - lastPose.time)/(nextPose.time - lastPose.time)
					transforms[jointName] = lastPose.cframe:Lerp(nextPose.cframe, getLerpAlpha(dt, nextPose.easingStyle, nextPose.easingDirection))
				end
			end
			debug.profileend()
			return transforms, weight
		end
		self.IsPlaying = true
		self._step = step
	end

	function AnimationTrack:_fadeOut(fadeTime)
		local initCFrames = table.clone(self._transforms)
		local startTime = clock()
		local function step()
			local elapsed = clock() - startTime
			local newTransforms = {}
			local a = min(elapsed/fadeTime, 1)
			if a == 1 then
				self.Ended:Fire()
				self._step = nil
				return
			end
			for jointName, initCF in initCFrames do
				newTransforms[jointName] = initCF:Lerp(cframeIdentity, a)
			end
			self._transforms = newTransforms
			return {}, 1
		end
		self._step = step
	end

	function AnimationTrack:Stop(fadeTime)
		if not self.IsPlaying then
			return
		end
		fadeTime = fadeTime or 0.5
		self.IsPlaying = false
		self.Stopped:Fire()
		self._step = nil
		self._startTime = nil
		if fadeTime > 0 then
			self:_fadeOut(fadeTime)
		else
			self.Ended:Fire()
		end
	end

	function AnimationTrack.new(parent, keyframeSequence)
		local self = setmetatable({}, AnimationTrack)

		self.IsPlaying = false
		self.Length = 0
		self.Looped = keyframeSequence.Loop
		self.Speed = 1
		self.TimePosition = 0
		self.Priority = keyframeSequence.Priority

		self.Name = keyframeSequence.Name

		self.DidLoop = Signal.new("DidLoop")
		self.Ended = Signal.new("Ended")
		self.KeyframeReached = Signal.new("KeyframeReached")
		self.Stopped = Signal.new("Stopped")

		self._parent = parent
		self._keyframeSequence = keyframeSequence
		self._destroyed = false
		self._keyframes = {}
		self._keyframeTimes = {}
		self._markerTimes = {}
		self._jointNames = {}
		self._transforms = {}
		self._step = nil 

		self._markerReachedSignals = {}

		for _, keyframe in keyframeSequence:GetChildren() do
			self.Length = math.max(self.Length, keyframe.time)
			if keyframe.Name ~= "Keyframe" then
				self._keyframeTimes[keyframe.Name] = keyframe.time
			end
			for _, marker in keyframe:GetMarkers() do
				self._markerTimes[marker.Name] = keyframe.time
			end
			local rootPose = keyframe:FindFirstChild("HumanoidRootPart")
			if not rootPose then
				continue
			end
			for _, pose in rootPose:GetDescendants() do
				if not pose:IsA("Pose") or pose.Weight == 0 then
					continue
				end
				local keyframes = self._keyframes[pose.Name]
				if not keyframes then
					keyframes = {}
					self._keyframes[pose.Name] = keyframes
					self._transforms[pose.Name] = CFrame.identity
					table.insert(self._jointNames, pose.Name)
				end
				table.insert(keyframes, {
					time = keyframe.Time,
					cframe = pose.CFrame,
					easingDirection = pose.EasingDirection.Value,
					easingStyle = pose.EasingStyle.Value,
					weight = pose.Weight
				})
			end
		end


		for _, jointKeyframes in self._keyframes do
			table.sort(jointKeyframes, function(a, b)
				return a.time < b.time
			end)
			if self.Looped and #jointKeyframes > 1 then

				local first = table.clone(jointKeyframes[1])
				local last = table.clone(jointKeyframes[#jointKeyframes])
				first.time = self.Length + first.time
				last.time = last.time - self.Length
				table.insert(jointKeyframes, first)
				table.insert(jointKeyframes, 1, last)
			end
		end



		return self
	end


end
Animator.AnimationMode = AnimationMode

function Animator:LoadAnimation(keyframeSequence)

	local animations = self._animations
	for _, animation in ipairs(animations) do
		if animation._keyframeSequence == keyframeSequence then
			return animation
		end
	end
	local animation = AnimationTrack.new(self, keyframeSequence)
	table.insert(animations, animation)
	
	return animation
end

function Animator:GetPlayingAnimations()
	local animations = self._animations
	
	for key, _ in animations do
		return (animations[key].Name)
	end
	
end

function Animator:Destroy()
	self._destroyed = true
	for _, stopTracker in self._jointTrackers do
		stopTracker()
	end
	table.clear(self._animations)
	table.clear(self._jointTrackers)
	self._stepped:Disconnect()
	self._descendantAdded:Disconnect()
	self._descendantRemoving:Disconnect()
	self._stepped = nil
	self._descendantAdded = nil
	self._descendantRemoving = nil
end

local clock = os.clock
local cfIdentity = CFrame.identity

local function Part1Tracker(part, onSet)
	local connection = part:GetPropertyChangedSignal("Name"):Connect(function()
		onSet(part.Name)
	end)
	return function()
		connection:Disconnect()
	end
end

local function JointTracker(joint, onSet, onUnset)
	local current
	local currentTracker
	local function onPartNameChanged(name)
		onUnset(current)
		current = name
		onSet(current)
	end
	if joint.Part1 then
		current = joint.Part1.Name
		currentTracker = Part1Tracker(joint.Part1, onPartNameChanged)
	end
	local connection = joint:GetPropertyChangedSignal("Part1"):Connect(function()
		onUnset(current)
		if currentTracker then
			currentTracker()
			currentTracker = nil
		end
		if joint.Part1 then
			current = joint.Part1.Name
			onSet(current)
			currentTracker = Part1Tracker(joint.Part1, onPartNameChanged)
		end
	end)
	return function()
		connection:Disconnect()
		if currentTracker then
			currentTracker()
		end
	end
end

function Animator.new(humanoid)

	local self = setmetatable({}, Animator)
	local animations = {}
	self.AnimationMode = AnimationMode.Combined

	self._humanoid = humanoid
	self._destroyed = false
	self._joints = {}
	self._transforms = {}
	self._jointTrackers = {}
	self._animations = animations

	self._descendantAdded = nil
	self._descendantRemoving = nil

	local last = clock()
	self._stepped = RunService.Stepped:Connect(function(delta)

		local currentTransforms = self._transforms
		local joints = self._joints

		local newTransforms = {}
		local priorities = {}
		for jointName in self._joints do
			priorities[jointName] = 0
		end
		for _, animation in (animations) do
			if not animation._step then
				continue
			end
			local priority = animation.Priority.Value
			local transforms, weight = animation._step()
			if not transforms then
				continue
			end
			for jointName, cf in transforms do
				if not self._joints[jointName] then
					continue
				end
				local override = false
				if priority > priorities[jointName] then
					priorities[jointName] = priority
					override = true
				end
				local other = newTransforms[jointName]
				local startTime = animation._startTime
				if override or not other or startTime > other[1] then
					newTransforms[jointName] = {startTime, cf, weight}
				end
			end
		end
		for jointName, cfData in newTransforms do
			local weight = cfData[3]
			if weight == 1 then
				newTransforms[jointName] = cfData[2]
			else
				newTransforms[jointName] = currentTransforms[jointName]:Lerp(cfData[2], weight)
			end
		end
		
		for jointName, joint in joints do
			local cf = newTransforms[jointName]
			local transform
			if cf then
				transform = cf
				newTransforms[jointName] = transform
			else
				transform = currentTransforms[jointName]:Lerp(cfIdentity, 1 - (1/10)^(delta*10))
				newTransforms[jointName] = transform
			end
			local isTransformChanged = newTransforms[jointName] ~= currentTransforms[jointName]

			if self.AnimationMode == AnimationMode.Transform then
				joint.joint.Transform = transform
				
			elseif self.AnimationMode == AnimationMode.C0 then
				joint.joint.C0 = joint.c0 * transform
				
			elseif self.AnimationMode == AnimationMode.Combined then
				if isTransformChanged then
					joint.joint.Transform = newTransforms[jointName]
				else
					joint.joint.C0 = joint.c0 * newTransforms[jointName]
				end
			end
		end
		
		self._transforms = newTransforms
	end)

	local function newDescendant(joint)
		if joint.ClassName ~= "Motor6D" then
			return
		end
		local me = {
			joint = joint,
			c0 = joint.C0
		}
		if joint.Part1 then
			self._joints[joint.Part1.Name] = me
			self._transforms[joint.Part1.Name] = cfIdentity
		end
		self._jointTrackers[joint] = JointTracker(joint, function(name)
			self._joints[name] = me
			if not self._transforms[joint.Part1.Name] then
				self._transforms[joint.Part1.Name] = cfIdentity
			end
		end, function(name)
			self._joints[name] = nil
		end)
	end

	self._descendantAdded = humanoid.Parent.DescendantAdded:Connect(newDescendant)
	self._descendantRemoving = humanoid.Parent.DescendantRemoving:Connect(function(joint)
		if joint.ClassName ~= "Motor6D" then
			return
		end
		if joint.Part1 then
			self._joints[joint.Part1.Name] = nil
		end
		self._jointTrackers[joint]()
		self._jointTrackers[joint] = nil
	end)

	for _, joint in humanoid.Parent:GetDescendants() do
		newDescendant(joint)
	end

	return self
end

return Animator
-- made into one
