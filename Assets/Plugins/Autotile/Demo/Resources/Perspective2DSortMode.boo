import UnityEngine

[ExecuteInEditMode, RequireComponent(Camera)]
class Perspective2DSortMode (MonoBehaviour):
    def Awake ():
        camera.transparencySortMode = TransparencySortMode.Orthographic
