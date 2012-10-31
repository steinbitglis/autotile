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

    def CurrentTransformParent() as Transform:
        active_tile = Selection.activeGameObject.GetComponent of Autotile() if Selection.activeGameObject
        parent_transform = Selection.activeTransform.parent if active_tile
        return parent_transform

    def NewObjectPos(parent as Transform) as Vector3:
        target_pos = Vector3.zero

        view = SceneView.currentDrawingSceneView
        cameras = view.GetAllSceneCameras()
        ccam = cameras[0] if cameras.Length
        if ccam:
            screenCenterRay = ccam.ScreenPointToRay(Vector3(ccam.pixelWidth / 2f, ccam.pixelHeight / 2f, 0.0f))
            active_tile = Selection.activeGameObject.GetComponent of AutotileBase() if Selection.activeGameObject
            parent = Selection.activeTransform.parent if active_tile
            if parent:
                screen_ray_direction = parent.InverseTransformPoint(screenCenterRay.direction + parent.position)
                screen_ray_origin = parent.InverseTransformPoint(screenCenterRay.origin)

                if screen_ray_direction.z > 0f and  screen_ray_origin.z < 0f or\
                   screen_ray_direction.z < 0f and  screen_ray_origin.z > 0f:

                    t = -screen_ray_origin.z / screen_ray_direction.z
                    target_pos = screen_ray_origin + t * screen_ray_direction
                    target_pos.z = 0f
                    target_pos = parent.TransformPoint(target_pos)
            else:
                if screenCenterRay.direction.z > 0f and  screenCenterRay.origin.z < 0f or\
                   screenCenterRay.direction.z < 0f and  screenCenterRay.origin.z > 0f:

                    t = -screenCenterRay.origin.z / screenCenterRay.direction.z
                    target_pos = screenCenterRay.origin + t * screenCenterRay.direction
                    target_pos.z = 0f

        return target_pos

    [MenuItem("GameObject/Create Other/Autotile Animation")]
    def CreateAutotileAnimation() as AutotileAnimation:
        parent_transform = CurrentTransformParent()
        target_pos = NewObjectPos(parent_transform)

        targetObject = GameObject("Autotile")
        target = targetObject.AddComponent of AutotileAnimation()
        targetObject.transform.position = target_pos
        targetObject.transform.parent = parent_transform if parent_transform
        targetObject.transform.localRotation = Quaternion.identity
        if AutotileConfig.config.animationSets.Count:
            target.tilesetKey = AutotileConfig.config.animationSets.FirstKey()
            target.renderer.material = AutotileConfig.config.animationSets.First().material
            target.Refresh()
        EditorGUIUtility.PingObject(targetObject)
        Undo.RegisterCreatedObjectUndo(targetObject, "Create Autotile")

    [MenuItem("GameObject/Create Other/Autotile %t")]
    def CreateAutotile() as Autotile:
        parent_transform = CurrentTransformParent()
        target_pos = NewObjectPos(parent_transform)

        targetObject = GameObject("Autotile")
        target = targetObject.AddComponent of Autotile()
        targetObject.transform.position = target_pos
        targetObject.transform.parent = parent_transform if parent_transform
        targetObject.transform.localRotation = Quaternion.identity
        if AutotileConfig.config.sets.Count:
            target.tilesetKey = AutotileConfig.config.sets.FirstKey()
            target.renderer.material = AutotileConfig.config.sets.First().material
            target.Refresh()
        EditorGUIUtility.PingObject(targetObject)
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

    [MenuItem ("Component/Plugins/Autotile Animation", true)]
    def ValidateCreateAutotileAnimationComponent() as bool:
        return Selection.activeTransform != null

    [MenuItem("Component/Plugins/Autotile Animation")]
    def CreateAutotileAnimationComponent() as AutotileAnimation:
        changed_objects = List of GameObject()
        for o in Selection.gameObjects:
            unless o.GetComponent of AutotileAnimation():
                changed_objects.Add(o)
        if changed_objects.Count > 1:
            Undo.RegisterUndo(array(Object, changed_objects), "Create Autotile Animation components")
        elif changed_objects.Count == 1:
            Undo.RegisterUndo(array(Object, changed_objects), "Create Autotile Animation component")
        for o in changed_objects:
            t = o.AddComponent of AutotileAnimation()
            if AutotileConfig.config.sets.Count:
                t.tilesetKey = AutotileConfig.config.animationSets.FirstKey()
                t.renderer.material = AutotileConfig.config.animationSets.First().material
                t.Refresh()
