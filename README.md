
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ReacTranScripter

<!-- badges: start -->

<!-- badges: end -->

Create Reactive Transport Models from configuration files. The resulting
scripts are in the style of the ReacTran R-package, using the package
functionality. Equivalent models can be scripted in R and Fortran code.

## Installation

You can install the development version of ReacTranScripter from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("RoKo-reuther/ReacTranScripter")
```

## Concepts

### reactions “database”

  - Reactions are declared in a .yaml file. This incolves the reactions,
    species, constants and arbitrary expressions (type *generic*)
  - Dependencies on constants, other reactions or expressions have to be
    declared(\!) using yaml-anchors. These anchor has to be set before
    used later.
  - Everything is an “expression”.
  - “Groups” / “Families” can be used to group reactions and species for
    evaluation, plotting, … (e.g. species with several degradability
    stages and corresponding pools and reactions)

#### expression types

  - *global\_constant*
      - occur in more than one reaction
      - explicitly user declared name (k000 - k499, or any other name)
      - no dependencies; value is stated
  - *local\_constant*
      - occur in only one reaction
      - treated as variables in R / Fortran for calibration
      - user defines local name which is later replaced by k500 - k999
      - no dependencies; value is stated
  - *generic*
      - an expression, usally a part of a reaction rate equation which
          - occurs in more than one reaction or
          - value needs to be tracked seperately or
          - parts of reaction expression are split for better
            readability
      - dependencies need to be declared
  - *reaction*
      - describes actual reactions
      - uses constants and generic expressions as dependencies
      - name gets replaced with R1, R2, …
      - dependencies need to be declared

#### decleration of dependencies

As dependencies of an expression of type *reaction* or *generic* can be
declared

  - global constants
      - name is set in database and remains in model
      - given name can be arbitrary, except for k500 - k999 (reserved
        for local constants)
      - name can be used directly in expressions after dependency is
        declared using an anchor
  - local constants
      - local name is set in data base (e.g. LOCAL1)
      - local name can be used in expressions enclosed by ‘\!’
        (e.g. \!LOCAL1\!)
      - get declared under a new name (k500 - k999) in model
      - local name gets replaced in parent expression automatically
  - reaction rates of other reactions
      - use name of reaction in expression similar to a local constant
        (e.g. \!REACTION\_NAME\!)
      - under this name reference the reaction using an anchor
      - \!REACTION\_NAME\! gets replaced by new R1, … name of reaction
  - reference to dCdt of a species by species name ???

Example:

``` yaml
species:
  S1: &S1
    phase: "aqueous"
    diffusion_coeff:
      value: 10
      unit: "???"
  S2: &S2
    phase: "solid"
    diffusion_coeff:
      value: "Db"
      unit: null
    family: null

expressions:
  k001: &k001
    type: "global_constant"
    value: 0.005
    unit: "???"

  Reaction1: &Reaction1
    type: "reaction"
    label: "Reaction 1"
    reaction_equation: "S1 + XX -> S2"
    source: "name_your_source"
    expr: "!k1! * S1 * k001"
    unit: "???"
    require:
      k1:
        type: "local_constant"
        value: 10
        unit: "???"
      k001: *k001
    involved_species:
      S1:
        stoichiometry: -1
        info: *S1
      S2:
        stoichiometry: 1
        info: *S2
    family: null

  example_expression: &example_expression
    type: "generic"
    expr: "k001 * !Reaction1!"
    unit: "m/d"
    require:
      k001: *k001
      Reaction1: *Reaction1

  Reaction2: &Reaction2
    type: "reaction"
    label: "Reaction 2 does not make sense; it should only demonstrate the use of an expression in a reaction"
    reaction_equation: "???"
    source: "name_your_source"
    expr: "2 * example_expression * !Reaction1!"
    unit: "???"
    require:
      example_expression: *example_expression
      Reaction1: *Reaction1
    involved_species: null
```
