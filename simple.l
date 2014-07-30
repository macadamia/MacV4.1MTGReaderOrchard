panel name: simple
background: 0
size: 400 600

type: SLIDER
name: Initial Lambda
colors: 7 1
origin: 201 379
min/max: 20 65
value: 30
message: d INITLAM %d 100

type: SLIDER
name: Target Lambda
colors: 7 1
origin: 195 425
min/max: 45 65
value: 50
message: d TARGLAM %d 100

type: SLIDER
name: Transition Delay
colors: 7 1
origin: 190 523
min/max: 0 20
value: 5
message: d DELAY %d 1

type: SLIDER
name: Transition Period
colors: 7 1
origin: 193 469
min/max: 0 10
value: 0
message: d TRANSITION %d 1

type: SLIDER
name: Gravitropism
colors: 7 1
origin: 11 132
min/max: -150 300
value: 60
message: d TROPISM %d 100

type: SLIDER
name: Phototropism
colors: 7 1
origin: 11 183
min/max: 0 200
value: 102
message: d REORIENT %d 100

type: SLIDER
name: Shadow Strength
colors: 7 1
origin: 205 173
min/max: 10 200
value: 90
message: d STRENGTH %d 100

type: SLIDER
name: Shadow Fade
colors: 7 1
origin: 205 125
min/max: 10 200
value: 110
message: d FADE %d 10

type: LABEL
name: Lambda Parameters
color: 7
origin: 191 572

type: LABEL
name: Behaviour
color: 7
origin: 47 240

type: LABEL
name: LightModel
color: 7
origin: 236 344

type: SLIDER
name: Branch Drop Threshold
colors: 7 1
origin: 16 281
min/max: 0 100
value: 52
message: d DROPTHRESH %d 100

type: SLIDER
name: Size of Light Model
colors: 7 1
origin: 199 283
min/max: 100 1000
value: 600
message: d VOXSIZE %d 1

type: SLIDER
name: Density (must be odd number)
colors: 7 1
origin: 203 225
min/max: 1 301
value: 99
message: d DENSITY %d 1

type: LABEL
name: Structural
color: 7
origin: 39 436

type: SLIDER
name: Minimum Vigor for growth
colors: 7 1
origin: 10 381
min/max: 10 100
value: 37
message: d MINNODES %d 10

type: SLIDER
name: Light Conversion Factor
colors: 7 1
origin: 12 331
min/max: 10 100
value: 39
message: d LIGHTFACTOR %d 10

type: SLIDER
name: Linearity of Response
colors: 7 1
origin: 18 13
min/max: 10 100
value: 10
message: d NONLINEAR %d 10

type: SLIDER
name: Tropism Elasticity
colors: 7 1
origin: 18 70
min/max: 10 100
value: 10
message: d TROPISMELASTICITY %d 100

type: LABEL
name: Run parameters
color: 7
origin: 26 575

type: SLIDER
name: Number of Flushes
colors: 7 1
origin: 7 523
min/max: 1 20
value: 12
message: d FLUSHES %d 1

type: SLIDER
name: Create MTG at which Flush
colors: 7 1
origin: 10 472
min/max: 1 20
value: 20
message: d XYZFLUSH %d 1
