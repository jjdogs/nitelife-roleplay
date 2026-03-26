# Lation UI

A modern UI library for FiveM

## Components Overview

- [Alert Dialog](#alert-dialog) - Confirmation and information dialogs
- [Input Dialog](#input-dialog) - Form inputs with various field types
- [Menu](#menu) - Context menus with navigation and actions
- [Notification](#notification) - Customizable notifications
- [Progress Bar](#progress-bar) - Progress bar with animations and steps
- [Radial Menu](#radial-menu) - Circular radial menu with submenus
- [Skill Check](#skill-check) - Interactive skill check minigame
- [Text UI](#text-ui) - Contextual text displays with keybinds

---

## Alert Dialog

Alert dialogs can be used for confirmations, warnings, informational messages and more.

### Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `header` | string | No* | `nil` | The dialog header text (supports markdown) |
| `content` | string | No* | `nil` | The main content text (supports markdown) |
| `icon` | string | No | `nil` | FontAwesome icon class |
| `iconColor` | string | No | `'#71717A'` | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `labels` | table | No | `{}` | Button labels: `{ cancel = 'Cancel', confirm = 'Confirm' }` |
| `type` | string | No | `'default'` | Dialog type: `'default'`, `'info'`, `'success'`, `'warning'`, `'error'` |
| `size` | string | No | `'md'` | Dialog size: `'xs'`, `'sm'`, `'md'`, `'lg'`, `'xl'` |
| `cancel` | boolean | No | `true` | Whether to show cancel button |
| `callouts` | table | No | `nil` | Array of callout objects (see below) |

*Either `header` or `content` is required.

### Callouts

Callouts are optional styled information boxes that can be added to alert dialogs to highlight important information.

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `label` | string | No | `nil` | The callout title/header (supports markdown) |
| `description` | string | Yes | `nil` | The callout content text (supports markdown) |
| `type` | string | No | `'info'` | Callout type: `'info'`, `'success'`, `'warning'`, `'error'` |
| `icon` | string | No | `nil` | Custom FontAwesome icon (inherits type color) |

### Functions

```lua
-- Show alert dialog
local result = exports.lation_ui:alert(data)

-- Close any open alert dialog
exports.lation_ui:closeAlert()
```

### Return Values
- `'confirm'` - User clicked confirm
- `'cancel'` - User clicked cancel or closed dialog

### Example

```lua copy
local alert = exports.lation_ui:alert({
    header = 'Delete Item',
    content = 'Are you sure you want to delete this item?',
    icon = 'fas fa-trash',
    iconColor = '#EF4444',
    type = 'destructive',
})

if alert == 'confirm' then
    print('Item deleted!')
end
```

```lua copy
local alert = exports.lation_ui:alert({
    header = 'Callouts',
    content = 'Below is a showcase of a new optional element inside alert dialogs - callouts! Make important information stand out like never before.',
    icon = 'fas fa-star',
    callouts = {
        {
            label = 'Warning',
            description = 'This is the warning type callout',
            type = 'warning'
        },
        {
            label = 'Success',
            description = 'This is the success type callout',
            type = 'success'
        },
        {
            label = 'Error',
            description = 'This is the error type callout',
            type = 'error'
        },
        {
            label = 'Customizable',
            description = 'This callout uses a custom icon but inherits the default type settings',
            icon = 'fas fa-rocket'
        }
    }
})
```

![](https://img.lationscripts.com/docs/ui/alert-dialog/destructive-example.webp)

![](https://img.lationscripts.com/docs/ui/alert-dialog/callouts-example.webp)

---

## Input Dialog

Input dialogs provide forms with various field types for collecting user data.

### Dialog Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `title` | string | No | `nil` | Dialog title |
| `subtitle` | string | No | `nil` | Dialog subtitle |
| `submitText` | string | No | `'Submit'` | Submit button text |
| `cancelText` | string | No | `'Cancel'` | Cancel button text |
| `type` | string | No | `'default'` | Dialog type: `'default'`, `'info'`, `'success'`, `'warning'`, `'error'` |
| `options` | table | Yes | `{}` | Array of input fields |

### Field Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `type` | string | Yes | `nil` | Field type: `'input'`, `'number'`, `'toggle'`, `'checkbox'`, `'select'`, `'multi-select'`, `'slider'`, `'textarea'`, `'color'`, `'date'`, `'date-range'` |
| `label` | string | Yes | `nil` | Field label |
| `description` | string | No | `nil` | Field description |
| `placeholder` | string | No | `nil` | Placeholder text (input, textarea, color, date, date-range) |
| `icon` | string | No | `nil` | FontAwesome icon class |
| `iconColor` | string | No | `'#71717A'` | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `required` | boolean | No | `false` | Whether field is required |
| `disabled` | boolean | No | `false` | Whether field is disabled |
| `password` | boolean | No | `false` | Password field with toggle visibility (input type only) |
| `min` | string/number | No | `nil` | Min value (number, slider), min length (input, textarea), or min date for date/date-range picker (must match format) |
| `max` | string/number | No | `nil` | Max value (number, slider), max length (input, textarea), max selections (multi-select), or max date for date/date-range picker (must match format) |
| `step` | number | No | `1` | Step value (number, slider) |
| `unit` | string | No | `nil` | Unit label (slider) |
| `options` | table | No | `{}` | Options for select/multi-select (see [Select Options](#select-options)) |
| `default` | any | No | `nil` | Default field value |
| `checked` | boolean | No | `nil` | Alias for `default` on toggle/checkbox types |
| `format` | string | No | `'hex'` / `'MM/DD/YYYY'` | Color format for color picker: `'hex'`, `'hexa'`, `'rgb'`, `'rgba'`, `'hsl'`, `'hsla'` or date format for date/date-range picker: `'MM/DD/YYYY'`, `'DD/MM/YYYY'`, `'YYYY-MM-DD'`, `'DD.MM.YYYY'` |
| `clearable` | boolean | No | `true` | Whether date/date-range picker shows clear button |
| `searchable` | boolean | No | `true` | Enable search functionality (select, multi-select) |

### Select Options

For `select` and `multi-select` field types, the `options` parameter accepts an array of option objects:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `label` | string | No | `nil` | Display text for the option (uses `value` if not provided) |
| `value` | any | Yes | `nil` | Value returned when option is selected |
| `disable` | boolean | No | `false` | Whether the option is disabled and cannot be selected |

**Notes:** 
- `'checkbox'` is an alias for `'toggle'` - both render the same component.
- `'checked'` is an alias for `'default'` on toggle/checkbox types.
- For `'date'` type fields, `min`, `max`, and `default` values must match the specified `format`.
- For `'date-range'` type fields, `default` can be used to set a default date range `default = { "01/01/2025", "01/07/2025" }`.

### Functions

```lua
-- Show input dialog
local result = exports.lation_ui:input(data)

-- Close any open input dialog
exports.lation_ui:closeInput()
```

### Return Values
- Table of values (indexed by field order) or `nil` if cancelled

### Example

```lua copy
local result = exports.lation_ui:input({
    title = "User Profile",
    subtitle = "Enter your information",
    submitText = "Save",
    options = {
        {
            type = 'input',
            label = 'Username',
            description = 'Input your username below',
            placeholder = 'IamLation',
            icon = 'fas fa-user',
            required = true
        },
        {
            type = 'number',
            label = 'Age',
            description = 'Input your age below',
            icon = 'fas fa-birthday-cake',
            required = true,
            default = 18
        },
        {
            type = 'select',
            label = 'Country',
            description = 'Select your country',
            icon = 'fas fa-globe',
            options = {
                { label = 'United States', value = 'us' },
                { label = 'Canada', value = 'ca' },
                { label = 'United Kingdom', value = 'uk' },
                { label = 'Australia', value = 'au' }
            }
        },
        {
            type = 'toggle',
            label = 'Receive Notifications',
            description = 'Toggle notifications on or off',
            icon = 'fas fa-bell',
            default = true
        },
        {
            type = 'slider',
            label = 'Volume',
            description = 'Adjust the volume level',
            icon = 'fas fa-volume-up',
            min = 0,
            max = 100,
            unit = '%',
            default = 50
        }
    }
})

if result then
    print('Username:', result[1])
    print('Age:', result[2])
    print('Country:', result[3])
    print('Notifications:', result[4])
    print('Volume:', result[5])
end
```

![](https://img.lationscripts.com/docs/ui/input-dialog/input-dialog-example.webp)

---

## Menu

Context menus provide navigation and action selection with hierarchical support.

### Registration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | string | Yes | `nil` | Unique menu identifier |
| `title` | string | No | `nil` | Menu title (supports markdown) |
| `subtitle` | string | No | `nil` | Menu subtitle (supports markdown) |
| `menu` | string | No | `nil` | Parent menu ID (for back navigation) |
| `canClose` | boolean | No | `true` | Whether menu can be closed with ESC |
| `position` | string | No | `'top-right'` | Menu position: `'top-left'`, `'top-right'`, `'offcenter-left'`, `'offcenter-right'` (submenus will inherit parent menu positioning) |
| `onExit` | function | No | `nil` | Function called when menu is closed with ESC |
| `options` | table | Yes | `{}` | Array of menu options |

### Option Properties

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `title` | string | Yes | `nil` | Option display text (supports markdown) |
| `icon` | string | No | `nil` | FontAwesome icon class or image URL (supports `.png`, `.webp`, `.jpg`, `.jpeg`, `.gif`, `.svg`) |
| `iconColor` | string | No | `'#71717A'` | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `iconAnimation` | string | No | `nil` | Icon animation: `'spin'`, `'spinPulse'`, `'spinReverse'`, `'pulse'`, `'beat'`, `'fade'`, `'beatFade'`, `'bounce'`, `'shake'`, |
| `description` | string | No | `nil` | Option description (supports markdown) |
| `keybind` | string | No | `nil` | Keybind display text |
| `disabled` | boolean | No | `false` | Whether option is disabled |
| `readOnly` | boolean | No | `false` | Whether option is read-only (no click) |
| `menu` | string | No | `nil` | Submenu ID to open |
| `arrow` | boolean | No | `false` | Show arrow indicator (auto-set for submenus) |
| `progress` | number | No | `nil` | Progress bar value (0-100) |
| `progressColor` or `colorScheme` | string | No | `'#3B82F6'` | Progress bar color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `image` | string | No | `nil` | URL to an image displayed in the hover metadata |
| `metadata` | table | No | `nil` | Additional information displayed on hover (see [Metadata](#metadata)) |
| `onSelect` | function | No | `nil` | Callback function |
| `event` | string | No | `nil` | Client event to trigger |
| `serverEvent` | string | No | `nil` | Server event to trigger |
| `args` | any | No | `nil` | Arguments for events |

### Metadata

The `metadata` property displays additional information in a hover card. It supports three formats:

**String Array**
```lua
metadata = {
    "Additional info line 1",
    "Additional info line 2", 
    "Additional info line 3"
}
```

**Key-Value Object**
```lua
metadata = {
    ["Property 1"] = "Value 1",
    ["Property 2"] = "Value 2",
    ["Status"] = "Active"
}
```

**Structured Array** (*Recommended*)
```lua
metadata = {
    { label = "Health", value = "85%" },
    { label = "Armor", value = "100%" },
    { label = "Experience", value = "1,250 XP", progress = 75, progressColor = "#3B82F6" },
    { label = "Level Progress", value = "3/4", progress = 75, progressColor = "#10B981" }
}
```

**Metadata Item Properties**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `label` | string | Yes | The label text |
| `value` | any | Yes | The value to display |
| `progress` | number | No | Progress bar value |
| `progressColor` or `colorScheme` | string | No | Progress bar color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |

### Functions

```lua
-- Register a menu
exports.lation_ui:registerMenu(menuData)

-- Show a registered menu
exports.lation_ui:showMenu(menuId)

-- Hide the current menu
exports.lation_ui:hideMenu()

-- Get the currently open menu ID
local menuId = exports.lation_ui:getOpenMenu()
```

### Example

```lua copy
-- Register main menu
exports.lation_ui:registerMenu({
    id = 'test_menu',
    title = 'Test Menu',
    subtitle = 'Select an option below',
    onExit = function()
        print('Menu closed')
    end,
    options = {
        {
            title = 'Simple',
            description = 'This is a simple menu option',
            icon = 'fas fa-bars',
        },
        {
            title = 'Disabled',
            description = 'This option is disabled',
            icon = 'fas fa-ban',
            iconColor = '#EF4444',
            disabled = true
        },
        {
            title = 'Read-Only',
            description = 'This option is read-only',
            icon = 'fas fa-circle-info',
            iconColor = '#44aae8',
            readOnly = true
        },
        {
            title = 'Progress Bar',
            description = 'This option shows a progress bar',
            icon = 'fas fa-bars-progress',
            progress = 45,
        },
        {
            title = 'Image',
            description = 'This option shows an image',
            icon = 'fas fa-image',
            image = 'https://img.lationscripts.com/lation-scripts-primary.png',
        },
        {
            title = 'Sub Menu',
            description = 'This option opens a sub menu',
            icon = 'fas fa-list',
            menu = 'sub_menu'
        }
    }
})

-- Register submenu
exports.lation_ui:registerMenu({
    id = 'sub_menu',
    title = 'Sub Menu',
    subtitle = 'Select an option below',
    menu = 'test_menu', -- Back button to test_menu
    options = {
        {
            title = 'Metadata',
            description = 'This option has metadata',
            icon = 'fas fa-database',
            metadata = {
                { label = 'Label 1', value = 'Value' },
                { label = 'Label 2', value = 69 }
            }
        },
        {
            title = 'onSelect',
            description = 'This option triggers a function',
            icon = 'fas fa-play',
            onSelect = function()
                print('onSelect function triggered')
            end
        },
        {
            title = 'Events',
            description = 'This option triggers a client event',
            icon = 'fas fa-broadcast-tower',
            event = 'resourceName:eventName',
            args = {
                message = 'Hello from sub_menu',
            }
        },
        {
            title = 'Keybind',
            description = 'This can be triggered with a keybind',
            icon = 'fas fa-keyboard',
            keybind = 'F2',
        }
    }
})

-- Show menu
exports.lation_ui:showMenu('test_menu')
```

![](https://img.lationscripts.com/docs/ui/context-menu/menu-example-1.webp)

![](https://img.lationscripts.com/docs/ui/context-menu/menu-example-2.webp)

---

## Notification

Notifications with customizable positioning, styling and more.

### Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `title` | string | No | `nil` | Notification title (supports markdown) |
| `message` | string | Yes* | `nil` | Notification message (supports markdown) |
| `type` | string | No | `'info'` | Type: `'info'`, `'success'`, `'warning'`, `'error'` |
| `duration` | number | No | `5000` | Duration in milliseconds |
| `position` | string | No | `'top-right'` | Position: `'top-left'`, `'top'`, `'top-right'`, `'center-left'`, `'center-right'`, `'bottom-left'`, `'bottom'`, `'bottom-right'` |
| `icon` | string | No | `nil` | FontAwesome icon class |
| `iconColor` | string | No | Auto | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `bgColor` | string | No | Auto | Background color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `txtColor` | string | No | Auto | Text color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |

*Either `title` or `message` is required.

**Notes:** 
- `'description'` is an alias for `'message'`.
- `'top'` is an alias for `'top-center'`.

### Example

```lua copy
exports.lation_ui:notify({
    title = 'Success',
    message = 'Profile updated successfully',
    type = 'success',
})

exports.lation_ui:notify({
    title = 'Error',
    message = 'Failed to save changes',
    type = 'error',
})

exports.lation_ui:notify({
    title = 'Warning',
    message = 'Your session is about to expire',
    type = 'warning',
})

exports.lation_ui:notify({
    title = 'Info',
    message = 'New features are now available',
    type = 'info',
})

exports.lation_ui:notify({
    message = 'A notification with only a message',
})

exports.lation_ui:notify({
    title = 'Custom',
    message = 'A notification with custom styles',
    bgColor = '#e35c5c',
    icon = 'fas fa-screwdriver-wrench',
    iconColor = '#3a3a3a',
    txtColor = '#e5e5e5',
})

exports.lation_ui:notify({
    title = 'Custom',
    message = 'A notification with custom styles',
    bgColor = '#bd71f2',
    icon = 'fas fa-bars',
    iconColor = '#3a3a3a',
    txtColor = '#e5e5e5',
})
```

![](https://img.lationscripts.com/docs/ui/notifications/notification-example.webp)

---

## Skill Check

Interactive skill check mini-game with configurable difficulty.

### Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `title` | string | Yes | `nil` | Title for skill check |
| `difficulty` | string/table | Yes | `nil` | Difficulty level or array of difficulties |
| `inputs` | string/table | No | `'E'` | Single input key or array of input keys |

### Difficulty Levels
- `'easy'` - Large target area, slow speed
- `'medium'` - Medium target area, medium speed  
- `'hard'` - Small target area, fast speed
- Custom object: `{ areaSize = 20, speedMultiplier = 1.5 }`

### Functions

```lua
-- Start skill check
local success = exports.lation_ui:skillCheck(title, difficulty, inputs)

-- Cancel active skill check
exports.lation_ui:cancelSkillCheck()

-- Check if skill check is active
local isActive = exports.lation_ui:skillCheckActive()
```

### Return Values
- `true` - All skill checks completed successfully
- `false` - Failed or cancelled

### Example

```lua copy
local success = exports.lation_ui:skillCheck('Lockpick', {'easy', 'easy', 'easy', 'easy'}, {'W', 'A', 'S', 'D'})

if success then
    print('Success')
else
    print('Failed')
end

-- Custom difficulty
local success = exports.lation_ui:skillCheck('Lockpick', {
    { areaSize = 15, speedMultiplier = 2.0 },
    { areaSize = 10, speedMultiplier = 2.5 }
})
```

![](https://img.lationscripts.com/docs/ui/skill-check/skill-check-example.webp)

---

## Progress Bar

Progress bar with optional multi-step feature & more.

### Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `label` | string | No | `Progress` | Progress bar label |
| `description` | string | No | `nil` | Progress description (overridden by steps) |
| `duration` | number | Yes | `nil` | Duration in milliseconds |
| `icon` | string | No | `nil` | FontAwesome icon class |
| `iconColor` | string | No | `'#71717A'` | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `iconAnimation` | string | No | `nil` | Icon animation: `'spin'`, `'spinPulse'`, `'spinReverse'`, `'pulse'`, `'beat'`, `'fade'`, `'beatFade'`, `'bounce'`, `'shake'` |
| `color` | string | No | `'#3B82F6'` | Progress bar color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `steps` | table | No | `{}` | Array of step objects with descriptions |
| `canCancel` | boolean | No | `true` | Whether progress can be cancelled with X key |
| `useWhileDead` | boolean | No | `false` | Allow progress while player is dead |
| `allowRagdoll` | boolean | No | `false` | Allow progress while player is ragdolled |
| `allowCuffed` | boolean | No | `false` | Allow progress while player is cuffed |
| `allowFalling` | boolean | No | `false` | Allow progress while player is falling |
| `allowSwimming` | boolean | No | `false` | Allow progress while player is swimming |
| `anim` | table | No | `nil` | See "Animations" below |
| `prop` | table | No | `nil` | See "Props" below |
| `disable` | table | No | `nil` | Controls to disable during progress |

### Animations

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `dict` | string | No* | `nil` | Animation dictionary |
| `clip` | string | Yes | `nil` | Animation clip name |
| `flag` | number | No | `49` | Animation flags |
| `blendIn` | number | No | `3.0` | Blend in speed |
| `blendOut` | number | No | `1.0` | Blend out speed |
| `duration` | number | No | `-1` | Animation duration (-1 for loop) |
| `playbackRate` | number | No | `0` | Playback rate |
| `lockX` | boolean | No | `false` | Lock X axis |
| `lockY` | boolean | No | `false` | Lock Y axis |
| `lockZ` | boolean | No | `false` | Lock Z axis |
| `scenario` | string | No* | `nil` | Scenario name (alternative to dict/clip) |
| `playEnter` | boolean | No | `true` | Play enter animation for scenarios |

*Either `dict` or `scenario` is required if using animations.

### Props

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `model` | string | Yes | `nil` | Prop model hash |
| `bone` | number | No | `60309` | Bone index to attach to |
| `pos` | table | Yes | `nil` | Position offset `{x, y, z}` |
| `rot` | table | Yes | `nil` | Rotation offset `{x, y, z}` |
| `rotOrder` | number | No | `0` | Rotation order |

### Disable

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `move` | boolean | `false` | Disable player movement |
| `sprint` | boolean | `false` | Disable sprinting only |
| `car` | boolean | `false` | Disable vehicle controls |
| `combat` | boolean | `false` | Disable combat actions |
| `mouse` | boolean | `false` | Disable mouse look |

### Functions

```lua
-- Show progress bar
local success = exports.lation_ui:progressBar(data)

-- Check if progress is active
local isActive = exports.lation_ui:progressActive()

-- Cancel active progress
exports.lation_ui:cancelProgress()
```

### Return Values
- `progressBar()`: `true` if completed, `false` if cancelled/failed
- `progressActive()`: `true` if progress is active, `false` otherwise

### Example

```lua copy
-- Basic progress bar
if exports.lation_ui:progressBar({
    label = 'Submitting',
    description = 'Please wait while we process your data...',
    duration = 5000,
    icon = 'fas fa-download',
}) then print('Progress completed') else print('Cancelled/incomplete') end
```

```lua copy
-- Progress with multi-step feature
if exports.lation_ui:progressBar({
    label = 'Initializing Hack',
    duration = 10000,
    icon = 'fas fa-crosshairs',
    iconColor = '#EF4444',
    color = '#EF4444',
    steps = {
        { description = 'Connecting to server...' },
        { description = 'Bypassing security protocols...' },
        { description = 'Establishing secure connection...' },
        { description = 'Hack in progress...' }
    }
}) then print('Progress completed') else print('Cancelled/incomplete') end
```

```lua copy
-- Progress with animation and props
if exports.lation_ui:progressBar({
    label = 'Robbing Store',
    description = 'Looting cash from the register...',
    duration = 30000,
    icon = 'fas fa-money-bill-wave',
    iconColor = '#10B981',
    color = '#10B981',
    useWhileDead = false,
    disable = { 
        car = true,
        move = true,
        combat = true
    },
    anim = {
        dict = 'anim@heists@ornate_bank@grab_cash',
        clip = 'grab'
    },
    prop = {
        model = 'p_ld_heist_bag_s',
        bone = 40269,
        pos = vec3(0.0454, 0.2131, -0.1887),
        rot = vec3(66.4762, 7.2424, -71.9051)
    }
}) then print('Progress completed') else print('Cancelled/incomplete') end
```

![](https://img.lationscripts.com/docs/ui/progress-bar/progress-bar-example.webp)

---

## Radial Menu

Circular radial menu with hierarchical navigation, progress indicators, and status badges.

### Registration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | string | Yes | `nil` | Unique menu identifier |
| `items` | table | Yes | `{}` | Array of menu items |

### Item Properties

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | string | No | `nil` | Unique item identifier (for global items) |
| `label` | string | Yes | `nil` | Item display text |
| `icon` | string | No | `nil` | FontAwesome icon class or image URL (supports `.png`, `.webp`, `.jpg`, `.jpeg`, `.gif`, `.svg`) |
| `iconColor` | string | No | `'#9CA3AF'` | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `iconAnimation` | string | No | `nil` | Icon animation: `'spin'`, `'spinPulse'`, `'spinReverse'`, `'pulse'`, `'beat'`, `'fade'`, `'beatFade'`, `'bounce'`, `'shake'` |
| `iconAnimateOnHover` | boolean | No | `false` | If `true`, icon only animates on hover instead of continuously |
| `menu` | string | No | `nil` | Submenu ID to open |
| `progress` | number | No | `nil` | Progress ring value (0-100) |
| `progressColor` | string | No | `'#3B82F6'` | Progress ring color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `badge` | number/string | No | `nil` | Badge text/count (numbers >99 display as "99") |
| `badgeColor` | string | No | `'#EF4444'` | Badge color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `readOnly` | boolean | No | `false` | Display only, no hover or click |
| `keepOpen` | boolean | No | `false` | Keep menu open after clicking |
| `onSelect` | function | No | `nil` | Callback function that receives `(currentMenu, itemIndex)` as parameters |

### Functions

```lua
-- Register a radial submenu
exports.lation_ui:registerRadial(radialData)

-- Add item(s) to global radial menu
exports.lation_ui:addRadialItem(item) -- Single item
exports.lation_ui:addRadialItem({item1, item2}) -- Multiple items

-- Remove item from global menu
exports.lation_ui:removeRadialItem(itemId)

-- Clear all global items
exports.lation_ui:clearRadialItems()

-- Hide radial menu
exports.lation_ui:hideRadial()

-- Disable radial menu
exports.lation_ui:disableRadial(state)

-- Get current radial menu ID
local menuId = exports.lation_ui:getCurrentRadialId()
```

### Example

```lua copy
-- Register submenus
exports.lation_ui:registerRadial({
    id = 'vehicle_menu',
    items = {
        {
            label = 'Lock/Unlock',
            icon = 'lock',
            onSelect = function()
                print('Toggling vehicle lock')
            end
        },
        {
            label = 'Engine',
            icon = 'key',
            onSelect = function()
                print('Toggling engine')
            end
        },
        {
            label = 'Trunk',
            icon = 'box',
            onSelect = function()
                print('Opening trunk')
            end
        }
    }
})

exports.lation_ui:registerRadial({
    id = 'player_menu',
    items = {
        {
            label = 'Wallet',
            icon = 'wallet',
            onSelect = function()
                print('Opening wallet')
            end
        },
        {
            label = 'Phone',
            icon = 'mobile',
            badge = 5,
            badgeColor = '#EF4444',
            onSelect = function()
                print('Opening phone')
            end
        },
        {
            label = 'Inventory',
            icon = 'bag-shopping',
            onSelect = function()
                print('Opening inventory')
            end
        }
    }
})

exports.lation_ui:registerRadial({
    id = 'examples_menu',
    items = {
        {
            label = 'Read Only',
            icon = 'circle-info',
            readOnly = true
        },
        {
            label = 'Custom Color',
            icon = 'palette',
            iconColor = '#EC4899',
            onSelect = function()
                print('Custom color example')
            end
        },
        {
            label = 'Spinning Icon',
            icon = 'gear',
            iconAnimation = 'spin',
            onSelect = function()
                print('Spinning icon example')
            end
        },
        {
            label = 'Progress Ring',
            icon = 'chart-line',
            progress = 65,
            progressColor = '#8B5CF6',
            onSelect = function()
                print('Progress ring example')
            end
        },
        {
            label = 'Badge',
            icon = 'bell',
            badge = 12,
            badgeColor = '#F59E0B',
            onSelect = function()
                print('Badge example')
            end
        }
    }
})

-- Add global menu items
exports.lation_ui:addRadialItem({
    {
        id = 'vehicle',
        label = 'Vehicle',
        icon = 'car',
        menu = 'vehicle_menu'
    },
    {
        id = 'player',
        label = 'Player',
        icon = 'user',
        menu = 'player_menu'
    },
    {
        id = 'examples',
        label = 'Examples',
        icon = 'lightbulb',
        menu = 'examples_menu'
    }
})
```

**Notes:**
- Press **Z** to open/close the global radial menu (will only display when there is at least one item)
- **Left click** to select an item
- **Right click** or click center button to go back
- Progress rings display 0-100% around icons
- Badges show counts (1-99) or text (single character recommended)
- Read-only items are informational and cannot be clicked
- `onSelect` callback receives `(currentMenu, itemIndex)` parameters where `currentMenu` is the current menu ID (or `nil` for global menu) and `itemIndex` is the clicked item's index

---

## Text UI

Contextual text displays with markdown support, icons, and keybind indicators. Supports both single-text mode and multi-option lists.

### Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `title` | string | No | `nil` | Text UI title |
| `description` | string | Yes* | `nil` | Main text content (supports markdown) |
| `position` | string | No | `'right-center'` | Position: `'top-left'`, `'top-center'`, `'top-right'`, `'left-center'`, `'center'`, `'right-center'`, `'bottom-left'`, `'bottom-center'`, `'bottom-right'` |
| `icon` | string | No | `nil` | FontAwesome icon class |
| `iconColor` | string | No | `'#71717A'` | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `iconAnimation` | string | No | `nil` | Icon animation: `'spin'`, `'spinPulse'`, `'spinReverse'`, `'pulse'`, `'beat'`, `'fade'`, `'beatFade'`, `'bounce'`, `'shake'`, |
| `keybind` | string | No | `nil` | Keybind text to display |
| `options` | table | No | `nil` | Array of options for multi-option display |
| `bgColor` | string | No | `'#1E1F24'` | Background color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `txtColor` | string | No | `'#E4E4E7'` | Text color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |

*Either `title`, `description`, or `options` is required.

### Option Item Structure

When using the `options` parameter, each option item supports:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `label` | string | Yes | `nil` | Option label text (supports markdown) |
| `icon` | string | No | `nil` | FontAwesome icon class |
| `iconColor` | string | No | Inherits from main | Icon color (hex or [CSS color name](https://htmlcolorcodes.com/color-names/)) |
| `iconAnimation` | string | No | `nil` | Icon animation |
| `keybind` | string | No | `nil` | Keybind text for this option |

### Markdown
- **Bold text**: `**text**`
- *Italic text*: `*text*`
- `Code text`: `` `text` ``
- Line breaks: `\n`

### Functions

```lua
-- Show text UI
exports.lation_ui:showText(data)

-- Hide text UI
exports.lation_ui:hideText()

-- Check if text UI is open
local isOpen, displayText = exports.lation_ui:isOpen()
```

### Return Values
- `isOpen()`: `isOpen` (boolean), `displayText` (string or nil)

### Example

```lua copy
-- Basic text UI
exports.lation_ui:showText({
    description = 'This is a *simple* message with **formatting**'
})
```

```lua copy
-- Customized text UI prompt
exports.lation_ui:showText({
    title = 'Interaction Available',
    description = 'Press to interact with this object',
    keybind = 'E',
    icon = 'fas fa-hand-paper',
    iconColor = '#3B82F6'
})
```

```lua copy
-- Multi-option text UI
exports.lation_ui:showText({
    title = 'Controls',
    description = 'Place the object where desired',
    options = {
        {
            label = 'Move Forward',
            icon = 'fas fa-arrow-up',
            keybind = 'W'
        },
        {
            label = 'Move Backward',
            icon = 'fas fa-arrow-down',
            keybind = 'S'
        },
        {
            label = 'Move Left',
            icon = 'fas fa-arrow-left',
            keybind = 'A'
        },
        {
            label = 'Move Right',
            icon = 'fas fa-arrow-right',
            keybind = 'D'
        },
        {
            label = 'Cancel',
            icon = 'fas fa-xmark',
            iconColor = '#EF4444',
            keybind = 'X'
        },
        {
            label = 'Confirm',
            icon = 'fas fa-check',
            iconColor = '#10B981',
            keybind = 'SPACE'
        }
    }
})
```

```lua copy
-- Check if text UI is open
local isOpen, text = exports.lation_ui:isOpen()
if isOpen then
    print('Text UI is open & currently displaying:', text)
end
```

![](https://img.lationscripts.com/docs/ui/text-ui/text-ui-example.webp)

![](https://img.lationscripts.com/docs/ui/text-ui/text-ui-options-example.webp)