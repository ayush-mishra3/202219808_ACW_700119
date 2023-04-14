// License Creative Commons Attribution - NonCommercial-ShareAlike 3.0 Unported License.
// partially derived from the following
// https://www.shadertoy.com/view/4ljXWh

#define TAU 6.28318530718
#define MAX_ITER 5

#define vec2 float2 
#define vec3 float3 
#define vec4 float4 
#define mat2 float2x2 
#define mat3 float3x3 

#define fract frac
#define mix lerp
#define mod fmod

static float4 Eye = float4(0, 1.0, 5.0, 1);
static const float precis = 0.0005;

cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

cbuffer TimeConstantBuffer : register(b1)
{
    float iTime;
    float3 padding2;
};

struct Ray
{
    float3 o; // origin 
    float3 d; // direction 
};

struct VS_Canvas
{
    float4 Position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};


static const int MAX_MARCHING_STEPS = 255;
static const float MIN_DIST = 0.0;
static const float MAX_DIST = 100.0;
static const float EPSILON = 0.0001;


// 0 = lattice
// 1 = simplex
#define NOISE 0


// please, do not use in real projects - replace this by something better
float hash(vec3 p)
{
    p = 17.0 * fract(p * 0.3183099 + vec3(.11, .17, .13));
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// https://iquilezles.org/articles/boxfunctions
vec2 iBox(in vec3 ro, in vec3 rd, in vec3 rad)
{
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if (tN > tF || tF < 0.0) return vec2(-1.0, -1.0);
    return vec2(tN, tF);
}

// https://iquilezles.org/articles/distfunctions
float sdBox(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// https://iquilezles.org/articles/smin
float smax(float a, float b, float k)
{
    float h = max(k - abs(a - b), 0.0);
    return max(a, b) + h * h * 0.25 / k;
}

//---------------------------------------------------------------
// A random SDF - it places spheres of random sizes in a grid
//---------------------------------------------------------------

float sdBase(in vec3 p)
{
#if NOISE==0
    vec3 i = floor(p);
    vec3 f = fract(p);

#define RAD(r) ((r)*(r)*0.7)
#define SPH(i,f,c) length(f-c)-RAD(hash(i+c))

    return min(min(min(SPH(i, f, vec3(0, 0, 0)),
        SPH(i, f, vec3(0, 0, 1))),
        min(SPH(i, f, vec3(0, 1, 0)),
            SPH(i, f, vec3(0, 1, 1)))),
        min(min(SPH(i, f, vec3(1, 0, 0)),
            SPH(i, f, vec3(1, 0, 1))),
            min(SPH(i, f, vec3(1, 1, 0)),
                SPH(i, f, vec3(1, 1, 1)))));
#else
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;

    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);

    vec3 e = step(d0.yzx, d0);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);

    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);

    float r0 = hash(i + 0.0);
    float r1 = hash(i + i1);
    float r2 = hash(i + i2);
    float r3 = hash(i + 1.0);

#define SPH(d,r) length(d)-r*r*0.55

    return min(min(SPH(d0, r0),
        SPH(d1, r1)),
        min(SPH(d2, r2),
            SPH(d3, r3)));
#endif
}

//---------------------------------------------------------------
// subtractive fbm
//---------------------------------------------------------------
vec2 sdFbm(in vec3 p, float d)
{
    const mat3 m = mat3(0.00, 0.80, 0.60,
        -0.80, 0.36, -0.48,
        -0.60, -0.48, 0.64);
    float t = 0.0;
    float s = 1.0;
    for (int i = 0; i < 7; i++)
    {
        float n = s * sdBase(p);
        d = smax(d, -n, 0.15 * s);
        t += d;
        p = mul(2.0, mul(m,p));
        s = 0.55 * s;
    }

    return vec2(d, t);
}
/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float2 map(vec3 p)
{
    // box
    float d = sdBox(p, vec3(1.0, 1.0, 1.0));

    // fbm
    vec2 dt = sdFbm(p + 0.5, d);

    dt.y = 1.0 + dt.y * 2.0; dt.y = dt.y * dt.y;

    return dt;
}

vec3 caustic(vec2 uv)
{
    vec2 p = mod(uv * TAU, TAU) - 250.0;
    float time = iTime * .5 + 23.0;

    vec2 i = vec2(p);
    float c = 1.0;
    float inten = .005;

    for (int n = 0; n < MAX_ITER / 3; n++)
    {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }

    c /= float(MAX_ITER / 3);
    c = 1.17 - pow(c, 1.4);
    vec3 color = vec3(pow(abs(c), 8.0), pow(abs(c), 8.0), pow(abs(c), 8.0));
    color = clamp(color + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
    color = mix(color, vec3(1.0, 1.0, 1.0), 0.3);

    return color;
}

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the ey to march before giving up
 */
float2 rayCast(vec3 ro, vec3 rd)
{
    vec2 res = vec2(-1.0, -1.0);

    // bounding volume    
    vec2 dis = iBox(ro, rd, vec3(1.0, 1.0, 1.0));
    if (dis.y < 0.0) return res;

    // raymarch
    float t = dis.x;
    for (int i = 0; i < 256; i++)
    {
        vec3 p = ro + t * rd;
        vec2 h = map(p);
        res.x = t;
        res.y = h.y;

        if (h.x<precis || t>dis.y) break;
        t += h.x;
    }

    if (t > dis.y) res = vec2(-1.0, -1.0);
    return res;
}
            
/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * precis;
    return normalize(e.xyy * map(pos + e.xyy).x +
        e.yyx * map(pos + e.yyx).x +
        e.yxy * map(pos + e.yxy).x +
        e.xxx * map(pos + e.xxx).x);
}

// https://iquilezles.org/articles/rmshadows
float calcSoftShadow(vec3 ro, vec3 rd, float tmin, float tmax, float w)
{
    // bounding volume    
    vec2 dis = iBox(ro, rd, vec3(1.0, 1.0, 1.0));
    if (dis.y < 0.0) return 1.0;

    tmin = max(tmin, dis.x);
    tmax = min(tmax, dis.y);

    float t = tmin;
    float res = 1.0;
    for (int i = 0; i < 128; i++)
    {
        float h = map(ro + t * rd).x;
        res = min(res, h / (w * t));
        t += clamp(h, 0.005, 0.50);
        if (res<-1.0 || t>tmax) break;
    }
    res = max(res, -1.0); // clamp to [-1,1]

    return 0.25 * (1.0 + res) * (1.0 + res) * (2.0 - res); // smoothstep
}

void render(Ray ray, out vec4 fragColor, in vec2 fragCoord, in vec2 uv)
{

    vec3 col = vec3(0.01, 0.01, 0.01);
    float2 dist = rayCast(ray.o, ray.d);
    
    if (dist.x < 0.0)
    {
        // Didn't hit anything
        discard;
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = ray.o + dist.x * ray.d;

    vec3  nor = calcNormal(p);
    float occ = dist.y * dist.y;

    // material
    vec3 mate = mix(vec3(0.6, 0.3, 1.1), vec3(1.0, 1.0, 1.0), dist.y) * 0.7;

    // key light
    {
        const vec3 lig = normalize(vec3(0.8, 0.8, 0.6));
        float dif = dot(lig, nor);
        if (dif > 0.0) dif *= calcSoftShadow(p + nor * 0.001, lig, 0.001, 10.0, 0.003);
        dif = clamp(dif, 0.0, 1.0);
        vec3 hal = normalize(lig - ray.d);
        float spe = clamp(dot(hal, nor), 0.0, 1.0);
        spe = pow(spe, 4.0) * dif * (0.04 + 0.96 * pow(max(1.0 - dot(hal, lig), 0.0), 5.0));

        col = vec3(0.0, 0.0, 0.0);
        col += mate * 1.5 * vec3(1.30, 4.85, 0.75) * dif;
        col += 9.0 * spe;
    }
    // ambient light
    {
        col += mate * 0.2 * vec3(0.40, 1.45, 0.60) * occ * (0.6 + 0.3 * nor.y);
    }
    // tonemap
    col = col * 1.7 / (1.0 + col);

    // gamma
    col = pow(col, vec3(0.4545, 0.4545, 0.4545));

    //caustic
  //  col += ((0.3 * caustic(vec2(uv.x, uv.y * 1.0))) + (0.3 * caustic(vec2(uv.x, uv.y * 2.7)))) * pow(uv.y, 4.0);

    fragColor = vec4(col, 1.0);
}

float4 main(VS_Canvas input) : SV_Target
{
	// specify primary ray: 
    Ray eyeray;

    eyeray.o = Eye.xyz;

	// set ray direction in view space 
    float dist2Imageplane = 1.0;
    float3 viewDir = float3(input.canvasXY, -dist2Imageplane);
    viewDir = normalize(viewDir);
    eyeray.d = viewDir;

    // Transform viewDir using the inverse view matrix
    float4x4 viewTrans = transpose(view);
    eyeray.d = viewDir.x * viewTrans._11_12_13 + viewDir.y * viewTrans._21_22_23
        + viewDir.z * viewTrans._31_32_33;

    float4 finalColor;
    render(eyeray, finalColor, input.Position.xy, input.canvasXY);
    return finalColor;
}