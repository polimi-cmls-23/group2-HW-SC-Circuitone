s.reboot;

(

~inputBus = Bus.audio(s);

~sig1 = {SinOsc.ar(100, 0, 0.3)};
~sig2 = {In.ar(2,1)};
~sig3 = {SinOsc.ar(440, 0, 0.5)};

~funcs = [~sig1, ~sig2, ~sig3];

f = Font ("Kreon", 12);
~wRect = Rect(left: 650, top: 150, width: 200, height: 200);
w = Window("Distorsion", ~wRect, false);
w.background = Color.new255(red: 251, green: 236, blue: 136, alpha: 255);
w.alwaysOnTop = true;
w.front;
w.onClose = {(
	~inputBus.free;
	~playing1.free;
	~playing2.free;
	~playing3.free;
)};

~inputBus.scope;

~menu = PopUpMenu(w, Rect(50, 60, 100, 30))
.items_(["Sin 100", "Mic", "Sin 440"])
.action_({|item|
	if (~stopButton.value==0,
		{
			if (item.value==1,
				{
					~playing1 = {Out.ar(~inputBus, ~funcs.at(item.value))}.play;
					~playing2.free;
					~playing3.free;
				},
				{
					if(item.value==2,
						{
							~playing1.free;
							~playing2 = {Out.ar(~inputBus, ~funcs.at(item.value))}.play;
							~playing3.free;
						},
						{
							~playing1.free;
							~playing2.free;
							~playing3 = {Out.ar(~inputBus, ~funcs.at(item.value))}.play;
					})
				}
			)
		},
		{}
	)

});
~menu.font_(Font("Kreon", 15));

~stopButton = Button(w, Rect(50, 110, 100, 30))
.states_([
	["Stop", Color.white, Color.new255(red: 111, green: 69, blue: 34, alpha: 255)],
	["Play", Color.white, Color.new255(red: 69, green: 111, blue: 34, alpha: 255)]
])
.action_({|butt|
	if (butt.value==1,
		{
			~playing1.free;
			~playing2.free;
			~playing3.free;
			// ~stopButton.value = 0;
		},
		{
			if (~menu.value==1,
				{
					~playing1 = {Out.ar(~inputBus, ~funcs.at(~menu.value))}.play;
					~playing2.free;
					~playing3.free;
				},
				{
					if(~menu.value==2,
						{
							~playing1.free;
							~playing2 = {Out.ar(~inputBus, ~funcs.at(~menu.value))}.play;
							~playing3.free;
						},
						{
							~playing1.free;
							~playing2.free;
							~playing3 = {Out.ar(~inputBus, ~funcs.at(~menu.value))}.play;
					})

				}
			)
		}
	)
});
~stopButton.font_(Font("Kreon", 15));

)