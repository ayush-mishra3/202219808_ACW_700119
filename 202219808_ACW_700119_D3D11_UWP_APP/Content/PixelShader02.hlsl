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

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float sphereSDF(vec3 samplePoint)
{
    return length(samplePoint) - 1.0;
}
float bubbleSDF(vec3 samplePoint, vec3 position, float radius)
{
    return length(samplePoint - position) - radius;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 samplePoint)
{
    //// Calculate position of the bubble in world space based on time
    //vec3 bubblePosition = vec3(sin(iTime) * 5.5, iTime * 0.1, 0.0);

    //// Calculate distance of samplePoint from the current bubble position
    //float distance = length(samplePoint - bubblePosition);

    //// Calculate the size of the bubble based on its distance from the top
    //float bubbleRadius = mix(2.0, 0.5, bubblePosition.y / 2.0);

    //// Return the signed distance to the surface of the bubble
    //return distance - bubbleRadius;
    
    
    // Calculate position and size of the first bubble in world space based on time
    vec3 bubble1Position = vec3(sin(iTime) * 5.5, iTime * 0.1, 0.0);
    float bubble1Radius = mix(2.0, 0.5, bubble1Position.y / 2.0);

    // Calculate position and size of the second bubble in world space based on time
    vec3 bubble2Position = vec3(cos(iTime) * 5.0, iTime * 0.07, -2.0);
    float bubble2Radius = mix(1.0, 0.3, bubble2Position.y / 2.0);

    // Calculate position and size of the third bubble in world space based on time
    vec3 bubble3Position = vec3(0.0, iTime * 0.01, 3.0);
    float bubble3Radius = mix(1.4, 0.2, bubble3Position.y / 2.0);

    // Combine the signed distance functions of the bubbles using opUnion
    float bubbleSDF1 = bubbleSDF(samplePoint, bubble1Position, bubble1Radius);
    float bubbleSDF2 = bubbleSDF(samplePoint, bubble2Position, bubble2Radius);
    float bubbleSDF3 = bubbleSDF(samplePoint, bubble3Position, bubble3Radius);
    return min(bubbleSDF1, min(bubbleSDF2, bubbleSDF3));
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
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end)
{
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON)
        {
            return depth;
        }
        depth += dist;
        if (depth >= end)
        {
            return end;
        }
    }
    return end;
}
            
/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p)
{
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

/**
 * Lighting contribution of a single point light source via Phong illumination.
 * 
 * The vec3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity)
{
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0)
    {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    }
    
    if (dotRV < 0.0)
    {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

/**
 * Lighting via Phong illumination.
 * 
 * The vec3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye)
{
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(4.0 * sin(iTime),
                          2.0,
                          4.0 * cos(iTime));
    vec3 light1Intensity = vec3(0.4, 0.4, 0.4);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    return color;
}


void render(Ray ray, out vec4 fragColor, in vec2 fragCoord, in vec2 uv)
{
	vec3 dir = ray.d;
    vec3 eye = ray.o;
    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON)
    {
        // Didn't hit anything
        discard;
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    vec3 p = eye + dist * dir;
    
    vec3 K_a = vec3(0.2, 0.2, 0.2);
    vec3 K_d = vec3(0.2, 0.2, 0.3);
    vec3 K_s = vec3(1.0, 1.0, 1.0);
    float shininess = 100.0;
    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    fragColor = vec4(color, 1.0);
    
     // Add transparency
    float alpha = 0.1; // Set the transparency level
    // Set the alpha channel and fade out the sphere near the edges
    fragColor = vec4(color, alpha * (1.0 - smoothstep(0.0, 0.1, dist))); 
}

float4 main(VS_Canvas input) : SV_Target
{
	// specify primary ray: 
    Ray eyeray;

    eyeray.o = Eye.xyz;

	// set ray direction in view space 
    float dist2Imageplane = 0.2;
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