[![Godot](https://img.shields.io/badge/Godot_Engine-4.5beta3-blue?logo=godotengine)](https://godotengine.org)
# Mournguard-Shaders
A collection of various shaders that are more-or-less ready to use.

# Shaders
## Keyhole
A noisy keyhole shader for godot 4.x, inspired by Neverwinter Nights EE
- Supplied as an extra node for the visual shader graph because I'm a baby.

https://github.com/user-attachments/assets/15acbc65-78ef-4f55-86c0-8c72d826a510

## Water
Just a simple water shader.

https://github.com/user-attachments/assets/cf41fb51-c11b-4c2d-8d4e-d16cb1e5043c

Doesn't really have any advanced features. Uses a small hack of setting metalness to 1.0 and making use of GI (Voxel, preferably) to look pretty.
Praying that one day easy no-bake GI solutions like SDFGI will be able to support screen-reading/transparent shaders because it looks great with it actually but having to disable any transparency is obviously too much of a drawback. So Voxel GI it is for now. There's a test scene. Water flows on the x axis of the meshes UVs so you can model like a river and unwrap it with Blender's "follow active quad" to get correct mapping.

# Assets
Assets included are under the CC0 license
- Foam Texture 001: https://ambientcg.com/view?id=Foam001/
