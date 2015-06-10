% Kunal Jathal

% John Chowning FM
% ================

% function JohnChowning(carrierFrequency, modulatorFrequency, duration)

% carrierFrequency      = Carrier Frequency 
% modulatorFrequency    = Modulator Frequency
% duration              = Duration of the signal

% Note - Instead of having the envelopes as input arguments, I've hardcoded
% them here because I'm trying to model a certain kind of instrument (bass drum).

function JohnChowning(carrierFrequency, modulatorFrequency, duration)

% Set sampling frequency and time variables
fs = 44100;
time = [0:1/fs:duration-1/fs];

% The envelope equation I am using for both the carrier and modulator is:
% Amplitude ./exp ((0:(length(time)-1))/fs).^decay;

% Tweaking the amplitude and the decay values shape the envelope. These are
% the values I use to simulate a bass drum sound:
% (along with carrierFrequency=70, modulatorFrequency=50)

modulatorAmplitude = 10;
modulatorEnvelopeDecay = 15;
carrierAmplitude = 2;
carrierEnvelopeDecay = 10;

modulationIndex = modulatorAmplitude./exp ((0:(length(time)-1))/fs).^modulatorEnvelopeDecay;
amplitudeCarrier = carrierAmplitude./exp ((0:(length(time)-1))/fs).^carrierEnvelopeDecay;

% Modulator
modulator = modulationIndex.*sin(2*pi*modulatorFrequency*time); 

% Carrier
carrier = amplitudeCarrier.*cos(2*pi*carrierFrequency*time + modulator);

%Sound the wave
sound(carrier, fs);


