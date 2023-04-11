struct GeometryShaderInput
{
    float4 pos : SV_POSITION;
    float3 col : COLOR0;
};
 
struct PixelShaderInput
{
    float4 pos : SV_POSITION;
    float3 col : COLOR0;
    float2 uv : TEXCOORD0;
};
 

[maxvertexcount(36)]
void main(triangle GeometryShaderInput input[3], inout
TriangleStream<PixelShaderInput> OutputStream)
{
    PixelShaderInput v0 = (PixelShaderInput) 0;
    PixelShaderInput v1 = (PixelShaderInput) 0;
    PixelShaderInput v2 = (PixelShaderInput) 0;
    PixelShaderInput v3 = (PixelShaderInput) 0;
    PixelShaderInput v4 = (PixelShaderInput) 0;
    PixelShaderInput v5 = (PixelShaderInput) 0;
    PixelShaderInput v6 = (PixelShaderInput) 0;
    PixelShaderInput v7 = (PixelShaderInput) 0;
    PixelShaderInput v8 = (PixelShaderInput) 0;
    PixelShaderInput v9 = (PixelShaderInput) 0;
    PixelShaderInput v10 = (PixelShaderInput) 0;
    PixelShaderInput v11 = (PixelShaderInput) 0;
    
    v0.pos = input[0].pos;
    v1.pos = input[1].pos;
    v2.pos = input[2].pos;

    v0.col = input[0].col;
    v1.col = input[1].col;
    v2.col = input[2].col;
    
    float4 mid01 = (v0.pos + v1.pos) * 0.5f;
    float4 mid12 = (v1.pos + v2.pos) * 0.5f;
    float4 mid20 = (v2.pos + v0.pos) * 0.5f;

    float spikeFactor = 0.9;

    float4 spikeDir1 = float4(-1.0f, 0.0f, 0.0f, 0.0f);
    float4 spikeDir2 = float4(0.0f, 1.0f, 0.0f, 0.0f);
    float4 spikeDir3 = float4(0.0f, 0.0f, 1.0f, 0.0f);

    float spikeLen1 = 1.0f;
    float spikeLen2 = 2.0f;
    float spikeLen3 = 2.0f;

    v3.pos = mid01 + spikeDir1 * spikeLen1 * spikeFactor;
    v4.pos = mid01 + spikeDir1 * spikeLen2 * spikeFactor;
    v5.pos = mid01 + spikeDir1 * spikeLen3 * spikeFactor;

    v6.pos = mid12 + spikeDir2 * spikeLen1 * spikeFactor;
    v7.pos = mid12 + spikeDir2 * spikeLen2 * spikeFactor;
    v8.pos = mid12 + spikeDir2 * spikeLen3 * spikeFactor;

    v9.pos = mid20 + spikeDir3 * spikeLen1 * spikeFactor;
    v10.pos = mid20 + spikeDir3 * spikeLen2 * spikeFactor;
    v11.pos = mid20 + spikeDir3 * spikeLen3 * spikeFactor;

    v3.col = input[0].col;
    v4.col = input[1].col;
    v5.col = input[2].col;
    v6.col = input[0].col;
    v7.col = input[1].col;
    v8.col = input[2].col;
    v9.col = input[0].col;
    v10.col = input[1].col;
    v11.col = input[2].col;
    
    // Front face
    OutputStream.Append(v0);
    OutputStream.Append(v3);
    OutputStream.Append(v5);
    OutputStream.RestartStrip();

    OutputStream.Append(v3);
    OutputStream.Append(v1);
    OutputStream.Append(v4);
    OutputStream.RestartStrip();

    OutputStream.Append(v5);
    OutputStream.Append(v4);
    OutputStream.Append(v3);
    OutputStream.RestartStrip();

    OutputStream.Append(v1);
    OutputStream.Append(v2);
    OutputStream.Append(v4);
    OutputStream.RestartStrip();

    OutputStream.Append(v5);
    OutputStream.Append(v2);
    OutputStream.Append(v4);
    OutputStream.RestartStrip();

    // Back face
    OutputStream.Append(v2);
    OutputStream.Append(v0);
    OutputStream.Append(v6);
    OutputStream.RestartStrip();

    OutputStream.Append(v6);
    OutputStream.Append(v0);
    OutputStream.Append(v8);
    OutputStream.RestartStrip();

    OutputStream.Append(v8);
    OutputStream.Append(v0);
    OutputStream.Append(v9);
    OutputStream.RestartStrip();

    OutputStream.Append(v9);
    OutputStream.Append(v0);
    OutputStream.Append(v11);
    OutputStream.RestartStrip();

    OutputStream.Append(v11);
    OutputStream.Append(v0);
    OutputStream.Append(v10);
    
    OutputStream.RestartStrip();

    OutputStream.Append(v10);
    OutputStream.Append(v0);
    OutputStream.Append(v7);
    OutputStream.RestartStrip();

    OutputStream.Append(v7);
    OutputStream.Append(v0);
    OutputStream.Append(v6);
    OutputStream.RestartStrip();

// Top face
    OutputStream.Append(v6);
    OutputStream.Append(v8);
    OutputStream.Append(v11);
    OutputStream.RestartStrip();

    OutputStream.Append(v11);
    OutputStream.Append(v9);
    OutputStream.Append(v6);
    OutputStream.RestartStrip();

// Bottom face
    OutputStream.Append(v7);
    OutputStream.Append(v10);
    OutputStream.Append(v5);
    OutputStream.RestartStrip();

    OutputStream.Append(v5);
    OutputStream.Append(v4);
    OutputStream.Append(v7);
    OutputStream.RestartStrip();

// Left face
    OutputStream.Append(v2);
    OutputStream.Append(v5);
    OutputStream.Append(v10);
    OutputStream.RestartStrip();

    OutputStream.Append(v10);
    OutputStream.Append(v8);
    OutputStream.Append(v2);
    OutputStream.RestartStrip();

// Right face
    OutputStream.Append(v9);
    OutputStream.Append(v11);
    OutputStream.Append(v4);
    OutputStream.RestartStrip();

    OutputStream.Append(v4);
    OutputStream.Append(v3);
    OutputStream.Append(v9);
    OutputStream.RestartStrip();

}