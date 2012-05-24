// Only works on ARGB32, RGB24 and Alpha8 textures that are marked readable

#pragma strict
import System.Threading;

interface TextureScaleProgressListener {
    function Progress(s : float);
}

class TextureScaleTransform {
    public var flip : TextureScaleFlip;
    public var rotate : TextureScaleRotate;
    function TextureScaleTransform(f : TextureScaleFlip, r : TextureScaleRotate) {
        flip = f;
        rotate = r;
    }
}

enum TextureScaleFlip {
    None,
    Horizontal,
    Vertical,
    Both
}

enum TextureScaleRotate {
    None,
    CW,
    CCW,
    _180
}

class TextureScale {
    class ThreadData {
        var start : int;
        var end : int;
        var report : boolean;
        var flip : TextureScaleFlip;
        var rotate : TextureScaleRotate;
        function ThreadData (s : int, e : int, r : boolean, f : TextureScaleFlip, ro : TextureScaleRotate) {
            start = s;
            end = e;
            report = r;
            flip = f;
            rotate = ro;
        }
    }

    private static var texColors : Color[];
    private static var newColors : Color[];
    private static var w : int;
    private static var ratioX : float;
    private static var ratioY : float;
    private static var w2 : int;
    private static var h2 : int;
    private static var finishCount : int;
    private static var listener : TextureScaleProgressListener;

    static function Point (tex : Texture2D, newWidth : int, newHeight : int) {
        Point (tex, newWidth, newHeight, null);
    }

    static function Bilinear (tex : Texture2D, newWidth : int, newHeight : int) {
        Bilinear (tex, newWidth, newHeight, null);
    }

    static function Point (tex : Texture2D, result : Texture2D, l : TextureScaleProgressListener) {
        listener = l;
        ThreadedScale (tex, result.width, result.height, result, false);
    }

    static function Bilinear (tex : Texture2D, result : Texture2D, l : TextureScaleProgressListener) {
        listener = l;
        ThreadedScale (tex, result.width, result.height, result, true);
    }

    static function Bilinear (tex : Texture2D, result : Texture2D, l : TextureScaleProgressListener, transform : TextureScaleTransform) {
        listener = l;
        ThreadedScale (tex, result.width, result.height, result, true, transform);
    }

    static function Point (tex : Texture2D, newWidth : int, newHeight : int, l : TextureScaleProgressListener) {
        listener = l;
        ThreadedScale (tex, newWidth, newHeight, tex, false);
    }

    static function Bilinear (tex : Texture2D, newWidth : int, newHeight : int, l : TextureScaleProgressListener) {
        listener = l;
        ThreadedScale (tex, newWidth, newHeight, tex, true);
    }

    private static function ThreadedScale (tex : Texture2D, newWidth : int, newHeight : int, result : Texture2D, useBilinear : boolean) {
        TextureScale.ThreadedScale(tex, newWidth, newHeight, result, useBilinear, new TextureScaleTransform(TextureScaleFlip.None, TextureScaleRotate.None));
    }

    private static function ThreadedScale (tex : Texture2D, newWidth : int, newHeight : int, result : Texture2D, useBilinear : boolean, transform : TextureScaleTransform) {
        texColors = tex.GetPixels();
        newColors = new Color[newWidth * newHeight];
        if (useBilinear) {
            ratioX = 1.0 / (parseFloat(newWidth) / (tex.width-1));
            ratioY = 1.0 / (parseFloat(newHeight) / (tex.height-1));
        } else {
            ratioX = parseFloat(tex.width) / newWidth;
            ratioY = parseFloat(tex.height) / newHeight;
        }
        w = tex.width;
        w2 = newWidth;
        h2 = newHeight;
        var cores = Mathf.Min(SystemInfo.processorCount, newHeight);
        var slice = newHeight/cores;
        finishCount = 0;

        if (cores > 1) {
            for (var i = 0; i < cores-1; i++) {
                var threadData = new ThreadData(slice*i, slice*(i+1), false, transform.flip, transform.rotate);
                var thread = useBilinear? new Thread(BilinearScale) : new Thread(PointScale);
                thread.Start(threadData);
            }
            threadData = new ThreadData(slice*i, newHeight, true, transform.flip, transform.rotate);
            if (useBilinear) {
                BilinearScale(threadData);
            } else {
                PointScale(threadData);
            }
            while (finishCount < cores);
        } else {
            threadData = new ThreadData(0, newHeight, true, transform.flip, transform.rotate);
            if (useBilinear) {
                BilinearScale(threadData);
            } else {
                PointScale(threadData);
            }
        }

        if (tex == result) {
            result.Resize(newWidth, newHeight);
        }
        result.SetPixels(newColors);
        result.Apply();
    }

    private static function BilinearScale (threadData : ThreadData) {
        for (var y = threadData.start; y < threadData.end; y++) {
            var yFloor = Mathf.Floor(y * ratioY);
            var y1 = yFloor * w;
            var y2 = (yFloor+1) * w;

            for (var x = 0; x < w2; x++) {
                var xFloor = Mathf.Floor(x * ratioX);
                var xLerp = x * ratioX-xFloor;

                var target_x : int;
                var target_y : int;
                if (threadData.flip == TextureScaleFlip.None){
                    target_x = x;
                    target_y = y;
                } else if (threadData.flip == TextureScaleFlip.Horizontal) {
                    target_x = w2 - x - 1;
                    target_y = y;
                } else if (threadData.flip == TextureScaleFlip.Vertical) {
                    target_x = x;
                    target_y = h2 - y - 1;
                } else if (threadData.flip == TextureScaleFlip.Both) {
                    target_x = w2 - x - 1;
                    target_y = h2 - y - 1;
                }

                var buf = target_x;
                if (threadData.rotate == TextureScaleRotate.CW) {
                    target_x = h2 - target_y - 1;
                    target_y = buf;
                } else if (threadData.rotate == TextureScaleRotate.CCW) {
                    target_x = target_y;
                    target_y = w2 - buf - 1;
                } else if (threadData.rotate == TextureScaleRotate._180) {
                    target_x = w2 - target_x - 1;
                    target_y = h2 - target_y - 1;
                }

                newColors[target_y * w2 + target_x] = ColorLerpUnclamped(ColorLerpUnclamped(texColors[y1 + xFloor], texColors[y1 + xFloor+1], xLerp),
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
