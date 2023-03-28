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

cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    float4 iResolution;
    float4 timer;
};
static float iTime = timer.x * 0.5;

static float4 Eye = float4(0, 0, 15, 1); //eye position 

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


float hash(float n)
{
    return fract(sin(n) * 43758.5453);
}

//Hash from iq
float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 k = fract(x);
    k = k * k * (3.0 - 2.0 * k);

    float n = p.x + p.y * 57.0 + p.z * 113.0;
    float a = hash(n);
    float b = hash(n + 1.0);
    float c = hash(n + 57.0);
    float d = hash(n + 58.0);

    float e = hash(n + 113.0);
    float f = hash(n + 114.0);
    float g = hash(n + 170.0);
    float h = hash(n + 171.0);

    float res = mix(mix(mix(a, b, k.x), mix(c, d, k.x), k.y),
        mix(mix(e, f, k.x), mix(g, h, k.x), k.y),
        k.z);
    return res;
}

vec3 caustic(vec2 uv)
{
    vec2 p = mod(uv * TAU, TAU) - 250.0;
    float time = iTime * .5 + 23.0;

    vec2 i = vec2(p);
    float c = 1.0;
    float inten = .005;

    for (int n = 0; n < MAX_ITER; n++)
    {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }

    c /= float(MAX_ITER);
    c = 1.17 - pow(c, 1.4);
    vec3 color = vec3(pow(abs(c), 8.0), pow(abs(c), 8.0), pow(abs(c), 8.0));
    color = clamp(color + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
    color = mix(color, vec3(1.0, 1.0, 1.0), 0.3);

    return color;
}


// perf increase for god ray, eliminates Y
float causticX(float x, float power, float gtime)
{
    float p = mod(x * TAU, TAU) - 250.0;
    float time = gtime * .5 + 23.0;

    float i = p;;
    float c = 1.0;
    float inten = .005;

    for (int n = 0; n < MAX_ITER / 2; n++)
    {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + cos(t - i) + sin(t + i);
        c += 1.0 / length(p / (sin(i + t) / inten));
    }
    c /= float(MAX_ITER);
    c = 1.17 - pow(c, power);

    return c;
}


float GodRays(vec2 uv)
{
    float light = 0.0;

    light += pow(causticX((uv.x + 0.08 * uv.y) / 1.7 + 0.5, 1.8, iTime * 0.65), 10.0) * 0.05;
    light -= pow((1.0 - uv.y) * 0.3, 2.0) * 0.2;
    light += pow(causticX(sin(uv.x), 0.3, iTime * 0.7), 9.0) * 0.4;
    light += pow(causticX(cos(uv.x * 2.3), 0.3, iTime * 1.3), 4.0) * 0.1;

    light -= pow((1.0 - uv.y) * 0.3, 3.0);
    light = clamp(light, 0.0, 1.0);

    return light;
}

vec3 raymarchTerrain(in vec3 ro, in vec3 rd, in float tmin, in float tmax)
{
    float t = tmin;
    vec3 res = vec3(-1.0, -1.0, -1.0);

    for (int i = 0; i < 110; i++)
    {
        vec3 p = ro + rd * t;
        float n = noise(p);
        vec2 m = vec2(0.0, p.y - n);
        res = vec3(m, t);

        float d = res.y;

        if (d < (0.001 * t) || t > tmax)
        {
            break;
        }

        t += 0.5 * d;
    }

    return res;
}


vec3 getTerrainNormal(in vec3 p)
{
    float eps = 0.025;
    return normalize(vec3(noise(vec3(vec2(p.x - eps, p.z), 1.0)) - noise(vec3(vec2(p.x + eps, p.z), 1.0)),
        2.0 * eps,
        noise(vec3(vec2(p.x, p.z - eps), 1.0)) - noise(vec3(vec2(p.x, p.z + eps), 1.0))));
}


float4 render(Ray ray, out vec4 fragColor, in vec2 fragCoord)
{
    vec3 skyColor = vec3(0.3, 1.0, 1.0);

    vec3 sunLightColor = vec3(1.7, 0.65, 0.65);
    vec3 skyLightColor = vec3(0.8, 0.35, 0.15);
    vec3 indLightColor = vec3(0.4, 0.3, 0.2);
    vec3 horizonColor = vec3(0.0, 0.05, 0.2);
    vec3 sunDirection = normalize(vec3(0.8, 0.8, 0.6));

    vec2 p = (-iResolution.xy + 2.0 * fragCoord) / iResolution.y;

    vec3 eye = vec3(0.0, 1.25, 50.5);
    /*vec2 rot = 6.2831 * (vec2(-0.05 + iTime * 0.01, 0.0 - sin(iTime * 0.5) * 0.01) + vec2(1.0, 0.0) * (iResolution.xy * 0.25) / iResolution.x);
    eye.yz = cos(rot.y) * eye.yz + sin(rot.y) * eye.zy * vec2(-1.0, 1.0);
    eye.xz = cos(rot.x) * eye.xz + sin(rot.x) * eye.zx * vec2(1.0, -1.0);*/

    vec3 ro = eye;
    vec3 ta = vec3(0.5, 0.0, 30.0);

    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(vec3(0.0, 1.0, 0.0), cw));
    vec3 cv = normalize(cross(cw, cu));
    mat3 cam = mat3(cu, cv, cw);

    vec3 rd = mul(cam, vec3(-p.xy, 1.0));

    // background
    vec3 color = skyColor;
    float sky = 0.0;

    // terrain marching
    float tmin = 0.1;
    float tmax = 20.0;
    vec3 res = raymarchTerrain(ro, rd, tmin, tmax);

    vec3 colorBubble = vec3(0.0, 0.0, 0.0);
    //float bubble = 0.0;
    //bubble += speck(vec2(sin(iTime * 0.32), cos(iTime) * 0.2 + 0.1), rd.xy, -0.08 * rd.z);
    //bubble += speck(vec2(sin(1.0 - iTime * 0.39) + 0.5, cos(1.0 - iTime * 0.69) * 0.2 + 0.15), rd.xy, 0.07 * rd.z);
    //bubble += speck(vec2(cos(1.0 - iTime * 0.5) - 0.5, sin(1.0 - iTime * 0.36) * 0.2 + 0.1), rd.xy, 0.12 * rd.z);
    //bubble += speck(vec2(sin(iTime * 0.44) - 1.0, cos(1.0 - iTime * 0.32) * 0.2 + 0.15), rd.xy, -0.09 * rd.z);
    //bubble += speck(vec2(1.0 - sin(1.0 - iTime * 0.6) - 1.3, sin(1.0 - iTime * 0.82) * 0.2 + 0.1), rd.xy, 0.15 * rd.z);

    //colorBubble = bubble * vec3(0.2, 0.7, 1.0);
    //if (rd.z < 0.1)
    //{
    //    float y = 0.00;
    //    for (float x = 0.39; x < 6.28; x += 0.39)
    //    {
    //        vec3 height = texture(iChannel0, vec2(x)).xyz;
    //        y += 0.03 * height.x;
    //        bubble = speck(vec2(sin(iTime + x) * 0.5 + 0.2, cos(iTime * height.z * 2.1 + height.x * 1.7) * 0.2 + 0.2),
    //            rd.xy, (cos(iTime + height.y * 2.3 + rd.z * -1.0) * -0.01 + 0.25));
    //        colorBubble += bubble * vec3(-0.1 * rd.z, -0.5 * rd.z, 1.0);
    //    }
    //}

    float t = res.z;

    if (t < tmax)
    {
        vec3 pos = ro + rd * t;
        vec3 nor;

        // add bumps
        nor = getTerrainNormal(pos);
        nor = normalize(nor + 0.5 * getTerrainNormal(pos * 8.0));

        float sun = clamp(dot(sunDirection, nor), 0.0, 1.0);
        sky = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
        // vec3 diffuse = mix(texture(iChannel2, vec2(pos.x * pow(pos.y, 0.01), pos.z * pow(pos.y, 0.01))).xyz, vec3(1.0, 1.0, 1.0), clamp(1.1 - pos.y, 0.0, 1.0));
        vec3 diffuse = vec3(0.5, 0.5, 0.5);

        diffuse *= caustic(vec2(mix(pos.x, pos.y, 0.2), mix(pos.z, pos.y, 0.2)) * 1.1);
        vec3 lightColor = 1.0 * sun * sunLightColor;

        lightColor += 0.7 * sky * skyLightColor;

        color *= 0.8 * diffuse * lightColor;

        // fog
        color = mix(color, horizonColor, 1.0 - exp(-0.3 * pow(t, 1.0)));
    }
    else
    {
        sky = clamp(0.8 * (1.0 - 0.8 * rd.y), 0.0, 1.0);
        color = sky * skyColor;
        color += ((0.3 * caustic(vec2(ray.d.x, ray.d.y * 1.0))) + (0.3 * caustic(vec2(ray.d.x, ray.d.y * 2.7)))) * pow(ray.d.y, 4.0);

        // horizon
        color = mix(color, horizonColor, pow(1.0 - pow(rd.y, 4.0), 20.0));
    }

    // special effects
    color += colorBubble;
    color += GodRays(ray.d) * mix(skyColor.y, 1.0, ray.d.y * ray.d.y) * vec3(0.7, 1.0, 1.0);

    // gamma correction
    vec3 gamma = vec3(0.46, 0.46, 0.46);
    fragColor = vec4(pow(color, gamma), 1.0);
    return fragColor;
}

float4 main(VS_Canvas input) : SV_Target
{

	// specify primary ray: 
    Ray eyeray;

    eyeray.o = Eye.xyz;

	// set ray direction in view space 
    float dist2Imageplane = 5.0;
    float3 viewDir = float3(input.canvasXY, -dist2Imageplane);
    viewDir = normalize(viewDir);
    eyeray.d = viewDir;

    float4 finalColor;
    finalColor = render(eyeray, finalColor, input.Position.xy);
    return finalColor;
}