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

    [MenuItem("GameObject/Create Other/Autotile %t")]
    def CreateAutotile() as Autotile:
        target_pos = Vector3.zero

        view = SceneView.currentDrawingSceneView
        cameras = view.GetAllSceneCameras()
        ccam = cameras[0] if cameras.Length
        parent_transform as Transform
        if ccam:
            screenCenterRay = ccam.ScreenPointToRay(Vector3(ccam.pixelWidth / 2f, ccam.pixelHeight / 2f, 0.0f))
            active_tile = Selection.activeGameObject.GetComponent of Autotile() if Selection.activeGameObject
            parent_transform = Selection.activeTransform.parent if active_tile
            if parent_transform:
                screen_ray_direction = parent_transform.InverseTransformPoint(screenCenterRay.direction + parent_transform.position)
                screen_ray_origin = parent_transform.InverseTransformPoint(screenCenterRay.origin)

                if screen_ray_direction.z > 0f and  screen_ray_origin.z < 0f or\
                   screen_ray_direction.z < 0f and  screen_ray_origin.z > 0f:

                    t = -screen_ray_origin.z / screen_ray_direction.z
                    target_pos = screen_ray_origin + t * screen_ray_direction
                    target_pos.z = 0f
                    target_pos = parent_transform.TransformPoint(target_pos)
            else:
                if screenCenterRay.direction.z > 0f and  screenCenterRay.origin.z < 0f or\
                   screenCenterRay.direction.z < 0f and  screenCenterRay.origin.z > 0f:

                    t = -screenCenterRay.origin.z / screenCenterRay.direction.z
                    target_pos = screenCenterRay.origin + t * screenCenterRay.direction
                    target_pos.z = 0f

        targetObject = GameObject("Autotile")
        target = targetObject.AddComponent of Autotile()
        targetObject.transform.position = target_pos
        targetObject.transform.parent = parent_transform if parent_transform
        targetObject.transform.localRotation = Quaternion.identity
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
