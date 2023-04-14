s.boot;

/* Colors codes
light_green = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
dark_blue = Color.new255(red: 47, green: 72, blue: 88, alpha: 255);
c3 = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
*/

// Main window
(
f = Font ("Kreon", 12);
~wRect = Rect(left: 300, top: 100, width: 600, height: 600);
~window = Window("Distorsion", ~wRect, false);
~wColor = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
~window.background = ~wColor;
~window.front;
~window.alwaysOnTop = true;
~effectName = StaticText(~window,Rect(150, 15, 300, 50))
.string_("DISTEACHER")
.align_(\center)
.font_(Font("Kreon", 40));
)

// Mode Buttons
(
~tutorialButton = Button(~window, Rect(35, 25, 100, 30));
~tutorialButton.states_([
            ["Tutorial mode", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Tutorial mode", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~tutorialButton.action_({|butt|
	butt.value.postln;
	if (butt.value==0,
	{~window.background = Color.new255(red: 0, green: 236, blue: 136, alpha: 255); ~onmyownButton.value = 1},
	{~window.background = ~wColor; ~onmyownButton.value = 0; ~inputMenu.value = 2};
)});

~tutorialButton.font = f;
~onmyownButton = Button(~window, Rect(455, 25, 100, 30))
        .states_([
            ["I can do it", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["I can do it", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~onmyownButton.font = f;
~onmyownButton.value = 0;
~onmyownButton.action_({|butt|
	butt.value.postln;
	if (butt.value==1,
	{~window.background = Color.new255(red: 0, green: 236, blue: 136, alpha: 255); ~tutorialButton.value = 0; ~inputMenu.value = 0},
	{~window.background = ~wColor; ~tutorialButton.value = 1};
)});
)

// Knobs
(
o = ControlSpec.new(minval: 0.0, maxval: 10.0);
i = ControlSpec.new(minval: 0.0, maxval: 10.0);
t = ControlSpec.new(minval: 0.0, maxval: 1.0);
p = ControlSpec.new(minval: 0.0, maxval: 1.0);
~inputKnob = EZKnob(~window, Rect(100,95, 80, 80), "Input", i, layout: 'vert2');
~toneKnob = EZKnob(~window, Rect(210, 95, 80, 80), "Tone", t, layout: 'vert2');
~typeKnob = EZKnob(~window, Rect(320,95, 80, 80), "Type",  p, layout: 'vert2');
~outputKnob = EZKnob(~window, Rect(430, 95, 80, 80), "Output", o, layout: 'vert2');
~inputKnob.font = f;
~toneKnob.font = f;
~typeKnob.font = f;
~outputKnob.font = f;
)


// Styles buttons
(
~overdriveButton = Button(~window, Rect(30, 200, 160, 40))
        .states_([
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~overdriveButton.font = f;

~distorsionButton = Button(~window, Rect(220, 200, 160, 40))
        .states_([
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~distorsionButton.font = f;

~fuzzButton = Button(~window, Rect(410, 200, 160, 40))
        .states_([
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
~fuzzButton.font = f;

~overdriveButton.action_({|me|
	me.value.postln;
	if (me.value == 1,
		{~inputKnob.value = 3.5; ~toneKnob.value = 0.7; ~typeKnob.value = 0.3; ~outputKnob.value = 5; ~distorsionButton.value = 0; ~fuzzButton.value = 0};
)});

~distorsionButton.action_({|me|
	me.value.postln;
	if (me.value == 1,
		{~inputKnob.value = 7; ~toneKnob.value = 0.7; ~typeKnob.value = 0.5; ~outputKnob.value = 5; ~overdriveButton.value = 0; ~fuzzButton.value = 0};
)});

~fuzzButton.action_({|me|
	me.value.postln;
	if (me.value == 1,
		{~inputKnob.value = 9; ~toneKnob.value = 0.7; ~typeKnob.value = 0.8; ~outputKnob.value = 5; ~overdriveButton.value = 0; ~distorsionButton.value = 0};
)});
)


// Wave scopes
(
// For the following code I followed this example: https://subscription.packtpub.com/book/application-development/9781783289677/1/ch01lvl1sec09/scoping-signals and this updated version: https://gist.github.com/gusano/e961e0ce67b09fea80e9

~buffC = Buffer.alloc(s, s.sampleRate); // create two buffer in order to plot with ScopeOut2 and ScopeView.
~buffD = Buffer.alloc(s, s.sampleRate);
  ~sound = { //trial sound
	~signal = SinOsc.ar([110,  164.81], 0.3); // a stereo signal
    ScopeOut2.ar(~signal, ~buffC); // update first buffer
    ScopeOut2.ar(~signal, ~buffD); // update second buffer
    Out.ar(0,~signal); // write to output
  }.play;
c = ScopeView(~window,Rect(33,370,250,200)).server = s; //By using ScopeView, we need to use buffers and ScopeOut2 -> see ScopeView examples in the search section.
c.bufnum = (~buffC.bufnum);
c.start;
d = ScopeView(~window,Rect(321,370,250,200)).server = s;
d.bufnum =(~buffD.bufnum);
d.start;
~inputScopeName = StaticText(~window, Rect(110, 535, 100, 100))
.string_("Clean waveform")
.font_(Font("Kreon", 12));
~outputcopeName = StaticText(~window, Rect(400, 535, 100, 100))
.string_("Distorted waveform")
.font_(Font("Kreon", 12));
w.onClose = {(
	~sound.stop;
	~buffC.free;
	~buffD.free;
	c.stop;
	d.stop;
)};
)

//Pop Up Menu - Distorsion Type
(
~curveMenu = EZPopUpMenu.new(~window, Rect(310, 342, 205, 20), "CURVE TYPE", layout: \horz);
~curveMenu.addItem(\Quadratic, {"this is item 0". postln});
~curveMenu.addItem(\Hyperbolic_tangent, {"this is item 1". postln});
~curveMenu.addItem(\item2, {"this is item 2". postln});
~curveMenu.addItem(\item4, {"this is item 4". postln});
~curveMenu.font_(Font("Kreon", 12));
)

//Pop Up Menu - Input choice
(
~inputMenu = EZPopUpMenu.new(~window, Rect(29, 342, 200, 20), "INPUT SOURCE", layout: \horz);
~inputMenu.addItem(\Soundcard, {"this is item 0". postln});
~inputMenu.addItem(\Computer_mic, {"this is item 1". postln});
~inputMenu.addItem(\Guitar_mp3, {"this is item 2". postln});
~inputMenu.addItem(\Voice_mp3, {"this is item 4". postln});
~inputMenu.font_(Font("Kreon", 11));
~inputMenu.value = 2;
)

// Curve button
(
var curve_button;
curve_button = Button(~window, Rect(522, 338, 45, 30))
        .states_([
            ["SHOW ME
THE CURVE", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["SHOW ME
THE CURVE", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
curve_button.font_(Font("Kreon", 8));
)





