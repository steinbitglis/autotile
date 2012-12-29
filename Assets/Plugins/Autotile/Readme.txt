######################
#      Autotile      #
######################

version: 1.0

Homepage:
    http://rain-games.com/autotile

Example images & videos:
    http://rain-games.com/autotile

Contact:
    autotile@rain-games.com

--------------------------
|      Installation      |
--------------------------

To install Autotile in your project, import the
unitypackage by clicking:
    'Assets->Import Package->Custom Package...'

The package installs the necessary files in three
folders:
    'Assets/Gizmos/Autotile'
    'Assets/Plugins/Autotile'
    'Assets/Plugins/Editor/Autotile'



--------------------------
|       Tile Usage       |
--------------------------

To create an Autotile, click 'GameObject->Create Other->Autotile'.

Make sure you are not using the Debug editor in Unity.

Autotiles can be scaled in either the X or Y direction locally.

Autotiles can also be connected at their ends; this is the main feature of
autotile, and allows for fast levelbuilding with custom textures.

Each non-square Autotile has a 1x1 corner area at each end that can connect to
other Autotiles when drag-and-drop'ed in such a way that the corners overlap in
either a 90 or 180 degree angle. (Do not rotate tiles. To create horizontal and
vertical tiles: scale down to 1 x 1, and then to your desired length
horizontally or vertically).

Autotiles can have a custom offset of 'left', 'right', 'bottom', 'top' or
'center'. This is useful when resizing them in a given direction.

When a connected Autotile is resized or moved, all its neighbours will get the
chance to move and resize in order to stay connected.
Neighbouring Autotiles will use their own offsets during the move/reszize. This
way you can create connections that stay fixed during certain move/resize
operations.

The Autotile script will modify the gameobject mesh and size when necessary, but
you can add other scripts to the object if desirable.



--------------------------
|   Single sided tiles   |
--------------------------

Autotiles can be either single sided, or double sided. This configuration is
done per tile, and per direction relative to its corners. The inspector shows
this as 2, 4 or 6 sun/moon-icons.

This does not necessarily mean that the tileset configuration has to respect
this abstraction (single sided, double sided, lit, dark etc.). It is a
convenient way of keeping track of which tiles are ie. ceiling, and which are
both floor and ceiling at the same time.

You can use dark tiles to hide the back side of single sided tiles. If a tile
has a dark center side, there will be "Insert dark tile"-button visible in the
inspector. This button will insert a tile which can be scaled both in the X and
Y directions, but which does not create a tiling texture. It can be used to
cover up parts of your game that is inside a wall, floor etc.  In practice, dark
tiles are just tiles that are configured to have no 'lit' sides. This enables
them to behave differently than other tiles.



--------------------------
|      Config Usage      |
--------------------------

Autotile texture configuration is done in the file
'Assets/Plugins/Autotile/Tilesets.asset'. You can use any texture, but it's
the easiest to configure textures that are based on a regular grid. For
examples, look in the folder 'Assets/Plugins/Autotile/Examples'.

Make sure you are not using the Debug editor in Unity.

Tileset texture configurations can be created from other texture configurations.
This is useful when painting tilesets on top of already configured tilesets. We
recommend duplicating and painting on top of
'Assets/Plugins/Autotile/Examples/Template/Template.png' and duplicating the
tileset configuration 'Template' when configuring it. This way, creating a
complete tileset configuration involves as little editor configuration work as
possible.




--------------------------
|   Autotile Animations  |
--------------------------

Autotile animations is a separate type of Autotiles. These can not be single
sided, or connect to other tiles. Animations will play when you press play in
Unity.

To create an Autotile Animation, click
'GameObject->Create Other->Autotile Animation'.

You can configure the animation speed per tileset.
You can also configure single frames to last longer than others. This has to be
in multiples of the default frame duration, so it is only meant to be used to
specify the relative duration of frames.



--------------------------
|     Example scene      |
--------------------------

Example scene:
    'Assets/Plugins/Autotile/Example Scene.unity'

The example scene shows how you can use gameobjects to rotate and scale
Autotiles freely. Tiles that have different parent objects are not able to
connect to eachother.

There is also one Autotile animation in the scene. It looks like it is one
sided, but that is just the look of the texture. Autotile animations can not be
configured to be one sided, but you could always fake it.

Please visit our website if you need more examples:
    http://rain-games.com/autotile



--------------------------
|         Support        |
--------------------------

Reach us:
    autotile@rain-games.com
