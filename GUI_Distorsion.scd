s.boot;

/* Colors codes
light_green = Color.new255(red: 169, green: 211, blue: 134, alpha: 255);
dark_blue = Color.new255(red: 47, green: 72, blue: 88, alpha: 255);
c3 = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
*/

// Main window

(
var wRect;
var wColor;
f = Font ("Kreon", 12);
wRect = Rect(left: 300, top: 100, width: 600, height: 600);
w = Window("Distorsion", wRect, false);
wColor = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
w.background = wColor;
w.front;
w.alwaysOnTop = true;
~effectName = StaticText(w,Rect(150, 15, 300, 50))
.string_("DISTEACHER")
.align_(\center)
.font_(Font("Kreon", 40));
)


// Knobs
(
var k1_input_level;
var k2_tone;
var k3_disType;
var k4_output_level;
o = ControlSpec.new(minval: 0.0, maxval: 10.0);
i = ControlSpec.new(minval: 0.0, maxval: 10.0);
t = ControlSpec.new(minval: 0.0, maxval: 1.0);
p = ControlSpec.new(minval: 0.0, maxval: 1.0);
k1_input_level = EZKnob(w, Rect(100,95, 80, 80), "Input", i, layout: 'vert2');
k2_tone = EZKnob(w, Rect(210, 95, 80, 80), "Tone", t, layout: 'vert2');
k3_disType = EZKnob(w, Rect(320,95, 80, 80), "Type",  p, layout: 'vert2');
k4_output_level = EZKnob(w, Rect(430, 95, 80, 80), "Output", o, layout: 'vert2');
k1_input_level.font = f;
k2_tone.font = f;
k3_disType.font = f;
k4_output_level.font = f;
)


// Styles buttons
(
a = Button(w, Rect(30, 200, 160, 40))
        .states_([
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Steve Ray Vaughan
(Overdrive)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
a.font = f;
b = Button(w, Rect(220, 200, 160, 40))
        .states_([
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["AC/DC
(Distorsion)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
b.font = f;
c = Button(w, Rect(410, 200, 160, 40))
        .states_([
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["Matt Bellamy
(Fuzz)", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
c.font = f;
)


// Wave scopes, do not work :(
(
// For the following code I followed this example: https://subscription.packtpub.com/book/application-development/9781783289677/1/ch01lvl1sec09/scoping-signals
  var sound = {
    var signal = Resonz.ar(
      [ ClipNoise.ar(1.7), ClipNoise.ar(1.8) ],
      SinOsc.ar(1000).range(100,500)); // a stereo signal
    ScopeOut.ar(signal, bufferA); // update first buffer
    ScopeOut.ar(signal, bufferB); // update second buffer
    Out.ar(0,signal); // write to output
  }.play;
~buffC = Buffer.alloc(s, s.sampleRate); // create two buffer in order to plot with ScopeOut2 and ScopeView.
~buffD = Buffer.alloc(s, s.sampleRate);
ScopeOut2.ar(SinOsc.ar(), ~buffC);
ScopeOut2.ar(SinOsc.ar(110), ~buffD);
c = ScopeView(w,Rect(33,370,250,200)).server = s; //By using ScopeView, we need to use buffers and ScopeOut2 -> see ScopeView examples in the search section.
c.bufnum = (~buffC.bufnum);
c.start;
d = ScopeView(w,Rect(321,370,250,200)).server = s;
d.bufnum =(~buffD.bufnum);
d.start;
~inputScopeName = StaticText(w,Rect(110, 535, 100, 100))
.string_("Clean waveform")
.font_(Font("Kreon", 12));
~outputcopeName = StaticText(w,Rect(400, 535, 100, 100))
.string_("Distorted waveform")
.align_(\center)
.font_(Font("Kreon", 12));
w.onClose_(
	~buffC.free;
	~buffD.free;
	c.stop;
	d.stop;
);
)

//Pop Up Menu - Distorsion Type
(
m = EZPopUpMenu.new(w, Rect(310, 342, 205, 20), "CURVE TYPE", layout: \horz);
m.addItem(\Quadratic, {"this is item 0". postln});
m.addItem(\Hyperbolic_tangent, {"this is item 1". postln});
m.addItem(\item2, {"this is item 2". postln});
m.addItem(\item4, {"this is item 4". postln});
m.font_(Font("Kreon", 12));
)

//Pop Up Menu - Input choice
(
m = EZPopUpMenu.new(w, Rect(29, 342, 200, 20), "INPUT SOURCE", layout: \horz);
m.addItem(\Soundcard, {"this is item 0". postln});
m.addItem(\Computer_mic, {"this is item 1". postln});
m.addItem(\Guitar_mp3, {"this is item 2". postln});
m.addItem(\Voice_mp3, {"this is item 4". postln});
m.font_(Font("Kreon", 11));
)

// Curve button
(
var curve_button;
curve_button = Button(w, Rect(522, 338, 45, 30))
        .states_([
            ["SHOW ME
THE CURVE", Color.white, Color.new255(red: 169, green: 211, blue: 134, alpha: 255)],
            ["SHOW ME
THE CURVE", Color.white, Color.new255(red: 47, green: 72, blue: 88, alpha: 255)],
        ]);
curve_button.font_(Font("Kreon", 8));
)
