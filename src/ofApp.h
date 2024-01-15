#pragma once

#include "ofxiOS.h"
#include "ofxBRT.h"

class ofApp : public ofxiOSApp {
	
    public:
        void setup() override;
        void update() override;
        void draw() override;
        void exit() override;
	
        void touchDown(ofTouchEventArgs & touch) override;
        void touchMoved(ofTouchEventArgs & touch) override;
        void touchUp(ofTouchEventArgs & touch) override;
        void touchDoubleTap(ofTouchEventArgs & touch) override;
        void touchCancelled(ofTouchEventArgs & touch) override;

        void lostFocus() override;
        void gotFocus() override;
        void gotMemoryWarning() override;
        void deviceOrientationChanged(int newOrientation) override;
        void launchedWithURL(std::string url) override;
    
private:
    
    /// openFrameworks Audio
    // int GetAudioDeviceIndexMenu(std::vector<ofSoundDevice>& list, int _audioDeviceId);
    // void SetDeviceAndAudio(int _audioDeviceId);
    // void audioOut(float* output, int bufferSize, int nChannels);
    // void audioProcess(Common::CEarPair<CMonoBuffer<float>>& bufferOutput, int uiBufferSize);
    void StartOFAudio();
    void StopOFAudio();
    
private:
    /// BRT Library
    Common::CGlobalParameters globalParameters;                                                     // Class where the global BRT parameters are defined.
    BRTBase::CBRTManager brtManager;                                                                // BRT global manager interface
    std::shared_ptr<BRTListenerModel::CListenerHRTFbasedModel> listener;                            // Pointer to listener model
    std::shared_ptr<BRTSourceModel::CSourceSimpleModel> source1BRT;                               // Pointers to each audio source model
    
    /// Openframeworks Audio
    bool ofAudioStarted;
    ofSoundStream systemSoundStream;

};
