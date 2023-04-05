cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
};

struct HS_Tri_Tess_Factors
{
    float Edges[3] : SV_TessFactor;
    float Inside : SV_InsideTessFactor;
};

static const float PI = 3.14159265358979323846f;
static const int SPHERE_TESS_LEVEL = 50;

static float3 QuadPos[4] =
{
    float3(-1, 1, 0),
    float3(-1, -1, 0),
    float3(1, 1, 0),
    float3(1, -1, 0)
};

[domain("tri")]
VS_OUTPUT main(HS_Tri_Tess_Factors input,
float3 UVW : SV_DomainLocation)
{
    VS_OUTPUT Output;
    
    static float3 SpherePos[SPHERE_TESS_LEVEL * SPHERE_TESS_LEVEL];
    
    int index = 0;
    for (int i = 0; i < SPHERE_TESS_LEVEL; i++)
    {
        float phi = i * PI / (SPHERE_TESS_LEVEL - 1);
        for (int j = 0; j < SPHERE_TESS_LEVEL; j++)
        {
            float theta = j * 2 * PI / (SPHERE_TESS_LEVEL - 1);
            float x = sin(phi) * cos(theta);
            float y = sin(phi) * sin(theta);
            float z = cos(phi);
            SpherePos[index++] = float3(x, y, z);
        }
    };
    
    float3 finalPos = UVW.x * SpherePos[(int) (UVW.y * (SPHERE_TESS_LEVEL - 1)) * SPHERE_TESS_LEVEL + (int) (UVW.x * (SPHERE_TESS_LEVEL - 1))] +
        UVW.y * SpherePos[(int) (UVW.z * (SPHERE_TESS_LEVEL - 1)) * SPHERE_TESS_LEVEL + (int) (UVW.y * (SPHERE_TESS_LEVEL - 1))] +
        UVW.z * SpherePos[(int) (UVW.z * (SPHERE_TESS_LEVEL - 1)) * SPHERE_TESS_LEVEL + (int) (UVW.x * (SPHERE_TESS_LEVEL - 1))];

    Output.pos = float4(0.6 * finalPos, 1.0);

    return Output;

}