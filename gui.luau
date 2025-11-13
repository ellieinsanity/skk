
local ScreenGui = Instance.new("ScreenGui")
local main = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local suggest = Instance.new("ScrollingFrame")
local innerCmd = Instance.new("Frame")
local TextBox = Instance.new("TextBox")
local logs = Instance.new("ScrollingFrame")
local template = Instance.new("TextLabel")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

main.Name = "main"
main.Parent = ScreenGui
main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
main.BackgroundTransparency = 1.000
main.BorderColor3 = Color3.fromRGB(0, 0, 0)
main.BorderSizePixel = 0
main.Position = UDim2.new(1, -250, 1, -200)
main.Size = UDim2.new(0, 250, 0, 200)

UIListLayout.Parent = main
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

suggest.Name = "suggest"
suggest.Parent = main
suggest.Active = true
suggest.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
suggest.BackgroundTransparency = 0.500
suggest.BorderColor3 = Color3.fromRGB(0, 0, 0)
suggest.BorderSizePixel = 0
suggest.Size = UDim2.new(0, 250, 0, 175)
suggest.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
suggest.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

innerCmd.Name = "innerCmd"
innerCmd.Parent = main
innerCmd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
innerCmd.BackgroundTransparency = 0.500
innerCmd.BorderColor3 = Color3.fromRGB(0, 0, 0)
innerCmd.BorderSizePixel = 0
innerCmd.Size = UDim2.new(1, 0, 0, 25)

TextBox.Parent = innerCmd
TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BackgroundTransparency = 1.000
TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BorderSizePixel = 0
TextBox.Position = UDim2.new(0.0500000007, 0, 0, 0)
TextBox.Size = UDim2.new(0.949999988, 0, 1, 0)
TextBox.Font = Enum.Font.Code
TextBox.PlaceholderText = "Command"
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.TextSize = 14.000
TextBox.TextXAlignment = Enum.TextXAlignment.Left

logs.Name = "logs"
logs.Parent = ScreenGui
logs.Active = true
logs.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logs.BackgroundTransparency = 0.500
logs.BorderColor3 = Color3.fromRGB(0, 0, 0)
logs.BorderSizePixel = 0
logs.Position = UDim2.new(0, 0, 1, -200)
logs.Size = UDim2.new(0, 250, 0, 200)
logs.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
logs.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

template.Name = "template"
template.Parent = logs
template.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
template.BackgroundTransparency = 1.000
template.BorderColor3 = Color3.fromRGB(0, 0, 0)
template.BorderSizePixel = 0
template.Size = UDim2.new(1, 0, 0, 25)
template.Font = Enum.Font.Code
template.TextColor3 = Color3.fromRGB(255, 255, 255)
template.TextSize = 14.000
template.TextXAlignment = Enum.TextXAlignment.Left

return ScreenGui
