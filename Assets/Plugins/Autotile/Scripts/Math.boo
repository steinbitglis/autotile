import UnityEngine

static class MathUtil:

    public def GCD(l as (int)) as int:
        return l[0] if l.Length == 1
        return GCD(l[0], l[1:])

    public def GCD(a as int, l as (int)) as int:
        return GCD(a, l[0]) if l.Length == 1
        return GCD(GCD(a, l[0]), l[1:])

    public def GCD(a as int, b as int) as int:
        return a unless b
        return GCD(b, (a % b))

    public def LCM(l as (int)) as int:
        return l[0] if l.Length == 1
        return LCM(l[0], l[1:])

    public def LCM(a as int, l as (int)) as int:
        return LCM(a, l[0]) if l.Length == 1
        return LCM(LCM(a, l[0]), l[1:])

    public def LCM(a as int, b as int) as int:
        return ((a * b) / GCD(a, b))

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

    def GetVertsFromBox(component as MonoBehaviour) as (Vector2):
        box = component.GetComponent of BoxCollider()
        if box:
            half_h = box.size.y * 0.5f
            half_w = box.size.x * 0.5f
            x = box.center.x
            y = box.center.y
            return (Vector2(x - half_w, y - half_h),
                    Vector2(x - half_w, y + half_h),
                    Vector2(x + half_w, y + half_h),
                    Vector2(x + half_w, y - half_h))
        else:
            return MathOfPlanes.StandardSquare

    def RectIntersectsRect(remote as (Vector2)) as bool:
        outsideTop = outsideLeft = outsideRight = outsideBottom = true

        for v in remote:
            outsideTop = outsideTop and v.y > StandardSquare[2].y
            outsideLeft = outsideLeft and v.x < StandardSquare[0].x
            outsideRight = outsideRight and v.x > StandardSquare[2].x
            outsideBottom = outsideBottom and v.y < StandardSquare[0].y

        return not (outsideTop or outsideLeft or outsideRight or outsideBottom)

    def RectIntersectsRect(local as (Vector2), remote as (Vector2)) as bool:
        outsideTop = outsideLeft = outsideRight = outsideBottom = true

        for v in remote:
            outsideTop = outsideTop and v.y > local[2].y
            outsideLeft = outsideLeft and v.x < local[0].x
            outsideRight = outsideRight and v.x > local[2].x
            outsideBottom = outsideBottom and v.y < local[0].y

        return not (outsideTop or outsideLeft or outsideRight or outsideBottom)
