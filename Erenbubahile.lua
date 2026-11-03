-- BUBA MM2 - authorized companion panel
-- LocalScript: StarterPlayer > StarterPlayerScripts
--
-- Optional data published by YOUR server in an experience you own:
-- ReplicatedStorage.MM2PublicState (Folder) attributes:
--   RoundStatus       string
--   MurdererUserId    number
--   SheriffUserId     number
--   SheriffGunDropped boolean
--
-- Players may have a server-published "MM2Role" attribute.
-- This script does not inspect hidden game state or affect other players.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PRIMARY_LOGO = "rbxassetid://129287367563025"
local BACKUP_LOGO = "rbxassetid://114072040627090"

local themes = {
	{name = "Blue", accent = Color3.fromRGB(55, 170, 255), panel = Color3.fromRGB(20, 22, 29), surface = Color3.fromRGB(34, 37, 48)},
	{name = "Purple", accent = Color3.fromRGB(165, 105, 255), panel = Color3.fromRGB(20, 22, 29), surface = Color3.fromRGB(34, 37, 48)},
	{name = "Orange", accent = Color3.fromRGB(255, 135, 45), panel = Color3.fromRGB(20, 22, 29), surface = Color3.fromRGB(34, 37, 48)},
}

local themeIndex = 1
local theme = themes[themeIndex]
local savedTab = "Players"
local selectedPlayer
local stateFolder
local stateConnections = {}
local previousRound
local previousMurderer
local previousSheriff
local previousGunDropped
local visualHighlight
local notificationHistory = {}

local function make(className, parent, props)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function rounded(object, radius)
	make("UICorner", object, {CornerRadius = UDim.new(0, radius)})
end

local function notify(message)
	table.insert(notificationHistory, 1, os.date("%H:%M:%S") .. "  " .. message)
	while #notificationHistory > 8 do
		table.remove(notificationHistory)
	end

	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "BUBA MM2",
			Text = message,
			Duration = 4,
		})
	end)

	if historyLabel then
		historyLabel.Text = #notificationHistory > 0
			and table.concat(notificationHistory, "\n")
			or "No notifications yet."
	end
end

local gui = make("ScreenGui", playerGui, {
	Name = "BUBAMM2Companion",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local main = make("Frame", gui, {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.78),
	BackgroundColor3 = theme.panel,
	BorderSizePixel = 0,
})
rounded(main, 14)

make("UISizeConstraint", main, {
	MinSize = Vector2.new(300, 310),
	MaxSize = Vector2.new(800, 650),
})

local header = make("Frame", main, {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = theme.surface,
	BorderSizePixel = 0,
})
rounded(header, 14)

make("Frame", header, {
	Position = UDim2.new(0, 0, 1, -12),
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundColor3 = theme.surface,
	BorderSizePixel = 0,
})

make("TextLabel", header, {
	Position = UDim2.new(0, 14, 0, 0),
	Size = UDim2.new(1, -115, 1, 0),
	BackgroundTransparency = 1,
	Text = "BUBA MM2",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 19,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local minimize = make("TextButton", header, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.new(0, 40, 0, 36),
	BackgroundColor3 = theme.accent,
	Text = "—",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 22,
	Font = Enum.Font.GothamBold,
})
rounded(minimize, 9)

local tabsBar = make("Frame", main, {
	Position = UDim2.new(0, 0, 0, 48),
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
})

make("UIListLayout", tabsBar, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
})

local pageHolder = make("Frame", main, {
	Position = UDim2.new(0, 0, 0, 92),
	Size = UDim2.new(1, 0, 1, -92),
	BackgroundTransparency = 1,
})

local pages = {}
local tabButtons = {}

local function createPage(name)
	local page = make("Frame", pageHolder, {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	})
	pages[name] = page
	return page
end

local function setTab(name)
	if not pages[name] then
		return
	end

	savedTab = name
	for pageName, page in pairs(pages) do
		page.Visible = pageName == name
	end
	for tabName, button in pairs(tabButtons) do
		button.BackgroundColor3 = tabName == name and theme.accent or theme.surface
	end
end

for _, name in ipairs({"Players", "Round", "Effects", "Settings"}) do
	local button = make("TextButton", tabsBar, {
		Name = name .. "Tab",
		Size = UDim2.new(0.23, -4, 0, 36),
		BackgroundColor3 = theme.surface,
		Text = name,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	})
	rounded(button, 8)
	tabButtons[name] = button
	button.Activated:Connect(function()
		setTab(name)
	end)
end

local function createScroll(parent, name, position, size)
	local scroll = make("ScrollingFrame", parent, {
		Name = name,
		Position = position,
		Size = size,
		BackgroundColor3 = theme.surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	rounded(scroll, 10)

	make("UIPadding", scroll, {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})
	make("UIListLayout", scroll, {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	return scroll
end

-- Players tab
local playersPage = createPage("Players")
local search = make("TextBox", playersPage, {
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(1, -16, 0, 38),
	BackgroundColor3 = theme.surface,
	BorderSizePixel = 0,
	ClearTextOnFocus = false,
	PlaceholderText = "Search username or display name",
	PlaceholderColor3 = Color3.fromRGB(170, 170, 170),
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.Gotham,
})
rounded(search, 8)

local playerList = createScroll(
	playersPage,
	"PlayerList",
	UDim2.new(0, 8, 0, 54),
	UDim2.new(1, -16, 0.46, 0)
)

local profile = make("TextLabel", playersPage, {
	Position = UDim2.new(0, 8, 0.48, 0),
	Size = UDim2.new(1, -16, 0.49, -8),
	BackgroundColor3 = theme.surface,
	Text = "Select a player to view their profile.",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
rounded(profile, 10)

-- Round tab
local roundPage = createPage("Round")
local roundInfo = make("TextLabel", roundPage, {
	Position = UDim2.new(0, 8, 0, 8),
	Size = UDim2.new(1, -16, 0.55, 0),
	BackgroundColor3 = theme.surface,
	Text = "No server-published round data available.",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
rounded(roundInfo, 10)

local historyLabel
historyLabel = make("TextLabel", roundPage, {
	Position = UDim2.new(0, 8, 0.58, 0),
	Size = UDim2.new(1, -16, 0.39, -8),
	BackgroundColor3 = theme.surface,
	Text = "No notifications yet.",
	TextColor3 = Color3.fromRGB(220, 220, 220),
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
rounded(historyLabel, 10)

-- Effects tab: local-only visual effect, no character physics changes.
local effectsPage = createPage("Effects")
local effectsText = make("TextLabel", effectsPage, {
	Position = UDim2.new(0, 12, 0, 12),
	Size = UDim2.new(1, -24, 0, 62),
	BackgroundTransparency = 1,
	Text = "Visual effects apply only to your own client-side character display.",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local effectButton = make("TextButton", effectsPage, {
	Position = UDim2.new(0, 12, 0, 82),
	Size = UDim2.new(1, -24, 0, 46),
	BackgroundColor3 = theme.accent,
	Text = "Enable self space glow",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.GothamBold,
})
rounded(effectButton, 9)

local launchButton = make("TextButton", effectsPage, {
	Position = UDim2.new(0, 12, 0, 138),
	Size = UDim2.new(1, -24, 0, 46),
	BackgroundColor3 = theme.surface,
	Text = "Play visual launch effect",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.GothamBold,
})
rounded(launchButton, 9)

local function clearHighlight()
	if visualHighlight then
		visualHighlight:Destroy()
		visualHighlight = nil
	end
end

local function applySelfHighlight()
	clearHighlight()
	local character = player.Character
	if character then
		visualHighlight = Instance.new("Highlight")
		visualHighlight.Name = "BUBASelfVisualEffect"
		visualHighlight.FillColor = theme.accent
		visualHighlight.OutlineColor = Color3.new(1, 1, 1)
		visualHighlight.FillTransparency = 0.35
		visualHighlight.Parent = character
	end
end

local selfGlowEnabled = false
effectButton.Activated:Connect(function()
	selfGlowEnabled = not selfGlowEnabled
	effectButton.Text = selfGlowEnabled and "Disable self space glow" or "Enable self space glow"
	if selfGlowEnabled then
		applySelfHighlight()
	else
		clearHighlight()
	end
end)

player.CharacterAdded:Connect(function()
	if selfGlowEnabled then
		task.wait(0.5)
		applySelfHighlight()
	end
end)

launchButton.Activated:Connect(function()
	local character = player.Character
	if not character then
		notify("Your character is not available.")
		return
	end

	local effect = Instance.new("Highlight")
	effect.Name = "BUBALaunchVisual"
	effect.Adornee = character
	effect.FillColor = theme.accent
	effect.OutlineColor = Color3.new(1, 1, 1)
	effect.FillTransparency = 0.05
	effect.OutlineTransparency = 0
	effect.Parent = character

	local tween = TweenService:Create(
		effect,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FillTransparency = 1, OutlineTransparency = 1}
	)
	tween:Play()
	tween.Completed:Connect(function()
		effect:Destroy()
	end)
	notify("Played a visual-only launch effect.")
end)

-- Settings tab
local settingsPage = createPage("Settings")
local settingsScroll = createScroll(
	settingsPage,
	"SettingsList",
	UDim2.new(0, 8, 0, 8),
	UDim2.new(1, -16, 1, -16)
)

local function settingsRow(label, buttonLabel, callback)
	local row = make("Frame", settingsScroll, {
		Size = UDim2.new(1, -8, 0, 48),
		BackgroundColor3 = theme.surface,
	})
	rounded(row, 8)

	make("TextLabel", row, {
		Position = UDim2.new(0, 9, 0, 0),
		Size = UDim2.new(1, -120, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})

	local button = make("TextButton", row, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 104, 0, 36),
		BackgroundColor3 = theme.accent,
		Text = buttonLabel,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	})
	rounded(button, 8)
	button.Activated:Connect(function()
		callback(button)
	end)
	return button
end

settingsRow("Change interface accent", theme.name, function(button)
	themeIndex = (themeIndex % #themes) + 1
	theme = themes[themeIndex]
	button.Text = theme.name

	main.BackgroundColor3 = theme.panel
	header.BackgroundColor3 = theme.surface
	for _, item in ipairs(header:GetChildren()) do
		if item:IsA("Frame") then
			item.BackgroundColor3 = theme.surface
		end
	end

	minimize.BackgroundColor3 = theme.accent
	effectButton.BackgroundColor3 = theme.accent
	for _, tabButton in pairs(tabButtons) do
		tabButton.BackgroundColor3 = tabButton.Name == savedTab .. "Tab" and theme.accent or theme.surface
	end
	if selfGlowEnabled then
		applySelfHighlight()
	end
end)

local sizeChoices = {
	UDim2.fromScale(0.82, 0.72),
	UDim2.fromScale(0.90, 0.78),
	UDim2.fromScale(0.95, 0.84),
}
local sizeIndex = 2

settingsRow("Adjust panel size", "Medium", function(button)
	sizeIndex = (sizeIndex % #sizeChoices) + 1
	button.Text = ({"Small", "Medium", "Large"})[sizeIndex]
	main.Size = sizeChoices[sizeIndex]
end)

settingsRow("Reset panel position", "Reset", function()
	main.Position = UDim2.fromScale(0.5, 0.5)
end)

settingsRow("Reset visual settings", "Reset", function()
	selfGlowEnabled = false
	effectButton.Text = "Enable self space glow"
	clearHighlight()
	notify("Local visual settings reset.")
end)

-- Player information and distance.
local function rootPart(target)
	local character = target and target.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function publishedRole(target)
	if stateFolder then
		local murdererId = tonumber(stateFolder:GetAttribute("MurdererUserId"))
		local sheriffId = tonumber(stateFolder:GetAttribute("SheriffUserId"))
		if murdererId == target.UserId then
			return "Murderer"
		elseif sheriffId == target.UserId then
			return "Sheriff"
		end
	end

	local role = target:GetAttribute("MM2Role")
	return typeof(role) == "string" and role or "Unknown"
end

local function distanceTo(target)
	local myRoot = rootPart(player)
	local targetRoot = rootPart(target)
	if myRoot and targetRoot then
		return (myRoot.Position - targetRoot.Position).Magnitude
	end
	return nil
end

local function updateProfile()
	if not selectedPlayer or not selectedPlayer.Parent then
		profile.Text = "Select a player to view their profile."
		return
	end

	local distance = distanceTo(selectedPlayer)
	local distanceText = distance and (math.floor(distance + 0.5) .. " studs") or "Unavailable"

	profile.Text = string.format(
		"PLAYER PROFILE\n\nDisplay name: %s\nUsername: @%s\nUserId: %d\nAccount age: %d days\nPublished role: %s\nDistance: %s",
		selectedPlayer.DisplayName,
		selectedPlayer.Name,
		selectedPlayer.UserId,
		selectedPlayer.AccountAge,
		publishedRole(selectedPlayer),
		distanceText
	)
end

local function refreshPlayers()
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local query = string.lower(search.Text)
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		return string.lower(a.DisplayName) < string.lower(b.DisplayName)
	end)

	for _, target in ipairs(list) do
		local textToSearch = string.lower(target.Name .. " " .. target.DisplayName)
		if query == "" or string.find(textToSearch, query, 1, true) then
			local distance = distanceTo(target)
			local distanceText = distance and (math.floor(distance + 0.5) .. " studs") or "—"

			local button = make("TextButton", playerList, {
				Size = UDim2.new(1, -8, 0, 42),
				BackgroundColor3 = target == selectedPlayer and theme.accent or theme.surface,
				Text = string.format("%s  |  %s  |  %s", target.DisplayName, publishedRole(target), distanceText),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextWrapped = true,
			})
			rounded(button, 8)
			button.Activated:Connect(function()
				selectedPlayer = target
				updateProfile()
				refreshPlayers()
			end)
		end
	end

	updateProfile()
end

search:GetPropertyChangedSignal("Text"):Connect(refreshPlayers)
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(leaving)
	if selectedPlayer == leaving then
		selectedPlayer = nil
	end
	refreshPlayers()
end)

-- Optional role/round notifications from your own server.
local function playerNameFromId(value)
	local id = tonumber(value)
	if not id then
		return "Unknown"
	end
	for _, target in ipairs(Players:GetPlayers()) do
		if target.UserId == id then
			return target.DisplayName
		end
	end
	return "Player " .. tostring(id)
end

local function refreshRoundInfo()
	if not stateFolder then
		roundInfo.Text = "No server-published round data available."
		return
	end

	local round = stateFolder:GetAttribute("RoundStatus") or "Unknown"
	local murdererId = stateFolder:GetAttribute("MurdererUserId")
	local sheriffId = stateFolder:GetAttribute("SheriffUserId")
	local gunDropped = stateFolder:GetAttribute("SheriffGunDropped") == true

	roundInfo.Text = string.format(
		"AUTHORIZED TEST SERVER DATA\n\nRound: %s\nMurderer: %s\nSheriff: %s\nSheriff gun reported dropped: %s",
		tostring(round),
		murdererId and playerNameFromId(murdererId) or "Not provided",
		sheriffId and playerNameFromId(sheriffId) or "Not provided",
		gunDropped and "Yes" or "No"
	)
end

local function bindState(folder)
	for _, connection in ipairs(stateConnections) do
		connection:Disconnect()
	end
	table.clear(stateConnections)

	stateFolder = folder
	previousRound = folder:GetAttribute("RoundStatus")
	previousMurderer = folder:GetAttribute("MurdererUserId")
	previousSheriff = folder:GetAttribute("SheriffUserId")
	previousGunDropped = folder:GetAttribute("SheriffGunDropped") == true

	local watchedAttributes = {
		"RoundStatus",
		"MurdererUserId",
		"SheriffUserId",
		"SheriffGunDropped",
	}

	for _, attribute in ipairs(watchedAttributes) do
		table.insert(stateConnections, folder:GetAttributeChangedSignal(attribute):Connect(function()
			local value = folder:GetAttribute(attribute)

			if attribute == "RoundStatus" and previousRound ~= nil and value ~= previousRound then
				notify("Round status changed: " .. tostring(value))
				previousRound = value
			elseif attribute == "MurdererUserId" and previousMurderer ~= nil and value ~= previousMurderer then
				notify("Published Murderer changed: " .. playerNameFromId(value))
				previousMurderer = value
			elseif attribute == "SheriffUserId" and previousSheriff ~= nil and value ~= previousSheriff then
				notify("Published Sheriff changed: " .. playerNameFromId(value))
				previousSheriff = value
			elseif attribute == "SheriffGunDropped" then
				local dropped = value == true
				if dropped and not previousGunDropped then
					notify("The test server reported a dropped Sheriff gun.")
				end
				previousGunDropped = dropped
			end

			refreshRoundInfo()
			refreshPlayers()
		end))
	end

	refreshRoundInfo()
	refreshPlayers()
end

local existingState = ReplicatedStorage:FindFirstChild("MM2PublicState")
if existingState and existingState:IsA("Folder") then
	bindState(existingState)
end

ReplicatedStorage.ChildAdded:Connect(function(child)
	if child.Name == "MM2PublicState" and child:IsA("Folder") then
		bindState(child)
	end
end)

-- Draggable main window, dragged from the header.
do
	local dragging = false
	local dragStart
	local startPosition

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

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPosition.X.Scale, startPosition.X.Offset + delta.X,
				startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

-- Circular floating logo with automatic primary -> backup -> fallback icon.
local floating = make("TextButton", gui, {
	Name = "FloatingLogo",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -18, 1, -22),
	Size = UDim2.new(0, 62, 0, 62),
	BackgroundColor3 = theme.surface,
	Text = "B",
	TextColor3 = theme.accent,
	TextSize = 27,
	Font = Enum.Font.GothamBold,
	Visible = false,
	ClipsDescendants = true,
	AutoButtonColor = false,
})
rounded(floating, 100)

make("UIStroke", floating, {
	Color = theme.accent,
	Thickness = 2,
	Transparency = 0.1,
})

local logoImage = make("ImageLabel", floating, {
	Name = "LogoImage",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
	Visible = false,
})
rounded(logoImage, 100)

local function tryLogo(assetId)
	local loaded = false
	local asset = assetId

	local success = pcall(function()
		ContentProvider:PreloadAsync({asset}, function(_, status)
			if status == Enum.AssetFetchStatus.Success then
				loaded = true
			end
		end)
	end)

	if success and loaded then
		logoImage.Image = asset
		logoImage.Visible = true
		floating.Text = ""
		return true
	end
	return false
end

task.spawn(function()
	if not tryLogo(PRIMARY_LOGO) then
		if not tryLogo(BACKUP_LOGO) then
			logoImage.Visible = false
			floating.Text = "B"
		end
	end
end)

local function reopenMenu()
	main.Visible = true
	floating.Visible = false
	setTab(savedTab)
end

minimize.Activated:Connect(function()
	main.Visible = false
	floating.Visible = true
end)

-- Drag the logo; a short tap reopens the menu.
do
	local activeInput
	local startPosition
	local startPoint
	local wasDragged = false

	floating.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			activeInput = input
			startPosition = floating.Position
			startPoint = input.Position
			wasDragged = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if activeInput and (input == activeInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - startPoint
			if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then
				wasDragged = true
				floating.Position = UDim2.new(
					startPosition.X.Scale, startPosition.X.Offset + delta.X,
					startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
				)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if activeInput and (input == activeInput
			or input.UserInputType == Enum.UserInputType.MouseButton1) then
			if not wasDragged then
				reopenMenu()
			end
			activeInput = nil
		end
	end)
end

setTab(savedTab)
refreshPlayers()
refreshRoundInfo()

task.spawn(function()
	while gui.Parent do
		task.wait(2)
		if main.Visible then
			refreshPlayers()
		end
	end
end)
