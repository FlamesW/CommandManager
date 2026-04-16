-- // Made by Mommy Flames
if not game:IsLoaded() then
	game.Loaded:Wait();
end

local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local API = {}
API.__index = API

-- local ___ = IB_ENCSTR("6FgAcOM@$%(#@&^%&*#@wp4R2p@(!@%%#_%_^@Y&)qa&^%&*UViorl")
local ___ = "FgAcOM@$%(#@&^%&*#@wp4R2p@(!@%%#_%_^@Y&)qa&^%&*UViorl"

-- // Services
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local UserInputService = cloneref(game:GetService("UserInputService"))
local RbxAnalytics = cloneref(game:GetService("RbxAnalyticsService"))

local WebSocket = (pcall(function() return WebSocket end) and WebSocket) or nil
local SocketBoy = nil
local ConnectedUsers = {}
local LastSeen = {}
local LastHeartbeat = 0

API.Commands = {}
API.CommandPrefix = "!"
API.UserRanks = {}
API.ClientRun = false
API.SupermeRank = "Owner"

function API:SetSupermeRank(rankName)
    self.SupermeRank = rankName
    return self
end

function API:IsSuperme()
    local hwid = RbxAnalytics:GetClientId()
    local rank = self:GetRank(LocalPlayer.UserId, hwid)
    return rank == self.SupermeRank
end

function API:SetRank(identifier, rank)
    self.UserRanks[tostring(identifier)] = rank
    return self
end

function API:GetRank(userId, hwid)
    if self.UserRanks[hwid] then
        return self.UserRanks[hwid]
    end
    if self.UserRanks[tostring(userId)] then
        return self.UserRanks[tostring(userId)]
    end
    return nil
end

function API:GetUserRank(username, userId, hwid)
    local rank = self:GetRank(userId, hwid)
    return rank or "user"
end

function API:CanUse(userId, hwid, requiredRanks)
    if not requiredRanks or #requiredRanks == 0 then
        return true
    end

    local userRank = self:GetRank(userId, hwid)
    if not userRank then return false end

    for _, required in ipairs(requiredRanks) do
        if userRank == required then
            return true
        end
    end
    return false
end

function API:AddCommand(name, func, ranks)
    if ranks and type(ranks) == "string" then
        ranks = {ranks}
    end
    
    self.Commands[name:lower()] = {
        func = func,
        ranks = ranks
    }
    return self
end

function API:RunCommand(msg, player)
    if not msg or msg:sub(1, 1) ~= self.CommandPrefix then 
        return false, "Not a command"
    end

    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local cmdName = args[1]:sub(2):lower()
    local cmd = self.Commands[cmdName]
    
    if not cmd then 
        return false, "Unknown command"
    end

    local hwid = RbxAnalytics:GetClientId()
    
    local requiredRanks = cmd.ranks
    if requiredRanks and type(requiredRanks) == "string" then
        requiredRanks = {requiredRanks}
    end
    
    if not self:CanUse(player.UserId, hwid, requiredRanks) then
        return false, "No permission"
    end

    table.remove(args, 1)
    local success, result = pcall(cmd.func, player, args)

    if not success then
        return false, "Error: " .. tostring(result)
    end

    return true, result
end

function API:RunLocalCommand(msg)
    if not msg or msg:sub(1, 1) ~= self.CommandPrefix then 
        return false, "Not a command"
    end
    
    return self:RunCommand(msg, LocalPlayer)
end

function API:SendCommand(msg)
    if SocketBoy and msg then
        SocketBoy:Send(___ .. msg)
        return true
    else
        if self.ClientRun then
            warn("WebSocket not connected, running locally instead")
            return self:RunLocalCommand(msg)
        else
            warn("WebSocket not connected and ClientRun is disabled")
            return false, "WebSocket not available"
        end
    end
end

function API:GetConnectedUsers()
    local users = {}
    for username, data in pairs(ConnectedUsers) do
        local lastData = LastSeen[username]
        local rank = self:GetRank(data.userId, data.hwid)
        table.insert(users, {
            name = username,
            rank = rank or "user",
            platform = lastData and lastData.Platform or "Unknown",
            time = lastData and lastData.time or 0
        })
    end
    return users
end

function API:GetConnectedCount()
    local count = 0
    for _ in pairs(ConnectedUsers) do count = count + 1 end
    return count
end

function API:GetConnectedList()
    local list = {}
    local i = 1
    for username, data in pairs(ConnectedUsers) do
        local lastData = LastSeen[username]
        if lastData then
            local time = os.date("%H:%M:%S", lastData.time + (3 * 3600))
            local rank = self:GetRank(data.userId, data.hwid) or "user"
            list[i] = string.format("%d. %s [%s] [%s] [%s]", i, username, rank, lastData.Platform, time)
        else
            list[i] = string.format("%d. %s", i, username)
        end
        i = i + 1
    end
    return list
end

function API:ConnectWebSocket(url)
    url = url or "wss://ws.postman-echo.com/raw"

    if not WebSocket then
        warn("WebSocket is not available")
        return false
    end

    if SocketBoy then
        return true
    end

    local success, connection = pcall(function()
        return WebSocket.connect(url)
    end)
    
    if success and connection then
        SocketBoy = connection
        self.SocketBoy = SocketBoy
        self:Setup()
        self:StartSession()
        self:TrackExits()
        shared.__API_Connected = true
        return true
    end
    return false
end

if not shared.__API_Handlers then
    shared.__API_Handlers = true

    function API:Setup()
        if not SocketBoy then return end

        SocketBoy.OnMessage:Connect(function(msg)
            pcall(function()
                if msg:sub(1, #___) ~= ___ then return end
                local Trim = msg:sub(#___ + 1)

                if Trim:sub(1, 7) == "!hello|" then
                    local username = Trim:sub(8)
                    if username ~= "" then
                        local Platform = UserInputService:GetPlatform().Name
                        local hwid = RbxAnalytics:GetClientId()
                        local player = Players:FindFirstChild(username)
                        
                        if not ConnectedUsers[username] then
                            LastSeen[username] = {
                                time = os.time(),
                                Platform = Platform,
                            }
                            ConnectedUsers[username] = {
                                userId = player and player.UserId or 0,
                                hwid = hwid,
                                lastSeen = os.time()
                            }
                            if self:IsSuperme() then
                                local rank = self:GetRank(player and player.UserId, hwid) or "user"
                                warn("[CONNECTED]", username, "| Rank:", rank, "| Platform:", Platform)
                            end
                        else
                            LastSeen[username] = {
                                time = os.time(),
                                Platform = Platform,
                            }
                            ConnectedUsers[username].lastSeen = os.time()
                        end
                    end
                    return
                end
         
                if Trim:sub(1, 1) == self.CommandPrefix then
                    for username, _ in pairs(ConnectedUsers) do
                        local player = Players:FindFirstChild(username)
                        if player then
                            local success, result = self:RunCommand(Trim, player)
                            if success and result and self:IsSuperme() then
                                warn("[CMD]", username, "→", result)
                            end
                        end
                        break
                    end
                    return
                end
            end)
        end)
    end
end

function API:StartSession()
    task.spawn(function()
        while SocketBoy do
            pcall(function()
                if SocketBoy then
                    SocketBoy:Send(___ .. "!hello|" .. LocalPlayer.Name)
                    LastHeartbeat = os.time()
                end
            end)
            task.wait(15)
        end
    end)
end

function API:TrackExits()
    task.spawn(function()
        while SocketBoy do
            task.wait(15)
            local now = os.time()
            local toRemove = {}
            
            for name, data in pairs(ConnectedUsers) do
                local lastData = LastSeen[name]
                if lastData and now - lastData.time > 45 then
                    table.insert(toRemove, name)
                end
            end
            
            for _, name in ipairs(toRemove) do
                ConnectedUsers[name] = nil
                LastSeen[name] = nil
                if self:IsSuperme() then
                    warn("[DISCONNECTED]", name)
                end
            end
        end
    end)
end

function API:Init(config)
    config = config or {}
    
    if config.CommandPrefix then
        self.CommandPrefix = config.CommandPrefix
    end
    
    if config.SupermeRank then
        self:SetSupermeRank(config.SupermeRank)
    end
    
    if config.ClientRun ~= nil then
        self.ClientRun = config.ClientRun
    end
    
    if config.Ranks then
        local firstKey = next(config.Ranks)
        local Formatted = firstKey and type(config.Ranks[firstKey]) == "table"
        
        if Formatted then
            for rankName, users in pairs(config.Ranks) do
                if type(users) == "table" then
                    for _, identifier in ipairs(users) do
                        self:SetRank(identifier, rankName)
                    end
                else
                    self:SetRank(users, rankName)
                end
            end
        else
            for identifier, rank in pairs(config.Ranks) do
                self:SetRank(identifier, rank)
            end
        end
    end

    self:ConnectWebSocket(config.WebSocketUrl)

    -- // Prebuilt in commands
    if not self.Commands["help"] then
        self:AddCommand("help", function(player, args)
            local cmds = {}
            for name, cmd in pairs(self.Commands) do
                if cmd.ranks and #cmd.ranks > 0 then
                    table.insert(cmds, self.CommandPrefix .. name .. " [" .. table.concat(cmd.ranks, "/") .. "]")
                else
                    table.insert(cmds, self.CommandPrefix .. name)
                end
            end
            table.sort(cmds)
            print("Commands: " .. table.concat(cmds, ", "))
        end, nil)
    end

    if not self.Commands["players"] then
        self:AddCommand("players", function(player, args)
            local count = self:GetConnectedCount()
            local list = self:GetConnectedList()
            
            print("Connected Users: " .. count)
            for _, line in ipairs(list) do
                warn(line)
            end
        end, self.SupermeRank)
    end

    if not self.Commands["shutdown"] then
        self:AddCommand("shutdown", function(player, args)
            task.spawn(function()
                task.wait(1)
                game:Shutdown()
            end)
            return "Shutting down..."
        end, self.SupermeRank)
    end

    return self
end

return API
