import UnityEngine
import System.Collections
import System.Collections.Generic

class AnimationTile (Tile):
    public frames = 1

    override def Duplicate() as Tile:
        result = AnimationTile()
        result.atlasLocation = Rect(
            atlasLocation.x,
            atlasLocation.y,
            atlasLocation.width,
            atlasLocation.height)
        result.flipped = flipped
        result.direction = direction
        result.rotated = rotated
        result.rotation = rotation
        result.frames = frames
        return result

class AutotileAnimationTileset (IEnumerable of (AnimationTile)):
    enum Orientation:
        Horizontal
        Vertical

    [System.NonSerialized]
    public show = false
    [System.NonSerialized]
    public showRemoveOption = false
    [System.NonSerialized]
    public showingFace = (false, false)

    public candidateFrames = (1, 1)
    public horizontalFaces = (AnimationTile(),)
    public verticalFaces = (AnimationTile(),)

    def SetFaces(index as int, value as (AnimationTile)):
        if index == Orientation.Horizontal:
            horizontalFaces = value
        else:
            verticalFaces = value

    self[index as int] as (AnimationTile):
        get:
            return (horizontalFaces, verticalFaces)[index]

    private myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator of (AnimationTile):
        yield horizontalFaces
        yield verticalFaces

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()

    def Duplicate() as AutotileAnimationTileset:
        result = AutotileAnimationTileset()
        result.horizontalFaces = horizontalFaces
        result.verticalFaces = verticalFaces
        return result

class AutotileAnimationTilesetDatabase (IEnumerable[KeyValuePair[of int, AutotileAnimationTileset]]):
    [SerializeField]
    private keys = List of int()

    [SerializeField]
    private values = List of AutotileAnimationTileset()

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
    private _backingDictionary = SortedDictionary[of int, AutotileAnimationTileset](Autotile.Descending())
    private backingDictionary as SortedDictionary[of int, AutotileAnimationTileset]:
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

    self[index as int] as AutotileAnimationTileset:
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
    public def GetEnumerator() as Generic.IEnumerator[of KeyValuePair[of int, AutotileAnimationTileset]]:
        for pair as KeyValuePair[of int, AutotileAnimationTileset] in self.backingDictionary:
            yield pair

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()

class AutotileAnimationCorners (IEnumerable of (AnimationTile)):

    [System.NonSerialized]
    public show = false

    [System.NonSerialized]
    public showingCorner = (false, false, false, false, false)

    public candidateFrames = (1, 1, 1, 1, 1)

    public centric = (AnimationTile(),)
    public left    = (AnimationTile(),)
    public right   = (AnimationTile(),)
    public bottom  = (AnimationTile(),)
    public top     = (AnimationTile(),)

    self[index as int] as (AnimationTile):
        get:
            return (centric, left, right, bottom, top)[index]

    #eachCornerList as IEnumerator of (AnimationTile):
    #    get:
    #        yield horizontalFaces
    #        yield verticalFaces

    def SetCorners(index as int, value as (AnimationTile)):
        if index < 2:
            if index == 0:
                centric = value
            else:
                left = value
        else:
            if index < 3:
                right = value
            elif index < 4:
                bottom = value
            else:
                top = value

    private myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator of (AnimationTile):
        yield centric
        yield left
        yield right
        yield bottom
        yield top

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()

    def Duplicate() as AutotileAnimationCorners:
        result = AutotileAnimationCorners()
        result.centric = (f.Duplicate() as AnimationTile for f in centric)
        result.left    = (f.Duplicate() as AnimationTile for f in left)
        result.right   = (f.Duplicate() as AnimationTile for f in right)
        result.bottom  = (f.Duplicate() as AnimationTile for f in bottom)
        result.top     = (f.Duplicate() as AnimationTile for f in top)
        return result

[System.Serializable]
class AutotileAnimationSet (AutotileBaseSet):

    public framesPerSecond = 50f

    [System.NonSerialized]
    public showSets = false
    [System.NonSerialized]
    public showNewSetOption = false
    public sets = AutotileAnimationTilesetDatabase()

    [System.NonSerialized]
    public showCorners = false
    public corners = AutotileAnimationCorners()

    def Duplicate() as AutotileBaseSet:
        result = AutotileAnimationSet()
        result.material = material
        result.tileSize = tileSize
        for csEntry in sets:
            cSet = csEntry.Value
            cSetKey = csEntry.Key
            dup = cSet.Duplicate()
            result.sets[cSetKey] = dup
        return result

class AutotileAnimationSetDatabase (IEnumerable[of KeyValuePair[of string, AutotileAnimationSet]]):
    public show = false

    [SerializeField]
    private keys = List of string()

    [SerializeField]
    private values = List of AutotileAnimationSet()

    [System.NonSerialized]
    private _backingDictionary as Dictionary[of string, AutotileAnimationSet]
    private backingDictionary as Dictionary[of string, AutotileAnimationSet]:
        get:
            if not _backingDictionary or _backingDictionary.Count != keys.Count:
                _backingDictionary = Dictionary[of string, AutotileAnimationSet]()
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

    self[index as string] as AutotileAnimationSet:
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

    public def First() as AutotileAnimationSet:
        return values[0]

    public def FirstKey() as string:
        return keys[0]

    public def ContainsKey(index as string) as bool:
        return self.backingDictionary.ContainsKey(index)

    public myGetEnumerator = GetEnumerator
    public def GetEnumerator() as Generic.IEnumerator[of KeyValuePair[of string, AutotileAnimationSet]]:
        for pair as KeyValuePair[of string, AutotileAnimationSet] in self.backingDictionary:
            yield pair

    def IEnumerable.GetEnumerator() as IEnumerator:
        return myGetEnumerator()
