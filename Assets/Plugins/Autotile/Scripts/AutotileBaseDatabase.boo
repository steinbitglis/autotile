enum UVMarginMode:
    NoMargin
    HalfPixel

[System.Serializable]
class AutotileBaseSet:
    [System.NonSerialized]
    public name = ""
    [System.NonSerialized]
    public show = false

    [System.NonSerialized]
    public newCandidate = 2

    [System.NonSerialized]
    public showDuplicateOption = false
    [System.NonSerialized]
    public duplicateCandidate = ""

    [System.NonSerialized]
    public showSettings = false
    public tileSize = 128
    public uvMarginMode as UVMarginMode

    [System.NonSerialized]
    public _materialCache as Material
    public _material as Material
    material as Material:
        get:
            ifdef UNITY_EDITOR:
                if materialAvailableInRuntime:
                    unless _material:
                        _material = UnityEditor.AssetDatabase.LoadAssetAtPath(UnityEditor.AssetDatabase.GUIDToAssetPath(materialGUID), Material)
                    return _material
                else:
                    unless _materialCache:
                        _materialCache = UnityEditor.AssetDatabase.LoadAssetAtPath(UnityEditor.AssetDatabase.GUIDToAssetPath(materialGUID), Material)
                    return _materialCache
            ifdef not UNITY_EDITOR:
                return _material
        set:
            ifdef UNITY_EDITOR:
                _materialCache = value
                _material = value if materialAvailableInRuntime
                materialGUID = UnityEditor.AssetDatabase.AssetPathToGUID(UnityEditor.AssetDatabase.GetAssetPath(value))
            ifdef not UNITY_EDITOR:
                _material = value

    public materialGUID as string

    materialAvailableInRuntime as bool:
        get:
            return _materialAvailableInRuntime
        set:
            if value:
                ifdef UNITY_EDITOR:
                    if materialGUID:
                        _material = UnityEditor.AssetDatabase.LoadAssetAtPath(UnityEditor.AssetDatabase.GUIDToAssetPath(materialGUID), Material)
                ifdef not UNITY_EDITOR:
                    pass
            else:
                _material = null
            _materialAvailableInRuntime = value
    public _materialAvailableInRuntime = true

    [System.NonSerialized]
    public preview as Texture2D

    [System.NonSerialized]
    public showRemoveOption = false

    abstract def Duplicate() as AutotileBaseSet:
        pass

    public def ReadGUID():
        ifdef UNITY_EDITOR:
            materialGUID = UnityEditor.AssetDatabase.AssetPathToGUID(UnityEditor.AssetDatabase.GetAssetPath(material))
        ifdef not UNITY_EDITOR:
            pass
