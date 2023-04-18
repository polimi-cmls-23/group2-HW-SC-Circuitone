s.reboot;

(

~inputBus = Bus.audio(s, 2); // define bus with 2 channels
~outputBus = Bus.audio(s, 2);
~xyBus = Bus.audio(s, 2);
~myBuffer = Buffer.alloc(s, 1024, 1);
// ~inputSignal = SinOsc.ar([220, 220], mul:1);
// ~outputSignal = Signal.new;

)


(
~mySynth = SynthDef(\scopes,{

	var inputSignal, outputSignal;
	// var outputSignal;
	// var inputBus, outputBus;
	var tf;

	var gain, thr;

	gain = 2;
	thr = 0.4;


	 inputSignal = SinOsc.ar([220, 220], mul:1);
	// inputSignal = SoundIn.ar(0,2);

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
	outputSignal = (gain * inputSignal).tanh;
	*/

	// Quadratic
	//***************************************************************
	// Link to the GeoGebra site: https://www.geogebra.org/m/x5bhsngv
	//***************************************************************

	// myBuffer = Buffer.alloc(s, 1024, 1);

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

	// tf.plot;

	~myBuffer.sendCollection(tf.asWavetableNoWrap);

	// ~myBuffer.plot;

	outputSignal = Shaper.ar(~myBuffer, inputSignal, 1, 0);

	//********************************************************
	Out.ar(~inputBus, inputSignal);
	Out.ar(~outputBus, outputSignal);
	Out.ar(~xyBus, [inputSignal.sum, outputSignal.sum]);

}).send(s);
)

(

var inputScope, outputScope, startButton, xyScope, inputFreqScope, outputFreqScope;
// var mySynth = Synth(\scopes);
~mySynth.play(s);

w = Window.new("my own scope", Rect(20, 20, 800, 500));
w.view.decorator = FlowLayout(w.view.bounds);

inputScope = Stethoscope.new(s, numChannels: 2, index: ~inputBus.index, view:w.view);
xyScope = Stethoscope.new(s, numChannels: 2, index: ~xyBus.index, view:w.view);
outputScope = Stethoscope.new(s, numChannels: 2, index: ~outputBus.index, view:w.view);
inputFreqScope = FreqScopeView(w, Rect(0, 300, 370, 200));
outputFreqScope = FreqScopeView(w, Rect(370, 300, 370, 200));
inputFreqScope.active_(true);
outputFreqScope.active_(true);
inputFreqScope.freqMode_(1);
outputFreqScope.freqMode_(1);
inputFreqScope.inBus_(~inputBus);
outputFreqScope.inBus_(~outputBus);

xyScope.yZoom = 0.4;
xyScope.style = 2;

w.onClose = {
	inputScope.free;
	outputScope.free;
	xyScope.free;
	inputFreqScope.kill;
	outputFreqScope.kill;
	~myBuffer.free;
	~inputBus.free;
	~outputBus.free;
	~xyBus.free;
	// ~inputSignal.free;
	// ~outputSignal.free;
	~mySynth.free;
};

w.front;

)