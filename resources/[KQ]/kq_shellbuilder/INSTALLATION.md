## INSTALLATION GUIDE

### Dependencies:
Install our KQ_LINK resource if you don't have it installed already
- If you do have it installed, make sure its up-to-date

Follow the detailed guide here: https://docs.kuzquality.com/kq-link/kq-link-or-installation-guide

Github: https://github.com/Kuzkay/kq_link

⚠ Make sure that `kq_link` is started **before** this resource. It also must be named exactly `kq_link`
___

### Step 0:
Install `kq_shellbuilder_props`, You will find this resource on your Keymaster along with this resource.

### Step 1:
Put the folder into your resources folder

### Step 2:
The script should automatically create a new database table named `kq_shellbuilder`. But if you want to be 100% safe. Import it manually from
`_installation_extras/kq_shellbuilder_table.sql`

### Step 3:
To allow our script to create dynamic doors, you must add

```
setr game_enableDynamicDoorCreation "true"
```

to your `server.cfg`. Simply paste it near the top of `server.cfg`

### Step 4:
Ensure the script in your `server.cfg` file.

```
ensure kq_shellbuilder_props
ensure kq_shellbuilder
```

### Step 5:
(This step only applies when you are using an Anti-cheat)

Make sure to fully whitelist `kq_shellbuilder` to allow it for creating objects.
If you are not able to whitelist the entire script. You may have to whitelist all objects found in the `kq_shellbuilder_props` resource as well as in `settings.lua` of `kq_shellbuilder`

### Step 6: (Optional)
Install `screenshot-basic` (a CFX resource) to use thumbnails within the Shell Creator shells list.
<https://github.com/citizenfx/screenshot-basic>

### Done
Enjoy the script

___

- https://docs.kuzquality.com/
- https://kuzquality.com/
- https://discord.gg/fZsyam7Rvz
