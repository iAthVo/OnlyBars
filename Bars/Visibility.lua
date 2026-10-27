--[[
	OnlyBars · Bars/Visibility.lua
	When each bar is shown (D-26), like Blizzard's transmog situations:
	• Location, specialization and equipment set: checked in Lua out of combat
	  and handed to the bar as the "ob-allowed" attribute.
	• State (combat, mounted, target, group, vehicle): a secure state driver,
	  so it also changes in combat.
	• Mouseover: transparency only, allowed in combat.
	Cuándo se muestra cada barra (D-26), como las situaciones de la
	transfiguración de Blizzard:
	• Ubicación, especialización y conjunto de equipo: se revisan en Lua fuera
	  de combate y se pasan a la barra como el atributo "ob-allowed".
	• Estado (combate, montado, objetivo, grupo, vehículo): un controlador de
	  estados seguro, así también cambia en combate.
	• Al pasar el mouse: solo transparencia, permitida en combate.
	© 2026 iAthVo_Kr
]]

local _, ns = ...

local Visibility = {}
ns.Visibility = Visibility

-- Runs in the restricted environment, also in combat. Shows or hides the bar,
-- and turns its keys on while it is shown, or always with "Teclas activas
-- aunque esté oculta" (D-52). Keys come from the "ob-key<i>" attributes.
-- Corre en el entorno restringido, también en combate. Muestra u oculta la
-- barra, y enciende sus teclas mientras se ve, o siempre con "Teclas activas
-- aunque esté oculta" (D-52). Las teclas salen de los atributos "ob-key<i>".
local SNIPPET = [[
	local shown = self:GetAttribute("ob-force") or (newstate == "show" and self:GetAttribute("ob-allowed"))
	if shown then self:Show() else self:Hide() end
	self:ClearBindings()
	if shown or self:GetAttribute("ob-keysalways") then
		for i = 1, 12 do
			local key = self:GetAttribute("ob-key" .. i)
			if key then self:SetBindingClick(true, key, self:GetAttribute("ob-btn" .. i), "Keybind") end
		end
	end
]]

-- Out of combat, the same as the snippet, from Lua (D-52). Override bindings
-- leave Blizzard's own bindings untouched (D-49).
-- Fuera de combate, lo mismo que el fragmento, desde Lua (D-52). Los atajos de
-- prioridad dejan intactos los atajos de Blizzard (D-49).
local function ApplyKeys(f, shown)
	local keys = ns.DB:ActiveSet(f.data).keys
	local layout = f.layout
	ClearOverrideBindings(f)
	for i = 1, ns.MAX_BUTTONS do
		local b = f.buttons[i]
		local key = i <= layout.buttons and b and keys[i] or nil
		f:SetAttribute("ob-key" .. i, key)
		f:SetAttribute("ob-btn" .. i, b and b:GetName() or nil)
		if key and (shown or layout.keysAlways) then
			SetOverrideBindingClick(f, true, key, b:GetName(), "Keybind")
		end
	end
	f:SetAttribute("ob-keysalways", layout.keysAlways and true or false)
	-- Keys act on press if Blizzard's option says so (Bars/Buttons.lua).
	-- Las teclas actúan al presionar si la opción de Blizzard lo dice (Bars/Buttons.lua).
	f:SetAttribute("ob-keydown", GetCVarBool("ActionButtonUseKeyDown"))
end

---------------------------------------------------------------------------
-- Location, spec, equipment set / Ubicación, spec, conjunto de equipo
---------------------------------------------------------------------------
local INSTANCE_LOCATION = {
	party = "dungeon",
	raid = "raid",
	scenario = "delve",
	pvp = "battleground",
	arena = "arena",
}

-- Where the player is now. Open world and rest areas are separate places
-- (0.7.4): a city or inn is a rest area, not open world.
-- Dónde está el jugador ahora. Mundo abierto y áreas de descanso son lugares
-- distintos (0.7.4): una ciudad o posada es área de descanso, no mundo abierto.
function Visibility:Locations()
	local here = {}
	local inInstance, instanceType = IsInInstance()
	local resting = IsResting()
	if not inInstance or instanceType == "none" then
		if resting then here.rest = true else here.world = true end
	else
		if INSTANCE_LOCATION[instanceType] then here[INSTANCE_LOCATION[instanceType]] = true end
		if resting then here.rest = true end
	end
	return here
end

-- Is that equipment set worn now? / ¿Ese conjunto de equipo está puesto ahora?
local function IsSetEquipped(name)
	local setID = C_EquipmentSet.GetEquipmentSetID(name)
	if not setID then return false end
	local _, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
	return isEquipped and true or false
end

-- Any marked option in the category holds; an empty category always holds.
-- Se cumple alguna opción marcada de la categoría; una categoría vacía siempre se cumple.
local function AnyHolds(marked, holds)
	if next(marked) == nil then return true end
	for key in pairs(marked) do
		if holds(key) then return true end
	end
	return false
end

-- Location, spec and equipment: may the bar show here? (checked in Lua) / Ubicación, spec y equipo: ¿la barra se puede ver aquí? (se revisa en Lua)
function Visibility:Allowed(data, vis)
	-- A Per-spec bar only shows in its checked specs (D-54, D-60).
	-- Una barra por spec solo se ve en sus specs marcadas (D-54, D-60).
	if data.hidden or not ns.DB:InSpec(data) then return false end
	local here = self:Locations()
	return AnyHolds(vis.location, function(key) return here[key] end)
		and AnyHolds(vis.equipset, IsSetEquipped)
end

---------------------------------------------------------------------------
-- State driver / Controlador de estados
-- 1. Filters hide first and always apply (D-66): vehicle and pet battle,
--    mount, target.
-- 2. "Mostrar solo si…" shows (D-55); without combat or group it is the only
--    way to show the bar (D-61).
-- 3. Combat and group hide when not met; otherwise it shows.
-- 1. Los filtros ocultan primero y siempre se aplican (D-66): vehículo y
--    batalla de mascotas, montura, objetivo.
-- 2. "Mostrar solo si…" muestra (D-55); sin combate ni grupo es la única
--    forma de mostrar la barra (D-61).
-- 3. Combate y grupo ocultan si no se cumplen; si no, se muestra.
---------------------------------------------------------------------------
local TARGET_HIDES = {
	exists = "[@target,noexists] hide",
	harm = "[@target,noharm] hide",
	help = "[@target,nohelp] hide",
}

-- The macro-condition string for the secure state driver / La cadena de condiciones de macro para el controlador seguro
function Visibility:Driver(vis)
	local parts = {}
	if vis.hideVehicle then
		parts[#parts + 1] = "[vehicleui] hide"
		parts[#parts + 1] = "[petbattle] hide"
	end
	if vis.mounted == "yes" then parts[#parts + 1] = "[nomounted] hide" end
	if vis.mounted == "no" then parts[#parts + 1] = "[mounted] hide" end
	if TARGET_HIDES[vis.target] then parts[#parts + 1] = TARGET_HIDES[vis.target] end
	local shows = #parts
	for _, def in ipairs(ns.Settings.SHOW_IF) do
		if vis.showIf[def.key] then parts[#parts + 1] = def.condition .. " show" end
	end
	-- Without Estado (D-61) the checks are the only way to show the bar:
	-- otherwise it hides. A bar that still uses both keeps D-55's "or".
	-- Sin Estado (D-61) las casillas son la única forma de mostrar la barra:
	-- si no, se oculta. Una barra que aún usa los dos conserva el "o" de D-55.
	if #parts > shows and not self:UsesState(vis) then
		parts[#parts + 1] = "hide"
		return table.concat(parts, "; ")
	end
	if vis.combat == "in" then parts[#parts + 1] = "[nocombat] hide" end
	if vis.combat == "out" then parts[#parts + 1] = "[combat] hide" end
	if vis.group then parts[#parts + 1] = "[nogroup] hide" end
	parts[#parts + 1] = "show"
	return table.concat(parts, "; ")
end

---------------------------------------------------------------------------
-- Never at the same time (D-59): two bars may share a key only if their
-- situations can never let both be active. Bars of different specs never
-- clash: keys are only compared within the current spec (D-60). Only what the
-- bars guarantee counts: location and mount always (a filter, D-66); combat
-- only without "Mostrar solo si…", which can show a bar in either (D-55).
-- Nunca al mismo tiempo (D-59): dos barras pueden compartir tecla solo si sus
-- situaciones nunca dejan que ambas estén activas. Barras de specs distintas
-- nunca chocan: las teclas solo se comparan dentro de la spec actual (D-60).
-- Solo cuenta lo que las barras garantizan: ubicación y montura siempre (un
-- filtro, D-66); combate solo sin "Mostrar solo si…", que puede mostrar la
-- barra en cualquiera (D-55).
---------------------------------------------------------------------------
-- Where the player can be at once (Locations): open world or a rest area, or
-- an instance that may also be a rest area.
-- Dónde puede estar el jugador a la vez (Locations): mundo abierto o área de
-- descanso, o una instancia que también puede ser área de descanso.
local PLACES = { { world = true }, { rest = true } }
for _, key in ipairs({ "dungeon", "raid", "delve", "battleground", "arena" }) do
	PLACES[#PLACES + 1] = { [key] = true }
	PLACES[#PLACES + 1] = { [key] = true, rest = true }
end

-- Does the bar use "Mostrar solo si…"? / ¿La barra usa "Mostrar solo si…"?
local function HasExceptions(vis)
	return next(vis.showIf) ~= nil
end

-- Combat and group are not used together with "Mostrar solo si…" (D-61):
-- the panel locks one while the other has something marked. Filters (mount,
-- target, vehicle) always apply, so they do not count (D-66).
-- Combate y grupo no se usan junto con "Mostrar solo si…" (D-61): el panel
-- bloquea uno mientras el otro tiene algo marcado. Los filtros (montura,
-- objetivo, vehículo) siempre se aplican, así que no cuentan (D-66).
function Visibility:UsesState(vis)
	return vis.combat == "in" or vis.combat == "out" or vis.group
end

-- Has any "Mostrar solo si…" check marked / Tiene marcada alguna casilla de "Mostrar solo si…"
function Visibility:UsesShowIf(vis)
	return next(vis.showIf) ~= nil
end

-- The combat and mounted states the bar guarantees; nil means either.
-- Los estados de combate y montura que la barra garantiza; nil es cualquiera.
local function Guaranteed(vis)
	local free = HasExceptions(vis)
	local combat = not free and (vis.combat == "in" or vis.combat == "out") and vis.combat or nil
	local mounted = vis.mounted ~= "any" and vis.mounted or nil
	return combat, mounted
end

-- Two guaranteed states that can never hold together / Dos estados garantizados que nunca se cumplen juntos
local function Differ(a, b)
	return a ~= nil and b ~= nil and a ~= b
end

-- Can these two bars be active at the same time? (D-59) / ¿Pueden estas dos barras estar activas al mismo tiempo? (D-59)
function Visibility:CanOverlap(da, db)
	if da.hidden or db.hidden then return false end
	local sa, sb = ns.DB:ActiveSet(da), ns.DB:ActiveSet(db)
	-- Keys that stay on while hidden are always active (D-52).
	-- Las teclas activas aunque esté oculta siempre están activas (D-52).
	if sa.layout.keysAlways or sb.layout.keysAlways then return true end
	local va, vb = sa.visibility, sb.visibility

	local samePlace = false
	for _, here in ipairs(PLACES) do
		local holds = function(key) return here[key] end
		if AnyHolds(va.location, holds) and AnyHolds(vb.location, holds) then
			samePlace = true
			break
		end
	end
	if not samePlace then return false end

	local combatA, mountedA = Guaranteed(va)
	local combatB, mountedB = Guaranteed(vb)
	return not (Differ(combatA, combatB) or Differ(mountedA, mountedB))
end

---------------------------------------------------------------------------
-- Applying / Aplicar
---------------------------------------------------------------------------
-- Out of combat only. Free mode and Edit Mode always show the bar.
-- Solo fuera de combate. El modo libre y el Modo Edición siempre muestran la barra.
function Visibility:Apply(f)
	if not f.data then return end
	local vis = ns.DB:Visibility(f.data)
	local allowed = self:Allowed(f.data, vis)
	-- Free mode shows every bar of this spec, but never another spec's (D-54).
	-- El modo libre muestra todas las barras de esta spec, pero nunca las de otra (D-54).
	-- Assigning keys shows them too (0.5.6) / Asignar teclas también las muestra (0.5.6)
	local force = (ns.Modes:IsFree() or ns.Keybinds:IsActive()) and ns.DB:InSpec(f.data)
	local driver = self:Driver(vis)

	if not f.visibilityReady then
		f:SetAttribute("_onstate-obvis", SNIPPET)
		f.visibilityReady = true
	end
	f:SetAttribute("ob-allowed", allowed)
	f:SetAttribute("ob-force", force)
	RegisterStateDriver(f, "obvis", driver)
	local shown = force or (allowed and SecureCmdOptionParse(driver) == "show")
	f:SetShown(shown)
	ApplyKeys(f, shown)
	-- Mouseover lives in the shape now (D-65) / El mouse ahora vive en la forma (D-65)
	f.mouseover = f.layout and f.layout.mouseover and not force
	self:Fade(f)
end

-- Apply on every bar / Aplica en cada barra
function Visibility:ApplyAll()
	for _, f in pairs(ns.Bars.frames) do
		if f.data then self:Apply(f) end
	end
end

-- Stops a bar's driver and keys when its frame is freed / Detiene el controlador y las teclas de una barra al liberar su marco
function Visibility:Release(f)
	UnregisterStateDriver(f, "obvis")
	ClearOverrideBindings(f)
	for i = 1, ns.MAX_BUTTONS do f:SetAttribute("ob-key" .. i, nil) end
	f.mouseover = nil
end

-- Blizzard's "cast on key press" option changed / Cambió la opción de Blizzard de "lanzar al presionar"
ns:On("CVAR_UPDATE", function(_, name)
	if name == "ActionButtonUseKeyDown" then
		ns.Combat:Run("visibility", function() Visibility:ApplyAll() end, true)
	end
end)

-- Mouseover (D-65): without the mouse (and nothing being dragged) the bar
-- stays at "Opacidad sin el mouse", never above its transparency; with the
-- mouse it goes back to its transparency. Cosmetic only: buttons and keys
-- keep working at any opacity.
-- Al pasar el mouse (D-65): sin el mouse (y sin arrastrar nada) la barra se
-- queda en "Opacidad sin el mouse", nunca arriba de su transparencia; con el
-- mouse regresa a su transparencia. Solo cosmético: botones y teclas siguen
-- funcionando con cualquier opacidad.
function Visibility:Fade(f)
	local layout = f.layout
	local alpha = layout and layout.alpha or 1
	if f.mouseover and not f:IsMouseOver() and not GetCursorInfo() then
		alpha = math.min(layout.fadeAlpha or 0, alpha)
	end
	f:SetAlpha(alpha)
end

local fadeTimer
-- Checks the mouse over faded bars 10 times a second / Revisa el mouse sobre las barras desvanecidas 10 veces por segundo
function Visibility:StartFadeTimer()
	if fadeTimer then return end
	fadeTimer = C_Timer.NewTicker(0.1, ns.Log.Wrap(function()
		for _, f in pairs(ns.Bars.frames) do
			if f.mouseover and f:IsShown() then Visibility:Fade(f) end
		end
	end))
end

-- Location, spec and equipment changes re-check the bars, after combat if needed.
-- Los cambios de ubicación, spec y equipo vuelven a revisar las barras, al salir de combate si hace falta.
local function Recheck()
	ns.Combat:Run("visibility", function() Visibility:ApplyAll() end, true)
end

for _, event in ipairs({
	"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_UPDATE_RESTING",
	"EQUIPMENT_SETS_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
}) do
	ns:On(event, Recheck)
end
