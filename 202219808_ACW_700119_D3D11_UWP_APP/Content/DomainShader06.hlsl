cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    float4 iResolution;
    float4 timer;
};

struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
};

static float3 QuadPos[4] =
{
    float3(-1, 1, 0),
    float3(-1, -1, 0),
    float3(1, 1, 0),
    float3(1, -1, 0)
};

struct HS_Tri_Tess_Factors
{
    float Edges[3] : SV_TessFactor;
    float Inside : SV_InsideTessFactor;
};

static const int SPHERE_TESS_LEVEL = 16;

static float3 SpherePos[SPHERE_TESS_LEVEL * SPHERE_TESS_LEVEL];

void GenerateSphereVertices()
{
    const float PI = 3.14159265358979323846f;

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
    }
}



[domain("tri")]
VS_OUTPUT main(HS_Tri_Tess_Factors input,
float3 UVW : SV_DomainLocation)
{
    VS_OUTPUT Output;
    GenerateSphereVertices();
    float3 finalPos = UVW.x * SpherePos[(int) (UVW.y * (SPHERE_TESS_LEVEL - 1)) * SPHERE_TESS_LEVEL + (int) (UVW.x * (SPHERE_TESS_LEVEL - 1))] +
        UVW.y * SpherePos[(int) (UVW.z * (SPHERE_TESS_LEVEL - 1)) * SPHERE_TESS_LEVEL + (int) (UVW.y * (SPHERE_TESS_LEVEL - 1))] +
        UVW.z * SpherePos[(int) (UVW.z * (SPHERE_TESS_LEVEL - 1)) * SPHERE_TESS_LEVEL + (int) (UVW.x * (SPHERE_TESS_LEVEL - 1))];

    finalPos.z -= 3.0;
    
    Output.pos = float4(6.5f * finalPos, 1.0f);
    //Output.pos = mul(Output.pos, model);
    Output.pos = mul(Output.pos, view);
    Output.pos = mul(Output.pos, projection);

    return Output;
}