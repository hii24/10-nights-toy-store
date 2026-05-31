--!strict
-- UpgradeUiController — мини-UI выбора апгрейда (НЕ Fusion — это P1-07). Показывает карты в
-- Upgrade-фазе; по клику шлёт SelectUpgrade (намерение). Истина — от сервера (применяет Humanoid).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local UpgradeConfig = require(Config:WaitForChild("UpgradeConfig"))
local Net = require(Shared:WaitForChild("Net"):WaitForChild("Net"))

local ATTR_STATE = "RoundState"
local STATE_UPGRADE = "Upgrade"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local selectUpgrade = Net.get("SelectUpgrade")

local gui = Instance.new("ScreenGui")
gui.Name = "UpgradeUi"
gui.ResetOnSpawn = false
gui.Enabled = false

local holder = Instance.new("Frame")
holder.Size = UDim2.fromScale(0.6, 0.22)
holder.Position = UDim2.fromScale(0.2, 0.62)
holder.BackgroundTransparency = 1
holder.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0.02, 0)
layout.Parent = holder

local chosenThisPhase = false

for _, card in UpgradeConfig.cards do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(0.3, 1)
	btn.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Text = `{card.name}\n{card.desc}`
	btn.Parent = holder
	btn.Activated:Connect(function()
		if chosenThisPhase then
			return
		end
		chosenThisPhase = true
		selectUpgrade:FireServer(card.id)
		gui.Enabled = false
	end)
end

local function render()
	local isUpgrade = Workspace:GetAttribute(ATTR_STATE) == STATE_UPGRADE
	if isUpgrade then
		chosenThisPhase = false -- новая фаза → снова можно выбрать
	end
	gui.Enabled = isUpgrade and not chosenThisPhase
end

gui.Parent = playerGui
Workspace:GetAttributeChangedSignal(ATTR_STATE):Connect(render)
render()
