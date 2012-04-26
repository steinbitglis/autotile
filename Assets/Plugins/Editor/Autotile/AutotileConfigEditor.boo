import UnityEngine
import UnityEditor
import System.IO

[CustomEditor(AutotileConfig)]
class AutotileConfigEditor (Editor):

    config as AutotileConfig

    newSetName = ""

    def Awake():
        config = target as AutotileConfig

    [MenuItem("Assets/Autotile/Create Autotile Config")]
    static def CreateConfig() as AutotileConfig:
        tc = AssetDatabase.LoadAssetAtPath("Assets/Resources/Editor/AutotileConfig.asset", AutotileConfig)
        unless tc:
            unless Directory.Exists("Assets/Resources"):
                AssetDatabase.CreateFolder("Assets", "Resources")
            unless Directory.Exists("Assets/Resources/Editor"):
                AssetDatabase.CreateFolder("Assets/Resources", "Editor")
            tc = ScriptableObject.CreateInstance(AutotileConfig)
            AssetDatabase.CreateAsset(tc, "Assets/Resources/Editor/AutotileConfig.asset")
        return tc

     def drawTileGUINamed(t as Tile, n as string, prefix as string):
        t.show = EditorGUILayout.Foldout(t.show, n)
        if t.show:
            EditorGUI.indentLevel += 1
            newAtlasLocation = EditorGUILayout.RectField("Atlas Location", t.atlasLocation)
            if t.atlasLocation != newAtlasLocation:
                Undo.RegisterUndo(config, "Set Atlas Location in $(prefix)$n")
                t.atlasLocation = newAtlasLocation
            newFlipped = EditorGUILayout.Toggle("Flipped", t.flipped)
            if t.flipped != newFlipped:
                Undo.RegisterUndo(config, "Set Flipped in $(prefix)$n")
                t.flipped = newFlipped
            if t.flipped:
                newDirection = EditorGUILayout.EnumPopup("Direction", t.direction)
                if t.direction cast System.Enum != newDirection:
                    Undo.RegisterUndo(config, "Set Direction in $(prefix)$n")
                    t.direction = newDirection
            EditorGUI.indentLevel -= 1

    def drawTileGUI(t as Tile, n as string):
        drawTileGUINamed(t, n, "")

    def OnInspectorGUI():

        EditorGUILayout.BeginHorizontal(GUILayout.Width(400))
        newSetName = EditorGUILayout.TextField("New Set", newSetName);
        EditorGUILayout.Space();
        acceptNewSet = GUILayout.Button("Add", GUILayout.Width(60))
        EditorGUILayout.EndHorizontal()
        EditorGUILayout.Space();
        EditorGUILayout.Space();

        if newSetName and acceptNewSet:
            Undo.RegisterUndo(config, "Add Autotile Set $newSetName")

            config.sets[newSetName] = AutotileSet()
            newSetName = ""
            GUIUtility.keyboardControl = 0
            EditorUtility.SetDirty(config)

        tileSetTrash = []

        for setEntry in config.sets:
            autotileSet = setEntry.Value
            autotileSetName = setEntry.Key

            EditorGUILayout.BeginHorizontal()
            autotileSet.show = EditorGUILayout.Foldout(autotileSet.show, autotileSetName)
            if GUILayout.Button("Remove $autotileSetName", GUILayout.Width(160)):
                Undo.RegisterUndo(config, "Remove Set $autotileSetName")
                tileSetTrash.Push(autotileSetName)
                EditorUtility.SetDirty(config)
            EditorGUILayout.EndHorizontal()

            if autotileSet.show:

                EditorGUI.indentLevel += 1
                EditorGUILayout.BeginHorizontal(GUILayout.Width(400))
                autotileSet.newCandidate = EditorGUILayout.IntField("New Center Set", autotileSet.newCandidate)
                EditorGUILayout.Space();
                acceptNew = GUILayout.Button("Add", GUILayout.Width(60))
                EditorGUILayout.EndHorizontal()

                if autotileSet.newCandidate > 0 and acceptNew:
                    Undo.RegisterUndo(config, "Add New Center Set $(autotileSet.newCandidate)")

                    newCenterSet = AutotileCenterSet()
                    autotileSet.centerSets[autotileSet.newCandidate] = newCenterSet
                    autotileSet.newCandidate = 0
                    autotileSet.showCenterSets = true
                    newCenterSet.show = true
                    GUIUtility.keyboardControl = 0
                    EditorUtility.SetDirty(config)

                autotileSet.showCenterSets = EditorGUILayout.Foldout(autotileSet.showCenterSets, "Center Sets")
                if autotileSet.showCenterSets:
                    trash = []

                    EditorGUI.indentLevel += 1
                    for csEntry in autotileSet.centerSets:

                        if csEntry.Value:
                            cSet = csEntry.Value
                            cSetKey = csEntry.Key

                            EditorGUILayout.BeginHorizontal()
                            cSet.show = EditorGUILayout.Foldout(cSet.show, "$cSetKey")
                            if GUILayout.Button("Remove $cSetKey", GUILayout.Width(160)):
                                Undo.RegisterUndo(config, "Remove Center Set $cSetKey")
                                trash.Push(cSetKey)
                                EditorUtility.SetDirty(config)
                            EditorGUILayout.EndHorizontal()

                            if cSet.show:
                                EditorGUI.indentLevel += 1
                                props      = (cSet.leftFace,  cSet.rightFace,  cSet.downFace,  cSet.upFace,  cSet.doubleHorizontalFace,   cSet.doubleVerticalFace)
                                prop_names = ("Left Face",    "Right Face",    "Down Face",    "Up Face",    "Double Horizontal Face",    "Double Vertical Face")
                                for face as Tile, faceName as string in zip(props, prop_names):
                                    drawTileGUINamed(face, faceName, "$cSetKey.")
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

                autotileSet.showCorners = EditorGUILayout.Foldout(autotileSet.showCorners, "Corners")
                if autotileSet.showCorners:
                    EditorGUI.indentLevel += 1
                    all_corners autotileSet.corners, drawTileGUI
                    EditorGUI.indentLevel -= 1

                EditorGUI.indentLevel -= 1

        for s as string in tileSetTrash:
            config.sets.Remove(s)

        if GUI.changed:
            EditorUtility.SetDirty(config)
