--[[
	OnlyBars · UI/Report.lua
	Report window: diagnostics and error log as copyable text (Ctrl+A, Ctrl+C).
	Ventana de Reporte: diagnóstico y errores como texto copiable (Ctrl+A, Ctrl+C).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, Style = ns.L, ns.Style

local Report = {}
ns.Report = Report

local WIDTH, HEIGHT = 640, 420

-- Builds the window: hint, text box and buttons / Arma la ventana: aviso, caja de texto y botones
local function Create()
	local f = Style.Window("OnlyBarsReport", L.REPORT_TITLE, WIDTH, HEIGHT)

	local hint = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	hint:SetPoint("TOPLEFT", 12, -36)
	hint:SetText(L.REPORT_HINT)

	local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 10, -54)
	box:SetPoint("BOTTOMRIGHT", -10, 44)
	Style.Flat(box, Style.PANEL)

	local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", -28, 8)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetFontObject(ChatFontNormal)
	edit:SetWidth(WIDTH - 20 - 36)
	edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	scroll:SetScrollChild(edit)
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function() edit:SetFocus() end)
	f.edit = edit

	local selectAll = Style.Button(f, L.REPORT_SELECT, 140)
	selectAll:SetPoint("BOTTOMLEFT", 10, 12)
	selectAll:SetScript("OnClick", function()
		edit:SetFocus()
		edit:HighlightText()
	end)

	local clear = Style.Button(f, L.REPORT_CLEAR, 140)
	clear:SetPoint("LEFT", selectAll, "RIGHT", 8, 0)
	clear:SetScript("OnClick", function() ns.Log:Clear() end)

	local close = Style.Button(f, L.REPORT_CLOSE, 100)
	close:SetPoint("BOTTOMRIGHT", -10, 12)
	close:SetScript("OnClick", function() f:Hide() end)

	f:SetScript("OnShow", function() Report:Refresh() end)
	return f
end

-- Fills it with the current report / La llena con el reporte actual
function Report:Refresh()
	if not self.frame then return end
	self.frame.edit:SetText(ns.Log:ReportText())
	self.frame.edit:SetCursorPosition(0)
end

-- Refreshes only if shown / Actualiza solo si se ve
function Report:RefreshIfShown()
	if self.frame and self.frame:IsShown() then self:Refresh() end
end

-- Holding Shift/Ctrl/Alt refreshes the report, to see what live macros read (D-46).
-- Presionar Shift/Ctrl/Alt actualiza el reporte, para ver qué leen las macros en vivo (D-46).
ns:On("MODIFIER_STATE_CHANGED", function() Report:RefreshIfShown() end)

-- Opens it / La abre
function Report:Show()
	self.frame = self.frame or Create()
	self.frame:Show()
end

-- /ob errores opens or closes it / /ob errores la abre o la cierra
function Report:Toggle()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
	else
		self:Show()
	end
end
