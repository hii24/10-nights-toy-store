--!strict
-- RemoteSchema — единый реестр RemoteEvent'ов (docs/02). Сервер создаёт инстансы, клиент ждёт.
-- Добавлять remote ТОЛЬКО сюда + серверный handler с middleware (см. /add-validated-remote).

local RemoteSchema = {
	"SelectUpgrade", -- client→server: выбор апгрейд-карты (id: string) в Upgrade-фазе
}

return RemoteSchema
