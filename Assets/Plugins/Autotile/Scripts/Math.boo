import UnityEngine

static class MathOfPlanes:

    def PointInTri(a as Vector2, b as Vector2, c as Vector2, p as Vector2) as bool:
        v0 = b-c
        v1 = a-c
        v2 = p-c
        dot00 = Vector2.Dot(v0, v0)
        dot01 = Vector2.Dot(v0, v1)
        dot02 = Vector2.Dot(v0, v2)
        dot11 = Vector2.Dot(v1, v1)
        dot12 = Vector2.Dot(v1, v2)
        invDenom = 1.0f / (dot00 * dot11 - dot01 * dot01)
        u = (dot11 * dot02 - dot01 * dot12) * invDenom
        v = (dot00 * dot12 - dot01 * dot02) * invDenom
        return (0f < u) and (0f < v) and (u + v < 1.0f)

    inline_enum direction:
        Top
        Left
        Right
        Bottom

    public final StandardSquare = (
        Vector2(-0.5f, -0.5f), Vector2(-0.5f,  0.5f),
        Vector2( 0.5f,  0.5f), Vector2( 0.5f, -0.5f))

    def RectIntersectsRect(remote as (Vector2)) as bool:
        minLimitX = StandardSquare[0].x
        minLimitY = StandardSquare[0].y
        maxLimitX = StandardSquare[2].x
        maxLimitY = StandardSquare[2].y
        outside = (true, true, true, true)

        for v in remote:
            outside[Top] = outside[Top] and v.y > maxLimitY
            outside[Left] = outside[Left] and v.x < minLimitX
            outside[Right] = outside[Right] and v.x > maxLimitX
            outside[Bottom] = outside[Bottom] and v.y < minLimitY

        return true not in outside

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
