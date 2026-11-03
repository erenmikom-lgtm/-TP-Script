-- BUBA MM2 - authorized Studio/test-place panel
-- Place this LocalScript in StarterPlayerScripts.
--
-- Optional server-published test data:
-- ReplicatedStorage.MM2TestState (Folder) attributes:
--   MurdererUserId     number/string
--   SheriffUserId      number/string
--   SheriffGunDropped  boolean
--   DroppedGunPosition Vector3
--
-- Player role attributes may also be published by your own server:
--   Player:SetAttribute("MM2Role", "Murderer" | "Sheriff" | "Innocent")
--
-- This script does not infer hidden roles, provide ESP, alter movement,
-- target players, or automate gameplay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local function create(className, parent, properties)
	local instance = Instance.new(className)

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	instance.Parent = parent
	return instance
end

local function addCorner(instance, radius)
	create("UICorner", instance, {
		CornerRadius = UDim.new(0, radius),
	})
end

local function notify(title, message)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = message,
			Duration = 4,
		})
	end)
end

local palettes = {
	{
		name = "Orange",
		accent = Color3.fromRGB(255, 130, 35),
		panel = Color3.fromRGB(22, 22, 24),
		surface = Color3.fromRGB(34, 34, 37),
	},
	{
		name = "Cyan",
		accent = Color3.fromRGB(40, 190, 220),
		panel = Color3.fromRGB(22, 22, 24),
		surface = Color3.fromRGB(34, 34, 37),
	},
	{
		name = "Purple",
		accent = Color3.fromRGB(160, 100, 240),
		panel = Color3.fromRGB(22, 22, 24),
		surface = Color3.fromRGB(34, 34, 37),
	},
}

local paletteIndex = 1
local palette = palettes[paletteIndex]
local transparency = 0
local sizeIndex = 2
local sizeOptions = {
	UDim2.new(0.84, 0, 0.78, 0),
	UDim2.new(0.90, 0, 0.82, 0),
	UDim2.new(0.94, 0, 0.86, 0),
}

local themeBindings = {}
local accentObjects = {}
local navButtons = {}
local currentTab = "Players"
local selectedPlayer = nil
local fpsEnabled = false
local fpsConnection = nil

local function bindTheme(instance, slot)
	table.insert(themeBindings, {
		instance = instance,
		slot = slot,
	})
end

local screenGui = create("ScreenGui", playerGui, {
	Name = "BUBAMM2Panel",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local main = create("Frame", screenGui, {
	Name = "MainPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = sizeOptions[sizeIndex],
	BackgroundColor3 = palette.panel,
	BorderSizePixel = 0,
})
addCorner(main, 14)
bindTheme(main, "panel")

create("UISizeConstraint", main, {
	MinSize = Vector2.new(320, 300),
	MaxSize = Vector2.new(900, 680),
})

local header = create("Frame", main, {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = palette.surface,
	BorderSizePixel = 0,
})
addCorner(header, 14)
bindTheme(header, "surface")

-- Covers the lower rounded part of the header so its bottom is straight.
local headerCover = create("Frame", header, {
	Position = UDim2.new(0, 0, 1, -14),
	Size = UDim2.new(1, 0, 0, 14),
	BackgroundColor3 = palette.surface,
	BorderSizePixel = 0,
})
bindTheme(headerCover, "surface")

local title = create("TextLabel", header, {
	Position = UDim2.new(0, 14, 0, 0),
	Size = UDim2.new(1, -120, 1, 0),
	BackgroundTransparency = 1,
	Text = "BUBA MM2",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local fpsLabel = create("TextLabel", header, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -48, 0.5, 0),
	Size = UDim2.new(0, 62, 0, 28),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.fromRGB(220, 220, 220),
	TextSize = 12,
	Font = Enum.Font.Gotham,
	Visible = false,
})

local closeButton = create("TextButton", header, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.new(0, 36, 0, 36),
	BackgroundColor3 = palette.accent,
	Text = "X",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = true,
})
addCorner(closeButton, 10)
table.insert(accentObjects, closeButton)

local sidebar = create("Frame", main, {
	Name = "Sidebar",
	Position = UDim2.new(0, 0, 0, 48),
	Size = UDim2.new(0, 108, 1, -48),
	BackgroundColor3 = palette.surface,
	BorderSizePixel = 0,
})
bindTheme(sidebar, "surface")

local content = create("Frame", main, {
	Name = "Content",
	Position = UDim2.new(0, 108, 0, 48),
	Size = UDim2.new(1, -108, 1, -48),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})

local floating = create("ImageButton", screenGui, {
	Name = "FloatingMenu",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -24),
	Size = UDim2.new(0, 64, 0, 64),
	BackgroundColor3 = palette.accent,
	Image = "rbxassetid://129287367563025",
	ScaleType = Enum.ScaleType.Crop,
	Visible = false,
	AutoButtonColor = false,
})
addCorner(floating, 100)
table.insert(accentObjects, floating)

local function makePage(name)
	local page = create("Frame", content, {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = palette.panel,
		BorderSizePixel = 0,
		Visible = false,
	})
	bindTheme(page, "panel")
	return page
end

local playersPage = makePage("PlayersPage")
local rolesPage = makePage("RolesPage")
local settingsPage = makePage("SettingsPage")

local function makeScroll(parent, name, position, size)
	local scroll = create("ScrollingFrame", parent, {
		Name = name,
		Position = position,
		Size = size,
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = palette.accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	addCorner(scroll, 10)
	bindTheme(scroll, "surface")

	create("UIPadding", scroll, {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	create("UIListLayout", scroll, {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return scroll
end

-- Players page
local searchBox = create("TextBox", playersPage, {
	Name = "PlayerSearch",
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(1, -16, 0, 38),
	BackgroundColor3 = palette.surface,
	BorderSizePixel = 0,
	ClearTextOnFocus = false,
	PlaceholderText = "Search players...",
	PlaceholderColor3 = Color3.fromRGB(160, 160, 160),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
})
addCorner(searchBox, 9)
bindTheme(searchBox, "surface")

local playerList = makeScroll(
	playersPage,
	"PlayerList",
	UDim2.new(0, 8, 0, 54),
	UDim2.new(1, -16, 0.42, 0)
)

local profileBox = create("TextLabel", playersPage, {
	Name = "SelectedPlayerProfile",
	Position = UDim2.new(0, 8, 0.46, 0),
	Size = UDim2.new(1, -16, 0.52, -8),
	BackgroundColor3 = palette.surface,
	BorderSizePixel = 0,
	Text = "Select a player to view their profile.",
	TextColor3 = Color3.fromRGB(240, 240, 240),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
addCorner(profileBox, 10)
bindTheme(profileBox, "surface")

create("UIPadding", profileBox, {
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 8),
})

-- Roles page
local rolesScroll = makeScroll(
	rolesPage,
	"RoleAndTestState",
	UDim2.new(0, 8, 0, 8),
	UDim2.new(1, -16, 1, -16)
)

local rolesInfo = create("TextLabel", rolesScroll, {
	Name = "RoleInformation",
	Size = UDim2.new(1, -8, 0, 240),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Text = "Waiting for server-published test data...",
	TextColor3 = Color3.fromRGB(240, 240, 240),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})

-- Settings page
local settingsScroll = makeScroll(
	settingsPage,
	"Settings",
	UDim2.new(0, 8, 0, 8),
	UDim2.new(1, -16, 1, -16)
)

local function makeSettingRow(text, buttonText, callback)
	local row = create("Frame", settingsScroll, {
		Size = UDim2.new(1, -8, 0, 48),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
	})
	addCorner(row, 9)
	bindTheme(row, "surface")

	create("TextLabel", row, {
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -118, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.fromRGB(245, 245, 245),
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})

	local button = create("TextButton", row, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.new(0, 100, 0, 36),
		BackgroundColor3 = palette.accent,
		Text = buttonText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
	})
	addCorner(button, 8)
	table.insert(accentObjects, button)

	button.Activated:Connect(callback)
	return button
end

local paletteButton
local transparencyButton
local sizeButton
local fpsButton

paletteButton = makeSettingRow("Menu color theme", "Orange", function()
	paletteIndex = (paletteIndex % #palettes) + 1
	palette = palettes[paletteIndex]
	paletteButton.Text = palette.name
end)

transparencyButton = makeSettingRow("Panel transparency", "0%", function()
	transparency = transparency + 0.1
	if transparency > 0.31 then
		transparency = 0
	end
	transparencyButton.Text = tostring(math.floor(transparency * 100 + 0.5)) .. "%"
end)

sizeButton = makeSettingRow("Panel size", "Medium", function()
	sizeIndex = (sizeIndex % #sizeOptions) + 1
	sizeButton.Text = ({"Small", "Medium", "Large"})[sizeIndex]
	main.Size = sizeOptions[sizeIndex]
end)

fpsButton = makeSettingRow("Performance counter", "Off", function()
	fpsEnabled = not fpsEnabled
	fpsLabel.Visible = fpsEnabled
	fpsButton.Text = fpsEnabled and "On" or "Off"

	if fpsEnabled and not fpsConnection then
		local frameCount = 0
		local elapsed = 0

		fpsConnection = RunService.RenderStepped:Connect(function(deltaTime)
			frameCount += 1
			elapsed += deltaTime

			if elapsed >= 1 then
				fpsLabel.Text = tostring(math.floor(frameCount / elapsed + 0.5)) .. " FPS"
				frameCount = 0
				elapsed = 0
			end
		end)
	elseif not fpsEnabled and fpsConnection then
		fpsConnection:Disconnect()
		fpsConnection = nil
		fpsLabel.Text = ""
	end
end)

local function applyTheme()
	for _, binding in ipairs(themeBindings) do
		local instance = binding.instance
		if instance and instance.Parent then
			if binding.slot == "panel" then
				instance.BackgroundColor3 = palette.panel
			elseif binding.slot == "surface" then
				instance.BackgroundColor3 = palette.surface
			end

			if instance:IsA("GuiObject") and instance.BackgroundTransparency < 1 then
				instance.BackgroundTransparency = transparency
			end
		end
	end

	for _, instance in ipairs(accentObjects) do
		if instance and instance.Parent then
			instance.BackgroundColor3 = palette.accent
		end
	end

	for _, button in ipairs(navButtons) do
		if button and button.Parent then
			button.BackgroundColor3 = button.Name == currentTab .. "Tab"
				and palette.accent
				or palette.surface
		end
	end

	if playerList then
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = child:GetAttribute("Selected")
					and palette.accent
					or palette.surface
			end
		end
	end
end

-- Sidebar navigation
local navLayout = create("UIListLayout", sidebar, {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
})

create("UIPadding", sidebar, {
	PaddingTop = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
})

local pages = {
	Players = playersPage,
	Roles = rolesPage,
	Settings = settingsPage,
}

local function setTab(tabName)
	currentTab = tabName

	for name, page in pairs(pages) do
		page.Visible = name == tabName
	end

	for _, button in ipairs(navButtons) do
		button.BackgroundColor3 = button.Name == tabName .. "Tab"
			and palette.accent
			or palette.surface
	end
end

for _, tabName in ipairs({"Players", "Roles", "Settings"}) do
	local button = create("TextButton", sidebar, {
		Name = tabName .. "Tab",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = palette.surface,
		Text = tabName,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextWrapped = true,
		AutoButtonColor = true,
	})
	addCorner(button, 9)
	table.insert(navButtons, button)

	button.Activated:Connect(function()
		setTab(tabName)
	end)
end

setTab("Players")

-- Server-published test state. Missing state is treated as unknown.
local stateFolder = nil
local stateConnections = {}
local sheriffCharacterConnection = nil
local sheriffDiedConnection = nil
local trackedSheriffId = nil
local sheriffDeathNotifiedFor = nil
local previousMurdererId = nil
local previousSheriffId = nil
local lastGunDropped = nil

local function getStateId(attributeName)
	if not stateFolder then
		return nil
	end

	local value = stateFolder:GetAttribute(attributeName)
	if typeof(value) == "number" then
		return value
	end

	return tonumber(value)
end

local function getPlayerById(userId)
	if not userId then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end

	return nil
end

local function getRoot(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getDistance(player)
	local myRoot = getRoot(localPlayer)
	local theirRoot = getRoot(player)

	if not myRoot or not theirRoot then
		return nil
	end

	return (myRoot.Position - theirRoot.Position).Magnitude
end

local function getRole(player)
	if not player then
		return "Unknown"
	end

	if stateFolder then
		if player.UserId == getStateId("MurdererUserId") then
			return "Murderer"
		elseif player.UserId == getStateId("SheriffUserId") then
			return "Sheriff"
		end
	end

	local roleAttribute = player:GetAttribute("MM2Role")
	if typeof(roleAttribute) == "string" then
		local normalized = string.lower(roleAttribute)
		if normalized == "murderer" then
			return "Murderer"
		elseif normalized == "sheriff" then
			return "Sheriff"
		elseif normalized == "innocent" then
			return "Innocent"
		end
	end

	return "Unknown"
end

local function updateProfile()
	if not selectedPlayer or not selectedPlayer.Parent then
		profileBox.Text = "Select a player to view their profile."
		return
	end

	local distance = getDistance(selectedPlayer)
	local distanceText = distance and (tostring(math.floor(distance + 0.5)) .. " studs") or "Unavailable"

	profileBox.Text = string.format(
		"PLAYER PROFILE\n\nDisplay name: %s\nUsername: @%s\nUserId: %d\nAccount age: %d days\nRole: %s\nDistance: %s",
		selectedPlayer.DisplayName,
		selectedPlayer.Name,
		selectedPlayer.UserId,
		selectedPlayer.AccountAge,
		getRole(selectedPlayer),
		distanceText
	)
end

local function refreshPlayerList()
	if not playerList or not playerList.Parent then
		return
	end

	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local query = string.lower(searchBox.Text)
	local sortedPlayers = Players:GetPlayers()

	table.sort(sortedPlayers, function(a, b)
		return string.lower(a.DisplayName) < string.lower(b.DisplayName)
	end)

	for _, player in ipairs(sortedPlayers) do
		local searchable = string.lower(player.DisplayName .. " " .. player.Name)
		if query == "" or string.find(searchable, query, 1, true) then
			local distance = getDistance(player)
			local distanceText = distance and (tostring(math.floor(distance + 0.5)) .. " studs") or "—"
			local selected = player == selectedPlayer

			local row = create("TextButton", playerList, {
				Name = "Player_" .. player.UserId,
				Size = UDim2.new(1, -8, 0, 42),
				BackgroundColor3 = selected and palette.accent or palette.surface,
				Text = string.format("%s  |  %s  |  %s", player.DisplayName, getRole(player), distanceText),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextWrapped = true,
				AutoButtonColor = true,
			})
			addCorner(row, 8)
			row:SetAttribute("Selected", selected)

			row.Activated:Connect(function()
				selectedPlayer = player
				updateProfile()
				refreshPlayerList()
			end)
		end
	end

	updateProfile()
	applyTheme()
end

searchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)

local function roleNameForId(userId)
	local player = getPlayerById(userId)
	return player and (player.DisplayName .. " (@" .. player.Name .. ")") or "Not in server"
end

local function updateRolesPage()
	local murdererId = getStateId("MurdererUserId")
	local sheriffId = getStateId("SheriffUserId")
	local lines = {}

	if murdererId then
		table.insert(lines, "Murderer: " .. roleNameForId(murdererId))
	else
		table.insert(lines, "Murderer: Not provided by the test server")
	end

	if sheriffId then
		table.insert(lines, "Sheriff: " .. roleNameForId(sheriffId))
	else
		table.insert(lines, "Sheriff: Not provided by the test server")
	end

	table.insert(lines, "")
	table.insert(lines, "Server-published player roles:")

	local hasPublishedRole = false
	for _, player in ipairs(Players:GetPlayers()) do
		local role = getRole(player)
		if role ~= "Unknown" then
			hasPublishedRole = true
			table.insert(lines, string.format("%s (@%s): %s", player.DisplayName, player.Name, role))
		end
	end

	if not hasPublishedRole then
		table.insert(lines, "No role attributes are currently available.")
	end

	table.insert(lines, "")
	table.insert(lines, "Dropped sheriff gun:")

	local gunDropped = stateFolder and stateFolder:GetAttribute("SheriffGunDropped") == true
	local position = stateFolder and stateFolder:GetAttribute("DroppedGunPosition")

	if gunDropped then
		table.insert(lines, "Status: Dropped")
		if typeof(position) == "Vector3" then
			table.insert(lines, string.format(
				"Test location: X %.1f, Y %.1f, Z %.1f",
				position.X,
				position.Y,
				position.Z
			))
		else
			table.insert(lines, "Location: Not provided by the test server")
		end
	else
		table.insert(lines, "Status: Not reported as dropped")
	end

	rolesInfo.Text = table.concat(lines, "\n")
end

local function disconnectSheriffTracking()
	if sheriffCharacterConnection then
		sheriffCharacterConnection:Disconnect()
		sheriffCharacterConnection = nil
	end

	if sheriffDiedConnection then
		sheriffDiedConnection:Disconnect()
		sheriffDiedConnection = nil
	end
end

local function attachSheriffCharacter(character)
	if not character then
		return
	end

	if sheriffDiedConnection then
		sheriffDiedConnection:Disconnect()
		sheriffDiedConnection = nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 5)
	end

	if humanoid and trackedSheriffId then
		local trackedId = trackedSheriffId
		sheriffDiedConnection = humanoid.Died:Connect(function()
			if trackedSheriffId == trackedId and sheriffDeathNotifiedFor ~= trackedId then
				sheriffDeathNotifiedFor = trackedId
				notify("BUBA MM2", "The server-published Sheriff character died.")
			end
		end)
	end
end

local function trackSheriff(userId)
	if trackedSheriffId == userId then
		return
	end

	disconnectSheriffTracking()
	trackedSheriffId = userId
	sheriffDeathNotifiedFor = nil

	local sheriff = getPlayerById(userId)
	if not sheriff then
		return
	end

	if sheriff.Character then
		attachSheriffCharacter(sheriff.Character)
	end

	sheriffCharacterConnection = sheriff.CharacterAdded:Connect(attachSheriffCharacter)
end

local function bindStateFolder(folder)
	for _, connection in ipairs(stateConnections) do
		connection:Disconnect()
	end
	table.clear(stateConnections)

	stateFolder = folder
	previousMurdererId = getStateId("MurdererUserId")
	previousSheriffId = getStateId("SheriffUserId")
	lastGunDropped = folder:GetAttribute("SheriffGunDropped") == true

	trackSheriff(previousSheriffId)

	table.insert(stateConnections, folder:GetAttributeChangedSignal("MurdererUserId"):Connect(function()
		local newId = getStateId("MurdererUserId")
		if previousMurdererId and newId ~= previousMurdererId then
			notify("BUBA MM2", "The test server reported a Murderer role change.")
		end
		previousMurdererId = newId
		updateRolesPage()
		refreshPlayerList()
	end))

	table.insert(stateConnections, folder:GetAttributeChangedSignal("SheriffUserId"):Connect(function()
		local newId = getStateId("SheriffUserId")
		if previousSheriffId and newId ~= previousSheriffId then
			notify("BUBA MM2", "The test server reported a Sheriff role change.")
		end
		previousSheriffId = newId
		trackSheriff(newId)
		updateRolesPage()
		refreshPlayerList()
	end))

	table.insert(stateConnections, folder:GetAttributeChangedSignal("SheriffGunDropped"):Connect(function()
		local isDropped = folder:GetAttribute("SheriffGunDropped") == true

		if isDropped and not lastGunDropped then
			local position = folder:GetAttribute("DroppedGunPosition")
			if typeof(position) == "Vector3" then
				notify("BUBA MM2", string.format(
					"Sheriff gun dropped at X %.1f, Y %.1f, Z %.1f.",
					position.X,
					position.Y,
					position.Z
				))
			else
				notify("BUBA MM2", "The test server reported that the Sheriff gun was dropped.")
			end
		end

		lastGunDropped = isDropped
		updateRolesPage()
	end))

	table.insert(stateConnections, folder:GetAttributeChangedSignal("DroppedGunPosition"):Connect(updateRolesPage))

	updateRolesPage()
	refreshPlayerList()
end

local existingState = ReplicatedStorage:FindFirstChild("MM2TestState")
if existingState and existingState:IsA("Folder") then
	bindStateFolder(existingState)
end

ReplicatedStorage.ChildAdded:Connect(function(child)
	if child.Name == "MM2TestState" and child:IsA("Folder") then
		bindStateFolder(child)
	end
end)

-- Player list refresh and role/profile refresh.
Players.PlayerAdded:Connect(function()
	refreshPlayerList()
	updateRolesPage()
end)

Players.PlayerRemoving:Connect(function(player)
	if selectedPlayer == player then
		selectedPlayer = nil
	end
	refreshPlayerList()
	updateRolesPage()
end)

-- Draggable main panel: drag from its title bar.
do
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = main.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

-- Draggable floating logo. Tap it to reopen the panel.
do
	local startInput = nil
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil
	local moved = false
	local dragging = false

	floating.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			startInput = input
			dragStart = input.Position
			startPosition = floating.Position
			moved = false
			dragging = true
		end
	end)

	floating.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart

			if math.abs(delta.X) > 7 or math.abs(delta.Y) > 7 then
				moved = true
			end

			if moved then
				floating.Position = UDim2.new(
					startPosition.X.Scale,
					startPosition.X.Offset + delta.X,
					startPosition.Y.Scale,
					startPosition.Y.Offset + delta.Y
				)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == startInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false

			if not moved then
				main.Visible = true
				floating.Visible = false
			end
		end
	end)
end

closeButton.Activated:Connect(function()
	main.Visible = false
	floating.Visible = true
end)

local function refreshAll()
	refreshPlayerList()
	updateRolesPage()
end

-- Apply initial settings and keep displayed distances current.
applyTheme()
refreshAll()

task.spawn(function()
	while screenGui.Parent do
		task.wait(2)
		refreshAll()
	end
end)

-- Update an already-selected player's distance without waiting for list refresh.
RunService.Heartbeat:Connect(function()
	if selectedPlayer and selectedPlayer.Parent then
		updateProfile()
	end
end)
