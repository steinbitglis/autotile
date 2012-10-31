import UnityEngine
import UnityEditor

[CustomEditor(AutotileAnimation), CanEditMultipleObjects]
class AutotileAnimationEditor (Editor, TextureScaleProgressListener):

    tile as AutotileAnimation
    localTransform as Transform

    squeezeModeProp                as SerializedProperty
    tileModeProp                   as SerializedProperty

    private prev_pivot_mode as PivotMode
    private prev_tile_anathomy as AutotileAnathomy
    private missing_tileset = false

    def OnEnable():
        tile = target as AutotileAnimation

        missing_tileset = false

        squeezeModeProp       = serializedObject.FindProperty("squeezeMode")
        tileModeProp          = serializedObject.FindProperty("tileMode")

        localTransform = tile.transform

        prev_pivot_mode = Tools.pivotMode
        Tools.pivotMode = PivotMode.Pivot

        for t in FindObjectsOfType(AutotileAnimation):
            if not t.tilesetKey and AutotileConfig.config.animationSets.Count:
                t.tilesetKey = AutotileConfig.config.animationSets.FirstKey()
                t.Rebuild()
            try:
                ts = AutotileConfig.config.animationSets[t.tilesetKey]
                tsm = ts.material if ts
                mt = tsm.mainTexture if tsm
                if mt and t.renderer.sharedMaterial != tsm:
                    t.renderer.material = tsm
                    EditorUtility.SetDirty(t.renderer)
            except e as KeyNotFoundException:
                missing_tileset = missing_tileset or t == tile
                Debug.LogError("The key $(t.tilesetKey) was missing in the tileset config")

    def OnDisable():
        Tools.pivotMode = prev_pivot_mode

    def Progress(s as single):
        pass

    def GetPreview(t as Tile, tileSize as int, source as Texture2D, result as Texture2D):
        w = t.atlasLocation.width * source.width
        h = t.atlasLocation.height * source.height
        fullTile = Texture2D(w, h, TextureFormat.ARGB32, false)
        fullTile.SetPixels(source.GetPixels(t.atlasLocation.xMin * source.width, t.atlasLocation.yMin * source.height, w, h))
        if t.flipped:
            ourFlip = ((t.direction + 1) cast int) cast TextureScaleFlip
        if t.rotated:
            ourRotation = ((t.rotation + 1) cast int) cast TextureScaleRotate
        TextureScale.Bilinear(fullTile, result, self, TextureScaleTransform(ourFlip, ourRotation))
        DestroyImmediate(fullTile)

    def Refresh(t as AutotileBase):
        t.Refresh()
        if t.unsaved:
            t.unsaved = false
            EditorUtility.SetDirty(t)
        if t.unsavedMesh:
            t.unsavedMesh = false
            mf = t.GetComponent of MeshFilter()
            EditorUtility.SetDirty(mf) if mf

    virtual def OnInspectorGUI():
        serializedObject.Update()

        EditorGUI.BeginChangeCheck()
        for t as AutotileAnimation in serializedObject.targetObjects:
            if t.tilesetKey != tile.tilesetKey:
                needMix = true
        EditorGUI.showMixedValue = serializedObject.isEditingMultipleObjects and needMix
        tilesets = array(string, AutotileConfig.config.animationSets.Count)
        for i as int, e as KeyValuePair[of string, AutotileAnimationSet] in enumerate(AutotileConfig.config.animationSets):
            currentIndex = i if e.Key == tile.tilesetKey
            tilesets[i] = e.Key
        unless needMix or tile.tilesetKey in tilesets:
            tilesets = ("",) + tilesets
        newIndex = EditorGUILayout.Popup("Tileset", currentIndex, tilesets)
        if EditorGUI.EndChangeCheck():
            undoSaved = false
            for t as AutotileAnimation in serializedObject.targetObjects:
                if tilesets[newIndex] != t.tilesetKey:
                    unless undoSaved:
                        undoSaved = true
                        Undo.RegisterUndo(serializedObject.targetObjects, "Change AutotileAnimation tileset")
                    t.tilesetKey = tilesets[newIndex]
                    new_material = AutotileConfig.config.animationSets[t.tilesetKey].material
                    unless t.renderer.sharedMaterial == new_material:
                        t.renderer.material = AutotileConfig.config.animationSets[t.tilesetKey].material
                        EditorUtility.SetDirty(t.renderer)
                    missing_tileset = false
                    Refresh(t) if serializedObject.isEditingMultipleObjects

        if missing_tileset:
            EditorGUILayout.LabelField("The tileset '$(tile.tilesetKey)' is missing.")
            EditorGUILayout.LabelField("Full Autotile Animation editor can not display.")
            return

        if serializedObject.isEditingMultipleObjects:
            return

        EditorGUILayout.PropertyField(squeezeModeProp, GUIContent("Squeeze Mode"))
        GUI.enabled = false
        EditorGUILayout.PropertyField(tileModeProp, GUIContent("Tile Mode"))
        GUI.enabled = true
        newUseCorner = EditorGUILayout.EnumMaskField(GUIContent("Corners"), tile.useCorner)

        if tile.useCorner cast System.Enum != newUseCorner:
            Undo.RegisterUndo(tile, "Change tile corner")
            tile.useCorner = newUseCorner
            Refresh(tile)
            EditorUtility.SetDirty(tile)

        newUseFrameRateOverride = EditorGUILayout.Toggle("Use custom framerate", tile.useFramerateOverride)

        if tile.useFramerateOverride != newUseFrameRateOverride:
            changesToFramerate = true
            Undo.RegisterUndo(tile, "Change 'Use custom framerate'")
            tile.useFramerateOverride = newUseFrameRateOverride

        if tile.useFramerateOverride:
            newFramerateOverride = EditorGUILayout.IntField("Custom frames/second", tile.framerateOverride)

            if tile.framerateOverride != newFramerateOverride:
                changesToFramerate = true
                Undo.RegisterUndo(tile, "Change 'Custom framerate'")
                tile.framerateOverride = newFramerateOverride

        if changesToFramerate:
            tile.dirty = true
            Refresh(tile)
            EditorUtility.SetDirty(tile)

        if GUILayout.Button("Rebuild animations thas use '$(tile.tilesetKey)'"):
            tiles = FindObjectsOfType(AutotileAnimation)
            tilesWithSameKey = array(AutotileAnimation, (t for t in tiles if t.tilesetKey == tile.tilesetKey))
            Undo.RegisterUndo(tilesWithSameKey, "Rebuild animations")
            for t in tilesWithSameKey:
                t.dirty = true
                Refresh(t)
                EditorUtility.SetDirty(t)

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

        serializedObject.ApplyModifiedProperties()
        Refresh(tile)

    def SnapshotImmediately():
        affected = array(Component, (tile, tile.transform))
        Undo.SetSnapshotTarget(affected, "Resize/Move Autotile Animations")

        Undo.CreateSnapshot()
        Undo.RegisterSnapshot()
        Undo.ClearSnapshotTarget()

    def NormalizeScales():
        tile.transform.localRotation = Quaternion.identity
        tile.transform.localPosition.z = 0.0f
        tile.transform.localScale = tile.SuggestScales()

    def OnSceneGUI():
        if Event.current.type == EventType.Repaint:
            for t in AutotileBase.allAutotileBases:
                Refresh(t)
                if t.tilesetKey and not t.localRenderer.sharedMaterial:
                    t.localRenderer.material = AutotileConfig.config.animationSets[t.tilesetKey].material
                    EditorUtility.SetDirty(t.localRenderer)

        elif Event.current.type == EventType.MouseUp and Event.current.button == 0:
            NormalizeScales()
            Refresh(tile)

        elif Event.current.type == EventType.MouseDown and Event.current.button == 0:
            SnapshotImmediately()
