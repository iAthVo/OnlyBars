--[[
	OnlyBars · Bars/Buttons.lua
	The addon's own secure buttons (D-01): content, drag and drop, cooldowns,
	charges, range, usability and proc glow. Midnight-safe (D-12).
	Botones seguros propios del addon (D-01): contenido, arrastrar y soltar,
	cooldowns, cargas, alcance, si se puede usar y brillo de proc. Seguros en
	Midnight (D-12).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local Buttons = { pool = {} }
ns.Buttons = Buttons

local ACTION_ATTRIBUTES = { "spell", "item", "toy", "macro", "macrotext" }
local QUESTION_MARK = 134400

local WHITE = { 1, 1, 1 }
local BLUE = { 0.5, 0.5, 1 }     -- not enough power / falta de maná
local GREY = { 0.4, 0.4, 0.4 }   -- not usable / no se puede usar
local RED = { 1, 0.3, 0.3 }      -- out of range / fuera de alcance

---------------------------------------------------------------------------
-- Content kinds / Tipos de contenido
-- Each kind knows how to cast, show and return itself to the cursor.
-- Cada tipo sabe cómo lanzarse, mostrarse y volver al cursor.
---------------------------------------------------------------------------
local Kinds = {}

Kinds.spell = {
	attr = function(s) return "spell", "spell", s.id end,
	icon = function(s) return C_Spell.GetSpellTexture(s.id) end,
	pickup = function(s) C_Spell.PickupSpell(s.id) end,
	tooltip = function(s) GameTooltip:SetSpellByID(s.id) end,
	spellID = function(s) return s.id end,
}

Kinds.item = {
	attr = function(s) return "item", "item", "item:" .. s.id end,
	icon = function(s) return C_Item.GetItemIconByID(s.id) end,
	pickup = function(s) C_Item.PickupItem(s.id) end,
	tooltip = function(s) GameTooltip:SetItemByID(s.id) end,
	itemID = function(s) return s.id end,
}

Kinds.toy = {
	attr = function(s) return "toy", "toy", s.id end,
	icon = function(s)
		local _, _, icon = C_ToyBox.GetToyInfo(s.id)
		return icon or C_Item.GetItemIconByID(s.id)
	end,
	pickup = function(s) C_ToyBox.PickupToyBoxItem(s.id) end,
	tooltip = function(s) GameTooltip:SetToyByItemID(s.id) end,
	itemID = function(s) return s.id end,
}

-- What a macro would cast or use right now (D-46, 0.4.8). GetMacroSpell does
-- not follow modifiers such as [mod:shift], so the macro is read like Blizzard
-- does: its "#showtooltip <x>" argument or its first /cast or /use line,
-- evaluated now with SecureCmdOptionParse.
-- Lo que una macro lanzaría o usaría ahora (D-46, 0.4.8). GetMacroSpell no
-- sigue modificadores como [mod:shift], así que la macro se lee como lo hace
-- Blizzard: el argumento de "#showtooltip <x>" o su primera línea /cast o
-- /use, evaluada ahora con SecureCmdOptionParse.
local CAST_COMMANDS = {}
for _, command in ipairs({ "CAST", "USE" }) do
	for i = 1, 10 do
		local slash = _G["SLASH_" .. command .. i]
		if slash then CAST_COMMANDS[slash:lower()] = true end
	end
end
CAST_COMMANDS["/cast"], CAST_COMMANDS["/use"] = true, true

-- The options text the macro would act on / El texto de opciones sobre el que actuaría la macro
local function MacroOptions(body)
	if not body then return nil end
	local tooltip
	for line in body:gmatch("[^\r\n]+") do
		local command, rest = strtrim(line):match("^(%S+)%s*(.*)$")
		command = command and command:lower()
		if command == "#showtooltip" or command == "#show" then
			if rest ~= "" then tooltip = rest end
		elseif command and CAST_COMMANDS[command] then
			return tooltip or rest
		end
	end
	return tooltip
end

-- A spell or item from what the options resolved to (name, "Name(Subtext)", slot number).
-- Un hechizo u objeto a partir de lo que resolvieron las opciones (nombre, "Nombre(Subtexto)", número de ranura).
local function ResolveAction(action)
	action = strtrim((action:gsub("^!", "")))
	if action == "" then return nil end
	local slot = tonumber(action)
	if slot then
		local itemID = GetInventoryItemID("player", slot)
		return itemID and "item", itemID and ("item:" .. itemID)
	end
	local info = C_Spell.GetSpellInfo(action)
	local base = action:match("^(.-)%s*%(.-%)$")
	if not info and base then info = C_Spell.GetSpellInfo(base) end
	if info and info.spellID then return "spell", info.spellID end
	local itemID = C_Item.GetItemInfoInstant(base or action)
	if itemID then return "item", "item:" .. itemID end
	return nil
end

local function MacroTarget(name)
	local _, _, body = GetMacroInfo(name)
	local options = MacroOptions(body)
	if options then
		local ok, action = pcall(SecureCmdOptionParse, options)
		if ok and action and not U.IsSecret(action) then
			local kind, target = ResolveAction(action)
			if kind then return kind, target end
		end
	end
	-- Fallback: what the client reports / Respaldo: lo que reporta el cliente
	local spellID = GetMacroSpell(name)
	if spellID and not U.IsSecret(spellID) then return "spell", spellID end
	local _, link = GetMacroItem(name)
	if link and not U.IsSecret(link) then return "item", link end
	return nil
end
Buttons.MacroTarget = MacroTarget

-- A macro follows what it would use when its icon is the question mark, or
-- when its text starts with a bare "#showtooltip" / "#show" line (0.4.7: the
-- client may not report the question mark for those).
-- Una macro sigue lo que usaría cuando su ícono es el signo de interrogación, o
-- cuando su texto empieza con una línea "#showtooltip" / "#show" sin nada más
-- (0.4.7: el cliente puede no devolver el signo de interrogación en esas).
local function IsDynamicMacro(name)
	local _, icon, body = GetMacroInfo(name)
	if icon == nil or icon == QUESTION_MARK then return true, icon end
	local first = body and body:match("^%s*([^\n]*)") or ""
	first = strtrim(first):lower()
	return first == "#showtooltip" or first == "#show", icon
end
Buttons.IsDynamicMacro = IsDynamicMacro

Kinds.macro = {
	attr = function(s) return "macro", "macro", s.name end,
	-- Like Blizzard (D-46): a #showtooltip macro shows the icon of what it would
	-- use now; a macro with a chosen icon and no bare #showtooltip stays fixed.
	-- Como Blizzard (D-46): una macro con #showtooltip muestra el ícono de lo que
	-- usaría ahora; una con ícono elegido y sin #showtooltip solo se queda fija.
	icon = function(s)
		local dynamic, icon = IsDynamicMacro(s.name)
		if dynamic then
			local kind, target = MacroTarget(s.name)
			if kind == "spell" then return C_Spell.GetSpellTexture(target) or icon end
			if kind == "item" then return C_Item.GetItemIconByID(target) or icon end
		end
		return icon
	end,
	pickup = function(s) PickupMacro(s.name) end,
	-- Tooltip of what the macro would use now, like Blizzard's #showtooltip.
	-- Tooltip de lo que la macro usaría ahora, como el #showtooltip de Blizzard.
	tooltip = function(s)
		local kind, target = MacroTarget(s.name)
		if kind == "spell" then
			GameTooltip:SetSpellByID(target)
		elseif kind == "item" then
			GameTooltip:SetHyperlink(target)
		else
			GameTooltip:SetText(s.name)
		end
	end,
	target = MacroTarget,
	-- Cooldown, charges and range follow the live target too (D-46).
	-- El cooldown, las cargas y el alcance también siguen al objetivo en vivo (D-46).
	spellID = function(s)
		local kind, target = MacroTarget(s.name)
		return kind == "spell" and target or nil
	end,
	-- "/use <item>" macros: count and cooldown come from the item, like Blizzard.
	-- Macros "/use <objeto>": la cantidad y el cooldown salen del objeto, como en Blizzard.
	itemID = function(s)
		local kind, target = MacroTarget(s.name)
		return kind == "item" and C_Item.GetItemInfoInstant(target) or nil
	end,
	label = function(s) return s.name end,
}

Kinds.mount = {
	-- Summoned by name, like a "/cast <mount>" macro: casting the mount's spell
	-- by ID stopped working on buttons (0.5.5). Falls back to the spell if the
	-- name is not available yet.
	-- Se invoca por nombre, como una macro "/cast <montura>": lanzar el hechizo
	-- de la montura por su número dejó de funcionar en los botones (0.5.5). Si
	-- el nombre todavía no está disponible, usa el hechizo.
	attr = function(s)
		local name = C_MountJournal.GetMountInfoByID(s.id)
		if name and name ~= "" then return "macro", "macrotext", "/cast " .. name end
		return "spell", "spell", s.spell
	end,
	icon = function(s)
		local _, _, icon = C_MountJournal.GetMountInfoByID(s.id)
		return icon
	end,
	pickup = function(s)
		for i = 1, C_MountJournal.GetNumDisplayedMounts() do
			if C_MountJournal.GetDisplayedMountID(i) == s.id then
				C_MountJournal.Pickup(i)
				return
			end
		end
	end,
	tooltip = function(s) GameTooltip:SetMountBySpellID(s.spell) end,
	spellID = function(s) return s.spell end,
}

Kinds.pet = {
	attr = function(s) return "macro", "macrotext", "/summonpet " .. s.guid end,
	icon = function(s)
		local _, _, _, _, _, _, _, _, icon = C_PetJournal.GetPetInfoByPetID(s.guid)
		return icon
	end,
	pickup = function(s) C_PetJournal.PickupPet(s.guid) end,
	tooltip = function(s) GameTooltip:SetCompanionPet(s.guid) end,
}

-- Equipment manager sets, equipped through the game's /equipset command.
-- Conjuntos del gestor de equipo, se equipan con el comando /equipset del juego.
Kinds.equipset = {
	attr = function(s) return "macro", "macrotext", "/equipset " .. s.name end,
	icon = function(s)
		local setID = C_EquipmentSet.GetEquipmentSetID(s.name)
		if not setID then return nil end
		local _, icon = C_EquipmentSet.GetEquipmentSetInfo(setID)
		return icon
	end,
	pickup = function(s)
		local setID = C_EquipmentSet.GetEquipmentSetID(s.name)
		if setID then C_EquipmentSet.PickupEquipmentSet(setID) end
	end,
	-- Midnight takes the set's ID, not its name; a deleted set shows only its name (0.7.3).
	-- Midnight recibe el ID del conjunto, no su nombre; un conjunto borrado solo muestra su nombre (0.7.3).
	tooltip = function(s)
		local setID = C_EquipmentSet.GetEquipmentSetID(s.name)
		if setID then
			GameTooltip:SetEquipmentSet(setID)
		else
			GameTooltip:SetText(s.name)
		end
	end,
	label = function(s) return s.name end,
}

-- Turns what the cursor holds into a slot. Returns nil and the cursor type
-- when that type is not supported.
-- Convierte lo que hay en el cursor en un slot. Si el tipo no se admite,
-- devuelve nil y el tipo del cursor.
local function SlotFromCursor()
	local kind, a, b, c, d = GetCursorInfo()
	if kind == "spell" then
		-- a = book slot, b = book type, c = spellID, d = base spellID
		local spellID = d or c
		if spellID then return { kind = "spell", id = spellID } end
	elseif kind == "item" then
		if PlayerHasToy and PlayerHasToy(a) then
			return { kind = "toy", id = a }
		end
		return { kind = "item", id = a }
	elseif kind == "macro" then
		local name = GetMacroInfo(a)
		if name then return { kind = "macro", name = name } end
	elseif kind == "mount" then
		local mountID = a
		local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
		if not spellID then
			mountID = C_MountJournal.GetDisplayedMountID(a)
			_, spellID = C_MountJournal.GetMountInfoByID(mountID)
		end
		if spellID then return { kind = "mount", id = mountID, spell = spellID } end
	elseif kind == "battlepet" then
		return { kind = "pet", guid = a }
	elseif kind == "equipmentset" then
		-- a = set name / a = nombre del conjunto
		return { kind = "equipset", name = a }
	end
	-- Raw cursor data, for the log / Datos crudos del cursor, para el registro
	return nil, kind, ("%s, %s, %s, %s, %s"):format(tostring(kind), tostring(a), tostring(b), tostring(c), tostring(d))
end

---------------------------------------------------------------------------
-- Button methods / Métodos del botón
---------------------------------------------------------------------------
local Button = {}

-- Out of combat only: changes secure attributes.
-- Solo fuera de combate: cambia atributos seguros.
function Button:ApplySlot(slot)
	if slot and not Kinds[slot.kind] then slot = nil end
	for _, attribute in ipairs(ACTION_ATTRIBUTES) do
		self:SetAttribute(attribute, nil)
	end
	if slot then
		local actionType, attribute, value = Kinds[slot.kind].attr(slot)
		self:SetAttribute("type", actionType)
		self:SetAttribute(attribute, value)
	else
		self:SetAttribute("type", nil)
	end
	self.slot = slot
	self.kind = slot and Kinds[slot.kind]
	self.hasCharges = nil
	self.macroKey = nil
	self:Refresh()
end

function Button:Refresh()
	self:UpdateHotkey()
	self:UpdateIcon()
	self:UpdateQuality()
	self:UpdateCooldown()
	self:UpdateCount()
	self:UpdateState()
	self:UpdateGlow()
	self:UpdateEmpty()
end

-- Never returns a secret value, so callers may test it freely (D-12).
-- Nunca devuelve un valor secreto, así quien la llama puede probarlo sin riesgo (D-12).
function Button:SpellID()
	local spellID = self.kind and self.kind.spellID and self.kind.spellID(self.slot)
	if U.IsSecret(spellID) then return nil end
	return spellID
end

function Button:ItemID()
	local itemID = self.kind and self.kind.itemID and self.kind.itemID(self.slot)
	if U.IsSecret(itemID) then return nil end
	return itemID
end

function Button:UpdateIcon()
	if not self.kind then
		self.icon:Hide()
		self.label:SetText("")
		return
	end
	local ok, texture = pcall(self.kind.icon, self.slot)
	self.icon:SetTexture(ok and texture or QUESTION_MARK)
	self.icon:Show()
	self.label:SetText(self.kind.label and self.kind.label(self.slot) or "")
	-- A spell the current spec does not have stays, greyed out.
	-- Un hechizo que la spec actual no tiene se conserva, en gris.
	self.icon:SetDesaturated(self.slot.kind == "spell" and not U.IsSpellKnown(self.slot.id))
end

---------------------------------------------------------------------------
-- Crafting quality / Calidad de profesión
-- The API and atlas names have changed between expansions, so every known
-- form is tried and an atlas is used only if the client has it.
-- La API y los nombres de atlas han cambiado entre expansiones: se prueba cada
-- forma conocida y solo se usa un atlas si el cliente lo tiene.
---------------------------------------------------------------------------
local QUALITY_ATLASES = {
	"Professions-Icon-Quality-12-Tier%d-Inv",
	"Professions-Icon-Quality-Tier%d-Inv",
}

local function AtlasExists(atlas)
	return C_Texture.GetAtlasInfo(atlas) ~= nil
end

function Buttons.QualityAtlas(itemID)
	local trade = C_TradeSkillUI
	if not trade then return nil end
	-- Info tables that already carry the atlas / Tablas que ya traen el atlas
	for _, fn in ipairs({ trade.GetItemReagentQualityInfo, trade.GetItemCraftedQualityInfo }) do
		local ok, info = pcall(fn, itemID)
		if ok and type(info) == "table" and info.iconInventory and AtlasExists(info.iconInventory) then
			return info.iconInventory
		end
	end
	-- A tier number / Un número de rango
	for _, fn in ipairs({ trade.GetItemReagentQualityByItemInfo, trade.GetItemCraftedQualityByItemInfo }) do
		local ok, tier = pcall(fn, itemID)
		if ok and type(tier) == "number" then
			for _, pattern in ipairs(QUALITY_ATLASES) do
				local atlas = pattern:format(tier)
				if AtlasExists(atlas) then return atlas end
			end
		end
	end
	return nil
end

function Button:UpdateQuality()
	local itemID = self.slot and (self.slot.kind == "item" or self.slot.kind == "macro") and self:ItemID()
	local atlas = itemID and Buttons.QualityAtlas(itemID)
	if atlas then
		self.quality:SetAtlas(atlas)
		self.quality:Show()
	else
		self.quality:Hide()
	end
end

local function ApplyDuration(cooldown, duration, diagKey)
	if not duration then
		U.NoteEmpty(diagKey)
		cooldown:Clear()
		return
	end
	local ok, err = pcall(cooldown.SetCooldownFromDurationObject, cooldown, duration)
	U.Note(diagKey, nil, not ok and err or nil)
	if not ok then cooldown:Clear() end
end

function Button:UpdateCooldown()
	local spellID, itemID = self:SpellID(), self:ItemID()
	if spellID and C_Spell.GetSpellCooldownDuration then
		ApplyDuration(self.cooldown, C_Spell.GetSpellCooldownDuration(spellID), "cooldown")
		ApplyDuration(self.chargeCooldown, C_Spell.GetSpellChargeDuration(spellID), "charges")
	elseif itemID then
		-- Item cooldowns may be secret in combat: passed straight to the widget.
		-- El cooldown de objetos puede ser secreto en combate: va directo al widget.
		self.chargeCooldown:Clear()
		local ok, start, duration = pcall(C_Item.GetItemCooldown, itemID)
		-- No truth tests on "start": it may be secret / Sin probar "start": puede ser secreto
		local value, err
		if ok then
			value = start
			local shown, setErr = pcall(self.cooldown.SetCooldown, self.cooldown, start, duration)
			if not shown then err = setErr end
		else
			err = start
		end
		U.Note("itemcd", value, err)
		if err then self.cooldown:Clear() end
	else
		self.cooldown:Clear()
		self.chargeCooldown:Clear()
	end
end

function Button:UpdateCount()
	local text = ""
	local slot = self.slot
	-- Spells and macros (through the spell the macro casts) / Hechizos y macros (por el hechizo que lanza la macro)
	local spellID = slot and (slot.kind == "spell" or slot.kind == "macro") and self:SpellID()
	if spellID and self.chargesFor ~= spellID then
		self.chargesFor = spellID
		self.hasCharges = nil
	end
	if spellID then
		local info = C_Spell.GetSpellCharges(spellID)
		if info then
			-- Whether it has charges is learned out of combat and remembered.
			-- Si tiene cargas se aprende fuera de combate y se recuerda.
			if not U.IsSecret(info.maxCharges) then
				self.hasCharges = info.maxCharges > 1
			end
			if self.hasCharges then
				U.Note("charges", info.currentCharges)
				text = info.currentCharges
			end
		end
	elseif slot and (slot.kind == "item" or slot.kind == "macro") and self:ItemID() then
		-- Item data may not be cached yet at login: having more than one always
		-- shows the count, and GET_ITEM_INFO_RECEIVED refreshes it later.
		-- Al entrar, los datos del objeto pueden no estar cargados: tener más de
		-- uno siempre muestra la cantidad, y GET_ITEM_INFO_RECEIVED lo actualiza.
		local itemID = self:ItemID()
		local count = C_Item.GetItemCount(itemID, false, true) or 0
		local stack = C_Item.GetItemMaxStackSizeByID(itemID) or 1
		if count > 1 or stack > 1 or C_Item.IsConsumableItem(itemID) then
			text = count
		end
	end
	if not pcall(self.count.SetText, self.count, text) then
		self.count:SetText("")
	end
end

function Button:UpdateState()
	if not self.slot then return end
	local color = WHITE
	local hasTarget = UnitExists("target")
	local spellID, itemID = self:SpellID(), self:ItemID()

	if spellID then
		local ok, usable, noPower = pcall(C_Spell.IsSpellUsable, spellID)
		U.Note("usable", usable, not ok and usable or nil)
		if ok and not U.IsSecret(usable) and not U.IsSecret(noPower) then
			if noPower then color = BLUE elseif not usable then color = GREY end
		end
		if hasTarget and color == WHITE then
			local okRange, inRange = pcall(C_Spell.IsSpellInRange, spellID, "target")
			U.Note("range", inRange, not okRange and inRange or nil)
			if okRange and not U.IsSecret(inRange) and inRange == false then color = RED end
		end
	elseif itemID and self.slot.kind == "item" then
		local ok, usable = pcall(C_Item.IsUsableItem, itemID)
		if ok and not U.IsSecret(usable) and not usable then color = GREY end
		-- Item range is restricted in combat / El alcance de objetos está restringido en combate
		if hasTarget and color == WHITE and not InCombatLockdown() then
			local okRange, inRange = pcall(C_Item.IsItemInRange, itemID, "target")
			if okRange and not U.IsSecret(inRange) and inRange == false then color = RED end
		end
	end
	self.icon:SetVertexColor(color[1], color[2], color[3])
	-- The key turns red out of range, like Blizzard (D-53) / La tecla se pone roja fuera de alcance, como Blizzard (D-53)
	if color == RED then
		self.hotkey:SetTextColor(1, 0.1, 0.1)
	else
		self.hotkey:SetTextColor(0.75, 0.75, 0.75)
	end
end

-- The key of this button in the bar's active set, short like Blizzard (D-53).
-- La tecla de este botón en el conjunto activo de la barra, corta como Blizzard (D-53).
function Button:UpdateHotkey()
	local f = self.bar
	local key = f and f.data and ns.DB:ActiveSet(f.data).keys[self.index]
	local show = f and f.layout and f.layout.showKeys
	self.hotkey:SetText(show and key and ns.Keybinds.Abbreviate(key) or "")
end

local IsOverlayed = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed or IsSpellOverlayed

function Button:UpdateGlow()
	local spellID = self:SpellID()
	local on = false
	if spellID and IsOverlayed then
		local ok, result = pcall(IsOverlayed, spellID)
		on = ok and not U.IsSecret(result) and result or false
	end
	self:SetGlow(on)
end

function Button:SetGlow(on)
	self.glow:SetShown(on and true or false)
end

function Button:MatchesSpell(spellID)
	local own = self:SpellID()
	if not own then return false end
	if own == spellID then return true end
	local ok, override = pcall(C_Spell.GetOverrideSpell, own)
	return ok and not U.IsSecret(override) and override == spellID
end

-- Empty buttons use transparency, never Show/Hide, so it also works in combat.
-- Los botones vacíos usan transparencia, nunca Show/Hide, así funciona en combate.
function Button:UpdateEmpty()
	if self.slot then
		self:SetAlpha(1)
		return
	end
	local layout = self.bar and self.bar.layout
	if not layout then return end
	local show = layout.showEmpty or GetCursorInfo() ~= nil or ns.Modes:IsFree() or ns.Keybinds:IsActive()
	self:SetAlpha(show and 1 or 0)
end

---------------------------------------------------------------------------
-- Scripts
---------------------------------------------------------------------------
local function OnEnter(self)
	if not self.kind then return end
	GameTooltip_SetDefaultAnchor(GameTooltip, self)   -- respects tooltip addons / respeta addons de tooltips (D-05)
	pcall(self.kind.tooltip, self.slot)
	GameTooltip:Show()
end

local function OnLeave()
	GameTooltip:Hide()
end

local function OnDragStart(self)
	if InCombatLockdown() or not self.slot then return end
	-- Taking content out always needs Shift, or Blizzard's "pick up action" modifier if set to another key (D-23).
	-- Sacar contenido siempre pide Shift, o el modificador de Blizzard si está en otra tecla (D-23).
	if not IsShiftKeyDown() and not IsModifiedClick("PICKUPACTION") then return end
	Buttons:PickUp(self)
end

local function OnReceiveDrag(self)
	Buttons:Receive(self)
end

-- Out of combat, a click with something on the cursor places it instead of
-- casting. Shift + click casts normally ([mod:shift] macros, D-44): buttons
-- act on release, and a drag cancels the click, so picking up never casts.
-- Fuera de combate, un clic con algo en el cursor lo coloca en vez de lanzar.
-- Shift + clic lanza normal (macros [mod:shift], D-44): los botones actúan al
-- soltar, y arrastrar cancela el clic, así recoger nunca lanza.
local function PreClick(self, button, down)
	-- A key press looks pressed, like Blizzard's buttons (D-53).
	-- Una tecla se ve presionada, como los botones de Blizzard (D-53).
	if button == "Keybind" then
		pcall(self.SetButtonState, self, down and "PUSHED" or "NORMAL")
		return
	end
	if InCombatLockdown() or not GetCursorInfo() then return end
	self.savedType = self:GetAttribute("type")
	self:SetAttribute("type", nil)
	self.suppressed = true
	self.receiving = true
end

local function PostClick(self, _, down)
	if not self.suppressed then return end
	self.suppressed = nil
	self:SetAttribute("type", self.savedType)
	if self.receiving and not down then
		Buttons:Receive(self)
	end
	self.receiving = nil
end

---------------------------------------------------------------------------
-- Creation / Creación
---------------------------------------------------------------------------
-- Blizzard's action button atlases (textures of the game, not code) (D-19).
-- Los atlas de los botones de Blizzard (texturas del juego, no código) (D-19).
local ART_ATLASES = {
	border = "UI-HUD-ActionBar-IconFrame",
	down = "UI-HUD-ActionBar-IconFrame-Down",
	mouseover = "UI-HUD-ActionBar-IconFrame-Mouseover",
	mask = "UI-HUD-ActionBar-IconFrame-Mask",
	background = "UI-HUD-ActionBar-IconFrame-Background",
}

-- Checked once; the missing ones show up in the report.
-- Se revisan una vez; los que falten salen en el reporte.
function Buttons:Art()
	if not self.art then
		self.art, self.missingArt = {}, {}
		for key, atlas in pairs(ART_ATLASES) do
			if AtlasExists(atlas) then
				self.art[key] = atlas
			else
				table.insert(self.missingArt, atlas)
			end
		end
		table.sort(self.missingArt)
	end
	return self.art
end

-- Runs securely right before each click, also in combat (D-53): a key
-- ("Keybind") acts on press if Blizzard's "cast on key press" option is on;
-- the mouse always acts on release, so a drag never casts (D-44).
-- Corre seguro justo antes de cada clic, también en combate (D-53): una tecla
-- ("Keybind") actúa al presionar si la opción de Blizzard "lanzar al presionar"
-- está activa; el mouse siempre actúa al soltar, así arrastrar nunca lanza (D-44).
local CLICK_WRAP = [[
	if button == "Keybind" then
		self:SetAttribute("useOnKeyDown", owner:GetAttribute("ob-keydown") and true or false)
	else
		self:SetAttribute("useOnKeyDown", false)
	end
]]

local function CreateButton(name, parent)
	local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
	Mixin(b, Button)
	-- Both press and release arrive; CLICK_WRAP decides which one acts.
	-- Llegan el presionar y el soltar; CLICK_WRAP decide cuál actúa.
	b:RegisterForClicks("AnyUp", "AnyDown")
	b:SetAttribute("useOnKeyDown", false)
	SecureHandlerWrapScript(b, "OnClick", parent, CLICK_WRAP)
	b:RegisterForDrag("LeftButton")
	-- Follow Blizzard's self / focus / mouseover cast modifiers.
	-- Seguir los modificadores de Blizzard de auto-lanzamiento, foco y mouseover.
	b:SetAttribute("checkselfcast", true)
	b:SetAttribute("checkfocuscast", true)
	b:SetAttribute("checkmouseovercast", true)

	-- Blizzard's action button art (D-19), or a flat look if the client lacks it.
	-- El arte de los botones de Blizzard (D-19), o estilo plano si el cliente no lo tiene.
	local art = Buttons:Art()
	local blizzard = art.border ~= nil and b.SetNormalAtlas ~= nil

	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	if blizzard and art.background then
		bg:SetAtlas(art.background)
	else
		bg:SetColorTexture(0, 0, 0, 0.6)
	end

	local icon = b:CreateTexture(nil, "ARTWORK")
	b.icon = icon
	if blizzard and art.mask then
		-- Rounded corners: Blizzard's mask, centred and at its own size relative
		-- to a 45 px button, like Blizzard does. Stretching it to the button
		-- clipped the icon too much (it has a transparent margin) (0.3.12).
		-- Esquinas redondeadas: la máscara de Blizzard, centrada y a su tamaño
		-- propio respecto a un botón de 45 px, como hace Blizzard. Estirarla al
		-- botón recortaba de más el ícono (trae un margen transparente) (0.3.12).
		icon:SetAllPoints()
		local mask = b:CreateMaskTexture()
		mask:SetAtlas(art.mask, false)
		mask:SetPoint("CENTER", icon)
		icon:AddMaskTexture(mask)
		b.iconMask = mask
	else
		icon:SetPoint("TOPLEFT", 1, -1)
		icon:SetPoint("BOTTOMRIGHT", -1, 1)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end

	if blizzard then
		-- Frame, pressed frame and hover, sized like Blizzard's (46×45 on a 45 button).
		-- Marco, marco presionado y resaltado, con la medida de Blizzard (46×45 en un botón de 45).
		b:SetNormalAtlas(art.border)
		if art.down then b:SetPushedAtlas(art.down) end
		if art.mouseover then b:SetHighlightAtlas(art.mouseover) end
		local maskInfo = art.mask and C_Texture.GetAtlasInfo(art.mask)
		b:HookScript("OnSizeChanged", function(self, width, height)
			for _, texture in pairs({ self:GetNormalTexture(), self:GetPushedTexture(), self:GetHighlightTexture() }) do
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT")
				texture:SetSize(width * 46 / 45, height)
			end
			if self.iconMask then
				if maskInfo and maskInfo.width and maskInfo.width > 0 then
					self.iconMask:SetSize(maskInfo.width * width / 45, maskInfo.height * height / 45)
				else
					self.iconMask:SetSize(width, height)
				end
			end
		end)
	else
		local highlight = b:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints(icon)
		highlight:SetColorTexture(1, 1, 1, 0.15)
		b:SetHighlightTexture(highlight)

		local pushed = b:CreateTexture(nil, "OVERLAY")
		pushed:SetAllPoints(icon)
		pushed:SetColorTexture(1, 1, 1, 0.25)
		b:SetPushedTexture(pushed)
	end

	-- Inside the frame, so the swipe does not cover the rounded corners.
	-- Dentro del marco, para que el barrido no tape las esquinas redondeadas.
	local inset = blizzard and 2 or 0
	local cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	cooldown:SetPoint("TOPLEFT", icon, inset, -inset)
	cooldown:SetPoint("BOTTOMRIGHT", icon, -inset, inset)
	cooldown:SetDrawEdge(false)
	b.cooldown = cooldown

	-- Charge recharge: edge only, like Blizzard / Recarga de cargas: solo el borde, como Blizzard
	local chargeCooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	chargeCooldown:SetAllPoints(cooldown)
	chargeCooldown:SetDrawSwipe(false)
	chargeCooldown:SetDrawEdge(true)
	chargeCooldown:SetHideCountdownNumbers(true)
	b.chargeCooldown = chargeCooldown

	-- Text above the cooldown swipe / Texto por encima del barrido del cooldown
	local top = CreateFrame("Frame", nil, b)
	top:SetAllPoints()
	top:SetFrameLevel(cooldown:GetFrameLevel() + 2)

	b.hotkey = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
	b.hotkey:SetPoint("TOPRIGHT", -2, -3)

	b.count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	b.count:SetPoint("BOTTOMRIGHT", -2, 2)

	-- Crafting quality, top left like Blizzard / Calidad de profesión, arriba a la izquierda como Blizzard
	b.quality = top:CreateTexture(nil, "OVERLAY")
	b.quality:SetPoint("TOPLEFT", 1, -1)
	b.quality:SetPoint("BOTTOMRIGHT", b, "CENTER", 2, -2)
	b.quality:Hide()

	b.label = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
	b.label:SetPoint("BOTTOMLEFT", 2, 2)
	b.label:SetPoint("BOTTOMRIGHT", -2, 2)
	b.label:SetWordWrap(false)

	-- Proc glow: Blizzard's frame tinted gold, or a square edge in the flat look.
	-- Brillo de proc: el marco de Blizzard en dorado, o un borde cuadrado en el estilo plano.
	local glow
	if blizzard then
		glow = CreateFrame("Frame", nil, b)
		glow:SetAllPoints()
		local texture = glow:CreateTexture(nil, "OVERLAY")
		texture:SetAtlas(art.border)
		texture:SetPoint("TOPLEFT")
		texture:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, 0)
		texture:SetVertexColor(1, 0.82, 0.2)
		texture:SetBlendMode("ADD")
	else
		glow = U.Border(b, 2, 1, 0.82, 0.2, 1)
	end
	glow:SetFrameLevel(top:GetFrameLevel() + 1)
	local pulse = glow:CreateAnimationGroup()
	pulse:SetLooping("BOUNCE")
	local fade = pulse:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0.3)
	fade:SetDuration(0.5)
	glow:SetScript("OnShow", function() pulse:Play() end)
	glow:SetScript("OnHide", function() pulse:Stop() end)
	glow:Hide()
	b.glow = glow

	local Wrap = ns.Log.Wrap
	b:SetScript("OnEnter", Wrap(OnEnter))
	b:SetScript("OnLeave", OnLeave)
	b:SetScript("OnDragStart", Wrap(OnDragStart))
	b:SetScript("OnReceiveDrag", Wrap(OnReceiveDrag))
	b:SetScript("PreClick", Wrap(PreClick))
	b:SetScript("PostClick", Wrap(PostClick))
	return b
end

-- Buttons are pooled by name and reused when a bar is rebuilt.
-- Los botones se guardan por nombre y se reutilizan al reconstruir una barra.
function Buttons:Get(barFrame, index)
	local name = ("OnlyBarsBar%dButton%d"):format(barFrame.id, index)
	local b = self.pool[name]
	if not b then
		b = CreateButton(name, barFrame)
		self.pool[name] = b
	end
	b.bar = barFrame
	b.index = index
	return b
end

---------------------------------------------------------------------------
-- Drag and drop / Arrastrar y soltar
---------------------------------------------------------------------------
function Buttons:Store(b, slot)
	ns.DB:ActiveSet(b.bar.data).slots[b.index] = slot
	b:ApplySlot(slot)
end

function Buttons:PickUp(b)
	local slot = b.slot
	self:Store(b, nil)
	pcall(Kinds[slot.kind].pickup, slot)
end

function Buttons:Receive(b)
	if not GetCursorInfo() then return end
	if InCombatLockdown() then
		U.Print(L.COMBAT_BLOCKED)
		return
	end
	local slot, cursorKind, raw = SlotFromCursor()
	if not slot then
		if cursorKind then
			U.Print(L.UNSUPPORTED)
			ns.Log:Add(L.LOG_KIND_WARNING, L.LOG_CURSOR:format(raw))
		end
		return
	end
	local old = b.slot
	ClearCursor()
	self:Store(b, slot)
	-- Swap: what was there goes to the cursor / Intercambio: lo que había pasa al cursor
	if old then
		pcall(Kinds[old.kind].pickup, old)
	end
end

---------------------------------------------------------------------------
-- Updates / Actualizaciones
-- Only buttons with content on a visible bar are updated.
-- Solo se actualizan los botones con contenido en una barra visible.
---------------------------------------------------------------------------
function Buttons:ForEachActive(fn)
	for _, b in pairs(self.pool) do
		if b.slot and b:IsVisible() then fn(b) end
	end
end

local function Each(...)
	local methods = { ... }
	return function()
		Buttons:ForEachActive(function(b)
			for _, method in ipairs(methods) do b[method](b) end
		end)
	end
end

ns:On("SPELL_UPDATE_COOLDOWN", Each("UpdateCooldown"))
ns:On("SPELL_UPDATE_CHARGES", Each("UpdateCooldown", "UpdateCount"))
ns:On("BAG_UPDATE_COOLDOWN", Each("UpdateCooldown"))
ns:On("SPELL_UPDATE_USABLE", Each("UpdateState"))
ns:On("PLAYER_TARGET_CHANGED", Each("UpdateState"))
ns:On("BAG_UPDATE_DELAYED", Each("UpdateCount", "UpdateState"))
ns:On("SPELLS_CHANGED", Each("Refresh"))
ns:On("UPDATE_MACROS", Each("Refresh"))
ns:On("EQUIPMENT_SETS_CHANGED", Each("Refresh"))

-- Item data arrived from the server / Llegaron los datos del objeto desde el servidor
ns:On("GET_ITEM_INFO_RECEIVED", function(_, itemID)
	Buttons:ForEachActive(function(b)
		if b:ItemID() == itemID then b:Refresh() end
	end)
end)

ns:On("CURSOR_CHANGED", function()
	for _, b in pairs(Buttons.pool) do
		if not b.slot and b:IsShown() then b:UpdateEmpty() end
	end
end)

local function OnGlow(on)
	return function(_, spellID)
		U.Note("glow", spellID)
		if U.IsSecret(spellID) then return end
		local matched = false
		Buttons:ForEachActive(function(b)
			if b:MatchesSpell(spellID) then
				b:SetGlow(on)
				matched = true
			end
		end)
		if on then U.NoteGlowSpell(spellID, matched) end
	end
end
ns:On("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", OnGlow(true))
ns:On("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", OnGlow(false))

-- Range only changes with distance, so it is polled while there is a target.
-- El alcance solo cambia con la distancia: se revisa mientras hay objetivo.
function Buttons:StartRangeTimer()
	if self.rangeTimer then return end
	self.rangeTimer = C_Timer.NewTicker(0.25, ns.Log.Wrap(function()
		if UnitExists("target") then
			Buttons:ForEachActive(function(b) b:UpdateState() end)
		end
	end))
	self:StartMacroTimer()
end

---------------------------------------------------------------------------
-- Live macros (D-46) / Macros en vivo (D-46)
-- A macro button follows what the macro would use now. It only redraws when
-- that changes. Modifiers update at once; any other condition (target,
-- combat, form, mount, stealth…) is checked 5 times a second.
-- Un botón con macro sigue lo que la macro usaría ahora. Solo se redibuja si
-- eso cambia. Los modificadores actualizan al instante; cualquier otra
-- condición (objetivo, combate, forma, montura, sigilo…) se revisa 5 veces por segundo.
---------------------------------------------------------------------------
function Button:UpdateMacro()
	if not (self.slot and self.slot.kind == "macro") then return end
	local kind, target = self.kind.target(self.slot.name)
	local key = kind and (kind .. ":" .. tostring(target)) or ""
	if key == self.macroKey then return end
	self.macroKey = key
	self:UpdateIcon()
	self:UpdateQuality()
	self:UpdateCooldown()
	self:UpdateCount()
	self:UpdateState()
	self:UpdateGlow()
	if GameTooltip:IsOwned(self) then OnEnter(self) end
end

local function UpdateMacros()
	Buttons:ForEachActive(function(b) b:UpdateMacro() end)
end

ns:On("MODIFIER_STATE_CHANGED", UpdateMacros)

function Buttons:StartMacroTimer()
	if self.macroTimer then return end
	self.macroTimer = C_Timer.NewTicker(0.2, ns.Log.Wrap(UpdateMacros))
end
