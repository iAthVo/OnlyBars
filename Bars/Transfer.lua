--[[
	OnlyBars · Bars/Transfer.lua
	Import and export bars (D-76), like Blizzard's talent loadouts: one bar or a
	group becomes a text to copy, and is also saved in a list for the whole
	account. Importing brings the shape, position and situations always; the
	content and the keys only if asked. Each bar is added as new or replaces one.
	Importar y exportar barras (D-76), como los talentos de Blizzard: una barra o
	un grupo se vuelve un texto para copiar, y también se guarda en una lista para
	toda la cuenta. Al importar siempre llegan la forma, la posición y las
	situaciones; el contenido y las teclas solo si se pide. Cada barra se agrega
	como nueva o reemplaza a una.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local Transfer = {}
ns.Transfer = Transfer

local MAX_NAME = 96   -- bytes: 32 letters with accents / bytes: 32 letras con acentos
local MAX_OFFSET = 5000

-- What each kind of button content keeps, and its type.
-- Lo que guarda cada tipo de contenido de botón, y su tipo.
local KINDS = {
	spell = { id = "number" },
	item = { id = "number" },
	toy = { id = "number" },
	macro = { name = "string" },
	mount = { id = "number", spell = "number" },
	pet = { guid = "string" },
	equipset = { name = "string" },
}

local SIDES = { above = true, below = true, left = true, right = true }

-- Allowed values of the text settings / Valores permitidos de los ajustes de texto
local CHOICES = {
	orientation = { horizontal = true, vertical = true },
	combat = { any = true, always = true, ["in"] = true, out = true },
	mounted = { any = true, yes = true, no = true },
	target = { any = true, exists = true, harm = true, help = true },
}

---------------------------------------------------------------------------
-- Export / Exportar
---------------------------------------------------------------------------
-- A set without the values that are already the default: a shorter text.
-- Un conjunto sin los valores que ya son los de por defecto: un texto más corto.
local function TrimSet(set)
	local layoutDefaults, visDefaults = ns.DB.LAYOUT_DEFAULTS, ns.DB.VISIBILITY_DEFAULTS
	local out = { name = set.name, layout = {}, visibility = {}, slots = {}, keys = {} }
	for key, value in pairs(set.layout or {}) do
		if key == "anchor" then
			out.layout.anchor = CopyTable(value)
		elseif layoutDefaults[key] ~= nil and value ~= layoutDefaults[key] then
			out.layout[key] = value
		end
	end
	for key, value in pairs(set.visibility or {}) do
		local default = visDefaults[key]
		if type(default) == "table" then
			if type(value) == "table" and next(value) then out.visibility[key] = CopyTable(value) end
		elseif default ~= nil and value ~= default then
			out.visibility[key] = value
		end
	end
	local count = U.Clamp((set.layout and set.layout.buttons) or ns.MAX_BUTTONS, 1, ns.MAX_BUTTONS)
	for i = 1, count do
		if set.slots and set.slots[i] then out.slots[i] = CopyTable(set.slots[i]) end
		if set.keys and set.keys[i] then out.keys[i] = set.keys[i] end
	end
	return out
end

-- The bars as a table ready to write. Per-spec bars take their checked specs.
-- Las barras como una tabla lista para escribir. Las barras por spec llevan sus specs marcadas.
function Transfer:Pack(list)
	local package = { v = 1, class = select(2, UnitClass("player")), bars = {} }
	for _, data in ipairs(list) do
		local bar = { id = data.id, scope = data.scope == "spec" and "spec" or "global", sets = {} }
		if bar.scope == "spec" then
			for _, specID in ipairs(ns.DB:BarSpecs(data)) do bar.sets[specID] = TrimSet(data.sets[specID]) end
		else
			bar.sets.global = TrimSet(ns.DB:SetFor(data, "global"))
		end
		package.bars[#package.bars + 1] = bar
	end
	return package
end

-- The bars as text: "!OB1!…" / Las barras como texto: "!OB1!…"
function Transfer:Export(list)
	return ns.Serialize.ToText(self:Pack(list))
end

---------------------------------------------------------------------------
-- Reading a text / Leer un texto
-- A pasted text can come from anyone: only known fields with the right type
-- pass, numbers are clamped to their ranges.
-- Un texto pegado puede venir de cualquiera: solo pasan los campos conocidos
-- con el tipo correcto, y los números se ajustan a sus rangos.
---------------------------------------------------------------------------
local function CleanAnchor(raw)
	if type(raw) ~= "table" or not SIDES[raw.side] or type(raw.to) ~= "string" then return nil end
	if not (raw.to:match("^ob:%d+$") or raw.to:match("^bz:[%w_]+$")) then return nil end
	if type(raw.dx) ~= "number" or type(raw.dy) ~= "number" then return nil end
	return {
		to = raw.to, side = raw.side,
		dx = U.Clamp(raw.dx, -MAX_OFFSET, MAX_OFFSET), dy = U.Clamp(raw.dy, -MAX_OFFSET, MAX_OFFSET),
	}
end

local function CleanSlot(raw)
	local fields = type(raw) == "table" and KINDS[raw.kind]
	if not fields then return nil end
	local slot = { kind = raw.kind }
	for field, kind in pairs(fields) do
		if type(raw[field]) ~= kind then return nil end
		slot[field] = raw[field]
	end
	return slot
end

local function CleanSet(raw)
	if type(raw) ~= "table" then return nil end
	local set = { layout = {}, visibility = {}, slots = {}, keys = {} }
	if type(raw.name) == "string" and raw.name ~= "" and #raw.name <= MAX_NAME then set.name = raw.name end

	local layout = type(raw.layout) == "table" and raw.layout or {}
	for key, default in pairs(ns.DB.LAYOUT_DEFAULTS) do
		local value = layout[key]
		if type(value) == type(default) and (not CHOICES[key] or CHOICES[key][value]) then
			if type(value) == "number" then
				value = (key == "x" or key == "y") and U.Clamp(value, -MAX_OFFSET, MAX_OFFSET)
					or ns.Settings.Normalize(key, value)
			end
			set.layout[key] = value
		end
	end
	set.layout.anchor = CleanAnchor(layout.anchor)

	local vis = type(raw.visibility) == "table" and raw.visibility or {}
	for key, default in pairs(ns.DB.VISIBILITY_DEFAULTS) do
		local value = vis[key]
		if type(default) == "table" then
			if type(value) == "table" then
				set.visibility[key] = {}
				for k, v in pairs(value) do
					if type(k) == "string" and v == true then set.visibility[key][k] = true end
				end
			end
		elseif type(value) == type(default) and (not CHOICES[key] or CHOICES[key][value]) then
			set.visibility[key] = value
		end
	end

	for i = 1, ns.MAX_BUTTONS do
		local slots, keys = type(raw.slots) == "table" and raw.slots, type(raw.keys) == "table" and raw.keys
		set.slots[i] = slots and CleanSlot(slots[i]) or nil
		local key = keys and keys[i]
		if type(key) == "string" and #key <= 40 and key:match("^[%w%-]+$") then set.keys[i] = key end
	end
	return set
end

-- The read table → clean bars, or nil and why ("damaged", "empty").
-- La tabla leída → barras limpias, o nil y por qué ("damaged", "empty").
function Transfer.Clean(package)
	if type(package) ~= "table" or type(package.bars) ~= "table" then return nil, "damaged" end
	local class = type(package.class) == "string" and package.class:match("^%u+$") or nil
	local clean, seen = { class = class, bars = {} }, {}
	for i = 1, math.min(#package.bars, ns.MAX_BARS) do
		local raw = package.bars[i]
		if type(raw) == "table" and type(raw.sets) == "table" then
			local id = type(raw.id) == "number" and math.floor(raw.id) or nil
			if not id or seen[id] then id = 1000 + i end   -- the number only joins anchors / el número solo une anclajes
			seen[id] = true
			local bar = { id = id, scope = raw.scope == "spec" and "spec" or "global", off = {}, sets = {} }
			if bar.scope == "spec" then
				for key, set in pairs(raw.sets) do
					if type(key) == "number" and key > 0 and key == math.floor(key) then bar.sets[key] = CleanSet(set) end
				end
			else
				bar.sets.global = CleanSet(raw.sets.global)
			end
			if next(bar.sets) then clean.bars[#clean.bars + 1] = bar end
		end
	end
	if #clean.bars == 0 then return nil, "empty" end
	return clean
end

-- Text → clean bars, or nil and the reason / Texto → barras limpias, o nil y el motivo
function Transfer:Read(text)
	local package, why = ns.Serialize.FromText(text)
	if not package then return nil, why end
	return Transfer.Clean(package)
end

-- A bar's name in a package: its first named set, or "Bar N".
-- El nombre de una barra de un paquete: su primer conjunto con nombre, o "Barra N".
function Transfer.BarName(bar, index)
	local keys = {}
	for key in pairs(bar.sets) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	for _, key in ipairs(keys) do
		if bar.sets[key].name then return bar.sets[key].name end
	end
	return L.BAR_NAME:format(bar.id < 1000 and bar.id or index)
end

---------------------------------------------------------------------------
-- Import / Importar
---------------------------------------------------------------------------
-- Is the content there on this character? Macros and battle pets belong to
-- an account or a character; the rest works anywhere.
-- ¿El contenido existe en este personaje? Las macros y las mascotas de
-- combate son de una cuenta o un personaje; lo demás funciona en cualquier lado.
function Transfer.Available(slot)
	if slot.kind == "macro" then
		return GetMacroIndexByName ~= nil and (GetMacroIndexByName(slot.name) or 0) > 0
	elseif slot.kind == "pet" then
		local ok, species = pcall(C_PetJournal.GetPetInfoByPetID, slot.guid)
		return ok and species ~= nil
	end
	return true
end

-- Keeps the specs of this class; a bar with none (another class) becomes
-- General with its first spec's set, like copying from another character (D-67).
-- Conserva las specs de esta clase; una barra sin ninguna (otra clase) pasa a
-- General con el conjunto de su primera spec, como al copiar de otro personaje (D-67).
local function FitClass(bar)
	if bar.scope ~= "spec" then return false end
	local mine = {}
	for _, spec in ipairs(ns.DB:ClassSpecs()) do mine[spec.id] = true end
	local foreign = {}
	for key in pairs(bar.sets) do
		if not mine[key] then foreign[#foreign + 1] = key end
	end
	table.sort(foreign)
	local first = foreign[1] and bar.sets[foreign[1]]
	for _, key in ipairs(foreign) do bar.sets[key] = nil end
	if next(bar.sets) then return false end
	bar.scope, bar.sets = "global", { global = first }
	return true
end

-- The sets of `other` that can be on together with `set` of `bar` (same spec).
-- Los conjuntos de `other` que pueden estar junto con `set` de `bar` (misma spec).
local function SetsTogether(key, other)
	local list = {}
	if other.scope ~= "spec" then
		list[1] = other.sets.global
	elseif key == "global" then
		for _, spec in ipairs(ns.DB:BarSpecs(other)) do list[#list + 1] = other.sets[spec] end
	elseif other.sets[key] and not other.off[key] then
		list[1] = other.sets[key]
	end
	return list
end

-- Removes the keys that another bar (not imported) already uses and that can
-- be on at the same time (D-59). Returns how many were removed.
-- Quita las teclas que otra barra (no importada) ya usa y que pueden estar
-- activas al mismo tiempo (D-59). Regresa cuántas se quitaron.
local function DropClashingKeys(bar, imported)
	local dropped = 0
	for key, set in pairs(bar.sets) do
		for i, bind in pairs(set.keys) do
			local clash = false
			for id, other in pairs(ns.DB:Bars()) do
				if not imported[id] then
					for _, theirs in ipairs(SetsTogether(key, other)) do
						for j, otherBind in pairs(theirs.keys or {}) do
							if otherBind == bind and j <= (theirs.layout.buttons or ns.MAX_BUTTONS)
								and ns.Visibility:CanOverlap(bar, other, set, theirs) then
								clash = true
							end
						end
					end
				end
			end
			if clash then
				set.keys[i] = nil
				dropped = dropped + 1
			end
		end
	end
	return dropped
end

-- Puts the bars in this character's data (out of combat).
-- options = { content = bool, keys = bool, targets = { [index] = barID to replace } }
-- Returns { added, replaced, skipped, converted, slots, keys, last }.
-- Pone las barras en los datos de este personaje (fuera de combate).
-- options = { content = bool, keys = bool, targets = { [índice] = barra a reemplazar } }
-- Regresa { added, replaced, skipped, converted, slots, keys, last }.
function Transfer:Apply(package, options)
	local result = { added = 0, replaced = 0, skipped = 0, converted = 0, slots = 0, keys = 0 }
	local targets = options.targets or {}
	local bars = ns.DB:Bars()
	local map, imported, done = {}, {}, {}

	for index, source in ipairs(package.bars) do
		local bar = CopyTable(source)
		if FitClass(bar) then result.converted = result.converted + 1 end
		for _, set in pairs(bar.sets) do
			if not options.content then
				set.slots = {}
			else
				for i, slot in pairs(set.slots) do
					if not Transfer.Available(slot) then
						set.slots[i] = nil
						result.slots = result.slots + 1
					end
				end
			end
			if not options.keys then set.keys = {} end
		end

		local old = targets[index] and bars[targets[index]]
		local id = old and old.id or ns.DB:FreeID()
		if not id then
			result.skipped = result.skipped + 1
		else
			bar.order = old and old.order or nil
			bar.hidden = old and old.hidden or false
			bar.lastKey = nil
			map[source.id] = id
			imported[id] = true
			done[#done + 1] = ns.DB:PutBar(bar, id)
			result.last = result.last or bar
			if old then result.replaced = result.replaced + 1 else result.added = result.added + 1 end
		end
	end

	-- Anchors between the imported bars follow their new numbers; an anchor to
	-- a bar that did not come stays free, where it was.
	-- Los anclajes entre las barras importadas siguen sus números nuevos; un
	-- anclaje a una barra que no vino queda libre, donde estaba.
	for _, bar in ipairs(done) do
		for _, set in pairs(bar.sets) do
			local anchor = set.layout.anchor
			local from = anchor and tonumber(anchor.to:match("^ob:(%d+)$"))
			if from then
				local to = map[from]
				if to and to ~= bar.id then anchor.to = "ob:" .. to else set.layout.anchor = nil end
			end
		end
	end

	if options.keys then
		for _, bar in ipairs(done) do result.keys = result.keys + DropClashingKeys(bar, imported) end
	end
	return result
end

-- Import with frames and messages (combat queue). onDone(result).
-- Importar con marcos y mensajes (cola de combate). onDone(result).
function Transfer:Import(package, options, onDone)
	ns.Combat:Run("import", function()
		local result = self:Apply(package, options)
		ns.Bars:BuildAll()
		ns.Bars:Changed()
		if ns.KeyList then ns.KeyList:RefreshIfShown() end
		U.Print(L.IMPORT_DONE, result.added, result.replaced)
		if result.skipped > 0 then U.Print(L.IMPORT_SKIPPED, result.skipped, ns.MAX_BARS) end
		if result.converted > 0 then U.Print(L.IMPORT_CONVERTED, result.converted) end
		if result.slots > 0 then U.Print(L.IMPORT_SLOTS, result.slots) end
		if result.keys > 0 then U.Print(L.IMPORT_KEYS, result.keys) end
		if onDone then onDone(result) end
	end)
end

---------------------------------------------------------------------------
-- Saved list, for the whole account / Lista guardada, para toda la cuenta
-- entry = { name, date, class, count, text }
---------------------------------------------------------------------------
function Transfer:Library()
	return ns.DB.db.library
end

-- Saves an export at the top of the list / Guarda una exportación al principio de la lista
function Transfer:Save(name, text, count)
	local entry = {
		name = name, text = text, count = count,
		class = select(2, UnitClass("player")),
		date = (date or os.date)("%Y-%m-%d"),
	}
	table.insert(self:Library(), 1, entry)
	return entry
end

function Transfer:Rename(index, name)
	local entry = self:Library()[index]
	name = name and strtrim(name) or ""
	if entry and name ~= "" then entry.name = name end
end

function Transfer:Delete(index)
	table.remove(self:Library(), index)
end
