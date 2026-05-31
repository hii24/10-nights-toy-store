--!strict
-- RoundUiController — минимальный экран матча (НЕ Fusion-HUD, это P1-07).
-- Читает Workspace.RoundState/RoundTimeLeft/RoundNight → центр-текст стадии/ночи.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ATTR_STATE = "RoundState"
local ATTR_TIME = "RoundTimeLeft"
local ATTR_NIGHT = "RoundNight"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RoundUi"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 0.18)
label.Position = UDim2.fromScale(0, 0.06)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0.4
label.Text = ""
label.Parent = gui

gui.Parent = playerGui

local function render()
	local state = Workspace:GetAttribute(ATTR_STATE)
	local timeLeft = Workspace:GetAttribute(ATTR_TIME)
	local night = Workspace:GetAttribute(ATTR_NIGHT)
	local t = if typeof(timeLeft) == "number" then tostring(math.floor(timeLeft)) else "0"
	local n = if typeof(night) == "number" then tostring(night) else "?"

	if state == "Preparation" then
		label.Text = `Get ready... {t}s`
	elseif state == "Night" then
		label.Text = `NIGHT {n} - SURVIVE {t}s`
	elseif state == "Morning" then
		label.Text = `NIGHT {n} SURVIVED`
	elseif state == "Upgrade" then
		label.Text = `UPGRADE... {t}s`
	elseif state == "EndMatch" then
		label.Text = "YOU WON - ALL NIGHTS SURVIVED"
	elseif state == "Lost" then
		label.Text = `CAUGHT! (Night {n})`
	else
		label.Text = ""
	end
end

Workspace:GetAttributeChangedSignal(ATTR_STATE):Connect(render)
Workspace:GetAttributeChangedSignal(ATTR_TIME):Connect(render)
Workspace:GetAttributeChangedSignal(ATTR_NIGHT):Connect(render)
render()
