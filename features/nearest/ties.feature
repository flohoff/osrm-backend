@nearest
Feature: Nearest API - ties between equally close segments

    # Candidates at the same distance must resolve by geometry, not by the layout of the R-tree.

    Background:
        Given the profile "testbot"

    Scenario: Nearest - two parallel ways at the same distance
        Given the node map
            """
            a   0   b
            c       d
            """

        And the ways
            | nodes | name |
            | ac    | west |
            | bd    | east |

        When I request nearest I should get
            | in | name | snapping_distance |
            | 0  | west | 200.0             |

    Scenario: Nearest - the way order does not decide a tie
        Given the node map
            """
            a   0   b
            c       d
            """

        And the ways
            | nodes | name |
            | bd    | east |
            | ac    | west |

        When I request nearest I should get
            | in | name | snapping_distance |
            | 0  | west | 200.0             |

    Scenario: Nearest - overlapping collinear ways
        Given the node map
            """
            a
            c
                q
            b
            d
            """

        And the ways
            | nodes | name  |
            | ab    | north |
            | cd    | south |

        When I request nearest I should get
            | in | name  | snapping_distance |
            | q  | south | 200.0             |

    Scenario: Nearest - overlapping collinear ways in the opposite way order
        Given the node map
            """
            a
            c
                q
            b
            d
            """

        And the ways
            | nodes | name  |
            | cd    | south |
            | ab    | north |

        When I request nearest I should get
            | in | name  | snapping_distance |
            | q  | south | 200.0             |
