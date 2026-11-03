
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "BubaGamesPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(340, 285)
main.Position = UDim2.new(0.5, -170, 0.5, -142)
main.BackgroundColor3 = Color3.fromRGB(19, 20, 28)
main.Parent = gui
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 13)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 90, 1, -12)
sidebar.Position = UDim2.fromOffset(6, 6)
sidebar.BackgroundColor3 = Color3.fromRGB(27, 29, 40)
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 48)
title.Text = "BUBA"
title.TextColor3 = Color3.fromRGB(255, 155, 45)
title.TextSize = 21
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = sidebar

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(105, 48)
content.Size = UDim2.new(1, -115, 1, -58)
content.BackgroundTransparency = 1
content.Parent = main

local selected = nil

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -10, 0, 25)
status.Position = UDim2.fromOffset(5, 0)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1,1,1)
status.Text = "Oyuncu seç"
status.Parent = content

local function button(parent, name, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 35)
    b.Position = UDim2.fromOffset(5, y)
    b.BackgroundColor3 = Color3.fromRGB(39, 42, 57)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = name
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function clear()
    for _, v in ipairs(content:GetChildren()) do
        if v ~= status then v:Destroy() end
    end
end

local function playersPage()
    clear()
    status.Text = "OYUNCU LİSTESİ"

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(5, 30)
    list.Size = UDim2.new(1, -10, 1, -35)
    list.BackgroundTransparency = 1
    list.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = list

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -5, 0, 35)
            b.BackgroundColor3 = Color3.fromRGB(39, 42, 57)
            b.TextColor3 = Color3.new(1,1,1)
            b.Text = p.DisplayName .. " (@" .. p.Name .. ")"
            b.Parent = list

            b.MouseButton1Click:Connect(function()
                selected = p
                status.Text = "Seçildi: " .. p.Name
            end)
        end
    end

    list.CanvasSize = UDim2.fromOffset(0, #Players:GetPlayers() * 40)
end

local function page(name)
    clear()
    status.Text = name

    if name == "TP" or name == "BRING" then
        button(content, "OYUNCU SEÇ", 45, playersPage)
        button(content, name .. " İŞLEMİ", 90, function()
            status.Text = selected and
                selected.Name .. " seçildi - sunucu yetkisi gerekli"
                or "Önce oyuncu seç!"
        end)
    elseif name == "FLY" then
        button(content, "FLY TEST", 45, function()
            status.Text = "Yetkili test sistemi gerekli"
        end)
    elseif name == "TROLL" then
        button(content, "TROLL TEST", 45, function()
            status.Text = "Yetkili test sistemi gerekli"
        end)
    end
end

button(sidebar, "TP", 65, function() page("TP") end)
button(sidebar, "BRING", 105, function() page("BRING") end)
button(sidebar, "FLY", 145, function() page("FLY") end)
button(sidebar, "TROLL", 185, function() page("TROLL") end)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.Text = "×"
close.TextSize = 23
close.BackgroundColor3 = Color3.fromRGB(180, 65, 65)
close.TextColor3 = Color3.new(1,1,1)
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(1,0)

local mini = Instance.new("ImageButton")
mini.Size = UDim2.fromOffset(58,58)
mini.Position = UDim2.new(0, 15, 0.5, 0)
mini.BackgroundColor3 = Color3.fromRGB(255, 153, 40)
mini.Image = "rbxassetid://129287367563025"
mini.ScaleType = Enum.ScaleType.Crop
mini.Visible = false
mini.Parent = gui
mini.Active = true
mini.Draggable = true

Instance.new("UICorner", mini).CornerRadius = UDim.new(1,0)

close.MouseButton1Click:Connect(function()
    main.Visible = false
    mini.Visible = true
end)

mini.MouseButton1Click:Connect(function()
    main.Visible = true
    mini.Visible = false
end)

Players.PlayerAdded:Connect(function()
    if status.Text == "OYUNCU LİSTESİ" then
        playersPage()
    end
end)

Players.PlayerRemoving:Connect(function()
    if status.Text == "OYUNCU LİSTESİ" then
        playersPage()
    end
end)

page("TP")
