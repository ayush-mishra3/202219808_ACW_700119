cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
	matrix model;
	matrix view;
	matrix projection;
	float4 iResolution;
	float4 iTime;
};

struct VS_OUTPUT
{
	float4 pos : SV_POSITION;
	float3 color : COLOR0;
};


float hash(float n)
{
    return frac(sin(n) * 43758.5453);
}

//Hash from iq
float noise(in float3 x)
{
    float3 p = floor(x);
    float3 k = frac(x);
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

    float res = lerp(lerp(lerp(a, b, k.x), lerp(c, d, k.x), k.y),
        lerp(lerp(e, f, k.x), lerp(g, h, k.x), k.y),
        k.z);
    return res;
}

float3 ComputeGradient(float3 position)
{
    float noiseValue = noise(position);
    float3 gradient;

    // Compute the gradient along the x-axis
    gradient.x = (noise(position + float3(0.01, 0, 0)) - noise(position - float3(0.01, 0, 0))) / 0.02;

    // Compute the gradient along the y-axis
    gradient.y = (noise(position + float3(0, 0.01, 0)) - noise(position - float3(0, 0.01, 0))) / 0.02;

    // Compute the gradient along the z-axis
    gradient.z = (noise(position + float3(0, 0, 0.01)) - noise(position - float3(0, 0, 0.01))) / 0.02;

    // Compute a complementary color to blue (opposite color on the color wheel)
    float3 cyan = float3(0, 1, 1);

    // Interpolate between a dark and a light cyan color using the noise value
    gradient *= lerp(cyan * 0.5, cyan, noiseValue);

    return gradient * 0.8;
}

VS_OUTPUT main(float3 vPos : POSITION, float3 vCol : COLOR)
{
	VS_OUTPUT output;

	float4 inPos = float4(vPos, 1.0);
    
	// Transformations
    float r = 4.0;
    inPos.x = r * sin(inPos.y) * cos(inPos.x);
    inPos.y = r * sin(inPos.y) * sin(inPos.x);
    inPos.z = r * cos(inPos.y) * -0.3; // sin(iTime.x * 0.5);

    inPos = mul(inPos, view);
    inPos = mul(inPos, projection);
    inPos.x -= 10;
    inPos.y -= 5;
    
    output.pos = inPos;
    output.color = ComputeGradient(inPos.xyz) + float3(1.0, 1.0, 1.0) * 0.2;

	return output;
}