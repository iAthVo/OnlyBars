--[[
	OnlyBars · Core/DB.lua
	Saved variables: each character's bars and their Global / Per-spec sets
	(D-04, D-16, D-20, D-25).
	Variables guardadas: las barras de cada personaje y sus conjuntos Global /
	Por spec (D-04, D-16, D-20, D-25).
	© 2026 iAthVo_Kr
]]

local _, ns = ...

local DB = {}
ns.DB = DB

local SCHEMA_VERSION = 14

--[[ Layout / Estructura (schema 3)
	OnlyBarsDB = {
		schemaVersion = 3,
		settings = { locked = true },
		chars    = { ["Name-Realm"] = { bars = { [barID] = bar } } },   -- per character (D-25)
		log      = { ... },  -- Core/Log.lua
	}
	bar = { id, scope = "global" | "spec", hidden, lastKey, off = { [specID] = true }, sets = { ... } }
	-- off: specs unchecked in Especialización; their set stays saved (D-60).
	-- off: specs desmarcadas en Especialización; su conjunto queda guardado (D-60).
	-- The scope covers the whole bar (D-20, D-30): name, position, shape,
	-- visibility, content, keys. Only the number is shared.
	-- El alcance abarca toda la barra (D-20, D-30): nombre, posición, forma,
	-- visibilidad, contenido, teclas. Solo el número es común.
	bar.sets = { global = set } | { [specID] = set, ... }
	set = {
		name       = nil | "Demo PvE",   -- nil shows "Barra 9" / nil muestra "Barra 9"
		layout     = { rows, buttons, iconSize, spacing, alpha, showEmpty, showKeys, keysAlways, x, y, anchor },
		visibility = see VISIBILITY_DEFAULTS (D-26),
		slots      = { [i] = slot },
		keys       = { [i] = "SHIFT-1" },   -- per set: per spec on Per-spec bars (D-48)
	}
	slot = { kind = "spell" | "item" | "toy" | "macro" | "mount" | "pet" | "equipset", ... }
]]

-- The same settings and defaults as Blizzard's action bars in Edit Mode (D-39).
-- Los mismos ajustes y valores iniciales que las barras de Blizzard en el Modo Edición (D-39).
local LAYOUT_DEFAULTS = {
	rows = 1,           -- "Número de filas"
	buttons = 12,       -- "Número de iconos"
	iconSize = 1,       -- "Tamaño de los iconos": 1 = 100% = Blizzard's 45 px button
	spacing = 2,        -- "Margen de iconos": 2-10, like Blizzard
	showKeys = true,    -- "Mostrar teclas" (D-53)
	keysAlways = false, -- "Teclas activas aunque esté oculta" (D-52)
	alpha = 1,
	mouseover = false,  -- "Aparecer al pasar el mouse" (D-65)
	fadeAlpha = 0,      -- "Opacidad sin el mouse": 0 = invisible, as before / 0 = invisible, como antes
	showEmpty = true,
	x = 0,
	y = 0,              -- screen centre: new bars and "Restablecer posición" (0.9.1) / centro de la pantalla
}
DB.LAYOUT_DEFAULTS = LAYOUT_DEFAULTS

-- Situations, like Blizzard's transmog situations (D-26). Within a category
-- any marked option is enough; across categories all must hold. An empty
-- category does not limit the bar.
-- Situaciones, como las de la transfiguración de Blizzard (D-26). Dentro de
-- una categoría basta cualquiera de las marcadas; entre categorías deben
-- cumplirse todas. Una categoría vacía no limita la barra.
local VISIBILITY_DEFAULTS = {
	location = {},       -- { world, rest, dungeon, raid, delve, battleground, arena = true }
	-- The specs are the bar's own, not a situation (D-60) / Las specs son de la barra, no una situación (D-60)
	equipset = {},       -- { [setName] = true }
	combat = "any",      -- "any" | "always" | "in" | "out"
	-- Filters, always applied (D-66) / Filtros, siempre se aplican (D-66)
	mounted = "any",     -- "any" | "yes" | "no"
	target = "any",      -- "any" | "exists" | "harm" | "help"
	group = false,
	hideVehicle = true,
	-- "Mostrar solo si…" (D-55, D-61): without combat or group, the bar shows
	-- only when one of these holds.
	-- "Mostrar solo si…" (D-55, D-61): sin combate ni grupo, la barra se ve
	-- solo cuando se cumple alguna de estas.
	showIf = {},         -- { nopet, petdead, stealth, flying, swimming, focus = true }
}

local function FillTable(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = type(value) == "table" and {} or value
		end
	end
	return target
end

local function NewSet(layout)
	return {
		layout = FillTable(layout or {}, LAYOUT_DEFAULTS),
		visibility = FillTable({}, VISIBILITY_DEFAULTS),
		slots = {},
		keys = {},
	}
end

local function FillBar(bar)
	bar.scope = bar.scope or "global"
	bar.hidden = bar.hidden or false
	bar.off = bar.off or {}
	bar.sets = bar.sets or {}
	for _, set in pairs(bar.sets) do
		set.layout = FillTable(set.layout or {}, LAYOUT_DEFAULTS)
		set.visibility = FillTable(set.visibility or {}, VISIBILITY_DEFAULTS)
		set.slots = set.slots or {}
		set.keys = set.keys or {}
	end
end

-- A new bar starts at the screen centre (0.9.1): stacking them lower each time
-- put the 13th behind Blizzard's action bar 1.
-- Una barra nueva empieza en el centro de la pantalla (0.9.1): acomodarlas cada
-- vez más abajo dejaba la 13.ª detrás de la barra de acción 1 de Blizzard.
local function NewBar(id)
	local bar = { id = id, scope = "global", hidden = false, off = {}, sets = {} }
	bar.sets.global = NewSet()
	return bar
end

---------------------------------------------------------------------------
-- Migrations / Migraciones
---------------------------------------------------------------------------
local LAYOUT_KEYS = { "buttons", "perRow", "size", "spacing", "scale", "alpha", "showEmpty", "x", "y" }

-- 1 → 2: the shape and position lived on the bar; now each set has its own copy (D-20).
-- 1 → 2: la forma y la posición vivían en la barra; ahora cada conjunto tiene su copia (D-20).
local function MigrateTo2(db)
	for _, profile in pairs(db.profiles or {}) do
		for _, bar in pairs(profile.bars or {}) do
			local layout = {}
			for _, key in ipairs(LAYOUT_KEYS) do
				layout[key] = bar[key]
				bar[key] = nil
			end
			bar.sets = bar.sets or {}
			if next(bar.sets) == nil then bar.sets.global = { slots = {}, keys = {} } end
			for _, set in pairs(bar.sets) do
				set.layout = FillTable(CopyTable(layout), LAYOUT_DEFAULTS)
			end
		end
	end
end

-- 2 → 3: shared profiles become per-character bars. Every character keeps a
-- copy of what it was seeing (D-25).
-- 2 → 3: los perfiles compartidos pasan a barras por personaje. Cada personaje
-- se queda con una copia de lo que veía (D-25).
local function MigrateTo3(db)
	for _, char in pairs(db.chars) do
		local profile = db.profiles and db.profiles[char.profile or "Predeterminado"]
		char.bars = profile and CopyTable(profile.bars or {}) or {}
		char.profile = nil
	end
	db.profiles = nil
end

-- 3 → 4: the name moves from the bar into its sets (D-30). It stays in the
-- General set and in the spec sets that hold something; empty spec sets go
-- back to "Barra N".
-- 3 → 4: el nombre pasa de la barra a sus conjuntos (D-30). Se queda en el
-- conjunto General y en los de spec que tienen algo; los de spec vacíos
-- regresan a "Barra N".
local function MigrateTo4(db)
	for _, char in pairs(db.chars) do
		for _, bar in pairs(char.bars or {}) do
			if bar.name then
				for key, set in pairs(bar.sets or {}) do
					if key == "global" or next(set.slots or {}) ~= nil then
						set.name = bar.name
					end
				end
				bar.name = nil
			end
		end
	end
end

-- 4 → 5 (D-36): a scale other than 100% keeps "use scale" on, so no bar
-- changes size; the gap becomes Blizzard's icon padding range (2-10).
-- 4 → 5 (D-36): una escala distinta de 100% deja "usar escala" activado, así
-- ninguna barra cambia de tamaño; la separación pasa al rango del relleno de
-- iconos de Blizzard (2-10).
local function MigrateTo5(db)
	for _, char in pairs(db.chars) do
		for _, bar in pairs(char.bars or {}) do
			for _, set in pairs(bar.sets or {}) do
				local layout = set.layout
				if layout then
					if layout.useScale == nil then
						layout.useScale = (layout.scale or 1) ~= 1
					end
					if layout.spacing then
						layout.spacing = math.max(2, math.min(10, layout.spacing))
					end
				end
			end
		end
	end
end

-- 5 → 6 (D-37): every bar follows Blizzard's size and padding, as the user
-- asked; turning "Igual que Blizzard" off brings back its own values.
-- 5 → 6 (D-37): todas las barras siguen el tamaño y el relleno de Blizzard,
-- como pidió el usuario; al apagar "Igual que Blizzard" vuelven sus valores.
local function MigrateTo6(db)
	for _, char in pairs(db.chars) do
		for _, bar in pairs(char.bars or {}) do
			for _, set in pairs(bar.sets or {}) do
				if set.layout then set.layout.native = true end
			end
		end
	end
end

-- 6 → 7 (D-39): Blizzard's settings. Buttons per row become rows; the size
-- becomes 100% (Blizzard's button, as agreed); "use scale" off means 100%;
-- the "Igual que Blizzard" and "Usar escala" check boxes are gone.
-- 6 → 7 (D-39): los ajustes de Blizzard. Botones por fila pasa a filas; el
-- tamaño pasa a 100% (el botón de Blizzard, como se acordó); "usar escala"
-- apagado es 100%; se quitan las casillas "Igual que Blizzard" y "Usar escala".
local function MigrateTo7(db)
	for _, char in pairs(db.chars) do
		for _, bar in pairs(char.bars or {}) do
			for _, set in pairs(bar.sets or {}) do
				local layout = set.layout
				if layout then
					local buttons = layout.buttons or 12
					layout.rows = math.max(1, math.ceil(buttons / math.max(1, layout.perRow or buttons)))
					layout.iconSize = 1
					if layout.useScale == false then layout.scale = 1 end
					layout.perRow, layout.size, layout.native, layout.useScale = nil, nil, nil, nil
				end
			end
		end
	end
end

-- 10 → 11 (D-60): the spec condition leaves the situations; the bar's specs
-- say where it shows. A General bar limited to some specs becomes a Per-spec
-- bar of those specs, each with a copy of its content, so it keeps showing
-- where it did. A Per-spec set whose condition left out its own spec is unchecked.
-- 10 → 11 (D-60): la condición de spec sale de las situaciones; las specs de
-- la barra dicen dónde se ve. Una barra General limitada a algunas specs pasa a
-- barra por spec de esas specs, cada una con una copia de su contenido, así se
-- sigue viendo donde se veía. Un conjunto por spec cuya condición dejaba fuera
-- su propia spec queda desmarcado.
local function MigrateTo11(db)
	for _, char in pairs(db.chars) do
		for _, bar in pairs(char.bars or {}) do
			bar.off = bar.off or {}
			bar.sets = bar.sets or {}
			local general = bar.sets.global
			local limited = general and general.visibility and general.visibility.spec
			if bar.scope ~= "spec" and limited and next(limited) then
				general.visibility.spec = nil
				for key in pairs(bar.sets) do
					if type(key) == "number" and not limited[key] then bar.off[key] = true end
				end
				for specID in pairs(limited) do
					bar.sets[specID] = CopyTable(general)
					bar.off[specID] = nil
					bar.lastKey = specID
				end
				bar.scope = "spec"
			elseif bar.scope == "spec" then
				local on = 0
				for key, set in pairs(bar.sets) do
					local specs = type(key) == "number" and set.visibility and set.visibility.spec
					if specs and next(specs) and not specs[key] then
						bar.off[key] = true
					elseif type(key) == "number" then
						on = on + 1
					end
				end
				-- One spec always stays checked / Siempre queda una spec marcada
				if on == 0 then
					local first = next(bar.off)
					if first then bar.off[first] = nil end
				end
			end
			for _, set in pairs(bar.sets) do
				if set.visibility then set.visibility.spec = nil end
			end
		end
	end
end

-- 13 → 14 (D-66): one control for mount and one for target.
-- • "Ocultar si estoy montado" becomes Montura: solo sin montar.
-- • "Solo con objetivo" becomes Objetivo: con objetivo; the "Objetivo
--   enemigo / aliado" checks become Objetivo: enemigo / aliado (both: con objetivo).
-- 13 → 14 (D-66): un control para montura y uno para objetivo.
-- • "Ocultar si estoy montado" pasa a Montura: solo sin montar.
-- • "Solo con objetivo" pasa a Objetivo: con objetivo; las casillas "Objetivo
--   enemigo / aliado" pasan a Objetivo: enemigo / aliado (las dos: con objetivo).
local function MigrateTo14(db)
	for _, char in pairs(db.chars) do
		for _, bar in pairs(char.bars or {}) do
			for _, set in pairs(bar.sets or {}) do
				local vis = set.visibility
				if vis then
					if vis.hideMounted then vis.mounted = "no" end
					vis.hideMounted = nil
					local showIf = vis.showIf or {}
					local target = vis.target == true and "exists" or "any"
					if showIf.harm and showIf.help then
						target = "exists"
					elseif showIf.harm then
						target = "harm"
					elseif showIf.help then
						target = "help"
					end
					vis.target = target
					showIf.harm, showIf.help = nil, nil
				end
			end
		end
	end
end

local function Migrate(db)
	if db.schemaVersion < 2 then MigrateTo2(db) end
	if db.schemaVersion < 3 then MigrateTo3(db) end
	if db.schemaVersion < 4 then MigrateTo4(db) end
	if db.schemaVersion < 5 then MigrateTo5(db) end
	if db.schemaVersion < 6 then MigrateTo6(db) end
	if db.schemaVersion < 7 then MigrateTo7(db) end
	if db.schemaVersion < 8 then
		-- 7 → 8 (D-40): "Usar escala" is back; a scale other than 100% keeps it on.
		-- 7 → 8 (D-40): regresa "Usar escala"; una escala distinta de 100% la deja encendida.
		for _, char in pairs(db.chars) do
			for _, bar in pairs(char.bars or {}) do
				for _, set in pairs(bar.sets or {}) do
					if set.layout then set.layout.useScale = (set.layout.scale or 1) ~= 1 end
				end
			end
		end
	end
	if db.schemaVersion < 9 then
		-- 8 → 9 (D-41): the scale is fixed in code; each bar's scale is removed.
		-- 8 → 9 (D-41): la escala es fija en el código; se quita la de cada barra.
		for _, char in pairs(db.chars) do
			for _, bar in pairs(char.bars or {}) do
				for _, set in pairs(bar.sets or {}) do
					if set.layout then set.layout.scale, set.layout.useScale = nil, nil end
				end
			end
		end
	end
	if db.schemaVersion < 10 then
		-- 9 → 10 (D-54): the blank sets that Per-spec bars got just by visiting a
		-- spec are removed, so those bars stop showing there. One set is always kept.
		-- 9 → 10 (D-54): se quitan los conjuntos vacíos que las barras por spec
		-- recibieron solo por visitar una spec, así dejan de verse ahí. Siempre
		-- queda al menos uno.
		for _, char in pairs(db.chars) do
			for _, bar in pairs(char.bars or {}) do
				if bar.scope == "spec" and bar.sets then
					for key, set in pairs(bar.sets) do
						local blank = next(set.slots or {}) == nil and next(set.keys or {}) == nil and not set.name
						local others = 0
						for other in pairs(bar.sets) do
							if other ~= key then others = others + 1 end
						end
						if blank and others > 0 then bar.sets[key] = nil end
					end
				end
			end
		end
	end
	if db.schemaVersion < 11 then MigrateTo11(db) end
	if db.schemaVersion < 12 then
		-- 11 → 12 (D-62): the custom condition is gone, so it is cleared and
		-- no bar keeps a rule that can no longer be seen.
		-- 11 → 12 (D-62): la condición personalizada ya no existe; se borra para
		-- que ninguna barra conserve una regla que ya no se puede ver.
		for _, char in pairs(db.chars) do
			for _, bar in pairs(char.bars or {}) do
				for _, set in pairs(bar.sets or {}) do
					if set.visibility then set.visibility.custom = nil end
				end
			end
		end
	end
	if db.schemaVersion < 13 then
		-- 12 → 13 (D-65): "Aparecer al pasar el mouse" moves from the
		-- situations to the shape, next to its new opacity.
		-- 12 → 13 (D-65): "Aparecer al pasar el mouse" pasa de las situaciones
		-- a la forma, junto a su nueva opacidad.
		for _, char in pairs(db.chars) do
			for _, bar in pairs(char.bars or {}) do
				for _, set in pairs(bar.sets or {}) do
					if set.visibility then
						set.layout = set.layout or {}
						set.layout.mouseover = set.visibility.mouseover or false
						set.visibility.mouseover = nil
					end
				end
			end
		end
	end
	if db.schemaVersion < 14 then MigrateTo14(db) end
	db.schemaVersion = SCHEMA_VERSION
end

---------------------------------------------------------------------------
-- Start-up / Arranque
---------------------------------------------------------------------------
function DB:Init()
	OnlyBarsDB = OnlyBarsDB or {}
	local db = OnlyBarsDB
	-- A fresh install starts at the current schema / Una instalación nueva empieza en el esquema actual
	db.schemaVersion = db.schemaVersion or (db.profiles and 1 or SCHEMA_VERSION)
	db.settings = db.settings or { locked = true }
	db.chars = db.chars or {}
	Migrate(db)
	self.db = db
end

-- Needs the character name, so it runs on PLAYER_LOGIN. A new character
-- starts with one sample bar, never with another character's bars (D-25).
-- Necesita el nombre del personaje, por eso corre en PLAYER_LOGIN. Un personaje
-- nuevo empieza con una barra de ejemplo, nunca con las de otro (D-25).
function DB:InitCharacter()
	local key = UnitName("player") .. "-" .. GetRealmName()
	local char = self.db.chars[key]
	if not char then
		char = { bars = { [ns.FIRST_BAR] = NewBar(ns.FIRST_BAR) } }
		self.db.chars[key] = char
	end
	char.bars = char.bars or {}
	-- The class, so bars can be copied to this character from another one (D-67).
	-- La clase, para poder copiarle barras a este personaje desde otro (D-67).
	char.class = select(2, UnitClass("player"))
	self.char = char
	for _, bar in pairs(char.bars) do
		FillBar(bar)
	end
end

-- This character's bars / Las barras de este personaje
function DB:Bars()
	return self.char.bars
end

---------------------------------------------------------------------------
-- Specs / Especializaciones
---------------------------------------------------------------------------
local GetSpecIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
local GetSpecInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo

function DB:SpecID()
	local index = GetSpecIndex and GetSpecIndex()
	return index and GetSpecInfo(index) or nil
end

-- { { id, name, icon }, ... } for this character's class / para la clase de este personaje
function DB:ClassSpecs()
	local specs = {}
	for i = 1, (GetNumSpecializations and GetNumSpecializations() or 0) do
		local id, name, _, icon = GetSpecInfo(i)
		if id then specs[#specs + 1] = { id = id, name = name, icon = icon } end
	end
	return specs
end

---------------------------------------------------------------------------
-- Sets / Conjuntos
---------------------------------------------------------------------------
-- A new set copies the layout and visibility of the last set the bar used,
-- with empty buttons and no keys (D-16).
-- Un conjunto nuevo copia la forma y la visibilidad del último conjunto que
-- usó la barra, con los botones vacíos y sin teclas (D-16).
local function NewSetFrom(bar)
	local previous = bar.lastKey and bar.sets[bar.lastKey] or select(2, next(bar.sets))
	local set = NewSet(previous and CopyTable(previous.layout))
	if previous then
		set.layout.anchor = nil
		set.visibility = CopyTable(previous.visibility)
	end
	return set
end

-- Stand-in sets of Per-spec bars in specs they do not belong to: never saved (D-54).
-- Conjuntos de reemplazo de barras por spec en specs a las que no pertenecen: nunca se guardan (D-54).
local standIns = setmetatable({}, { __mode = "k" })

local function EnsureSet(bar, key)
	if not bar.sets[key] then
		bar.sets[key] = NewSetFrom(bar)
		standIns[bar] = nil
	end
	return bar.sets[key]
end

-- Does the bar belong to the current spec? General bars always do; a Per-spec
-- bar only in the specs it has a set for (D-54) that are checked (D-60).
-- ¿La barra pertenece a la spec actual? Las General siempre; una barra por
-- spec solo en las specs donde tiene conjunto (D-54) y que están marcadas (D-60).
function DB:InSpec(bar)
	if bar.scope ~= "spec" then return true end
	local specID = self:SpecID()
	return specID == nil or (bar.sets[specID] ~= nil and not bar.off[specID])
end

-- The set the bar uses right now. A Per-spec bar that is not part of this
-- spec gets a stand-in (it stays hidden) instead of a new saved set (D-54).
-- El conjunto que la barra usa ahora. Una barra por spec que no es de esta
-- spec recibe uno de reemplazo (queda oculta) en vez de un conjunto nuevo guardado (D-54).
function DB:ActiveSet(bar)
	if not self:InSpec(bar) then
		standIns[bar] = standIns[bar] or NewSetFrom(bar)
		return standIns[bar]
	end
	local key = bar.scope == "spec" and self:SpecID() or "global"
	local set = EnsureSet(bar, key)
	bar.lastKey = key
	return set
end

-- The checked specs of a Per-spec bar / Las specs marcadas de una barra por spec
function DB:BarSpecs(bar)
	-- Other characters' bars may lack fields until they log in (D-67).
	-- Las barras de otros personajes pueden no tener campos hasta que entren (D-67).
	local specs, off = {}, bar.off or {}
	for key in pairs(bar.sets or {}) do
		if type(key) == "number" and not off[key] then specs[#specs + 1] = key end
	end
	table.sort(specs)
	return specs
end

-- Checks or unchecks a spec of a Per-spec bar (D-60). Unchecking keeps its set
-- saved; the last spec cannot be unchecked. A spec checked for the first time
-- starts with a copy of the current spec's set. Returns false if refused.
-- Marca o desmarca una spec de una barra por spec (D-60). Desmarcar deja su
-- conjunto guardado; la última spec no se puede desmarcar. Una spec marcada por
-- primera vez empieza con una copia del conjunto de la spec actual. Regresa false si no se pudo.
function DB:SetSpec(bar, specID, on)
	if bar.scope ~= "spec" then return false end
	if not on then
		if #self:BarSpecs(bar) <= 1 then return false end
		bar.off[specID] = true
		return true
	end
	if not bar.sets[specID] then
		local source = self:InSpec(bar) and self:ActiveSet(bar) or bar.sets[self:BarSpecs(bar)[1]]
		bar.sets[specID] = source and CopyTable(source) or NewSetFrom(bar)
	end
	bar.off[specID] = nil
	standIns[bar] = nil
	return true
end

-- The set of a given key ("global" or a specID); the panel reads the set of
-- another spec to show a bar that is not in this one (D-60).
-- El conjunto de una clave ("global" o un specID); el panel lee el conjunto de
-- otra spec para mostrar una barra que no está en esta (D-60).
function DB:SetFor(bar, key)
	if key == nil or key == "global" or bar.scope ~= "spec" then
		return bar.scope == "spec" and self:ActiveSet(bar) or EnsureSet(bar, "global")
	end
	return EnsureSet(bar, key)
end

function DB:Layout(bar)
	return self:ActiveSet(bar).layout
end

function DB:Visibility(bar)
	return self:ActiveSet(bar).visibility
end

-- Changing the scope never deletes a set (D-27): every spec and the Global
-- version stay saved, so going back brings back what was there.
-- • Global → Per spec: the current spec gets back its own set, or a copy of
--   the Global one the first time. Specs never seen start blank (D-16).
-- • Per spec → Global: Global becomes a copy of the current spec's set.
-- Only the current spec stays checked when leaving General (D-60).
-- Cambiar el alcance nunca borra un conjunto (D-27): cada spec y la versión
-- Global quedan guardadas, así al regresar vuelve lo que había.
-- • Global → Por spec: la spec actual recupera su conjunto, o una copia del
--   Global la primera vez. Las specs que nunca se vieron empiezan en blanco (D-16).
-- • Por spec → Global: el Global pasa a ser una copia del de la spec actual.
-- Al dejar General solo queda marcada la spec actual (D-60).
function DB:SetScope(bar, scope)
	if bar.scope == scope then return end
	local current = self:ActiveSet(bar)
	if scope == "spec" then
		local specID = self:SpecID()
		if specID and not bar.sets[specID] then
			bar.sets[specID] = CopyTable(current)
		end
		if specID then
			for key in pairs(bar.sets) do
				if type(key) == "number" then bar.off[key] = key ~= specID or nil end
			end
		end
		standIns[bar] = nil
		bar.lastKey = specID
	else
		bar.sets.global = CopyTable(current)
		bar.lastKey = "global"
	end
	bar.scope = scope
end

---------------------------------------------------------------------------
-- Bars / Barras
---------------------------------------------------------------------------
local function FreeID(bars)
	local count = 0
	for _ in pairs(bars) do count = count + 1 end
	if count >= ns.MAX_BARS then return nil, count end
	-- Lowest free number from 9 up / El número libre más bajo desde el 9 (D-02)
	local id = ns.FIRST_BAR
	while bars[id] do id = id + 1 end
	return id, count
end

function DB:CreateBar()
	local bars = self:Bars()
	local id = FreeID(bars)
	if not id then return nil end
	bars[id] = NewBar(id)
	return bars[id]
end

-- A copy with its own number, a little lower on screen / Una copia con su propio número, un poco más abajo
function DB:DuplicateBar(source)
	local bars = self:Bars()
	local id = FreeID(bars)
	if not id then return nil end
	local copy = CopyTable(source)
	copy.id = id
	copy.order = nil   -- goes to the end of the list / va al final de la lista (D-56)
	-- A Per-spec bar of another spec is copied into the current spec, so the copy
	-- shows here; each spec is edited in its own spec (D-60).
	-- Una barra por spec de otra spec se copia a la spec actual, así la copia se
	-- ve aquí; cada spec se edita en su propia spec (D-60).
	local specID = self:SpecID()
	if source.scope == "spec" and specID and not self:InSpec(source) then
		local from = source.lastKey and source.sets[source.lastKey] and not source.off[source.lastKey]
			and source.lastKey or self:BarSpecs(source)[1]
		copy.sets = { [specID] = CopyTable(source.sets[from]) }
		copy.off = {}
		copy.lastKey = specID
	end
	for _, set in pairs(copy.sets) do
		set.layout.anchor = nil   -- the copy starts free / la copia empieza libre (D-47)
		set.keys = {}             -- and without keys, so they do not clash / y sin teclas, para que no choquen (D-50)
		set.layout.y = set.layout.y - 48
		if set.name then set.name = set.name .. " " .. ns.L.COPY_SUFFIX end
	end
	bars[id] = copy
	return copy
end

---------------------------------------------------------------------------
-- Copy from another character (D-67) / Copiar de otro personaje (D-67)
---------------------------------------------------------------------------
-- This account's other characters: { { key, name, realm, bars }, ... }. Also
-- those without bars, so bars can be copied to them (bidirectional, 0.10.1).
-- Los otros personajes de esta cuenta: { { key, name, realm, bars }, ... }.
-- También los que no tienen barras, para poder copiarles (en los dos sentidos, 0.10.1).
function DB:OtherChars()
	local list, mine = {}, UnitName("player") .. "-" .. GetRealmName()
	for key, char in pairs(self.db.chars) do
		if key ~= mine and char.bars then
			local name, realm = key:match("^(.-)%-(.*)$")
			list[#list + 1] = { key = key, name = name or key, realm = realm or "", bars = char.bars }
		end
	end
	table.sort(list, function(a, b) return a.key < b.key end)
	return list
end

-- Does that character have this character's class? Known once it has logged
-- in with OnlyBars 0.10.1; before that, guessed from its bars' specs.
-- ¿Ese personaje es de la clase de este? Se sabe cuando entró con OnlyBars
-- 0.10.1; antes, se deduce de las specs de sus barras.
function DB:SameClass(key)
	local char = self.db.chars[key]
	if not char then return false end
	if char.class then return char.class == select(2, UnitClass("player")) end
	local mine = {}
	for _, spec in ipairs(self:ClassSpecs()) do mine[spec.id] = true end
	for _, bar in pairs(char.bars or {}) do
		for setKey in pairs(bar.sets or {}) do
			if mine[setKey] then return true end
		end
	end
	return false
end

-- A copy of a bar added to a character's bars: this one by default, or
-- another one (bidirectional, 0.10.1). It starts at the screen centre,
-- unanchored and without keys (D-50). Specs of the target's class are kept as
-- they are; a bar with none of them (another class) becomes General with the
-- content of its first spec. Returns the copy and whether it was converted, or
-- nil at the bar limit.
-- Una copia de una barra agregada a las barras de un personaje: este por
-- defecto, u otro (en los dos sentidos, 0.10.1). Empieza en el centro de la
-- pantalla, sin anclar y sin teclas (D-50). Las specs de la clase del destino se
-- conservan igual; una barra sin ninguna (otra clase) pasa a General con el
-- contenido de su primera spec. Regresa la copia y si se convirtió, o nil en el
-- límite de barras.
function DB:CopyBarFrom(source, targetKey)
	local toOther = targetKey ~= nil
	local bars = toOther and self.db.chars[targetKey].bars or self:Bars()
	local id = FreeID(bars)
	if not id then return nil end
	local copy = CopyTable(source)
	copy.id, copy.order, copy.hidden, copy.lastKey = id, nil, false, nil
	copy.off = copy.off or {}

	local converted = false
	if copy.scope == "spec" then
		-- The target's specs: this class's, or none for another class.
		-- Las specs del destino: las de esta clase, o ninguna si es otra clase.
		local mine = {}
		if not toOther or self:SameClass(targetKey) then
			for _, spec in ipairs(self:ClassSpecs()) do mine[spec.id] = true end
		end
		local foreign = {}
		for key in pairs(copy.sets) do
			if type(key) == "number" and not mine[key] then foreign[#foreign + 1] = key end
		end
		table.sort(foreign)
		local first = foreign[1] and copy.sets[foreign[1]]
		for _, key in ipairs(foreign) do
			copy.sets[key], copy.off[key] = nil, nil
		end
		local kept = {}
		for key in pairs(copy.sets) do
			if type(key) == "number" then kept[#kept + 1] = key end
		end
		table.sort(kept)
		if #kept == 0 then
			local general = first or copy.sets.global or select(2, next(copy.sets)) or NewSet()
			copy.sets, copy.off, copy.scope = { global = general }, {}, "global"
			converted = true
		elseif #self:BarSpecs(copy) == 0 then
			-- Same class, every spec unchecked: check the first one / Misma clase, todas desmarcadas: marcar la primera
			copy.off[kept[1]] = nil
		end
	end

	for _, set in pairs(copy.sets) do
		set.layout = set.layout or {}
		set.layout.anchor = nil
		set.layout.x, set.layout.y = LAYOUT_DEFAULTS.x, LAYOUT_DEFAULTS.y
		set.keys = {}
	end
	FillBar(copy)
	bars[id] = copy
	return copy, converted
end

function DB:DeleteBar(id)
	self:Bars()[id] = nil
end
