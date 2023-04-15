cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

struct VS_Output
{
    float4 Position : SV_POSITION;
    float4 Color : COLOR0;
};

VS_Output main(float3 vPos : POSITION, float3 vCol : COLOR)
{
    VS_Output Output;
    
    vPos.xyz *= 1.2;
    vPos.x += 5.2;
    vPos.y -= 2.8;
    vPos.z -= 5.0; //10.0;   // Original Position

    //Output.Position = float4(vPos, 1.0);
    //Output.Position = mul(float4(vPos, 1.0), model);
    //Output.Position = mul(float4(vPos, 1.0), view);
    Output.Position = mul(float4(vPos, 1.0), projection);
    
    Output.Color = float4(vCol, 0.1) * 0.5;
    
    return Output;
}