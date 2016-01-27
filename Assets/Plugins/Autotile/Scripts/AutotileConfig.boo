import UnityEngine

class AutotileConfig (ScriptableObject):

    static public final tilesetsPath = "Assets/Resources/Autotile/Tilesets.asset"
    static private autotileConfig as AutotileConfig

    static config as AutotileConfig:
        get:
            unless autotileConfig:
                if tilesetsPath =~ @/^Assets\/Resources\//:
                    extension = System.IO.Path.GetExtension(tilesetsPath)
                    target = (tilesetsPath[17:])[:-extension.Length] # Resources.Load requires path relative to 'Assets/Resources' minus extension
                    autotileConfig = Resources.Load(target, AutotileConfig)
                else:
                    ifdef UNITY_EDITOR:
                        autotileConfig = UnityEditor.AssetDatabase.LoadAssetAtPath(tilesetsPath, AutotileConfig)
                    ifdef not UNITY_EDITOR:
                        pass
            return autotileConfig

    public sets = AutotileSetDatabase()
    public animationSets = AutotileAnimationSetDatabase()
