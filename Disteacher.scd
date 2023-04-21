s.boot;

(

~outBus = 0; // tefault output bus is set to 0
~microphoneBus = 0; // Selection of the proper input bus for a microphone
~soundcardBus = Bus.audio(s); // Selection of the proper input bus for playing an instrument (guitar)

// General initializations

~inGain = 1.0;
~gain = 1;
~thr = 1;
~outGain = 1.0;
~freq = 20;
~analogPos = 0;
~analogNeg = 0;

// Example sounds load

~guitarBuffer = Buffer.read(s, "C:/Users/Gabriele/Documents/MEGA/Magistrale/Music and Acoustic Engineering/CMLS/HW1/Clean guitar loop_mono.mp3");
~bassBuffer = Buffer.read(s, "C:/Users/Gabriele/Documents/MEGA/Magistrale/Music and Acoustic Engineering/CMLS/HW1/Bass_mono.mp3");
~voiceBuffer = Buffer.read(s, "C:/Users/Gabriele/Documents/MEGA/Magistrale/Music and Acoustic Engineering/CMLS/HW1/Voice_mono.mp3");
~alabamaBuffer = Buffer.read(s, "C:/Users/Gabriele/Documents/MEGA/Magistrale/Music and Acoustic Engineering/CMLS/HW1/Sweet Home Alabama.mp3");

~inputBus = Bus.audio(s); // The bus in which the selected input is routed in order to be manipulated by the plugin

// Definition of the different functions

~sinusoid = {SinOsc.ar(~freq, 0, 1)};
~guitar = {PlayBuf.ar(1, ~guitarBuffer.bufnum)};
~voice = {PlayBuf.ar(1, ~voiceBuffer.bufnum)};
~bass = {PlayBuf.ar(1, ~bassBuffer.bufnum)};
~alabama = {PlayBuf.ar(1, ~alabamaBuffer.bufnum)};
~mic = {SoundIn.ar(~microphoneBus, 1)};
~soundcard = {In.ar(~soundcardBus, 1)};

// The input will be choosen by indexing in this assay

~funcs = [~sinusoid, ~guitar, ~voice, ~bass, ~alabama, ~mic, ~soundcard];

// Buffers and signals needed to compute the transfer functions

~myBuffer = Buffer.alloc(s, 1024, 1);
~tf = Signal.newClear(513);
~myInBuffer = Buffer.alloc(s, 1024, 1);
~inTf = Signal.newClear(513);

// Link to the GeoGebra site to better visualize the transfer functions: https://www.geogebra.org/m/x5bhsngv

// Hyperbolic tangent transfer function

~tanhFunction = {

	// Apply a transfer function to scale the input signal with the input gain knob value

	~inTf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, In.ar(~inputBus));

	// Apply the hyperbolic tangent transfer function using the same method as before

	~tf.waveFill({arg x, old, i; 2*x-1});

	// Introduce the effect of the analog button on the gain parameter

	~tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				old*(~gain+~analogPos)
			},
			{// negative
				old*(~gain+~analogNeg)
			}
		)
	});
	~tf = ~tf.tanh;
	if((~gain == 0), {~tf = ~tf * 0;}, {}); // To reduce artifacts due to the analog option
	~tf = ~tf * ~outGain;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	Shaper.ar(~myBuffer, ~gainedInputSignal);
};

// Foldback transfer function

~foldbackFunction = {
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, In.ar(~inputBus));
	~tf.waveFill({arg x, old, i; 2*x-1});
	~tf.waveFill({arg x, old, i;
		if((old>0),
			{// positive
				((~gain+~analogPos)*((~gain+~analogPos)*old).sin)*((-2)*(~gain+~analogPos)*old).exp
			},
			{// negative
				((~gain+~analogNeg)*((~gain+~analogNeg)*old).sin)*(2*(~gain+~analogNeg)*old).exp;
			}
		)
	});
	if((~gain == 0), {~tf = ~tf * 0;}, {});
	~tf = ~tf * ~outGain;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	Shaper.ar(~myBuffer, ~gainedInputSignal);
};

// Quadratic transfer function

~quadraticFunction = {
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, In.ar(~inputBus));
	~tf.waveFill({arg x, old, i; 2*x-1});
	~tf.waveFill({arg x, old, i;
		if((old>0),
			{// positive
				if((old<((~thr-~analogPos)/(~gain+~analogPos))),
					{// linear
						old*(~gain+~analogPos)
					},
					{if((old<((2-(~thr-~analogPos))/(~gain+~analogPos))),
						{// quatratic
							((((old-((2-(~thr-~analogPos))/(~gain+~analogPos))).squared)*(~gain+~analogPos)*(~gain+~analogPos))/(4*((~thr-~analogPos)-1)))+1
						},
						{// clip
							1
					})
				})
			},
			{// negative
				if((old>((-1)*(~thr+~analogNeg)/(~gain+~analogNeg))),
					{// linear
						old*(~gain+~analogNeg)
					},
					{if((old>(((~thr+~analogNeg)-2)/(~gain+~analogNeg))),
						{// quatratic
							((((old-(((~thr+~analogNeg)-2)/(~gain+~analogNeg))).squared)*(~gain+~analogNeg)*(~gain+~analogNeg))/(4*(1-(~thr+~analogNeg))))-1
						},
						{// clip
							-1
					})
				})
			}
		)
	});
	if((~gain == 0), {~tf = ~tf * 0;}, {});
	~tf = ~tf * ~outGain;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	Shaper.ar(~myBuffer, ~gainedInputSignal);
};

// Choose a mode - Initial PopUp

f = Font ("Kreon", 12);
~initialPopUp = Window.new("Initial mode choice", Rect(left: 650, top: 150, width: 400, height: 115), false);
~initialPopUp.front;
~initialPopUp.background = ~wColor;
~initialText = StaticText(~initialPopUp, Rect(20, 10, 380, 50));
~initialText.string = "Welcome to DISTEACHER, choose a mode to start.";
~initialText.font = Font("Kreon", 16);

// Actions needed to properly start the main window and the signal flow

~initialPopUp.onClose = {(
	~k3_disThr.doAction;
	~playButton.value = 1;
	~playButton.doAction;
)};

// If the user choose the "Tutorial" mode...

~tutorialButtonStart = Button(~initialPopUp, Rect(50, 70, 100, 30));
~tutorialButtonStart.font = f;
~tutorialButtonStart.states_([
	["Tutorial mode", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
	["Tutorial mode", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
]);
~tutorialButtonStart.action_({|butt| // The one in the initial window
	if (butt.value==1,
		{
			w.front; // w is the main window
			~tutorialw.front;
			~tutorialButton.value = 1; // The one in the main window
			~initialPopUp.close;
			~inputMenu.items_(["Sinusoid at"+~freq+"Hz", "Guitar mp3", "Voice mp3", "Bass mp3", "Sweet Home Alabama"]); // Set the input options corresponding to the tutorial mode
			~playButton = Button(w, ~playButRect)
			.states_([
				["Stop", Color.white, Color.new255(red: 111, green: 69, blue: 34, alpha: 255)],
				["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)]
			])
			.action_({|butt|
				if (butt.value==1,
					{
						// "stop" state --> stop all the sounds
						~sinusoidSig.free;
						~guitarSig.free;
						~voiceSig.free;
						~bassSig.free;
						~alabamaSig.free;
						~micSig.free;
						~soundcardSig.free;
					},
					{if (~inputMenu.value==0, // "play" state
						{
							// route (and play) the correct signal in the input bus
							~sinusoidSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
							~guitarSig.free;
							~voiceSig.free;
							~bassSig.free;
							~alabamaSig.free;
							~micSig.free;
							~soundcardSig.free;
						},
						{if(~inputMenu.value==1,
							{
								~sinusoidSig.free;
								~guitarSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
								~voiceSig.free;
								~bassSig.free;
								~alabamaSig.free;
								~micSig.free;
								~soundcardSig.free;
							},
							{if(~inputMenu.value==2,
								{
									~sinusoidSig.free;
									~guitarSig.free;
									~voiceSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
									~bassSig.free;
									~alabamaSig.free;
									~micSig.free;
									~soundcardSig.free;
								},
								{if(~inputMenu.value==3,
									{
										~sinusoidSig.free;
										~guitarSig.free;
										~voiceSig.free;
										~bassSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
										~alabamaSig.free;
										~micSig.free;
										~soundcardSig.free;
									},
									{
										~sinusoidSig.free;
										~guitarSig.free;
										~voiceSig.free;
										~bassSig.free;
										~alabamaSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
										~micSig.free;
										~soundcardSig.free;
									}
								)}
							)}
						)}
					)}
				)
			});
			~playButton.font_(Font("Kreon", 15));
		},
		{};
)});

// If the user choose the "I can do it" mode...

~iCanDoItButtonStart = Button(~initialPopUp, Rect(250, 70, 100, 30))
        .states_([
            ["I can do it", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["I can do it", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~iCanDoItButtonStart.font = f;
~iCanDoItButtonStart.value = 0;
~iCanDoItButtonStart.action_({|butt| // The one in the initial window
	if (butt.value==1,
		{
			w.front;
			~iCanDoItButton.value = 1; // The one in the main window
			~iCanDoItw.front;
			~initialPopUp.close;
			w.background = ~wColor2;
			~inputMenu.items_(["Computer mic", "Soundcard"]); // Update the input options
			~playButton = Button(w, ~playButRect)
			.states_([
				["Stop", Color.white, Color.new255(red: 111, green: 69, blue: 34, alpha: 255)],
				["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)]
			])
			.action_({|butt|
				if (butt.value==1, // Same as before...
					{
						~sinusoidSig.free;
						~guitarSig.free;
						~voiceSig.free;
						~bassSig.free;
						~alabamaSig.free;
						~micSig.free;
						~soundcardSig.free;
					},
					{if (~inputMenu.value==0,
						{
							~sinusoidSig.free;
							~guitarSig.free;
							~voiceSig.free;
							~bassSig.free;
							~alabamaSig.free;
							// The first 5 input options of the menu are now unavailable, so we have to add 5 to the index of the choosen input
							~micSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value+5))}.play;
							~soundcardSig.free;
						},
						{
							~sinusoidSig.free;
							~guitarSig.free;
							~voiceSig.free;
							~bassSig.free;
							~alabamaSig.free;
							~micSig.free;
							~soundcardSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value+5))}.play;
						}
					)}
				)
			});
			~playButton.font_(Font("Kreon", 15));
		},
		{};
)});

// Main window

f = Font ("Kreon", 12);
~wRect = Rect(left: 650, top: 150, width: 600, height: 500);
w = Window("Distorsion", ~wRect, false);
~wColor = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
~wColor2 = Color.new255(red: 255, green: 165, blue: 0, alpha: 255);
w.background = ~wColor;
w.alwaysOnTop = true;
~effectName = StaticText(w,Rect(150, 15, 300, 50))
.string_("DISTEACHER")
.align_(\center)
.font_(Font("Kreon", 40));

w.onClose = {(
	~sound.stop;
	Buffer.freeAll(s);
	~inputScope.stop;
	~outputScope.stop;
	~xyScope.stop;
	~inputBus.free;
	~outBus.free;
	~microphoneBus.free;
	~soundcardBus.free;
	~sinusoidSig.free;
	~guitarSig.free;
	~voiceSig.free;
	~bassSig.free;
	~alabamaSig.free;
	~micSig.free;
	~soundcardSig.free;
	Server.freeAll;
	Server.killAll;
)};

// Analog button

// Every time you select the analog mode, two new random nombers are added to the gain value in the transfer function, one to the positive part and the other to the negative part, in order to simulate the behaviour of a more realistic analog circuit

~analogButton = Button(w, Rect(260, 100, 80, 40))
        .states_([
            ["Analog", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["Analog", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~analogButton.font = f;
~analogButton.action_({|butt|
	if ((butt.value==1),
		{
			~analogPos = (1.0.rand.round(0.01)-1.0.rand.round(0.01))*0.1*~gain;
			~analogNeg = (1.0.rand.round(0.01)-1.0.rand.round(0.01))*0.1*~gain;
			~k0_inGain.doAction; // To recalculate the current transfer function
		},
		{
			~analogPos = 0;
			~analogNeg = 0;
			~k0_inGain.doAction; // To recalculate the current transfer function
		}
)});

// Knobs

// Intervals for every knob

i = ControlSpec.new(minval: 0.0, maxval: 10.0);
g = ControlSpec.new(minval: 0.0, maxval: 10.0);
p = ControlSpec.new(minval: 0.0, maxval: 1.0);
o = ControlSpec.new(minval: 0.0, maxval: 2.0);

~k0_inGain = EZKnob(w, Rect(30, 95, 80, 80), "Input gain", i, initVal: 1, layout: 'vert2');
~k1_gain = EZKnob(w, Rect(145,95, 80, 80), "Gain", g, initVal: 1, layout: 'vert2');
~k3_disThr = EZKnob(w, Rect(375,95, 80, 80), "Harshness",  p, initVal: 1, layout: 'vert2');
~k4_output_level = EZKnob(w, Rect(490, 95, 80, 80), "Output", o, initVal: 1, layout: 'vert2');

~k0_inGain.font = f;
~k1_gain.font = f;
~k3_disThr.font = f;
~k4_output_level.font = f;

// The input gain only change the amplitude of the selected input signal

~k0_inGain.action_({
	arg knob;
	~inGain = knob.value;
	// Changing the input gain we have to recalculate the gained input signal and the output one
	~inTf.waveFill({arg x, old, i; 2*x-1});
	~inTf = ~inTf * ~inGain;
	~myInBuffer.sendCollection(~inTf.asWavetableNoWrap);
	~gainedInputSignal = Shaper.ar(~myInBuffer, In.ar(~inputBus), 1, 0);
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

// The gain parameter change the slope of the transfer function

~k1_gain.action_({
	arg knob;
	// By touching this knob we are no more in one of the presets
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	// Now we have to recalculate the output signal according to the new gain paramenter
	~gain = knob.value;
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

// The threashold parameter governs the amplitude above the one the quadratic transfer function becomes quadratic and no more linear (0 means all quadratic, 1 means all linear till the clip value)

~k3_disThr.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;

	// If the selected transfer function is the quadratic one, the value is simply passed. If the linear transfer function is selected, the value of the knob and the variable is set to 1

	if((~dystTypeMenu.value == 1), {~thr = knob.value;}, {
		if(((~dystTypeMenu.value == 0)||(~dystTypeMenu.value == 2)), {knob.value = 1; ~thr = 1;}, {});
	});
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

// This knob simply scale the output signal in amplitude, without changing the shape in any way

~k4_output_level.action_({
	arg knob;
	~overdriveButton.value = 0;
	~fuzzButton.value = 0;
	~distorsionButton.value = 0;
	~outGain = knob.value;
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
});

// Styles buttons (presets)

~overdriveButton = Button(w, Rect(30, 200, 160, 40))
        .states_([
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~overdriveButton.font = f;

~distorsionButton = Button(w, Rect(220, 200, 160, 40))
        .states_([
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~distorsionButton.font = f;

~fuzzButton = Button(w, Rect(410, 200, 160, 40))
        .states_([
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~fuzzButton.font = f;

~overdriveButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 2; ~k3_disThr.value = 0.3; ~k4_output_level.value = 0.8; ~distorsionButton.value = 0; ~fuzzButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~dystTypeMenu.value = 1;
			if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
				~outputSignal = ~quadraticFunction.value;
			}, {
				if((~dystTypeMenu.value == 2), {
					~outputSignal = ~tanhFunction.value;
				}, {
					~outputSignal = ~foldbackFunction.value;
				});
			});
		};
)});

~distorsionButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 7; ~k3_disThr.value = 0; ~k4_output_level.value = 0.8; ~overdriveButton.value = 0; ~fuzzButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~dystTypeMenu.value = 1;
			if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
				~outputSignal = ~quadraticFunction.value;
			}, {
				if((~dystTypeMenu.value == 2), {
					~outputSignal = ~tanhFunction.value;
				}, {
					~outputSignal = ~foldbackFunction.value;
				});
			});
		};
)});

~fuzzButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 9; ~k3_disThr.value = 0.8; ~k4_output_level.value = 0.5; ~overdriveButton.value = 0; ~distorsionButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~dystTypeMenu.value = 1;
			if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
				~outputSignal = ~quadraticFunction.value;
			}, {
				if((~dystTypeMenu.value == 2), {
					~outputSignal = ~tanhFunction.value;
				}, {
					~outputSignal = ~foldbackFunction.value;
				});
			});
		};
)});

//Pop Up Menu - Distorsion Type

// Every time the output signal have to be calculated, a little if tree is implemented in order to select the proper transfer function according to this menu and the choise of the user

~dystTypeMenu = EZPopUpMenu.new(w, Rect(366, 260, 205, 20), "CURVE TYPE", layout: \horz);
~dystTypeMenu.addItem(\Linear, {"Linear".postln; ~k3_disThr.doAction;});
~dystTypeMenu.addItem(\Quadratic, {"Quadratic".postln; ~k3_disThr.doAction;});
~dystTypeMenu.addItem(\Hyperbolic_tangent, {"Hyperbolic tangent".postln; ~k3_disThr.doAction;});
~dystTypeMenu.addItem(\Foldback, {"Foldback".postln; ~k3_disThr.doAction;});
~dystTypeMenu.font_(Font("Kreon", 12));

//Pop Up Menu - Input choice

~inputMenuTitle = StaticText(w, Rect(32, 260, 90, 20)).string = "INPUT SOURCE";
~inputMenuTitle.font_(Font("Kreon", 11));
~inputMenu = PopUpMenu.new(w, Rect(118, 260, 100, 20));
~inputMenu.font_(Font("Kreon", 11));
~inputMenu.action = {~playButton.doAction};

// Wave scopes

// create three buffers in order to plot with ScopeOut2 and ScopeView

~inputBuffer = Buffer.alloc(s, 1024);
~outputBuffer = Buffer.alloc(s, 1024);
~xyBuffer = Buffer.alloc(s, 1024, 2);

// In this function the gaind input signal and the output signal are re-evaluated to be passet to the ScopeOut2.ar methods. Then the output signal is routed to the selected output bus in order to be heard

~sound = {
	~gainedInputSignal = Shaper.ar(~myInBuffer, In.ar(~inputBus));
	if(((~dystTypeMenu.value == 1)||(~dystTypeMenu.value == 0)), {
		~outputSignal = ~quadraticFunction.value;
	}, {
		if((~dystTypeMenu.value == 2), {
			~outputSignal = ~tanhFunction.value;
		}, {
			~outputSignal = ~foldbackFunction.value;
		});
	});
	ScopeOut2.ar(~gainedInputSignal, ~inputBuffer); // update input buffer
    ScopeOut2.ar(~outputSignal, ~outputBuffer); // update output buffer
	ScopeOut2.ar([~gainedInputSignal, ~outputSignal], ~xyBuffer); // update xy buffer
	Out.ar(~outBus, ~outputSignal);
}.play;

// Now we can finally use ScopeView

~inputScope = ScopeView(w,Rect(30,300,186,176)).server = s;
~inputScope.bufnum = ~inputBuffer.bufnum;
~inputScope.yZoom = 0.9; // only to properly align the scope to the transfer function
~inputScope.start;
~xyScope = ScopeView(w,Rect(222,300,156,176)).server = s;
~xyScope.bufnum = ~xyBuffer.bufnum;
~xyScope.style = 2;
~xyScope.start;
~outputScope = ScopeView(w,Rect(384,300,186,176)).server = s;
~outputScope.bufnum = ~outputBuffer.bufnum;
~outputScope.yZoom = 0.9; // only to properly align the scope to the transfer function
~outputScope.start;

~inputScopeName = StaticText(w,Rect(53, 435, 140, 100))
.string_("Clean waveform")
.align_(\center)
.font_(Font("Kreon", 12));
~xyScopeName = StaticText(w,Rect(230, 435, 140, 100))
.string_("Transfer function")
.align_(\center)
.font_(Font("Kreon", 12));
~outputScopeName = StaticText(w,Rect(407, 435, 140, 100))
.string_("Distorted waveform")
.align_(\center)
.font_(Font("Kreon", 12));

// Play/Stop button

~playButRect = Rect(275, 260, 50, 30);

// Main window mode buttons

// "Tutorial" button

~tutorialButton = Button(w, Rect(30, 25, 100, 30));
~tutorialButton.states_([
	["Tutorial mode", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
	["Tutorial mode", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
]);
~tutorialButton.action_({|butt|
	~playButton.value = 1; // we need to stop the current sound...
	~playButton.doAction; // ...
	if (butt.value==0,
		{
			w.background = ~wColor2;
			~iCanDoItButton.value = 1;
		},
		{
			w.background = ~wColor;
			~iCanDoItButton.value = 0;
			~tutorialw.front; // Tutorial mode explenation window
			~inputMenu.clear; // As before we update the input selection possibilities
			~inputMenu.items_(["Sinusoid", "Guitar mp3", "Voice mp3", "Bass mp3", "Sweet Home Alabama"]);
			~playButton = Button(w, ~playButRect)
			.states_([
				["Stop", Color.white, Color.new255(red: 111, green: 69, blue: 34, alpha: 255)],
				["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)]
			])
			.action_({|butt|
				if (butt.value==1,
					{
						~sinusoidSig.free;
						~guitarSig.free;
						~voiceSig.free;
						~bassSig.free;
						~alabamaSig.free;
						~micSig.free;
						~soundcardSig.free;
					},
					{if (~inputMenu.value==0,
						{
							~sinusoidSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
							~guitarSig.free;
							~voiceSig.free;
							~bassSig.free;
							~alabamaSig.free;
							~micSig.free;
							~soundcardSig.free;
						},
						{if(~inputMenu.value==1,
							{
								~sinusoidSig.free;
								~guitarSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
								~voiceSig.free;
								~bassSig.free;
								~alabamaSig.free;
								~micSig.free;
								~soundcardSig.free;
							},
							{if(~inputMenu.value==2,
								{
									~sinusoidSig.free;
									~guitarSig.free;
									~voiceSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
									~bassSig.free;
									~alabamaSig.free;
									~micSig.free;
									~soundcardSig.free;
								},
								{if(~inputMenu.value==3,
									{
										~sinusoidSig.free;
										~guitarSig.free;
										~voiceSig.free;
										~bassSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
										~alabamaSig.free;
										~micSig.free;
										~soundcardSig.free;
									},
									{
										~sinusoidSig.free;
										~guitarSig.free;
										~voiceSig.free;
										~bassSig.free;
										~alabamaSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value))}.play;
										~micSig.free;
										~soundcardSig.free;
									}
								)}
							)}
						)}
					)}
				)
			});
			~playButton.value = 1; // Start in "stop" mode
			~playButton.font_(Font("Kreon", 15));
		};
)});
~tutorialButton.font = f;
~tutorialw = Window("Tutorial mode", Rect(left: 650, top: 460, width: 600, height: 160), false);
~tutorialw.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
~tutorialw.alwaysOnTop = true;
~tutorialText = StaticText(~tutorialw, Rect(left: 20, top: 0, width: 560, height: 120));
~tutorialText.font_(Font("Kreon", 13));
~tutorialText.string =
"
                                                       TUTORIAL MODE

• Choose one audio file from the 'Input Source' menu.
• Switch between the four distorsion presets and change the parameters as you prefer.
• When you feel comfortable, switch to the 'I can do it' mode and try to distort some of your own sounds! Have fun!";
~gotItButton = Button(~tutorialw, Rect(275, 130, 50, 20));
~gotItButton.states_([
	["Got It"],
	["Got It"],
]);
~gotItButton.action_({|butt|
	if (butt.value==1,
		{~tutorialw.close;};
)});

// "I can do it" button (analogous behaviour of the "tutorial" one)

~iCanDoItButton = Button(w, Rect(470, 25, 100, 30))
        .states_([
            ["I can do it", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["I can do it", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~iCanDoItButton.font = f;
~iCanDoItButton.value = 0;
~iCanDoItButton.action_({|butt|
	~playButton.value = 1;
	~playButton.doAction;
	if (butt.value==0,
		{
			w.background = ~wColor;
			~tutorialButton.value = 1;
		},
		{
			w.background = ~wColor2;
			~tutorialButton.value = 0;
			~iCanDoItw.front;
			~inputMenu.clear;
			~inputMenu.items_(["Computer mic", "Soundcard"]);
			~playButton = Button(w, ~playButRect)
			.states_([
				["Stop", Color.white, Color.new255(red: 111, green: 69, blue: 34, alpha: 255)],
				["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)]
			])
			.action_({|butt|
				if (butt.value==1,
					{
						~sinusoidSig.free;
						~guitarSig.free;
						~voiceSig.free;
						~bassSig.free;
						~alabamaSig.free;
						~micSig.free;
						~soundcardSig.free;
					},
					{if (~inputMenu.value==0,
						{
							~sinusoidSig.free;
							~guitarSig.free;
							~voiceSig.free;
							~bassSig.free;
							~alabamaSig.free;
							~micSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value+5))}.play;
							~soundcardSig.free;
						},
						{
							~sinusoidSig.free;
							~guitarSig.free;
							~voiceSig.free;
							~bassSig.free;
							~alabamaSig.free;
							~micSig.free;
							~soundcardSig = {Out.ar(~inputBus, ~funcs.at(~inputMenu.value+5))}.play;
						}
					)}
				)
			});
			~playButton.value = 1;
			~playButton.font_(Font("Kreon", 15));
		};
)});
~iCanDoItw = Window("I can do it mode", Rect(left: 650, top: 460, width: 600, height: 130), false);
~iCanDoItw.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
~iCanDoItw.alwaysOnTop = true;
~tutorialText = StaticText(~iCanDoItw, Rect(left: 20, top: 0, width: 560, height: 80));
~tutorialText.font_(Font("Kreon", 13));
~tutorialText.string =
"
                                                       I CAN DO IT MODE

• Choose one audio input from the 'Input Source' menu.
• Start to play and adjust the parameters to reach the desired sound. Have fun!";
~gotItButton2 = Button(~iCanDoItw, Rect(275, 100, 50, 20));
~gotItButton2.states_([
	["Got It"],
	["Got It"],
]);
~gotItButton2.action_({|butt|
	if (butt.value==1,
		{~iCanDoItw.close;};
)});

// info window "Knob roles and Analog button"

~knobInfoButton = Button(w, Rect(30, 63, 25, 30))
        .states_([
            ["i", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)],
            ["i", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~knobInfoButton.font = (Font("Kreon", 25));
~knobInfoButton.action_({|butt|
	if (butt.value==1,
		{
			~infow = Window("Knobs roles", Rect(left: 325, top: 500, width: 320, height: 200), false);
			~infow.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
			~infow.alwaysOnTop = true;
			~infos = StaticText(~infow, Rect(left: 10, top: 0, width: 300, height: 170));
			~infos.string =
			"• INPUT KNOB: set the desired input volume.
• GAIN KNOB: this value represent the slope of the transfer function.
• HARSNESS KNOB: changes the shape of the quadratic portion of the transfer function. It's linked to the threashold where the linear part ends and the quadratic part starts:
    0 --> only quadratic shape
    1 --> only linear shape (clipper)
• OUTPUT KNOB: set the desired output volume.
• ANALOG BUTTON: introduce asymmetrical behaviours in the transfer function, typical of real analogue circuits.";
			~infow.front;
			~gotItButton = Button(~infow, Rect(135, 172, 50, 20));
			~gotItButton.states_([
				["Got It"],
				["Got It"],
			]);
			~gotItButton.action_({|butt|
				if (butt.value==1,
					{~knobInfoButton.value = 0; ~infow.close;};
		)})}
)});

)