cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

struct VS_Output
{
    float4 Pos : SV_POSITION;
    float4 Color : COLOR0;
};

VS_Output main(float3 vPos : POSITION, float3 vCol : COLOR)
{
    VS_Output Output;
    
    Output.Pos = float4(vPos, 1.0);
    Output.Color = float4(vCol, 1.0);
    
    return Output;
}