s.reboot;

(
SynthDef(\scopes,{

	var inputSignal, outputSignal;
	// var inputBus, outputBus;
	var myBuffer, tf;

	var gain, thr;

	gain = 1.8;
	thr = 0.5;

	~inputBus = Bus.audio(s, 2);
	~outputBus = Bus.audio(s, 2);
	~xyBus = Bus.audio(s, 2);

	inputSignal = SinOsc.ar([220, 220], mul:1);

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
	//***************************************************************
	// Link to the GeoGebra site: https://www.geogebra.org/m/x5bhsngv
	//***************************************************************

	myBuffer = Buffer.alloc(s, 1024, 1);

	tf = Signal.newClear(513);
	tf.waveFill({arg x, old, i; 2*x-1}); // 0 < x_axis < 513    -1 < y_axis < 1
	tf.waveFill({arg x, old, i;  //    0 < x < 1    -1 < old < 1    0 < i < 512
		if((old>0),
			{// positive
				if((old<(thr/gain)),
					{// linear
						("linear pos"+"i ="+i).postln;
						old*gain
					},
					{if((old<((2-thr)/gain)),
						{// quatratic
							("quadratic pos"+"i ="+i).postln;
							((((old-((2-thr)/gain)).squared)*gain*gain)/(4*(thr-1)))+1
						},
						{// clip
							("clip pos"+"i ="+i).postln;
							1
					})
				})
			},
			{// negative
				if((old>((-1)*thr/gain)),
					{// linear
						("linear neg"+"i ="+i).postln;
						old*gain
					},
					{if((old>((thr-2)/gain)),
						{// quatratic
							("quadratic neg"+"i ="+i).postln;
							((((old-((thr-2)/gain)).squared)*gain*gain)/(4*(1-thr)))-1
						},
						{// clip
							("clip neg"+"i ="+i).postln;
							-1
					})
				})
			}
		)
	});

	tf.plot;

	myBuffer.sendCollection(tf.asWavetableNoWrap);

	outputSignal = Shaper.ar(myBuffer, inputSignal, 1, 0);

	//********************************************************
	Out.ar(~inputBus, inputSignal);
	Out.ar(~outputBus, outputSignal);
	Out.ar(~xyBus, [inputSignal.sum, outputSignal.sum]);

}).send(s);
)

(

var inputScope, outputScope, startButton, xyScope;
var mySynth = Synth(\scopes);

w = Window.new("my own scope", Rect(20, 20, 800, 400));
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
xyScope = Stethoscope.new(s, numChannels: 2, index: ~xyBus.index, view:w.view);
outputScope = Stethoscope.new(s, numChannels: 2, index: ~outputBus.index, view:w.view);
xyScope.style = 2;
w.onClose = { inputScope.free; outputScope.free; xyScope.free; };
w.front;

)

