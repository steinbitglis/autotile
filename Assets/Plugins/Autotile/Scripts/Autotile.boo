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

enum HorizontalFace:
    Up
    Down
    Double
    None

enum VerticalFace:
    Left
    Right
    Double
    None

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
class Autotile (MonoBehaviour):

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

    public tilesetKey as string
    public tileMode as TileMode
    public secondaryTileMode as TileMode
    public squeezeMode = SqueezeMode.Clip
    public connections = AutotileConnections()

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

    def ResetAllConnections():
        for i in IndexSet.all:
            Disconnect(i)
        dirty = true

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

    public horizontalFace = HorizontalFace.Double
    public verticalFace = VerticalFace.Double

    public offset as Vector3
    [SerializeField]
    private _offsetMode = OffsetMode.Center

    private applied_tileset_key = ""
    private applied_horizontal_face = HorizontalFace.Up
    private applied_vertical_face = VerticalFace.Left
    private applied_scale = Vector3.one
    private applied_discrete_width = 1
    private applied_discrete_height = 1
    private applied_offset = Vector3.zero
    private dirty = false

    private favoredConnections = Generic.List of int()

    offsetMode as OffsetMode:
        set:
            _offsetMode = value

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
        get:
            return _offsetMode

    def Start():
        for index as int, neighbour as Autotile in enumerate(connections):
            if neighbour:
                unless neighbour.connections[connections.reverse[index]] == self:
                    connections[index] = null
                    connections.reverse[index] = -1

    def Awake():
        GetComponent of MeshFilter().sharedMesh = Mesh()
        Refresh()

    def Reset():
        GetComponent of MeshFilter().sharedMesh = Mesh()
        ApplyCentric()

    def Update():
        ifdef UNITY_EDITOR:
            pos = transform.position
            unless pos.z == 0.0f:
                pos.z = 0.0f
                transform.position = pos

    def ConnectionCanReachHorizontaly(c_index as int, worldPoint as Vector3) as bool:
        p = transform.position
        r_core = IndexSet.right_wing_core
        l_core = IndexSet.left_wing_core
        c_core = IndexSet.non_horizontal

        if _offsetMode == OffsetMode.Left:
            if c_index in c_core:
                return worldPoint.x - (p + Vector3(0.5f, 0.0f)).x > -1e-5f
            elif c_index in r_core:
                return worldPoint.x - (p + Vector3(1.5f, 0.0f)).x > -1e-5f
            elif c_index == i_right:
                return worldPoint.x - (p + Vector3(2.0f, 0.0f)).x > -1e-5f
        elif _offsetMode == OffsetMode.Right:
            if c_index in c_core:
                return worldPoint.x - (p + Vector3(-0.5f, 0.0f)).x > 1e-5f
            elif c_index in l_core:
                return worldPoint.x - (p + Vector3(-1.5f, 0.0f)).x < 1e-5f
            elif c_index == i_left:
                return worldPoint.x - (p + Vector3(-2.0f, 0.0f)).x < 1e-5f
        else:
            if c_index in r_core:
                return worldPoint.x - (p + Vector3(0.5f, 0.0f)).x > -1e-5f
            elif c_index == i_right:
                return worldPoint.x - (p + Vector3(1.0f, 0.0f)).x > -1e-5f
            elif c_index in l_core:
                return worldPoint.x - (p + Vector3(-0.5f, 0.0f)).x < 1e-5f
            elif c_index == i_left:
                return worldPoint.x - (p + Vector3(-1.0f, 0.0f)).x < 1e-5f
        c_pos = Autotile.ConnectionPosition(self, c_index, 0.0f)
        return Mathf.Abs(worldPoint.x - c_pos.x) < 1e-5f

    def ConnectionCanReachVerticaly(c_index as int, worldPoint as Vector3) as bool:
        p = transform.position
        u_core = IndexSet.up_wing_core
        d_core = IndexSet.down_wing_core
        c_core = IndexSet.non_vertical
        if _offsetMode == OffsetMode.Bottom:
            if c_index in c_core:
                return worldPoint.y - (p + Vector3(0.0f, 0.5f)).y > -1e-5f
            elif c_index in u_core:
                return worldPoint.y - (p + Vector3(0.0f, 1.5f)).y > -1e-5f
            elif c_index == i_up:
                return worldPoint.y - (p + Vector3(0.0f, 2.0f)).y > -1e-5f
        elif _offsetMode == OffsetMode.Top:
            if c_index in c_core:
                return worldPoint.y - (p + Vector3(0.0f, -0.5f)).y < 1e-5f
            elif c_index in d_core:
                return worldPoint.y - (p + Vector3(0.0f, -1.5f)).y < 1e-5f
            elif c_index == i_down:
                return worldPoint.y - (p + Vector3(0.0f, -2.0f)).y < 1e-5f
        else:
            if c_index in u_core:
                return worldPoint.y - (p + Vector3(0.0f, 0.5f)).y > -1e-5f
            elif c_index == i_up:
                return worldPoint.y - (p + Vector3(0.0f, 1.0f)).y > -1e-5f
            elif c_index in d_core:
                return worldPoint.y - (p + Vector3(0.0f, -0.5f)).y < 1e-5f
            elif c_index == i_down:
                return worldPoint.y - (p + Vector3(0.0f, -1.0f)).y < 1e-5f
        c_pos = Autotile.ConnectionPosition(self, c_index, 0.0f)
        return Mathf.Abs(worldPoint.y - c_pos.y) < 1e-5f

    def ConformToConnection(c_index as int, position as Vector3):
        ScaleCToPos(c_index, position)
        Rebuild()
        c_index = GetMovedConnection(c_index)
        MoveCToPos(c_index, position)
        PushNeighbours()

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

    # def TestConformsToConnection(c_index as int, position as Vector3):

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
                other_half_w = other_t.localScale.x / 2.0f
                other_half_h = other_t.localScale.y / 2.0f
                local_half_w = transform.localScale.x / 2.0f
                local_half_h = transform.localScale.y / 2.0f
                other_p = other.OffsetPosition()
                other_x = other_p.x
                other_y = other_p.y
                local_p = OffsetPosition()
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

    private static final singleVertices = (
            Vector3(-0.5f, -0.5f), Vector3(-0.5f,  0.5f), Vector3( 0.5f,  0.5f),
            Vector3( 0.5f,  0.5f), Vector3( 0.5f, -0.5f), Vector3(-0.5f, -0.5f),)
    private static final doubleHorizontalVertices = (
            Vector3(-0.5f, -0.5f),  Vector3(-0.5f,  0.5f),  Vector3( 0.0f,  0.5f),
            Vector3( 0.0f,  0.5f),  Vector3( 0.0f, -0.5f),  Vector3(-0.5f, -0.5f),
            Vector3( 0.0f, -0.5f),  Vector3( 0.0f,  0.5f),  Vector3( 0.5f,  0.5f),
            Vector3( 0.5f,  0.5f),  Vector3( 0.5f, -0.5f),  Vector3( 0.0f, -0.5f),)
    private static final doubleVerticalVertices = (
            Vector3(-0.5f,  0.0f),  Vector3(-0.5f,  0.5f),  Vector3( 0.5f,  0.5f),
            Vector3( 0.5f,  0.5f),  Vector3( 0.5f,  0.0f),  Vector3(-0.5f,  0.0f),
            Vector3(-0.5f, -0.5f),  Vector3(-0.5f,  0.0f),  Vector3( 0.5f,  0.0f),
            Vector3( 0.5f,  0.0f),  Vector3( 0.5f, -0.5f),  Vector3(-0.5f, -0.5f),)
    private static final singleTriangles = ( 0, 1, 2, 3, 4, 5, )
    private static final doubleTriangles = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, )
    private static final tripleTriangles = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, )

    private static def TileUVs(t as Tile) as (Vector2):
        return TileUVs(t, 1.0f, TileDirection.Horizontal)

    private static def TileUVs(t as Tile, fraction as single, direction as TileDirection) as (Vector2):
        if direction == TileDirection.Horizontal:
            xMin = t.atlasLocation.xMin
            xMax = (1.0f - fraction) * xMin + fraction * t.atlasLocation.xMax
            yMin = t.atlasLocation.yMin
            yMax = t.atlasLocation.yMax
        else:
            xMin = t.atlasLocation.xMin
            xMax = t.atlasLocation.xMax
            yMin = t.atlasLocation.yMin
            yMax = (1.0f - fraction) * yMin + fraction * t.atlasLocation.yMax
        # unless fraction == 1.0f:
        #     Debug.Log("tile not 1.0f ($(xMin)-$(xMax), $(yMin)-$(yMax))")
        #     Debug.Log("$(t.direction) $(t.flipped)")
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

    def ApplyHorizontalTile():
        air_info = getAirInfo()
        left = getLeftCorner(air_info)
        right = getRightCorner(air_info)
        mf = GetComponent of MeshFilter()
        mf.sharedMesh.vertices = OffsetVertices(Autotile.doubleHorizontalVertices)
        mf.sharedMesh.triangles = Autotile.doubleTriangles
        mf.sharedMesh.uv = Autotile.TileUVs(left) + Autotile.TileUVs(right)
        mf.sharedMesh.RecalculateNormals()

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

    def ApplyLongTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]], direction as TileDirection):
        air_info = getAirInfo()
        if direction == TileDirection.Horizontal:
            width = transform.localScale.x
            black_center = horizontalFace == HorizontalFace.None
            draw_first_corner = not connections.left or connections.upLeft or connections.downLeft
            draw_last_corner = not connections.right or connections.upRight or connections.downRight
            left = getLeftCorner(air_info) if draw_first_corner
            right = getRightCorner(air_info) if draw_last_corner
        else:
            width = transform.localScale.y
            black_center = verticalFace == VerticalFace.None
            draw_first_corner = not connections.down or connections.leftDown or connections.rightDown
            draw_last_corner = not connections.up or connections.leftUp or connections.rightUp
            left = getBottomCorner(air_info) if draw_first_corner
            right = getTopCorner(air_info) if draw_last_corner

        if draw_first_corner:
            if draw_last_corner:
                spareSpace = width - 2.0f
            else:
                spareSpace = width - 1.0f
        elif draw_last_corner:
            spareSpace = width - 1.0f
        else:
            spareSpace = width

        if black_center:
            centerUnits = 1
        elif squeezeMode == SqueezeMode.Clip:
            centerUnits = Mathf.Ceil(spareSpace) cast int
        else:
            centerUnits = Mathf.Round(spareSpace) cast int
        cornerSize = 1f / width

        if draw_first_corner:
            firstSplit = -0.5f + cornerSize
            vertices = TileSlice(-0.5f, firstSplit, direction)
            uvs = Autotile.TileUVs(left)
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
            if tileWidth > max_splits_to_use:
                enumeratorHealthy = ctEnumerator.MoveNext()
            else:
                currentSplitIndex += tileWidth
                if currentSplitIndex == centerUnits:
                    if not black_center and squeezeMode == SqueezeMode.Clip:
                        fractionOfTile = (lastSplit - currentSplit) / (splitWidth * tileWidth)
                    else:
                        fractionOfTile = 1.0f
                    vertices += TileSlice(currentSplit, lastSplit, direction)
                    uvs += Autotile.TileUVs(tile, fractionOfTile, direction)
                else:
                    nextSplit = currentSplit + splitWidth * tileWidth
                    vertices += TileSlice(currentSplit, nextSplit, direction)
                    uvs += Autotile.TileUVs(tile)

                tilesSpent += 1
                currentSplit = nextSplit

        if draw_last_corner:
            vertices += TileSlice(lastSplit, 0.5f, direction)
            uvs += Autotile.TileUVs(right)
            tilesSpent += 1

        mf = GetComponent of MeshFilter()
        mf.sharedMesh.vertices = vertices
        mf.sharedMesh.triangles = array(int, (i for i in range(6 * tilesSpent)))
        mf.sharedMesh.uv = uvs
        mf.sharedMesh.RecalculateNormals()

    def ApplyHorizontalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]]):
        ApplyLongTile(
            centerTiles,
            TileDirection.Horizontal)

    def ApplyVerticalTile():
        air_info = getAirInfo()
        bottom = getBottomCorner(air_info)
        top = getTopCorner(air_info)
        mf = GetComponent of MeshFilter()
        mf.sharedMesh.vertices = OffsetVertices(Autotile.doubleVerticalVertices)
        mf.sharedMesh.triangles = Autotile.doubleTriangles
        mf.sharedMesh.uv = Autotile.TileUVs(bottom) + Autotile.TileUVs(top)
        mf.sharedMesh.RecalculateNormals()

    def ApplyVerticalTile(centerTiles as Generic.IEnumerable[of Generic.KeyValuePair[of int, Tile]]):
        ApplyLongTile(
            centerTiles,
            TileDirection.Vertical)

    def ApplyTile(tile as Tile):
        uvs = (
            Vector2(tile.atlasLocation.xMin, tile.atlasLocation.yMin),
            Vector2(tile.atlasLocation.xMin, tile.atlasLocation.yMax),
            Vector2(tile.atlasLocation.xMax, tile.atlasLocation.yMax),
            Vector2(tile.atlasLocation.xMax, tile.atlasLocation.yMax),
            Vector2(tile.atlasLocation.xMax, tile.atlasLocation.yMin),
            Vector2(tile.atlasLocation.xMin, tile.atlasLocation.yMin))
        mf = GetComponent of MeshFilter()
        if mf.sharedMesh:
            mf.sharedMesh.vertices = OffsetVertices(Autotile.singleVertices)
            mf.sharedMesh.triangles = Autotile.singleTriangles
            mf.sharedMesh.uv = uvs
            mf.sharedMesh.RecalculateNormals()

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

    def CornersNeeded() as int:
        if tileMode == TileMode.Horizontal and not CanScaleHorizontalyToCentric() or\
           tileMode == TileMode.Vertical   and not CanScaleVerticalyToCentric():
            return 2
        elif tileMode == TileMode.Horizontal and\
            connections.left and connections.right:
            for i in IndexSet.up_down_face:
                if connections[i]:
                    return 1
            return 0
        elif tileMode == TileMode.Vertical and\
            connections.up and connections.down:
            for i in IndexSet.left_right_face:
                if connections[i]:
                    return 1
            return 0
        else:
            return 1

    class AirInfo:
        # info whether corners are
        # in contact with air
        #
        #    __X__
        #   |     |
        # X |     | X
        #   |     |
        #    ^^X^^
        #
        public up as bool
        public down as bool
        public left as bool
        public right as bool

    def getAirInfo() as AirInfo:
        result = AirInfo()
        result.up    = horizontalFace in (HorizontalFace.Double, HorizontalFace.Up)
        result.down  = horizontalFace in (HorizontalFace.Double, HorizontalFace.Down)
        result.left  = verticalFace in (VerticalFace.Double, VerticalFace.Left)
        result.right = verticalFace in (VerticalFace.Double, VerticalFace.Right)
        return result

    def getHorizontalConnectionClassification(\
            c as Autotile,
            air_top_default as bool,
            air_bottom_default as bool) as string:
        if c and c.secondaryTileMode == TileMode.Horizontal:
            hface_directions_cgx c.horizontalFace:
                return "c"
                return "g"
                return "d"
        else:
            if_00_01_10_11 air_top_default, air_bottom_default:
                return "b"
                return "c"
                return "g"
                return "a"

    def getVerticalConnectionClassification(\
            c as Autotile,
            air_left_default as bool,
            air_right_default as bool) as string:
        if c and c.secondaryTileMode == TileMode.Vertical:
            vface_directions_lrx c.verticalFace:
                return "l"
                return "r"
                return "d"
        else:
            if_00_01_10_11 air_left_default, air_right_default:
                return "b"
                return "r"
                return "l"
                return "a"

    def getRightCorner(air_info as AirInfo):
        w = getVerticalConnectionClassification(\
                connections.upRight,
                air_info.up,
                air_info.right)

        r = connections.right
        if r:
            hface_directions_cgx r.horizontalFace:
                x = "c"
                x = "g"
                x = "d"
        else:
            vface_directions_lrx verticalFace:
                x = "b"
                x = "a"
                x = "a"

        y = getVerticalConnectionClassification(\
                connections.downRight,
                air_info.down,
                air_info.right)

        hface_directions_cgx horizontalFace:
            z = "c"
            z = "g"
            z = "d"

        return AutotileConfig.config.sets[tilesetKey].corners["$w$x$y$z"]

    def getLeftCorner(air_info as AirInfo):
        w = getVerticalConnectionClassification(\
                connections.upLeft,
                air_info.left,
                air_info.up)

        hface_directions_cgx horizontalFace:
            x = "c"
            x = "g"
            x = "d"

        y = getVerticalConnectionClassification(\
                connections.downLeft,
                air_info.left,
                air_info.down)

        l = connections.left
        if l:
            hface_directions_cgx l.horizontalFace:
                z = "c"
                z = "g"
                z = "d"
        else:
            vface_directions_lrx verticalFace:
                z = "a"
                z = "b"
                z = "a"

        return AutotileConfig.config.sets[tilesetKey].corners["$w$x$y$z"]

    def getTopCorner(air_info as AirInfo):
        u = connections.up
        if u:
            vface_directions_lrx u.verticalFace:
                w = "l"
                w = "r"
                w = "d"
        else:
            hface_directions_cgx horizontalFace:
                w = "b"
                w = "a"
                w = "a"

        x = getHorizontalConnectionClassification(\
                connections.rightUp,
                air_info.up,
                air_info.right)

        vface_directions_lrx verticalFace:
            y = "l"
            y = "r"
            y = "d"

        z = getHorizontalConnectionClassification(\
                connections.leftUp,
                air_info.up,
                air_info.left)

        return AutotileConfig.config.sets[tilesetKey].corners["$w$x$y$z"]

    def getBottomCorner(air_info as AirInfo):
        vface_directions_lrx verticalFace:
            w = "l"
            w = "r"
            w = "d"

        x = getHorizontalConnectionClassification(\
                connections.rightDown,
                air_info.right,
                air_info.down)

        d = connections.down
        if d:
            vface_directions_lrx d.verticalFace:
                y = "l"
                y = "r"
                y = "d"
        else:
            hface_directions_cgx horizontalFace:
                y = "a"
                y = "b"
                y = "a"

        z = getHorizontalConnectionClassification(\
                connections.leftDown,
                air_info.left,
                air_info.down)

        return AutotileConfig.config.sets[tilesetKey].corners["$w$x$y$z"]

    def ApplyHorizontal(dim as int):
        try:
            tileMode = secondaryTileMode = TileMode.Horizontal
            UseHorizontalConnections()
            if dim == 2 and (CornersNeeded() == 2 or not squeezeMode == SqueezeMode.Clip):
                ApplyHorizontalTile()
            else:
                if horizontalFace == HorizontalFace.Up:
                    ApplyHorizontalTile(DescendingUpFaces(tilesetKey))
                elif horizontalFace == HorizontalFace.Down:
                    ApplyHorizontalTile(DescendingDownFaces(tilesetKey))
                elif horizontalFace == HorizontalFace.None:
                    ApplyHorizontalTile(DescendingNoneFaces(tilesetKey))
                else:
                    horizontalFace = HorizontalFace.Double
                    ApplyHorizontalTile(DescendingDoubleHorizontalFaces(tilesetKey))
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyVertical(dim as int):
        try:
            tileMode = secondaryTileMode = TileMode.Vertical
            UseVerticalConnections()
            if dim == 2 and not (connections.up or connections.down):
                ApplyVerticalTile()
            else:
                if verticalFace == VerticalFace.Left:
                    ApplyVerticalTile(DescendingLeftFaces(tilesetKey))
                elif verticalFace == VerticalFace.Right:
                    ApplyVerticalTile(DescendingRightFaces(tilesetKey))
                elif verticalFace == VerticalFace.None:
                    ApplyVerticalTile(DescendingNoneFaces(tilesetKey))
                else:
                    verticalFace = VerticalFace.Double
                    ApplyVerticalTile(DescendingDoubleVerticalFaces(tilesetKey))
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyCentric():
        try:
            tileMode = TileMode.Centric
            UseCentricConnections()
            ApplyTile(AutotileConfig.config.sets[tilesetKey].corners.aaaa)
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyNone():
        try:
            tileMode = secondaryTileMode = TileMode.None
            ApplyTile(AutotileConfig.config.sets[tilesetKey].corners.bbbb)
        except e as Generic.KeyNotFoundException:
            return
        except e as System.ArgumentNullException:
            return

    def ApplyScale():
        x = Mathf.Max(1f, Mathf.Round(transform.localScale.x)) cast int
        y = Mathf.Max(1f, Mathf.Round(transform.localScale.y)) cast int
        if squeezeMode == SqueezeMode.Clip:
            if secondaryTileMode == TileMode.Horizontal and (connections.left or connections.right) or transform.localScale.x > 2.0f:
                x = Mathf.Ceil(transform.localScale.x) cast int
            if secondaryTileMode == TileMode.Vertical and (connections.up or connections.down) or transform.localScale.y > 2.0f:
                y = Mathf.Ceil(transform.localScale.y) cast int
        if applied_discrete_width != x or applied_discrete_height != y or dirty:
            dirty = false
            if horizontalFace == HorizontalFace.None and verticalFace == VerticalFace.None:
                ApplyNone()
            else:
                applied_discrete_width = x
                applied_discrete_height = y
                applied_scale = transform.localScale
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
        if applied_scale != transform.localScale:
            if horizontalFace == HorizontalFace.None and verticalFace == VerticalFace.None:
                applied_scale = transform.localScale
            else:
                if x == 1 and y >= 2:
                    ApplyVertical(y)
                    applied_scale = transform.localScale
                elif y == 1 and x >= 2:
                    ApplyHorizontal(x)
                    applied_scale = transform.localScale

    def ApplyFace():
        if applied_horizontal_face != horizontalFace or applied_vertical_face != verticalFace:
            applied_horizontal_face = horizontalFace
            applied_vertical_face = verticalFace
            dirty = true

    def SuggestScales() as Vector3:
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
    def OnDestroy():
        unless workingOnConnections:
            try:
                workingOnConnections = true
                for i, remote as Autotile in enumerate(connections):
                    if remote:
                        remote.connections[connections.reverse[i]] = null
                        remote.Refresh()
            ensure:
                workingOnConnections = false

    def ApplyOffset():
        if applied_offset != offset:
            applied_offset = offset
            dirty = true

    def ApplyTilesetKey():
        if applied_tileset_key != tilesetKey:
            applied_tileset_key = tilesetKey
            dirty = true

    def Refresh():
        ApplyTilesetKey()
        ApplyOffset()
        ApplyFace()
        ApplyScale()

    [ContextMenu("Force Rebuild")]
    def Rebuild():
        dirty = true
        transform.localScale = SuggestScales()
        Refresh()
