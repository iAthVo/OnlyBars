--[[
	OnlyBars · Core/Combat.lua
	Combat queue: protected changes wait for the end of combat.
	Cola de combate: los cambios protegidos esperan a que termine el combate.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local Combat = {}
ns.Combat = Combat

local queue, order = {}, {}
local warned = false

-- Runs fn now, or after combat. The same key queued twice runs once (the last one).
-- silent: automatic updates (zone, equipment) do not warn in chat.
-- Ejecuta fn ahora o al salir de combate. La misma clave encolada dos veces se
-- ejecuta una sola vez (la última).
-- silent: las actualizaciones automáticas (zona, equipo) no avisan en el chat.
function Combat:Run(key, fn, silent)
	if not InCombatLockdown() then
		fn()
		return true
	end
	if not queue[key] then
		order[#order + 1] = key
	end
	queue[key] = fn
	if not warned and not silent then
		warned = true
		U.Print(L.COMBAT_QUEUED)
	end
	return false
end

ns:On("PLAYER_REGEN_ENABLED", function()
	warned = false
	local keys, fns = order, queue
	order, queue = {}, {}
	for _, key in ipairs(keys) do
		ns.Log.Call(fns[key])
	end
end)
