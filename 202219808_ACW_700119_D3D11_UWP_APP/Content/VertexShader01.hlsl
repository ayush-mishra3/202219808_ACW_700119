cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
	matrix model;
	matrix view;
	matrix projection;
};

struct VS_Canvas
{
	float4 Position   : SV_POSITION;
	float2 canvasXY  : TEXCOORD0;
};

VS_Canvas main(float3 vPos : POSITION)
{
	VS_Canvas Output;
	vPos.xyz *= 50.0; 
	vPos.z += 15.0;
    
    //Output.Position = mul(float4(vPos, 1.0), model);
    Output.Position = mul(float4(vPos, 1.0), view);
    Output.Position = mul(Output.Position, projection);

	float AspectRatio = projection._m11 / projection._m00;
	Output.canvasXY = sign(vPos.xy) * float2(AspectRatio, 1.0);

	return Output;
}