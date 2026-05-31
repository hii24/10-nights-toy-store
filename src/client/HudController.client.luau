--!strict
-- HudController — Fusion-HUD (P1-07), реактивный к СЕРВЕРНОМУ состоянию (docs/01: клиент = UI/ввод).
-- Источники — бродкаст-атрибуты (Player/Workspace). Читаемо/по углам (мобильно), центр свободен.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages:WaitForChild("Fusion"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local RoundConfig = require(Config:WaitForChild("RoundConfig"))
local GeneratorConfig = require(Config:WaitForChild("GeneratorConfig"))

local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local scope = Fusion.scoped(Fusion)

-- Fusion Value, провязанный к атрибуту инстанса (начальное чтение + GetAttributeChangedSignal).
local function attrValue(instance: Instance, attr: string, default: any)
	local value = scope:Value(instance:GetAttribute(attr) or default)
	instance:GetAttributeChangedSignal(attr):Connect(function()
		value:set(instance:GetAttribute(attr) or default)
	end)
	return value
end

local batteries = attrValue(player, "Batteries", 0)
local power = attrValue(Workspace, "GeneratorPower", 0)
local night = attrValue(Workspace, "RoundNight", 0)
local repairProgress = attrValue(player, "RepairProgress", 0)
local inToyBox = attrValue(player, "InToyBox", false)
local boxedCount = attrValue(Workspace, "BoxedCount", 0)

local WHITE = Color3.fromRGB(255, 255, 255)
local PANEL = Color3.fromRGB(18, 20, 28)
local POWER_COLOR = Color3.fromRGB(120, 200, 120)
local REPAIR_COLOR = Color3.fromRGB(230, 200, 90)
local WARN_COLOR = Color3.fromRGB(225, 85, 75)

-- TextLabel с читаемыми дефолтами (мобильно: TextScaled, жирный, обводка).
local function text(props: any): any
	props.BackgroundTransparency = if props.BackgroundTransparency == nil
		then 1
		else props.BackgroundTransparency
	props.Font = Enum.Font.GothamBold
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextStrokeTransparency = 0.4
	return scope:New("TextLabel")(props)
end

-- Прогресс-бар: фон + фронт по доле fill (Computed [0..1]). size/position — внутри родителя.
local function progressBar(fill: any, color: Color3, size: UDim2, position: UDim2): any
	return scope:New("Frame")({
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 1),
		Position = position,
		Size = size,
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.3,
		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 6) }),
			scope:New("Frame")({
				Name = "Fill",
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Size = scope:Computed(function(use)
					return UDim2.fromScale(math.clamp(use(fill), 0, 1), 1)
				end),
				[Children] = { scope:New("UICorner")({ CornerRadius = UDim.new(0, 6) }) },
			}),
		},
	})
end

scope:New("ScreenGui")({
	Name = "Hud",
	ResetOnSpawn = false,
	IgnoreGuiInset = false, -- Roblox учитывает безопасные зоны (нотч/home bar) — мобильно
	Parent = playerGui,
	[Children] = {
		-- Счётчик ночи (верх-право).
		text({
			Name = "NightLabel",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(0.98, 0.05),
			Size = UDim2.fromScale(0.22, 0.06),
			TextXAlignment = Enum.TextXAlignment.Right,
			Visible = scope:Computed(function(use)
				return use(night) > 0
			end),
			Text = scope:Computed(function(use)
				return `NIGHT {use(night)}/{RoundConfig.nightCount}`
			end),
		}),

		-- Батарея + power-бар (низ-лево).
		scope:New("Frame")({
			Name = "Supplies",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0.02, 0.92),
			Size = UDim2.fromScale(0.26, 0.1),
			BackgroundTransparency = 1,
			[Children] = {
				text({
					Name = "BatteryLabel",
					Size = UDim2.fromScale(1, 0.45),
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = scope:Computed(function(use)
						return `Batteries: {use(batteries)}`
					end),
				}),
				progressBar(
					scope:Computed(function(use)
						return (use(power) :: number) / GeneratorConfig.maxPower
					end),
					POWER_COLOR,
					UDim2.fromScale(1, 0.4),
					UDim2.fromScale(0, 1)
				),
			},
		}),

		-- Прогресс ремонта (низ-центр), виден при 0<p<1.
		scope:New("Frame")({
			Name = "Repair",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.86),
			Size = UDim2.fromScale(0.4, 0.075),
			BackgroundTransparency = 1,
			Visible = scope:Computed(function(use)
				local p = use(repairProgress) :: number
				return p > 0 and p < 1
			end),
			[Children] = {
				text({
					Name = "RepairLabel",
					Position = UDim2.fromScale(0, 0),
					Size = UDim2.fromScale(1, 0.45),
					Text = "REPAIRING...",
				}),
				progressBar(
					repairProgress,
					REPAIR_COLOR,
					UDim2.fromScale(1, 0.45),
					UDim2.fromScale(0, 1)
				),
			},
		}),

		-- Revive-промпт (верх-центр).
		text({
			Name = "ReviveLabel",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.27),
			Size = UDim2.fromScale(0.6, 0.06),
			TextColor3 = WARN_COLOR,
			Visible = scope:Computed(function(use)
				return use(inToyBox) == true or (use(boxedCount) :: number) > 0
			end),
			Text = scope:Computed(function(use)
				if use(inToyBox) == true then
					return "CAUGHT! Wait for a teammate to free you"
				elseif (use(boxedCount) :: number) > 0 then
					return "Teammate caught - free them at the Toy Box"
				end
				return ""
			end),
		}),
	},
})
