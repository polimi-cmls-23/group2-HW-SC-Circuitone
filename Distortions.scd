s.reboot;

(
SynthDef(\scopes,{

	var inputSignal, outputSignal;
	// var inputBus, outputBus;
	var myBuffer, tf;

	var gain;

	gain = 10;

	~inputBus = Bus.audio(s, 2);
	~outputBus = Bus.audio(s, 2);

	inputSignal = SinOsc.ar([220, 440], mul:0.5);

	//********************************************************
	// Transfer functions

	// tanh behaviour
	/*
	~myPlot = {
		var a;
		a = Line.ar(-3, 3, 0.01);
		a.tanh
	}.plot

	outputSignal = (gain * inputSignal).tanh;
	*/

	// Quadratic

	myBuffer = Buffer.alloc(s, 1024, 1);
	tf = Signal.fill(513, { |i| i.linlin(85.0, 427.0, -1, 1)}).normalizeTransfer;
	tf.plot;

	myBuffer.sendCollection(tf.asWavetableNoWrap);

	outputSignal = Shaper.ar(myBuffer, inputSignal, 1, 0);

	//********************************************************
	Out.ar(~inputBus, inputSignal);
	Out.ar(~outputBus, outputSignal);

}).send(s);
)

(

var inputScope, outputScope, startButton;
var mySynth = Synth(\scopes);

w = Window.new("my own scope", Rect(20, 20, 600, 400));
w.view.decorator = FlowLayout(w.view.bounds);
/*
startButton = Button(w, Rect(20, 20, 340, 30))
.states_([
	["play", Color.black, Color.green],
	["stop", Color.black, Color.red]
])
.action_({ arg butt;
	if(butt.value == 0, mySynth.run(false), mySynth.run(true));
});
*/
inputScope = Stethoscope.new(s, numChannels: 2, index: ~inputBus.index, view:w.view);
outputScope = Stethoscope.new(s, numChannels: 2, index: ~outputBus.index, view:w.view);
w.onClose = { inputScope.free; outputScope.free; };
w.front;

)