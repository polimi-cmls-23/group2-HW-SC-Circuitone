s.boot;

(
SynthDef(\distortedMic, {
    arg out=0, gain=1, decimation=0.5, bitDepth=8;
    var input = SoundIn.ar(0, 2);
    input = (Decimator.ar(input, decimation, bitDepth) * gain).clip2(1);
    Out.ar(out, input);
}).add;
)


( var distortedMicSynth;
distortedMicSynth = Synth(\distortedMic, [\out, 0, \gain, 1.5, \decimation, 0.2, \bitDepth, 6]);
)

