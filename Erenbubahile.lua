local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GUI = Instance.new("ScreenGui")
GUI.Name = "ModernTPPanel"
GUI.ResetOnSpawn = false
GUI.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 270, 0, 350)
Frame.Position = UDim2.new(0.5, -135, 0.5, -175)
Frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Frame.Parent = GUI

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 45)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PLAYER CONTROL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 17
Title.Parent = Frame

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 35, 0, 35)
Close.Position = UDim2.new(1, -40, 0, 5)
Close.Text = "×"
Close.TextSize = 25
Close.Parent = Frame

local Circle = Instance.new("TextButton")
Circle.Size = UDim2.new(0, 55, 0, 55)
Circle.Position = UDim2.new(0, 20, 0.5, 0)
Circle.Text = "TP"
Circle.Visible = false
Circle.Parent = GUI

Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

Close.MouseButton1Click:Connect(function()
    Frame.Visible = false
    Circle.Visible = true
end)

Circle.MouseButton1Click:Connect(function()
    Frame.Visible = true
    Circle.Visible = false
end)

local Search = Instance.new("TextBox")
Search.Size = UDim2.new(1, -20, 0, 35)
Search.Position = UDim2.new(0, 10, 0, 55)
Search.PlaceholderText = "Oyuncu ara..."
Search.Text = ""
Search.Parent = Frame

local List = Instance.new("ScrollingFrame")
List.Size = UDim2.new(1, -20, 0, 175)
List.Position = UDim2.new(0, 10, 0, 100)
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.Parent = Frame

local Selected = nil

local function Refresh()
    List:ClearAllChildren()
    local y = 5

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():find(Search.Text:lower(), 1, true) then
            local B = Instance.new("TextButton")
            B.Size = UDim2.new(1, -10, 0, 35)
            B.Position = UDim2.new(0, 5, 0, y)
            B.Text = p.Name
            B.Parent = List

            B.MouseButton1Click:Connect(function()
                Selected = p
            end)

            y = y + 40
        end
    end

    List.CanvasSize = UDim2.new(0, 0, 0, y)
end

Search:GetPropertyChangedSignal("Text"):Connect(Refresh)
Players.PlayerAdded:Connect(Refresh)
Players.PlayerRemoving:Connect(Refresh)

Refresh()
