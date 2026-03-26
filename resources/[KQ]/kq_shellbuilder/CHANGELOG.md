# Update 1.1.0
- Made it possible to move the shells within housing systems (when placing it in the world)
    - The doors will not move with the shell, don't worry about them. They'll be in the correct place when entering the shell
    - The "void" will move with the shell. An option to toggle the void off is planned for the near future
- Added ak47_housing config export
- Fixed issues with ps-housing config export
- Increased the max prop limit to 1100 (from 1000)
- Fixed minor issues

**⚙️ Updated files**
- `client/spawner/shell.lua`
- `client/spawner/propBased.lua`
- `client/spawner/main.lua`
- `client/spawner/shell.lua`
- `shared/privSettings.lua`
- `server/server.lua`
- `config.lua`

# Update 1.2.0
- Added 3 new wall types
    - Glass wall 🔥
    - Metal panel wall
    - New wooden wall
- Added 3 new floor types
    - New wooden floor
    - Industrial floor
    - New tiled floor
    - Glass floor
- Added a new ceiling type
    - Glass ceiling

- Added an option to disable the "Void" around the shell. This can be done within the shell editor under the timecycle settings
    - We recommend keeping it on for normal shells/ipls. Only to be used for shells placed within the city with see-through windows (glass wall)

ℹ️ Normal "Windows" still come with a fake exterior. Those will be changed in the next update. To see the outside without the void, use the glass wall for now

⚠️ kq_shellbuilder_props has also been updated. Update it to 1.1.0. Replace the entire resource.

**⚙️ Updated files**
- `shared/privSettings.lua`
- `client/spawner/propBased.lua`
- `client/spawner/shell.lua`
- `client/builder/main.lua`
- `client/builder/parts/doors.lua`
- `client/builder/parts/walls.lua`
- `client/nui.lua`
- `server/manager.lua`
- `nui/dist/*`

# Update 1.3.0
- Added server sided exports and events
    - https://docs.kuzquality.com/resources/premium-resources/shell-creator/api

**⚙️ Updated files**
- `server/server.lua`

# Update 1.4.0
- Added an option to **hold and drag** to texture/paint/place while in the editor (`Config.allowMouseHoldToEdit`)
- Increased the overal max prop limit to **1200** (from 1100)
- Added additional debug logs

**⚙️ Updated files**
- `config.lua`
- `client/builder/tile/main.lua`
- `client/spawner/main.lua`
- `client/spawner/shell.lua`
- `shared/privSettings.lua`

# Update 1.5.0
- Added a client export `OpenShellEditor`
    - Find out more on [our docs page](https://docs.kuzquality.com/resources/premium-resources/shell-creator/api/client#openshelleditor)
- Added a debug command: `/objectstats`
    - This will display the amount of props, useful to debug the prop limits
- Added additional debug logs

**⚙️ Updated files**
- `client/editable/editable.lua`
- `client/builder/main.lua`
- `client/spawner/propBased.lua`

# Update 1.6.0
- Added a precision move mode for decorations
    - You can now right-click on decoration props (while in the decoration mode) to enter the gizmo mode
    - This allows you to move and rotate the decorations within their tile.
    - We still recommend using more detailed furniture systems to furnish your shells in more detail
    - This currently only works for decor with collision
    - Added a paragraph in the guide to describe this mode
- Increased the maximum prop limit to **1400** (from 1200)

**⚙️ Updated files**
- `config.lua`
- `client/builder/functions.lua`
- `client/builder/interact.lua`
- `client/builder/main.lua`
- `client/builder/tile/main.lua`
- `client/builder/tile/parts/decor.lua`
- `client/editable/editable.lua`
- `nui/*`

# Update 1.7.0
- Added custom textures
  - You can now have 50 custom wall and floor textures
  - Check out the "HOW_TO_ADD_TEXTURES.md" file located within the `custom_textures` folder for more info
- Moved all the "parts" to the public `settings.lua` file
- Added NUI theme customization
  - You can now customize the UI color through the config file
- Replaced the native gizmo with a custom gizmo system
- Void now has no collision when its hidden
- Added locale support. Everything can now be translated
- Updated oxmysql integration
- Increased the prop limit to `1500`


- Fixed various UI issues/bugs
- Fixed various shell creator issues/bugs

**⚙️ Files to replace**
- All non-editable files
- `nui/*`
- `server/editable/sql.lua`
- `settings.lua`
- `config.lua`
- `fxmanifest.lua`

I recommend a full clean install.

⚠️ **Make sure to also update the `kq_shellbuilder_props` resource to 1.2.0^**


# Update 1.8.0
- Reworked the custom textures system to be more reliable
- Fixed an issue with teleporters when the inside teleporter was within 30 meters of the outside teleporter
- Added more systems to the weather sync disabling
- Improved the keybind detection for leaving the "Preview mode"
- Added a search function to the Shells list
- Minor UI (styling) fixes

**⚙️ Files to replace**
- `nui/*`
- `fxmanifest.lua`
- `client/customs.lua`
- `client/builder/main.lua`
- `client/spawner/shell.lua`
- `locales/en.json`

⚠️ **Make sure to also update the `kq_shellbuilder_props` resource to 1.3.0^**
