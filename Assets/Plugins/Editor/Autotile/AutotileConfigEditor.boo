import UnityEngine
import UnityEditor
import System.IO
import System.Collections.Generic

[CustomEditor(AutotileConfig)]
class AutotileConfigEditor (Editor, TextureScaleProgressListener):

    class TilesetMeta:
        public tilesWide as int
        public tilesHigh as int
        public preview as Texture2D

    config as AutotileConfig

    newSetName = ""
    newSetMaterial as Material
    newSetTileSize = 128
    showNewSet = false
    initialized = false

    inError as bool

    tilesetMeta as Dictionary[of AutotileSet, TilesetMeta]
    highlightTexture as Texture2D

    trashCan as GUIContent
    corners as Dictionary[of string, GUIContent]

    def ExpandedCornerLetters(s as string):
        s = join(s[:4], "-")
        s = /A/.Replace(s, "Air")
        s = /B/.Replace(s, "Black")
        s = /C/.Replace(s, "Ceiling")
        s = /G/.Replace(s, "Ground")
        s = /L/.Replace(s, "Left")
        s = /R/.Replace(s, "Right")
        s = /D/.Replace(s, "Double")
        return s

    def Init():
        corners = Dictionary[of string, GUIContent]()
        tilesetMeta = Dictionary[of AutotileSet, TilesetMeta]()

        highlightColor = Color(GUI.contentColor.r, GUI.contentColor.g, GUI.contentColor.b, 0.5f)
        highlightTexture = Texture2D(1, 1, TextureFormat.ARGB32, false)
        highlightTexture.SetPixel(0, 0, highlightColor)
        highlightTexture.Apply()

        if EditorGUIUtility.isProSkin:
            trashCan = GUIContent("Remove", AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Icons/Trash/Dark.png", Texture))
            corner_folder = "Assets/Plugins/Autotile/Icons/Corners/Dark"
        else:
            trashCan = GUIContent("Remove", AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Icons/Trash/Light.png", Texture))
            corner_folder = "Assets/Plugins/Autotile/Icons/Corners/Light"
        for icon as string in [Path.GetFileName(p) for p in Directory.GetFiles(corner_folder)]:
            if icon =~ /^[ABLRD][ABCGD][ABLRD][ABCGD]\.png$/:
                tips = ExpandedCornerLetters(icon)
                corners[icon[:4]] = GUIContent(AssetDatabase.LoadAssetAtPath("$corner_folder/$(icon[:4]).png", Texture), tips)

        config = target as AutotileConfig

        imagesBeingResized = config.sets.Count
        for i, setEntry as KeyValuePair[of string, AutotileSet] in enumerate(config.sets):
            imageBeingResized = i
            PopulateAtlasPreview(setEntry.Value, setEntry.Key)
        EditorUtility.ClearProgressBar()

    private imagesBeingResized as int
    private imageBeingResized as int
    def Progress(s as single):
        EditorUtility.DisplayProgressBar("Creating atlas previews", "", (imageBeingResized + s) / imagesBeingResized)

    def PopulateAtlasPreview(s as AutotileSet, name as string) as bool:
        PopulateAtlasPreview(s, name, true)

    private preview_failure = false
    def PopulateAtlasPreview(s as AutotileSet, name, initMetaAndTexture as bool) as bool:
        if not preview_failure:

            unless s.material:
                preview_failure = true
                Debug.LogError("$name did not have a readable texture to preview")
                return false

            try:
                mt = s.material.mainTexture as Texture2D

                if initMetaAndTexture:
                    newMeta = TilesetMeta()
                    if s.preview:
                        newMeta.preview = s.preview
                    else:
                        aspect = mt.width / mt.height
                        nextTexture = Texture2D(
                            Mathf.Min(mt.width,  256.0f * aspect),
                            Mathf.Min(mt.height, 256.0f),
                            TextureFormat.ARGB32,
                            false)
                        TextureScale.Bilinear(mt, nextTexture, self)
                        newMeta.preview = nextTexture
                        s.preview = nextTexture
                    if s in tilesetMeta:
                        Object.DestroyImmediate(tilesetMeta[s].preview)
                    tilesetMeta[s] = newMeta
                else:
                    newMeta = tilesetMeta[s]

                newMeta.tilesWide = mt.width / s.tileSize
                newMeta.tilesHigh = mt.height / s.tileSize

            except e as UnityException:
                preview_failure = true
                Debug.LogError("$name did not have a readable texture to preview")

        return not preview_failure

    [MenuItem("Assets/Autotile/Create Autotile Config")]
    static def CreateConfig() as AutotileConfig:
        tc = AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Tilesets.asset", AutotileConfig)
        unless tc:
            unless Directory.Exists("Assets/Plugins"):
                AssetDatabase.CreateFolder("Assets", "Plugins")
            unless Directory.Exists("Assets/Plugins/Autotile"):
                AssetDatabase.CreateFolder("Assets/Plugins", "Autotile")
            tc = ScriptableObject.CreateInstance(AutotileConfig)
            AssetDatabase.CreateAsset(tc, "Assets/Plugins/Autotile/Tilesets.asset")
        return tc

     def drawTileGUIContent(s as AutotileSet, t as Tile, n as string, prefix as string, c as GUIContent):
        t.show = EditorGUILayout.Foldout(t.show, c)
        nextMeta as TilesetMeta
        if t.show:
            if tilesetMeta.TryGetValue(s, nextMeta) and s.material:
                EditorGUI.indentLevel += 1

                mt = s.material.mainTexture as Texture2D

                aspect = mt.width / mt.height
                indent = 8 + EditorGUI.indentLevel * 8
                width = Screen.width - indent - 16
                height = Mathf.Min(width / aspect, 256.0f)
                width = height * aspect
                myRect = GUILayoutUtility.GetRect(width, height, GUILayout.MaxWidth(width), GUILayout.MaxHeight(height))
                myRect.x += indent

                if Event.current.type == EventType.MouseDown and Event.current.button == 0:
                    if myRect.Contains(Event.current.mousePosition):
                        x = (Event.current.mousePosition.x - myRect.xMin) / myRect.width
                        y = 1.0f - (Event.current.mousePosition.y - myRect.yMin) / myRect.height
                        x = Mathf.Min(1.0f - t.atlasLocation.width, Mathf.Floor(x * nextMeta.tilesWide) / nextMeta.tilesWide)
                        y = Mathf.Min(1.0f - t.atlasLocation.height, Mathf.Floor(y * nextMeta.tilesHigh) / nextMeta.tilesHigh)

                        Undo.RegisterUndo(config, "Set Tile Location in $(prefix)$n")
                        t.atlasLocation.x = x
                        t.atlasLocation.y = y

                if Event.current.type == EventType.Repaint:
                    GUI.DrawTexture(myRect, nextMeta.preview)
                    highlightRect = Rect(
                            myRect.x + t.atlasLocation.x * myRect.width,
                            myRect.y + (1.0f - t.atlasLocation.bottom) * myRect.height,
                            t.atlasLocation.width * myRect.width,
                            t.atlasLocation.height * myRect.height)
                    GUI.DrawTexture(highlightRect, highlightTexture)

                newAtlasLocation = EditorGUILayout.RectField("Tile Location", t.atlasLocation)
                if t.atlasLocation != newAtlasLocation:
                    Undo.RegisterUndo(config, "Set Tile Location in $(prefix)$n")
                    t.atlasLocation = newAtlasLocation
                newFlipped = EditorGUILayout.Toggle("Source Flipped", t.flipped)
                if t.flipped != newFlipped:
                    Undo.RegisterUndo(config, "Set Flipped in $(prefix)$n")
                    t.flipped = newFlipped
                if t.flipped:
                    newDirection = EditorGUILayout.EnumPopup("Direction", t.direction)
                    if t.direction cast System.Enum != newDirection:
                        Undo.RegisterUndo(config, "Set Direction in $(prefix)$n")
                        t.direction = newDirection
                newRotated = EditorGUILayout.Toggle("Source Rotated", t.rotated)
                if t.rotated != newRotated:
                    Undo.RegisterUndo(config, "Set Rotated in $(prefix)$n")
                    unless t.rotation == TileRotation._180:
                        buf = t.atlasLocation.width
                        t.atlasLocation.width = t.atlasLocation.height
                        t.atlasLocation.height = buf
                    t.rotated = newRotated
                if t.rotated:
                    newRotation = EditorGUILayout.EnumPopup("Rotation", t.rotation)
                    if t.rotation cast System.Enum != newRotation:
                        Undo.RegisterUndo(config, "Set Rotation in $(prefix)$n")
                        if newRotation == TileRotation._180 cast System.Enum or\
                           t.rotation == TileRotation._180:
                            buf = t.atlasLocation.width
                            t.atlasLocation.width = t.atlasLocation.height
                            t.atlasLocation.height = buf
                        t.rotation = newRotation
                EditorGUI.indentLevel -= 1

            else:
                Debug.LogError("Failed to get material for $(s.name)") unless inError
                inError = true

    def drawTileGUINamed(s as AutotileSet, t as Tile, n as string, prefix as string):
        drawTileGUIContent(s, t, n, prefix, GUIContent("$n"))

    def drawTileGUI(s as AutotileSet, t as Tile, n as string):
        drawTileGUIContent(s, t, n, "", corners[n])

    def OnInspectorGUI():

        unless initialized:
            Init()
            initialized = true

        showNewSet = EditorGUILayout.Foldout(showNewSet, "New Set")
        if showNewSet:
            EditorGUI.indentLevel += 1
            newSetName = EditorGUILayout.TextField("Name", newSetName)
            newSetTileSize = EditorGUILayout.IntField("Tile Size", newSetTileSize)
            newSetMaterial = EditorGUILayout.ObjectField("Material", newSetMaterial, Material, false)
            myRect = GUILayoutUtility.GetRect(0f, 16f)
            myRect.x += 16
            myRect.width -= 16
            GUI.enabled = newSetName != "" and newSetMaterial != null
            acceptNewSet = GUI.Button(myRect, "Add")
            GUI.enabled = true
            EditorGUI.indentLevel -= 1

        if newSetName and acceptNewSet and newSetMaterial:
            Undo.RegisterUndo(config, "Add Autotile Set $newSetName")

            path = AssetDatabase.GetAssetPath(newSetMaterial.mainTexture)
            textureImporter = AssetImporter.GetAtPath(path) as TextureImporter
            textureImporter.mipmapEnabled = false
            textureImporter.isReadable = true
            textureImporter.filterMode = FilterMode.Point
            AssetDatabase.ImportAsset(path)

            newSet = AutotileSet()
            newSet.material = newSetMaterial
            newSet.tileSize = newSetTileSize

            # Add a '1' center set
            newCenterSet = AutotileCenterSet()
            v_props = (newCenterSet.leftFace, newCenterSet.rightFace, newCenterSet.doubleVerticalFace)
            h_props = (newCenterSet.downFace, newCenterSet.upFace,    newCenterSet.doubleHorizontalFace)
            newTilesWide = newSetMaterial.mainTexture.width / newSetTileSize
            newTilesHigh = newSetMaterial.mainTexture.height / newSetTileSize
            for face in h_props:
                face.atlasLocation.width = 1.0f / newTilesWide
                face.atlasLocation.height = 1.0f / newTilesHigh
                face.direction = TileFlipDirection.Vertical
            for face in v_props:
                face.atlasLocation.width = 1.0f / newTilesWide
                face.atlasLocation.height = 1.0f / newTilesHigh
                face.direction = TileFlipDirection.Horizontal
            newSet.centerSets[1] = newCenterSet

            for t in newSet.corners:
                t.atlasLocation.width = 1.0f / newTilesWide
                t.atlasLocation.height = 1.0f / newTilesHigh

            PopulateAtlasPreview(newSet, newSetName)
            EditorUtility.ClearProgressBar()

            config.sets[newSetName] = newSet
            newSetName = ""
            newSetTileSize = 128
            newSetMaterial = null
            GUIUtility.keyboardControl = 0
            EditorUtility.SetDirty(config)

        tileSetTrash = []
        newSets = []
        newNames = []

        for setEntry in config.sets:
            autotileSet = setEntry.Value
            autotileSetName = setEntry.Key
            autotileSet.name = autotileSetName
            meta as TilesetMeta
            unless tilesetMeta.TryGetValue(autotileSet, meta):
                Debug.LogError("Failed to get material for $(autotileSetName)") unless inError
                inError = true

            openAllTiles = false
            closeAllTiles = false

            autotileSet.show = EditorGUILayout.Foldout(autotileSet.show, autotileSetName)

            if autotileSet.show:
                EditorGUI.indentLevel += 1

                f = def(v as bool):
                    return not closeAllTiles and (openAllTiles or v)

                autotileSet.showDuplicateOption = EditorGUILayout.Foldout(autotileSet.showDuplicateOption, "Duplicate")
                if autotileSet.showDuplicateOption:
                    EditorGUI.indentLevel += 1

                    autotileSet.duplicateCandidate = EditorGUILayout.TextField("Duplicate Name", autotileSet.duplicateCandidate)

                    GUI.enabled = autotileSet.duplicateCandidate != "" and\
                                  not config.sets.ContainsKey(autotileSet.duplicateCandidate)

                    myRect = GUILayoutUtility.GetRect(0f, 16f)
                    myRect.x += 24
                    myRect.width -= 24
                    if GUI.Button(myRect, "Duplicate $autotileSetName as $(autotileSet.duplicateCandidate)"):
                        Undo.RegisterUndo(config, "Duplicate $autotileSetName")
                        newSet = autotileSet.Duplicate()
                        newSets.Add(newSet)
                        newNames.Add(autotileSet.duplicateCandidate)

                        autotileSet.duplicateCandidate = ""
                        GUIUtility.keyboardControl = 0

                    GUI.enabled = true
                    EditorGUI.indentLevel -= 1

                autotileSet.showSettings = EditorGUILayout.Foldout(autotileSet.showSettings, "Settings")
                if autotileSet.showSettings:
                    EditorGUI.indentLevel += 1
                    changedTileSize = EditorGUILayout.IntField("Tile Size", autotileSet.tileSize)
                    if changedTileSize != autotileSet.tileSize:
                        Undo.RegisterUndo(config, "Change $autotileSetName tile size")
                        autotileSet.tileSize = changedTileSize
                        PopulateAtlasPreview(autotileSet, autotileSetName, false)
                    changedMaterial = EditorGUILayout.ObjectField("Material", autotileSet.material, Material, false)
                    if changedMaterial != autotileSet.material:
                        Undo.RegisterUndo(config, "Change $autotileSetName material")
                        autotileSet.material = changedMaterial
                        PopulateAtlasPreview(autotileSet, autotileSetName)
                        EditorUtility.ClearProgressBar()

                    myRect = GUILayoutUtility.GetRect(0f, 16f)
                    myRect.x += 24
                    myRect.width -= 24
                    openAllTiles = GUI.Button(myRect, "Open All Tiles")
                    myRect = GUILayoutUtility.GetRect(0f, 16f)
                    myRect.x += 24
                    myRect.width -= 24
                    closeAllTiles = GUI.Button(myRect, "Close All Tiles")

                    EditorGUI.indentLevel -= 1

                autotileSet.showCenterSets = EditorGUILayout.Foldout(f(autotileSet.showCenterSets), "Center Sets")
                if autotileSet.showCenterSets:
                    trash = []

                    EditorGUI.indentLevel += 1

                    autotileSet.showNewCenterSetOption = EditorGUILayout.Foldout(autotileSet.showNewCenterSetOption, "New")
                    if autotileSet.showNewCenterSetOption:
                        EditorGUI.indentLevel += 1
                        autotileSet.newCandidate = EditorGUILayout.IntField("Length", autotileSet.newCandidate)
                        myRect = GUILayoutUtility.GetRect(0f, 16f)
                        myRect.x += 32
                        myRect.width -= 32
                        GUI.enabled = autotileSet.newCandidate > 0 and not autotileSet.centerSets.ContainsKey(autotileSet.newCandidate)
                        acceptNew = GUI.Button(myRect, "Add")
                        GUI.enabled = true
                        EditorGUI.indentLevel -= 1

                    if autotileSet.newCandidate > 0 and acceptNew and meta:
                        Undo.RegisterUndo(config, "Add New Center Set $(autotileSet.newCandidate)")

                        newCenterSet = AutotileCenterSet()
                        v_props = (newCenterSet.leftFace, newCenterSet.rightFace, newCenterSet.doubleVerticalFace)
                        h_props = (newCenterSet.downFace, newCenterSet.upFace,    newCenterSet.doubleHorizontalFace)
                        tilesWide = meta.tilesWide
                        tilesHigh = meta.tilesHigh
                        for face in v_props:
                            face.atlasLocation.width = 1.0f / tilesWide
                            face.atlasLocation.height = autotileSet.newCandidate cast single / tilesHigh
                        for face in h_props:
                            face.atlasLocation.width = autotileSet.newCandidate cast single / tilesWide
                            face.atlasLocation.height = 1.0f / tilesHigh
                        autotileSet.centerSets[autotileSet.newCandidate] = newCenterSet
                        autotileSet.newCandidate = 1
                        while autotileSet.centerSets.ContainsKey(autotileSet.newCandidate):
                            autotileSet.newCandidate *= 2
                        autotileSet.showCenterSets = true
                        newCenterSet.show = true
                        GUIUtility.keyboardControl = 0
                        EditorUtility.SetDirty(config)

                    for csEntry in autotileSet.centerSets:

                        if csEntry.Value:
                            cSet = csEntry.Value
                            cSetKey = csEntry.Key

                            cSet.show = EditorGUILayout.Foldout(f(cSet.show), "$cSetKey")
                            if cSet.show:
                                EditorGUI.indentLevel += 1
                                props      = (cSet.leftFace,  cSet.rightFace,  cSet.downFace,  cSet.upFace,  cSet.doubleHorizontalFace,   cSet.doubleVerticalFace)
                                prop_names = ("Left Face",    "Right Face",    "Down Face",    "Up Face",    "Double Horizontal Face",    "Double Vertical Face")
                                for face as Tile, faceName as string in zip(props, prop_names):
                                    drawTileGUINamed(autotileSet, face, faceName, "$cSetKey/")

                                cSet.showRemoveOption = EditorGUILayout.Foldout(cSet.showRemoveOption, trashCan)
                                if cSet.showRemoveOption:
                                    EditorGUI.indentLevel += 1
                                    myRect = GUILayoutUtility.GetRect(0f, 16f)
                                    myRect.x += 40
                                    myRect.width -= 40
                                    removeCenterSet = GUI.Button(myRect, "Remove $autotileSetName/$cSetKey")
                                    if removeCenterSet:
                                        Undo.RegisterUndo(config, "Remove Center Set $autotileSetName/$cSetKey")
                                        trash.Push(cSetKey)
                                        EditorUtility.SetDirty(config)

                                        autotileSet.newCandidate = 1
                                        while cSetKey != autotileSet.newCandidate and autotileSet.centerSets.ContainsKey(autotileSet.newCandidate):
                                            autotileSet.newCandidate *= 2

                                    EditorGUI.indentLevel -= 1

                                EditorGUI.indentLevel -= 1
                        else:
                            EditorGUILayout.BeginHorizontal()
                            EditorGUILayout.LabelField("$(csEntry.Key) (missing)")
                            if GUILayout.Button("Remove $(csEntry.Key)", GUILayout.Width(160)):
                                Undo.RegisterUndo(config, "Remove Center Set $(csEntry.Key)")
                                trash.Push(csEntry.Key)
                            EditorGUILayout.EndHorizontal()

                    EditorGUI.indentLevel -= 1

                    for t in trash:
                        autotileSet.centerSets.Remove(t)

                for csEntry in autotileSet.centerSets:
                    if csEntry.Value:
                        cSet = csEntry.Value
                        cSet.show = f(cSet.show)
                        props = (cSet.leftFace,  cSet.rightFace,  cSet.downFace,  cSet.upFace,  cSet.doubleHorizontalFace,   cSet.doubleVerticalFace)
                        if closeAllTiles or openAllTiles:
                            for face in props:
                                face.show = f(face.show)

                if closeAllTiles or openAllTiles:
                    for t in autotileSet.corners:
                        t.show = f(t.show)

                autotileSet.showCorners = EditorGUILayout.Foldout(f(autotileSet.showCorners), "Corners")
                if autotileSet.showCorners:
                    EditorGUI.indentLevel += 1
                    all_corners autotileSet, autotileSet.corners, drawTileGUI
                    EditorGUI.indentLevel -= 1

                autotileSet.showRemoveOption = EditorGUILayout.Foldout(autotileSet.showRemoveOption, trashCan)
                if autotileSet.showRemoveOption:
                    myRect = GUILayoutUtility.GetRect(0f, 16f)
                    myRect.x += 24
                    myRect.width -= 24
                    if GUI.Button(myRect, "Remove $autotileSetName"):
                        Undo.RegisterUndo(config, "Remove Set $autotileSetName")
                        tileSetTrash.Push(autotileSetName)
                        EditorUtility.SetDirty(config)

                EditorGUI.indentLevel -= 1

        for s as string in tileSetTrash:
            config.sets.Remove(s)

        for tileset, name in zip(newSets, newNames):
            config.sets[name] = tileset
            PopulateAtlasPreview(tileset, name)
            EditorUtility.ClearProgressBar()
            EditorUtility.SetDirty(config)

        if GUI.changed:
            EditorUtility.SetDirty(config)
