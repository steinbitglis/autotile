import UnityEngine
import System.Collections

[RequireComponent(MeshRenderer), RequireComponent(MeshFilter), ExecuteInEditMode]
class AutotileAnimation (AutotileBase):

    def OnDrawGizmos():
        Gizmos.DrawIcon(transform.position, "AutotileAnimation.png", true)

    public currentFrame = 0
    public frameDuration = 1f

    [System.NonSerialized]
    private lastTime = 0f

    override def Awake():
        super()
        frameDuration = 1f / Mathf.Max(0.01f, AutotileConfig.config.animationSets[tilesetKey].framesPerSecond)
        ifdef UNITY_EDITOR:
            unless Application.isPlaying:
                applied_non_serialized_scale = applied_scale
                mf = GetComponent of MeshFilter()
                sm = mf.sharedMesh
                if sm:
                    for t in FindObjectsOfType(AutotileAnimation):
                        if t != self and sm == t.GetComponent of MeshFilter().sharedMesh:
                            mf.sharedMesh = Mesh()
                            unsavedMesh = true
                            dirty = true
                            break
                else:
                    mf.mesh = Mesh()
                    unsavedMesh = true
                    dirty = true

                Refresh()

    override def Update():
        super()
        # if Time.time > lastTime + frameDuration:
        #     currentFrame %= int.MaxValue
        #     currentFrame += 1
        #     lastTime = Time.time
        #     RefreshUVS()

    def Reset():
        GetComponent of MeshFilter().sharedMesh = Mesh()
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

    def ApplyHorizontalTile():
        unless Mathf.Abs(transform.localScale.x) < 0.001f:
            left = getLeftCorner()
            right = getRightCorner()
            mf = GetComponent of MeshFilter()
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.doubleHorizontalVertices)
            mf.sharedMesh.triangles = AutotileBase.doubleTriangles
            mf.sharedMesh.uv = AutotileBase.TileUVs(left) + AutotileBase.TileUVs(right)
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true

    def ApplyLongTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, AnimationTile]], direction as TileDirection):
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

        if draw_first_corner:
            firstSplit = -0.5f + cornerSize
            vertices = TileSlice(-0.5f, firstSplit, direction)
            uvs = AutotileBase.TileUVs(left)
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
                    uvs += AutotileBase.TileUVs(tile, fractionOfTile, direction)
                else:
                    nextSplit = currentSplit + splitWidth * tileWidth
                    vertices += TileSlice(currentSplit, nextSplit, direction)
                    uvs += AutotileBase.TileUVs(tile)

                tilesSpent += 1
                currentSplit = nextSplit

        if draw_last_corner:
            vertices += TileSlice(lastSplit, 0.5f, direction)
            uvs += AutotileBase.TileUVs(right)
            tilesSpent += 1

        mf = GetComponent of MeshFilter()
        mf.sharedMesh.Clear()
        mf.sharedMesh.vertices = vertices
        mf.sharedMesh.triangles = array(int, (i for i in range(6 * tilesSpent)))
        mf.sharedMesh.uv = uvs
        mf.sharedMesh.RecalculateNormals()
        mf.sharedMesh.RecalculateBounds()
        unsavedMesh = true

    def ApplyHorizontalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, AnimationTile]]):
        ApplyLongTile(centerTiles, TileDirection.Horizontal)

    def ApplyVerticalTile():
        unless Mathf.Abs(transform.localScale.y) < 0.001f:
            bottom = getBottomCorner()
            top = getTopCorner()
            mf = GetComponent of MeshFilter()
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.doubleVerticalVertices)
            mf.sharedMesh.triangles = AutotileBase.doubleTriangles
            mf.sharedMesh.uv = AutotileBase.TileUVs(bottom) + AutotileBase.TileUVs(top)
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true

    def ApplyVerticalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, AnimationTile]]):
        ApplyLongTile(centerTiles, TileDirection.Vertical)

    def ApplyTile(tile as Tile):
        uvs = AutotileBase.TileUVs(tile)
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

    def getCentricCorner() as Tile:
        return AutotileConfig.config.animationSets[tilesetKey].corners.center[0]

    def getRightCorner() as Tile:
        return AutotileConfig.config.animationSets[tilesetKey].corners.right[0]

    def getLeftCorner() as Tile:
        return AutotileConfig.config.animationSets[tilesetKey].corners.left[0]

    def getTopCorner() as Tile:
        return AutotileConfig.config.animationSets[tilesetKey].corners.top[0]

    def getBottomCorner() as Tile:
        return AutotileConfig.config.animationSets[tilesetKey].corners.bottom[0]

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
            ApplyTile(getCentricCorner())
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return


    private def DescendingHorizontalFaces(animationSet as string) as Generic.IEnumerable[of Generic.KeyValuePair[of int, AnimationTile]]:
        tileset = Generic.SortedDictionary[of int, AnimationTile](Autotile.Descending())
        for kv as Generic.KeyValuePair[of int, AutotileAnimationTileset] in AutotileConfig.config.animationSets[animationSet].sets:
            tileset[kv.Key] = kv.Value.horizontalFaces[currentFrame]
        return tileset

    private def DescendingVerticalFaces(animationSet as string) as Generic.IEnumerable[of Generic.KeyValuePair[of int, AnimationTile]]:
        tileset = Generic.SortedDictionary[of int, AnimationTile](Autotile.Descending())
        for kv as Generic.KeyValuePair[of int, AutotileAnimationTileset] in AutotileConfig.config.animationSets[animationSet].sets:
            tileset[kv.Key] = kv.Value.verticalFaces[currentFrame]
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
