--[[
    Korone Studio Tools (2026 Multi-File Edition)
    Inspired by Dex by Moon. Credit to Moon for the original Dex concept + UX.

    Folder layout (place entire "KoroneStudio" folder in your executor workspace):
      • main.lua         – bootstrap
      • KS_Util.lua      – filesystem helpers, decompiler, saveinstance
      • Editor.lua       – script + properties editor
      • Explorer.lua     – instance tree
      • RSpy.lua         – remote spy
      • SecretPanel.lua  – executor + console
      • ModelViewer.lua  – simple 3D viewer
      • Hub.lua          – emoji hub
--]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[KoroneStudio]", res)
    end
    return ok, res
end

_G.KS_Shared = {
    Players          = Players,
    RunService       = RunService,
    UserInputService = UserInputService,
    CoreGui          = CoreGui,
    HttpService      = HttpService,
    LocalPlayer      = Players.LocalPlayer or Players.PlayerAdded:Wait(),
    safe             = safe,
}

local function include(relPath)
    local folder   = "KoroneStudio"
    local fullPath = folder .. "/" .. relPath
    if not readfile then
        error("Filesystem not available; use a single-file build instead.")
    end
    local src = readfile(fullPath)
    if not src then
        error("Missing KoroneStudio file: " .. fullPath)
    end
    local fn, err = loadstring(src, "=" .. relPath)
    if not fn then
        error("Failed to load " .. relPath .. ": " .. tostring(err))
    end
    fn()
end

include("KS_Util.lua")
include("Editor.lua")
include("Explorer.lua")
include("RSpy.lua")
include("SecretPanel.lua")
include("ModelViewer.lua")
include("Hub.lua")

print("[KoroneStudio] Multi-file build loaded. Use the 🌙 Korone Studio hub on the left.")
