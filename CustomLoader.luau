repeat task.wait(0.25) until game:IsLoaded()
if workspace.DistributedGameTime < 3 then
    task.wait(3 - workspace.DistributedGameTime)
end

local Players = game:GetService("Players")
repeat task.wait(0.25) until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
-- ВПИШИ СВОЙ НИК И ИМЯ РЕПО СЮДА:
-- ═══════════════════════════════════════════════════════════
local GITHUB_USER = "abram11144"
local GITHUB_REPO = "luau"
local GITHUB_BRANCH = "main"

local SourceURL = string.format(
    "https://raw.githubusercontent.com/abram11144/luau/refs/heads/main/Main.luau",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

local function FetchMain()
    local ok, src = pcall(game.HttpGet, game, SourceURL)
    if ok and type(src) == "string" and #src > 100 then return src end
    return nil
end

local Source = FetchMain()
if not Source then
    return LocalPlayer:Kick("Cannot fetch Main.luau from GitHub.\n" .. SourceURL)
end

for Reason, Missing in {["getgenv"] = not getgenv} do
    if Missing then return LocalPlayer:Kick("Exploit not supported: " .. Reason) end
end

local Getgc, Getfflag, Setfflag = getgc or get_gc, getfflag or get_fflag, setfflag or set_fflag
if not (Getgc and Getfflag and Setfflag) then
    return LocalPlayer:Kick("Exploit missing getgc/getfflag/setfflag")
end

local ok, Dbg = pcall(Getfflag, "DebugRunParallelLuaOnMainThread")
if not ok then
    return LocalPlayer:Kick("getfflag error")
end

if string.lower(tostring(Dbg)) == "true" then
    return loadstring(Source)()
end

pcall(Setfflag, "DebugRunParallelLuaOnMainThread", "True")

local Queue = queueonteleport or queue_on_teleport
if Queue then
    pcall(Queue, string.format([[
        repeat task.wait(0.25) until game:IsLoaded()
        if workspace.DistributedGameTime < 3 then
            task.wait(3 - workspace.DistributedGameTime)
        end
        local Src = game:HttpGet(%q)
        if type(Src) == "string" and #Src > 100 then
            loadstring(Src)()
        end
    ]], SourceURL))
end

task.delay(0.35, function()
    local TS = game:GetService("TeleportService")
    for _ = 1, 5 do
        if pcall(TS.Teleport, TS, game.PlaceId) then return end
        task.wait(0.5)
    end
    LocalPlayer:Kick("Teleport failed. Rejoin manually.\ndiscord.gg/DsGCKtxxEN")
end)
