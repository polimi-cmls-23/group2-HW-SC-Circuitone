// Connect your guitar to an audio interface or an amplifier that has a line-level output.

// Connect the audio interface or amplifier's line-level output to your computer's audio interface using an audio cable.

s.boot;
s.options.numInputBusChannels = 1;// This will create a new audio input bus with one channel.

s.reboot;

(
SynthDef(\guitar, {
    arg out=0;
    var input = SoundIn.ar(0);
    Out.ar(out, input);
}).add;
) ///This SynthDef named "guitar" takes one argument for the output bus and uses SoundIn.ar(0) to receive audio from the first audio input bus.

guitarSynth = Synth(\guitar, [\out, 0]); //Create a new instance of the "guitar" SynthDef and assign it to a variable.


(
SynthDef(\guitarDistortion, {
    arg out=0, gain=1, decimation=0.5, bitDepth=8;
    var input = SoundIn.ar(0);
    input = (Decimator.ar(input, decimation, bitDepth) * gain).clip2(1);
    Out.ar(out, input);
}).add;
) //This SynthDef named "guitarDistortion" takes four arguments: the output bus, the distortion gain, the decimation factor (which determines how much to reduce the sample rate), and the bit depth (which determines how many bits to use for each sample).

(
guitarDistortionSynth = Synth(\guitarDistortion, [\out, 0, \gain, 1.5, \decimation, 0.2, \bitDepth, 6]);
) //create a new instance of the "guitarDistortion" SynthDef and adjust the arguments to get the desired sound. This will create a new instance of the "guitarDistortion" SynthDef and apply a distortion effect with a gain of 1.5, a decimation factor of 0.2, and a bit depth of 6.




