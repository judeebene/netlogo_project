

extensions [array py ]



;-----------------------------------------------------------------
; Agent vars
; patch-value holds an important value used in learning algorithm
; patches-own gives all patches this variable
; breed defines different types of turtles, allowing for seperate use.
;-----------------------------------------------------------------
patches-own [patch-value ptimer]
globals [mouse-inactive reward patch-average]
breed [TDturtles TDturtle]
breed [AutoCars autocar]
breed [Parks park]
Autocars-own [value-holder]


;-----------------------------------------------------------------
; setup
; Initial values being set and clearing of the simulation
; Resets all values
;-----------------------------------------------------------------
to setup
  clear-all
  set mouse-inactive true
  ;if user-set home is false, provides random integar values.
  if home-location? = false [
    set set-x int random-xcor
    set set-y int random-ycor
  ]

  ;turtle creation with x y coords
  create-TDturtles number-of-cars [set shape "car" set color blue set size 1 setxy set-x set-y]
  create-Parks 1 [set shape "house" set color white set size 1 setxy set-x set-y]

  ;ensure clean board
  reset-ticks

  ;tells the patches to set values and colur
  ask patches [set patch-value 0 set plabel patch-value set pcolor scale-color patch-value user-colour upper-range lower-range]

  ;askes one random or specific patch to become the car source
  ifelse car-location? = true [
    ask patch car-x car-y [set pcolor blue set patch-value 100 set plabel patch-value]
  ][
    ask patch random-pxcor random-pycor [set pcolor blue set patch-value 100 set plabel patch-value]
  ]
end


;-----------------------------------------------------------------
; step
; the turtle function that holds all other functions that produce
; movement or actions for the turtle
; it is useful to keep this seperate, even if containing one function, as the visual interfaces uses this to run the program via the turtle.
;-----------------------------------------------------------------
to step
  main
  move-food
  patch-decay
  patch-interval-reset
  zero-base
  pointer-xy
  patch-average-calculator
  tick
end


;-----------------------------------------------------------------
; move-food
; repeatable button on visual side to cause food to move.
;-----------------------------------------------------------------
to move-food
  if move-car? = true [
  food-turtle-caller
  ]
end


;-----------------------------------------------------------------
; edit
; patches functions for editing the board during step or on its own
;-----------------------------------------------------------------
to edit
  wall-edit
  food-edit
end


;-----------------------------------------------------------------
; patch-decay
; each number of specificed ticks the patch values are decreased.
;-----------------------------------------------------------------
to patch-decay
  if patch-decay? = true [ask patches [
    if patch-value > 1 and patch-value != 100 and patch-value != -100[
      set patch-value patch-value - patch-decay-variable set-plabel
    ]
  ]]

end


;-----------------------------------------------------------------
; zero-base
; ensures that values dont get stuck between 0 and 1
;-----------------------------------------------------------------
to zero-base
  ask patches [if patch-value < 1 and patch-value > 0 [set patch-value 0]]
end


;-----------------------------------------------------------------
; turtle-walk
; function manages turtle movement and provides base for
; learning algorithm function
;-----------------------------------------------------------------
to random-walk
  let wall? false
  rt random 360
  ask patch-ahead 1 [if patch-value = -100 [set wall? true]] ;checks for wall infront of turtle, if wall is present, do not activate TD learning or move.
  if wall? = false [
    let patch-error 0
    ask patch-ahead 1 [set patch-error discount * patch-value set-plabel]
    ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]
    fd 1
    goal-reset
  ]
end


;-----------------------------------------------------------------
; pointerxy
; small turtle that shows home location
;-----------------------------------------------------------------
to pointer-xy
  ifelse show-pointer? = true [ask Parks [show-turtle setxy set-x set-y]] [ask Parks [hide-turtle]]
end


;-----------------------------------------------------------------
; car-random-movement
; function manages food turtle movement based on ticks
;-----------------------------------------------------------------
to car-random-movement
  let r 0
  let holder 0
  set r ticks mod car-move-interval ; if ticks divisible by user defined number
  if r = 0 and ticks > 1  [ ; if there is no remainder
    let wall? false
    rt random 360
    ask patch-ahead 1 [if patch-value = -100 [set wall? true]] ;checks for wall infront of turtle, if wall is present, do not activate TD learning or move.
    while [wall? = true] [ ; rotates turtle until not wall
      rt random 360
      ask patch-ahead 1 [if patch-value != -100 [set wall? false]]
    ]
    set holder value-holder ; loads stored patch value
    ask patch-here [set patch-value holder set-plabel] ; restores patches value
    fd 1 ; moves forward to new patch
    ask patch-here [set holder patch-value set patch-value 100 set-plabel] ; saves new patch value in turtle variable and turns it into food.
    set value-holder holder ; saving the value for next cycle
  ]
end


;-----------------------------------------------------------------
; food-turtle-caller
; manages all functions of the food turtle breed
;-----------------------------------------------------------------
to food-turtle-caller
  ifelse hide-moveable-food? = true [ask AutoCars [set size 0]] [ask AutoCars [set size 1]]
  ask AutoCars [car-random-movement]
end


;-----------------------------------------------------------------
; main - contains all non-repeatable code segments
; > patch value finder and TD turtle mover
; > random walk provider
; finds the highest valued patch next to turtle and then moves turtle to that patch. if all are equa move to top left corner.
;-----------------------------------------------------------------
to main
  let i 0
  ask TDturtles [
    let largest-index 0
    let value-search -1
    let holder array:from-list [0 0 0 0 0 0 0 0] ; holders patch values
    let equal-finder 0

    ;gives array values based on turtle nighbour patches.
    ask patch-at -1 1 [array:set holder 0 patch-value]
    ask patch-at 0 1 [array:set holder 1 patch-value]
    ask patch-at 1 1 [array:set holder 2 patch-value]
    ask patch-at -1 0 [array:set holder 3 patch-value]
    ask patch-at 1 0 [array:set holder 4 patch-value]
    ask patch-at -1 -1 [array:set holder 5 patch-value]
    ask patch-at 0 -1 [array:set holder 6 patch-value]
    ask patch-at 1 -1 [array:set holder 7 patch-value]

    ;While loop sets value-search to highest value in array and finds amount of equal values.
    while [i != 8][

      ;records index of highest valued data
      if array:item holder i > value-search [set value-search array:item holder i set largest-index i]

      ;checks to see if previous value is the same as current value
      if array:item holder i = 0 or array:item holder i = -100 [set equal-finder equal-finder + 1]
      set i i + 1
    ]


    ;random walk called if random chance dictates.
    if random 100 <= random-chance [
      random-walk
      stop
    ]

    ; TD-walk, given the highest valued data index, turtle moves.
    set i 0
    let patch-error 0
    ifelse equal-finder >= 8 [random-walk]
    [
      ;index with relevant patch location
      if largest-index = 0 [
        ask patch-at -1 1 [set patch-error discount * patch-value set-plabel]
        ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]
        move-to patch-at -1 1
      ]

      if largest-index = 1 [ask patch-at 0 1 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at 0 1]
      if largest-index = 2 [ask patch-at 1 1 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at 1 1]
      if largest-index = 3 [ask patch-at -1 0 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at -1 0]
      if largest-index = 4 [ask patch-at 1 0 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at 1 0]
      if largest-index = 5 [ask patch-at -1 -1 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at -1 -1]
      if largest-index = 6 [ask patch-at 0 -1 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at 0 -1]
      if largest-index = 7 [ask patch-at 1 -1 [set patch-error discount * patch-value set-plabel] ask patch-here [set patch-error patch-error - patch-value set patch-value patch-value + learning-rate * patch-error set-plabel]  move-to patch-at 1 -1]

    ]
  goal-reset
  ]
end


;-----------------------------------------------------------------
; goal-reset
; manages the search for the goal patch
; resets position to home if goal is reach
;-----------------------------------------------------------------
to goal-reset
  ;reset  car turtle position if goal is reach .
  let temp-value 0
  ask patch-here [set temp-value patch-value]
  if temp-value = 100 [
    setxy set-x set-y
    set reward reward + 10
  ]
end


;-----------------------------------------------------------------
; food-edit
; uses mouse controller to change patch values, 0, 100
;-----------------------------------------------------------------
to food-edit
  if custom-food? = true[ ;switch on visual map
    set custom-walls? false
    if mouse-controller = true[ ;mouse controller
      ask patch mouse-xcor mouse-ycor [
        ifelse patch-value = 100 [
          set patch-value 0 set-plabel ;undo food
        ][
          set patch-value 100 set-plabel ;create food
        ]
      ]
    ]
  ]
end


;-----------------------------------------------------------------
; wall-edit
; > uses mouse to determin when to draw walls
; > uses switch custom-walls? to activate click painting, also able to turn walls (-100) back into floor (0).
; > uses switch paint-walls to activate painting walls mode, custom-walls? must also be true for it to work.
;-----------------------------------------------------------------
to wall-edit
  ifelse custom-walls? = true[ ; first switch for click walls.
    set custom-food? false
    ifelse paint-walls? = true[ ; second switch for painting walls.
      if mouse-down? = true [ask patch mouse-xcor mouse-ycor [set patch-value -100 set-wall-plabel]]
    ][
      if mouse-controller = true[ ;mouse controller
        if mouse-down? = true [
          ask patch mouse-xcor mouse-ycor [
            ifelse patch-value = -100 [
              set patch-value 0 set-plabel ;undo wall
            ][
              set patch-value -100 set-wall-plabel ;create wall
            ]
          ]
        ]
      ]
    ]
  ][
   set paint-walls? false
  ]
end


;-----------------------------------------------------------------
; patch average finder
; calculates patch average value
;-----------------------------------------------------------------
to patch-average-calculator
  if calculate-patch-average? = true [
    ask patches [
      set patch-average patch-average + patch-value
    ]
    set patch-average patch-average / 240
  ]

end

;-----------------------------------------------------------------
; patch-interval-reset
; resets patch values to 0 if the turtle does not visit the patch in a user specified timeframe.
;-----------------------------------------------------------------
to patch-interval-reset
  if patch-interval-reset? = true[
    ask patches [
      if count TDturtles-here >= 1 [set ptimer 0]
      ifelse patch-value = 100 or patch-value < -99 [
        set ptimer 0
      ][
        set ptimer ptimer + 1
        if ptimer >= interval-reset [set patch-value 0 set-plabel set ptimer 0]
      ]
    ]
  ]
end


;-----------------------------------------------------------------
; set-plabel
; set the label as patch-value of specified patch
;-----------------------------------------------------------------
to set-plabel
  set plabel round patch-value
  set pcolor scale-color patch-value user-colour upper-range lower-range
end

;-----------------------------------------------------------------
; set-wall-plabel
; specific plabel dealing with walls. sets to black instead
;-----------------------------------------------------------------
to set-wall-plabel
  set plabel round patch-value
  set pcolor black
end


;-----------------------------------------------------------------
; mouse-controller
; stops the mouse from repeatedly activating a command.
; waits for mouse to do both click and unclick before allowing another input.
; reports true when the mouse has been clicked.
;-----------------------------------------------------------------
to-report mouse-controller
  ifelse mouse-inactive = true[
    if mouse-down? = true[ ;mouse click in
      set mouse-inactive false ;locks input
      report true
    ]
  ][
    if mouse-down? = false[set mouse-inactive true] ;mouse click up, allows for next input
    report false
  ]
  report false
end
@#$#@#$#@
GRAPHICS-WINDOW
415
14
1070
670
-1
-1
38.1
1
10
1
1
1
0
1
1
1
-8
8
-8
8
0
0
1
ticks
30.0

BUTTON
308
18
408
51
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
309
55
409
88
NIL
step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
307
91
410
124
Run program
step
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
237
133
409
166
learning-rate
learning-rate
0.01
1
0.2
0.01
1
%
HORIZONTAL

SLIDER
237
168
409
201
discount
discount
0
1
0.95
0.01
1
%
HORIZONTAL

SWITCH
1082
15
1221
48
home-location?
home-location?
0
1
-1000

SLIDER
238
203
410
236
random-chance
random-chance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1083
54
1255
87
set-x
set-x
-8
8
-4.0
1
1
NIL
HORIZONTAL

SLIDER
1084
91
1256
124
set-y
set-y
-8
8
-4.0
1
1
NIL
HORIZONTAL

INPUTBOX
1079
324
1151
384
user-colour
55.0
1
0
Number

SLIDER
1081
391
1253
424
lower-range
lower-range
user-colour / 2
user-colour * 2
42.0
1
1
NIL
HORIZONTAL

SLIDER
1081
428
1253
461
upper-range
upper-range
user-colour / 2
user-colour * 2
68.0
1
1
NIL
HORIZONTAL

BUTTON
1083
467
1239
500
Load Colour Preset #1
set user-colour 55\nset lower-range 42\nset upper-range 68
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
280
363
411
396
custom-food?
custom-food?
0
1
-1000

BUTTON
322
327
408
360
edit mode
edit
T
1
T
PATCH
NIL
NIL
NIL
NIL
1

SWITCH
154
400
286
433
custom-walls?
custom-walls?
0
1
-1000

SWITCH
290
400
410
433
paint-walls?
paint-walls?
0
1
-1000

BUTTON
236
239
409
272
Load Preset Options #1
set learning-rate 0.20\nset discount 0.95\nset random-chance 50\nset patch-interval-reset? false\nset car-location? true\nset calculate-patch-average? false\nset show-pointer? true\nset number-of-cars 1\nset interval-reset 1000\nset home-location? true\nset patch-decay? false\nset patch-decay-variable 0.01\nset user-colour 55\nset lower-range 42\nset upper-range 68\nset car-move-interval 1000\nset hide-moveable-food? false\nset custom-food? false\nset custom-walls? false\nset paint-walls? false\nset set-x -4\nset set-y -4\nset car-x 4\nset car-y 4\nsetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
246
635
412
668
Remove Moveable Car
ask AutoCars [die]
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

INPUTBOX
253
497
408
557
Car-move-interval
1000.0
1
0
Number

SWITCH
238
562
410
595
hide-moveable-food?
hide-moveable-food?
1
1
-1000

BUTTON
274
598
410
631
Create Car agent
ask AutoCars [die]\ncreate-AutoCars 1 [ set shape \"car\" set size 1 set color white setxy int random-xcor int random-ycor]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1085
167
1216
200
patch-decay?
patch-decay?
1
1
-1000

INPUTBOX
1085
203
1199
263
patch-decay-variable
0.01
1
0
Number

BUTTON
29
65
145
98
Add 1 TD Turtle
create-TDTurtles 1 [set size 1 set color blue setxy set-x set-y]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
148
33
261
95
number-of-Cars
50.0
1
0
Number

BUTTON
27
29
146
62
Remove all TD Turtles
ask TDTurtles [die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1078
597
1250
630
interval-reset
interval-reset
100
2500
1000.0
1
1
NIL
HORIZONTAL

SWITCH
1078
632
1250
665
patch-interval-reset?
patch-interval-reset?
1
1
-1000

SWITCH
1225
15
1359
48
show-pointer?
show-pointer?
0
1
-1000

INPUTBOX
1080
533
1235
593
interval-reset
1000.0
1
0
Number

MONITOR
503
675
833
736
Number of times goal has been reach:
reward
0
1
15

MONITOR
815
675
984
736
Patch Average Value
patch-average
1
1
15

SWITCH
1424
15
1563
48
car-location?
car-location?
0
1
-1000

SLIDER
1424
51
1596
84
car-x
car-x
-8
8
4.0
1
1
NIL
HORIZONTAL

SLIDER
1424
87
1596
120
car-y
car-y
-8
8
4.0
1
1
NIL
HORIZONTAL

SWITCH
802
743
998
776
calculate-patch-average?
calculate-patch-average?
1
1
-1000

SWITCH
150
598
273
631
move-car?
move-car?
0
1
-1000

@#$#@#$#@
# Tobias Tagarsi 15060639 | April 2019 #


## WHAT IS IT?

This model simulates agents that traverse the map to find a food source. 

## HOW IT WORKS

The agents use Temporal Difference to calculate patch values. These patch values form a path that is able to lead the agent to the food source.

## HOW TO USE IT

To start, push the button labeled 'Load preset settings #1', and then toggle 'Run Program' to begin.

You can add in extra food, walls, moveable food, and more by using the surrounding options.

## EDIT MODE

Edit mode allows walls and food to be created with mouse clicks. To enable pain walls, enable custom walls first.

## THINGS TO TRY

Try using the edit mode to create mazes and obstacles, but remember to create a walled area first as the map loops.


## CREDITS AND REFERENCES

University of Hertfordshire
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="5" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>step</go>
    <timeLimit steps="25000"/>
    <metric>food-found-counter</metric>
    <metric>patch-average</metric>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
