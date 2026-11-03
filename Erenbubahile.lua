local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GUI = Instance.new("ScreenGui")
GUI.Name = "BetaTPPanel"
GUI.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 180)
Frame.Position = UDim2.new(0.5, -110, 0.5, -90)
Frame.Parent = GUI

local Target = Instance.new("TextBox")
Target.Size = UDim2.new(1, -20, 0, 35)
Target.Position = UDim2.new(0, 10, 0, 10)
Target.PlaceholderText = "Oyuncu adı"
Target.Text = ""
Target.Parent = Frame

local function teleport(action)
    local player = Players:FindFirstChild(Target.Text)
    if not player then return end

    local char = LocalPlayer.Character
    local targetChar = player.Character

    if not char or not targetChar then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")

    if not root or not targetRoot then return end

    if action == "TP" then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    end
end

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1, -20, 0, 40)
Button.Position = UDim2.new(0, 10, 0, 60)
Button.Text = "TP TO PLAYER"
Button.Parent = Frame
Button.MouseButton1Click:Connect(function()
    teleport("TP")
end)