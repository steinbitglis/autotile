import UnityEngine

class AutotileConfig (ScriptableObject):

    static private autotileConfig as AutotileConfig

    static config as AutotileConfig:
        get:
            unless autotileConfig:
                autotileConfig = Resources.LoadAssetAtPath("Assets/Plugins/Autotile/Tilesets.asset", AutotileConfig)
            return autotileConfig

    public sets = AutotileSetDatabase()
    public animationSets = AutotileAnimationSetDatabase()
