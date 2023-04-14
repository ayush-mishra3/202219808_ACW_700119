cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float3 nor : NORMAL;
    float2 tex : TEXCOORD0;
};

struct HS_Tri_Tess_Factors
{
    float Edges[3] : SV_TessFactor;
    float Inside : SV_InsideTessFactor;
};

static float3 QuadPos[4] =
{
    float3(-1, 1, 0),
    float3(-1, -1, 0),
    float3(1, 1, 0),
    float3(1, -1, 0)
};

float3 rotate(float angle, float3 axis)
{
    float c = cos(angle);
    float s = sin(angle);
    float3 temp = (1.0f - c) * axis;

    float3 r0 = float3(c + temp.x * axis.x, temp.x * axis.y + s * axis.z, temp.x * axis.z - s * axis.y);
    float3 r1 = float3(temp.y * axis.x - s * axis.z, c + temp.y * axis.y, temp.y * axis.z + s * axis.x);
    float3 r2 = float3(temp.z * axis.x + s * axis.y, temp.z * axis.y - s * axis.x, c + temp.z * axis.z);

    return float3(dot(r0, axis), dot(r1, axis), dot(r2, axis));
}
float3 CoralFunction(float3 p)
{
    float3 result = p;
    
    // Add noise to create irregularities
    result += 0.2 * sin(3.0 * p);
    
    // Add branches
    float3 branchDir = normalize(p);
    float branchAngle = 0.5;
    float branchLength = 0.2;
    float branchFreq = 10.0;
    float branchAmp = 0.05;
    float branchNoise = 0.2;
    
    float t = branchFreq * dot(p, float3(1, 2, 3));
    float3 branchOffset = branchAmp * branchLength * (1.0 - branchNoise * sin(t));
    float3 branchPos = p + branchOffset;
    float3 branch1 = p + branchLength * branchDir + branchOffset;
    float3 branch2 = p + branchLength * rotate(branchAngle, branchDir) + branchOffset;
    float3 branch3 = p + branchLength * rotate(-branchAngle, branchDir) + branchOffset;
    
    result += 0.2 * (sin(10.0 * branch1) + sin(10.0 * branch2) + sin(10.0 * branch3));
    
    return result;
}


[domain("tri")]
VS_OUTPUT main(HS_Tri_Tess_Factors input,
float3 UVW : SV_DomainLocation)
{
    VS_OUTPUT Output;
    
    float3 finalPos = UVW.x * QuadPos[0].xyz
+ UVW.y * QuadPos[2].xyz
+ UVW.z * QuadPos[1].xyz;

    // Transform the uvPos into a coral object
    float3 coralPos = CoralFunction(finalPos);
    
    float angleInRadians = -0.8;

    float cosTheta = cos(angleInRadians);
    float sinTheta = sin(angleInRadians);

    float4x4 rotationMatrix =
    {
        cosTheta, sinTheta, 0.0f, 0.0f,
   -sinTheta, cosTheta, 0.0f, 0.0f,
    0.0f, 0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f
    };

    float4 position = float4(coralPos, 1.0);
    position = mul(position, rotationMatrix);
    
    position.x += 3.8;
    position.y -= 0.5;
    
    Output.pos = float4(0.2 * position.xyz, 1.0);
    Output.tex = UVW.xy;

   return Output;

}