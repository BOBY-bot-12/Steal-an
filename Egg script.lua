local Players = game:GetService("Players")

local RARITIES = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
	"Divine",
	"Cosmic"
}

local STEAL_TIME = 1
local MAX_DISTANCE = 15
local COOLDOWN = 0.25

local settings = {}
local busy = {}

local function createSettings(player)
	settings[player] = {}

	for _, rarity in ipairs(RARITIES) do
		settings[player][rarity] = true
	end
end

Players.PlayerAdded:Connect(createSettings)

Players.PlayerRemoving:Connect(function(player)
	settings[player] = nil
	busy[player] = nil
end)

-- Create GUI
local function createGUI(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "EggStealGUI"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(260, 390)
	frame.Position = UDim2.new(0, 20, 0.5, -195)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.Parent = gui

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 45)
	title.BackgroundTransparency = 1
	title.Text = "🥚 EGG STEAL"
	title.TextSize = 22
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1,1,1)
	title.Parent = frame

	local y = 50

	for _, rarity in ipairs(RARITIES) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -30, 0, 36)
		button.Position = UDim2.new(0, 15, 0, y)
		button.Text = "✓  " .. rarity
		button.TextSize = 16
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = Color3.new(1,1,1)
		button.BackgroundColor3 = Color3.fromRGB(55, 145, 70)
		button.Parent = frame

		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

		button.MouseButton1Click:Connect(function()
			settings[player][rarity] = not settings[player][rarity]

			if settings[player][rarity] then
				button.Text = "✓  " .. rarity
				button.BackgroundColor3 = Color3.fromRGB(55, 145, 70)
			else
				button.Text = "✕  " .. rarity
				button.BackgroundColor3 = Color3.fromRGB(145, 55, 55)
			end
		end)

		y += 40
	end

	local speed = Instance.new("TextLabel")
	speed.Size = UDim2.new(1, 0, 0, 30)
	speed.Position = UDim2.new(0, 0, 0, y)
	speed.BackgroundTransparency = 1
	speed.Text = "⚡ Steal Speed: 1 Second"
	speed.TextSize = 16
	speed.Font = Enum.Font.GothamBold
	speed.TextColor3 = Color3.new(1,1,1)
	speed.Parent = frame
end

local function getPart(egg)
	if egg:IsA("BasePart") then
		return egg
	end

	if egg:IsA("Model") then
		return egg.PrimaryPart
			or egg:FindFirstChildWhichIsA("BasePart", true)
	end
end

local function steal(player, egg)
	if busy[player] then
		return
	end

	if not settings[player] then
		return
	end

	if not egg or not egg:IsDescendantOf(workspace) then
		return
	end

	local rarity = egg:GetAttribute("Rarity")

	if not rarity or not settings[player][rarity] then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local part = getPart(egg)

	if not root or not part then
		return
	end

	if (root.Position - part.Position).Magnitude > MAX_DISTANCE then
		return
	end

	busy[player] = true

	-- Fixed 1-second steal time
	task.wait(STEAL_TIME)

	if not egg:IsDescendantOf(workspace) then
		busy[player] = nil
		return
	end

	-- Check player is still close
	character = player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")

	if not root or (root.Position - part.Position).Magnitude > MAX_DISTANCE then
		busy[player] = nil
		return
	end

	local inventory = player:FindFirstChild("Inventory")

	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "Inventory"
		inventory.Parent = player
	end

	local newEgg = Instance.new("StringValue")
	newEgg.Name = egg.Name
	newEgg.Value = rarity
	newEgg.Parent = inventory

	egg:Destroy()

	task.wait(COOLDOWN)
	busy[player] = nil
end

local function setupEgg(egg)
	local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)

	if not prompt then
		return
	end

	if prompt:GetAttribute("EggConnected") then
		return
	end

	prompt:SetAttribute("EggConnected", true)

	prompt.Triggered:Connect(function(player)
		steal(player, egg)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	if not settings[player] then
		createSettings(player)
	end

	task.spawn(createGUI, player)
end

Players.PlayerAdded:Connect(function(player)
	createSettings(player)
	task.spawn(createGUI, player)
end)

for _, object in ipairs(workspace:GetDescendants()) do
	if (object:IsA("Model") or object:IsA("BasePart"))
		and object:GetAttribute("Rarity") then
		setupEgg(object)
	end
end

workspace.DescendantAdded:Connect(function(object)
	if (object:IsA("Model") or object:IsA("BasePart"))
		and object:GetAttribute("Rarity") then
		task.wait()
		setupEgg(object)
	end
end)
