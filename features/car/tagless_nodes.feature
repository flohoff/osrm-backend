@routing @car @tagless_nodes
Feature: Car - Calling process_node for nodes without tags

    # The patched process_node makes every node it is called with a barrier, so
    # the route over the middle node b only exists if b never reaches Lua.

    Scenario: Car - Tagless nodes are not passed to process_node by default
        Given the profile file "car" initialized with
            """
            functions.process_node = function(profile, node, result, relations)
              obstacle_map:add(node, Obstacle.new(obstacle_type.barrier))
            end
            """
        And the node map
            """
            a-b-c
            """
        And the ways
            | nodes | highway | name |
            | abc   | primary | abc  |
        And the nodes
            | node | name  |
            | b    | (nil) |
        When I route I should get
            | from | to | route   |
            | a    | c  | abc,abc |

    Scenario: Car - Tagless nodes are passed to process_node if the profile asks for it
        Given the profile file "car" initialized with
            """
            profile.properties.call_tagless_node_function = true
            functions.process_node = function(profile, node, result, relations)
              obstacle_map:add(node, Obstacle.new(obstacle_type.barrier))
            end
            """
        And the node map
            """
            a-b-c
            """
        And the ways
            | nodes | highway | name |
            | abc   | primary | abc  |
        And the nodes
            | node | name  |
            | b    | (nil) |
        When I route I should get
            | from | to | route |
            | a    | c  |       |

    Scenario: Car - Tagged nodes are still passed to process_node by default
        Given the profile file "car" initialized with
            """
            functions.process_node = function(profile, node, result, relations)
              obstacle_map:add(node, Obstacle.new(obstacle_type.barrier))
            end
            """
        And the node map
            """
            a-b-c
            """
        And the ways
            | nodes | highway | name |
            | abc   | primary | abc  |
        And the nodes
            | node | highway  |
            | b    | crossing |
        When I route I should get
            | from | to | route |
            | a    | c  |       |
