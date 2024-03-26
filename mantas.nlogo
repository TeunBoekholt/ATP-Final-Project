;; Code by:
;; Group 12
;; Teun Boekholt (s4716515), Jelle Molenaar (s4807243),
;; Natan Szigeti (s5230152), Eliane Rodenburg (s5249511)

globals [
  plankton-eaten
]

breed [mantas manta]
breed [planktons plankton]

patches-own [flow]
mantas-own [previous-turn leader]
planktons-own []

to setup
  clear-all

  create-mantas number-of-mantas [
    setxy random-xcor random-ycor
    set shape "manta"
    set color gray - 1
    set size 6

  ]
  create-planktons plankton-population-limit * plankton-density / 100 [
    setxy random-xcor random-ycor
    set hidden? true
  ]

  ask patches [
    set pcolor sky + 3
    set pcolor pcolor - 0.01 * count planktons-here
    set flow random 360
  ]
  
  set plankton-eaten 0
  reset-ticks
end

to go
  move-plankton
  move-mantas
  eat
  hatch-plankton


  update-patches

  if count planktons = 0 [stop]
  tick
end

to move-plankton
  ask planktons [
    ifelse count planktons-here < (plankton-population-limit / 100) [
      set heading [flow] of patch-here
      if random 100 < 10 [set heading random 360]
      forward plankton-speed
  ] [
      set heading [flow] of patch-here + random 180 - 90
      if random 100 < 20 [set heading random 360]
      forward plankton-speed * plankton-diffusion
    ]
  ]

end

to feed-mantas
  create-planktons 50 * plankton-density [
    setxy 0 0
    set hidden? true
  ]
end

to move-mantas
  ask mantas[
    if movement-method = "angles" [move-mantas-with-angles]
    if movement-method = "leaders" [move-mantas-with-all-angles]
  ]
end

to move-mantas-with-all-angles
  let sum-heading heading 
  
  ask other mantas in-cone manta-vision-distance manta-vision-radius [
    set sum-heading sum-heading + heading
  ]
  
  set heading (sum-heading / count mantas in-cone manta-vision-distance manta-vision-radius) 
  
  let nearest-manta min-one-of other mantas in-cone manta-vision-distance manta-vision-radius [distance myself]
  
  if (nearest-manta != nobody)[
    let preferred-direction calculate-heading false nearest-manta
    let preferred-turn subtract-headings preferred-direction heading
    ;; keep the mantas from making impossibly sharp turns
    ifelse preferred-turn * previous-turn < 0 and smooth-turns?[
      set previous-turn mean (list (preferred-turn * turn-ratio) previous-turn)
    ][
      set previous-turn preferred-turn * turn-ratio
    ]
    ;; turn and swim forward
    rt previous-turn
  ]
  
  
  forward manta-speed
end

to move-mantas-with-angles
  ;; find closest manta
  let nearest-manta min-one-of other mantas in-cone manta-vision-distance manta-vision-radius [distance myself]
  ifelse (nearest-manta != nobody) and distance nearest-manta > manta-separation [
    ;; if there is another manta close by, swim towards the middle of them and where the most plankton is
    let preferred-direction calculate-heading true nearest-manta
    set preferred-direction average-angle preferred-direction calculate-heading false nearest-manta
    let preferred-turn subtract-headings preferred-direction heading
    ;; keep the mantas from making impossibly sharp turns
    ifelse preferred-turn * previous-turn < 0 and smooth-turns?[
      set previous-turn mean (list (preferred-turn * turn-ratio) previous-turn)
    ][
      set previous-turn preferred-turn * turn-ratio
    ]
    ;; turn and swim forward
    rt previous-turn
    forward manta-speed
  ] [
    ;; if there's no other mantas to follow, just swim towards the most plankton
    let preferred-direction calculate-heading false nearest-manta
    let preferred-turn subtract-headings preferred-direction heading
    ;; keep the mantas from making impossibly sharp turns
    ifelse preferred-turn * previous-turn < 0 and smooth-turns?[
      set previous-turn mean (list (preferred-turn * turn-ratio) previous-turn)
    ][
      set previous-turn preferred-turn * turn-ratio
    ]
    ;; turn and swim forward
    rt previous-turn
    forward manta-speed
  ]
end

to-report calculate-heading [follow? nearest-manta]
  ;; find what the heading of this manta should be to face the patch with the most plankton on it.
  let original-h heading
  ifelse follow? [
    face nearest-manta
  ] [
    face max-one-of patches in-cone manta-vision-distance manta-vision-radius [count planktons-here]
  ]
  let new-h heading
  set heading original-h
  report new-h
end

to hatch-plankton
  if count planktons < plankton-population-limit[
    create-planktons number-of-hatch [
      setxy random-xcor random-ycor
      set hidden? true
    ]
  ]
end

to eat
  ask mantas [
    if any? planktons-here [
      ifelse count planktons-here < plankton-in-one-bite [
        set plankton-eaten plankton-eaten + count planktons-here
        ask planktons-here [die]
      ][
        set plankton-eaten plankton-eaten + plankton-in-one-bite
        ask n-of plankton-in-one-bite planktons-here [die]
      ]
    ]
  ]
end

to-report average-angle [angle1 angle2]
  let difference subtract-headings angle1 angle2
  report (angle1 - (difference / 2))
end


to update-patches
  ask patches [
    set pcolor sky + 3 - (0.05 * count planktons-here)
    if pcolor > 99 [set pcolor 99]
    if pcolor < 91 [set pcolor 91]
    if any? mantas-here [
      set flow average-angle [heading] of one-of mantas-here flow
      ask neighbors4 [
        set flow average-angle (flow * water-flow) [flow] of myself
        ask neighbors4 [
          set flow average-angle (flow * water-flow) [flow] of myself
        ]
      ]
    ]
  ]
end
