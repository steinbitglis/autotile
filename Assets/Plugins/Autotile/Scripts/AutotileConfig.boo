import UnityEngine

class AutotileConfig (ScriptableObject):

    static public final tilesetsPath = "Assets/Plugins/Autotile/Tilesets.asset"
    static private autotileConfig as AutotileConfig

    static config as AutotileConfig:
        get:
            unless autotileConfig:
                if tilesetsPath =~ @/^Assets\/Resources\//:
                    extension = Path.GetExtension(tilesetsPath)
                    target = (tilesetsPath[17:])[:-extension.Length] # Resources.Load requires path relative to 'Assets/Resources' minus extension
                    autotileConfig = Resources.Load(target, AutotileConfig)
                else:
                    autotileConfig = Resources.LoadAssetAtPath(tilesetsPath, AutotileConfig)
            return autotileConfig

    public sets = AutotileSetDatabase()
    public animationSets = AutotileAnimationSetDatabase()
