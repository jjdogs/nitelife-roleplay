local resourceName = GetCurrentResourceName()

Config = {}

-- I don't know if I need to clarify this but you CAN'T use the 3 configs at the same time -.-
-- DON'T try to register multiple apps using the same resource
-- DON'T try to register your app using any of the laptop resources (av_laptop or any other APP)

Config.App = { -- This config will open an app built with React and the UI folder template
    name = "tow_app", -- You can modify this just make sure don't use duplicated app names
    label = "Tow App", -- You can modify this
    resource = resourceName, -- don't modify this
    icon = resourceName..'/icon.png', -- don't modify this?
    isEnabled = function(serial)
        print(serial)
        -- this check runs when the player opens the laptop, return true/false to enable/disable app
        return true
    end
}

--[[

Config.App = { -- This config will open a website, you don't need the UI folder at all
    name = "template", -- You can modify this just make sure don't use duplicated app names
    label = "App Template", -- You can modify this
    resource = resourceName, -- don't modify this
    icon = resourceName..'/icon.png', -- don't modify this?
    website = "https://uwucatcafe.com/", -- custom website
    isEnabled = function(serial)
        -- this check runs when the player opens the laptop, return true/false to enable/disable app
        return true
    end
}


]]--

-- Config.App = { -- This config will trigger a NUIEvent (check client/nui/example)
--     name = "template", -- You can modify this just make sure don't use duplicated app names
--     label = "App Template", -- You can modify this
--     resource = resourceName, -- don't modify this
--     icon = resourceName..'/icon.png', -- don't modify this?
--     event = "doSomething", -- trigger a nui event
--     isEnabled = function(serial)
--         -- this check runs when the player opens the laptop, return true/false to enable/disable app
--         return true
--     end
-- }
