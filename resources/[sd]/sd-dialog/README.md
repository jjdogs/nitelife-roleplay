# sd-dialog

> A cinematic dialog system for FiveM featuring smooth camera transitions, interactive option menus, and seamless target integration.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ab1344b5-2afc-43dd-8028-6dd5d2a30c97" />

https://github.com/user-attachments/assets/ac3735bd-e801-4293-900b-8856b9646cd8

![GitHub release](https://img.shields.io/github/v/release/Samuels-Development/sd-dialog?label=Release&logo=github)
[![Discord](https://img.shields.io/discord/842045164951437383?label=Discord&logo=discord&logoColor=white)](https://discord.gg/FzPehMQaBQ)

## 📋 Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- Target resource (ox_target, qb-target, or qtarget)

## 🎯 Features

- **Cinematic Camera** - Smooth camera transitions focusing on the NPC during conversations
- **Interactive UI** - Modern, clean interface with icons, descriptions, and sub-menus
- **Target Integration** - Automatic bridge support for ox_target, qb-target, and qtarget
- **Conditional Options** - Lock options behind conditions using `canInteract`
- **Multiple Action Types** - Direct functions, client events, and server events
- **Config-Based Setup** - Define entities and models directly in config.lua

---

## 📦 Installation

1. [Download the latest release](https://github.com/Samuels-Development/sd-dialog/releases/latest) (ZIP, NOT SOURCE)
2. Ensure `ox_lib` is started before `sd-dialog`
3. Add `sd-dialog` to your resources folder
4. Add `ensure sd-dialog` to your server.cfg

---

## 🛠️ Configuration

You can define dialog NPCs directly in `config.lua` without writing any additional code:

```lua
-- config.lua
return {
    -- Global setting: options shown per page (default: 3)
    itemsPerPage = 3,

    -- Spawned NPCs with dialog
    entities = {
        {
            model = 'csb_mweather',
            coords = vector4(195.17, -933.77, 29.69, 144.04),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            spawnDistance = 50.0,
            invincible = true,
            freeze = true,

            dialog = {
                targetIcon = 'fas fa-comments',
                targetLabel = 'Talk to Marcus',
                targetDistance = 2.5,

                name = 'Marcus Webb',
                role = 'FIXER',
                roleColor = '#f59e0b',
                description = "You look like someone who gets things done.",
                options = { ... },
            },
        },
    },

    -- Dialog for existing world peds by model
    models = {
        {
            model = 'cs_bankman',
            dialog = {
                name = 'Bank Teller',
                description = "Welcome to the bank.",
                options = { ... },
            },
        },
    },
}
```

### Entity Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | - | Ped model name |
| `coords` | vector4 | - | Position and heading |
| `scenario` | string | nil | Scenario to play |
| `anim` | table | nil | Animation to play (see below) |
| `spawnDistance` | number | 50.0 | Distance to spawn ped |
| `despawnDistance` | number | spawnDistance + 10 | Distance to despawn ped |
| `invincible` | boolean | true | Make ped invincible |
| `freeze` | boolean | true | Freeze ped position |
| `dialog` | table | - | Dialog configuration |

### Animation Table

```lua
anim = {
    dict = 'anim_dict',
    name = 'anim_name',
    blendIn = 8.0,
    blendOut = -8.0,
    duration = -1,
    flag = 1,
    playbackRate = 0.0,
}
```

---

## 📤 Exports

### Open

Opens a dialog directly. Use this when you want to integrate sd-dialog into an existing target interaction, command, event, or any other trigger you already have set up.

For example, if you already have a blackmarket ped with an `ox_target` registration, you can call this export inside the `onSelect` to open the dialog instead of creating a separate target.

```lua
exports['sd-dialog']:Open(data, callback?)
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | table | Dialog configuration |
| `callback` | function? | Optional callback when any option is selected |

#### Data Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `entity` | number | nil | Entity to focus camera on |
| `name` | string | 'Unknown' | NPC name displayed in header |
| `role` | string | nil | Role/title badge text |
| `roleColor` | string | '#ec4899' | Role badge color (hex) |
| `description` | string | '' | Main dialog text |
| `options` | table | {} | Array of dialog options |
| `itemsPerPage` | number | 3 | Options shown per page |
| `transitionTime` | number | 1000 | Camera transition time (ms) |

#### Example: Integrating with existing ox_target

```lua
-- You already have a ped spawned and a target registered...
exports.ox_target:addLocalEntity(myPed, {
    {
        name = 'blackmarket_talk',
        icon = 'fas fa-comments',
        label = 'Talk',
        onSelect = function(data)
            -- Open sd-dialog when the target is selected
            exports['sd-dialog']:Open({
                entity = data.entity,
                name = 'Shadow',
                role = 'BLACK MARKET',
                roleColor = '#ef4444',
                description = "You didn't see me, and I didn't see you. What do you need?",
                options = {
                    {
                        id = 'weapons',
                        label = 'Browse Weapons',
                        icon = 'swords',
                        description = 'See what hardware is available.',
                        clientEvent = 'blackmarket:openWeapons',
                    },
                    {
                        id = 'ammo',
                        label = 'Buy Ammo',
                        icon = 'package',
                        description = 'Stock up on ammunition.',
                        clientEvent = 'blackmarket:openAmmo',
                    },
                    {
                        id = 'sell',
                        label = 'Sell Goods',
                        icon = 'hand-coins',
                        description = 'Offload some hot merchandise.',
                        serverEvent = 'blackmarket:sellGoods',
                    },
                },
            })
        end,
    },
})
```

#### Example: Standalone Usage

```lua
-- myPed = your spawned ped entity handle
exports['sd-dialog']:Open({
    entity = myPed, -- Optional: camera will focus on this entity
    name = 'John Doe',
    role = 'MERCHANT',
    roleColor = '#10b981',
    description = "Welcome! What can I do for you?",
    options = {
        {
            id = 'buy',
            label = 'Buy Items',
            icon = 'shopping-cart',
            description = 'Browse available items.',
            clientEvent = { 'shop:openBuyMenu', 'weapons' },
        },
        {
            id = 'sell',
            label = 'Sell Items',
            icon = 'hand-coins',
            description = 'Sell your items for cash.',
            serverEvent = 'shop:openSellMenu',
        },
    },
}, function(optionId, dialogData) -- Optional callback, triggered when any option is selected
    print('Player selected:', optionId)
end)
```

---

### Close

Closes the currently open dialog.

```lua
exports['sd-dialog']:Close()
```

---

### IsOpen

Returns whether a dialog is currently open.

```lua
local isOpen = exports['sd-dialog']:IsOpen()
```

---

### addLocalEntity

Adds a dialog to a specific entity with automatic target registration. Use this when spawning your own peds and want sd-dialog to handle the target interaction.

```lua
exports['sd-dialog']:addLocalEntity(entity, data)
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `entity` | number | Entity handle |
| `data` | table | Dialog and target configuration |

#### Data Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `targetIcon` | string | 'fas fa-comments' | Icon shown on target (Font Awesome format) |
| `targetLabel` | string | 'Talk' | Label shown on target |
| `targetDistance` | number | 2.5 | Interaction distance |
| `targetCanInteract` | function | nil | Condition for target to show |
| `name` | string | 'Unknown' | NPC name |
| `role` | string | nil | Role badge text |
| `roleColor` | string | '#ec4899' | Role badge color (hex) |
| `description` | string | '' | Dialog text |
| `options` | table | {} | Dialog options |
| `itemsPerPage` | number | 3 | Options shown per page |
| `onSelect` | function | nil | Callback when any option is selected |

#### Example

```lua
local ped = CreatePed(...)

exports['sd-dialog']:addLocalEntity(ped, {
    targetIcon = 'fas fa-comments',
    targetLabel = 'Talk to Marcus',
    targetDistance = 2.5,

    name = 'Marcus Webb',
    role = 'FIXER',
    roleColor = '#f59e0b',
    description = "I've got work if you're interested.",

    options = {
        {
            id = 'job_easy',
            label = 'Easy Job',
            icon = 'briefcase',
            description = 'Low risk, low reward.',
            serverEvent = { 'jobs:start', 'easy', 1500 },
        },
        {
            id = 'job_hard',
            label = 'Hard Job',
            icon = 'skull',
            description = 'High risk, high reward.',
            canInteract = function(entity)
                -- Replace with your own condition
                return exports['yourResource']:getReputation() >= 50
            end,
            serverEvent = { 'jobs:start', 'hard', 5000 },
        },
    },
})
```

---

### removeLocalEntity

Removes the dialog and target from an entity.

```lua
exports['sd-dialog']:removeLocalEntity(entity)
```

---

### addModel

Adds a dialog to all peds of a specific model (or models). Useful for adding interactions to existing world peds.

```lua
exports['sd-dialog']:addModel(models, data)
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `models` | string/table | Model name or array of model names |
| `data` | table | Dialog and target configuration (same as addLocalEntity) |

#### Example

```lua
-- Single model
exports['sd-dialog']:addModel('cs_bankman', {
    name = 'Bank Teller',
    role = 'EMPLOYEE',
    roleColor = '#3b82f6',
    description = "How may I assist you?",
    options = { ... },
})

-- Multiple models
exports['sd-dialog']:addModel({'cs_bankman', 's_m_m_bankman'}, {
    name = 'Bank Teller',
    description = "How may I assist you?",
    options = { ... },
})
```

---

### removeModel

Removes the dialog from a model (or models).

```lua
exports['sd-dialog']:removeModel(models)
```

---

## 🎛️ Option Properties

Each option in the `options` array supports the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | **Required.** Unique identifier |
| `label` | string | **Required.** Button text |
| `description` | string | Description text shown in list |
| `icon` | string | Lucide icon name (e.g., 'shopping-cart') |
| `canInteract` | function | Return false to lock/disable the option |
| `action` | function | Direct function to execute |
| `clientEvent` | string/table | Client event to trigger (string or `{event, args...}`) |
| `serverEvent` | string/table | Server event to trigger (string or `{event, args...}`) |
| `onSelect` | function | Legacy callback (receives option, dialog) |
| `menu` | table | Sub-menu configuration |

> **Note:** Only one action type should be used per option: `action`, `clientEvent`, `serverEvent`, or `onSelect`.

> **Important:** The dialog does **not** auto-close when an option is selected. Call `exports['sd-dialog']:Close()` in your action/event handler when you want to close it.

---

## 🔒 Conditional Options (canInteract)

Use `canInteract` to conditionally lock options. Locked options display with a lock icon and cannot be clicked.

```lua
options = {
    {
        id = 'vip_option',
        label = 'VIP Access',
        icon = 'star',
        description = 'Requires VIP membership.',
        canInteract = function(entity)
            -- Replace with your own condition (e.g., check player data, job, etc.)
            return exports['yourResource']:isPlayerVIP()
        end,
        serverEvent = 'vip:access',
    },
}
```

---

## ⚡ Action Types

### Direct Function

Execute a Lua function directly.

```lua
{
    id = 'example',
    label = 'Direct Action',
    action = function()
        DoSomething('arg1', 'arg2', 123)
        exports['sd-dialog']:Close()
    end,
}
```

### Client Event

Triggers a client-side event. Use a string for no arguments, or a table to pass arguments.

```lua
-- String: no arguments
clientEvent = 'myResource:doSomething'

-- Table: with arguments (first element is event name, rest are arguments)
clientEvent = { 'myResource:doSomething', 'arg1', 'arg2', 123 }
```

**Example with handler:**

```lua
-- Option
{
    id = 'example',
    label = 'Client Event',
    clientEvent = { 'shop:open', 'weapons' },
}

-- Handler (client-side)
RegisterNetEvent('shop:open', function(category)
    exports['sd-dialog']:Close()
    -- Your logic here
end)
```

### Server Event

Triggers a server-side event. Use a string for no arguments, or a table to pass arguments.

```lua
-- String: no arguments
serverEvent = 'myResource:doSomething'

-- Table: with arguments (first element is event name, rest are arguments)
serverEvent = { 'myResource:doSomething', 'arg1', 'arg2', 123 }
```

**Example with handler:**

```lua
-- Option
{
    id = 'example',
    label = 'Server Event',
    serverEvent = { 'jobs:start', 'delivery', 1500 },
}

-- Handler (server-side)
RegisterNetEvent('jobs:start', function(jobType, pay)
    local src = source
    -- Your logic here
end)
```

---

## 📂 Sub-Menus

Options can contain nested sub-menus:

```lua
options = {
    {
        id = 'delivery',
        label = 'Delivery Jobs',
        icon = 'truck',
        description = 'Various delivery routes.',
        menu = {
            description = 'Choose your route:',
            options = {
                {
                    id = 'route_easy',
                    label = 'Local Route',
                    icon = 'map-pin',
                    description = 'Short distance. Pay: $1,500',
                    serverEvent = { 'delivery:start', 'easy' },
                },
                {
                    id = 'route_hard',
                    label = 'County Route',
                    icon = 'map',
                    description = 'Long distance. Pay: $5,000',
                    canInteract = function(entity)
                        -- Replace with your own condition
                        return exports['yourResource']:getDeliveriesCompleted() >= 5
                    end,
                    serverEvent = { 'delivery:start', 'hard' },
                },
            },
        },
    },
}
```

---

## 🎨 Icons

**Dialog Options** support both [Lucide Icons](https://lucide.dev/icons) and [Font Awesome](https://fontawesome.com/icons):

```lua
-- Lucide (kebab-case)
icon = 'shopping-cart'
icon = 'circle-dollar-sign'
icon = 'briefcase'

-- Font Awesome
icon = 'fas fa-home'
icon = 'far fa-envelope'
icon = 'fa-solid fa-user'
icon = 'fa-cart-shopping'      -- Shorthand (defaults to solid)
```

**Target Icons** (`targetIcon`) use [Font Awesome](https://fontawesome.com/icons) format (handled by your target resource):

```lua
targetIcon = 'fas fa-comments'
targetIcon = 'fas fa-user'
targetIcon = 'fas fa-briefcase'
```

---
