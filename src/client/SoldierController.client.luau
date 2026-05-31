--!strict
-- SoldierController — клиентский knockback от Wind-Up Soldier (P1-02).
-- Сервер (EnemyService) — авторитет: ставит атрибуты SoldierPushTick/X/Z на Player.
-- Клиент применяет импульс СВОЕМУ персонажу (он владеет его физикой — серверный пуш чужого
-- персонажа откатывается сетевым владением, см. журнал P1-01). Без RemoteEvent (атрибут-broadcast).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local EnemyConfig = require(Config:WaitForChild("EnemyConfig"))

local ATTR_PUSH_TICK = "SoldierPushTick"
local ATTR_PUSH_X = "SoldierPushX"
local ATTR_PUSH_Z = "SoldierPushZ"

local player = Players.LocalPlayer

local function applyPush()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local x = player:GetAttribute(ATTR_PUSH_X)
	local z = player:GetAttribute(ATTR_PUSH_Z)
	if typeof(x) ~= "number" or typeof(z) ~= "number" then
		return
	end

	local horizontal = Vector3.new(x, 0, z)
	if horizontal.Magnitude < 0.05 then
		return
	end

	-- Impulse = Δvelocity * mass → горизонтальный толчок + лёгкий подброс.
	local mass = hrp.AssemblyMass
	local impulse = horizontal.Unit * (EnemyConfig.soldierPushForce * mass)
		+ Vector3.new(0, EnemyConfig.soldierPushUp * mass, 0)
	hrp:ApplyImpulse(impulse)
end

-- Толчок инициируется сервером через инкремент SoldierPushTick на Player.
player:GetAttributeChangedSignal(ATTR_PUSH_TICK):Connect(applyPush)
