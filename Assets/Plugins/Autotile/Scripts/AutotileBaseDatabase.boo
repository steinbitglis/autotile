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
    public material as Material

    [System.NonSerialized]
    public preview as Texture2D

    [System.NonSerialized]
    public showRemoveOption = false

    abstract def Duplicate() as AutotileBaseSet:
        pass
