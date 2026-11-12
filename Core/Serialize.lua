--[[
	OnlyBars · Core/Serialize.lua
	Tables to text and back, for exporting bars (D-76), like Blizzard's talent
	loadout strings. Plain Lua, no loadstring: a pasted text can never run code.
	Format: "!OB<version>!" .. Base64(data) .. "!" .. checksum (hex).
	Tablas a texto y de regreso, para exportar barras (D-76), como el texto de
	los talentos de Blizzard. Lua simple, sin loadstring: un texto pegado nunca
	puede ejecutar código.
	Formato: "!OB<versión>!" .. Base64(datos) .. "!" .. suma de control (hex).
	© 2026 iAthVo_Kr
]]

local _, ns = ...

local Serialize = {}
ns.Serialize = Serialize

local MAX_DEPTH = 12

---------------------------------------------------------------------------
-- Values / Valores
-- table: { key value key value … }   string: s<length>:<bytes>
-- number: n<number>;   true: t   false: f
---------------------------------------------------------------------------
local function Number(n)
	if n == math.floor(n) and math.abs(n) < 2 ^ 53 then return ("%d"):format(n) end
	return ("%.17g"):format(n)
end

-- Keys in a fixed order, so the same bars always give the same text.
-- Las claves en un orden fijo, así las mismas barras siempre dan el mismo texto.
local function SortedKeys(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b)
		local ta, tb = type(a), type(b)
		if ta ~= tb then return ta < tb end
		return a < b
	end)
	return keys
end

local function Write(out, value, depth)
	local kind = type(value)
	if kind == "string" then
		out[#out + 1] = "s" .. #value .. ":" .. value
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then error("number") end
		out[#out + 1] = "n" .. Number(value) .. ";"
	elseif kind == "boolean" then
		out[#out + 1] = value and "t" or "f"
	elseif kind == "table" then
		if depth > MAX_DEPTH then error("depth") end
		out[#out + 1] = "{"
		for _, k in ipairs(SortedKeys(value)) do
			local kt = type(k)
			if kt == "string" or kt == "number" then
				Write(out, k, depth + 1)
				Write(out, value[k], depth + 1)
			end
		end
		out[#out + 1] = "}"
	else
		error("type " .. kind)
	end
end

-- Table → string; nil, error if it holds something that cannot be written.
-- Tabla → texto; nil, error si tiene algo que no se puede escribir.
function Serialize.Pack(value)
	local out = {}
	local ok, err = pcall(Write, out, value, 0)
	if not ok then return nil, err end
	return table.concat(out)
end

-- Reads one value at pos; returns value, next pos. Errors on anything odd.
-- Lee un valor en pos; regresa valor y la siguiente posición. Falla con cualquier cosa rara.
local function Read(s, pos, depth)
	local tag = s:sub(pos, pos)
	if tag == "s" then
		local colon = s:find(":", pos + 1, true)
		local length = colon and tonumber(s:sub(pos + 1, colon - 1))
		if not length or length < 0 or colon + length > #s then error("string") end
		return s:sub(colon + 1, colon + length), colon + length + 1
	elseif tag == "n" then
		local semi = s:find(";", pos + 1, true)
		local n = semi and tonumber(s:sub(pos + 1, semi - 1))
		if not n or n ~= n or n == math.huge or n == -math.huge then error("number") end
		return n, semi + 1
	elseif tag == "t" then
		return true, pos + 1
	elseif tag == "f" then
		return false, pos + 1
	elseif tag == "{" then
		if depth > MAX_DEPTH then error("depth") end
		local t = {}
		pos = pos + 1
		while true do
			if pos > #s then error("end") end
			if s:sub(pos, pos) == "}" then return t, pos + 1 end
			local k, v
			k, pos = Read(s, pos, depth + 1)
			if type(k) ~= "string" and type(k) ~= "number" then error("key") end
			v, pos = Read(s, pos, depth + 1)
			t[k] = v
		end
	end
	error("tag")
end

-- String → table; nil if it is not valid / Texto → tabla; nil si no es válido
function Serialize.Unpack(s)
	if type(s) ~= "string" or s == "" then return nil end
	local ok, value, pos = pcall(Read, s, 1, 0)
	if not ok or pos ~= #s + 1 then return nil end
	return value
end

---------------------------------------------------------------------------
-- Base64, without bit operations (Lua 5.1) / Base64, sin operaciones de bits (Lua 5.1)
---------------------------------------------------------------------------
local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local VALUE = {}
for i = 1, #ALPHABET do VALUE[ALPHABET:sub(i, i)] = i - 1 end

function Serialize.Encode64(s)
	local out = {}
	for i = 1, #s, 3 do
		local a, b, c = s:byte(i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local c1, c2 = math.floor(n / 262144), math.floor(n / 4096) % 64
		local c3, c4 = math.floor(n / 64) % 64, n % 64
		out[#out + 1] = ALPHABET:sub(c1 + 1, c1 + 1) .. ALPHABET:sub(c2 + 1, c2 + 1)
			.. (b and ALPHABET:sub(c3 + 1, c3 + 1) or "=") .. (c and ALPHABET:sub(c4 + 1, c4 + 1) or "=")
	end
	return table.concat(out)
end

-- nil if it has characters that are not Base64 / nil si tiene caracteres que no son Base64
function Serialize.Decode64(s)
	s = s:gsub("=+$", "")
	if s:find("[^%w%+/]") or #s % 4 == 1 then return nil end
	local out = {}
	for i = 1, #s, 4 do
		local chunk = s:sub(i, i + 3)
		local n, count = 0, #chunk
		for j = 1, 4 do
			n = n * 64 + (j <= count and VALUE[chunk:sub(j, j)] or 0)
		end
		local a, b, c = math.floor(n / 65536), math.floor(n / 256) % 256, n % 256
		out[#out + 1] = string.char(a)
		if count > 2 then out[#out + 1] = string.char(b) end
		if count > 3 then out[#out + 1] = string.char(c) end
	end
	return table.concat(out)
end

-- Adler-32, to tell a damaged or cut text / Adler-32, para saber si un texto está dañado o incompleto
function Serialize.Checksum(s)
	local a, b = 1, 0
	for i = 1, #s do
		a = (a + s:byte(i)) % 65521
		b = (b + a) % 65521
	end
	return ("%08x"):format(b * 65536 + a)
end

---------------------------------------------------------------------------
-- Text / Texto
---------------------------------------------------------------------------
Serialize.VERSION = 1

-- Table → "!OB1!…!checksum" / Tabla → "!OB1!…!suma"
function Serialize.ToText(value)
	local data, err = Serialize.Pack(value)
	if not data then return nil, err end
	return ("!OB%d!%s!%s"):format(Serialize.VERSION, Serialize.Encode64(data), Serialize.Checksum(data))
end

-- Text → table, or nil and why: "format", "version", "damaged".
-- Spaces and line breaks (from chat or Discord) are ignored.
-- Texto → tabla, o nil y por qué: "format", "version", "damaged".
-- Los espacios y saltos de línea (del chat o de Discord) se ignoran.
function Serialize.FromText(text)
	if type(text) ~= "string" then return nil, "format" end
	text = text:gsub("%s+", "")
	local version, body, sum = text:match("^!OB(%d+)!([%w%+/=]+)!(%x+)$")
	if not version then return nil, "format" end
	if tonumber(version) ~= Serialize.VERSION then return nil, "version" end
	local data = Serialize.Decode64(body)
	if not data or Serialize.Checksum(data) ~= sum:lower() then return nil, "damaged" end
	local value = Serialize.Unpack(data)
	if type(value) ~= "table" then return nil, "damaged" end
	return value
end
