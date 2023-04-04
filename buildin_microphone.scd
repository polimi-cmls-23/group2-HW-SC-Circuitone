s.boot;

(
SynthDef(\micInput, {
    arg out=0;
    var input = SoundIn.ar(0, 2);
    Out.ar(out, input);
}).add;
)

(
s.scope; // open the Scope window
)


( var micInputSynth;
micInputSynth = Synth(\micInput, [\out, 0]);
)


(
SynthDef(\distortedMic, {
    arg out=0, gain=1, decimation=0.5, bitDepth=8;
    var input = SoundIn.ar(0, 2);
    input = (Decimator.ar(input, decimation, bitDepth) * gain).clip2(1);
    Out.ar(out, input);
}).add;
)


(
distortedMicSynth = Synth(\distortedMic, [\out, 0, \gain, 2, \decimation, 0.1, \bitDepth, 4]);
)