--[[
	OnlyBars · UI/Widgets.lua
	Shared controls for the Edit Mode dialog and the /ob panel (D-18): slider
	rows, check boxes, cycle buttons, headers and buttons.
	Controles compartidos de la ventana del Modo Edición y del panel /ob (D-18):
	filas con deslizador, casillas, botones de ciclo, encabezados y botones.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L = ns.L

local W = {}
ns.Widgets = W

W.ROW = 30

-- Blizzard templates may change between patches; nil if one is missing.
-- Las plantillas de Blizzard pueden cambiar entre parches; nil si falta alguna.
function W.TryCreate(frameType, parent, template)
	local ok, frame = pcall(CreateFrame, frameType, nil, parent, template)
	if ok then return frame end
	ns.Log:Add(L.LOG_KIND_WARNING, L.LOG_TEMPLATE:format(template))
	return nil
end

-- Label + Blizzard slider with steppers. onChange(value) only fires for the user.
-- Etiqueta + deslizador de Blizzard con flechas. onChange(value) solo se llama por el usuario.
function W.SliderRow(parent, def, width, labelWidth, onChange)
	local slider = W.TryCreate("Frame", parent, "MinimalSliderWithSteppersTemplate")
	if not slider then return nil end

	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(width, W.ROW)
	row.def = def

	local label = row:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")
	label:SetPoint("LEFT")
	label:SetWidth(labelWidth)
	label:SetJustifyH("LEFT")
	label:SetText(def.label)

	slider:SetParent(row)
	slider:SetPoint("LEFT", label, "RIGHT", 4, 0)
	slider:SetPoint("RIGHT", row, "RIGHT", -44, 0)
	slider:SetHeight(W.ROW)

	local formatters = {
		[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, def.format),
	}
	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not row.loading then ns.Log.Call(onChange, value) end
	end, row)

	function row:Load(value)
		self.loading = true
		local steps = math.floor((def.max - def.min) / def.step + 0.5)
		slider:Init(value, def.min, def.max, steps, formatters)
		self.loading = false
	end

	-- Greyed out and not usable when disabled / En gris y sin poder usarse cuando está deshabilitado
	function row:SetEnabled(enabled)
		if slider.SetEnabled then slider:SetEnabled(enabled) end
		label:SetTextColor((enabled and HIGHLIGHT_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
	end
	return row
end

-- Check box with its label. onClick(checked, row); row.label can be renamed later.
-- Casilla con su etiqueta. onClick(checked, row); row.label se puede cambiar después.
function W.Check(parent, text, width, onClick)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(width, 24)
	local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	check:SetSize(24, 24)
	check:SetPoint("LEFT", -2, 0)
	local label = row:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")
	label:SetPoint("LEFT", check, "RIGHT", 2, 0)
	label:SetPoint("RIGHT")
	label:SetJustifyH("LEFT")
	label:SetWordWrap(false)
	label:SetText(text)
	row.label = label
	check:SetScript("OnClick", ns.Log.Wrap(function(self)
		onClick(self:GetChecked() and true or false, row)
	end))

	function row:Load(value) check:SetChecked(value and true or false) end

	-- Greyed out and not usable when disabled / En gris y sin poder usarse cuando está deshabilitado
	function row:SetEnabled(enabled)
		check:SetEnabled(enabled)
		label:SetTextColor((enabled and HIGHLIGHT_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
	end
	return row
end

-- Flat button that goes through the definition's options. onChange(value).
-- Botón plano que pasa por las opciones de la definición. onChange(value).
function W.Cycle(parent, def, width, onChange)
	local button = ns.Style.Button(parent, "", width)
	button:SetHeight(24)
	local current

	local function Show(value)
		current = value
		for _, option in ipairs(def.options) do
			if option[1] == value then
				button.text:SetText(("%s: %s"):format(def.label, option[2]))
			end
		end
	end

	button:SetScript("OnClick", ns.Log.Wrap(function()
		for i, option in ipairs(def.options) do
			if option[1] == current then
				local nextOption = def.options[i % #def.options + 1]
				Show(nextOption[1])
				onChange(nextOption[1])
				return
			end
		end
	end))

	button.Load = function(_, value) Show(value) end

	-- Greyed out and not usable when disabled / En gris y sin poder usarse cuando está deshabilitado
	local enable = button.SetEnabled
	function button:SetEnabled(enabled)
		enable(self, enabled)
		self.text:SetTextColor((enabled and HIGHLIGHT_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
	end
	return button
end

-- Gold section title with a thin line / Título de sección dorado con una línea delgada
function W.Header(parent, text, width)
	local header = CreateFrame("Frame", nil, parent)
	header:SetSize(width, 20)
	local label = header:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormal")
	label:SetPoint("LEFT")
	label:SetText(text)
	local line = header:CreateTexture(nil, "ARTWORK")
	line:SetPoint("LEFT", label, "RIGHT", 6, 0)
	line:SetPoint("RIGHT")
	line:SetHeight(1)
	line:SetColorTexture(1, 0.82, 0, 0.25)
	header.label = label
	return header
end

-- Blizzard's red button / El botón rojo de Blizzard
function W.BlizzardButton(parent, text, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 24)
	button:SetText(text)
	button:SetScript("OnClick", ns.Log.Wrap(onClick))
	return button
end

-- OnlyBars' flat button / El botón plano de OnlyBars
function W.FlatButton(parent, text, width, onClick)
	local button = ns.Style.Button(parent, text, width)
	button:SetScript("OnClick", ns.Log.Wrap(onClick))
	return button
end
