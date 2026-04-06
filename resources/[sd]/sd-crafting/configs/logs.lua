--[[
    ============================================
    SD-CRAFTING LOGGING CONFIGURATION
    ============================================

    This file configures the logging system for SD-Crafting.
    You can customize every aspect of how logs appear.

    AVAILABLE PLACEHOLDERS FOR MESSAGES:
    ------------------------------------
    Player Info:
        {player}        - Player name with ID, e.g. "OOpium (ID: 272)"
        {playerName}    - Just the player name
        {playerId}      - Just the server ID
        {identifier}    - Player identifier (citizenid/license)
        {charName}      - Character name (firstname lastname)

    Crafting Info:
        {station}       - Station ID/name
        {stationLabel}  - Station display label
        {recipe}        - Recipe ID
        {recipeLabel}   - Recipe display label
        {item}          - Item name/label
        {quantity}      - Number of times recipe was crafted
        {outputAmount}  - Items produced per craft
        {itemList}      - Formatted list of items given
        {materials}     - Formatted list of materials used/refunded

    Shop Info:
        {shopItem}      - Shop item name
        {cost}          - Cost of purchase/action
        {balance}       - Remaining balance after purchase
        {payType}       - Payment type (cash, bank, society)

    Blueprint Info:
        {blueprint}     - Blueprint name
        {durability}    - Durability value

    Tech Tree Info:
        {node}          - Tech tree node name
        {tree}          - Tech tree name
        {xpRefunded}    - XP refunded on reset

    XP Info:
        {amount}        - XP amount gained
        {source}        - Source of XP gain
        {totalXp}       - Total XP after gain
        {level}         - Current level

    Error Info:
        {errorType}     - Type of error
        {details}       - Error details
        {reason}        - Reason for failure

    DISCORD EMBED COLORS (Decimal format):
    --------------------------------------
        Red:        16711680    (0xFF0000)
        Green:      65280       (0x00FF00)
        Blue:       255         (0x0000FF)
        Yellow:     16776960    (0xFFFF00)
        Orange:     16744448    (0xFF8000)
        Purple:     10494192    (0xA020F0)
        Cyan:       65535       (0x00FFFF)
        Pink:       16761035    (0xFFB6C1)
        Gold:       16766720    (0xFFD700)
        Gray:       9807270     (0x959595)
        Dark Gray:  5592405     (0x555555)
        White:      16777215    (0xFFFFFF)

        -- SD-Crafting Theme Colors --
        Success:    5763719     (0x57F287) - Green
        Error:      15548997    (0xED4245) - Red
        Warning:    16776960    (0xFFFF00) - Yellow
        Info:       5793266     (0x5865F2) - Blurple
        Neutral:    9807270     (0x959595) - Gray
]]

return {
    logs = {
        -- ============================================
        -- SERVICE CONFIGURATION
        -- ============================================

        --[[
            Available services:
            - 'discord'     : Send logs to Discord via webhook
            - 'fivemanage'  : Send logs to Fivemanage dashboard
            - 'fivemerr'    : Send logs to Fivemerr (fm-logs)
            - 'loki'        : Send logs to Loki/Prometheus stack
            - 'grafana'     : Send logs to Grafana Cloud
            - 'none'        : Disable all logging
        ]]
        service = 'none',

        -- Include screenshots with logs (Fivemanage/Fivemerr only)
        screenshots = false,

        -- ============================================
        -- DISCORD CONFIGURATION
        -- ============================================
        -- Only used when service = 'discord'

        discord = {
            -- REQUIRED: Your Discord webhook URL
            webhook = '',

            -- Bot display name in Discord
            botName = 'Crafting Logger',

            -- Bot avatar image URL (leave empty for default)
            botAvatar = '',

            -- Footer text shown on all embeds
            footerText = 'SD-Crafting Logging',

            -- Footer icon URL (leave empty for none)
            footerIcon = '',

            -- How often to send batched logs (in seconds)
            -- Lower = more real-time, Higher = less Discord API calls
            flushInterval = 5,

            -- Tag @everyone for critical events?
            -- Events tagged: error_occurred
            tagEveryone = false,
        },

        -- ============================================
        -- FIVEMANAGE CONFIGURATION
        -- ============================================
        -- Only used when service = 'fivemanage'

        fivemanage = {
            -- Dataset ID for organizing logs
            dataset = 'sd-crafting',
        },

        -- ============================================
        -- LOKI CONFIGURATION
        -- ============================================
        -- Only used when service = 'loki'

        loki = {
            -- Loki push endpoint (without trailing slash)
            -- Example: 'https://loki.example.com'
            endpoint = '',

            -- Basic auth credentials (optional)
            user     = '',
            password = '',

            -- X-Scope-OrgID header for multi-tenancy (optional)
            tenant   = '',

            -- Server name label for filtering logs
            server   = '',
        },

        -- ============================================
        -- GRAFANA CLOUD CONFIGURATION
        -- ============================================
        -- Only used when service = 'grafana'

        grafana = {
            -- Grafana Cloud Logs endpoint (without trailing slash)
            -- Example: 'https://logs-prod-us-central1.grafana.net'
            endpoint = '',

            -- Your Grafana Cloud API key
            apiKey   = '',

            -- X-Scope-OrgID header (optional)
            tenant   = '',

            -- Server name label for filtering logs
            server   = '',
        },

        -- ============================================
        -- EVENT CONFIGURATIONS
        -- ============================================
        --[[
            Each event can have:
            - enabled       : true/false - Whether to log this event
            - title         : The title (supports emojis)
            - description   : The main message (supports placeholders)
            - color         : Embed color in decimal format (DISCORD ONLY)
            - fields        : Array of field definitions for structured data

            Field definition:
            {
                name   = "Field Label",     -- The bold label
                value  = "{placeholder}",   -- Value with placeholders
                inline = true/false         -- Display inline (DISCORD ONLY)
            }

            =============================================
            HOW LOGS APPEAR ON DIFFERENT SERVICES:
            =============================================

            DISCORD:
            - Full rich embed with title, description, color, and inline fields
            - Example:
              ┌─────────────────────────────────────┐
              │ 🔨 Crafting Completed               │ <- title
              │ Player has crafted an item          │ <- description
              │                                     │
              │ Player: OOpium    Identifier: abc   │ <- inline fields
              │ Items: Pistol x1, Bandage x5        │ <- non-inline field
              └─────────────────────────────────────┘

            FIVEMANAGE / FIVEMERR / LOKI / GRAFANA:
            - Converted to plain text format
            - Title is used as the log title/label
            - Description + fields become the message body
            - 'color' and 'inline' are IGNORED
            - Example:
              [Title: 🔨 Crafting Completed]
              Player has crafted an item.

              Player: OOpium (ID: 272)
              Identifier: license:abc123
              Item Count: 5 items
              Items: Pistol x1, Bandage x5, Water x3

            WHAT EACH PROPERTY DOES:
            -------------------------
            enabled     - ALL SERVICES  - Toggles the event on/off
            title       - ALL SERVICES  - Log title/header
            description - ALL SERVICES  - Main message body
            color       - DISCORD ONLY  - Embed sidebar color
            fields      - ALL SERVICES  - Structured data (name: value pairs)
            inline      - DISCORD ONLY  - Whether fields appear side-by-side
        ]]

        events = {
            -- ============================================
            -- CRAFTING EVENTS
            -- ============================================

            craft_started = {
                enabled = true,
                title = "🔨 Crafting Started",
                description = "A player has started crafting an item.",
                color = 5793266, -- Blurple
                fields = {
                    { name = "Player",          value = "{player}",       inline = true },
                    { name = "Identifier",      value = "{identifier}",   inline = true },
                    { name = "Character",       value = "{charName}",     inline = true },
                    { name = "Station",         value = "{stationLabel}", inline = true },
                    { name = "Recipe",          value = "{recipeLabel}",  inline = true },
                    { name = "Quantity",        value = "{quantity}",     inline = true },
                    { name = "Output/Craft",    value = "{outputAmount}", inline = true },
                    { name = "Materials Taken", value = "{materials}",    inline = false },
                },
            },

            craft_completed = {
                enabled = true,
                title = "✅ Crafting Completed",
                description = "A player has successfully crafted an item.",
                color = 5763719, -- Green
                fields = {
                    { name = "Player",        value = "{player}",       inline = true },
                    { name = "Identifier",    value = "{identifier}",   inline = true },
                    { name = "Character",     value = "{charName}",     inline = true },
                    { name = "Station",       value = "{stationLabel}", inline = true },
                    { name = "Recipe",        value = "{recipeLabel}",  inline = true },
                    { name = "Quantity",      value = "{quantity}",     inline = true },
                    { name = "Output/Craft",  value = "{outputAmount}", inline = true },
                    { name = "Items Given",   value = "{itemList}",     inline = false },
                    { name = "Materials Used", value = "{materials}",   inline = false },
                },
            },

            craft_failed = {
                enabled = true,
                title = "❌ Crafting Failed",
                description = "A player's crafting attempt has failed.",
                color = 15548997, -- Red
                fields = {
                    { name = "Player",     value = "{player}",       inline = true },
                    { name = "Identifier", value = "{identifier}",   inline = true },
                    { name = "Station",    value = "{stationLabel}", inline = true },
                    { name = "Recipe",     value = "{recipeLabel}",  inline = true },
                    { name = "Reason",     value = "{reason}",       inline = false },
                },
            },

            craft_cancelled = {
                enabled = true,
                title = "🚫 Crafting Cancelled",
                description = "A player has cancelled their crafting.",
                color = 16744448, -- Orange
                fields = {
                    { name = "Player",             value = "{player}",       inline = true },
                    { name = "Identifier",         value = "{identifier}",   inline = true },
                    { name = "Character",          value = "{charName}",     inline = true },
                    { name = "Station",            value = "{stationLabel}", inline = true },
                    { name = "Recipe",             value = "{recipeLabel}",  inline = true },
                    { name = "Quantity",           value = "{quantity}",     inline = true },
                    { name = "Output/Craft",       value = "{outputAmount}", inline = true },
                    { name = "Materials Refunded", value = "{materials}",    inline = false },
                },
            },

            -- ============================================
            -- STATION EVENTS
            -- ============================================

            station_opened = {
                enabled = true,
                title = "📂 Station Opened",
                description = "A player has opened a crafting station.",
                color = 5793266, -- Blurple
                fields = {
                    { name = "Player",     value = "{player}",       inline = true },
                    { name = "Identifier", value = "{identifier}",   inline = true },
                    { name = "Station",    value = "{stationLabel}", inline = true },
                },
            },

            station_closed = {
                enabled = true,
                title = "📁 Station Closed",
                description = "A player has closed a crafting station.",
                color = 9807270, -- Gray
                fields = {
                    { name = "Player",     value = "{player}",       inline = true },
                    { name = "Identifier", value = "{identifier}",   inline = true },
                    { name = "Station",    value = "{stationLabel}", inline = true },
                },
            },

            -- ============================================
            -- SHOP EVENTS
            -- ============================================

            shop_purchase = {
                enabled = true,
                title = "🛒 Shop Purchase",
                description = "A player has purchased an item from the shop.",
                color = 5763719, -- Green
                fields = {
                    { name = "Player",     value = "{player}",     inline = true },
                    { name = "Identifier", value = "{identifier}", inline = true },
                    { name = "Character",  value = "{charName}",   inline = true },
                    { name = "Item",       value = "{shopItem}",   inline = true },
                    { name = "Quantity",   value = "{quantity}",   inline = true },
                    { name = "Cost",       value = "${cost}",      inline = true },
                    { name = "Payment",    value = "{payType}",    inline = true },
                    { name = "Balance",    value = "${balance}",   inline = true },
                },
            },

            shop_purchase_failed = {
                enabled = true,
                title = "❌ Shop Purchase Failed",
                description = "A player's shop purchase has failed.",
                color = 15548997, -- Red
                fields = {
                    { name = "Player",     value = "{player}",     inline = true },
                    { name = "Identifier", value = "{identifier}", inline = true },
                    { name = "Item",       value = "{shopItem}",   inline = true },
                    { name = "Reason",     value = "{reason}",     inline = false },
                },
            },

            -- ============================================
            -- BLUEPRINT EVENTS
            -- ============================================

            blueprint_used = {
                enabled = true,
                title = "📜 Blueprint Used",
                description = "A player has used a blueprint for crafting.",
                color = 10494192, -- Purple
                fields = {
                    { name = "Player",     value = "{player}",      inline = true },
                    { name = "Identifier", value = "{identifier}",  inline = true },
                    { name = "Blueprint",  value = "{blueprint}",   inline = true },
                    { name = "Recipe",     value = "{recipeLabel}", inline = true },
                    { name = "Durability", value = "{durability}",  inline = true },
                },
            },

            blueprint_broken = {
                enabled = true,
                title = "💔 Blueprint Broken",
                description = "A player's blueprint has broken from use.",
                color = 15548997, -- Red
                fields = {
                    { name = "Player",     value = "{player}",      inline = true },
                    { name = "Identifier", value = "{identifier}",  inline = true },
                    { name = "Blueprint",  value = "{blueprint}",   inline = true },
                    { name = "Recipe",     value = "{recipeLabel}", inline = true },
                },
            },

            -- ============================================
            -- TECHTREE EVENTS
            -- ============================================

            techtree_unlocked = {
                enabled = true,
                title = "🔓 Tech Tree Unlocked",
                description = "A player has unlocked a new tech tree node.",
                color = 16766720, -- Gold
                fields = {
                    { name = "Player",        value = "{player}",        inline = true },
                    { name = "Identifier",    value = "{identifier}",    inline = true },
                    { name = "Character",     value = "{charName}",      inline = true },
                    { name = "Station",       value = "{stationLabel}",  inline = true },
                    { name = "Workbench Type", value = "{workbenchType}", inline = true },
                    { name = "Node",          value = "{node}",          inline = true },
                    { name = "Tree",          value = "{tree}",          inline = true },
                    { name = "Cost",          value = "{cost} XP",       inline = true },
                },
            },

            -- ============================================
            -- XP EVENTS
            -- ============================================

            xp_gained = {
                enabled = true,
                title = "⭐ XP Gained",
                description = "A player has gained crafting XP.",
                color = 5763719, -- Green
                fields = {
                    { name = "Player",     value = "{player}",     inline = true },
                    { name = "Identifier", value = "{identifier}", inline = true },
                    { name = "Amount",     value = "+{amount} XP", inline = true },
                    { name = "Source",     value = "{source}",     inline = true },
                    { name = "Total XP",   value = "{totalXp}",    inline = true },
                },
            },

            level_up = {
                enabled = true,
                title = "🎉 Level Up!",
                description = "A player has leveled up their crafting skill.",
                color = 16766720, -- Gold
                fields = {
                    { name = "Player",     value = "{player}",      inline = true },
                    { name = "Identifier", value = "{identifier}",  inline = true },
                    { name = "Character",  value = "{charName}",    inline = true },
                    { name = "New Level",  value = "Level {level}", inline = true },
                    { name = "Total XP",   value = "{totalXp}",     inline = true },
                },
            },

            -- ============================================
            -- ERROR EVENTS
            -- ============================================

            error_occurred = {
                enabled = true,
                title = "❌ Error Occurred",
                description = "An error has occurred in the crafting system.",
                color = 15548997, -- Red
                fields = {
                    { name = "Error Type", value = "{errorType}", inline = true },
                    { name = "Details",    value = "{details}",   inline = false },
                    { name = "Player",     value = "{player}",    inline = true },
                },
            },
        },
    },
}
