#include "ofApp.h"

constexpr float RAD_2_DEG = 180.0 / 3.141592653589793;

//--------------------------------------------------------------
// Auxiliary local function to extract audio frames from wav samples
//
void FillBuffer(const std::vector<float>& samples, unsigned int& position, unsigned int& endFrame, CMonoBuffer<float> &output)
{
    position = endFrame + 1;                             // Set starting point as next sample of the end of last frame
    if (position >= samples.size())                 // If the end of the audio is met, the position variable must return to the beginning
        position = 0;

    endFrame = position + output.size() - 1;             // Set ending point as starting point plus frame size
    for (int i = 0; i < output.size(); i++) {
        if ((position + i) < samples.size())
            output[i] = (samples[position + i]);     // Fill with audio
        else
            output[i] = 0.0f;                             // Fill with zeros if the end of the audio is met
    }
}

//--------------------------------------------------------------
void ofApp::audioOut(ofSoundBuffer & buffer)
{
    // Make sure we still have the proper buffer size
    if (globalParameters.GetBufferSize() == buffer.getNumFrames())
    {

        // Prepare input buffers from sources
        CMonoBuffer<float> source1Input(buffer.getNumFrames());
        FillBuffer(sample1, posSource1, endSource1, source1Input);
        source1BRT->SetBuffer(source1Input);
        
        // Binaural processing
        brtManager.ProcessAll();

        // Get ouput stereo buffers
        Common::CEarPair<CMonoBuffer<float>> bufferOutput;
        listener->GetBuffers(bufferOutput.left, bufferOutput.right);
        

        // Interlace stereo output
        for (size_t i = 0; i < buffer.getNumFrames(); i++) {
           buffer[i*buffer.getNumChannels()     ] = bufferOutput.left[i];
           buffer[i*buffer.getNumChannels() + 1 ] = bufferOutput.right[i];
        }

    }
}


//--------------------------------------------------------------
void ofApp::setup(){	

    // Global parameters. 
    globalParameters.SetSampleRate(SAMPLERATE);
    globalParameters.SetBufferSize(BUFFERSIZE);
    
    // Listener setup
    brtManager.BeginSetup();
    listener = brtManager.CreateListener<BRTBase::CListener>(LISTERNER_ID); // Instatiate a BRT Listener
    listenerModel = brtManager.CreateListenerModel<BRTListenerModel::CListenerDirectHRTFConvolutionModel>(LISTENER_HRTF_MODEL_ID); // Instatiate a BRT Listener Model
    volatile bool control = listener->ConnectListenerModel(LISTENER_HRTF_MODEL_ID); // Connect Listener to the Listener Model
    // TODO: Check if control is true, otherwise print error message.
    brtManager.EndSetup();    

    Common::CTransform listenerPosition = Common::CTransform();		 // Setting listener in (0,0,0)
    listenerPosition.SetPosition(Common::CVector3(0, 0, 0));
    listener->SetListenerTransform(listenerPosition);

    // Data path managed by openFrameworks. 
    std::string pathToData = ofToDataPath("");
    std::string pathToSofa = pathToData + SOFA_FILEPATH_1;

    // Read SOFA
    bool hrtfSofaLoaded1 = LoadSofaFile(pathToSofa);
    if (hrtfSofaLoaded1) {
        listener->SetHRTF(HRTF_list[0]);
    }

    // TODO: Load Nearfield ILD coefficientes. 
    
    // Create and connect source 1
    brtManager.BeginSetup();
    source1BRT = brtManager.CreateSoundSource<BRTSourceModel::CSourceOmnidirectionalModel>("speech");    // Instatiate a BRT Sound Source
    listenerModel->ConnectSoundSource(source1BRT);                                               // Connect Source to the listener model
    // Can also be done with listenerModel = brtManager->GetListenerModel(LISTENER_HRTF_MODEL_ID); // etc. 
    brtManager.EndSetup();

    // Setup source 1
    std::string pathToWav = pathToData + SOURCE_FILEPATH_1;
    LoadWav(pathToWav.c_str(), sample1);                                                // Loading .wav file
    Common::CTransform source1 = Common::CTransform();
    source1.SetPosition(Spherical2Cartesians(SOURCE1_INITIAL_AZIMUTH, SOURCE1_INITIAL_ELEVATION, SOURCE1_INITIAL_DISTANCE));
    source1BRT->SetSourceTransform(source1);

    // Setup openFrameworks audio 
    ofSoundStreamSettings settings;
	settings.setOutListener(this);
	settings.sampleRate = globalParameters.GetSampleRate();
	settings.numOutputChannels = 2;
	settings.numInputChannels = 0;
	settings.bufferSize = globalParameters.GetBufferSize();
    systemSoundStream.setup(settings);
    systemSoundStream.stop();
    // not implemented on iOS volatile auto deviceList = systemSoundStream.getDeviceList();
    ofAudioStarted = false;
    
    // Setup graphics
    ofSetColor(255,255,255);
    ofFill();
}

//--------------------------------------------------------------
void ofApp::update(){

}

//--------------------------------------------------------------
void ofApp::draw(){
    if (ofAudioStarted) {

        // Change background to pink.
        ofBackground(255,120,120);

        ofPushMatrix();
        ofPushView();
        ofTranslate(ofGetWidth()/2, ofGetHeight()/2);
        
        // Draw a square
        ofSetRectMode(OF_RECTMODE_CENTER);
        ofDrawRectangle(0,0,100,100);

        // Draw a message
        ofScale(2);
        ofDrawBitmapString("Double tap anywhere to stop", -100,-100);
        
        // Draw another message
        ofDrawBitmapString("Drag finger to move source around", -130,100);
        
        // Display source Azimuth
        std::string str = "Azimuth is ";
        str += ofToString(sourceAzimuth * RAD_2_DEG) + " degrees";
        ofDrawBitmapString(str,-100,150);
        
        // Draw a line and two triangles
        ofSetLineWidth(20);
        ofDrawLine(-130, 200, 130, 200);
        ofTranslate(130,200);
        ofDrawTriangle(-25,-25,25,0,-25,25);
        ofScale(-1,1);
        ofTranslate(260,0);
        ofDrawTriangle(-25,-25,25,0,-25,25);
        ofPopMatrix();
        ofPopView();
    }
    else {
        // Change background to grey
        ofBackground(120,120,120);
 
        ofPushMatrix();
        ofPushView();
        ofTranslate(ofGetWidth()/2, ofGetHeight()/2);
        
        // Draw a triangle
        ofDrawTriangle(-50,-50,50,0,-50,50);
        
        // Draw a message
        ofScale(2);
        ofDrawBitmapString("Double tap anywhere to play", -100,-100);

        ofPopMatrix();
        ofPopView();
        
    }
	
}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    if (touch.id == 0) {
        float azimuth = ofMap(touch.x, 10, ofGetWidth()-10, 3.141592653589793 / 2.0, -3.141592653589793 / 2.0);
        setSourceAzimuth(azimuth);
    }
}
//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    if (!ofAudioStarted) {
        StartOFAudio();
    } else {
        StopOFAudio();
    }
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}

//--------------------------------------------------------------
void ofApp::launchedWithURL(std::string url){

}

//--------------------------------------------------------------
void ofApp::StartOFAudio() {
    if (ofAudioStarted) return;
    systemSoundStream.start();
    ofAudioStarted = true;
}

//--------------------------------------------------------------
void ofApp::StopOFAudio() {
    if (!ofAudioStarted) return;
    systemSoundStream.stop();
    ofAudioStarted = false;
}

//--------------------------------------------------------------
bool ofApp::LoadSofaFile(const std::string & _filePath) {
    
    bool result = false;
    std::shared_ptr<BRTServices::CHRTF> hrtf = std::make_shared<BRTServices::CHRTF>();
    // Try to get sample rate in SOFA
    int sampleRateInSOFAFile = sofaReader.GetSampleRateFromSofa(_filePath);
    if (sampleRateInSOFAFile == -1) {
        result = false;
    }
    else {
        // Make sure sample rate is same as selected in app.
        if (globalParameters.GetSampleRate() != sampleRateInSOFAFile) {
            result = false;
        }
        else {
            result = sofaReader.ReadHRTFFromSofa(_filePath, hrtf, HRTFRESAMPLINGSTEP, BRTServices::TEXTRAPOLATION_METHOD::nearest_point);
            if (result) {
                // Success reading hrtf!
                HRTF_list.push_back(hrtf);
            }
        }
    }
    return result;
}


//--------------------------------------------------------------
void ofApp::LoadWav(const char* stringIn, std::vector<float>& sampleOut)
{
    struct WavHeader                                 // Local declaration of wav header struct type (more info in http://soundfile.sapp.org/doc/WaveFormat/)
    {                                                 // We only need the number of samples, so the rest will be unused assuming file is mono, 16-bit depth and 44.1kHz sampling rate
        char          fill[40];
        uint32_t    bytesCount;
    } wavHeader;

    FILE* wavFile = fopen(stringIn, "rb");                                             // Opening of the wav file
    fread(&wavHeader, sizeof(wavHeader), 1, wavFile);                                 // Reading of the 44 bytes of header to get the number of samples of the file
    fseek(wavFile, sizeof(wavHeader), SEEK_SET);                                     // Moving of the file pointer to the start of the audio samples

    unsigned int samplesCount = wavHeader.bytesCount / 2;                             // Getting number of samples by dividing number of bytes by 2 because we are reading 16-bit samples
    int16_t *sample; sample = new int16_t[samplesCount];                             // Declaration and initialization of 16-bit signed integer pointer
    memset(sample, 0, sizeof(int16_t) * samplesCount);                                 // Setting its size

    uint8_t *byteSample; byteSample = new uint8_t[2 * samplesCount];                 // Declaration and initialization of 8-bit unsigned integer pointer
    memset(byteSample, 0, sizeof(uint8_t) * 2 * samplesCount);                         // Setting its size

    fread(byteSample, 1, 2 * samplesCount, wavFile);                                 // Reading the whole file byte per byte, needed for endian-independent wav parsing

    for (int i = 0; i < samplesCount; i++)
        sample[i] = int16_t(byteSample[2 * i] | byteSample[2 * i + 1] << 8);         // Conversion from two 8-bit unsigned integer to a 16-bit signed integer

    sampleOut.reserve(samplesCount);                                             // Reserving memory for samples vector

    for (int i = 0; i < samplesCount; i++)
        sampleOut.push_back((float)sample[i] / (float)INT16_MAX);                 // Converting samples to float to push them in samples vector
}

//--------------------------------------------------------------
Common::CVector3 ofApp::Spherical2Cartesians(float azimuth, float elevation, float radius)
  {

    Common::CVector3 globalPos = listener->GetListenerTransform().GetPosition();

    float x = radius * cos(azimuth) * cos(elevation);
    float y = radius * sin(azimuth) * cos(elevation);
    float z = radius * sin(elevation);

    globalPos.x += x;
    globalPos.y += y;
    globalPos.z += z;

    return globalPos;
  }


//--------------------------------------------------------------
void  ofApp::setSourceAzimuth(float newAzimuth)
{
    Common::CVector3 newPosition;
    newPosition = Spherical2Cartesians(newAzimuth, sourceElevation, sourceDistance);
    Common::CTransform newPose = source1BRT->GetSourceTransform();
    newPose.SetPosition(newPosition);
    source1BRT->SetSourceTransform(newPose);
    sourceAzimuth = newAzimuth;
}
