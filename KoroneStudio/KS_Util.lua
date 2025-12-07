local HttpService = game:GetService("HttpService")

local KS_UTIL = {}

-- =========================
-- Executor capability checks
-- =========================
KS_UTIL.hasFS =
    typeof(writefile) == "function" and
    typeof(readfile) == "function" and
    typeof(isfolder) == "function" and
    typeof(makefolder) == "function"

KS_UTIL.hasDecompile =
    typeof(decompile) == "function" or
    typeof(getscriptbytecode) == "function"

KS_UTIL.hasSaveInstance =
    typeof(saveinstance) == "function"

-- =========================
-- Safe folder creation
-- =========================
function KS_UTIL.ensureFolders(path)
    if not KS_UTIL.hasFS then return end
    local cur = ""
    for seg in string.gmatch(path, "[^/]+") do
        cur = (cur == "") and seg or (cur .. "/" .. seg)
        if not isfolder(cur) then
            makefolder(cur)
        end
    end
end

-- =========================
-- Safe file write
-- =========================
function KS_UTIL.writeFile(path, contents)
    if not KS_UTIL.hasFS then return end
    pcall(writefile, path, contents)
end

-- =========================
-- SAFE decompiler
-- =========================
function KS_UTIL.getScriptSource(inst)
    if not inst or not inst:IsA("LuaSourceContainer") then
        return "-- invalid script"
    end

    if typeof(decompile) == "function" then
        local ok, res = pcall(decompile, inst)
        if ok and type(res) == "string" then
            return res
        end
    end

    if typeof(getscriptbytecode) == "function" then
        local ok, res = pcall(getscriptbytecode, inst)
        if ok then
            return "-- bytecode dump (no decompiler supported)"
        end
    end

    local ok, src = pcall(function()
        return inst.Source
    end)
    if ok then
        return src
    end

    return "-- decompiler not supported in this executor"
end

-- =========================
-- Safe apply script
-- =========================
function KS_UTIL.applyScriptSource(inst, src)
    if inst and inst:IsA("LuaSourceContainer") then
        pcall(function()
            inst.Source = src
        end)
    end
end

-- =========================
-- Safe export script
-- =========================
function KS_UTIL.exportScript(inst)
    if not KS_UTIL.hasFS then return end
    if not inst or not inst:IsA("LuaSourceContainer") then return end

    local folder = "KoroneExports/Scripts"
    KS_UTIL.ensureFolders(folder)

    local src = KS_UTIL.getScriptSource(inst)
    local safeName = inst.Name:gsub("[^%w_]+", "_")
    local path = folder .. "/" .. safeName .. ".lua"

    KS_UTIL.writeFile(path, src)
end

-- =========================
-- Safe SaveInstance
-- =========================
function KS_UTIL.saveGame()
    if KS_UTIL.hasSaveInstance then
        pcall(function()
            saveinstance()
        end)
    end
end

-- =========================
-- Safe Instance Decomposer
-- =========================
local function decompose(inst, depth)
    depth = depth or 0
    if depth > 5 then return { Name = inst.Name } end

    local t = {
        Name = inst.Name,
        ClassName = inst.ClassName,
        Children = {}
    }

    for _, child in ipairs(inst:GetChildren()) do
        table.insert(t.Children, decompose(child, depth + 1))
    end

    return t
end

function KS_UTIL.exportInstance(inst)
    if not KS_UTIL.hasFS then return end
    if not inst then return end

    local folder = "KoroneExports/Instances"
    KS_UTIL.ensureFolders(folder)

    local data = decompose(inst)
    local json = HttpService:JSONEncode(data)
    local path = folder .. "/" .. inst.Name .. ".json"

    KS_UTIL.writeFile(path, json)
end

_G.KS_UTIL = KS_UTIL
