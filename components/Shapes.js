.pragma library
// Material 3 Expressive-style shapes, drawn from scratch: each one is a polygon or star whose corners are
// rounded with circular arcs, then walked at even steps into N points. Every shape has the same number of
// points, starting at the top and going clockwise, so any two can morph by mixing their points.
// Points are in a box from -1 to 1 (x right, y down).

var N = 120;

function star(n, inner, round, innerRound, rot) {
    // n outer points on the unit circle; inner < 1 puts n points between them at that radius (a star),
    // inner = 1 (or 0) makes a plain polygon. rot in degrees; 0 puts a point straight up.
    var v = [], r = [];
    var a0 = -Math.PI / 2 + (rot || 0) * Math.PI / 180;
    var isStar = inner > 0 && inner < 1;
    for (var i = 0; i < n; i++) {
        var a = a0 + i * 2 * Math.PI / n;
        v.push([Math.cos(a), Math.sin(a)]);
        r.push(round);
        if (isStar) {
            var b = a + Math.PI / n;
            v.push([inner * Math.cos(b), inner * Math.sin(b)]);
            r.push(innerRound === undefined ? round : innerRound);
        }
    }
    return { v: v, r: r };
}

function box(rtl, rtr, rbr, rbl) {
    // a square from -1 to 1 with its own rounding per corner (top-left first, clockwise)
    return { v: [[-1, -1], [1, -1], [1, 1], [-1, 1]], r: [rtl, rtr, rbr, rbl] };
}

function scaled(p, sx, sy) {
    return { v: p.v.map(function (q) { return [q[0] * sx, q[1] * sy]; }), r: p.r };
}

// walk a polygon with rounded corners: a list of pieces (arcs and lines) with their lengths
function pieces(p) {
    var v = p.v, n = v.length, corners = [], want = [], i;
    function angle(i) {
        var P = v[i], A = v[(i + n - 1) % n], B = v[(i + 1) % n];
        var ax = A[0] - P[0], ay = A[1] - P[1], bx = B[0] - P[0], by = B[1] - P[1];
        return Math.acos(Math.max(-1, Math.min(1, (ax * bx + ay * by) / Math.hypot(ax, ay) / Math.hypot(bx, by))));
    }
    // how far along each side every corner would like its curve to start; a side too short for both of its
    // corners is shared between them in proportion (so a sharp notch next to a round lobe gives the lobe room)
    for (i = 0; i < n; i++) want.push(p.r[i] / Math.tan(angle(i) / 2));
    function share(i, j) {
        var L = Math.hypot(v[j][0] - v[i][0], v[j][1] - v[i][1]);
        return want[i] + want[j] > L ? L * want[i] / (want[i] + want[j]) : want[i];
    }
    for (i = 0; i < n; i++) {
        var P = v[i], A = v[(i + n - 1) % n], B = v[(i + 1) % n];
        var ax = A[0] - P[0], ay = A[1] - P[1], bx = B[0] - P[0], by = B[1] - P[1];
        var la = Math.hypot(ax, ay), lb = Math.hypot(bx, by);
        ax /= la; ay /= la; bx /= lb; by /= lb;
        var th = Math.acos(Math.max(-1, Math.min(1, ax * bx + ay * by)));
        var t = Math.tan(th / 2);
        var d = Math.min(share(i, (i + n - 1) % n), share(i, (i + 1) % n));
        var rad = d * t;
        var T1 = [P[0] + ax * d, P[1] + ay * d], T2 = [P[0] + bx * d, P[1] + by * d];
        if (rad < 1e-4) { corners.push({ T1: P, T2: P, rad: 0 }); continue; }
        var mx = ax + bx, my = ay + by, ml = Math.hypot(mx, my);
        var h = rad / Math.sin(th / 2);
        var C = [P[0] + mx / ml * h, P[1] + my / ml * h];
        var a1 = Math.atan2(T1[1] - C[1], T1[0] - C[0]), a2 = Math.atan2(T2[1] - C[1], T2[0] - C[0]);
        var da = a2 - a1;
        while (da > Math.PI) da -= 2 * Math.PI;
        while (da <= -Math.PI) da += 2 * Math.PI;
        corners.push({ T1: T1, T2: T2, C: C, rad: rad, a1: a1, da: da });
    }
    var out = [];
    for (var j = 0; j < n; j++) {
        var c = corners[j], nx = corners[(j + 1) % n];
        if (c.rad > 0) out.push({ arc: true, c: c, len: Math.abs(c.da) * c.rad });
        out.push({ arc: false, a: c.T2, b: nx.T1, len: Math.hypot(nx.T1[0] - c.T2[0], nx.T1[1] - c.T2[1]) });
    }
    return out;
}

function at(pc, s) {
    if (pc.arc) {
        var a = pc.c.a1 + pc.c.da * s;
        return [pc.c.C[0] + pc.c.rad * Math.cos(a), pc.c.C[1] + pc.c.rad * Math.sin(a)];
    }
    return [pc.a[0] + (pc.b[0] - pc.a[0]) * s, pc.a[1] + (pc.b[1] - pc.a[1]) * s];
}

function sample(p, fit) {
    var ps = pieces(p), total = 0, i;
    for (i = 0; i < ps.length; i++) total += ps[i].len;
    var M = N * 4, raw = [], k = 0, acc = 0;
    for (i = 0; i < M; i++) {
        var s = total * i / M;
        while (k < ps.length - 1 && acc + ps[k].len < s) { acc += ps[k].len; k++; }
        raw.push(at(ps[k], ps[k].len > 0 ? (s - acc) / ps[k].len : 0));
    }
    // fit: centre on the box and grow until the widest side touches it (stars don't fill their circle)
    var x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
    raw.forEach(function (q) { x0 = Math.min(x0, q[0]); x1 = Math.max(x1, q[0]); y0 = Math.min(y0, q[1]); y1 = Math.max(y1, q[1]); });
    var cx = (x0 + x1) / 2, cy = (y0 + y1) / 2, sc = fit === false ? 1 : 2 / Math.max(x1 - x0, y1 - y0);
    raw = raw.map(function (q) { return [(q[0] - cx) * sc, (q[1] - cy) * sc]; });
    // start at the point straight up from the centre, then keep going clockwise
    var best = 0, bd = 1e9;
    for (i = 0; i < M; i++) {
        var ang = Math.atan2(raw[i][0], -raw[i][1]);
        if (Math.abs(ang) < bd && raw[i][1] < 0) { bd = Math.abs(ang); best = i; }
    }
    var out = [];
    for (i = 0; i < N; i++) out.push(raw[(best + i * 4) % M]);
    return out;
}

function circle() {
    var out = [];
    for (var i = 0; i < N; i++) {
        var a = -Math.PI / 2 + i * 2 * Math.PI / N;
        out.push([Math.cos(a), Math.sin(a)]);
    }
    return out;
}

var defs = {
    circle:   null,
    square:   function () { return box(0.42, 0.42, 0.42, 0.42); },
    arch:     function () { return box(1, 1, 0.32, 0.32); },
    slanted:  function () { return { v: [[-0.85, -1], [1, -1], [0.85, 1], [-1, 1]], r: [0.3, 0.3, 0.3, 0.3] }; },
    semicircle: function () { return box(1, 1, 0.18, 0.18); },
    pentagon: function () { return star(5, 1, 0.3); },
    triangle: function () { return star(3, 1, 0.32); },
    diamond:  function () { return scaled(star(4, 1, 0.28), 0.86, 1); },
    gem:      function () { return scaled(star(6, 1, 0.25, 0.25, 30), 0.9, 1); },
    cookie4:  function () { return star(4, 0.58, 9, 9, 45); },
    cookie6:  function () { return star(6, 0.7, 9, 9); },
    cookie7:  function () { return star(7, 0.74, 9, 9); },
    cookie9:  function () { return star(9, 0.79, 9, 9); },
    cookie12: function () { return star(12, 0.84, 9, 9); },
    clover4:  function () { return star(4, 0.36, 9, 0.12, 45); },
    clover8:  function () { return star(8, 0.66, 9, 0.06); },
    sunny:    function () { return star(8, 0.82, 0.14, 0.14); },
    verySunny: function () { return star(8, 0.66, 0.14, 0.14); },
    burst:    function () { return star(12, 0.74, 0.04, 0.04); },
    softBurst: function () { return star(10, 0.72, 0.14, 0.14); },
    flower:   function () { return star(8, 0.58, 9, 0.16); },
    puffy:    function () { return scaled(star(10, 0.8, 9, 9), 1, 0.84); }
};

var cache = {};

function points(name) {
    if (cache[name]) return cache[name];
    var d = defs[name];
    var pts = d ? sample(d(), name !== "square" && name !== "arch" && name !== "semicircle" && name !== "slanted") : circle();
    cache[name] = pts;
    return pts;
}

function names() {
    return Object.keys(defs);
}
