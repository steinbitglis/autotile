import UnityEngine
import UnityEditor
import System.Collections

[CustomEditor(Autotile), CanEditMultipleObjects]
class AutotileEditor (Editor, TextureScaleProgressListener):

    tile as Autotile
    localTransform as Transform

    squeezeModeProp                as SerializedProperty
    # horizontalFaceProp             as SerializedProperty
    # verticalFaceProp               as SerializedProperty
    tileModeProp                   as SerializedProperty
    boxColliderMarginProp          as SerializedProperty
    useBoxColliderMarginLeftProp   as SerializedProperty
    useBoxColliderMarginRightProp  as SerializedProperty
    useBoxColliderMarginBottomProp as SerializedProperty
    useBoxColliderMarginTopProp    as SerializedProperty

    private prev_pivot_mode as PivotMode

    def OnEnable():
        tile = target as Autotile

        squeezeModeProp       = serializedObject.FindProperty("squeezeMode")
        # horizontalFaceProp    = serializedObject.FindProperty("horizontalFace")
        # verticalFaceProp      = serializedObject.FindProperty("verticalFace")
        tileModeProp          = serializedObject.FindProperty("tileMode")
        boxColliderMarginProp = serializedObject.FindProperty("boxColliderMargin")
        useBoxColliderMarginLeftProp   = serializedObject.FindProperty("useBoxColliderMarginLeft")
        useBoxColliderMarginRightProp  = serializedObject.FindProperty("useBoxColliderMarginRight")
        useBoxColliderMarginBottomProp = serializedObject.FindProperty("useBoxColliderMarginBottom")
        useBoxColliderMarginTopProp    = serializedObject.FindProperty("useBoxColliderMarginTop")

        localTransform = tile.transform

        prev_pivot_mode = Tools.pivotMode
        Tools.pivotMode = PivotMode.Pivot

        p = EndSnapshot as EditorApplication.CallbackFunction
        unless p in EditorApplication.modifierKeysChanged.GetInvocationList():
            EditorApplication.modifierKeysChanged = System.Delegate.Combine(EditorApplication.modifierKeysChanged, p)

    def OnDisable():
        Tools.pivotMode = prev_pivot_mode

        p = EndSnapshot as EditorApplication.CallbackFunction
        EditorApplication.modifierKeysChanged = System.Delegate.RemoveAll(EditorApplication.modifierKeysChanged, p)

    def Progress(s as single):
        pass

    def GetPreview(t as Tile, tileSize as int, source as Texture2D, result as Texture2D):
        fullTile = Texture2D(tileSize, tileSize, TextureFormat.ARGB32, false)
        fullTile.SetPixels(source.GetPixels(t.atlasLocation.xMin * source.width, t.atlasLocation.yMin * source.height, tileSize, tileSize))
        if t.flipped:
            ourFlip = ((t.direction + 1) cast int) cast TextureScaleFlip
        if t.rotated:
            ourRotation = ((t.rotation + 1) cast int) cast TextureScaleRotate
        TextureScale.Bilinear(fullTile, result, self, TextureScaleTransform(ourFlip, ourRotation))

    private preview_failure = false
    private try_again = true
    def PopulatePreview() as bool:
        if not preview_failure and\
           (try_again or\
            not tile.preview or\
            tile.previewTileMode       != tile.tileMode or\
            tile.previewHorizontalFace != tile.horizontalFace or\
            tile.previewVerticalFace   != tile.verticalFace):

            try:
                try_again = false
                tile.previewTileMode       = tile.tileMode
                tile.previewHorizontalFace = tile.horizontalFace
                tile.previewVerticalFace   = tile.verticalFace

                ts = AutotileConfig.config.sets[tile.tilesetKey]
                mt = ts.material.mainTexture as Texture2D
                nextPreview = Texture2D(60, 60, TextureFormat.ARGB32, false)
                nextPreview.SetPixels32(array(Color32, 3600))
                if tile.tileMode == TileMode.Horizontal:
                    preview = Texture2D(30, 30, TextureFormat.ARGB32, false)
                    GetPreview(tile.getLeftCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(0, 15, 30, 30, preview.GetPixels())
                    GetPreview(tile.getRightCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(30, 15, 30, 30, preview.GetPixels())
                    nextPreview.Apply()
                    tile.preview = nextPreview
                elif tile.tileMode == TileMode.Vertical:
                    preview = Texture2D(30, 30, TextureFormat.ARGB32, false)
                    GetPreview(tile.getTopCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(15, 30, 30, 30, preview.GetPixels())
                    GetPreview(tile.getBottomCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(15, 0, 30, 30, preview.GetPixels())
                    nextPreview.Apply()
                    tile.preview = nextPreview
                else: # if tile.tileMode == TileMode.Vertical:
                    preview = Texture2D(30, 30, TextureFormat.ARGB32, false)
                    GetPreview(ts.corners.aaaa, ts.tileSize, mt, preview)
                    nextPreview.SetPixels(15, 15, 30, 30, preview.GetPixels())
                    nextPreview.Apply()
                    tile.preview = nextPreview
            except e as UnityException:
                preview_failure = true
                Debug.LogError("$(tile.gameObject.name) did not have a readable texture to preview")
            except e as Generic.KeyNotFoundException:
                preview_failure = true
                Debug.LogError("$(tile.gameObject.name) did not find tileset to preview")
            except e as System.ArgumentNullException:
                preview_failure = true
                Debug.LogError("$(tile.gameObject.name) did not find tileset to preview")
        return not preview_failure

    virtual def OnInspectorGUI():
        serializedObject.Update()

        EditorGUI.BeginChangeCheck()
        for t as Autotile in serializedObject.targetObjects:
            if t.tilesetKey != tile.tilesetKey:
                needMix = true
        EditorGUI.showMixedValue = serializedObject.isEditingMultipleObjects and needMix
        tilesets = array(string, AutotileConfig.config.sets.Count)
        for i as int, e as KeyValuePair[of string, AutotileSet] in enumerate(AutotileConfig.config.sets):
            currentIndex = i if e.Key == tile.tilesetKey
            tilesets[i] = e.Key
        unless needMix or tile.tilesetKey in tilesets:
            tilesets = ("",) + tilesets
        newIndex = EditorGUILayout.Popup("Tileset", currentIndex, tilesets)
        if EditorGUI.EndChangeCheck():
            undoSaved = false
            for t as Autotile in serializedObject.targetObjects:
                if tilesets[newIndex] != t.tilesetKey:
                    unless undoSaved:
                        undoSaved = true
                        Undo.RegisterUndo(serializedObject.targetObjects, "Change Autotile tileset")
                    t.tilesetKey = tilesets[newIndex]
                    t.renderer.material = AutotileConfig.config.sets[t.tilesetKey].material
                    t.Refresh() if serializedObject.isEditingMultipleObjects
                    EditorUtility.SetDirty(t)

        if serializedObject.isEditingMultipleObjects:
            return

        EditorGUILayout.PropertyField(squeezeModeProp, GUIContent("Squeeze Mode"))
        # EditorGUILayout.PropertyField(horizontalFaceProp, GUIContent("Horizontal Face"))
        # EditorGUILayout.PropertyField(verticalFaceProp, GUIContent("Vertical Face"))
        GUI.enabled = false
        EditorGUILayout.PropertyField(tileModeProp, GUIContent("Tile Mode"))
        GUI.enabled = true
        if tile.boxCollider:
            EditorGUILayout.PropertyField(boxColliderMarginProp, GUIContent("Box Collider Margin"))
            if boxColliderMarginProp.floatValue:
                EditorGUI.indentLevel += 1
                EditorGUILayout.PropertyField(useBoxColliderMarginLeftProp, GUIContent("Left"))
                EditorGUILayout.PropertyField(useBoxColliderMarginRightProp, GUIContent("Right"))
                EditorGUILayout.PropertyField(useBoxColliderMarginBottomProp, GUIContent("Bottom"))
                EditorGUILayout.PropertyField(useBoxColliderMarginTopProp, GUIContent("Top"))
                EditorGUI.indentLevel -= 1

        if GUILayout.Button("Reset local connections"):
            tile.ResetAllConnections()
            EditorUtility.SetDirty(tile)

        offset_grid = GUILayoutUtility.GetRect(175.0f, 140.0f)
        GUI.Label(Rect(offset_grid.x + 20.0f, offset_grid.y + 5.0f, 200.0f, 15.0f), "Surroundings")

        top_button_rect    = Rect(offset_grid.x + 20.0f + 49.0f, offset_grid.y + 20.0f         , 30.0f, 30.0f)
        left_button_rect   = Rect(offset_grid.x + 20.0f        , offset_grid.y + 20.0f + 49.0f, 30.0f, 30.0f)
        center_rect        = Rect(offset_grid.x + 20.0f + 34.0f, offset_grid.y + 20.0f + 34.0f, 60.0f, 60.0f)
        right_button_rect  = Rect(offset_grid.x + 20.0f + 98.0f, offset_grid.y + 20.0f + 49.0f, 30.0f, 30.0f)
        bottom_button_rect = Rect(offset_grid.x + 20.0f + 49.0f, offset_grid.y + 20.0f + 98.0f, 30.0f, 30.0f)

        air_left   = 1
        air_left   = 0 if tile.verticalFace in (VerticalFace.Left, VerticalFace.Double)
        air_right  = 1
        air_right  = 0 if tile.verticalFace in (VerticalFace.Right, VerticalFace.Double)
        air_bottom = 1
        air_bottom = 0 if tile.horizontalFace in (HorizontalFace.Down, HorizontalFace.Double)
        air_top    = 1
        air_top    = 0 if tile.horizontalFace in (HorizontalFace.Up, HorizontalFace.Double)
        air_gc = GUIContent(AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Icons/Air/air2.png", Texture))
        if GUI.Button(top_button_rect, air_gc):
            surrounding_change = true
            air_top = 1 - air_top
        if GUI.Button(left_button_rect, air_gc):
            surrounding_change = true
            air_left = 1 - air_left
        if PopulatePreview():
            GUI.DrawTexture(center_rect, tile.preview)
        if GUI.Button(right_button_rect, air_gc):
            surrounding_change = true
            air_right = 1 - air_right
        if GUI.Button(bottom_button_rect, air_gc):
            surrounding_change = true
            air_bottom = 1 - air_bottom
        if surrounding_change:
            Undo.RegisterUndo(tile, "Change tile surroundings")
            if_00_01_10_11 air_left, air_right:
                tile.verticalFace = VerticalFace.Double
                tile.verticalFace = VerticalFace.Left
                tile.verticalFace = VerticalFace.Right
                tile.verticalFace = VerticalFace.None
            if_00_01_10_11 air_top, air_bottom:
                tile.horizontalFace = HorizontalFace.Double
                tile.horizontalFace = HorizontalFace.Up
                tile.horizontalFace = HorizontalFace.Down
                tile.horizontalFace = HorizontalFace.None
            EditorUtility.SetDirty(tile)

        offset_grid = GUILayoutUtility.GetRect(200.0f, 110.0f)
        GUI.Label(Rect(offset_grid.x + 20.0f, offset_grid.y + 17.0f, 200.0f, 15.0f), "Offset from")

        up_button_rect     = Rect(offset_grid.x + 20.0f +  60.0f, offset_grid.y + 20.0f + 12.0f, 60.0f, 30.0f)
        left_button_rect   = Rect(offset_grid.x + 20.0f         , offset_grid.y + 20.0f + 42.0f, 60.0f, 30.0f)
        center_button_rect = Rect(offset_grid.x + 20.0f +  60.0f, offset_grid.y + 20.0f + 42.0f, 60.0f, 30.0f)
        right_button_rect  = Rect(offset_grid.x + 20.0f + 120.0f, offset_grid.y + 20.0f + 42.0f, 60.0f, 30.0f)
        down_button_rect   = Rect(offset_grid.x + 20.0f +  60.0f, offset_grid.y + 20.0f + 72.0f, 60.0f, 30.0f)

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

    private resizing_tiles = false
    def StartSnapshot():
        unless resizing_tiles:
            Undo.SetSnapshotTarget(array(Transform, [t.transform for t in FindObjectsOfType(Autotile)]), "Resize Autotiles")
            Undo.CreateSnapshot()
            resizing_tiles = true

    def EndSnapshot():
        if resizing_tiles:
            Undo.SetSnapshotTarget(array(Transform, [t.transform for t in FindObjectsOfType(Autotile)]), "Resize Autotiles")
            Undo.RegisterSnapshot()
            Undo.ClearSnapshotTarget()
            resizing_tiles = false

    def OnSceneGUI():
        if Event.current.type == EventType.Repaint:
            for t in FindObjectsOfType(Autotile):
                t.Refresh()
            DrawAutotileConnections()
        elif Event.current.type == EventType.KeyDown:
            if Event.current.keyCode == KeyCode.LeftControl or\
               Event.current.keyCode == KeyCode.RightControl:
                StartSnapshot()
        elif Event.current.type == EventType.KeyUp:
            if Event.current.keyCode == KeyCode.LeftControl or\
               Event.current.keyCode == KeyCode.RightControl:
                EndSnapshot()
        elif Event.current.type == EventType.ScrollWheel and Event.current.control:
            StartSnapshot()
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
                        EditorUtility.SetDirty(one_tile)

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
