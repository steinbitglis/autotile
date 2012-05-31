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

    [MenuItem("GameObject/Create Other/Autotile")]
    def CreateAutotile() as Autotile:
        targetPos = Vector3.zero

        ccam = Camera.current
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
        Undo.RegisterCreatedObjectUndo(target, "Create Autotile")

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
