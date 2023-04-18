s.reboot；
(
~inputBus = Bus.audio(s, 2); // define bus with 2 channels
~outputBus = Bus.audio(s, 2);
~xyBus = Bus.audio(s, 2);
~myBuffer = Buffer.alloc(s, 1024, 1);
// ~inputSignal = SinOsc.ar([220, 220], mul:1);
// ~outputSignal = Signal.new;
)


(
	var tf;

	var gain, thr;

	gain = 2;
	thr = 0.4;

	tf = Signal.newClear(513);
	tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				if((old<(thr/gain)),
					{// linear
						// ("linear pos"+"i ="+i).postln;
						old*gain
					},
					{if((old<((2-thr)/gain)),
						{// quatratic
							// ("quadratic pos"+"i ="+i).postln;
							((((old-((2-thr)/gain)).squared)*gain*gain)/(4*(thr-1)))+1
						},
						{// clip
							// ("clip pos"+"i ="+i).postln;
							1
					})
				})
			},
			{// negative
				if((old>((-1)*thr/gain)),
					{// linear
						// ("linear neg"+"i ="+i).postln;
						old*gain
					},
					{if((old>((thr-2)/gain)),
						{// quatratic
							// ("quadratic neg"+"i ="+i).postln;
							((((old-((thr-2)/gain)).squared)*gain*gain)/(4*(1-thr)))-1
						},
						{// clip
							// ("clip neg"+"i ="+i).postln;
							-1
					})
				})
			}
		)
	});
	~myBuffer.sendCollection(tf.asWavetableNoWrap);
   // ~myBuffer.plot;
)

// Create a SynthDef that uses Shaper.ar to apply the Wavetable to the microphone input
(
SynthDef(\mySynth, {
    var inputSignal, outputSignal;
    inputSignal = SoundIn.ar(0, 2);
    outputSignal = Shaper.ar(~myBuffer, inputSignal, 1, 0);
	Out.ar(~inputBus, inputSignal);
    Out.ar(~outputBus, outputSignal);
}).send(s);
)

s.scope;

~mySynth = Synth(\mySynth);

~inputBus.plot;
~outputBus.plot;

s.scope(~inputBus);
s.scope(~outputBus);
// Send the audio output to the computer's audio output
SoundOut.ar(0, [~outputBus, ~outputBus]);


///////////////////////////////
// Create a Synth that uses the 'mySynth' SynthDef
~mySynth = Synth(\mySynth, [\out, ~outputBus]);

// Route the microphone input to the input bus of the 'mySynth' Synth
Ndef(\input, { SoundIn.ar(0, 2) }).play;
Ndef(\input).set(\in, ~inputBus);

// Route the output bus of the 'mySynth' Synth to the default output
Ndef(\output, { Mix.new(~outputBus) }).play;
Ndef(\output).set(\in, 0);












/////////////////////////////////////////
(
// Allocate a new bus for the input signal
~inputBus = Bus.audio(s, 2);

// Allocate a new bus for the output signal
~outputBus = Bus.audio(s, 2);

// Allocate a new buffer
~myBuffer = Buffer.alloc(s, 1024, 1);
)
// Define the SynthDef
(
~mySynth = SynthDef(\mySynth, {
    var inputSignal, outputSignal;
    inputSignal = SoundIn.ar(0,2);
    outputSignal = Shaper.ar( ~myBuffer.asWavetable, inputSignal, 1, 0);
    Out.ar(~outputBus.index, outputSignal);
}).send(s);
)
// Start the input signal
SoundIn.ar(~inputBus);

// Start the output signal
Synth.new(\mySynth, [\out, ~outputBus]);

// Define the distortion function and send it to the buffer
tf = Signal.newClear(513);
tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
    var gain, thr;
    gain = 2;
    thr = 0.4;
    if((old>0),
        {// positive
            if((old<(thr/gain)),
                {// linear
                    old*gain
                },
                {if((old<((2-thr)/gain)),
                    {// quatratic
                        ((((old-((2-thr)/gain)).squared)*gain*gain)/(4*(thr-1)))+1
                    },
                    {// clip
                        1
                })
            })
        },
        {// negative
            if((old>((-1)*thr/gain)),
                {// linear
                    old*gain
                },
                {if((old>((thr-2)/gain)),
                    {// quatratic
                        ((((old-((thr-2)/gain)).squared)*gain*gain)/(4*(1-thr)))-1
                    },
                    {// clip
                        -1
                })
            })
        }
    )
});

// Send the distortion function to the buffer
~myBuffer.sendCollection(tf.asWavetableNoWrap);

// Define a function to continuously update the buffer with the distortion function
{
    var distortionFunc;
    inf.do({
        distortionFunc = tf.asWavetableNoWrap;
        ~myBuffer.set(distortionFunc);
        20.wait;
    });
}.fork;


// Define a function to continuously print the current input and output levels
{
    inf.do({
        var inputLevel, outputLevel;
        inputLevel = SoundIn.ar(~inputBus).rms;
        outputLevel = SoundIn.ar(~outputBus).rms;
        ["Input level: ", inputLevel, "Output level: ", outputLevel].postln;
        0.1.wait;
    });
}.fork;
