--[[
	OnlyBars · UI/Style.lua
	Shared look for OnlyBars windows: flat, dark, minimal.
	Estilo común de las ventanas de OnlyBars: plano, oscuro, minimalista.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local U = ns.U

local Style = {}
ns.Style = Style

Style.BG = { 0.06, 0.07, 0.09, 0.96 }
Style.PANEL = { 0.11, 0.12, 0.15, 1 }
Style.BORDER = { 0, 0, 0, 1 }
Style.ACCENT = U.ACCENT

---------------------------------------------------------------------------
-- Fonts (0.10.1): OnlyBars' own, one point bigger than Blizzard's small ones
-- and with a crisp 1 px shadow, so text stays legible at low UI scales.
-- Names follow Blizzard's: OnlyBarsFont<Color><Size>.
-- Fuentes (0.10.1): propias de OnlyBars, un punto más grandes que las chicas de
-- Blizzard y con sombra nítida de 1 px, así el texto se lee con escalas bajas.
-- Los nombres siguen a los de Blizzard: OnlyBarsFont<Color><Tamaño>.
---------------------------------------------------------------------------
local FONT_COLORS = {
	Normal = { 1, 0.82, 0 },        -- gold titles / títulos dorados
	Highlight = { 1, 1, 1 },        -- white text / texto blanco
	Disable = { 0.6, 0.6, 0.6 },    -- grey hints / avisos en gris
}
local FONT_SIZES = { Small = 11, [""] = 13, Large = 16 }

for color, rgb in pairs(FONT_COLORS) do
	for size, points in pairs(FONT_SIZES) do
		local font = CreateFont("OnlyBarsFont" .. color .. size)
		font:SetFont(STANDARD_TEXT_FONT, points, "")
		font:SetTextColor(rgb[1], rgb[2], rgb[3])
		font:SetShadowColor(0, 0, 0, 1)
		font:SetShadowOffset(1, -1)
	end
end

local FLAT = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
}

function Style.Flat(frame, color)
	color = color or Style.BG
	frame:SetBackdrop(FLAT)
	frame:SetBackdropColor(color[1], color[2], color[3], color[4])
	frame:SetBackdropBorderColor(unpack(Style.BORDER))
end

-- A movable window with a title bar and an accent line. Esc closes it.
-- Una ventana movible con barra de título y línea de acento. Se cierra con Esc.
function Style.Window(name, title, width, height)
	local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	f:SetSize(width, height)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	Style.Flat(f)
	tinsert(UISpecialFrames, name)

	local bar = CreateFrame("Frame", nil, f)
	bar:SetPoint("TOPLEFT")
	bar:SetPoint("TOPRIGHT")
	bar:SetHeight(28)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", function() f:StartMoving() end)
	bar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

	local line = bar:CreateTexture(nil, "ARTWORK")
	line:SetPoint("BOTTOMLEFT")
	line:SetPoint("BOTTOMRIGHT")
	line:SetHeight(1)
	line:SetColorTexture(Style.ACCENT[1], Style.ACCENT[2], Style.ACCENT[3], 1)

	f.title = bar:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")
	f.title:SetPoint("LEFT", 12, 0)
	f.title:SetText(title)

	local close = Style.Button(bar, "×", 28)
	close:SetPoint("RIGHT", -1, 0)
	close:SetHeight(26)
	close:SetScript("OnClick", function() f:Hide() end)

	f:Hide()
	return f
end

-- Flat text button with an accent hover / Botón plano con acento al pasar el mouse
function Style.Button(parent, text, width)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(width or 120, 24)
	Style.Flat(b, Style.PANEL)
	b.text = b:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlightSmall")
	b.text:SetPoint("CENTER")
	b.text:SetText(text)
	b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(Style.ACCENT[1], Style.ACCENT[2], Style.ACCENT[3], 1) end)
	b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(Style.BORDER)) end)
	return b
end
