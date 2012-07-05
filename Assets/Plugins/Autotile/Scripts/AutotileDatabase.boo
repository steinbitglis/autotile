import UnityEngine
import System.Collections
import System.Collections.Generic
import System.Reflection

enum TileDirection:
    Horizontal
    Vertical

enum TileFlipDirection:
    Horizontal
    Vertical
    Both

enum TileRotation:
    CW
    CCW
    _180

class Tile:
    [System.NonSerialized]
    public show = false
    public atlasLocation = Rect()
    public flipped = false
    public direction = TileFlipDirection.Horizontal
    public rotated = false
    public rotation = TileRotation.CW

    virtual def Duplicate() as Tile:
        result = Tile()
        result.atlasLocation = Rect(
            atlasLocation.x,
            atlasLocation.y,
            atlasLocation.width,
            atlasLocation.height)
        result.flipped = flipped
        result.direction = direction
        result.rotated = rotated
        result.rotation = rotation
        return result

class AutotileCenterSet:
    [System.NonSerialized]
    public show = false
    [System.NonSerialized]
    public showRemoveOption = false
    public leftFace = Tile()
    public rightFace = Tile()
    public downFace = Tile()
    public upFace = Tile()
    public doubleHorizontalFace = Tile()
    public doubleVerticalFace = Tile()

    def Duplicate() as AutotileCenterSet:
        result = AutotileCenterSet()
        result.leftFace = leftFace.Duplicate()
        result.rightFace = rightFace.Duplicate()
        result.downFace = downFace.Duplicate()
        result.upFace = upFace.Duplicate()
        result.doubleHorizontalFace = doubleHorizontalFace.Duplicate()
        result.doubleVerticalFace = doubleVerticalFace.Duplicate()
        return result

class AutotileCorners (IEnumerable[Tile]):
    //
    //            - ----------------------------------------------------------------------- -
    //            - -- Center piece naming convention for horizontal and vertical pieces -- -
    //            - ----------------------------------------------------------------------- -
    //
    //             L                  R                  D                  A                  B
    //      ______________     ______________     ______________     ______________     ______________
    //     |$Oo           |   |           oO$|   |$Oo        oO$|   |              |   |              |
    //     |$Oo           |   |           oO$|   |$Oo        oO$|   |              |   |              |
    //     |$Oo           |   |           oO$|   |$Oo        oO$|   |              |   |              |
    //     |$Oo  black    |   |   black   oO$|   |$Oo  black oO$|   |      air     |   |     black    |
    //     |$Oo           |   |           oO$|   |$Oo        oO$|   |              |   |              |
    //     |$Oo           |   |           oO$|   |$Oo        oO$|   |              |   |              |
    //     |$Oo           |   |           oO$|   |$Oo        oO$|   |              |   |              |
    //      ^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^
    //
    //             G                  C                  D
    //      ______________     ______________     ______________
    //     |$$$$$$$$$$$$$$|   |              |   |$$$$$$$$$$$$$$|
    //     |oooooooooooooo|   |              |   |oooooooooooooo|
    //     |              |   |              |   |              |
    //     |     black    |   |     black    |   |     black    |
    //     |              |   |              |   |              |
    //     |              |   |oooooooooooooo|   |oooooooooooooo|
    //     |              |   |$$$$$$$$$$$$$$|   |$$$$$$$$$$$$$$|
    //      ^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^
    //
    //            - ----------------------------------------------------------------------- -
    //            - --                    Corner piece naming convention                 -- -
    //            - ----------------------------------------------------------------------- -
    //
    //           |       W      |
    //           |              |
    //            ^^^^^^^^^^^^^^
    //      ___   ______________   ___
    //         | |              | |
    //         | |              | |
    //         | |              | |
    //       Z | |    corner    | | X
    //         | |              | |
    //         | |              | |
    //         | |              | |
    //      ^^^   ^^^^^^^^^^^^^^   ^^^
    //            ______________
    //           |              |
    //           |       Y      |
    //
    //    Given neighbours of types W, X, Y and Z,
    //    the corner will have the name 'WXYZ'.
    //
    [System.NonSerialized]
    public show = false
    public aaaa = Tile()
    public aaad = Tile()
    public aada = Tile()
    public aadd = Tile()
    public aarg = Tile()
    public adaa = Tile()
    public adad = Tile()
    public adda = Tile()
    public addd = Tile()
    public adrg = Tile()
    public agbg = Tile()
    public agla = Tile()
    public agld = Tile()
    public bbbb = Tile()
    public bblc = Tile()
    public bcac = Tile()
    public bcdc = Tile()
    public bcrb = Tile()
    public daaa = Tile()
    public daad = Tile()
    public dada = Tile()
    public dadd = Tile()
    public darg = Tile()
    public ddaa = Tile()
    public ddad = Tile()
    public ddda = Tile()
    public dddd = Tile()
    public ddrg = Tile()
    public dgbg = Tile()
    public dgla = Tile()
    public dgld = Tile()
    public lbbg = Tile()
    public lbla = Tile()
    public lbld = Tile()
    public lcaa = Tile()
    public lcad = Tile()
    public lcda = Tile()
    public lcdd = Tile()
    public lcrg = Tile()
    public raac = Tile()
    public radc = Tile()
    public rarb = Tile()
    public rdac = Tile()
    public rddc = Tile()
    public rdrb = Tile()
    public rgbb = Tile()
    public rglc = Tile()
    public unknown = Tile()

    private static myType = typeof(AutotileCorners)
    self[index as string] as Tile:
        get:
            fieldInfo = AutotileCorners.myType.GetField(index, BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
            return fieldInfo.GetValue(self) as Tile if fieldInfo
            raise KeyNotFoundException(index)

    private myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator[of Tile]:
        yield aaaa
        yield aaad
        yield aada
        yield aadd
        yield aarg
        yield adaa
        yield adad
        yield adda
        yield addd
        yield adrg
        yield agbg
        yield agla
        yield agld
        yield bbbb
        yield bblc
        yield bcac
        yield bcdc
        yield bcrb
        yield daaa
        yield daad
        yield dada
        yield dadd
        yield darg
        yield ddaa
        yield ddad
        yield ddda
        yield dddd
        yield ddrg
        yield dgbg
        yield dgla
        yield dgld
        yield lbbg
        yield lbla
        yield lbld
        yield lcaa
        yield lcad
        yield lcda
        yield lcdd
        yield lcrg
        yield raac
        yield radc
        yield rarb
        yield rdac
        yield rddc
        yield rdrb
        yield rgbb
        yield rglc
        yield unknown

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()

    def Duplicate() as AutotileCorners:
        result = AutotileCorners()
        result.aaaa = aaaa.Duplicate(); result.aaad = aaad.Duplicate(); result.aada = aada.Duplicate()
        result.aadd = aadd.Duplicate(); result.aarg = aarg.Duplicate(); result.adaa = adaa.Duplicate()
        result.adad = adad.Duplicate(); result.adda = adda.Duplicate(); result.addd = addd.Duplicate()
        result.adrg = adrg.Duplicate(); result.agbg = agbg.Duplicate(); result.agla = agla.Duplicate()
        result.agld = agld.Duplicate(); result.bbbb = bbbb.Duplicate(); result.bblc = bblc.Duplicate()
        result.bcac = bcac.Duplicate(); result.bcdc = bcdc.Duplicate(); result.bcrb = bcrb.Duplicate()
        result.daaa = daaa.Duplicate(); result.daad = daad.Duplicate(); result.dada = dada.Duplicate()
        result.dadd = dadd.Duplicate(); result.darg = darg.Duplicate(); result.ddaa = ddaa.Duplicate()
        result.ddad = ddad.Duplicate(); result.ddda = ddda.Duplicate(); result.dddd = dddd.Duplicate()
        result.ddrg = ddrg.Duplicate(); result.dgbg = dgbg.Duplicate(); result.dgla = dgla.Duplicate()
        result.dgld = dgld.Duplicate(); result.lbbg = lbbg.Duplicate(); result.lbla = lbla.Duplicate()
        result.lbld = lbld.Duplicate(); result.lcaa = lcaa.Duplicate(); result.lcad = lcad.Duplicate()
        result.lcda = lcda.Duplicate(); result.lcdd = lcdd.Duplicate(); result.lcrg = lcrg.Duplicate()
        result.raac = raac.Duplicate(); result.radc = radc.Duplicate(); result.rarb = rarb.Duplicate()
        result.rdac = rdac.Duplicate(); result.rddc = rddc.Duplicate(); result.rdrb = rdrb.Duplicate()
        result.rgbb = rgbb.Duplicate(); result.rglc = rglc.Duplicate()
        result.unknown = unknown.Duplicate()
        return result

class AutotileCenterSetDatabase (IEnumerable[KeyValuePair[of int, AutotileCenterSet]]):
    [SerializeField]
    private keys = List of int()

    [SerializeField]
    private values = List of AutotileCenterSet()

    smallestKey as int:
        get:
            return _smallestKey unless _smallestKey == int.MaxValue
            for k in keys:
                _smallestKey = k if k < _smallestKey
            if _smallestKey == int.MaxValue:
                if keys.Count:
                    return keys[0]
                else:
                    return 0
            else:
                return _smallestKey

    [SerializeField]
    private _smallestKey = int.MaxValue

    [System.NonSerialized]
    private _backingDictionary = Dictionary[of int, AutotileCenterSet]()
    private backingDictionary as Dictionary[of int, AutotileCenterSet]:
        get:
            if _backingDictionary.Count != keys.Count:
                _backingDictionary.Clear()
                _smallestKey = int.MaxValue
                for i in range(values.Count):
                    _smallestKey = keys[i] if keys[i] < _smallestKey
                    _backingDictionary[keys[i]] = values[i]
            return _backingDictionary

    public def Remove(index as int) as bool:
        _backingDictionary.Remove(index)
        for i, key as int in enumerate(keys):
            if key == index:
                keys.RemoveAt(i)
                values.RemoveAt(i)
                was_found = true
                break
        if _smallestKey == index:
            _smallestKey = int.MaxValue
            for i in range(values.Count):
                _smallestKey = keys[i] if keys[i] < _smallestKey
        return was_found

    self[index as int] as AutotileCenterSet:
        set:
            _smallestKey = index if index < _smallestKey
            _backingDictionary[index] = value
            for i in range(values.Count):
                if keys[i] == index:
                    values[i] = value
                    return
            keys.Add(index)
            values.Add(value)
        get:
            return self.backingDictionary[index]

    public Count as int:
        get:
            return self.backingDictionary.Count

    public def ContainsKey(k as int) as bool:
        return self.backingDictionary.ContainsKey(k)

    private myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator[of KeyValuePair[of int, AutotileCenterSet]]:
        for pair as KeyValuePair[of int, AutotileCenterSet] in self.backingDictionary:
            yield pair

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()

[System.Serializable]
class AutotileSet (AutotileBaseSet):

    [System.NonSerialized]
    public showCenterSets = false
    [System.NonSerialized]
    public showNewCenterSetOption = false
    public centerSets = AutotileCenterSetDatabase()

    [System.NonSerialized]
    public showCorners = false
    public corners = AutotileCorners()

    def Duplicate() as AutotileBaseSet:
        result = AutotileSet()
        result.material = material
        result.tileSize = tileSize
        for csEntry in centerSets:
            cSet = csEntry.Value
            cSetKey = csEntry.Key
            dup = cSet.Duplicate()
            result.centerSets[cSetKey] = dup
        result.corners = corners.Duplicate()
        return result

class AutotileSetDatabase (IEnumerable[of KeyValuePair[of string, AutotileSet]]):
    public show = false

    [SerializeField]
    private keys = List of string()

    [SerializeField]
    private values = List of AutotileSet()

    [System.NonSerialized]
    private _backingDictionary as Dictionary[of string, AutotileSet]
    private backingDictionary as Dictionary[of string, AutotileSet]:
        get:
            if not _backingDictionary or _backingDictionary.Count != keys.Count:
                _backingDictionary = Dictionary[of string, AutotileSet]()
                for i in range(values.Count):
                    _backingDictionary[keys[i]] = values[i]
            return _backingDictionary

    public def Remove(index as string) as bool:
        self.backingDictionary.Remove(index)
        for i in range(values.Count):
            if keys[i] == index:
                keys.RemoveAt(i)
                values.RemoveAt(i)
                return true
        return false

    self[index as string] as AutotileSet:
        set:
            self.backingDictionary[index] = value
            for i in range(values.Count):
                if keys[i] == index:
                    values[i] = value
                    return
            keys.Add(index)
            values.Add(value)
        get:
            return self.backingDictionary[index]

    public Count as int:
        get:
            return self.backingDictionary.Count

    public def First() as AutotileSet:
        return values[0]

    public def FirstKey() as string:
        return keys[0]

    public def ContainsKey(index as string) as bool:
        return self.backingDictionary.ContainsKey(index)

    public myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator[of KeyValuePair[of string, AutotileSet]]:
        for pair as KeyValuePair[of string, AutotileSet] in self.backingDictionary:
            yield pair

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()
