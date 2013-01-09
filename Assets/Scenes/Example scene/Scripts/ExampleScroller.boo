import UnityEngine

class ExampleScroller (MonoBehaviour):

    private num as int
    def Update ():
        if Input.GetKeyDown(KeyCode.Space):
            animation.Play("Animation $num")
            num = (num + 1) % 5
