import UnityEngine
import UnityEditor
import System.Collections

[CustomEditor(Autotile), CanEditMultipleObjects]
class AutotileEditor (Editor, TextureScaleProgressListener):

    tile as Autotile
    localTransform as Transform

    airGuiContent as GUIContent
    blackGuiContent as GUIContent

    squeezeModeProp                as SerializedProperty
    tileModeProp                   as SerializedProperty
    boxColliderMarginProp          as SerializedProperty
    useBoxColliderMarginLeftProp   as SerializedProperty
    useBoxColliderMarginRightProp  as SerializedProperty
    useBoxColliderMarginBottomProp as SerializedProperty
    useBoxColliderMarginTopProp    as SerializedProperty

    private prev_pivot_mode as PivotMode
    private blackAirInfo = Autotile.AirInfoState(false, false, false, false,false, false, false, false)

    def OnEnable():
        tile = target as Autotile

        airGuiContent = GUIContent(AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Icons/Air/air3.png", Texture))
        blackGuiContent = GUIContent(AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Icons/Air/air3-black.png", Texture))

        squeezeModeProp       = serializedObject.FindProperty("squeezeMode")
        tileModeProp          = serializedObject.FindProperty("tileMode")
        boxColliderMarginProp = serializedObject.FindProperty("boxColliderMargin")
        useBoxColliderMarginLeftProp   = serializedObject.FindProperty("useBoxColliderMarginLeft")
        useBoxColliderMarginRightProp  = serializedObject.FindProperty("useBoxColliderMarginRight")
        useBoxColliderMarginBottomProp = serializedObject.FindProperty("useBoxColliderMarginBottom")
        useBoxColliderMarginTopProp    = serializedObject.FindProperty("useBoxColliderMarginTop")

        localTransform = tile.transform

        prev_pivot_mode = Tools.pivotMode
        Tools.pivotMode = PivotMode.Pivot

        for t in FindObjectsOfType(Autotile):
            ts = AutotileConfig.config.sets[t.tilesetKey]
            tsm = ts.material if ts
            mt = tsm.mainTexture if tsm
            if mt and t.renderer.sharedMaterial != tsm:
                t.renderer.material = tsm
                EditorUtility.SetDirty(t.renderer)

        p = EndSnapshot as EditorApplication.CallbackFunction
        unless EditorApplication.modifierKeysChanged and p in EditorApplication.modifierKeysChanged.GetInvocationList():
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
        DestroyImmediate(fullTile)

    private preview_failure = false
    private try_again = true
    def PopulatePreview(air_info as Autotile.AirInfoState) as bool:
        if not preview_failure and\
           (try_again or\
            not tile.preview or\
            tile.previewTileMode != tile.tileMode or\
            not tile.previewAirInfo.Equals(air_info)):

            try:
                try_again = false
                tile.previewTileMode = tile.tileMode
                tile.previewAirInfo  = air_info

                ts = AutotileConfig.config.sets[tile.tilesetKey]
                unless ts.material:
                    preview_failure = true
                    Debug.LogError("The tileset $(tile.tilesetKey) did not have a material to preview")
                    return false
                unless ts.material.mainTexture:
                    preview_failure = true
                    Debug.LogError("The material $(ts.material) did not have a texture to preview")
                    return false
                mt = ts.material.mainTexture as Texture2D
                nextPreview = Texture2D(60, 60, TextureFormat.ARGB32, false)
                nextPreview.SetPixels32(array(Color32, 3600))
                nextPreview.hideFlags = HideFlags.DontSave
                DestroyImmediate(tile.preview)
                if tile.tileMode == TileMode.Horizontal:
                    preview = Texture2D(30, 30, TextureFormat.ARGB32, false)
                    GetPreview(tile.getLeftCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(0, 15, 30, 30, preview.GetPixels())
                    GetPreview(tile.getRightCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(30, 15, 30, 30, preview.GetPixels())
                    nextPreview.Apply()
                    tile.preview = nextPreview
                    DestroyImmediate(preview)
                elif tile.tileMode == TileMode.Vertical:
                    preview = Texture2D(30, 30, TextureFormat.ARGB32, false)
                    GetPreview(tile.getTopCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(15, 30, 30, 30, preview.GetPixels())
                    GetPreview(tile.getBottomCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(15, 0, 30, 30, preview.GetPixels())
                    nextPreview.Apply()
                    tile.preview = nextPreview
                    DestroyImmediate(preview)
                else: # if tile.tileMode == TileMode.Centric:
                    preview = Texture2D(30, 30, TextureFormat.ARGB32, false)
                    GetPreview(tile.getCentricCorner(), ts.tileSize, mt, preview)
                    nextPreview.SetPixels(15, 15, 30, 30, preview.GetPixels())
                    nextPreview.Apply()
                    tile.preview = nextPreview
                    DestroyImmediate(preview)
            except e as UnityException:
                preview_failure = true
                Debug.LogError("$(tile.gameObject.name) did not have a readable texture to preview")
            except e as Generic.KeyNotFoundException:
                preview_failure = true
                Debug.LogError("$(tile.gameObject.name) did not find tileset to preview\n$(e.Message)")
            except e as System.ArgumentNullException:
                preview_failure = true
                Debug.LogError("$(tile.gameObject.name) did not find tileset to preview")
        return not preview_failure

    def Refresh(t as Autotile):
        t.Refresh()
        if t.unsaved:
            t.unsaved = false
            EditorUtility.SetDirty(t)
        if t.unsavedMesh:
            t.unsavedMesh = false
            mf = t.GetComponent of MeshFilter()
            EditorUtility.SetDirty(mf) if mf

    def MakeScreenTileChild(f as callable(Autotile)):
        screenObject = GameObject()
        screen = screenObject.AddComponent of Autotile()
        screen.transform.parent = localTransform
        f(screen)
        screen.airInfo = blackAirInfo
        screen.tileMode = TileMode.None
        screen.secondaryTileMode = TileMode.None
        screen.tilesetKey = tile.tilesetKey
        screen.renderer.material = AutotileConfig.config.sets[screen.tilesetKey].material
        screen.Refresh()
        Undo.RegisterCreatedObjectUndo(screenObject, "Create black tile")
        EditorUtility.SetDirty(tile)

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
                    new_material = AutotileConfig.config.sets[t.tilesetKey].material
                    unless t.renderer.sharedMaterial == new_material:
                        t.renderer.material = AutotileConfig.config.sets[t.tilesetKey].material
                        EditorUtility.SetDirty(t.renderer)
                    Refresh(t) if serializedObject.isEditingMultipleObjects

        if serializedObject.isEditingMultipleObjects:
            return

        EditorGUILayout.PropertyField(squeezeModeProp, GUIContent("Squeeze Mode"))
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
            Refresh(tile)

        offset_grid = GUILayoutUtility.GetRect(175.0f, 140.0f)
        GUI.Label(Rect(offset_grid.x + 20.0f, offset_grid.y + 5.0f, 200.0f, 15.0f), "Surroundings")

        left_top_button_rect     = Rect(offset_grid.x + 20.0f +  5.0f, offset_grid.y + 20.0f +  5.0f, 30.0f, 30.0f)
        top_button_rect          = Rect(offset_grid.x + 20.0f + 49.0f, offset_grid.y + 20.0f +  5.0f, 30.0f, 30.0f)
        right_top_button_rect    = Rect(offset_grid.x + 20.0f + 93.0f, offset_grid.y + 20.0f +  5.0f, 30.0f, 30.0f)
        left_button_rect         = Rect(offset_grid.x + 20.0f +  5.0f, offset_grid.y + 20.0f + 49.0f, 30.0f, 30.0f)
        center_rect              = Rect(offset_grid.x + 20.0f + 34.0f, offset_grid.y + 20.0f + 34.0f, 60.0f, 60.0f)
        right_button_rect        = Rect(offset_grid.x + 20.0f + 93.0f, offset_grid.y + 20.0f + 49.0f, 30.0f, 30.0f)
        left_bottom_button_rect  = Rect(offset_grid.x + 20.0f +  5.0f, offset_grid.y + 20.0f + 93.0f, 30.0f, 30.0f)
        bottom_button_rect       = Rect(offset_grid.x + 20.0f + 49.0f, offset_grid.y + 20.0f + 93.0f, 30.0f, 30.0f)
        right_bottom_button_rect = Rect(offset_grid.x + 20.0f + 93.0f, offset_grid.y + 20.0f + 93.0f, 30.0f, 30.0f)

        air_info_state = tile.airInfo
        air_info = Autotile.AirInfo(air_info_state)

        is_centric = tile.tileMode == TileMode.Centric
        is_horizontal = tile.tileMode == TileMode.Horizontal
        is_vertical = tile.tileMode == TileMode.Vertical
        is_none = tile.tileMode == TileMode.None
        has_left_corner   = is_centric or is_horizontal and tile.DrawsLeftCorner()
        has_right_corner  = is_centric or is_horizontal and tile.DrawsRightCorner()
        has_bottom_corner = is_centric or is_vertical and tile.DrawsBottomCorner()
        has_top_corner    = is_centric or is_vertical and tile.DrawsTopCorner()
        has_left_top_corner = is_none or has_left_corner or has_top_corner
        has_right_top_corner = is_none or has_right_corner or has_top_corner
        has_left_bottom_corner = is_none or has_left_corner or has_bottom_corner
        has_right_bottom_corner = is_none or has_right_corner or has_bottom_corner

        if tile.tileMode == TileMode.None:
            if true in (air_info.leftUp, air_info.rightUp, air_info.leftDown, air_info.rightDown):
                ReturnFromNoneScales()

        if has_left_top_corner and\
           ((air_info.leftUp and GUI.Button(left_top_button_rect, airGuiContent)) or\
            (not air_info.leftUp and GUI.Button(left_top_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left, air_info.right,
                                        air_info.down,       air_info.up,
                                        not air_info.leftUp, air_info.rightUp,
                                        air_info.leftDown,   air_info.rightDown)
        if is_horizontal and\
           ((air_info.up and GUI.Button(top_button_rect, airGuiContent)) or\
            (not air_info.up and GUI.Button(top_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left, air_info.right,
                                        air_info.down,     not air_info.up,
                                        air_info.leftUp,   air_info.rightUp,
                                        air_info.leftDown, air_info.rightDown)
        if has_right_top_corner and\
           ((air_info.rightUp and GUI.Button(right_top_button_rect, airGuiContent)) or\
            (not air_info.rightUp and GUI.Button(right_top_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left, air_info.right,
                                        air_info.down,     air_info.up,
                                        air_info.leftUp,   not air_info.rightUp,
                                        air_info.leftDown, air_info.rightDown)

        if is_vertical and\
           ((air_info.left and GUI.Button(left_button_rect, airGuiContent)) or\
            (not air_info.left and GUI.Button(left_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(not air_info.left, air_info.right,
                                        air_info.down,     air_info.up,
                                        air_info.leftUp,   air_info.rightUp,
                                        air_info.leftDown, air_info.rightDown)
        if PopulatePreview(air_info_state):
            GUI.DrawTexture(center_rect, tile.preview)

        if is_vertical and\
           ((air_info.right and GUI.Button(right_button_rect, airGuiContent)) or\
            (not air_info.right and GUI.Button(right_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left,     not air_info.right,
                                        air_info.down,     air_info.up,
                                        air_info.leftUp,   air_info.rightUp,
                                        air_info.leftDown, air_info.rightDown)

        if has_left_bottom_corner and\
           ((air_info.leftDown and GUI.Button(left_bottom_button_rect, airGuiContent)) or\
            (not air_info.leftDown and GUI.Button(left_bottom_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left,         air_info.right,
                                        air_info.down,         air_info.up,
                                        air_info.leftUp,       air_info.rightUp,
                                        not air_info.leftDown, air_info.rightDown)
        if is_horizontal and\
           ((air_info.down and GUI.Button(bottom_button_rect, airGuiContent)) or\
            (not air_info.down and GUI.Button(bottom_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left,      air_info.right,
                                        not air_info.down,  air_info.up,
                                        air_info.leftUp,    air_info.rightUp,
                                        air_info.leftDown,  air_info.rightDown)
        if has_right_bottom_corner and\
           ((air_info.rightDown and GUI.Button(right_bottom_button_rect, airGuiContent)) or\
            (not air_info.rightDown and GUI.Button(right_bottom_button_rect, blackGuiContent))):
            surrounding_change = true
            air_info = Autotile.AirInfo(air_info.left,     air_info.right,
                                        air_info.down,     air_info.up,
                                        air_info.leftUp,   air_info.rightUp,
                                        air_info.leftDown, not air_info.rightDown)

        if not tile.usesAirInfo and GUILayout.Button("Upgrade without change (ctrl+u)"):
            surrounding_change = true

        if surrounding_change:
            all_autotiles = FindObjectsOfType(Autotile)
            Undo.RegisterUndo(all_autotiles, "Change tile surroundings")
            tile.SetAndPropagateAirInfo(air_info)
            for one_tile as Autotile in all_autotiles:
                Refresh(one_tile)

        GUI.enabled = true

        offset_grid = GUILayoutUtility.GetRect(200.0f, 125.0f)
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

        if is_horizontal and localTransform.localScale.x > 2.0f:
            if not tile.topScreen:
                if not air_info.up and GUILayout.Button("Insert top black tile"):
                    MakeScreenTileChild() do(t):
                        tile.topScreen = t
                        t.gameObject.name = "top_black_tile"
                        t.transform.localPosition = tile.offset + Vector2(0.0f, 2.0f)
                        t.transform.localScale = Vector2(1.0f, 3.0f)
                        t.offsetMode = OffsetMode.Bottom
            elif GUILayout.Button("Remove top black tile"):
                DestroyImmediate(tile.topScreen.gameObject)
            if not tile.bottomScreen:
                if not air_info.down and GUILayout.Button("Insert bottom black tile"):
                    MakeScreenTileChild() do(t):
                        tile.bottomScreen = t
                        t.gameObject.name = "bottom_black_tile"
                        t.transform.localPosition = tile.offset + Vector2(0.0f, -2.0f)
                        t.transform.localScale = Vector2(1.0f, 3.0f)
                        t.offsetMode = OffsetMode.Top
            elif GUILayout.Button("Remove bottom black tile"):
                DestroyImmediate(tile.bottomScreen.gameObject)
        elif is_vertical and localTransform.localScale.y > 2.0f:
            if not tile.leftScreen:
                if not air_info.left and GUILayout.Button("Insert left black tile"):
                    MakeScreenTileChild() do(t):
                        tile.leftScreen = t
                        t.gameObject.name = "left_black_tile"
                        t.transform.localPosition = tile.offset + Vector2(-2.0f, 0.0f)
                        t.transform.localScale = Vector2(3.0f, 1.0f)
                        t.offsetMode = OffsetMode.Right
            elif GUILayout.Button("Remove left black tile"):
                DestroyImmediate(tile.leftScreen.gameObject)
            if not tile.rightScreen:
                if not air_info.right and GUILayout.Button("Insert right black tile"):
                    MakeScreenTileChild() do(t):
                        tile.rightScreen = t
                        t.gameObject.name = "right_black_tile"
                        t.transform.localPosition = tile.offset + Vector2(2.0f, 0.0f)
                        t.transform.localScale = Vector2(3.0f, 1.0f)
                        t.offsetMode = OffsetMode.Left
            elif GUILayout.Button("Remove right black tile"):
                DestroyImmediate(tile.rightScreen.gameObject)

        serializedObject.ApplyModifiedProperties()
        Refresh(tile)

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
    private tiles_to_resize = 0
    private control_and_handle_resizing = false
    def SnapshotImmediately():
        if resizing_tiles:
            control_and_handle_resizing = true
        else:
            affected_transforms = array(Component, [t.transform for t in FindObjectsOfType(Autotile)])
            affected_tiles = array(Component, FindObjectsOfType(Autotile))
            affected = affected_transforms + affected_tiles
            Undo.SetSnapshotTarget(affected, "Resize/Move Autotiles")

            Undo.CreateSnapshot()
            Undo.RegisterSnapshot()
            Undo.ClearSnapshotTarget()

    def StartSnapshot():
        unless resizing_tiles:
            tiles = array(Transform, [t.transform for t in FindObjectsOfType(Autotile)])
            tiles_to_resize = tiles.Length
            Undo.SetSnapshotTarget(tiles, "Resize Autotile Length")
            Undo.CreateSnapshot()
            resizing_tiles = true

    def EndSnapshot():
        if resizing_tiles:
            tiles = array(Transform, [t.transform for t in FindObjectsOfType(Autotile)])
            unless control_and_handle_resizing or tiles_to_resize != tiles.Length:
                Undo.SetSnapshotTarget(tiles, "Resize Autotile Length")
                Undo.RegisterSnapshot()
                Undo.ClearSnapshotTarget()
            resizing_tiles = false
        control_and_handle_resizing = false

    def NormalizeScales():
        tile.transform.localRotation = Quaternion.identity
        tile.transform.localPosition.z = 0.0f
        tile.transform.localScale = tile.SuggestScales()

    def ReturnFromNoneScales():
        x = tile.transform.localScale.x
        y = tile.transform.localScale.y
        if x < y:
            tile.transform.localScale.x = 1.0f
        else:
            tile.transform.localScale.y = 1.0f

    private do_autotile_upgrades as bool
    def OnSceneGUI():

        if do_autotile_upgrades:
            do_autotile_upgrades = false
            AutotileMenus.UpgradeAutotiles()

        if Event.current.type == EventType.Repaint:
            for t in FindObjectsOfType(Autotile):
                Refresh(t)
                unless t.renderer.sharedMaterial:
                    t.renderer.material = AutotileConfig.config.sets[t.tilesetKey].material
                    EditorUtility.SetDirty(t.renderer)
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
            Refresh(tile)
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
                        changed = true
                    elif one_tile.secondaryTileMode == TileMode.Vertical:
                        one_tile.transform.localScale.y -= Event.current.delta.y / 3.0f
                        one_tile.transform.localScale = one_tile.SuggestScales()
                        changed = true
                    elif one_tile.secondaryTileMode == TileMode.Centric:
                        if one_tile.offsetMode in (OffsetMode.Bottom, OffsetMode.Top):
                            one_tile.transform.localScale.y -= Event.current.delta.y / 3.0f
                            one_tile.Refresh()
                            one_tile.transform.localScale = one_tile.SuggestScales()
                            changed = true
                        elif one_tile.offsetMode in (OffsetMode.Left, OffsetMode.Right):
                            one_tile.transform.localScale.x -= Event.current.delta.y / 3.0f
                            one_tile.Refresh()
                            one_tile.transform.localScale = one_tile.SuggestScales()
                            changed = true
                    if changed:
                        one_tile.Refresh()
                        one_tile.PushNeighbours()
                        Refresh(one_tile)

                    Event.current.Use()
                    break

        elif Event.current.type == EventType.MouseUp and Event.current.button == 0:
            NormalizeScales()
            Refresh(tile)

            local_collision_quad = tile.OffsetVertices2(MarginQuad(0.0f, localTransform))
            intersects = Generic.List of Autotile()
            for other_tile as Autotile in FindObjectsOfType(Autotile):
                continue if other_tile == tile
                continue if other_tile.transform.parent != tile.transform.parent

                from_other = other_tile.transform.localToWorldMatrix.MultiplyPoint3x4
                to_local = localTransform.worldToLocalMatrix.MultiplyPoint3x4

                other_collision_quad = other_tile.OffsetVertices2(MarginQuad(0.03f, other_tile.transform))
                t_vertices3 = array(Vector3, ( to_local(from_other(v)) for v in other_collision_quad ))
                t_vertices2 = System.Array.ConvertAll[of Vector3, Vector2](t_vertices3, {v as Vector3| return v})

                intersects.Add(other_tile) if MathOfPlanes.RectIntersectsRect(local_collision_quad, t_vertices2)

            affected = Generic.List of Autotile(intersects)
            for n in tile.connections:
                affected.Add(n) unless not n or n in affected

            affected_tiles = (tile as Component,) + array(Component, affected)
            affected_transforms = array(Component, affected.Count + 1)
            affected_transforms[affected.Count] = tile.transform
            for i, affected_tile as Autotile in enumerate(affected_tiles):
                affected_transforms[i] = affected_tile.transform

            tile.ConnectToTiles(intersects)
            tile.PushNeighbours()

            for affected_tile in affected_tiles:
                Refresh(affected_tile)
            for affected_transform in affected_transforms:
                EditorUtility.SetDirty(affected_transform)

        elif Event.current.type == EventType.MouseDown and Event.current.button == 0:
            SnapshotImmediately()
