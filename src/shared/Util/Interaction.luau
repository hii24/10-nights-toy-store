--!strict
-- Interaction — серверная перепроверка дистанции для интеракций (P1-10, docs/02).
-- ПОЧЕМУ: `ProximityPrompt.MaxActivationDistance`/`RequiresLineOfSight` энфорсятся на КЛИЕНТЕ;
-- эксплойтер шлёт `Triggered`/`PromptButtonHoldBegan` с любой дистанции. docs/02 требует валидировать
-- prompt как RemoteEvent (bounds — в т.ч. спатиальные). Поэтому сервер ОБЯЗАН перепроверить близость
-- ДО мутации. Чистое ядро `within` — тестируемо.

local Interaction = {}

-- Слэк на десинк позиции клиент↔сервер: легитимная активация у края промпта не должна отвергаться
-- (серверный HRP может слегка отставать). Блокирует «через всю карту», пропускает граничные.
Interaction.RANGE_SLACK = 1.5

-- Чистый: точка `a` в пределах `maxDistance` от `b`? (юнит-тестируемо)
function Interaction.within(a: Vector3, b: Vector3, maxDistance: number): boolean
	return (a - b).Magnitude <= maxDistance
end

-- Игрок (его HRP) в пределах `maxDistance` * SLACK от `position`? Нет персонажа/HRP → false.
-- Зовётся серверными prompt-хендлерами ДО мутации.
function Interaction.playerWithin(player: Player, position: Vector3, maxDistance: number): boolean
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	return Interaction.within(hrp.Position, position, maxDistance * Interaction.RANGE_SLACK)
end

return Interaction
