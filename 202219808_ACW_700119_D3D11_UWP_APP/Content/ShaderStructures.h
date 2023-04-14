#pragma once

namespace _202219808_D3D11_APP
{
	// Constant buffer used to send MVP matrices to the vertex shader.
	struct ModelViewProjectionConstantBuffer
	{
		DirectX::XMFLOAT4X4 model;
		DirectX::XMFLOAT4X4 view;
		DirectX::XMFLOAT4X4 projection;
	};
	struct TimeConstantBuffer
	{
		float time;
		DirectX::XMFLOAT3 padding;
	};
	struct ResolutionBuffer
	{
		float screenX;
		float screenY;
		DirectX::XMFLOAT2 padding;
	};
	struct TessBuffer
	{
		float tessAmount;
		DirectX::XMFLOAT3 padding;
	};

	// Used to send per-vertex data to the vertex shader.
	struct VertexPositionColor
	{
		DirectX::XMFLOAT3 pos;
		DirectX::XMFLOAT3 color;
	};
}