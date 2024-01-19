#pragma once

#include "ofxiOS.h"
#include "ofxBRT.h"

#define SOFA_FILEPATH_1 "3DTI_HRTF_IRC1008_512s_44100Hz.sofa"
#define SOURCE_FILEPATH_1 "MusArch_Sample_44.1kHz_Anechoic_FemaleSpeech.wav"


#define HRTFRESAMPLINGSTEP 15
#define SAMPLERATE 44100
#define BUFFERSIZE 512


constexpr float SOURCE1_INITIAL_AZIMUTH =  3.141592653589793 / 2.0; // pi/2
constexpr float SOURCE1_INITIAL_ELEVATION = 0.f;
constexpr float SOURCE1_INITIAL_DISTANCE = 0.1f; // 10 cm.

class ofApp : public ofxiOSApp {
	
    public:

        void audioOut(ofSoundBuffer & buffer);
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
    
    /// Basic wav reading
    void LoadWav(const char* stringIn, std::vector<float>& samplesVector);
    
    /// Load SOFA hrtf file via BRT Library
    bool LoadSofaFile(const std::string & _filePath);

    /// Get global cartesian coordinates from local to listener polar coordinates  
    Common::CVector3 Spherical2Cartesians(float azimuth, float elevation, float radius);
    
    
private:
    /// BRT Library
    Common::CGlobalParameters globalParameters;                                   // Global BRT parameters
    BRTBase::CBRTManager brtManager;                                              // BRT global manager interface
    std::shared_ptr<BRTListenerModel::CListenerHRTFbasedModel> listener;          // Pointer to listener model
    std::shared_ptr<BRTSourceModel::CSourceSimpleModel> source1BRT;               // Pointer to audio source model
    BRTReaders::CSOFAReader sofaReader;                                           // SOFA reader provided by BRT Library
    std::vector<std::shared_ptr<BRTServices::CHRTF>> HRTF_list;                   // List of HRTFs loaded

    /// Input audio sample
    std::vector<float> sample1;                                                  // Input Audio
    unsigned int posSource1, endSource1;	                                      // Store start and endi position of the current frame. 
    
    /// Openframeworks audio vars
    bool ofAudioStarted;
    ofSoundStream systemSoundStream;

};
