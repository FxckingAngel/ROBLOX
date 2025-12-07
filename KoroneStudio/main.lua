-- 🌙 Korone Studio Tools - Mobile + PC Safe Loader
-- Credits: Moon (Dex Inspiration) + Korone
print("[KoroneStudio] Booting...")

local function safeLoad(path)
    local full = "KoroneStudio/" .. path

    if not readfile then
        warn("Executor does not support readfile")
        return
    end

    if not isfile(full) then
        warn("Missing file:", full)
        return
    end

    local src = readfile(full)
    local fn, err = loadstring(src, "=" .. path)

    if not fn then
        warn("Compile error in", path, err)
        return
    end

    local ok, runErr = pcall(fn)
    if not ok then
        warn("Runtime error in", path, runErr)
    end
end

-- ✅ Load order (important)
safeLoad("KS_Util.lua")
safeLoad("Editor.lua")
safeLoad("Explorer.lua")
safeLoad("RSpy.lua")
safeLoad("SecretPanel.lua")
safeLoad("ModelViewer.lua")
safeLoad("Hub.lua")

print("[KoroneStudio] ✅ Loaded successfully")
