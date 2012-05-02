import UnityEngine
import System.Collections
import System.Collections.Generic
import System.Reflection

enum TileDirection:
    Horizontal
    Vertical

class Tile:
    [System.NonSerialized]
    public show = false
    public atlasLocation = Rect()
    public direction = TileDirection.Horizontal
    public flipped = false

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

    private static myType = typeof(AutotileCorners)
    self[index as string] as Tile:
        get:
            fieldInfo = AutotileCorners.myType.GetField(index, BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
            return fieldInfo.GetValue(self) as Tile if fieldInfo
            return bbbb

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

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()

class AutotileCenterSetDatabase (IEnumerable[KeyValuePair[of int, AutotileCenterSet]]):
    [SerializeField]
    private keys = List of int()

    [SerializeField]
    private values = List of AutotileCenterSet()

    [System.NonSerialized]
    private _backingDictionary as Dictionary[of int, AutotileCenterSet]
    private backingDictionary as Dictionary[of int, AutotileCenterSet]:
        get:
            if not _backingDictionary or _backingDictionary.Count != keys.Count:
                _backingDictionary = Dictionary[of int, AutotileCenterSet]()
                for i in range(values.Count):
                    _backingDictionary[keys[i]] = values[i]
            return _backingDictionary

    public def Remove(index as int) as bool:
        self.backingDictionary.Remove(index)
        for i in range(values.Count):
            if keys[i] == index:
                keys.RemoveAt(i)
                values.RemoveAt(i)
                return true;
        return false;

    self[index as int] as AutotileCenterSet:
        set:
            self.backingDictionary[index] = value;
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
class AutotileSet:
    [System.NonSerialized]
    public show = false

    [System.NonSerialized]
    public newCandidate = 2

    [System.NonSerialized]
    public showSettings = true
    public tileSize = 128
    public material as Material

    [System.NonSerialized]
    public showRemoveOption = false

    [System.NonSerialized]
    public showCenterSets = false
    [System.NonSerialized]
    public showNewCenterSetOption = false
    public centerSets = AutotileCenterSetDatabase()

    [System.NonSerialized]
    public showCorners = false
    public corners = AutotileCorners()

class AutotileSetDatabase (IEnumerable[of KeyValuePair[of string, AutotileSet]]):
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

    public myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator[of KeyValuePair[of string, AutotileSet]]:
        for pair as KeyValuePair[of string, AutotileSet] in self.backingDictionary:
            yield pair

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()
