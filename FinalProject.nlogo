;; Code by:
;; Group 12
;; Teun (s4716515), Jelle (s4807243)
;; Natan (s5230152), Eliane (s5249511)

breed [voters voter]
breed [parties party]
voters-own [preferred-party hated-parties]
parties-own [name party-color votes]

to setup
  clear-all
  ;; create a list of all the parties, where they fall on the spectrum and their party color
  let party-list [
    ["Bij1" -0.96 0.93 0]
    ["PVDD" -0.95 0.81 55]
    ["GL-PvdA" -0.55 0.66 14]
    ["Volt" -0.14 0.84 112]
    ["D66" -0.05 0.59 65]
    ["DENK" -0.68 0.32 86]
    ["SP" -0.78 0.21 15]
    ["CU" -0.33 0.23 105]
    ["50+" -0.23 -0.02 123]
    ["NSC" -0.09 -0.09 3]
    ["CDA" 0.24 -0.23 63]
    ["BBB" 0.10 -0.39 52]
    ["SGP" 0.26 -0.43 22]
    ["VVD" 0.51 -0.32 25]
    ["PVV" 0.11 -0.73 5]
    ["JA21" 0.78 -0.89 102]
    ["FVD" 0.63 -0.93 13]
    ["BVNL" 1 -0.89 100]
  ]

  ;; creates all the parties and places them in the world
  foreach party-list
  [
    [current-party] ->
    create-parties 1 [
      set xcor item 1 current-party * max-pxcor
      set ycor item 2 current-party * max-pycor

      set name item 0 current-party
      set party-color item 3 current-party

      ;visualizes above settings on the map
      set color party-color
      set plabel name
      set plabel-color black
    ]
  ]

  ask patches [
    ;; sets background patches to be pastel version of the party-color
    let closest-party min-one-of parties [distance myself]
    set pcolor [party-color] of closest-party + 3
  ]

  create-voters number-voters [
    ;; decides which quadrant this voter is most likely to vote
    let quadrant random-float 1.0
    ifelse (quadrant >= 0.5) [set quadrant 1] [set quadrant -1]
    ;; finds this voters place in this quadrant, making them more likely to vote near the middle
    set quadrant quadrant * (random-exponential stdiv)
    let x random-normal quadrant distribution-width
    let y random-normal (-1 * quadrant) distribution-width

    ;; makes sure no voters are outside the political spectrum
    if x < min-pxcor [set x min-pxcor]
    if x > max-pxcor [set x max-pxcor]
    if y < min-pycor [set y min-pycor]
    if y > max-pycor [set y max-pycor]
    setxy x y

    ;; decides the political preference of this voter
    set preferred-party min-one-of parties [distance myself]
    set hated-parties one-of parties who-are-not preferred-party

    ;; aesthetics
    set shape "circle"
    set size 2
    set color [color] of preferred-party
  ]

  reset-ticks
end

to go
  deffuant-communication
  update-vote
  poll
  print-poll
  ;if ticks = 1 [stop] ;; remove this later
  tick
end

to poll
  ;; poll
  ask voters [
    ask preferred-party [set votes votes + 1]
  ]
end

to print-poll
  ;; print poll result ()
  print "poll"
  ask parties [
    print name
    print votes
    print ""
  ]
end

to deffuant-communication
  ask voters [
    let x-voter1 xcor
    let y-voter1 ycor
    ask one-of other voters [
      let x-voter2 xcor
      let y-voter2 ycor
      if distance myself < opinion-threshold[
        let new-x-voter1 x-voter1 + convergence-parameter * (x-voter2 - x-voter1) + random-normal 0 0.5
        let new-y-voter1 y-voter1 + convergence-parameter * (y-voter2 - y-voter1) + random-normal 0 0.5
        let new-x-voter2 x-voter2 + convergence-parameter * (x-voter1 - x-voter2) + random-normal 0 0.5
        let new-y-voter2 y-voter2 + convergence-parameter * (y-voter1 - y-voter2)+ random-normal 0 0.5
        
        if new-x-voter1 > max-pxcor [set new-x-voter1 max-pxcor]
        if new-x-voter1 < min-pxcor [set new-x-voter1 min-pxcor]
        if new-y-voter1 > max-pycor [set new-y-voter1 max-pycor]
        if new-y-voter1 < min-pycor [set new-y-voter1 min-pycor]
        
        if new-x-voter2 > max-pxcor [set new-x-voter2 max-pxcor]
        if new-x-voter2 < min-pxcor [set new-x-voter2 min-pxcor]
        if new-y-voter2 > max-pycor [set new-y-voter2 max-pycor]
        if new-y-voter2 < min-pycor [set new-y-voter2 min-pycor]
        
        setxy new-x-voter2 new-y-voter2
        
        ask myself [
          set xcor new-x-voter1 
          set ycor new-y-voter1
        ]
      ]     
       
    ]   
  ]
end

to update-vote
  ask voters[
    set preferred-party min-one-of parties [distance myself]
    set color [color] of preferred-party
  ]
end
