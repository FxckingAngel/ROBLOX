-- 🌙 Korone Studio Tools - SANDBOX SAFE UNIVERSAL LOADER
-- Credits: Moon (Dex inspiration) + Korone

print("[KoroneStudio] Booting...")

if not (typeof(readfile) == "function" and typeof(isfile) == "function") then
    warn("[KoroneStudio] Executor has no filesystem access.")
    warn("[KoroneStudio] Use the single-file version instead.")
    return
end

-- ✅ ONLY use local relative paths (no directory escaping)
local BASE = ""

local function safeLoad(file)
    local path = BASE .. file

    if not isfile(path) then
        warn("[KoroneStudio] Missing file:", path)
        return
    end

    local src = readfile(path)
    local fn, err = loadstring(src, "=" .. file)

    if not fn then
        warn("[KoroneStudio] Compile error in " .. file .. ": " .. tostring(err))
        return
    end

    local ok, runErr = pcall(fn)
    if not ok then
        warn("[KoroneStudio] Runtime error in " .. file .. ": " .. tostring(runErr))
    end
end

-- ✅ Correct load order
safeLoad("KS_Util.lua")
safeLoad("Editor.lua")
safeLoad("Explorer.lua")
safeLoad("RSpy.lua")
safeLoad("SecretPanel.lua")
safeLoad("ModelViewer.lua")
safeLoad("Hub.lua")

print("[KoroneStudio] ✅ Loaded successfully – look for the 🌙 hub.")
