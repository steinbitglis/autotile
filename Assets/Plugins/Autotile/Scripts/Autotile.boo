import UnityEngine
import System.Collections

macro descending_faces(faceType as Boo.Lang.Compiler.Ast.ReferenceExpression):
    fnName = Boo.Lang.Compiler.Ast.ReferenceExpression("Descending" + faceType.Name[0:1].ToUpper() + faceType.Name[1:] + "Faces")
    faceName = Boo.Lang.Compiler.Ast.ReferenceExpression(faceType.Name + "Face")
    yield [|
        private def $fnName(autotileset as string) as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]]:
            tileset = Generic.SortedDictionary[of int, Tile](Autotile.Descending())
            for kv as Generic.KeyValuePair[of int, AutotileCenterSet] in AutotileConfig.config.sets[autotileset].centerSets:
                tileset[kv.Key] = kv.Value.$faceName
            return tileset
    |]

enum TileMode:
    Horizontal
    Vertical
    Centric
    None

enum OffsetMode:
    Center
    Left
    Right
    Top
    Bottom

enum SqueezeMode:
    Clip
    Scale

class AutotileConnections (Generic.IEnumerable[of Autotile]):

    public left as Autotile
    public leftUp as Autotile
    public leftDown as Autotile
    public right as Autotile
    public rightUp as Autotile
    public rightDown as Autotile
    public up as Autotile
    public upLeft as Autotile
    public upRight as Autotile
    public down as Autotile
    public downLeft as Autotile
    public downRight as Autotile

    [HideInInspector]
    public reverse = (-1, -1, -1, -1,
                      -1, -1, -1, -1,
                      -1, -1, -1, -1)

    self[i as int] as Autotile:
        get:
            binary_search_autotile_connection i:
                return left
                return leftUp
                return leftDown
                return right
                return rightUp
                return rightDown
                return up
                return upLeft
                return upRight
                return down
                return downLeft
                return downRight
        set:
            binary_search_autotile_connection i:
                left = value
                leftUp = value
                leftDown = value
                right = value
                rightUp = value
                rightDown = value
                up = value
                upLeft = value
                upRight = value
                down = value
                downLeft = value
                downRight = value

    [System.NonSerialized]
    public autotileGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator[of Autotile]:
        yield left
        yield leftUp
        yield leftDown
        yield right
        yield rightUp
        yield rightDown
        yield up
        yield upLeft
        yield upRight
        yield down
        yield downLeft
        yield downRight

    def IEnumerable.GetEnumerator() as IEnumerator:
        return autotileGetEnumerator()

    # public connected as Generic.IEnumerator[of Autotile]:
    #     get:
    #         yield left if left
    #         yield leftUp if leftUp
    #         yield leftDown if leftDown
    #         yield right if right
    #         yield rightUp if rightUp
    #         yield rightDown if rightDown
    #         yield up if up
    #         yield upLeft if upLeft
    #         yield upRight if upRight
    #         yield down if down
    #         yield downLeft if downLeft
    #         yield downRight if downRight

[RequireComponent(MeshRenderer), RequireComponent(MeshFilter), ExecuteInEditMode]
class Autotile (AutotileBase):

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

    inline_enum connectionDirection:
        i_left
        i_left_up
        i_left_down
        i_right
        i_right_up
        i_right_down
        i_up
        i_up_left
        i_up_right
        i_down
        i_down_left
        i_down_right

    static class IndexSet:
        public final left         = (i_left,)
        public final right        = (i_right,)
        public final up           = (i_up,)
        public final down         = (i_down,)

        public final left_stereo  = (i_left_up,   i_left_down)
        public final right_stereo = (i_right_up,  i_right_down)
        public final up_stereo    = (i_up_left,   i_up_right)
        public final down_stereo  = (i_down_left, i_down_right)

        public final left_face  = (i_left,  i_left_up,   i_left_down)
        public final right_face = (i_right, i_right_up,  i_right_down)
        public final up_face    = (i_up,    i_up_left,   i_up_right)
        public final down_face  = (i_down,  i_down_left, i_down_right)

        public final up_down_face = (i_up,    i_up_left,   i_up_right,
                                     i_down,  i_down_left, i_down_right)
        public final left_right_face = (i_left,  i_left_up,   i_left_down,
                                        i_right, i_right_up,  i_right_down)

        public final left_wing  = (i_up_left,   i_down_left,  i_left)
        public final right_wing = (i_up_right,  i_down_right, i_right)
        public final up_wing    = (i_left_up,   i_right_up,   i_up)
        public final down_wing  = (i_left_down, i_right_down, i_down)

        public final left_wing_core  = (i_up_left,   i_down_left)
        public final right_wing_core = (i_up_right,  i_down_right)
        public final up_wing_core    = (i_left_up,   i_right_up)
        public final down_wing_core  = (i_left_down, i_right_down)

        public final centric = (i_up, i_down, i_left, i_right)

        public final non_horizontal = (i_up,   i_down)
        public final non_vertical   = (i_left, i_right)

        public final all = (i_left,     i_left_up,    i_left_down, i_right,
                            i_right_up, i_right_down, i_up,        i_up_left,
                            i_up_right, i_down,       i_down_left, i_down_right)

    public connections = AutotileConnections()

    public boxCollider as BoxCollider
    public boxColliderMargin as single
    public useBoxColliderMarginLeft = true
    public useBoxColliderMarginRight = true
    public useBoxColliderMarginTop = true
    public useBoxColliderMarginBottom = true

    [System.NonSerialized]
    public previewAirInfo as AirInfoState

    public leftScreen as Autotile
    public rightScreen as Autotile
    public bottomScreen as Autotile
    public topScreen as Autotile

    def Connect(local_index as int, remote as Autotile, remote_index as int):
        Disconnect(local_index) if connections[local_index]
        remote.Disconnect(remote_index) if remote.connections[remote_index]

        connections[local_index] = remote
        connections.reverse[local_index] = remote_index

        remote.connections[remote_index] = self
        remote.connections.reverse[remote_index] = local_index

        self.Rebuild()
        remote.Rebuild()

    def Disconnect(i as int):
        remote = connections[i]
        remote_c_index = connections.reverse[i]

        connections[i] = null
        connections.reverse[i] = -1

        if remote:
            remote.connections[remote_c_index] = null
            remote.connections.reverse[remote_c_index] = -1
            remote.Rebuild()

    def ResetConnections(indexes as (int)):
        for i in indexes:
            Disconnect(i)
        dirty = true

    def ResetAllConnections():
        ResetConnections(IndexSet.all)

    def MoveConnection(curr as int, next as int):
        connections[next] = connections[curr]
        connections[curr] = null
        connections.reverse[next] = connections.reverse[curr]
        connections.reverse[curr] = -1
        connections[next].connections.reverse[connections.reverse[next]] = next

    def FavorOneMove(first as int, second as int, to as int):
        if connections[first]:
            MoveConnection(first, to)
            favoredConnections.Add(first) unless favoredConnections.Contains(first)
            favoredConnections.RemoveAll({e| e==second})
        elif connections[second]:
            MoveConnection(second, to)
            favoredConnections.Add(second) unless favoredConnections.Contains(second)
            favoredConnections.RemoveAll({e| e==first})

    def UseCentricConnections():
        FavorOneMove(i_up_left,   i_up_right,   i_up)
        FavorOneMove(i_down_left, i_down_right, i_down)
        FavorOneMove(i_left_up,   i_left_down,  i_left)
        FavorOneMove(i_right_up,  i_right_down, i_right)

    def GetCurrentFromConnectionSeries(c_index as int, center as int, a as int, b as int) as int:
        if c_index in (a, b):
            return center if connections[center]
        if c_index == center:
            return a if connections[a]
            return b if connections[b]
        return c_index

    def GetMovedConnection(c_index as int) as int:
        for s in (IndexSet.left_face, IndexSet.right_face, IndexSet.up_face, IndexSet.down_face):
            return GetCurrentFromConnectionSeries(c_index, s[0], s[1], s[2]) if c_index in s
        return c_index

    def UseHorizontalConnections():
        if connections[i_up]:
            if i_up_left in favoredConnections:
                MoveConnection(i_up, i_up_left)
            else:
                MoveConnection(i_up, i_up_right)
        if connections[i_down]:
            if i_down_left in favoredConnections:
                MoveConnection(i_down, i_down_left)
            else:
                MoveConnection(i_down, i_down_right)

    def UseVerticalConnections():
        if connections[i_left]:
            if i_left_up in favoredConnections:
                MoveConnection(i_left, i_left_up)
            else:
                MoveConnection(i_left, i_left_down)
        if connections[i_right]:
            if i_right_up in favoredConnections:
                MoveConnection(i_right, i_right_up)
            else:
                MoveConnection(i_right, i_right_down)

    airInfo as AirInfoState:
        set:
            _airInfo = AirInfo(value)
        get:
            return AirInfoState(_airInfo)

    uvMargin as Vector2:
        get:
            config = AutotileConfig.config.sets[tilesetKey]
            if config.uvMarginMode == UVMarginMode.HalfPixel:
                mt = config.material.mainTexture
                return Vector2(.5f/mt.width, .5f/mt.height)
            else:
                return Vector2.zero

    [SerializeField]
    private _airInfo = AirInfo(true, true, true, true, true, true, true, true)

    [SerializeField]
    private applied_air_info = AirInfoState(true, true, true, true, true, true, true, true)
    [SerializeField]
    private applied_box_collider_margin = 0.0f
    [SerializeField]
    private applied_use_box_collider_margins_left = true
    [SerializeField]
    private applied_use_box_collider_margins_right = true
    [SerializeField]
    private applied_use_box_collider_margins_bottom = true
    [SerializeField]
    private applied_use_box_collider_margins_top = true
    [SerializeField]
    protected applied_margin_mode = UVMarginMode.NoMargin

    private favoredConnections = Generic.List of int()

    def Start():
        for index as int, neighbour as Autotile in enumerate(connections):
            if neighbour:
                # neighbour might be in state of being instantiated or
                # not (a previously created asset)
                unless neighbour.connections and neighbour.connections[connections.reverse[index]] == self:
                    dirty = true
                    connections[index] = null
                    connections.reverse[index] = -1

    override def Awake():
        super()
        ifdef UNITY_EDITOR:
            unless Application.isPlaying:
                applied_non_serialized_scale = applied_scale
                mf = GetComponent of MeshFilter()
                sm = mf.sharedMesh
                if sm:
                    for t in FindObjectsOfType(Autotile):
                        if t != self and sm == t.GetComponent of MeshFilter().sharedMesh:
                            mf.sharedMesh = Mesh()
                            unsavedMesh = true
                            dirty = true
                            break
                else:
                    mf.mesh = Mesh()
                    unsavedMesh = true
                    dirty = true

                boxCollider = GetComponent of BoxCollider()
                Refresh()

    def Reset():
        GetComponent of MeshFilter().sharedMesh = Mesh()
        unsavedMesh = true
        boxCollider = GetComponent of BoxCollider()
        ApplyCentric()

    def ConnectionCanReachHorizontaly(c_index as int, worldPoint as Vector3) as bool:
        wp_local = transform.InverseTransformPoint(worldPoint)
        r_core = IndexSet.right_wing_core
        l_core = IndexSet.left_wing_core
        c_core = IndexSet.non_horizontal

        if _offsetMode == OffsetMode.Left:
            if c_index in c_core:
                return wp_local.x - Vector3(0.5f, 0.0f).x > -1e-5f
            elif c_index in r_core:
                return wp_local.x - Vector3(1.5f, 0.0f).x > -1e-5f
            elif c_index == i_right:
                return wp_local.x - Vector3(2.0f, 0.0f).x > -1e-5f
        elif _offsetMode == OffsetMode.Right:
            if c_index in c_core:
                return wp_local.x - Vector3(-0.5f, 0.0f).x > 1e-5f
            elif c_index in l_core:
                return wp_local.x - Vector3(-1.5f, 0.0f).x < 1e-5f
            elif c_index == i_left:
                return wp_local.x - Vector3(-2.0f, 0.0f).x < 1e-5f
        else:
            if c_index in r_core:
                return wp_local.x - Vector3(0.5f, 0.0f).x > -1e-5f
            elif c_index == i_right:
                return wp_local.x - Vector3(1.0f, 0.0f).x > -1e-5f
            elif c_index in l_core:
                return wp_local.x - Vector3(-0.5f, 0.0f).x < 1e-5f
            elif c_index == i_left:
                return wp_local.x - Vector3(-1.0f, 0.0f).x < 1e-5f
        c_pos = Autotile.ConnectionPosition(self, c_index, 0.0f)
        return Mathf.Abs(worldPoint.x - c_pos.x) < 1e-5f

    def ConnectionCanReachVerticaly(c_index as int, worldPoint as Vector3) as bool:
        wp_local = transform.InverseTransformPoint(worldPoint)
        u_core = IndexSet.up_wing_core
        d_core = IndexSet.down_wing_core
        c_core = IndexSet.non_vertical
        if _offsetMode == OffsetMode.Bottom:
            if c_index in c_core:
                return wp_local.y - Vector3(0.0f, 0.5f).y > -1e-5f
            elif c_index in u_core:
                return wp_local.y - Vector3(0.0f, 1.5f).y > -1e-5f
            elif c_index == i_up:
                return wp_local.y - Vector3(0.0f, 2.0f).y > -1e-5f
        elif _offsetMode == OffsetMode.Top:
            if c_index in c_core:
                return wp_local.y - Vector3(0.0f, -0.5f).y < 1e-5f
            elif c_index in d_core:
                return wp_local.y - Vector3(0.0f, -1.5f).y < 1e-5f
            elif c_index == i_down:
                return wp_local.y - Vector3(0.0f, -2.0f).y < 1e-5f
        else:
            if c_index in u_core:
                return wp_local.y - Vector3(0.0f, 0.5f).y > -1e-5f
            elif c_index == i_up:
                return wp_local.y - Vector3(0.0f, 1.0f).y > -1e-5f
            elif c_index in d_core:
                return wp_local.y - Vector3(0.0f, -0.5f).y < 1e-5f
            elif c_index == i_down:
                return wp_local.y - Vector3(0.0f, -1.0f).y < 1e-5f
        c_pos = Autotile.ConnectionPosition(self, c_index, 0.0f)
        return Mathf.Abs(worldPoint.y - c_pos.y) < 1e-5f

    def ConformToConnection(c_index as int, position as Vector3):
        originalOffsetMode = offsetMode
        offsetMode = OppositeOffset(c_index)
        ScaleCToPos(c_index, position)
        Rebuild()
        c_index = GetMovedConnection(c_index)
        MoveCToPos(c_index, position)
        PushNeighbours()
        offsetMode = originalOffsetMode
        Rebuild()

    public conforming = false
    def PushNeighbours():
        unless conforming:
            try:
                conforming = true
                for index as int, old_neighbour as Autotile in enumerate(connections):
                    if old_neighbour and not old_neighbour.conforming:
                        old_neighbour.ConformToConnection(connections.reverse[index], ConnectionPosition(self, index, 0.0f))
            ensure:
                conforming = false

    override def DrawsLeftCorner() as bool:
        return true if not connections.left or connections.upLeft or connections.downLeft
        return false
    override def DrawsRightCorner() as bool:
        return true if not connections.right or connections.upRight or connections.downRight
        return false
    override def DrawsBottomCorner() as bool:
        return true if not connections.down or connections.leftDown or connections.rightDown
        return false
    override def DrawsTopCorner() as bool:
        return true if not connections.up or connections.leftUp or connections.rightUp
        return false

    # ---------- Horizontal Connections ---------- #
    def SetLeftEnd(down as bool, up as bool):
        _airInfo.leftDown = down;
        _airInfo.leftUp = up;

    def SetRightEnd(down as bool, up as bool):
        _airInfo.rightDown = down;
        _airInfo.rightUp = up;

    def SetBottomLeftFace(left as bool, right as bool):
        _airInfo.leftDown = left;
        _airInfo.down = right;

    def SetTopLeftFace(left as bool, right as bool):
        _airInfo.leftUp = left;
        _airInfo.up = right;

    def SetHorizontalFace(bottom as bool, top as bool):
        _airInfo.down = bottom;
        _airInfo.up = top;

    def SetBottomRightFace(left as bool, right as bool):
        _airInfo.down = left;
        _airInfo.rightDown = right;

    def SetTopRightFace(left as bool, right as bool):
        _airInfo.up = left;
        _airInfo.rightUp = right;

    # ----------- Vertical Connections ----------- #
    def SetTopEnd(left as bool, right as bool):
        _airInfo.leftUp = left;
        _airInfo.rightUp = right;

    def SetBottomEnd(left as bool, right as bool):
        _airInfo.leftDown = left;
        _airInfo.rightDown = right;

    def SetLeftBottomFace(down as bool, up as bool):
        _airInfo.leftDown = down;
        _airInfo.left = up;

    def SetRightBottomFace(down as bool, up as bool):
        _airInfo.rightDown = down;
        _airInfo.right = up;

    def SetVerticalFace(left as bool, right as bool):
        _airInfo.left = left;
        _airInfo.right = right;

    def SetLeftTopFace(down as bool, up as bool):
        _airInfo.left = down;
        _airInfo.leftUp = up;

    def SetRightTopFace(down as bool, up as bool):
        _airInfo.right = down;
        _airInfo.rightUp = up;
    # -------------------------------------------- #


    def SetAndPropagateAirInfo(a as AirInfo):
        p_air = airInfo
        airInfo = AirInfoState(a)
        try:
            airPropagationStarter = true
            PropagateAirInfo(p_air)
        ensure:
            airPropagationStarter = false

    private def PropagateAirInfoThroughConnection(index, leftOrDown, rightOrUp):
        c = connections[index]
        c.ConformToConnectionAirChanged(connections.reverse[index], leftOrDown, rightOrUp) if c

    def PropagateAirInfo(previousAirInfo as AirInfoState):
        # previousAirInfo is used to check which connections should
        # propagate new air info
        p = PropagateAirInfoThroughConnection
        c = _airInfo
        left_up_changed    = previousAirInfo.leftUp    != c.leftUp
        up_changed         = previousAirInfo.up        != c.up
        right_up_changed   = previousAirInfo.rightUp   != c.rightUp
        left_changed       = previousAirInfo.left      != c.left
        right_changed      = previousAirInfo.right     != c.right
        left_down_changed  = previousAirInfo.leftDown  != c.leftDown
        down_changed       = previousAirInfo.down      != c.down
        right_down_changed = previousAirInfo.rightDown != c.rightDown

        if left_changed or right_changed:
            unless DrawsTopCorner():
                p(i_up,   c.left, c.right)
            unless DrawsBottomCorner():
                p(i_down, c.left, c.right)
        if up_changed or down_changed:
            p(i_left,  c.down, c.up) unless DrawsLeftCorner()
            p(i_right, c.down, c.up) unless DrawsRightCorner()

        if left_changed:
            p(i_left_down, c.leftDown, c.left  )
            p(i_left_up,   c.left,     c.leftUp)
        if right_changed:
            p(i_right_down, c.rightDown, c.right  )
            p(i_right_up,   c.right,     c.rightUp)
        if down_changed:
            p(i_down_left,  c.leftDown, c.down     )
            p(i_down_right, c.down,     c.rightDown)
        if up_changed:
            p(i_up_left,  c.leftUp, c.up     )
            p(i_up_right, c.up,     c.rightUp)

        if left_down_changed:
            p(i_left,      c.leftDown, c.leftUp)
            p(i_down_left, c.leftDown, c.down)
            p(i_down,      c.leftDown, c.rightDown)
        if right_down_changed:
            p(i_right,      c.rightDown, c.rightUp)
            p(i_down_right, c.down,      c.rightDown)
            p(i_down,       c.leftDown,  c.rightDown)
        if left_up_changed:
            p(i_left,    c.leftDown, c.leftUp)
            p(i_up_left, c.leftUp, c.up)
            p(i_up,      c.leftUp, c.rightUp)
        if right_up_changed:
            p(i_right,    c.rightDown, c.rightUp)
            p(i_up_right, c.up,        c.rightUp)
            p(i_up,       c.leftUp,    c.rightUp)

    public airPropagationStarter = false
    public conformingToAir = false
    def ConformToConnectionAirChanged(c_index as int, leftOrDown as bool, rightOrUp as bool):
        unless conformingToAir or airPropagationStarter:
            try:
                conformingToAir = true
                # Save air_info, so propagation happens cleanly
                air_info = airInfo
                if tileMode == TileMode.Horizontal:
                    if c_index == i_left:
                        if self.DrawsLeftCorner():
                            SetLeftEnd(leftOrDown, rightOrUp)
                        else:
                            SetHorizontalFace(leftOrDown, rightOrUp)
                    elif c_index == i_right:
                        if self.DrawsRightCorner():
                            SetRightEnd(leftOrDown, rightOrUp)
                        else:
                            SetHorizontalFace(leftOrDown, rightOrUp)
                    elif c_index == i_up_left:
                        SetTopLeftFace(leftOrDown, rightOrUp)
                    elif c_index == i_down_left:
                        SetBottomLeftFace(leftOrDown, rightOrUp)
                    elif c_index == i_up_right:
                        SetTopRightFace(leftOrDown, rightOrUp)
                    elif c_index == i_down_right:
                        SetBottomRightFace(leftOrDown, rightOrUp)
                elif tileMode == TileMode.Vertical:
                    if c_index == i_down:
                        if self.DrawsBottomCorner():
                            SetBottomEnd(leftOrDown, rightOrUp)
                        else:
                            SetVerticalFace(leftOrDown, rightOrUp)
                    elif c_index == i_up:
                        if self.DrawsTopCorner():
                            SetTopEnd(leftOrDown, rightOrUp)
                        else:
                            SetVerticalFace(leftOrDown, rightOrUp)
                    elif c_index == i_left_down:
                        SetLeftBottomFace(leftOrDown, rightOrUp)
                    elif c_index == i_right_down:
                        SetRightBottomFace(leftOrDown, rightOrUp)
                    elif c_index == i_left_up:
                        SetLeftTopFace(leftOrDown, rightOrUp)
                    elif c_index == i_right_up:
                        SetRightTopFace(leftOrDown, rightOrUp)
                elif tileMode == TileMode.Centric:
                    if c_index == i_left:
                        SetLeftEnd(leftOrDown, rightOrUp)
                    elif c_index == i_right:
                        SetRightEnd(leftOrDown, rightOrUp)
                    elif c_index == i_down:
                        SetBottomEnd(leftOrDown, rightOrUp)
                    elif c_index == i_up:
                        SetTopEnd(leftOrDown, rightOrUp)

                PropagateAirInfo(air_info)
                Refresh()
            ensure:
                conformingToAir = false

    def LocalConnectionPosition(c_index as int) as Vector3:
        width = transform.localScale.x
        height = transform.localScale.y
        binary_search_autotile_connection c_index:
            return Vector3( offset.x - 0.5f               , offset.y                        )
            return Vector3( offset.x - 0.5f               , offset.y + 0.5f - 0.5f / height )
            return Vector3( offset.x - 0.5f               , offset.y - 0.5f + 0.5f / height )
            return Vector3( offset.x + 0.5f               , offset.y                        )
            return Vector3( offset.x + 0.5f               , offset.y + 0.5f - 0.5f / height )
            return Vector3( offset.x + 0.5f               , offset.y - 0.5f + 0.5f / height )
            return Vector3( offset.x                      , offset.y + 0.5f                 )
            return Vector3( offset.x - 0.5f + 0.5f / width, offset.y + 0.5f                 )
            return Vector3( offset.x + 0.5f - 0.5f / width, offset.y + 0.5f                 )
            return Vector3( offset.x                      , offset.y - 0.5f                 )
            return Vector3( offset.x - 0.5f + 0.5f / width, offset.y - 0.5f                 )
            return Vector3( offset.x + 0.5f - 0.5f / width, offset.y - 0.5f                 )

    static def ConnectionPosition(other as Autotile, c_index as int, skin as single) as Vector3:
        l_t = other.transform
        w = l_t.TransformPoint
        width = l_t.localScale.x
        height = l_t.localScale.y
        off_x = other.offset.x
        off_y = other.offset.y
        binary_search_autotile_connection c_index:
            return w(Vector3( off_x - 0.5f - skin / width, off_y                        ))
            return w(Vector3( off_x - 0.5f - skin / width, off_y + 0.5f - 0.5f / height ))
            return w(Vector3( off_x - 0.5f - skin / width, off_y - 0.5f + 0.5f / height ))
            return w(Vector3( off_x + 0.5f + skin / width, off_y                        ))
            return w(Vector3( off_x + 0.5f + skin / width, off_y + 0.5f - 0.5f / height ))
            return w(Vector3( off_x + 0.5f + skin / width, off_y - 0.5f + 0.5f / height ))
            return w(Vector3( off_x                      , off_y + 0.5f + skin / height ))
            return w(Vector3( off_x - 0.5f + 0.5f / width, off_y + 0.5f + skin / height ))
            return w(Vector3( off_x + 0.5f - 0.5f / width, off_y + 0.5f + skin / height ))
            return w(Vector3( off_x                      , off_y - 0.5f - skin / height ))
            return w(Vector3( off_x - 0.5f + 0.5f / width, off_y - 0.5f - skin / height ))
            return w(Vector3( off_x + 0.5f - 0.5f / width, off_y - 0.5f - skin / height ))

    def OppositeOffset(c_index as int) as OffsetMode:
        if c_index in IndexSet.left_wing:
            return OffsetMode.Right
        elif c_index in IndexSet.right_wing:
            return OffsetMode.Left
        elif c_index in IndexSet.up_wing:
            return OffsetMode.Bottom
        else: #if c_index in IndexSet.down_wing:
            return OffsetMode.Top

    def MoveCToPos(c_index as int, worldPosition as Vector3):
        l_pos = LocalConnectionPosition(c_index)
        c_pos = transform.TransformPoint(l_pos)
        delta = worldPosition - c_pos
        transform.position += delta

    def ScaleCToPos(c_index as int, worldPosition as Vector3):
        w_as_local = transform.InverseTransformPoint(worldPosition)
        c_local = LocalConnectionPosition(c_index)

        horizontal = secondaryTileMode == TileMode.Horizontal
        vertical   = secondaryTileMode == TileMode.Vertical
        closeLeft   = offsetMode == OffsetMode.Left   and\
                    c_index in IndexSet.left_wing
        closeRight  = offsetMode == OffsetMode.Right  and\
                    c_index in IndexSet.right_wing
        closeBottom = offsetMode == OffsetMode.Bottom and\
                    c_index in IndexSet.down_wing
        closeTop    = offsetMode == OffsetMode.Top    and\
                    c_index in IndexSet.up_wing
        if horizontal and (closeLeft   or closeRight) or\
           vertical   and (closeBottom or closeTop  ):
            return

        if horizontal:
            if w_as_local.x < 0.0f:
                edge_dist = -0.5f + offset.x
            else:
                edge_dist =  0.5f + offset.x
            if edge_dist:
                signed_candidate_x = transform.localScale.x * (edge_dist + w_as_local.x - c_local.x) / Mathf.Abs(edge_dist)
            else:
                signed_candidate_x = transform.localScale.x * (w_as_local.x - c_local.x)
            candidate_x = Mathf.Abs(signed_candidate_x)
            if signed_candidate_x != candidate_x and\
               (c_index in IndexSet.right_wing or\
                c_index == i_up and i_up_left not in favoredConnections or\
                c_index == i_down and i_down_left not in favoredConnections)\
               or\
               signed_candidate_x == candidate_x and\
               (c_index in IndexSet.left_wing or\
                c_index == i_up and i_up_right not in favoredConnections or\
                c_index == i_down and i_down_right not in favoredConnections):

                candidate_x *= -1.0f

            transform.localScale.x = candidate_x
        elif vertical:
            if w_as_local.y < 0.0f:
                edge_dist = -0.5f + offset.y
            else:
                edge_dist =  0.5f + offset.y
            if edge_dist:
                signed_candidate_y = transform.localScale.y * (edge_dist + w_as_local.y - c_local.y) / Mathf.Abs(edge_dist)
            else:
                signed_candidate_y = transform.localScale.y * (w_as_local.y - c_local.y)
            candidate_y = Mathf.Abs(signed_candidate_y)
            if signed_candidate_y != candidate_y and\
               (c_index in IndexSet.up_wing or\
                c_index == i_right and i_right_down not in favoredConnections or\
                c_index == i_left and i_left_down not in favoredConnections)\
               or\
               signed_candidate_x == candidate_x and\
               (c_index in IndexSet.left_wing or\
                c_index == i_right and i_right_up not in favoredConnections or\
                c_index == i_left and i_left_up not in favoredConnections):

                candidate_y *= -1.0f

            transform.localScale.y = candidate_y

        transform.localScale = SuggestScales()

    def ConnectConnectors(
            other as Autotile,
            local_connections as Generic.IEnumerable[of int],
            remote_connections as Generic.IEnumerable[of int],
            moveAccordingly as bool):
        best_local_index = -1
        best_remote_index = -1
        best_sqr_dist = Mathf.Infinity
        for l_i as int in local_connections:
            for r_i as int in remote_connections:
                local_position  = Autotile.ConnectionPosition( self, l_i, 0.0f)
                remote_position = Autotile.ConnectionPosition(other, r_i, 0.0f)
                d = (local_position - remote_position).sqrMagnitude
                if d < best_sqr_dist:
                    best_sqr_dist = d
                    best_local_index = l_i
                    best_remote_index = r_i
        Connect(best_local_index, other, best_remote_index)
        if moveAccordingly:
            r_pos = Autotile.ConnectionPosition(other, best_remote_index, 0.0f)
            MoveCToPos( best_local_index, r_pos)

    def ConnectToTiles(tiles as Generic.IEnumerable[of Autotile]):
        first = true
        for other in tiles:
            continue if other in connections
            connectableTileModes = (TileMode.Centric, TileMode.Horizontal, TileMode.Vertical)
            nonVerticalModes = (TileMode.Centric, TileMode.Horizontal)
            nonHorizontalModes = (TileMode.Centric, TileMode.Vertical)

            if tileMode in connectableTileModes and\
               other.tileMode in connectableTileModes:

                other_t = other.transform
                other_half_w = 0.5f * other_t.localScale.x / transform.localScale.x
                other_half_h = 0.5f * other_t.localScale.y / transform.localScale.y
                local_half_w = 0.5f
                local_half_h = 0.5f
                other_p = transform.InverseTransformPoint(other.OffsetPosition())
                other_x = other_p.x
                other_y = other_p.y
                local_p = offset
                local_x = local_p.x
                local_y = local_p.y

                other_upper_lim = other_y + other_half_h
                other_lower_lim = other_y - other_half_h
                other_left_lim = other_x - other_half_w
                other_right_lim = other_x + other_half_w

                local_upper_lim = local_y + local_half_h
                local_lower_lim = local_y - local_half_h
                local_left_lim = local_x - local_half_w
                local_right_lim = local_x + local_half_w

                positioned_left = local_x < other_left_lim and\
                                  local_right_lim < other_right_lim
                positioned_right = local_x > other_right_lim and\
                                   local_left_lim > other_left_lim
                positioned_top = local_y > other_upper_lim and\
                                 local_lower_lim > other_lower_lim
                positioned_bottom = local_y < other_lower_lim and\
                                    local_upper_lim < other_upper_lim
                within_height = local_y > other_lower_lim and\
                                local_y < other_upper_lim
                within_width = local_x > other_left_lim and\
                               local_x < other_right_lim

                if positioned_right and (within_height or tileMode == TileMode.Vertical):
                    if tileMode in nonVerticalModes:
                        local_connections = IndexSet.left
                    else:
                        local_connections = IndexSet.left_stereo
                    if other.tileMode in nonVerticalModes:
                        remote_connections = IndexSet.right
                    else:
                        remote_connections = IndexSet.right_stereo

                elif positioned_left and (within_height or tileMode == TileMode.Vertical):
                    if tileMode in nonVerticalModes:
                        local_connections = IndexSet.right
                    else:
                        local_connections = IndexSet.right_stereo
                    if other.tileMode in nonVerticalModes:
                        remote_connections = IndexSet.left
                    else:
                        remote_connections = IndexSet.left_stereo

                elif positioned_bottom and (within_width or tileMode == TileMode.Horizontal):
                    if tileMode in nonHorizontalModes:
                        local_connections = IndexSet.up
                    else:
                        local_connections = IndexSet.up_stereo
                    if other.tileMode in nonHorizontalModes:
                        remote_connections = IndexSet.down
                    else:
                        remote_connections = IndexSet.down_stereo

                elif positioned_top and (within_width or tileMode == TileMode.Horizontal):
                    if tileMode in nonHorizontalModes:
                        local_connections = IndexSet.down
                    else:
                        local_connections = IndexSet.down_stereo
                    if other.tileMode in nonHorizontalModes:
                        remote_connections = IndexSet.up
                    else:
                        remote_connections = IndexSet.up_stereo
                else:
                    return
                ConnectConnectors(other, local_connections, remote_connections, first)
                first = false

    def ApplyHorizontalTile():
        unless Mathf.Abs(transform.localScale.x) < 0.001f:
            left = getLeftCorner()
            right = getRightCorner()
            mf = GetComponent of MeshFilter()
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.doubleHorizontalVertices)
            mf.sharedMesh.triangles = AutotileBase.doubleTriangles
            mf.sharedMesh.uv = AutotileBase.TileUVs(left, uvMargin) + AutotileBase.TileUVs(right, uvMargin)
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true
            AdjustBoxCollider()

    def AdjustBoxCollider():
        if boxCollider:
            boxCollider.center = offset

            width_margin = boxColliderMargin / transform.localScale.x
            height_margin = boxColliderMargin / transform.localScale.y

            width = height = 1.0f
            if useBoxColliderMarginLeft:
                boxCollider.center.x += width_margin * 0.5f
                width -= width_margin
            if useBoxColliderMarginRight:
                boxCollider.center.x -= width_margin * 0.5f
                width -= width_margin
            if useBoxColliderMarginBottom:
                boxCollider.center.y += height_margin * 0.5f
                height -= height_margin
            if useBoxColliderMarginTop:
                boxCollider.center.y -= height_margin * 0.5f
                height -= height_margin

            boxCollider.size.x = width
            boxCollider.size.y = height

    def ApplyLongTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]], direction as TileDirection):
        if direction == TileDirection.Horizontal:
            width = transform.localScale.x
            black_center = true not in (_airInfo.down, _airInfo.up)
            draw_first_corner = DrawsLeftCorner() and useLeftCorner
            draw_last_corner = DrawsRightCorner() and useRightCorner
            left = getLeftCorner() if draw_first_corner
            right = getRightCorner() if draw_last_corner
        else:
            width = transform.localScale.y
            black_center = true not in (_airInfo.left, _airInfo.right)
            draw_first_corner = DrawsBottomCorner() and useBottomCorner
            draw_last_corner = DrawsTopCorner() and useTopCorner
            left = getBottomCorner() if draw_first_corner
            right = getTopCorner() if draw_last_corner

        if_00_01_10_11 draw_first_corner, draw_last_corner:
            spareSpace = width
            spareSpace = width - 1.0f
            spareSpace = width - 1.0f
            spareSpace = width - 2.0f

        smallestKey = AutotileConfig.config.sets[tilesetKey].centerSets.smallestKey

        if black_center:
            centerUnits = 1
        elif squeezeMode == SqueezeMode.Clip:
            centerUnits = Mathf.Ceil(spareSpace) cast int
        else:
            centerUnits = smallestKey * Mathf.Round(spareSpace / smallestKey) cast int
            centerUnits = Mathf.Max(smallestKey, centerUnits)

        cornerSize = 1f / width

        if draw_first_corner:
            firstSplit = -0.5f + cornerSize
            vertices = TileSlice(-0.5f, firstSplit, direction)
            uvs = AutotileBase.TileUVs(left, uvMargin)
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
                    if not black_center and squeezeMode == SqueezeMode.Clip:
                        fractionOfTile = (lastSplit - currentSplit) / (splitWidth * tileWidth)
                    else:
                        fractionOfTile = 1.0f
                    vertices += TileSlice(currentSplit, lastSplit, direction)
                    uvs += AutotileBase.TileUVs(tile, fractionOfTile, direction, uvMargin)
                else:
                    nextSplit = currentSplit + splitWidth * tileWidth
                    vertices += TileSlice(currentSplit, nextSplit, direction)
                    uvs += AutotileBase.TileUVs(tile, uvMargin)

                tilesSpent += 1
                currentSplit = nextSplit

        if draw_last_corner:
            vertices += TileSlice(lastSplit, 0.5f, direction)
            uvs += AutotileBase.TileUVs(right, uvMargin)
            tilesSpent += 1

        mf = GetComponent of MeshFilter()
        mf.sharedMesh.Clear()
        mf.sharedMesh.vertices = vertices
        mf.sharedMesh.triangles = array(int, (i for i in range(6 * tilesSpent)))
        mf.sharedMesh.uv = uvs
        mf.sharedMesh.RecalculateNormals()
        mf.sharedMesh.RecalculateBounds()
        unsavedMesh = true
        AdjustBoxCollider()

    def ApplyHorizontalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]]):
        ApplyLongTile(centerTiles, TileDirection.Horizontal)

    def ApplyVerticalTile():
        unless Mathf.Abs(transform.localScale.y) < 0.001f:
            bottom = getBottomCorner()
            top = getTopCorner()
            mf = GetComponent of MeshFilter()
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.doubleVerticalVertices)
            mf.sharedMesh.triangles = AutotileBase.doubleTriangles
            mf.sharedMesh.uv = AutotileBase.TileUVs(bottom, uvMargin) + AutotileBase.TileUVs(top, uvMargin)
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true
            AdjustBoxCollider()

    def ApplyVerticalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]]):
        ApplyLongTile(centerTiles, TileDirection.Vertical)

    def ApplyTile(tile as Tile):
        uvs = AutotileBase.TileUVs(tile, uvMargin)
        mf = GetComponent of MeshFilter()
        if mf.sharedMesh:
            mf.sharedMesh.Clear()
            mf.sharedMesh.vertices = OffsetVertices(AutotileBase.singleVertices)
            mf.sharedMesh.triangles = AutotileBase.singleTriangles
            mf.sharedMesh.uv = uvs
            mf.sharedMesh.RecalculateNormals()
            mf.sharedMesh.RecalculateBounds()
            unsavedMesh = true
        AdjustBoxCollider()

    private class Descending (System.Collections.Generic.IComparer[of int]):
        public def Compare(left as int, right as int) as int:
            return System.Collections.Generic.Comparer[of int].Default.Compare(right, left)

    private def DescendingNoneFaces(autotileset as string) as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]]:
        tileset = Generic.List[of Generic.KeyValuePair[of int, Tile]]()
        tileset.Add(Generic.KeyValuePair[of int, Tile](1, AutotileConfig.config.sets[autotileset].corners.bbbb))
        return tileset

    descending_faces up
    descending_faces down
    descending_faces left
    descending_faces right
    descending_faces doubleHorizontal
    descending_faces doubleVertical

    def CanScaleHorizontalyToCentric():
        return not (connections[i_up_left]   and connections[i_up_right] or\
                    connections[i_down_left] and connections[i_down_right])

    def CanScaleVerticalyToCentric():
        return not (connections[i_left_up]  and connections[i_left_down] or\
                    connections[i_right_up] and connections[i_right_down])

    def CanScaleToCentric():
        return false unless CornersNeeded()
        return tileMode == TileMode.Horizontal and CanScaleHorizontalyToCentric() or\
               tileMode == TileMode.Vertical   and CanScaleVerticalyToCentric() or\
               tileMode == TileMode.Centric

    public class AirInfo:
        #                                       X_____X
        #                                       |     |
        #                                       |     |
        #   X_______X_______X      X_____X      |-----|
        #   |     |||||     |      |     |      |-----|
        #   |     |||||     |      |     |    X |-----| X
        #   |     |||||     |      |     |      |-----|
        #   X^^^^^^^X^^^^^^^X      X^^^^^X      |-----|
        #                                       |     |
        #                                       |     |
        #                                       X^^^^^X
        public up = false
        public down = false
        public left = false
        public right = false
        public leftUp = false
        public rightUp = false
        public leftDown = false
        public rightDown = false

        def constructor():
            pass

        def constructor(a as AirInfo):
            left = a.left; right = a.right
            down = a.down; up    = a.up
            leftUp   = a.leftUp;   rightUp   = a.rightUp
            leftDown = a.leftDown; rightDown = a.rightDown

        def constructor(a as AirInfoState):
            left = a.left; right = a.right
            down = a.down; up    = a.up
            leftUp   = a.leftUp;   rightUp   = a.rightUp
            leftDown = a.leftDown; rightDown = a.rightDown

        def constructor(l  as bool, r  as bool, d  as bool,  u as bool,
                        lu as bool, ru as bool, ld as bool, rd as bool):
            left = l;    right = r;    down = d;      up = u
            leftUp = lu; rightUp = ru; leftDown = ld; rightDown = rd

    public class AirInfoState:
        # This class prohibits the illusion of a changeable 'AirInfo'
        public final up as bool
        public final down as bool
        public final left as bool
        public final right as bool
        public final leftUp as bool
        public final rightUp as bool
        public final leftDown as bool
        public final rightDown as bool

        def constructor(a as AirInfo):
            left = a.left; right = a.right
            down = a.down; up    = a.up
            leftUp   = a.leftUp;   rightUp   = a.rightUp
            leftDown = a.leftDown; rightDown = a.rightDown

        def constructor(l  as bool, r  as bool, d  as bool,  u as bool,
                        lu as bool, ru as bool, ld as bool, rd as bool):
            left = l;    right = r;    down = d;      up = u
            leftUp = lu; rightUp = ru; leftDown = ld; rightDown = rd

        def Equals(s as AirInfo) as bool:
            return leftUp   == s.leftUp   and rightUp   == s.rightUp and\
                   leftDown == s.leftDown and rightDown == s.rightDown and\
                   left     == s.left     and right     == s.right and\
                   down     == s.down     and up        == s.up

        def Equals(s as AirInfoState) as bool:
            return leftUp   == s.leftUp   and rightUp   == s.rightUp and\
                   leftDown == s.leftDown and rightDown == s.rightDown and\
                   left     == s.left     and right     == s.right and\
                   down     == s.down     and up        == s.up

    private def IsNoneTile() as bool:
        if tileMode == TileMode.Horizontal:
            return false if _airInfo.up or _airInfo.down
        if tileMode == TileMode.Vertical:
            return false if _airInfo.left or _airInfo.right
        return not (_airInfo.leftUp or _airInfo.rightUp or _airInfo.leftDown or _airInfo.rightDown)

    private def HFace() as string:
        if_00_01_10_11 _airInfo.down, _airInfo.up:
            return "b"
            return "g"
            return "c"
            return "d"

    private def VFace() as string:
        if_00_01_10_11 _airInfo.left, _airInfo.right:
            return "b"
            return "r"
            return "l"
            return "d"

    def getHorizontalConnectionClassification(\
            c as Autotile,
            air_bottom_default as bool,
            air_top_default as bool) as string:
        if c and air_bottom_default and air_top_default:
            return "d"
        else:
            if_00_01_10_11 air_bottom_default, air_top_default:
                return "b"
                return "g"
                return "c"
                return "a"

    def getVerticalConnectionClassification(\
            c as Autotile,
            air_left_default as bool,
            air_right_default as bool) as string:
        if c and air_left_default and air_right_default:
            return "d"
        else:
            if_00_01_10_11 air_left_default, air_right_default:
                return "b"
                return "r"
                return "l"
                return "a"

    def cornerByName(key as string) as Tile:
        try:
            return AutotileConfig.config.sets[tilesetKey].corners[key]
        except e as Generic.KeyNotFoundException:
            return AutotileConfig.config.sets[tilesetKey].corners.unknown

    def getCenterLength() as int:
        if tileMode == TileMode.Horizontal:
            if applied_discrete_width > CornersNeeded():
                return AutotileConfig.config.sets[tilesetKey].centerSets.smallestKey
            else:
                return 0
        else: # if tileMode == TileMode.Vertical:
            if applied_discrete_height > CornersNeeded():
                return AutotileConfig.config.sets[tilesetKey].centerSets.smallestKey
            else:
                return 0

    def getCenterPiece() as Tile:
        tileSet = AutotileConfig.config.sets[tilesetKey]
        centerDB = tileSet.centerSets
        centerSet = centerDB[centerDB.smallestKey]
        if tileMode == TileMode.Horizontal:
            if _airInfo.up:
                if _airInfo.down:
                    return centerSet.doubleHorizontalFace
                else:
                    return centerSet.upFace
            elif _airInfo.down:
                return centerSet.downFace
            else:
                return tileSet.corners.bbbb
        else: # if tileMode == TileMode.Vertical:
            if _airInfo.left:
                if _airInfo.right:
                    return centerSet.doubleVerticalFace
                else:
                    return centerSet.leftFace
            elif _airInfo.right:
                return centerSet.rightFace
            else:
                return tileSet.corners.bbbb

    def getCentricCorner() as Tile:
        w = getVerticalConnectionClassification(  connections.up,         _airInfo.leftUp,    _airInfo.rightUp)
        x = getHorizontalConnectionClassification(connections.right,      _airInfo.rightDown, _airInfo.rightUp)
        y = getVerticalConnectionClassification(  connections.down,       _airInfo.leftDown,  _airInfo.rightDown)
        z = getHorizontalConnectionClassification(connections.left,       _airInfo.leftDown,  _airInfo.leftUp)
        return cornerByName("$w$x$y$z")

    def getRightCorner() as Tile:
        w = getVerticalConnectionClassification(  connections.upRight,    _airInfo.up,        _airInfo.rightUp)
        x = getHorizontalConnectionClassification(connections.right,      _airInfo.rightDown, _airInfo.rightUp)
        y = getVerticalConnectionClassification(  connections.downRight,  _airInfo.down,      _airInfo.rightDown)
        z = HFace()
        return cornerByName("$w$x$y$z")

    def getLeftCorner() as Tile:
        w = getVerticalConnectionClassification(  connections.upLeft,     _airInfo.leftUp,    _airInfo.up)
        x = HFace()
        y = getVerticalConnectionClassification(  connections.downLeft,   _airInfo.leftDown,  _airInfo.down)
        z = getHorizontalConnectionClassification(connections.left,       _airInfo.leftDown,  _airInfo.leftUp)
        return cornerByName("$w$x$y$z")

    def getTopCorner() as Tile:
        w = getVerticalConnectionClassification(  connections.up,        _airInfo.leftUp,     _airInfo.rightUp)
        x = getHorizontalConnectionClassification(connections.rightUp,   _airInfo.right,      _airInfo.rightUp)
        y = VFace()
        z = getHorizontalConnectionClassification(connections.leftUp,    _airInfo.left,       _airInfo.leftUp)
        return cornerByName("$w$x$y$z")

    def getBottomCorner() as Tile:
        w = VFace()
        x = getHorizontalConnectionClassification(connections.rightDown, _airInfo.rightDown,  _airInfo.right)
        y = getVerticalConnectionClassification(  connections.down,      _airInfo.leftDown,   _airInfo.rightDown)
        z = getHorizontalConnectionClassification(connections.leftDown,  _airInfo.leftDown,   _airInfo.left)
        return cornerByName("$w$x$y$z")

    def ApplyHorizontal(dim as int):
        try:
            tileMode = secondaryTileMode = TileMode.Horizontal
            UseHorizontalConnections()
            if dim == 2 and useLeftCorner and useRightCorner and not (connections.left or connections.right):
                ApplyHorizontalTile()
            else:
                if_00_01_10_11 _airInfo.down, _airInfo.up:
                    ApplyHorizontalTile(DescendingNoneFaces(tilesetKey))
                    ApplyHorizontalTile(DescendingUpFaces(tilesetKey))
                    ApplyHorizontalTile(DescendingDownFaces(tilesetKey))
                    ApplyHorizontalTile(DescendingDoubleHorizontalFaces(tilesetKey))
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyVertical(dim as int):
        try:
            tileMode = secondaryTileMode = TileMode.Vertical
            UseVerticalConnections()
            if dim == 2 and useTopCorner and useBottomCorner and not (connections.down or connections.up):
                ApplyVerticalTile()
            else:
                if_00_01_10_11 _airInfo.left, _airInfo.right:
                    ApplyVerticalTile(DescendingNoneFaces(tilesetKey))
                    ApplyVerticalTile(DescendingRightFaces(tilesetKey))
                    ApplyVerticalTile(DescendingLeftFaces(tilesetKey))
                    ApplyVerticalTile(DescendingDoubleVerticalFaces(tilesetKey))
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyCentric():
        try:
            tileMode = TileMode.Centric
            UseCentricConnections()
            ApplyTile(getCentricCorner())
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyClipCentric():
        if connections.left and connections.right and\
           not (connections.down or connections.up):

            tileMode = secondaryTileMode = TileMode.Horizontal
            UseHorizontalConnections()

            if_00_01_10_11 _airInfo.down, _airInfo.up:
                ApplyHorizontalTile(DescendingNoneFaces(tilesetKey))
                ApplyHorizontalTile(DescendingUpFaces(tilesetKey))
                ApplyHorizontalTile(DescendingDownFaces(tilesetKey))
                ApplyHorizontalTile(DescendingDoubleHorizontalFaces(tilesetKey))

        elif connections.down and connections.up and\
             not (connections.left or connections.right):

            tileMode = secondaryTileMode = TileMode.Vertical
            UseVerticalConnections()

            if_00_01_10_11 _airInfo.left, _airInfo.right:
                ApplyVerticalTile(DescendingNoneFaces(tilesetKey))
                ApplyVerticalTile(DescendingRightFaces(tilesetKey))
                ApplyVerticalTile(DescendingLeftFaces(tilesetKey))
                ApplyVerticalTile(DescendingDoubleVerticalFaces(tilesetKey))

    def ApplyNone():
        try:
            tileMode = secondaryTileMode = TileMode.None
            ApplyTile(AutotileConfig.config.sets[tilesetKey].corners.bbbb)
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    override def ApplyScale():
        x = Mathf.Max(1f, Mathf.Round(transform.localScale.x)) cast int
        y = Mathf.Max(1f, Mathf.Round(transform.localScale.y)) cast int
        if squeezeMode == SqueezeMode.Clip:
            if secondaryTileMode == TileMode.Horizontal and (connections.left or connections.right) or transform.localScale.x > 2.0f:
                x = Mathf.Ceil(transform.localScale.x) cast int
            if secondaryTileMode == TileMode.Vertical and (connections.up or connections.down) or transform.localScale.y > 2.0f:
                y = Mathf.Ceil(transform.localScale.y) cast int
        if applied_discrete_width != x and x > 0 or applied_discrete_height != y  and y > 0 or dirty:
            dirty = false
            unsaved = true

            applied_discrete_width = x
            applied_discrete_height = y
            applied_scale = transform.localScale
            applied_non_serialized_scale = transform.localScale

            if IsNoneTile():
                ApplyNone()
            else:
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
            if IsNoneTile():
                applied_scale = transform.localScale
                applied_non_serialized_scale = transform.localScale
            else:
                if x == 1 and y >= 2:
                    ApplyVertical(y)
                    applied_scale = transform.localScale
                    applied_non_serialized_scale = transform.localScale
                elif y == 1 and x >= 2:
                    ApplyHorizontal(x)
                    applied_scale = transform.localScale
                    applied_non_serialized_scale = transform.localScale
                elif squeezeMode == SqueezeMode.Clip:
                    ApplyClipCentric()
                    applied_scale = transform.localScale
                    applied_non_serialized_scale = transform.localScale

    def ApplyAirInfo():
        unless applied_air_info.Equals(_airInfo):
            applied_air_info = airInfo
            dirty = true

    override def SuggestScales() as Vector3:
        h = secondaryTileMode == TileMode.Horizontal
        v = secondaryTileMode == TileMode.Vertical
        centric = tileMode == TileMode.Centric
        c = transform.localScale.x if h
        c = transform.localScale.y if v
        d_c = Mathf.Round(c) cast int

        if h and (connections.left or connections.right) or\
           v and (connections.up   or connections.down):
            c = Mathf.Max(0.1f, Mathf.Max(CornersNeeded(), c))
        elif d_c < 2 and CanScaleToCentric():
            c = 1.0f
        elif squeezeMode == SqueezeMode.Scale and d_c == 2 or c < 2.0f:
            c = 2.0f

        return Vector3(   c, 1.0f, 1.0f) if h
        return Vector3(1.0f,    c, 1.0f) if v
        return Vector3.one if centric
        return transform.localScale

    private workingOnConnections = false
    override def OnDestroy():
        super()
        unless Application.isPlaying:
            unless workingOnConnections:
                try:
                    workingOnConnections = true
                    for i, remote as Autotile in enumerate(connections):
                        if remote:
                            remote.connections[connections.reverse[i]] = null
                            remote.Refresh()
                ensure:
                    workingOnConnections = false

            DestroyImmediate( GetComponent of MeshFilter().sharedMesh, true )

    def ApplyBoxColliderMargin():
        if applied_box_collider_margin != boxColliderMargin or\
           applied_use_box_collider_margins_left   != useBoxColliderMarginLeft or\
           applied_use_box_collider_margins_right  != useBoxColliderMarginRight or\
           applied_use_box_collider_margins_bottom != useBoxColliderMarginBottom or\
           applied_use_box_collider_margins_top    != useBoxColliderMarginTop:
            applied_box_collider_margin = boxColliderMargin
            applied_use_box_collider_margins_left   = useBoxColliderMarginLeft
            applied_use_box_collider_margins_right  = useBoxColliderMarginRight
            applied_use_box_collider_margins_bottom = useBoxColliderMarginBottom
            applied_use_box_collider_margins_top    = useBoxColliderMarginTop
            dirty = true

    def ApplyMarginMode():
        return unless AutotileConfig.config.sets.ContainsKey(tilesetKey)
        real_margin_mode = AutotileConfig.config.sets[tilesetKey].uvMarginMode
        if applied_margin_mode != real_margin_mode:
            applied_margin_mode = real_margin_mode
            dirty = true

    override def Refresh():
        boxCollider = GetComponent of BoxCollider() unless boxCollider
        ApplyAirInfo()
        ApplyBoxColliderMargin()
        ApplyMarginMode()
        super()
