local player = game:GetService("Players").LocalPlayer

local parts = {}
local function retainPart(part)
    table.insert(parts, part)
    part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
    part.CanCollide = false
end

local function getParts()
    return parts
end
local function returnSignal()
    return game:GetService("RunService").Heartbeat:connect(function()
        sethiddenproperty(player, "SimulationRadius", math.huge)
        for _,part in parts do
            part.Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
        end
    end)
end

return { retainPart = retainPart, returnSignal = returnSignal, getParts = getParts }
