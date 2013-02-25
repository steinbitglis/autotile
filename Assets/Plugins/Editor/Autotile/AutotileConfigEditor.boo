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

    class TilesetCandidate:
        public name = ""
        public material as Material
        public uvMarginMode as UVMarginMode
        public tileSize = 128
        public show = false

    class TilesetAnimationCandidate (TilesetCandidate):
        public framesPerSecond = 50f

    config as AutotileConfig

    candidate = TilesetCandidate()
    animationCandidate = TilesetAnimationCandidate()

    initialized = false

    inError as bool

    tilesetMeta as Dictionary[of AutotileBaseSet, TilesetMeta]
    highlightTexture as Texture2D

    trashCan as GUIContent
    corners as Dictionary[of string, GUIContent]
    cardinalCorners as (GUIContent)

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
        tilesetMeta = Dictionary[of AutotileBaseSet, TilesetMeta]()

        highlightColor = Color(GUI.contentColor.r, GUI.contentColor.g, GUI.contentColor.b, 0.5f)
        highlightTexture = Texture2D(1, 1, TextureFormat.ARGB32, false)
        highlightTexture.hideFlags = HideFlags.DontSave
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
        corners["Unknown"] = GUIContent(AssetDatabase.LoadAssetAtPath("$corner_folder/Unknown.png", Texture), "Fallback corner")

        cardinalCorners = (corners["AAAA"], corners["ADAA"], corners["AAAD"], corners["DAAA"], corners["AADA"])

        config = target as AutotileConfig

        autotileImages = config.sets.Count
        autotileAnimationImages = config.animationSets.Count
        imagesBeingResized = autotileImages + autotileAnimationImages

        for i as int, setEntry as KeyValuePair[of string, AutotileSet] in enumerate(config.sets):
            imageBeingResized = i
            PopulateAtlasPreview(setEntry.Value, setEntry.Key)
        for i as int, setEntry as KeyValuePair[of string, AutotileAnimationSet] in enumerate(config.animationSets):
            imageBeingResized = i + autotileImages
            aaSet = setEntry.Value
            animCorners = aaSet.corners
            for j in range(5):
                animCorners.candidateFrames[j] = len(animCorners[j])
            for j, len_set as KeyValuePair[of int, AutotileAnimationTileset] in enumerate(aaSet.sets):
                ats = len_set.Value
                for k in range(2):
                    ats.candidateFrames[k] = len(ats[k])
            PopulateAtlasPreview(setEntry.Value, setEntry.Key)

        EditorUtility.ClearProgressBar()

    private imagesBeingResized as int
    private imageBeingResized as int
    def Progress(s as single):
        EditorUtility.DisplayProgressBar("Creating atlas previews", "", (imageBeingResized + s) / imagesBeingResized)

    def PopulateAtlasPreview(s as AutotileBaseSet, name as string) as bool:
        return PopulateAtlasPreview(s, name, true)

    private preview_failures = List of string()
    def PopulateAtlasPreview(s as AutotileBaseSet, name as string, initMetaAndTexture as bool) as bool:
        unless name in preview_failures:

            unless s.material and s.material.mainTexture:
                preview_failures.Add(name)
                Debug.LogError("$name did not have a readable texture to preview")
                return false

            try:
                mt = s.material.mainTexture as Texture2D

                if initMetaAndTexture:
                    newMeta = TilesetMeta()
                    if s.preview:
                        newMeta.preview = s.preview
                    else:
                        aspect = mt.width cast single / mt.height cast single
                        nextTexture = Texture2D(
                            Mathf.Min(mt.width,  256.0f * aspect),
                            Mathf.Min(mt.height, 256.0f),
                            TextureFormat.ARGB32,
                            false)
                        nextTexture.hideFlags = HideFlags.DontSave
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
                preview_failures.Add(name)
                Debug.LogError("$name did not have a readable texture to preview")
                return false

            return true
        return false

     def drawTileGUIContent(s as AutotileBaseSet, t as Tile, n as string, prefix as string, c as GUIContent):
        t.show = EditorGUILayout.Foldout(t.show, c)
        nextMeta as TilesetMeta
        if t.show:
            if tilesetMeta.TryGetValue(s, nextMeta) and s.material and s.material.mainTexture:
                EditorGUI.indentLevel += 1

                mt = s.material.mainTexture as Texture2D

                aspect = mt.width cast single / mt.height cast single
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
                            myRect.y + (1.0f - t.atlasLocation.yMax) * myRect.height,
                            t.atlasLocation.width * myRect.width,
                            t.atlasLocation.height * myRect.height)
                    GUI.DrawTexture(highlightRect, highlightTexture)

                if t isa AnimationTile:
                    at = t as AnimationTile
                    newFrames = EditorGUILayout.IntField("Frames", at.frames)
                    if at.frames != newFrames:
                        Undo.RegisterUndo(config, "Set duration in $(prefix)$n")
                        at.frames = newFrames

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
                        t.atlasLocation.width = t.atlasLocation.height / aspect
                        t.atlasLocation.height = buf * aspect
                    t.rotated = newRotated
                if t.rotated:
                    newRotation = EditorGUILayout.EnumPopup("Rotation", t.rotation)
                    if t.rotation cast System.Enum != newRotation:
                        Undo.RegisterUndo(config, "Set Rotation in $(prefix)$n")
                        if newRotation == TileRotation._180 cast System.Enum or\
                           t.rotation == TileRotation._180:
                            buf = t.atlasLocation.width
                            t.atlasLocation.width = t.atlasLocation.height / aspect
                            t.atlasLocation.height = buf * aspect
                        t.rotation = newRotation
                EditorGUI.indentLevel -= 1

            else:
                Debug.LogError("Failed to get material for $(s.name)") unless inError
                inError = true

    def drawTileGUINamed(s as AutotileBaseSet, t as Tile, n as string, prefix as string):
        drawTileGUIContent(s, t, n, prefix, GUIContent("$n"))

    def drawTileGUI(s as AutotileBaseSet, t as Tile, n as string):
        drawTileGUIContent(s, t, n, "", corners[n])

    def changeTileSize(s as AutotileSet, newSize as int):
        s.tileSize = newSize
        if s.material and s.material.mainTexture:
            mt = s.material.mainTexture as Texture2D
            nWidth = newSize cast single / mt.width cast single
            nHeight = newSize cast single / mt.height cast single
            for tile in s.corners:
                setTileLocation(tile, nWidth, nHeight)
            for kvp as KeyValuePair[of int, AutotileCenterSet] in s.centerSets:
                cs = kvp.Value
                length = kvp.Key
                setVerticalTileLocation(cs.leftFace,           nWidth, nHeight, length)
                setVerticalTileLocation(cs.rightFace,          nWidth, nHeight, length)
                setVerticalTileLocation(cs.doubleVerticalFace, nWidth, nHeight, length)
                setHorizontalTileLocation(cs.upFace,               nWidth, nHeight, length)
                setHorizontalTileLocation(cs.downFace,             nWidth, nHeight, length)
                setHorizontalTileLocation(cs.doubleHorizontalFace, nWidth, nHeight, length)

    def changeTileSize(s as AutotileAnimationSet, newSize as int):
        s.tileSize = newSize
        if s.material and s.material.mainTexture:
            mt = s.material.mainTexture as Texture2D
            nWidth = newSize cast single / mt.width cast single
            nHeight = newSize cast single / mt.height cast single
            for cornerType in s.corners:
                for tile in cornerType:
                    setTileLocation(tile, nWidth, nHeight)
            for kvp as KeyValuePair[of int, AutotileAnimationTileset] in s.sets:
                cs = kvp.Value
                length = kvp.Key
                for hFace in cs.horizontalFaces:
                    setHorizontalTileLocation(hFace, nWidth, nHeight, length)
                for vFace in cs.verticalFaces:
                    setVerticalTileLocation(vFace, nWidth, nHeight, length)

    def setTileLocation(t as Tile, w as single, h as single):
        t.atlasLocation.width  = w
        t.atlasLocation.height = h

    def setHorizontalTileLocation(t as Tile, w as single, h as single, length as int):
        if t.rotated and t.rotation != TileRotation._180:
            t.atlasLocation.width  = w
            t.atlasLocation.height = h * length
        else:
            t.atlasLocation.width  = w * length
            t.atlasLocation.height = h

    def setVerticalTileLocation(t as Tile, w as single, h as single, length as int):
        if t.rotated and t.rotation != TileRotation._180:
            t.atlasLocation.width  = w * length
            t.atlasLocation.height = h
        else:
            t.atlasLocation.width  = w
            t.atlasLocation.height = h * length

    def PresentAndGetNewCandidate(c as TilesetCandidate, check as callable(string) as bool, f as callable(TilesetCandidate)):
        acceptNewSet = false
        c.show = EditorGUILayout.Foldout(c.show, "New Set")
        if c.show:
            EditorGUI.indentLevel += 1
            c.name = EditorGUILayout.TextField("Name", c.name)
            c.tileSize = EditorGUILayout.IntField("Tile Size", c.tileSize)
            c.uvMarginMode = EditorGUILayout.EnumPopup("UV Margin Mode", c.uvMarginMode)
            c.material = EditorGUILayout.ObjectField("Material", c.material, Material, false)
            if c isa TilesetAnimationCandidate:
                ac = c as TilesetAnimationCandidate
                ac.framesPerSecond = EditorGUILayout.FloatField("Frames Per Second", ac.framesPerSecond)
            myRect = GUILayoutUtility.GetRect(0f, 16f)
            myRect.x += 24
            myRect.width -= 24
            GUI.enabled = c.name != "" and check(c.name) and c.material != null
            acceptNewSet = GUI.Button(myRect, "Add")
            GUI.enabled = true
            EditorGUI.indentLevel -= 1

        if acceptNewSet and c.name and c.material:
            Undo.RegisterUndo(config, "Add Autotile Set $(c.name)")

            path = AssetDatabase.GetAssetPath(c.material.mainTexture)
            textureImporter = AssetImporter.GetAtPath(path) as TextureImporter
            textureImporter.mipmapEnabled = false
            textureImporter.isReadable = true
            textureImporter.filterMode = FilterMode.Point if c.uvMarginMode == UVMarginMode.NoMargin
            AssetDatabase.ImportAsset(path)

            f(c)

            c.name = ""
            c.tileSize = 128
            c.uvMarginMode = UVMarginMode.NoMargin
            c.material = null
            if c isa TilesetAnimationCandidate:
                ac = c as TilesetAnimationCandidate
                ac.framesPerSecond = 50f

            GUIUtility.keyboardControl = 0
            EditorUtility.SetDirty(config)

    def PresentAndGetDuplicate(c as AutotileBaseSet, name as string, check as callable(string) as bool, f as callable(AutotileBaseSet, string)):
        c.showDuplicateOption = EditorGUILayout.Foldout(c.showDuplicateOption, "Duplicate")
        if c.showDuplicateOption:
            EditorGUI.indentLevel += 1

            c.duplicateCandidate = EditorGUILayout.TextField("Duplicate Name", c.duplicateCandidate)

            GUI.enabled = c.duplicateCandidate != "" and check(c.duplicateCandidate)

            myRect = GUILayoutUtility.GetRect(0f, 16f)
            myRect.x += 32
            myRect.width -= 32
            if GUI.Button(myRect, "Duplicate $name as $(c.duplicateCandidate)"):
                Undo.RegisterUndo(config, "Duplicate $name")
                newSet = c.Duplicate()
                f(newSet, c.duplicateCandidate)

                c.duplicateCandidate = ""
                GUIUtility.keyboardControl = 0

            GUI.enabled = true
            EditorGUI.indentLevel -= 1

    def PresentAndGetSettings(c as AutotileBaseSet, name as string, onTileSizeChange as callable(int)):
        c.showSettings = EditorGUILayout.Foldout(c.showSettings, "Settings")
        if c.showSettings:
            EditorGUI.indentLevel += 1

            changedTileSize = EditorGUILayout.IntField("Tile Size", c.tileSize)
            if changedTileSize != c.tileSize:
                Undo.RegisterUndo(config, "Change $name tile size")
                onTileSizeChange(changedTileSize)
                PopulateAtlasPreview(c, name, false)

            changedUVMode = EditorGUILayout.EnumPopup("UV margin mode", c.uvMarginMode)
            if changedUVMode != c.uvMarginMode cast System.Enum:
                Undo.RegisterUndo(config, "Change $name uv margin mode")
                c.uvMarginMode = changedUVMode

            changedMaterial = EditorGUILayout.ObjectField("Material", c.material, Material, false)
            if changedMaterial != c.material:
                Undo.RegisterUndo(config, "Change $name material")
                c.material = changedMaterial
                c.preview = null

                path = AssetDatabase.GetAssetPath(c.material.mainTexture)
                textureImporter = AssetImporter.GetAtPath(path) as TextureImporter
                unless textureImporter.isReadable:
                    textureImporter.mipmapEnabled = false
                    textureImporter.isReadable = true
                    textureImporter.filterMode = FilterMode.Point
                AssetDatabase.ImportAsset(path)

                PopulateAtlasPreview(c, name)
                EditorUtility.ClearProgressBar()

            if c isa AutotileAnimationSet:
                animSet = c as AutotileAnimationSet
                changedFramesPerSecond = EditorGUILayout.FloatField("Frames Per Second", animSet.framesPerSecond)
                if changedFramesPerSecond != animSet.framesPerSecond:
                    Undo.RegisterUndo(config, "Change $name fps")
                    animSet.framesPerSecond = changedFramesPerSecond
                    for go in GameObject.FindObjectsOfType(AutotileAnimation):
                        if go.tilesetKey == name:
                            go.dirty = true
                            go.Refresh()
                            EditorUtility.SetDirty(go)

            myRect = GUILayoutUtility.GetRect(0f, 16f)
            myRect.x += 32
            myRect.width -= 32
            openAllTiles = GUI.Button(myRect, "Open All Tiles")
            myRect = GUILayoutUtility.GetRect(0f, 16f)
            myRect.x += 32
            myRect.width -= 32
            closeAllTiles = GUI.Button(myRect, "Close All Tiles")

            EditorGUI.indentLevel -= 1

    private openAllTiles as bool
    private closeAllTiles as bool
    def OnInspectorGUI():

        unless initialized:
            Init()
            initialized = true

        f = def(v as bool):
            return not closeAllTiles and (openAllTiles or v)

        tileSetTrash = []
        animTileSetTrash = []
        newSets = []
        newAnimSets = []
        newNames = []
        newAnimNames = []

        config.sets.show = EditorGUILayout.Foldout(config.sets.show, "Static")
        if config.sets.show:
            EditorGUI.indentLevel += 1

            PresentAndGetNewCandidate(candidate, {s as string | return not config.sets.ContainsKey(s)}) do(c):
                newSet = AutotileSet()
                newSet.material = c.material
                newSet.uvMarginMode = c.uvMarginMode
                newSet.tileSize = c.tileSize

                # Add a '1' center set
                newCenterSet = AutotileCenterSet()
                v_props = (newCenterSet.leftFace, newCenterSet.rightFace, newCenterSet.doubleVerticalFace)
                h_props = (newCenterSet.downFace, newCenterSet.upFace,    newCenterSet.doubleHorizontalFace)
                newTilesWide = c.material.mainTexture.width / c.tileSize
                newTilesHigh = c.material.mainTexture.height / c.tileSize
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

                PopulateAtlasPreview(newSet, c.name)
                EditorUtility.ClearProgressBar()

                config.sets[c.name] = newSet

            for setEntry in config.sets:
                autotileSet = setEntry.Value
                autotileSetName = setEntry.Key
                autotileSet.name = autotileSetName
                meta as TilesetMeta
                unless tilesetMeta.TryGetValue(autotileSet, meta):
                    Debug.LogError("Failed to get material for $(autotileSetName)") unless inError
                    inError = true

                autotileSet.show = EditorGUILayout.Foldout(autotileSet.show, autotileSetName)

                openAllTiles = false
                closeAllTiles = false

                if autotileSet.show:
                    EditorGUI.indentLevel += 1

                    PresentAndGetDuplicate(autotileSet, autotileSetName, {s as string| return not config.sets.ContainsKey(s)}) do(s, name):
                        newSets.Add(s)
                        newNames.Add(name)

                    PresentAndGetSettings(autotileSet, autotileSetName, {s as int | changeTileSize(autotileSet, s)})

                    locked = autotileSetName in preview_failures
                    GUI.enabled = not locked
                    autotileSet.showCenterSets = EditorGUILayout.Foldout(f(autotileSet.showCenterSets), "Center Sets") and not locked
                    GUI.enabled = true
                    if autotileSet.showCenterSets:
                        trash = []

                        EditorGUI.indentLevel += 1

                        autotileSet.showNewCenterSetOption = EditorGUILayout.Foldout(autotileSet.showNewCenterSetOption, "New")
                        if autotileSet.showNewCenterSetOption:
                            EditorGUI.indentLevel += 1
                            autotileSet.newCandidate = EditorGUILayout.IntField("Length", autotileSet.newCandidate)
                            myRect = GUILayoutUtility.GetRect(0f, 16f)
                            myRect.x += 40
                            myRect.width -= 40
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
                                face.direction = TileFlipDirection.Vertical
                            for face in h_props:
                                face.atlasLocation.width = autotileSet.newCandidate cast single / tilesWide
                                face.atlasLocation.height = 1.0f / tilesHigh
                                face.direction = TileFlipDirection.Horizontal
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
                                        myRect.x += 48
                                        myRect.width -= 48
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

                    GUI.enabled = not locked
                    autotileSet.showCorners = EditorGUILayout.Foldout(f(autotileSet.showCorners), "Corners") and not locked
                    GUI.enabled = true
                    if autotileSet.showCorners:
                        EditorGUI.indentLevel += 1
                        all_corners autotileSet, autotileSet.corners, drawTileGUI
                        EditorGUI.indentLevel -= 1

                    autotileSet.showRemoveOption = EditorGUILayout.Foldout(autotileSet.showRemoveOption, trashCan)
                    if autotileSet.showRemoveOption:
                        myRect = GUILayoutUtility.GetRect(0f, 16f)
                        myRect.x += 32
                        myRect.width -= 32
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

            EditorGUI.indentLevel -= 1

        config.animationSets.show = EditorGUILayout.Foldout(config.animationSets.show, "Animated")
        if config.animationSets.show:
            EditorGUI.indentLevel += 1

            PresentAndGetNewCandidate(animationCandidate, {s as string | return not config.animationSets.ContainsKey(s)}) do(c):
                newAnimSet = AutotileAnimationSet()
                newAnimSet.material = c.material
                newAnimSet.tileSize = c.tileSize
                ac = c as TilesetAnimationCandidate
                newAnimSet.framesPerSecond = ac.framesPerSecond

                # Add a '1' center set
                newAnimationTileset = AutotileAnimationTileset()
                newTilesWide = c.material.mainTexture.width / c.tileSize
                newTilesHigh = c.material.mainTexture.height / c.tileSize

                for hFace in newAnimationTileset.horizontalFaces:
                    hFace.atlasLocation.width  = 1.0f / newTilesWide
                    hFace.atlasLocation.height = 1.0f / newTilesHigh
                    hFace.direction = TileFlipDirection.Vertical
                for vFace in newAnimationTileset.verticalFaces:
                    vFace.atlasLocation.width  = 1.0f / newTilesWide
                    vFace.atlasLocation.height = 1.0f / newTilesHigh
                    vFace.direction = TileFlipDirection.Horizontal

                newAnimSet.sets[1] = newAnimationTileset

                for cornerType in newAnimSet.corners:
                    for t in cornerType:
                        t.atlasLocation.width = 1.0f / newTilesWide
                        t.atlasLocation.height = 1.0f / newTilesHigh

                PopulateAtlasPreview(newAnimSet, c.name)
                EditorUtility.ClearProgressBar()

                config.animationSets[animationCandidate.name] = newAnimSet

            for setEntry in config.animationSets:
                autotileAnimSet = setEntry.Value
                autotileAnimSetName = setEntry.Key
                autotileAnimSet.name = autotileAnimSetName
                animCorners = autotileAnimSet.corners
                unless tilesetMeta.TryGetValue(autotileAnimSet, meta):
                    Debug.LogError("Failed to get material for $(autotileAnimSetName)") unless inError
                    inError = true

                openAllTiles = false
                closeAllTiles = false

                autotileAnimSet.show = EditorGUILayout.Foldout(autotileAnimSet.show, autotileAnimSetName)

                if autotileAnimSet.show:
                    EditorGUI.indentLevel += 1

                    PresentAndGetDuplicate(autotileAnimSet, autotileAnimSetName, {s as string | return not config.animationSets.ContainsKey(s)}) do(s, name):
                        newAnimSets.Add(s)
                        newAnimNames.Add(name)

                    PresentAndGetSettings(autotileAnimSet, autotileAnimSetName, {s as int | changeTileSize(autotileAnimSet, s)})

                    locked = autotileAnimSetName in preview_failures
                    GUI.enabled = not locked
                    autotileAnimSet.showSets = EditorGUILayout.Foldout(f(autotileAnimSet.showSets), "Center Sets") and not locked
                    GUI.enabled = true

                    if autotileAnimSet.showSets:
                        trash = []

                        EditorGUI.indentLevel += 1

                        autotileAnimSet.showNewSetOption = EditorGUILayout.Foldout(autotileAnimSet.showNewSetOption, "New")
                        if autotileAnimSet.showNewSetOption:
                            EditorGUI.indentLevel += 1
                            autotileAnimSet.newCandidate = EditorGUILayout.IntField("Length", autotileAnimSet.newCandidate)
                            myRect = GUILayoutUtility.GetRect(0f, 16f)
                            myRect.x += 40
                            myRect.width -= 40
                            GUI.enabled = autotileAnimSet.newCandidate > 0 and not autotileAnimSet.sets.ContainsKey(autotileAnimSet.newCandidate)
                            acceptNew = GUI.Button(myRect, "Add")
                            GUI.enabled = true
                            EditorGUI.indentLevel -= 1

                        if autotileAnimSet.newCandidate > 0 and acceptNew and meta:
                            Undo.RegisterUndo(config, "Add New Animation Set $(autotileAnimSet.newCandidate)")

                            newAnimationTileset = AutotileAnimationTileset()
                            tilesWide = meta.tilesWide
                            tilesHigh = meta.tilesHigh

                            for hFace in newAnimationTileset.horizontalFaces:
                                hFace.atlasLocation.width  = autotileAnimSet.newCandidate cast single / tilesWide
                                hFace.atlasLocation.height = 1.0f / tilesHigh
                                hFace.direction = TileFlipDirection.Vertical
                            for vFace in newAnimationTileset.verticalFaces:
                                vFace.atlasLocation.width  = 1.0f / tilesWide
                                vFace.atlasLocation.height = autotileAnimSet.newCandidate cast single / tilesHigh
                                vFace.direction = TileFlipDirection.Horizontal

                            autotileAnimSet.sets[autotileAnimSet.newCandidate] = newAnimationTileset
                            autotileAnimSet.newCandidate = 1
                            while autotileAnimSet.sets.ContainsKey(autotileAnimSet.newCandidate):
                                autotileAnimSet.newCandidate *= 2
                            autotileAnimSet.showSets = true
                            newAnimationTileset.show = true
                            GUIUtility.keyboardControl = 0
                            EditorUtility.SetDirty(config)

                        for csEntry in autotileAnimSet.sets:

                            if csEntry.Value:
                                cAnimSet = csEntry.Value
                                cSetKey = csEntry.Key

                                cAnimSet.show = EditorGUILayout.Foldout(f(cAnimSet.show), "$cSetKey")
                                if cAnimSet.show:
                                    EditorGUI.indentLevel += 1
                                    faceTypes = ("Horizontal", "Vertical")
                                    for face as (AnimationTile), i as int in zip(cAnimSet, range(2)):
                                        cAnimSet.showingFace[i] = EditorGUILayout.Foldout(cAnimSet.showingFace[i], faceTypes[i])
                                        if cAnimSet.showingFace[i]:
                                            EditorGUI.indentLevel += 1
                                            cAnimSet.candidateFrames[i] = EditorGUILayout.IntField("Animation Frames", cAnimSet.candidateFrames[i])
                                            realFrames = len(cAnimSet[i])
                                            if realFrames != cAnimSet.candidateFrames[i] and cAnimSet.candidateFrames[i]:
                                                myRect = GUILayoutUtility.GetRect(0f, 16f)
                                                myRect.x += 48
                                                myRect.width -= 48
                                                if GUI.Button(myRect, "Apply"):
                                                    Undo.RegisterUndo(config, "Change number of animation frames")
                                                    newFrameTiles = array(AnimationTile, cAnimSet.candidateFrames[i])
                                                    refIndex = -1
                                                    for t in cAnimSet[i][:cAnimSet.candidateFrames[i]]:
                                                        refIndex += 1
                                                        newFrameTiles[refIndex] = t
                                                    if realFrames < cAnimSet.candidateFrames[i]:
                                                        for k in range(refIndex + 1, cAnimSet.candidateFrames[i]):
                                                            newFrameTiles[k] = cAnimSet[i][refIndex]
                                                    cAnimSet.SetFaces(i, array(AnimationTile, (t.Duplicate() for t in newFrameTiles)))
                                            for j, t as AnimationTile in enumerate(cAnimSet[i]):
                                                drawTileGUIContent(autotileAnimSet, t, "#$j", "", GUIContent("#$j"))
                                            EditorGUI.indentLevel -= 1

                                    cAnimSet.showRemoveOption = EditorGUILayout.Foldout(cAnimSet.showRemoveOption, trashCan)
                                    if cAnimSet.showRemoveOption:
                                        EditorGUI.indentLevel += 1
                                        myRect = GUILayoutUtility.GetRect(0f, 16f)
                                        myRect.x += 48
                                        myRect.width -= 48
                                        removeCenterSet = GUI.Button(myRect, "Remove $autotileAnimSetName/$cSetKey")
                                        if removeCenterSet:
                                            Undo.RegisterUndo(config, "Remove Center Set $autotileAnimSetName/$cSetKey")
                                            trash.Push(cSetKey)
                                            EditorUtility.SetDirty(config)

                                            autotileAnimSet.newCandidate = 1
                                            while cSetKey != autotileAnimSet.newCandidate and autotileAnimSet.sets.ContainsKey(autotileAnimSet.newCandidate):
                                                autotileAnimSet.newCandidate *= 2

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
                            autotileAnimSet.sets.Remove(t)

                    if closeAllTiles or openAllTiles:

                        for csEntry in autotileAnimSet.sets:
                            if csEntry.Value:
                                cAnimSet = csEntry.Value
                                cAnimSet.show = f(cAnimSet.show)
                                cAnimSet.showingFace[0] = f(cAnimSet.showingFace[0]) # 0: horizontal
                                cAnimSet.showingFace[1] = f(cAnimSet.showingFace[1]) # 1: vertical
                                for faceType as (AnimationTile) in cAnimSet:
                                    for face in faceType:
                                        face.show = f(face.show)

                        for cornerType in animCorners:
                            for t in cornerType:
                                t.show = f(t.show)

                    GUI.enabled = not locked
                    autotileAnimSet.showCorners = EditorGUILayout.Foldout(f(autotileAnimSet.showCorners), "Corners") and not locked
                    GUI.enabled = true
                    if autotileAnimSet.showCorners:
                        EditorGUI.indentLevel += 1
                        for cornerType as (AnimationTile), cornerGUI as GUIContent, i as int in\
                        zip(animCorners,                   cardinalCorners,         range(5)):

                            animCorners.showingCorner[i] = EditorGUILayout.Foldout(f(animCorners.showingCorner[i]), cornerGUI)
                            if animCorners.showingCorner[i]:
                                EditorGUI.indentLevel += 1

                                animCorners.candidateFrames[i] = EditorGUILayout.IntField("Animation Frames", animCorners.candidateFrames[i])
                                realFrames = len(animCorners[i])
                                if realFrames != animCorners.candidateFrames[i] and animCorners.candidateFrames[i]:
                                    myRect = GUILayoutUtility.GetRect(0f, 16f)
                                    myRect.x += 40
                                    myRect.width -= 40
                                    if GUI.Button(myRect, "Apply"):
                                        Undo.RegisterUndo(config, "Change number of animation frames")
                                        newFrameTiles = array(AnimationTile, animCorners.candidateFrames[i])
                                        refIndex = -1
                                        for t in animCorners[i][:animCorners.candidateFrames[i]]:
                                            refIndex += 1
                                            newFrameTiles[refIndex] = t
                                        if realFrames < animCorners.candidateFrames[i]:
                                            for k in range(refIndex + 1, animCorners.candidateFrames[i]):
                                                newFrameTiles[k] = animCorners[i][refIndex]
                                        animCorners.SetCorners(i, array(AnimationTile, (t.Duplicate() for t in newFrameTiles)))

                                for j, t as AnimationTile in enumerate(cornerType):
                                    drawTileGUIContent(autotileAnimSet, t, "#$j", "", GUIContent("#$j"))
                                EditorGUI.indentLevel -= 1
                        EditorGUI.indentLevel -= 1

                    autotileAnimSet.showRemoveOption = EditorGUILayout.Foldout(autotileAnimSet.showRemoveOption, trashCan)
                    if autotileAnimSet.showRemoveOption:
                        myRect = GUILayoutUtility.GetRect(0f, 16f)
                        myRect.x += 32
                        myRect.width -= 32
                        if GUI.Button(myRect, "Remove $autotileAnimSetName"):
                            Undo.RegisterUndo(config, "Remove Set $autotileAnimSetName")
                            animTileSetTrash.Push(autotileAnimSetName)
                            EditorUtility.SetDirty(config)

                    EditorGUI.indentLevel -= 1

            for s as string in animTileSetTrash:
                config.animationSets.Remove(s)

            for tileset, name in zip(newAnimSets, newAnimNames):
                config.animationSets[name] = tileset
                PopulateAtlasPreview(tileset, name)
                EditorUtility.ClearProgressBar()
                EditorUtility.SetDirty(config)

            EditorGUI.indentLevel -= 1

        if GUI.changed:
            EditorUtility.SetDirty(config)

