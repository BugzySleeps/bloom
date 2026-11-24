import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.services
import qs.components

// Bloom's own wallpaper, drawn by the shell so it takes the theme's colour (light or dark): a dusk gradient,
// a warm glow low on the right, big soft shapes, smaller crisp ones and a few squiggles. Laid out on a
// 1920x1080 canvas and scaled to cover whatever it's put in. Nothing moves, so it costs nothing after drawing.
Item {
    id: root
    clip: true

    readonly property real h: Theme.h
    readonly property real s: Theme.s
    readonly property bool dark: Theme.dark
    function t(sat, l, a) { return Theme.tone(h, s * sat, l, a); }

    readonly property color skyTop: dark ? t(0.9, 0.1) : t(0.9, 0.9)
    readonly property color skyLow: dark ? t(1.3, 0.28) : t(1.2, 0.76)
    readonly property color glow: dark ? t(1.8, 0.56, 0.75) : t(1.6, 0.96, 0.85)
    readonly property color far: dark ? t(1.5, 0.62, 0.14) : t(1.4, 0.5, 0.12)
    readonly property color near: dark ? t(1.6, 0.72, 0.27) : t(1.5, 0.45, 0.17)
    readonly property color line: dark ? t(1.6, 0.76, 0.3) : t(1.5, 0.42, 0.24)

    Item {
        id: canvas
        width: 1920
        height: 1080
        anchors.centerIn: parent
        scale: Math.max(root.width / 1920, root.height / 1080)

        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 700; y2: 1080
                    GradientStop { position: 0; color: root.skyTop }
                    GradientStop { position: 1; color: root.skyLow }
                }
                PathRectangle { width: 1920; height: 1080 }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 1500; centerY: 1000; centerRadius: 1100
                    focalX: 1500; focalY: 1000
                    GradientStop { position: 0; color: root.glow }
                    GradientStop { position: 1; color: Theme.alpha(root.glow, 0) }
                }
                PathRectangle { width: 1920; height: 1080 }
            }
        }

        component Blob: MShape {
            property real cx
            property real cy
            property real r
            x: cx - r; y: cy - r
            width: r * 2; height: r * 2
            duration: Theme.slow * 2
        }

        // far away: big, faint, soft
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.35; blurMax: 24 }
            Blob { cx: 1660; cy: 170; r: 330; shape: "cookie12"; spin: 8; color: root.far }
            Blob { cx: 180; cy: 900; r: 380; shape: "clover4"; spin: 20; color: root.far }
            Blob { cx: 980; cy: 1150; r: 300; shape: "sunny"; color: root.far }
            Blob { cx: -40; cy: 120; r: 260; shape: "flower"; spin: 12; color: root.far }
        }

        // nearer: smaller, crisp
        Blob { cx: 1500; cy: 760; r: 120; shape: "cookie9"; color: root.near }
        Blob { cx: 420; cy: 250; r: 70; shape: "pentagon"; spin: -8; color: root.near }
        Blob { cx: 820; cy: 360; r: 46; shape: "softBurst"; color: root.near }
        Blob { cx: 1240; cy: 330; r: 58; shape: "clover8"; spin: 10; color: root.near }
        Blob { cx: 640; cy: 820; r: 52; shape: "gem"; spin: 14; color: root.near }
        Blob { cx: 1780; cy: 560; r: 40; shape: "cookie6"; color: root.near }
        Blob { cx: 1080; cy: 720; r: 34; shape: "triangle"; spin: 18; color: root.near }

        component Squiggle: Shape {
            id: sq
            property real len
            property real amp
            property real wave
            property real thick
            preferredRendererType: Shape.CurveRenderer
            transformOrigin: Item.TopLeft
            ShapePath {
                strokeColor: root.line
                strokeWidth: sq.thick
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    path: {
                        const out = [];
                        for (let x = 0; x <= sq.len; x += 3) out.push(Qt.point(x, Math.sin(x / sq.wave * Math.PI * 2) * sq.amp));
                        return out;
                    }
                }
            }
        }
        Squiggle { x: 90; y: 470; rotation: -12; len: 380; amp: 12; wave: 70; thick: 6 }
        Squiggle { x: 1300; y: 980; rotation: -6; len: 420; amp: 10; wave: 60; thick: 5 }
        Squiggle { x: 980; y: 120; rotation: 8; len: 300; amp: 9; wave: 54; thick: 4 }
    }
}
