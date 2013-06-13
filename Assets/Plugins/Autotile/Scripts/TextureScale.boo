## This script is a major modification of http://wiki.unity3d.com/index.php?title=TextureScale

## Only works on ARGB32, RGB24 and Alpha8 textures that are marked readable

import System.Threading

interface TextureScaleProgressListener:
    def Progress(s as single)

class TextureScaleTransform:
    public flip as TextureScaleFlip
    public rotate as TextureScaleRotate
    def constructor (f as TextureScaleFlip, r as TextureScaleRotate):
        flip = f
        rotate = r

enum TextureScaleFlip:
    None
    Horizontal
    Vertical
    Both

enum TextureScaleRotate:
    None
    CW
    CCW
    _180

class TextureScale:

    class ThreadData:
        public start as int
        public end as int
        public report as bool
        public flip as TextureScaleFlip
        public rotate as TextureScaleRotate

        def constructor (s as int, e as int, r as bool, f as TextureScaleFlip, ro as TextureScaleRotate):
            start = s
            end = e
            report = r
            flip = f
            rotate = ro

    private static outOfMemory as bool
    private static texColors as (Color)
    private static newColors as (Color)
    private static texSource as Texture2D
    private static w as int
    private static ratioX as single
    private static ratioY as single
    private static w2 as int
    private static h2 as int
    private static finishCount as int
    private static listener as TextureScaleProgressListener
    private static mutex as Mutex

    static def Bilinear (tex as Texture2D, newWidth as int, newHeight as int):
        Bilinear (tex, newWidth, newHeight, null)

    static def Bilinear (tex as Texture2D, result as Texture2D, l as TextureScaleProgressListener):
        listener = l
        ThreadedScale (tex, result.width, result.height, result)

    static def Bilinear (tex as Texture2D, result as Texture2D, l as TextureScaleProgressListener, transform as TextureScaleTransform):
        listener = l
        ThreadedScale (tex, result.width, result.height, result, transform)

    static def Bilinear (tex as Texture2D, newWidth as int, newHeight as int, l as TextureScaleProgressListener):
        listener = l
        ThreadedScale (tex, newWidth, newHeight, tex)

    private static def ThreadedScale (tex as Texture2D, newWidth as int, newHeight as int, result as Texture2D):
        TextureScale.ThreadedScale(tex, newWidth, newHeight, result, TextureScaleTransform(TextureScaleFlip.None, TextureScaleRotate.None))

    private static def ThreadedScale (tex as Texture2D, newWidth as int, newHeight as int, result as Texture2D, transform as TextureScaleTransform):
        unless mutex:
            mutex = Mutex(false)
        try:
            texColors = tex.GetPixels()
            outOfMemory = false
        except err as System.OutOfMemoryException:
            texSource = tex
            outOfMemory = true
        newColors = array(Color, newWidth * newHeight)
        ratioX = 1.0 / ((newWidth cast single)  / (tex.width-1))
        ratioY = 1.0 / ((newHeight cast single) / (tex.height-1))
        w = tex.width
        w2 = newWidth
        h2 = newHeight
        cores = Mathf.Min(SystemInfo.processorCount, newHeight)
        slice = newHeight/cores
        finishCount = 0

        if cores > 1 and not outOfMemory:
            i = 0
            while i < cores-1:
                threadData = ThreadData(slice*i, slice*(i+1), false, transform.flip, transform.rotate)
                thread = Thread(BilinearScale)
                thread.Start(threadData)
                i += 1
            threadData = ThreadData(slice*i, newHeight, true, transform.flip, transform.rotate)
            BilinearScale(threadData)
            while finishCount < cores:
                Thread.Sleep(1)
        else:
            threadData = ThreadData(0, newHeight, true, transform.flip, transform.rotate)
            BilinearScale(threadData)

        if tex == result:
            result.Resize(newWidth, newHeight)
        result.SetPixels(newColors)
        result.Apply()

        texColors = null
        newColors = null
        texSource = null

    private static def BilinearScale (threadData as ThreadData):
        y = threadData.start
        while y < threadData.end:
            yFloor = Mathf.Floor(y * ratioY)
            y1 = yFloor * w
            y2 = (yFloor+1) * w

            x = 0
            while x < w2:
                xFloor = Mathf.Floor(x * ratioX)
                xLerp = x * ratioX-xFloor

                target_x as int
                target_y as int
                if threadData.flip == TextureScaleFlip.None:
                    target_x = x
                    target_y = y
                elif threadData.flip == TextureScaleFlip.Horizontal:
                    target_x = w2 - x - 1
                    target_y = y
                elif threadData.flip == TextureScaleFlip.Vertical:
                    target_x = x
                    target_y = h2 - y - 1
                elif threadData.flip == TextureScaleFlip.Both:
                    target_x = w2 - x - 1
                    target_y = h2 - y - 1

                buf = target_x
                if threadData.rotate == TextureScaleRotate.CW:
                    target_x = h2 - target_y - 1
                    target_y = buf
                elif threadData.rotate == TextureScaleRotate.CCW:
                    target_x = target_y
                    target_y = w2 - buf - 1
                elif threadData.rotate == TextureScaleRotate._180:
                    target_x = w2 - target_x - 1
                    target_y = h2 - target_y - 1

                if outOfMemory:
                    newColors[target_y * w2 + target_x] = texSource.GetPixelBilinear((x + 0.5f) / w2, (y + 0.5f) / h2)
                else:
                    newColors[target_y * w2 + target_x] = ColorLerpUnclamped(ColorLerpUnclamped(texColors[y1 + xFloor], texColors[y1 + xFloor+1], xLerp),
                                                                             ColorLerpUnclamped(texColors[y2 + xFloor], texColors[y2 + xFloor+1], xLerp),
                                                                             y*ratioY-yFloor)

                x += 1

            if threadData.report:
                d = y - threadData.start
                if listener:
                    listener.Progress(d / (threadData.end - threadData.start))

            y += 1

        mutex.WaitOne()
        finishCount++
        mutex.ReleaseMutex()

    private static def ColorLerpUnclamped (c1 as Color, c2 as Color, value as single) as Color:
        return Color (c1.r + (c2.r - c1.r)*value,
                      c1.g + (c2.g - c1.g)*value,
                      c1.b + (c2.b - c1.b)*value,
                      c1.a + (c2.a - c1.a)*value)
