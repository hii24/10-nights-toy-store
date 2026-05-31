--!strict
-- UpgradeUiController — Fusion-карточки выбора апгрейда (P1-07 поднял мини-UI из P1-06 до Fusion).
-- Показ при RoundState==Upgrade; по клику шлёт SelectUpgrade (намерение). Истина — сервер (P1-06).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages:WaitForChild("Fusion"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local UpgradeConfig = require(Config:WaitForChild("UpgradeConfig"))
local Net = require(Shared:WaitForChild("Net"):WaitForChild("Net"))

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

local STATE_UPGRADE = "Upgrade"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local selectUpgrade = Net.get("SelectUpgrade")

local scope = Fusion.scoped(Fusion)

local roundState = scope:Value(Workspace:GetAttribute("RoundState"))
local chosenThisPhase = scope:Value(false)
Workspace:GetAttributeChangedSignal("RoundState"):Connect(function()
	local state = Workspace:GetAttribute("RoundState")
	roundState:set(state)
	if state == STATE_UPGRADE then
		chosenThisPhase:set(false) -- новая фаза → снова можно выбрать
	end
end)

local function card(def: any): any
	return scope:New("TextButton")({
		Name = def.id,
		Size = UDim2.fromScale(0.3, 1),
		BackgroundColor3 = Color3.fromRGB(40, 44, 60),
		BackgroundTransparency = 0.1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextStrokeTransparency = 0.4, -- контраст на светлом фоне (мобильно)
		Text = `{def.name}\n{def.desc}`,
		[OnEvent("Activated")] = function()
			if peek(chosenThisPhase) then
				return
			end
			chosenThisPhase:set(true)
			selectUpgrade:FireServer(def.id)
		end,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			scope:New("UISizeConstraint")({ MinSize = Vector2.new(90, 50) }), -- тапабельно на телефоне
		},
	})
end

local cardButtons = {}
for _, def in UpgradeConfig.cards do
	table.insert(cardButtons, card(def))
end

scope:New("ScreenGui")({
	Name = "UpgradeUi",
	ResetOnSpawn = false,
	IgnoreGuiInset = false, -- safe zones; выровнено с HUD/RoundUi (P1-07)
	Enabled = scope:Computed(function(use)
		return use(roundState) == STATE_UPGRADE and not use(chosenThisPhase)
	end),
	Parent = playerGui,
	[Children] = {
		scope:New("Frame")({
			Name = "Cards",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.74),
			Size = UDim2.fromScale(0.62, 0.2),
			BackgroundTransparency = 1,
			[Children] = {
				scope:New("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0.02, 0),
				}),
				table.unpack(cardButtons),
			},
		}),
	},
})
