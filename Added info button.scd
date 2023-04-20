s.reboot;

(

~quadraticFunction = {
	~inputSignal = SinOsc.ar(10, mul:~inputGain);
	// ~inputSignal = {SoundIn.ar(0, 1)};

	//********************************************************
	// Transfer functions
	//********************************************************

	// tanh behaviour
	/*
	~myPlot = {
		var a;
		a = Line.ar(-3, 3, 0.01);
		a.tanh
	}.plot

	~outputSignal = (gain * ~inputSignal).tanh;
	*/

	// Quadratic
	//***************************************************************
	// Link to the GeoGebra site: https://www.geogebra.org/m/x5bhsngv
	//***************************************************************

	// ~tf = Signal.newClear(513);
	~tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	~tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				if((old<(~thr/~gain)),
					{// linear
						// ("linear pos"+"i ="+i).postln;
						old*~gain
					},
					{if((old<((2-~thr)/~gain)),
						{// quatratic
							// ("quadratic pos"+"i ="+i).postln;
							((((old-((2-~thr)/~gain)).squared)*~gain*~gain)/(4*(~thr-1)))+1
						},
						{// clip
							// ("clip pos"+"i ="+i).postln;
							1
					})
				})
			},
			{// negative
				if((old>((-1)*~thr/~gain)),
					{// linear
						// ("linear neg"+"i ="+i).postln;
						old*~gain
					},
					{if((old>((~thr-2)/~gain)),
						{// quatratic
							// ("quadratic neg"+"i ="+i).postln;
							((((old-((~thr-2)/~gain)).squared)*~gain*~gain)/(4*(1-~thr)))-1
						},
						{// clip
							// ("clip neg"+"i ="+i).postln;
							-1
					})
				})
			}
		)
	});
	~tf = ~tf * ~outGain;
	// ~tf.plot;
	~myBuffer.sendCollection(~tf.asWavetableNoWrap);
	// ~myBuffer.plot;
	Shaper.ar(~myBuffer, ~inputSignal, 1, 0);
};

)

// Main window
(

var wRect;
var wColor;
f = Font ("Kreon", 12);
wRect = Rect(left: 650, top: 150, width: 600, height: 600);
w = Window("Distorsion", wRect, false);
~wColor = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
~wColor2 = Color.new255(red: 255, green: 165, blue: 0, alpha: 255);
w.background = ~wColor;
w.front;
w.alwaysOnTop = true;
~effectName = StaticText(w,Rect(150, 15, 300, 50))
.string_("DISTEACHER")
.align_(\center)
.font_(Font("Kreon", 40));

)

(

~inputBus = Bus.audio(s);
~outputBus = Bus.audio(s);
~xyBus = Bus.audio(s);
~myBuffer = Buffer.alloc(s, 1024, 1);

)

(

~mySynth = SynthDef(\scopes,{
	~gain = 1;
	~thr = 1;
	~outGain = 1.0;
	~inputGain = 1.0;
	~outputSignal = ~quadraticFunction.value;
	Out.ar(~inputBus, ~inputSignal);
	Out.ar(~outputBus, ~outputSignal);
	Out.ar(~xyBus, [~inputSignal, ~outputSignal]);
}).play;

)

// Wave scopes
(

// For the following code I followed this example: https://subscription.packtpub.com/book/application-development/9781783289677/1/ch01lvl1sec09/scoping-signals and this updated version: https://gist.github.com/gusano/e961e0ce67b09fea80e9

// create two buffer in order to plot with ScopeOut2 and ScopeView.
~inputBuffer = Buffer.alloc(s, 1024);
~outputBuffer = Buffer.alloc(s, 1024);
~xyBuffer = Buffer.alloc(s, 1024, 2);
~sound = { //trial sound
	~inputSignal = SinOsc.ar(10, mul:~inputGain);
	~outputSignal = ~quadraticFunction.value;
	ScopeOut2.ar(~inputSignal, ~inputBuffer); // update first buffer
    ScopeOut2.ar(~outputSignal, ~outputBuffer); // update second buffer
	ScopeOut2.ar([~inputSignal, ~outputSignal], ~xyBuffer); // update second buffer
  }.play;

//By using ScopeView, we need to use buffers and ScopeOut2 -> see ScopeView examples in the search section.
~inputScope = ScopeView(w,Rect(40,400,180,176)).server = s;
~inputScope.bufnum = ~inputBuffer.bufnum;
~inputScope.start;
~xyScope = ScopeView(w,Rect(222,400,156,176)).server = s;
~xyScope.bufnum = ~xyBuffer.bufnum;
~xyScope.style = 2;
~xyScope.start;
~outputScope = ScopeView(w,Rect(380,400,180,176)).server = s;
~outputScope.bufnum = ~outputBuffer.bufnum;
~outputScope.start;

~inputScopeName = StaticText(w,Rect(60, 535, 140, 100))
.string_("Clean waveform")
.align_(\center)
.font_(Font("Kreon", 12));
~xyScopeName = StaticText(w,Rect(230, 535, 140, 100))
.string_("Transfer function")
.align_(\center)
.font_(Font("Kreon", 12));
~outputScopeName = StaticText(w,Rect(400, 535, 140, 100))
.string_("Distorted waveform")
.align_(\center)
.font_(Font("Kreon", 12));

/*
inputFreqScope = FreqScopeView(w, Rect(0, 300, 370, 200));
outputFreqScope = FreqScopeView(w, Rect(370, 300, 370, 200));
inputFreqScope.active_(true);
outputFreqScope.active_(true);
inputFreqScope.freqMode_(1);
outputFreqScope.freqMode_(1);
inputFreqScope.inBus_(~inputBus);
outputFreqScope.inBus_(~outputBus);
*/

w.onClose = {(
	~sound.stop;
	~inputBuffer.free;
	~outputBuffer.free;
	~xyBuffer.free;
	~inputScope.stop;
	~outputScope.stop;
	~xyScope.stop;
)};

)

// Knobs
(

i = ControlSpec.new(minval: 0.0, maxval: 10.0);
t = ControlSpec.new(minval: 0.0, maxval: 1.0);
p = ControlSpec.new(minval: 0.0, maxval: 1.0);
o = ControlSpec.new(minval: 0.0, maxval: 2.0);
~k1_gain = EZKnob(w, Rect(100,95, 80, 80), "Gain", i, initVal: 1, layout: 'vert2');
~k2_tone = EZKnob(w, Rect(210, 95, 80, 80), "Tone", t, initVal: 0.5, layout: 'vert2');
~k3_disThr = EZKnob(w, Rect(320,95, 80, 80), "Harshness",  p, initVal: 1, layout: 'vert2');
~k4_output_level = EZKnob(w, Rect(430, 95, 80, 80), "Output", o, initVal: 1, layout: 'vert2');
~k1_gain.font = f;
~k2_tone.font = f;
~k3_disThr.font = f;
~k4_output_level.font = f;

~k1_gain.action_({
	arg knob;
	~gain = knob.value;
	~outputSignal = ~quadraticFunction.value;
});

~k3_disThr.action_({
	arg knob;
	~thr = knob.value;
	~outputSignal = ~quadraticFunction.value;
});

~k4_output_level.action_({
	arg knob;
	~outGain = knob.value;
	~outputSignal = ~quadraticFunction.value;
});

)

// Styles buttons
(

~overdriveButton = Button(w, Rect(30, 200, 160, 40))
        .states_([
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~overdriveButton.font = f;

~distorsionButton = Button(w, Rect(220, 200, 160, 40))
        .states_([
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~distorsionButton.font = f;

~fuzzButton = Button(w, Rect(410, 200, 160, 40))
        .states_([
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~fuzzButton.font = f;

~overdriveButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 2; ~k2_tone.value = 0.7; ~k3_disThr.value = 0.3; ~k4_output_level.value = 0.8; ~distorsionButton.value = 0; ~fuzzButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~outputSignal = ~quadraticFunction.value;
		};
)});

~distorsionButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 7; ~k2_tone.value = 1; ~k3_disThr.value = 0; ~k4_output_level.value = 0.8; ~overdriveButton.value = 0; ~fuzzButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~outputSignal = ~quadraticFunction.value;
		};
)});

~fuzzButton.action_({|me|
	if (me.value == 1,
		{
			~k1_gain.value = 9; ~k2_tone.value = 1; ~k3_disThr.value = 0.8; ~k4_output_level.value = 0.5; ~overdriveButton.value = 0; ~distorsionButton.value = 0;
			~gain = ~k1_gain.value; ~thr = ~k3_disThr.value; ~outGain = ~k4_output_level.value;
			~outputSignal = ~quadraticFunction.value;
		};
)});

)

//Pop Up Menu - Distorsion Type
(

m = EZPopUpMenu.new(w, Rect(225, 342, 120, 40), "CURVE TYPE", layout: \vert);
m.addItem(\Quadratic, {"this is item 0". postln});
m.addItem(\Hyperbolic_tangent, {"this is item 1". postln});
m.addItem(\item2, {"this is item 2". postln});
m.addItem(\item4, {"this is item 4". postln});
m.font_(Font("Kreon", 12));

)

//Pop Up Menu - Input choice
(

~inputMenu = EZPopUpMenu.new(w, Rect(40, 342, 120, 40), "INPUT SOURCE", layout: \vert);
~inputMenu.addItem(\Guitar_mp3, {"this is item 0". postln});
~inputMenu.addItem(\Voice_mp3, {"this is item 1". postln});
~inputMenu.font_(Font("Kreon", 11));

)


// Mode Buttons
(
~tutorialButton = Button(w, Rect(35, 25, 100, 30));
~tutorialButton.states_([
            ["Tutorial mode", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Tutorial mode", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~tutorialButton.action_({|butt|
	butt.value.postln;
	if (butt.value==0,
		{
			w.background = ~wColor2;
			~iCanDoItButton.value = 1;
		},
		{
			w.background = ~wColor;
			~iCanDoItButton.value = 0;
			~tutorialw.front;
			~inputMenu.replaceItemAt(0, \Guitar_mp3, {"Item 0  replaced".postln});
			~inputMenu.replaceItemAt(1, \Voice_mp3, {"Item 1 replaced".postln});
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

• Choose one audio file from the 'Input Souce' menu.
• Switch between the three distorsion presets and change the parameters as you prefer.
• When you feel comfortable, switch to the 'I can do it' mode and try to distort some of your own sounds! Have fun!";

~gotItButton = Button(~tutorialw, Rect(275, 130, 50, 20));
			~gotItButton.states_([
            ["Got It"],
            ["Got It"],
        ]);
~gotItButton.action_({|butt|
				butt.value.postln;
				if (butt.value==1,
					{~tutorialw.close;};
		)});


~iCanDoItButton = Button(w, Rect(455, 25, 100, 30))
        .states_([
            ["I can do it", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["I can do it", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~iCanDoItButton.font = f;
~iCanDoItButton.value = 0;
~iCanDoItButton.action_({|butt|
	butt.value.postln;
	if (butt.value==1,
	{
			w.background = ~wColor2;
			~tutorialButton.value = 0;
			~inputMenu.replaceItemAt(0, \Computer_mic, {"Item 0  replaced".postln});
			~inputMenu.replaceItemAt(1, \Soundcard, {"Item 1 replaced".postln});
			~iCanDoItw.front;
	},
	{w.background = ~wColor; ~tutorialButton.value = 1};
)});
~iCanDoItw = Window("I can do it mode", Rect(left: 650, top: 460, width: 600, height: 160), false);
			~iCanDoItw.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
			~iCanDoItw.alwaysOnTop = true;
			~tutorialText = StaticText(~iCanDoItw, Rect(left: 20, top: 0, width: 560, height: 120));
            ~tutorialText.font_(Font("Kreon", 13));
			~tutorialText.string =
"
                                                                   I CAN DO IT MODE

• Choose one audio input from the 'Input Souce' menu.
• Start to play and adjust the parameters to reach the desired sound. Have fun!";
~gotItButton2 = Button(~iCanDoItw, Rect(275, 130, 50, 20));
			~gotItButton2.states_([
            ["Got It"],
            ["Got It"],
        ]);
~gotItButton2.action_({|butt|
				butt.value.postln;
				if (butt.value==1,
					{~iCanDoItw.close;};
		)});
)

// Window "Knob roles"
(
~knobInfoButton = Button(w, Rect(40, 90, 25, 30))
        .states_([
            ["i", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["i", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~knobInfoButton.font = (Font("Kreon", 25));
~knobInfoButton.action_({|butt|
	butt.value.postln;
	if (butt.value==1,
		{
			7.postln;
			~infow = Window("Knobs roles", Rect(left: 325, top: 500, width: 320, height: 180), false);
			~infow.background = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
			~infow.alwaysOnTop = true;
			~infos = StaticText(~infow, Rect(left: 10, top: 0, width: 300, height: 150));
			//~infos.allign = \top;
			//~infos.font = Font("Kreon", 9);
			~infos.string =
			"• GAIN KNOB: this value represent the slope of the linear portion of the transfer function.

• TONE KNOB: frequency filter that helps you to shape the desired sound. Set it at a low value if you want a mellower and bassy sound, set it high if you want a richer and full of highs sound.

• HARSNESS KNOB:

• OUTPUT KNOB: set the desired output volume.";
			~infow.front;
			~gotItButton = Button(~infow, Rect(135, 152, 50, 20));
			~gotItButton.states_([
            ["Got It"],
            ["Got It"],
        ]);
			~gotItButton.action_({|butt|
				butt.value.postln;
				if (butt.value==1,
					{~knobInfoButton.value = 0; ~infow.close;};
		)})}
)});

)