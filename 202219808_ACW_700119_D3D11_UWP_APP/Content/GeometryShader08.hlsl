cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

cbuffer TimeConstantBuffer : register(b1)
{
    float iTime;
    float3 pad;
};

struct GS_Input
{
    float4 pos : SV_POSITION;
    float4 col : COLOR0;
};

struct GS_Output
{
    float4 pos : SV_POSITION;
    float4 col : COLOR0;
    float2 uv : TEXCOORD0;
    
};

float4 fishMovement(float4 vPos)
{
    vPos.z -= 5.0;
    float angle = iTime * 0.05;
    
    // Define the rotation matrix to rotate around the y-axis
    float4x4 rotation =
    {
        cos(angle), 0, sin(angle), 0,
        0, 1, 0, 0,
        -sin(angle), 0, cos(angle), 0,
        0, 0, 0, 1
    };
    
    // Apply the rotation to the vertex position
    return mul(rotation, vPos);
}

[maxvertexcount(3)]
void main(
	point GS_Input input[1] : SV_POSITION,
	inout TriangleStream<GS_Output> output
)
{
    static const float3 g_pos[3] =
    {
        float3(-1, 1, 0),
        float3(-1, -1, 0),
        float3(1,0, 0),
    };
    
    GS_Output element;
    float4 inPos = input[0].pos;
    float quadSize = 0.05;
    
    //vertex 1:
    element.pos = inPos + float4(quadSize * g_pos[2], 0.0);
    element.pos = fishMovement(element.pos);
    element.pos = mul(element.pos, view);
    element.pos = mul(element.pos, projection);
    element.col = input[0].col;
    element.uv = (sign(input[0].pos.xy) + 1.0) / 2.0;
    
    output.Append(element);
    
    //vertex 2:
    element.pos = inPos + float4(quadSize * g_pos[0], 0.0);
    element.pos = fishMovement(element.pos);
    element.pos = mul(element.pos, view);
    element.pos = mul(element.pos, projection);
    element.col = input[0].col;
    element.uv = (sign(input[0].pos.xy) + 1.0) / 2.0;
    
    output.Append(element);
    
    //vertex 3:
    element.pos = inPos + float4(quadSize * g_pos[1], 0.0);
    element.pos = fishMovement(element.pos);
    element.pos = mul(element.pos, view);
    element.pos = mul(element.pos, projection);
    element.col = input[0].col;
    element.uv = (sign(input[0].pos.xy) + 1.0) / 2.0;
    
    output.Append(element);
    
    output.RestartStrip();
  
}
