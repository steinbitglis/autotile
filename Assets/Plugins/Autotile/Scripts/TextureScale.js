// Only works on ARGB32, RGB24 and Alpha8 textures that are marked readable

#pragma strict
import System.Threading;

interface TextureScaleProgressListener {
    function Progress(s : float);
}

class TextureScale {
    class ThreadData {
        var start : int;
        var end : int;
        var report : boolean;
        function ThreadData (s : int, e : int, r : boolean) {
            start = s;
            end = e;
            report = r;
        }
    }

    private static var texColors : Color[];
    private static var newColors : Color[];
    private static var w : int;
    private static var ratioX : float;
    private static var ratioY : float;
    private static var w2 : int;
    private static var finishCount : int;
    private static var listener : TextureScaleProgressListener;

    static function Point (tex : Texture2D, newWidth : int, newHeight : int) {
        Point (tex, newWidth, newHeight, null);
    }

    static function Bilinear (tex : Texture2D, newWidth : int, newHeight : int) {
        Bilinear (tex, newWidth, newHeight, null);
    }

    static function Point (tex : Texture2D, newWidth : int, newHeight : int, l : TextureScaleProgressListener) {
        listener = l;
        ThreadedScale (tex, newWidth, newHeight, false);
    }

    static function Bilinear (tex : Texture2D, newWidth : int, newHeight : int, l : TextureScaleProgressListener) {
        listener = l;
        ThreadedScale (tex, newWidth, newHeight, true);
    }

    private static function ThreadedScale (tex : Texture2D, newWidth : int, newHeight : int, useBilinear : boolean) {
        texColors = tex.GetPixels();
        newColors = new Color[newWidth * newHeight];
        if (useBilinear) {
            ratioX = 1.0 / (parseFloat(newWidth) / (tex.width-1));
            ratioY = 1.0 / (parseFloat(newHeight) / (tex.height-1));
        }
        else {
            ratioX = parseFloat(tex.width) / newWidth;
            ratioY = parseFloat(tex.height) / newHeight;
        }
        w = tex.width;
        w2 = newWidth;
        var cores = Mathf.Min(SystemInfo.processorCount, newHeight);
        var slice = newHeight/cores;
        finishCount = 0;

        if (cores > 1) {
            for (var i = 0; i < cores-1; i++) {
                var threadData = new ThreadData(slice*i, slice*(i+1), false);
                var thread = useBilinear? new Thread(BilinearScale) : new Thread(PointScale);
                thread.Start(threadData);
            }
            threadData = new ThreadData(slice*i, newHeight, true);
            if (useBilinear) {
                BilinearScale(threadData);
            }
            else {
                PointScale(threadData);
            }
            while (finishCount < cores);
        }
        else {
            threadData = new ThreadData(0, newHeight, true);
            if (useBilinear) {
                BilinearScale(threadData);
            }
            else {
                PointScale(threadData);
            }
        }

        tex.Resize(newWidth, newHeight);
        tex.SetPixels(newColors);
        tex.Apply();
    }

    private static function BilinearScale (threadData : ThreadData) {
        for (var y = threadData.start; y < threadData.end; y++) {
            var yFloor = Mathf.Floor(y * ratioY);
            var y1 = yFloor * w;
            var y2 = (yFloor+1) * w;
            var yw = y * w2;

            for (var x = 0; x < w2; x++) {
                var xFloor = Mathf.Floor(x * ratioX);
                var xLerp = x * ratioX-xFloor;
                newColors[yw + x] = ColorLerpUnclamped(ColorLerpUnclamped(texColors[y1 + xFloor], texColors[y1 + xFloor+1], xLerp),
                                                       ColorLerpUnclamped(texColors[y2 + xFloor], texColors[y2 + xFloor+1], xLerp),
                                                       y*ratioY-yFloor);
            }

            if (threadData.report) {
                var d : float = y - threadData.start;
                listener.Progress(d / (threadData.end - threadData.start));
            }
        }

        finishCount++;
    }

    private static function PointScale (threadData : ThreadData) {
        for (var y = threadData.start; y < threadData.end; y++) {
            var thisY = parseInt(ratioY * y) * w;
            var yw = y * w2;
            for (var x = 0; x < w2; x++) {
                newColors[yw + x] = texColors[thisY + ratioX*x];
            }

            if (threadData.report) {
                var d : float = y - threadData.start;
                listener.Progress(d / (threadData.end - threadData.start));
            }
        }

        finishCount++;
    }

    private static function ColorLerpUnclamped (c1 : Color, c2 : Color, value : float) : Color {
        return new Color (c1.r + (c2.r - c1.r)*value, 
                          c1.g + (c2.g - c1.g)*value, 
                          c1.b + (c2.b - c1.b)*value, 
                          c1.a + (c2.a - c1.a)*value);
    }
}
