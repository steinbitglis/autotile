import UnityEngine
import UnityEditor
import System.Collections

[CustomEditor(Autotile)]
class AutotileEditor (Editor):

    tile as Autotile
    localTransform as Transform

    squeezeModeProp    as SerializedProperty
    horizontalFaceProp as SerializedProperty
    verticalFaceProp   as SerializedProperty
    tileModeProp       as SerializedProperty

    def Awake():
        tile = target as Autotile

        squeezeModeProp    = serializedObject.FindProperty("squeezeMode")
        horizontalFaceProp = serializedObject.FindProperty("horizontalFace")
        verticalFaceProp   = serializedObject.FindProperty("verticalFace")
        tileModeProp       = serializedObject.FindProperty("tileMode")

        localTransform = tile.transform

    virtual def OnInspectorGUI():
        serializedObject.Update()

        tilesets = array(string, AutotileConfig.config.sets.Count)
        for i as int, e as KeyValuePair[of string, AutotileSet] in enumerate(AutotileConfig.config.sets):
            currentIndex = i if e.Key == tile.tilesetKey
            tilesets[i] = e.Key
        unless tile.tilesetKey in tilesets:
            tilesets = ("",) + tilesets
        newIndex = EditorGUILayout.Popup("Tileset", currentIndex, tilesets)
        if newIndex != currentIndex:
            Undo.RegisterUndo(tile, "Autotile tileset")
            currentIndex = newIndex
            tile.tilesetKey = tilesets[newIndex]
            tile.renderer.material = AutotileConfig.config.sets[tile.tilesetKey].material
            EditorUtility.SetDirty(tile)

        EditorGUILayout.PropertyField(squeezeModeProp, GUIContent("Squeeze Mode"))
        EditorGUILayout.PropertyField(horizontalFaceProp, GUIContent("Horizontal Face"))
        EditorGUILayout.PropertyField(verticalFaceProp, GUIContent("Vertical Face"))
        GUI.enabled = false
        EditorGUILayout.PropertyField(tileModeProp, GUIContent("Tile Mode"))
        GUI.enabled = true
        if GUILayout.Button("Reset all connections"):
            tile.ResetAllConnections()
            EditorUtility.SetDirty(tile)

        offset_grid = GUILayoutUtility.GetRect(200.0f, 110.0f)
        GUI.Label(Rect(offset_grid.x + 20.0f, offset_grid.y + 5.0f, 200.0f, 15.0f), "Offset from")

        up_button_rect     = Rect(offset_grid.x + 20.0f +  60.0f, offset_grid.y + 20.0f        , 60.0f, 30.0f)
        left_button_rect   = Rect(offset_grid.x + 20.0f         , offset_grid.y + 20.0f + 30.0f, 60.0f, 30.0f)
        center_button_rect = Rect(offset_grid.x + 20.0f +  60.0f, offset_grid.y + 20.0f + 30.0f, 60.0f, 30.0f)
        right_button_rect  = Rect(offset_grid.x + 20.0f + 120.0f, offset_grid.y + 20.0f + 30.0f, 60.0f, 30.0f)
        down_button_rect   = Rect(offset_grid.x + 20.0f +  60.0f, offset_grid.y + 20.0f + 60.0f, 60.0f, 30.0f)

        if GUI.Button(up_button_rect, "Top") and tile.offsetMode != OffsetMode.Top:
            tile.offsetMode = OffsetMode.Top
            EditorUtility.SetDirty(tile)
        if GUI.Button(left_button_rect, "Left") and tile.offsetMode != OffsetMode.Left:
            tile.offsetMode = OffsetMode.Left
            EditorUtility.SetDirty(tile)
        if GUI.Button(center_button_rect, "Center") and tile.offsetMode != OffsetMode.Center:
            tile.offsetMode = OffsetMode.Center
            EditorUtility.SetDirty(tile)
        if GUI.Button(right_button_rect, "Right") and tile.offsetMode != OffsetMode.Right:
            tile.offsetMode = OffsetMode.Right
            EditorUtility.SetDirty(tile)
        if GUI.Button(down_button_rect, "Bottom") and tile.offsetMode != OffsetMode.Bottom:
            tile.offsetMode = OffsetMode.Bottom
            EditorUtility.SetDirty(tile)

        serializedObject.ApplyModifiedProperties()
        tile.Refresh()

    def DrawAutotileConnections():
        for local_connection as int, remote as Autotile in enumerate(tile.connections):
            if remote:
                remote_connection = tile.connections.reverse[local_connection]
                a = Autotile.ConnectionPosition(tile,   local_connection, -0.2f)
                b = Autotile.ConnectionPosition(remote, remote_connection, -0.2f)
                Handles.color = Color.blue
                Handles.DrawAAPolyLine(0.03f, a, b)

    def MarginQuad(margin as single, tr as Transform) as (Vector2):
        margin_w = margin / tr.localScale.x
        margin_h = margin / tr.localScale.y
        return (Vector2(-0.5f + margin_w, -0.5f + margin_h), Vector2(-0.5f + margin_w,  0.5f - margin_h),
                Vector2( 0.5f - margin_w,  0.5f - margin_h), Vector2( 0.5f - margin_w, -0.5f + margin_h),)

    def OnSceneGUI():
        if Event.current.type == EventType.Repaint:
            tile.Refresh()
            DrawAutotileConnections()
        elif Event.current.type == EventType.ScrollWheel:
            tile.Refresh()
            ccam = Camera.current
            mouseRay = ccam.ScreenPointToRay(Vector3(Event.current.mousePosition.x, ccam.pixelHeight - Event.current.mousePosition.y, 0.0f))
            if mouseRay.direction.z > 0.0f:
                t = -mouseRay.origin.z / mouseRay.direction.z
                mouseWorldPos = mouseRay.origin + t * mouseRay.direction

            for one_tile as Autotile in FindObjectsOfType(Autotile):
                local_mouse = one_tile.transform.InverseTransformPoint(mouseWorldPos)
                if Mathf.Abs(local_mouse.x - one_tile.offset.x) < 0.5f and\
                   Mathf.Abs(local_mouse.y - one_tile.offset.y) < 0.5f:
                    if one_tile.tileMode in (TileMode.Horizontal, TileMode.Vertical):
                        one_tile.secondaryTileMode = one_tile.tileMode
                    changed = false
                    if one_tile.secondaryTileMode == TileMode.Horizontal:
                        one_tile.transform.localScale.x -= Event.current.delta.y / 3.0f
                        one_tile.transform.localScale = one_tile.SuggestScales()
                        one_tile.Refresh()
                        changed = true
                    elif one_tile.secondaryTileMode == TileMode.Vertical:
                        one_tile.transform.localScale.y -= Event.current.delta.y / 3.0f
                        one_tile.transform.localScale = one_tile.SuggestScales()
                        one_tile.Refresh()
                        changed = true
                    if changed:
                        one_tile.PushNeighbours()

                    Event.current.Use()
                    break
        elif Event.current.type == EventType.MouseUp and Event.current.button == 0:
            tile.transform.localRotation = Quaternion.identity
            tile.transform.localPosition.z = 0.0f
            tile.transform.localScale = tile.SuggestScales()
            tile.Refresh()

            local_collision_quad = tile.OffsetVertices2(MarginQuad(0.0f, localTransform))
            intersects = Generic.List of Autotile()
            for other_tile as Autotile in FindObjectsOfType(Autotile):
                continue if other_tile == tile

                from_other = other_tile.transform.localToWorldMatrix.MultiplyPoint3x4
                to_local = localTransform.worldToLocalMatrix.MultiplyPoint3x4

                other_collision_quad = other_tile.OffsetVertices2(MarginQuad(0.03f, other_tile.transform))
                t_vertices3 = array(Vector3, ( to_local(from_other(v)) for v in other_collision_quad ))
                t_vertices2 = System.Array.ConvertAll[of Vector3, Vector2](t_vertices3, {v as Vector3| return v})

                intersects.Add(other_tile) if MathOfPlanes.RectIntersectsRect(local_collision_quad, t_vertices2)
            tile.ConnectToTiles(intersects)

            tile.PushNeighbours()
