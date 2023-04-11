cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
};

cbuffer TimeConstantBuffer : register(b1)
{
    float iTime;
    float3 padding;
};

struct VS_Canvas
{
    float4 Position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};

VS_Canvas main(float3 vPos : POSITION)
{
    VS_Canvas Output;
    vPos.xyz *= 8.0;
    vPos.z -= 5.0;
    vPos.x += 2.0;
   
    Output.Position = float4(vPos, 1.0);
    Output.Position = mul(Output.Position, view);
    Output.Position = mul(Output.Position, projection);
    
    Output.Position.y += iTime * 0.9;
    
    float AspectRatio = projection._m11 / projection._m00;
    Output.canvasXY = sign(vPos.xy) * float2(AspectRatio, 1.7);

    return Output;
}