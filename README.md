# Example Usage:

- This operates like a server, You can execute stuff on others client and etc.

```lua
if not shared.__API_Connected then -- // You dont have to but ok.
    local CommandManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/FlamesW/CommandManager/refs/heads/home/Module.luau"))();

    getgenv().API = CommandManager:Init({
        WebSocketUrl = "Websocket_Url", -- // Your Websocket here (I recommend using railway app)
        CommandPrefix = "!",
        ClientRun = true, -- // Fallback to run on client just for tests and etc...
        -- ["SupremeRank"] = "God", -- // The name is "Owner" by default.
        ["Ranks"] = {
            ["Owner"] = {"0x0x0x0x0x0"}, -- // Script owner puts their hwid here.
            ["Moderator"] = {"0987654321", "325235"},
            ["VIP"] = {"some_hwid_string"},
        }
    }) 

    API = getgenv().API

    API:AddCommand("test", function(Player, args)
        -- // Your code here~
        return "Test successful!"; -- // Sends back to the console only supreme ranked can see
    end, "Owner", "Moderator") -- // VIP wont be able to use this command since we flagged these two ranks

    API:AddCommand("ping", function(Player, args)
        print("pong!");
    end, nil) -- // Anyone can use this

    API:SendCommand("!help"); -- // Built in command Open f9.
else
    warn("Command Manager is already connected");
end
```

- Only supreme ranked can see logs being sent to console plus connected and disconnected users alongside other commands

### Built in commands

```lua 
API:SendCommand("!help");
```

```lua 
API:SendCommand("!players");
```

```lua 
API:SendCommand("!shutdown");
```

#### Build these however you like :)~
