import UnityEngine
import UnityEditor
import System.Collections.Generic

static class AutotileMenus:

    [MenuItem("Assets/Create/Autotile Config")]
    def CreateConfig() as AutotileConfig:
        tc = AssetDatabase.LoadAssetAtPath("Assets/Plugins/Autotile/Tilesets.asset", AutotileConfig)
        unless tc:
            unless Directory.Exists("Assets/Plugins"):
                AssetDatabase.CreateFolder("Assets", "Plugins")
            unless Directory.Exists("Assets/Plugins/Autotile"):
                AssetDatabase.CreateFolder("Assets/Plugins", "Autotile")
            tc = ScriptableObject.CreateInstance(AutotileConfig)
            AssetDatabase.CreateAsset(tc, "Assets/Plugins/Autotile/Tilesets.asset")
        return tc

    def Refresh(t as Autotile):
        t.Refresh()
        if t.unsaved:
            t.unsaved = false
            EditorUtility.SetDirty(t)
        if t.unsavedMesh:
            t.unsavedMesh = false
            mf = t.GetComponent of MeshFilter()
            EditorUtility.SetDirty(mf) if mf

    [MenuItem("Autotile/Upgrade currently selected tile %g")]
    def UpgradeCurrentAutotile() as Autotile:
        tile = Selection.activeTransform.GetComponent of Autotile() if Selection.activeTransform
        if tile and not tile.usesAirInfo:
            air_info = Autotile.AirInfo(tile.airInfo)
            tile.SetAndPropagateAirInfo(air_info)

            all_autotiles = GameObject.FindObjectsOfType(Autotile)
            Undo.RegisterUndo(all_autotiles, "Change tile surroundings")
            for one_tile as Autotile in all_autotiles:
                Refresh(one_tile)

    [MenuItem("Autotile/Find old type tile %e")]
    def UpgradeAutotiles() as Autotile:
        tiles = GameObject.FindObjectsOfType(Autotile)
        for t in tiles:
            unless t.usesAirInfo:
                (SceneView.sceneViews[0] as SceneView).LookAt(t.transform.position)
                Selection.activeTransform = t.transform
                tiles = GameObject.FindObjectsOfType(Autotile)
                return
        Debug.Log("You're done")

    [MenuItem("GameObject/Create Other/Autotile %t")]
    def CreateAutotile() as Autotile:
        targetPos = Vector3.zero

        view = SceneView.currentDrawingSceneView
        cameras = view.GetAllSceneCameras()
        ccam = cameras[0] if cameras.Length
        if ccam:
            screenCenterRay = ccam.ScreenPointToRay(Vector3(ccam.pixelWidth / 2f, ccam.pixelHeight / 2f, 0.0f))
            if screenCenterRay.direction.z > 0f and  screenCenterRay.origin.z < 0f or\
               screenCenterRay.direction.z < 0f and  screenCenterRay.origin.z > 0f:

                t = -screenCenterRay.origin.z / screenCenterRay.direction.z
                targetPos = screenCenterRay.origin + t * screenCenterRay.direction
                targetPos.z = 0f

        targetObject = GameObject("Autotile")
        target = targetObject.AddComponent of Autotile()
        targetObject.transform.position = targetPos
        if AutotileConfig.config.sets.Count:
            target.tilesetKey = AutotileConfig.config.sets.FirstKey()
            target.renderer.material = AutotileConfig.config.sets.First().material
            target.Refresh()
        Undo.RegisterCreatedObjectUndo(targetObject, "Create Autotile")

    [MenuItem ("Component/Plugins/Autotile", true)]
    def ValidateCreateAutotileComponent() as bool:
        return Selection.activeTransform != null

    [MenuItem("Component/Plugins/Autotile")]
    def CreateAutotileComponent() as Autotile:
        changed_objects = List of GameObject()
        for o in Selection.gameObjects:
            unless o.GetComponent of Autotile():
                changed_objects.Add(o)
        if changed_objects.Count > 1:
            Undo.RegisterUndo(array(Object, changed_objects), "Create Autotile components")
        elif changed_objects.Count == 1:
            Undo.RegisterUndo(array(Object, changed_objects), "Create Autotile component")
        for o in changed_objects:
            t = o.AddComponent of Autotile()
            if AutotileConfig.config.sets.Count:
                t.tilesetKey = AutotileConfig.config.sets.FirstKey()
                t.renderer.material = AutotileConfig.config.sets.First().material
                t.Refresh()
