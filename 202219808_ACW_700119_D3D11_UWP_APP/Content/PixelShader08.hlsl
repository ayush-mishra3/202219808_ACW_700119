
struct PS_Input
{
    float4 Position : SV_POSITION;
    float4 Color : COLOR0;
    float2 UV : TEXCOORD0;
};


float4 main(PS_Input Input) : SV_TARGET
{
    return float4 (Input.UV, 1.0, 1.0);
}