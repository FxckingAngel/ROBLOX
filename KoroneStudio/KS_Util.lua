-- Korone Studio Util (FS, decomposer, decompiler, saveinstance)
local shared      = _G.KS_Shared or error("KS_Shared missing")
local HttpService = shared.HttpService

local KS_UTIL = {}

function KS_UTIL.canFS()
    return typeof(writefile) == "function" and typeof(readfile) == "function"
end

function KS_UTIL.ensureFolders(path)
    if not KS_UTIL.canFS() then return end
    if typeof(makefolder) ~= "function" or typeof(isfolder) ~= "function" then return end
    if not path or path == "" then return end

    local cur = ""
    for seg in string.gmatch(path, "[^/]+") do
        if cur == "" then
            cur = seg
        else
            cur = cur .. "/" .. seg
        end
        if not isfolder(cur) then
            makefolder(cur)
        end
    end
end

function KS_UTIL.writeFile(path, contents)
    if not KS_UTIL.canFS() then
        error("Filesystem not supported in this executor.")
    end
    local ok, err = pcall(writefile, path, contents)
    if not ok then
        error("Failed to write file '" .. path .. "': " .. tostring(err))
    end
end

-- Decomposer
local function decomposeInstance(inst, depth, maxDepth)
    depth    = depth or 0
    maxDepth = maxDepth or 6

    if depth > maxDepth then
        return {
            __truncated = true,
            Name        = inst.Name,
            ClassName   = inst.ClassName,
        }
    end

    local info = {
        Name       = inst.Name,
        ClassName  = inst.ClassName,
        Properties = {},
        Children   = {},
    }

    local function prop(p)
        local ok, v = pcall(function() return inst[p] end)
        if ok then
            info.Properties[p] = v
        end
    end

    for _, p in ipairs({
        "Name","ClassName","Parent","Archivable",
        "Transparency","Anchored","CanCollide",
        "Size","Position","CFrame",
        "Text","Value","BrickColor","Color",
        "BackgroundColor3","TextColor3",
        "Enabled","Visible","Active"
    }) do
        prop(p)
    end

    for _, child in ipairs(inst:GetChildren()) do
        table.insert(info.Children, decomposeInstance(child, depth + 1, maxDepth))
    end

    return info
end

function KS_UTIL.decompose(root, maxDepth)
    maxDepth = maxDepth or 6
    if typeof(root) == "string" then
        local current = game
        for token in string.gmatch(root, "[^%.]+") do
            local child = current:FindFirstChild(token)
            if not child then
                error("Cannot resolve '"..token.."' from "..current:GetFullName())
            end
            current = child
        end
        root = current
    end
    if typeof(root) ~= "Instance" then
        error("decompose expects Instance or path string")
    end
    local tree = decomposeInstance(root, 0, maxDepth)
    print("[KoroneStudio] Decomposed:", root:GetFullName())
    return tree
end

function KS_UTIL.exportInstance(root, opts)
    opts           = opts or {}
    local folder   = opts.folder or ("KoroneExports/"..tostring(game.PlaceId))
    local name     = opts.name   or root.Name
    local maxDepth = opts.maxDepth or 6

    KS_UTIL.ensureFolders(folder)
    local tree = KS_UTIL.decompose(root, maxDepth)
    local json = HttpService:JSONEncode(tree)
    local path = folder .. "/" .. name .. ".json"
    KS_UTIL.writeFile(path, json)
    print("[KoroneStudio] Exported instance to:", path)
    return path
end

-- Decompiler (script -> readable Lua or bytecode dump)
local function tryDecompile(inst)
    if typeof(decompile) == "function" then
        local ok, src = pcall(decompile, inst)
        if ok and typeof(src) == "string" and src:match("%S") then
            return src
        end
    end

    if inst:IsA("LuaSourceContainer") then
        local ok, src = pcall(function() return inst.Source end)
        if ok and typeof(src) == "string" then
            return src
        end
    end

    if typeof(getscriptbytecode) == "function" then
        local ok, bc = pcall(getscriptbytecode, inst)
        if ok and typeof(bc) == "string" then
            return ("--[[\nBytecode for %s\nLength: %d bytes\nUse an offline decompiler.\n--]]\n\nreturn %q")
                :format(inst:GetFullName(), #bc, bc)
        end
    end

    return "-- failed to get source for "..inst:GetFullName()
end

function KS_UTIL.getScriptSource(inst)
    if not inst or not inst:IsA("LuaSourceContainer") then
        error("getScriptSource expects Script/LocalScript/ModuleScript")
    end
    return tryDecompile(inst)
end

function KS_UTIL.applyScriptSource(inst, src)
    if not inst or not inst:IsA("LuaSourceContainer") then
        error("applyScriptSource expects Script/LocalScript/ModuleScript")
    end
    local ok, err = pcall(function() inst.Source = src end)
    if not ok then
        error("Failed to apply script source: " .. tostring(err))
    end
end

function KS_UTIL.exportScript(inst, folder)
    folder = folder or ("KoroneExports/" .. tostring(game.PlaceId) .. "/Scripts")
    KS_UTIL.ensureFolders(folder)
    local src      = KS_UTIL.getScriptSource(inst)
    local safeName = inst.Name:gsub("[^%w_]+", "_")
    local path     = folder .. "/" .. safeName .. "_" .. inst.ClassName .. ".lua"
    KS_UTIL.writeFile(path, src)
    print("[KoroneStudio] Exported script to:", path)
    return path
end

-- Binary SaveInstance helper
function KS_UTIL.binarySave(opts)
    if typeof(saveinstance) ~= "function" then
        warn("[KoroneStudio] saveinstance API not available in this executor.")
        return
    end
    opts = opts or {}
    local folder  = opts.folder or "KoroneExports"
    local file    = opts.file   or ("Place_"..tostring(game.PlaceId).."_binary.rbxm")
    local fullDir = folder
    local full    = folder.."/"..file

    KS_UTIL.ensureFolders(fullDir)

    local ok, err = pcall(function()
        saveinstance({
            Mode        = "savefile",
            FileName    = full,
            Decompose   = true,
            Binary      = true,
            SavePlayers = true,
        })
    end)

    if ok then
        print("[KoroneStudio] Binary place saved to:", full)
    else
        warn("[KoroneStudio] saveinstance failed:", err)
    end
end

_G.KS_UTIL = KS_UTIL
