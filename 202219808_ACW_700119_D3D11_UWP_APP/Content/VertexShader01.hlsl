cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
	matrix model;
	matrix view;
	matrix projection;
	float4 iResolution;
	float4 timer;
};

struct VS_Canvas
{
	float4 Position   : SV_POSITION;
	float2 canvasXY  : TEXCOORD0;
};


VS_Canvas main(float4 vPos : POSITION)
{
	VS_Canvas Output;
	vPos.xyz *= 100.0; //100;
	vPos.z += 30.0;//30.0;
	//Output.Position = float4(sign(vPos.xy), 0, 1);
	

	//vPos = mul(vPos, model);
	vPos = mul(vPos, view);
	vPos = mul(vPos, projection);
	Output.Position = vPos;

	float AspectRatio = projection._m11 / projection._m00;
	Output.canvasXY = sign(vPos.xy) * float2(AspectRatio, 1.8);

	return Output;
}