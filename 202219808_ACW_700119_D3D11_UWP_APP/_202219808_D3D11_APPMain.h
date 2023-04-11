#pragma once

#include "Common\StepTimer.h"
#include "Common\DeviceResources.h"
#include "Content\UnderwaterRenderer.h"
#include "Content\BubbleRenderer.h"
#include "Content\PlantRenderer.h"
#include "Content\PSCoralRenderer.h"
#include "Content\VSCoralRenderer.h"
#include "Content\TSCoralRenderer.h"
#include "Content\GSCoralRenderer.h"
#include "Content\FishRenderer.h"
#include "Content\FpsTextRenderer.h"

// Renders Direct2D and 3D content on the screen.
namespace _202219808_D3D11_APP
{
	using namespace Windows::System;
	using namespace Windows::UI::Core;

	class _202219808_D3D11_APPMain : public DX::IDeviceNotify
	{
	public:
		_202219808_D3D11_APPMain(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~_202219808_D3D11_APPMain();
		void CreateWindowSizeDependentResources();
		void Update();
		bool Render();

		// IDeviceNotify
		virtual void OnDeviceLost();
		virtual void OnDeviceRestored();

	private:
		void CheckInput(DX::StepTimer const& timer);
		bool CheckKeyPressed(VirtualKey key);
		
	private:
		// Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources>   m_deviceResources;

		// TODO: Replace with your own content renderers.
		std::unique_ptr<FpsTextRenderer>	   m_fpsTextRenderer;
		
		// Implicit geometry
		std::unique_ptr<UnderwaterRenderer>    m_underwaterRenderer;
		std::unique_ptr<BubbleRenderer>		   m_bubbleRenderer;
		std::unique_ptr<PlantRenderer>		   m_plantRenderer;
		std::unique_ptr<PSCoralRenderer>	   m_psCoralRenderer;

		// Explicit geometry
		std::unique_ptr<VSCoralRenderer>	   m_vsCoralRenderer;
		std::unique_ptr<TSCoralRenderer>	   m_tsCoralRenderer;
		std::unique_ptr<GSCoralRenderer>	   m_gsCoralRenderer;
		std::unique_ptr<FishRenderer>		   m_fishRenderer;

		// Rendering loop timer.
		DX::StepTimer m_timer;
		float m_tessFactor;
	};
}