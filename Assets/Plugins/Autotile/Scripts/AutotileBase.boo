import UnityEngine

enum AutotileBaseCorner:
    Left = 1
    Right = 2
    Bottom = 4
    Top = 8

class AutotileAnathomy:

    public drawsLeft as bool
    public drawsRight as bool
    public drawsBottom as bool
    public drawsTop as bool
    public drawsCenter as bool

    def constructor(left as bool, right as bool, bottom as bool, top as bool, center as bool):
        drawsLeft   = left
        drawsRight  = right
        drawsBottom = bottom
        drawsTop    = top
        drawsCenter = center

    def constructor(other as AutotileAnathomy):
        drawsLeft   = other.drawsLeft
        drawsRight  = other.drawsRight
        drawsBottom = other.drawsBottom
        drawsTop    = other.drawsTop
        drawsCenter = other.drawsCenter

    def Equals(other as AutotileAnathomy):
        return other.drawsLeft   == drawsLeft and\
               other.drawsRight  == drawsRight and\
               other.drawsBottom == drawsBottom and\
               other.drawsTop    == drawsTop and\
               other.drawsCenter == drawsCenter

class AutotileBase (MonoBehaviour):

    public static allAutotileBases = System.Collections.Generic.List of AutotileBase()

    virtual def Awake():
        localRenderer = renderer
        allAutotileBases.Add(self) unless self in allAutotileBases

    virtual def OnDestroy():
        allAutotileBases.Remove(self)

    public tilesetKey = ""
    public tileMode as TileMode
    public secondaryTileMode = TileMode.Centric
    public squeezeMode = SqueezeMode.Clip

    [System.NonSerialized]
    public localRenderer as MeshRenderer

    public useCorner = AutotileBaseCorner.Left | AutotileBaseCorner.Right | AutotileBaseCorner.Bottom | AutotileBaseCorner.Top

    useLeftCorner as bool:
        get:
            return true if useCorner & AutotileBaseCorner.Left
            return false
    useRightCorner as bool:
        get:
            return true if useCorner & AutotileBaseCorner.Right
            return false
    useBottomCorner as bool:
        get:
            return true if useCorner & AutotileBaseCorner.Bottom
            return false
    useTopCorner as bool:
        get:
            return true if useCorner & AutotileBaseCorner.Top
            return false

    [System.NonSerialized]
    public preview as Texture2D
    [System.NonSerialized]
    public previewTileMode as TileMode

    previewAnathomy as AutotileAnathomy:
        get:
            return _previewAnathomy if _previewAnathomy
            _previewAnathomy = AutotileAnathomy(DrawsLeftCorner(), DrawsRightCorner(), DrawsBottomCorner(), DrawsTopCorner(), DrawsCenterCorner())
            return _previewAnathomy
        set:
            _previewAnathomy = value
    private _previewAnathomy as AutotileAnathomy

    abstract def DrawsLeftCorner() as bool:
        pass
    abstract def DrawsRightCorner() as bool:
        pass
    abstract def DrawsBottomCorner() as bool:
        pass
    abstract def DrawsTopCorner() as bool:
        pass

    def DrawsCenterCorner() as bool:
        if tileMode == TileMode.Horizontal:
            return applied_discrete_width > CornersNeeded()
        else:
            return applied_discrete_height > CornersNeeded()

    def CornersNeeded() as int:
        h_corners = 1 if DrawsLeftCorner()
        h_corners += 1 if DrawsRightCorner()
        v_corners = 1 if DrawsBottomCorner()
        v_corners += 1 if DrawsTopCorner()

        if tileMode == TileMode.Horizontal:
            return h_corners
        elif tileMode == TileMode.Vertical:
            return v_corners
        elif h_corners or v_corners:
            return 1
        else:
            return 0

    public offset as Vector3
    [SerializeField]
    protected _offsetMode = OffsetMode.Center

    [System.NonSerialized]
    public dirty = false
    [System.NonSerialized]
    public unsaved = false
    [System.NonSerialized]
    public unsavedMesh = false

    [SerializeField]
    protected applied_use_corner = AutotileBaseCorner.Left | AutotileBaseCorner.Right | AutotileBaseCorner.Bottom | AutotileBaseCorner.Top
    [SerializeField]
    protected applied_tileset_key = ""
    [SerializeField]
    protected applied_scale = Vector3.one
    [System.NonSerialized]
    protected applied_non_serialized_scale = Vector3.one
    [SerializeField]
    protected applied_discrete_width = 1
    [SerializeField]
    protected applied_discrete_height = 1
    [SerializeField]
    protected applied_offset = Vector3.zero

    public static final singleVertices = (
            Vector3(-0.5f, -0.5f), Vector3(-0.5f,  0.5f), Vector3( 0.5f,  0.5f),
            Vector3( 0.5f,  0.5f), Vector3( 0.5f, -0.5f), Vector3(-0.5f, -0.5f),)
    public static final doubleHorizontalVertices = (
            Vector3(-0.5f, -0.5f),  Vector3(-0.5f,  0.5f),  Vector3( 0.0f,  0.5f),
            Vector3( 0.0f,  0.5f),  Vector3( 0.0f, -0.5f),  Vector3(-0.5f, -0.5f),
            Vector3( 0.0f, -0.5f),  Vector3( 0.0f,  0.5f),  Vector3( 0.5f,  0.5f),
            Vector3( 0.5f,  0.5f),  Vector3( 0.5f, -0.5f),  Vector3( 0.0f, -0.5f),)
    public static final doubleVerticalVertices = (
            Vector3(-0.5f, -0.5f),  Vector3(-0.5f,  0.0f),  Vector3( 0.5f,  0.0f),
            Vector3( 0.5f,  0.0f),  Vector3( 0.5f, -0.5f),  Vector3(-0.5f, -0.5f),
            Vector3(-0.5f,  0.0f),  Vector3(-0.5f,  0.5f),  Vector3( 0.5f,  0.5f),
            Vector3( 0.5f,  0.5f),  Vector3( 0.5f,  0.0f),  Vector3(-0.5f,  0.0f),)
    public static final singleTriangles = ( 0, 1, 2, 3, 4, 5, )
    public static final doubleTriangles = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, )
    public static final tripleTriangles = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, )

    offsetMode as OffsetMode:
        set:
            _offsetMode = value
            prev_offset = offset

            transform.position = transform.TransformPoint(offset)
            if value == OffsetMode.Left:
                offset = Vector3( 0.5f, 0.0f)
            elif value == OffsetMode.Right:
                offset = Vector3(-0.5f, 0.0f)
            elif value == OffsetMode.Top:
                offset = Vector3( 0.0f,-0.5f)
            elif value == OffsetMode.Bottom:
                offset = Vector3( 0.0f, 0.5f)
            elif value == OffsetMode.Center:
                offset = Vector3( 0.0f, 0.0f)
            transform.position = transform.TransformPoint(-offset)

            delta = offset - prev_offset
            for t in GetComponentsInChildren of Transform(true):
                unless t == transform:
                    t.localPosition += delta
        get:
            return _offsetMode

    virtual def Update():
        ifdef UNITY_EDITOR:
            pos = transform.localPosition
            unless pos.z == 0.0f:
                pos.z = 0.0f
                transform.localPosition = pos

    protected static def TileUVs(t as Tile, margin as Vector2) as (Vector2):
        return TileUVs(t, 1.0f, TileDirection.Horizontal, margin)

    protected static def TileUVs(t as Tile, fraction as single, direction as TileDirection, margin as Vector2) as (Vector2):
        orthogonal_source =  t.rotated and\
            (t.rotation == TileRotation.CW or\
             t.rotation == TileRotation.CCW)

        if orthogonal_source:
            backwards_source = t.flipped and (direction == TileDirection.Vertical   and t.direction == TileFlipDirection.Horizontal or\
                                              direction == TileDirection.Horizontal and t.direction == TileFlipDirection.Vertical)
            rotation_flip = t.rotated and t.rotation == TileRotation.CCW
        else:
            backwards_source = t.flipped and (direction == TileDirection.Horizontal and t.direction == TileFlipDirection.Horizontal or\
                                              direction == TileDirection.Vertical   and t.direction == TileFlipDirection.Vertical)
            rotation_flip = t.rotated and t.rotation == TileRotation._180

        reversed_fractions = backwards_source != rotation_flip # XOR equivalent

        if reversed_fractions:
            if (direction == TileDirection.Horizontal) != orthogonal_source:
                xMin = fraction * t.atlasLocation.xMin + (1.0f - fraction) * t.atlasLocation.xMax + margin.x
                xMax = t.atlasLocation.xMax - margin.x
                yMin = t.atlasLocation.yMin + margin.y
                yMax = t.atlasLocation.yMax - margin.y
            else:
                xMin = t.atlasLocation.xMin + margin.x
                xMax = t.atlasLocation.xMax - margin.x
                yMin = fraction * t.atlasLocation.yMin + (1.0f - fraction) * t.atlasLocation.yMax + margin.y
                yMax = t.atlasLocation.yMax - margin.y
        else:
            if (direction == TileDirection.Horizontal) != orthogonal_source:
                xMin = t.atlasLocation.xMin + margin.x
                xMax = (1.0f - fraction) * xMin + fraction * t.atlasLocation.xMax - margin.x
                yMin = t.atlasLocation.yMin + margin.y
                yMax = t.atlasLocation.yMax - margin.y
            else:
                xMin = t.atlasLocation.xMin + margin.x
                xMax = t.atlasLocation.xMax - margin.x
                yMin = t.atlasLocation.yMin + margin.y
                yMax = (1.0f - fraction) * yMin + fraction * t.atlasLocation.yMax - margin.y
        if t.flipped:
            if t.direction == TileFlipDirection.Horizontal:
                result = (
                    Vector2(xMax, yMin),
                    Vector2(xMax, yMax),
                    Vector2(xMin, yMax),
                    Vector2(xMin, yMax),
                    Vector2(xMin, yMin),
                    Vector2(xMax, yMin),)
            elif t.direction == TileFlipDirection.Vertical:
                result = (
                    Vector2(xMin, yMax),
                    Vector2(xMin, yMin),
                    Vector2(xMax, yMin),
                    Vector2(xMax, yMin),
                    Vector2(xMax, yMax),
                    Vector2(xMin, yMax),)
            else: # Both
                result = (
                    Vector2(xMax, yMax),
                    Vector2(xMax, yMin),
                    Vector2(xMin, yMin),
                    Vector2(xMin, yMin),
                    Vector2(xMin, yMax),
                    Vector2(xMax, yMax),)
        else:
            result = (
                Vector2(xMin, yMin),
                Vector2(xMin, yMax),
                Vector2(xMax, yMax),
                Vector2(xMax, yMax),
                Vector2(xMax, yMin),
                Vector2(xMin, yMin),)
        if t.rotated:
            if t.rotation == TileRotation.CW:
                return (result[1], result[2], result[4], result[4], result[5], result[1])
            elif t.rotation == TileRotation.CCW:
                return (result[4], result[5], result[1], result[1], result[2], result[4])
            else:
                return (result[3], result[4], result[5], result[0], result[1], result[2])
        else:
            return result

    def OffsetVertices2(vertices as (Vector2)) as (Vector2):
        return array(Vector2, (Vector2(offset.x + v.x, offset.y + v.y) for v in vertices))

    def OffsetVertices2(vertices as (Vector3)) as (Vector2):
        return array(Vector2, (offset + v for v in vertices))

    def OffsetVertices(vertices as (Vector3)) as (Vector3):
        return array(Vector3, (offset + v for v in vertices))

    def OffsetPosition() as Vector3:
        return transform.TransformPoint(offset)

    def TileSlice(low as single, high as single, d as TileDirection) as (Vector3):
        if d == TileDirection.Horizontal:
            return OffsetVertices((
                Vector3(low,  -0.5f),  Vector3(low,   0.5f),  Vector3(high,  0.5f),
                Vector3(high,  0.5f),  Vector3(high, -0.5f),  Vector3(low,  -0.5f),))
        else:
            return OffsetVertices((
                Vector3(-0.5f, low),  Vector3(-0.5f, high), Vector3( 0.5f, high),
                Vector3( 0.5f, high), Vector3( 0.5f, low),  Vector3(-0.5f, low),))

    def ApplyUseCorner():
        if applied_use_corner != useCorner:
            applied_use_corner = useCorner
            dirty = true

    def ApplyOffset():
        if applied_offset != offset:
            applied_offset = offset
            dirty = true

    virtual def ApplyTilesetKey():
        if applied_tileset_key != tilesetKey:
            applied_tileset_key = tilesetKey
            dirty = true

    abstract def ApplyScale():
        pass

    abstract def SuggestScales() as Vector3:
        pass

    virtual def Refresh():
        ApplyTilesetKey()
        ApplyOffset()
        ApplyUseCorner()
        ApplyScale()

    [ContextMenu("Force Rebuild")]
    def Rebuild():
        dirty = true
        transform.localScale = SuggestScales()
        Refresh()
