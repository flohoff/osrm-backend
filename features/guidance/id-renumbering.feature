@routing @guidance @turn-lanes @intersections
Feature: Lane and bearing data after guidance ID renumbering

    # Lane data, entry class and bearing class IDs are renumbered after turn annotation.
    # Several junctions with different lane layouts and bearings in one extract make the
    # renumbering permute IDs, so a wrong reference changes the lanes or bearings of a step.

    Background:
        Given the profile "car"
        Given a grid size of 5 meters

    Scenario: Different lane layouts and bearing classes in one extract
        Given the node map
            """
            a   b   c
                d










                h
            e   f   g












                l
            i   j   k
                m
            """

        And the ways
            | nodes | turn:lanes:forward | turn:lanes:backward | name |
            | ab    | through\|right     |                     | in1  |
            | bc    |                    | left\|through\|\|   | st1  |
            | bd    |                    | left\|right         | rt1  |
            | ef    | left\|through      |                     | in2  |
            | fg    |                    |                     | st2  |
            | fh    |                    |                     | lt2  |
            | ij    | left\|through\|right |                   | in3  |
            | jk    |                    |                     | st3  |
            | jl    |                    |                     | lt3  |
            | jm    |                    |                     | rt3  |

        When I route I should get
            | waypoints | route       | turns                           | lanes                                              | intersections                                         |
            | a,c       | in1,st1,st1 | depart,new name straight,arrive | ,straight:true right:false,                        | true:90;true:90 true:180 false:270;true:270           |
            | a,d       | in1,rt1,rt1 | depart,turn right,arrive        | ,straight:false right:true,                        | true:90;true:90 true:180 false:270;true:0             |
            | c,a       | st1,in1,in1 | depart,new name straight,arrive | ,left:false straight:true none:true none:true,     | true:270;false:90 true:180 true:270;true:90           |
            | c,d       | st1,rt1,rt1 | depart,turn left,arrive         | ,left:true straight:false none:false none:false,   | true:270;false:90 true:180 true:270;true:0            |
            | e,g       | in2,st2,st2 | depart,new name straight,arrive | ,left:false straight:true,                         | true:90;true:0 true:90 false:270;true:270             |
            | e,h       | in2,lt2,lt2 | depart,turn left,arrive         | ,left:true straight:false,                         | true:90;true:0 true:90 false:270;true:180             |
            | i,k       | in3,st3,st3 | depart,new name straight,arrive | ,left:false straight:true right:false,             | true:90;true:0 true:90 true:180 false:270;true:270    |
            | i,l       | in3,lt3,lt3 | depart,turn left,arrive         | ,left:true straight:false right:false,             | true:90;true:0 true:90 true:180 false:270;true:180    |
            | i,m       | in3,rt3,rt3 | depart,turn right,arrive        | ,left:false straight:false right:true,             | true:90;true:0 true:90 true:180 false:270;true:0      |
