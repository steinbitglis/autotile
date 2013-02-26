import UnityEngine
import System.Collections

macro defCorner(cornerType as Boo.Lang.Compiler.Ast.ReferenceExpression):
    fnName = Boo.Lang.Compiler.Ast.ReferenceExpression("get" + cornerType.Name[0:1].ToUpper() + cornerType.Name[1:] + "Corner")
    yield [|
        private def $fnName() as UVAnimation:
            animSet = AutotileConfig.config.animationSets[tilesetKey]
            framesPerSecond = animSet.framesPerSecond
            sources = animSet.corners.$cornerType
            result = UVAnimation(array(UVFrame, sources.Length))
            for i as int, s as AnimationTile in enumerate(sources):
                result.frames[i] = UVFrame(s.frames, AutotileBase.TileUVs(s, uvMargin))
            return result
    |]

[RequireComponent(MeshRenderer), RequireComponent(MeshFilter), ExecuteInEditMode]
class AutotileAnimation (AutotileBase):

    def OnDrawGizmos():
        if tileMode == TileMode.Horizontal:
            if _offsetMode == OffsetMode.Right:
                Gizmos.DrawIcon(transform.position, "Autotile/h_l.png", true)
            elif _offsetMode == OffsetMode.Left:
                Gizmos.DrawIcon(transform.position, "Autotile/h_r.png", true)
            else:
                Gizmos.DrawIcon(transform.position, "Autotile/h.png", true)
        elif tileMode == TileMode.Vertical:
            if _offsetMode == OffsetMode.Top:
                Gizmos.DrawIcon(transform.position, "Autotile/v_d.png", true)
            elif _offsetMode == OffsetMode.Bottom:
                Gizmos.DrawIcon(transform.position, "Autotile/v_u.png", true)
            else:
                Gizmos.DrawIcon(transform.position, "Autotile/v.png", true)
        else:
            if _offsetMode == OffsetMode.Right:
                Gizmos.DrawIcon(transform.position, "Autotile/c_l.png", true)
            elif _offsetMode == OffsetMode.Left:
                Gizmos.DrawIcon(transform.position, "Autotile/c_r.png", true)
            elif _offsetMode == OffsetMode.Top:
                Gizmos.DrawIcon(transform.position, "Autotile/c_d.png", true)
            elif _offsetMode == OffsetMode.Bottom:
                Gizmos.DrawIcon(transform.position, "Autotile/c_u.png", true)
            else:
                Gizmos.DrawIcon(transform.position, "Autotile/c.png", true)

    public currentFrame = 0

    [System.NonSerialized]
    private lastTime = 0f

    framesPerSecond as single:
        set:
            unless _useFramerateOverride:
                _frameDuration = 1f / Mathf.Max(0.01f, value)
            _framesPerSecond = value
        get:
            return _framesPerSecond

    framerateOverride as single:
        set:
            if _useFramerateOverride:
                _frameDuration = 1f / Mathf.Max(0.01f, value)
            _framerateOverride = value
        get:
            return _framerateOverride

    useFramerateOverride as bool:
        set:
            if value:
                _frameDuration = 1f / Mathf.Max(0.01f, _framerateOverride)
            else:
                _frameDuration = 1f / Mathf.Max(0.01f, _framesPerSecond)
            _useFramerateOverride = value
        get:
            return _useFramerateOverride

    public _frameDuration = 1f
    public _framesPerSecond = 50f
    public _framerateOverride = 50f
    public _useFramerateOverride = false

    public localMesh as Mesh

    uvMargin as Vector2:
        get:
            config = AutotileConfig.config.animationSets[tilesetKey]
            if config.uvMarginMode == UVMarginMode.HalfPixel:
                mt = config.material.mainTexture
                return Vector2(.5f/mt.width, .5f/mt.height)
            else:
                return Vector2.zero

    [SerializeField]
    protected applied_margin_mode = UVMarginMode.NoMargin

    def tryLoadFramesPerSecond():
        try:
            framesPerSecond = AutotileConfig.config.animationSets[tilesetKey].framesPerSecond
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    override def Awake():
        super()
        ifdef UNITY_EDITOR:
            tryLoadFramesPerSecond()
            unless Application.isPlaying:
                applied_non_serialized_scale = applied_scale
                mf = GetComponent of MeshFilter()
                sm = mf.sharedMesh
                if sm:
                    for t in FindObjectsOfType(AutotileAnimation):
                        if t != self and sm == t.GetComponent of MeshFilter().sharedMesh:
                            localMesh = Mesh()
                            mf.sharedMesh = localMesh
                            unsavedMesh = true
                            dirty = true
                            break
                else:
                    localMesh = Mesh()
                    mf.mesh = localMesh
                    unsavedMesh = true
                    dirty = true

                Refresh()

    override def Update():
        super()
        if Time.time > lastTime + _frameDuration:
            lastTime = Time.time
            localMesh.uv = cache.next_uvs()
            currentFrame = (currentFrame + 1) % cache.lcm

    def Reset():
        localMesh = Mesh()
        GetComponent of MeshFilter().sharedMesh = localMesh
        unsavedMesh = true
        ApplyCentric()

    override def DrawsLeftCorner() as bool:
        return true
    override def DrawsRightCorner() as bool:
        return true
    override def DrawsBottomCorner() as bool:
        return true
    override def DrawsTopCorner() as bool:
        return true


    ## ---- UV Building ---- ##

    private class UVFrame:
        # /---\
        # |   |  One frame
        # \---/
        public duration as int
        public uvs as (Vector2)

        def constructor(d as int, u as (Vector2)):
            duration = d
            uvs = u

    private class UVAnimation:
        # /---\
        # | ~ |  One animation
        # \---/
        public frames as (UVFrame)

        totalLength as int:
            get:
                sum = 0
                for f in frames:
                    sum += f.duration
                return sum

        def constructor(f as (UVFrame)):
            frames = f

        def unrolledUVs(dist as int) as ((Vector2)):
            uvs = List[of (Vector2)]()
            for f in frames:
                for _ in range(f.duration):
                    uvs.Add(f.uvs)
            current = 0
            localDist = uvs.Count
            result = List[of (Vector2)]()
            for _ in range(dist):
                result.Add(uvs[current])
                current = (current + 1) % localDist
            return array(typeof((Vector2)), result)

    private class UVAnimationCache:
        # /---+-------+-------+---\
        # | ~ |   ~   |   ~   | ~ |  One complete tile animation
        # \---+-------+-------+---/
        [Getter(lcm)]
        private _lcm as int
        private currentFrame as int
        private built as bool
        private uvs as ((Vector2))

        private def _build():
            built = true
            _lcm = MathUtil.LCM(array(int, (a.totalLength for a in _animations)))

            by_animation = array(typeof(((Vector2))), _animations.Length)
            for i as int, v as UVAnimation in enumerate(_animations):
                by_animation[i] = v.unrolledUVs(_lcm)

            all_animations = List[of (Vector2)]()
            for i in range(_lcm):
                all_uv_coords = List of Vector2()
                for f in by_animation:
                    for v in f[i]:
                        all_uv_coords.Add(v)
                all_animations.Add(array(Vector2, all_uv_coords))
            uvs = array(typeof((Vector2)), all_animations)

        animations as (UVAnimation):
            set:
                _animations = value
                built = false

        [SerializeField]
        private _animations as (UVAnimation)

        def next_uvs() as (Vector2):
            _build() unless built
            result = uvs[currentFrame]
            currentFrame = (currentFrame + 1) % _lcm
            return result

    [SerializeField]
    private cache = UVAnimationCache()

    ## -- UV Building End -- ##

    protected static def TileUVs(t as (AnimationTile), margin as Vector2) as UVAnimation:
        return TileUVs(t, 1.0f, TileDirection.Horizontal, margin)

    protected static def TileUVs(t as (AnimationTile), fraction as single, direction as TileDirection, margin as Vector2) as UVAnimation:
        result = UVAnimation(array(UVFrame, t.Length))
        for i as int, s as AnimationTile in enumerate(t):
            result.frames[i] = UVFrame(s.frames, AutotileBase.TileUVs(s, fraction, direction, margin))
        return result

    def ApplyLongTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, (AnimationTile)]], direction as TileDirection):
        if direction == TileDirection.Horizontal:
            width = transform.localScale.x
            draw_first_corner = DrawsLeftCorner() and useLeftCorner
            draw_last_corner = DrawsRightCorner() and useRightCorner
            left = getLeftCorner() if draw_first_corner
            right = getRightCorner() if draw_last_corner
        else:
            width = transform.localScale.y
            draw_first_corner = DrawsBottomCorner() and useBottomCorner
            draw_last_corner = DrawsTopCorner() and useTopCorner
            left = getBottomCorner() if draw_first_corner
            right = getTopCorner() if draw_last_corner

        if_00_01_10_11 draw_first_corner, draw_last_corner:
            spareSpace = width
            spareSpace = width - 1.0f
            spareSpace = width - 1.0f
            spareSpace = width - 2.0f

        smallestKey = AutotileConfig.config.animationSets[tilesetKey].sets.smallestKey

        if squeezeMode == SqueezeMode.Clip:
            centerUnits = Mathf.Ceil(spareSpace) cast int
        else:
            centerUnits = smallestKey * Mathf.Round(spareSpace / smallestKey) cast int
            centerUnits = Mathf.Max(smallestKey, centerUnits)

        cornerSize = 1f / width

        allFrames = List of UVAnimation()
        if draw_first_corner:
            firstSplit = -0.5f + cornerSize
            vertices = TileSlice(-0.5f, firstSplit, direction)
            uvs = left.frames[0].uvs
            allFrames.Add(left)
            tilesSpent = 1
        else:
            firstSplit = -0.5f
            vertices = array(Vector3, 0)
            uvs = array(Vector2, 0)
            tilesSpent = 0

        if draw_last_corner:
            lastSplit =   0.5f - cornerSize
        else:
            lastSplit =   0.5f

        if squeezeMode == SqueezeMode.Clip:
            splitWidth = Mathf.Ceil(spareSpace) / (width * centerUnits)
        else:
            splitWidth = spareSpace / (width * centerUnits)

        currentSplit = firstSplit
        currentSplitIndex = 0
        ctEnumerator = centerTiles.GetEnumerator()
        enumeratorHealthy = ctEnumerator.MoveNext()

        while currentSplitIndex < centerUnits and enumeratorHealthy:
            max_splits_to_use = centerUnits - currentSplitIndex
            tileWidth = ctEnumerator.Current.Key
            tile = ctEnumerator.Current.Value
            if tileWidth > max_splits_to_use and not tileWidth == smallestKey:
                enumeratorHealthy = ctEnumerator.MoveNext()
            else:
                currentSplitIndex += tileWidth
                if currentSplitIndex >= centerUnits:
                    if squeezeMode == SqueezeMode.Clip:
                        fractionOfTile = (lastSplit - currentSplit) / (splitWidth * tileWidth)
                    else:
                        fractionOfTile = 1.0f
                    vertices += TileSlice(currentSplit, lastSplit, direction)
                    anim = TileUVs(tile, fractionOfTile, direction, uvMargin)
                    uvs += anim.frames[0].uvs
                    allFrames.Add(anim)
                else:
                    nextSplit = currentSplit + splitWidth * tileWidth
                    vertices += TileSlice(currentSplit, nextSplit, direction)
                    anim = TileUVs(tile, uvMargin)
                    uvs += anim.frames[0].uvs
                    allFrames.Add(anim)

                tilesSpent += 1
                currentSplit = nextSplit

        if draw_last_corner:
            vertices += TileSlice(lastSplit, 0.5f, direction)
            uvs += right.frames[0].uvs
            allFrames.Add(right)
            tilesSpent += 1

        cache.animations = array(UVAnimation, allFrames)
        mf = GetComponent of MeshFilter()
        mf.sharedMesh.Clear()
        mf.sharedMesh.vertices = vertices
        mf.sharedMesh.triangles = array(int, (i for i in range(6 * tilesSpent)))
        mf.sharedMesh.uv = uvs
        mf.sharedMesh.RecalculateNormals()
        mf.sharedMesh.RecalculateBounds()
        unsavedMesh = true

    def ApplyHorizontalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, (AnimationTile)]]):
        ApplyLongTile(centerTiles, TileDirection.Horizontal)

    def ApplyHorizontalTile():
        unless Mathf.Abs(transform.localScale.x) < 0.001f:
            left = getLeftCorner()
            right = getRightCorner()
            cache.animations = (left, right)
            mf = GetComponent of MeshFilter()
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.doubleHorizontalVertices)
            mf.sharedMesh.triangles = AutotileBase.doubleTriangles
            mf.sharedMesh.uv = left.frames[0].uvs + right.frames[0].uvs
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true

    def ApplyVerticalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, (AnimationTile)]]):
        ApplyLongTile(centerTiles, TileDirection.Vertical)

    def ApplyVerticalTile():
        unless Mathf.Abs(transform.localScale.y) < 0.001f:
            bottom = getBottomCorner()
            top = getTopCorner()
            cache.animations = (bottom, top)
            mf = GetComponent of MeshFilter()
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.doubleVerticalVertices)
            mf.sharedMesh.triangles = AutotileBase.doubleTriangles
            mf.sharedMesh.uv = bottom.frames[0].uvs + top.frames[0].uvs
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true

    def ApplyTile(tile as (AnimationTile)):
        anim = TileUVs(tile, uvMargin)
        cache.animations = (anim,)
        uvs = anim.frames[0].uvs
        mf = GetComponent of MeshFilter()
        if mf.sharedMesh:
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.singleVertices)
            mf.sharedMesh.triangles = AutotileBase.singleTriangles
            mf.sharedMesh.uv = uvs
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true

    def CanScaleToCentric():
        return false unless CornersNeeded()
        return true

    def getCenterLength() as int:
        if tileMode == TileMode.Horizontal:
            if applied_discrete_width > CornersNeeded():
                return AutotileConfig.config.animationSets[tilesetKey].sets.smallestKey
            else:
                return 0
        else: # if tileMode == TileMode.Vertical:
            if applied_discrete_height > CornersNeeded():
                return AutotileConfig.config.animationSets[tilesetKey].sets.smallestKey
            else:
                return 0

    def getCenterPiece() as Tile:
        tileSet = AutotileConfig.config.animationSets[tilesetKey]
        db = tileSet.sets
        animationSet = db[db.smallestKey]
        if tileMode == TileMode.Horizontal:
            return animationSet.horizontalFaces[currentFrame]
        else: # if tileMode == TileMode.Vertical:
            return animationSet.verticalFaces[currentFrame]

    # defCorner centric
    defCorner right
    defCorner left
    defCorner top
    defCorner bottom

    def ApplyHorizontal(dim as int):
        try:
            tileMode = secondaryTileMode = TileMode.Horizontal
            if dim == 2 and useLeftCorner and useRightCorner:
                ApplyHorizontalTile()
            else:
                ApplyHorizontalTile(DescendingHorizontalFaces(tilesetKey))
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyVertical(dim as int):
        try:
            tileMode = secondaryTileMode = TileMode.Vertical
            if dim == 2 and useBottomCorner and useTopCorner:
                ApplyVerticalTile()
            else:
                ApplyVerticalTile(DescendingVerticalFaces(tilesetKey))
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyCentric():
        try:
            tileMode = TileMode.Centric
            animSet = AutotileConfig.config.animationSets[tilesetKey]
            framesPerSecond = animSet.framesPerSecond
            ApplyTile(animSet.corners.centric)
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return


    private def DescendingHorizontalFaces(animationSet as string) as Generic.IEnumerable[of Generic.KeyValuePair[of int, (AnimationTile)]]:
        tileset = Generic.SortedDictionary[of int, (AnimationTile)](Autotile.Descending())
        animSet = AutotileConfig.config.animationSets[animationSet]
        framesPerSecond = animSet.framesPerSecond
        for kv as Generic.KeyValuePair[of int, AutotileAnimationTileset] in animSet.sets:
            tileset[kv.Key] = kv.Value.horizontalFaces
        return tileset

    private def DescendingVerticalFaces(animationSet as string) as Generic.IEnumerable[of Generic.KeyValuePair[of int, (AnimationTile)]]:
        tileset = Generic.SortedDictionary[of int, (AnimationTile)](Autotile.Descending())
        animSet = AutotileConfig.config.animationSets[animationSet]
        framesPerSecond = animSet.framesPerSecond
        for kv as Generic.KeyValuePair[of int, AutotileAnimationTileset] in animSet.sets:
            tileset[kv.Key] = kv.Value.verticalFaces
        return tileset

    override def ApplyScale():
        x = Mathf.Max(1f, Mathf.Round(transform.localScale.x)) cast int
        y = Mathf.Max(1f, Mathf.Round(transform.localScale.y)) cast int
        if squeezeMode == SqueezeMode.Clip:
            if transform.localScale.x > 2.0f:
                x = Mathf.Ceil(transform.localScale.x) cast int
            if transform.localScale.y > 2.0f:
                y = Mathf.Ceil(transform.localScale.y) cast int
        if applied_discrete_width != x and x > 0 or applied_discrete_height != y  and y > 0 or dirty:
            dirty = false
            unsaved = true

            applied_discrete_width = x
            applied_discrete_height = y
            applied_scale = transform.localScale
            applied_non_serialized_scale = transform.localScale

            if x == 1 and y == 1:
                if CanScaleToCentric():
                    ApplyCentric()
                elif tileMode == TileMode.Horizontal:
                    ApplyHorizontal(x)
                elif tileMode == TileMode.Vertical:
                    ApplyVertical(y)
            elif x == 1:
                ApplyVertical(y)
            elif y == 1:
                ApplyHorizontal(x)
        if x > 0 and y > 0 and\
           (applied_scale != transform.localScale or\
            applied_non_serialized_scale != transform.localScale):
            unsaved = true
            if x == 1 and y >= 2:
                ApplyVertical(y)
                applied_scale = transform.localScale
                applied_non_serialized_scale = transform.localScale
            elif y == 1 and x >= 2:
                ApplyHorizontal(x)
                applied_scale = transform.localScale
                applied_non_serialized_scale = transform.localScale

    override def SuggestScales() as Vector3:
        h = secondaryTileMode == TileMode.Horizontal
        v = secondaryTileMode == TileMode.Vertical
        centric = tileMode == TileMode.Centric
        c = transform.localScale.x if h
        c = transform.localScale.y if v
        d_c = Mathf.Round(c) cast int

        if d_c < 2 and CanScaleToCentric():
            c = 1.0f
        elif squeezeMode == SqueezeMode.Scale and d_c == 2 or c < 2.0f:
            c = 2.0f

        return Vector3(   c, 1.0f, 1.0f) if h
        return Vector3(1.0f,    c, 1.0f) if v
        return Vector3.one if centric
        return transform.localScale

    override def OnDestroy():
        super()
        DestroyImmediate( GetComponent of MeshFilter().sharedMesh, true )

    override def ApplyTilesetKey():
        super()
        tryLoadFramesPerSecond()

    def ApplyMarginMode():
        return unless AutotileConfig.config.animationSets.ContainsKey(tilesetKey)
        real_margine_mode = AutotileConfig.config.animationSets[tilesetKey].uvMarginMode
        if applied_margin_mode != real_margine_mode:
            applied_margin_mode = real_margine_mode
            dirty = true

    override def Refresh():
        ApplyMarginMode()
        super()
