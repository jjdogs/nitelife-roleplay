# Custom Textures
This guide explains how to add your own custom textures to the Shell Creator. You can register up to:
- 100 unique wall textures
- 100 unique floor textures

This gives you a maximum of 200 custom texture slots in total.
Additionally, all custom floors will also be usable as ceilings. As those can utilize same models as floors.

## Using more than 50 custom textures?
To enable the additional models for extra textures, in `kq_shellbuilder_props/fxmanifest.lua`

You must add the following line: `data_file 'DLC_ITYP_REQUEST' 'stream/kq_sb_custom_addon.ytyp'`
Add it to the 18th line in the `fxmanifest.lua` file. Make sure to restart your server after adding this.

Once that's done, you can simply add more textures as mentioned below.
___
# How to add new textures:
1. Choose a texture type
    - Go to the walls folder if you’re adding wall textures.
    - Go to the floors folder if you’re adding floor textures.
2. Create a texture slot folder
   - Inside the chosen folder, create a new folder named after the slot number you want to use.
   - Slot names must be numbers only: "1", "2", "3", ... up to "100".
3. Add your texture files
   - Place your texture images inside the slot folder.
   - Accepted formats: .png and .dds
4. Name your files correctly
   - diffuse.png → Base texture (required)
   - normal.png → Normal map (optional)
   - spec.png → Specular map (optional)

If normal.png or spec.png are missing, default fallback textures will be applied. The diffuse.png is always required.

___
## Recommended sizes:
- Walls: We recommend a texture size of 256x256 or 512x512 for walls.
- Floors: We recommend a texture size of 512x512 or 1024x1024 for floors.

Make sure that all textures are seamless and "tileable".

___
## Understanding Texture Types
###  Diffuse (diffuse.png)

The diffuse map is the base color/visual look of the material. It’s the actual image you see painted onto the wall or floor, controlling color and basic detail. Without it, the material won’t render properly.

Example: A brick wall diffuse map contains the red brick and gray mortar colors.

### Normal (normal.png)

The normal map adds the illusion of depth, bumps, and surface detail without increasing the polygon count. It affects how light interacts with the surface, making flat textures appear 3D.

Example: A wood floor with a normal map looks like it has grooves between planks, even though the mesh is completely flat.

### Specular (spec.png)

The specular map controls shininess and reflectivity. Brighter areas on the spec map reflect more light (glossy/shiny), while darker areas reflect less (matte). This helps make surfaces look realistic under different lighting conditions.

Example: A polished marble floor would have a bright specular map, while a rough brick wall would have a dark one.
