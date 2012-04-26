import UnityEngine

static class MathOfPlanes:

    inline_enum direction:
        Top
        Left
        Right
        Bottom

    def RectIntersectsRect(local as (Vector2), remote as (Vector2)) as bool:
        minLimitX = local[0].x
        minLimitY = local[0].y
        maxLimitX = local[2].x
        maxLimitY= local[2].y
        outside = (true, true, true, true)

        for v in remote:
            outside[Top] = outside[Top] and v.y > maxLimitY
            outside[Left] = outside[Left] and v.x < minLimitX
            outside[Right] = outside[Right] and v.x > maxLimitX
            outside[Bottom] = outside[Bottom] and v.y < minLimitY

        return true not in outside
