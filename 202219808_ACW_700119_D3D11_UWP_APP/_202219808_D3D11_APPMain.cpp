﻿#include "pch.h"
#include "_202219808_D3D11_APPMain.h"
#include "Common\DirectXHelper.h"

using namespace _202219808_D3D11_APP;
using namespace Windows::Foundation;
using namespace Windows::System::Threading;
using namespace Concurrency;

// Loads and initializes application assets when the application is loaded.
_202219808_D3D11_APPMain::_202219808_D3D11_APPMain(const std::shared_ptr<DX::DeviceResources>& deviceResources) :
	m_deviceResources(deviceResources),
	m_tessFactor(31.0f)
{
	// Register to be notified if the Device is lost or recreated
	m_deviceResources->RegisterDeviceNotify(this);

	// TODO: Replace this with your app's content initialization.
	m_underwaterRenderer = std::unique_ptr<UnderwaterRenderer>(new UnderwaterRenderer(m_deviceResources));
	m_plantRenderer = std::unique_ptr<PlantRenderer>(new PlantRenderer(m_deviceResources));
	//m_vertexShaderRenderer = std::unique_ptr<VertexShaderRenderer>(new VertexShaderRenderer(m_deviceResources));
	//m_tessellationShaderRenderer = std::unique_ptr<TessellationRenderer>(new TessellationRenderer(m_deviceResources));
	m_fpsTextRenderer = std::unique_ptr<FpsTextRenderer>(new FpsTextRenderer(m_deviceResources));
	// TODO: Change the timer settings if you want something other than the default variable timestep mode.
	// e.g. for 60 FPS fixed timestep update logic, call:
	/*
	m_timer.SetFixedTimeStep(true);
	m_timer.SetTargetElapsedSeconds(1.0 / 60);
	*/
}

_202219808_D3D11_APPMain::~_202219808_D3D11_APPMain()
{
	// Deregister device notification
	m_deviceResources->RegisterDeviceNotify(nullptr);
}

// Updates application state when the window size changes (e.g. device orientation change)
void _202219808_D3D11_APPMain::CreateWindowSizeDependentResources()
{
	// TODO: Replace this with the size-dependent initialization of your app's content.
	m_underwaterRenderer->CreateWindowSizeDependentResources();
	m_plantRenderer->CreateWindowSizeDependentResources();
	//m_vertexShaderRenderer->CreateWindowSizeDependentResources();
	//m_tessellationShaderRenderer->CreateWindowSizeDependentResources();
}

// Updates the application state once per frame.
void _202219808_D3D11_APPMain::Update()
{
	CheckInput(m_timer);
	// Update scene objects.
	m_timer.Tick([&]()
		{
			// TODO: Replace this with your app's content update functions.

			m_underwaterRenderer->Update(m_timer);
			m_plantRenderer->Update(m_timer);
			//m_vertexShaderRenderer->Update(m_timer);
			//m_tessellationShaderRenderer->Update(m_timer);
			m_fpsTextRenderer->Update(m_timer, m_tessFactor);
		});
}

// Renders the current frame according to the current application state.
// Returns true if the frame was rendered and is ready to be displayed.
bool _202219808_D3D11_APPMain::Render()
{
	// Don't try to render anything before the first Update.
	if (m_timer.GetFrameCount() == 0)
	{
		return false;
	}

	auto context = m_deviceResources->GetD3DDeviceContext();

	// Reset the viewport to target the whole screen.
	auto viewport = m_deviceResources->GetScreenViewport();
	context->RSSetViewports(1, &viewport);

	// Reset render targets to the screen.
	ID3D11RenderTargetView* const targets[1] = { m_deviceResources->GetBackBufferRenderTargetView() };
	context->OMSetRenderTargets(1, targets, m_deviceResources->GetDepthStencilView());

	// Clear the back buffer and depth stencil view.
	context->ClearRenderTargetView(m_deviceResources->GetBackBufferRenderTargetView(), DirectX::Colors::CornflowerBlue);
	context->ClearDepthStencilView(m_deviceResources->GetDepthStencilView(), D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL, 1.0f, 0);

	// Render the scene objects.
	// TODO: Replace this with your app's content rendering functions.
	m_underwaterRenderer->Render();
	m_plantRenderer->Render();
	//m_vertexShaderRenderer->Render();
	//m_tessellationShaderRenderer->Render();
	m_fpsTextRenderer->Render();



	return true;
}

// Notifies renderers that device resources need to be released.
void _202219808_D3D11_APPMain::OnDeviceLost()
{
	m_underwaterRenderer->ReleaseDeviceDependentResources();
	m_plantRenderer->ReleaseDeviceDependentResources();
	//m_vertexShaderRenderer->ReleaseDeviceDependentResources();
	//m_tessellationShaderRenderer->ReleaseDeviceDependentResources();
	m_fpsTextRenderer->ReleaseDeviceDependentResources();
}

// Notifies renderers that device resources may now be recreated.
void _202219808_D3D11_APPMain::OnDeviceRestored()
{
	m_underwaterRenderer->CreateDeviceDependentResources();
	m_plantRenderer->CreateDeviceDependentResources();
	//m_vertexShaderRenderer->CreateDeviceDependentResources();
	//m_tessellationShaderRenderer->CreateDeviceDependentResources();
	m_fpsTextRenderer->CreateDeviceDependentResources();
	CreateWindowSizeDependentResources();
}

void _202219808_D3D11_APPMain::CheckInput(DX::StepTimer const& timer)
{

	if (CheckKeyPressed(static_cast<VirtualKey>(0x45)))
	{
		if (m_tessFactor > 1.0f)
		{
			m_tessFactor -= 1.0f;
		}
	}

	if (CheckKeyPressed(static_cast<VirtualKey>(0x51)))
	{
		if (m_tessFactor < 64.0f)
		{
			m_tessFactor += 1.0f;
		}
	}
}

bool _202219808_D3D11_APPMain::CheckKeyPressed(VirtualKey key)
{
	return (CoreWindow::GetForCurrentThread()->GetKeyState(key) & CoreVirtualKeyStates::Down) == CoreVirtualKeyStates::Down;
}