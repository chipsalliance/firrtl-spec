---
author:
- The FIRRTL Specification Contributors
title: Specification for the FIRRTL ABI
revisionHistoryAbi: true
---

# Introduction

FIRRTL defines a language/IR for describing synchronous hardware circuits.  This
document specifies the mapping of FIRRTL constructs to Verilog in a manner
similar to an application binary interface (ABI) which enables predictability of
the output of key constructs necessary for the interoperability between circuits
described in FIRRTL and between other languages and FIRRTL output.

This document describes multiple versions of the ABI, specifically calling
specific changes in later versions.  It is expected that a conforming FIRRTL
compiler can lower to all specified ABIs.  This mechanism exists to allow
improved representations when using tools which have better Verilog support and
allow incremental migration of existing development flows to the significant
representational changes introduced by ABI changes.

# FIRRTL System Verilog Interface

To use a circuit described in FIRRTL in a predictable way, the mapping of certain
behaviors and boundary constructs in FIRRTL to System Verilog must be defined.
Where possible this ABI does not impose constraints on implementation,
concerning itself primarily with the boundaries of the circuit.

Two ABIs are defined.  ABIv1 describes a system in which no aggregate types
appear on circuit boundaries (publicly visible locations).  This ABI captures
and formalizes the historic behavior of FIRRTL to verilog lowering.
Specifically, this ABI, by construction, produces no aggregate Verilog types.
ABIv2 defines an ABI in which aggregate types are preserved.  Both these ABIs
may evolve as new FIRRTL constructs are added.

## On Modules

### The Circuit and Top Level

The top level module, as specified by the circuit name, shall be present as a
System Verilog module of the same name.  This FIRRTL module is considered a
"public" module and subject to the lowering constraints for public modules.

### External Modules

An external module may be presumed to exist following the lowering constraints
for public modules.  The module shall exist with a verilog name matching the
defname value or, lacking that, the module name.

###  Public Modules

Any module considered a "public" module shall be implemented in Verilog in a
consistent way.  Any public module shall exist as a Verilog module of the same
name.

Each public module with definitions (e.g. not external modules) shall be placed
in a file with the same name.  No assumption is made of the filename of an
implementation of an external module, it is the user's job to include files in
such a way in their tools to resolve the name.

### Port Lowering ABIv1

Ports are generally lowered to netlist types, except where Verilog's type system
prevents it.

Ports of integer types shall be lowered to netlist ports (`wire`{.verilog}) as a
packed vector of equivalent size.  For example, consider the following FIRRTL:

```FIRRTL
circuit Top :
  module Top :
    output out: UInt<16>
    input b: UInt<32>
```

This is lowered to the following Verilog:

```verilog
module Top(
    output wire [15:0] out,
    input wire [31:0] in
);
```

Ports of aggregate type shall be scalarized according to the "Aggregate Type
Lowering" description in the FIRRTL spec.

Ports of ref type shall be lowered to a Verilog macro of the form `` `define
ref_<circuit name>_<module name>_<portname> <internal path from module>`` in a
file with name `ref_<circuit name>_<module name>.sv`.  References to aggregates
will be lowered to a series of references to ground types.  This ABI does not
specify whether the original aggregate referent is scalarized or not.

All other port types shall lower according ot the type lowering in
section ["On Types"](#On-Types).

### Port Lowering ABIv2

Ports are lowered per the v1 ABI above, except for aggregate types.

Vectors shall be lowered to Verilog packed vectors.

Bundles shall be recursively split as per "Aggregate Type Lowering", except
instead of recursively converting bundles to ground types, the recursion stops
at passive types.

Passive bundles shall be lowered to Verilog packed structs.

Reference types in ports shall be logically split out from aggregates and named
as though "Aggregate Type Lowering" was used.

## On Types

Types are only guaranteed to follow this lowering when the Verilog type is on an
element which is part of the ABI defined public elements.  These include
use in ports and elements exported by reference through a public module.

Ground types are lowered to the `logic`{.verilog} data type (SV.6.3.1), which is
the 4-valued type.  It is important to distinguish the `logic`{.verilog} data
type from using `logic`{.verilog} as a keyword to declare a variable instead of
net-list object.

Both unsigned and signed integers produce an unsigned packed bit vector of the
form `[width-1:0]`.  Whether Verilog variable or netlist depends on the
construct being used.

Passive bundles, when lowered, are lowered to packed structs with their fields
recursively following these lowering rules.

Vectors, when lowered, are lowered to packed vectors with their element type
recursively following these rules.

Enums shall have their payloads lowered as per this section.  By construction,
enums are passive FIRRTL types, so any valid variant payload will lower to a
verilog type.  An enum with empty or 0-bit payloads for all variants will lower
to a Verilog enum with tags for each FIRRTL enum tag value.  A FIRRTL enum with
at least one payload will lower to a packed struct containing a tag field which
is a Verilog enum, as well as a data field containing a packed union of the
padded types of the payloads.  A padded payload is a packed struct with the
payload as the first field and a packed bit vector as a second field.  The
padding for each payload is set to ensure all padded payloads have the same bit
width as required by Verilog packed unions.

## On Macros

### Randomization of Undefined Values

The following macros are emitted in the RTL that simulators or instantiators
can use configure the initialization and randomization
of registers and memories before their reset:

* `RANDOMIZE` - True/False flag that indicates whether any randomization should occur at all.
* `INIT_RANDOM`- Users can define INIT_RANDOM as general code that gets injected into the initializer block for modules with registers.
* `RANDOM` - May be set to an expression that produces a 32-bit random unsigned value.
* `RANDOMIZE_DELAY` - The delay used within the `initial` block to delay randomization.
* `RANDOMIZE_REG_INIT` - True/False define flag if registers should have randomized values (rather than X) at start of simulation.
* `RANDOMIZE_MEM_INIT` - True/False define flag if multi-dimenstional state elements should have randomized values (rather than X) at start of simulation.

### Conditionals

The following macros are emitted in the RTL that simulators or instantiators
can use configure behavior of certain events:

* `PRINTF_COND` - Users can define 'PRINTF_COND' to add an extra gate to prints.
* `STOP_COND` - Users can define 'STOP_COND' to add an extra gate to stop conditions.
* `ASSERT_VERBOSE_COND` - Users can define 'ASSERT_VERBOSE_COND' to add an extra gate to assert error printing.

### General

* `SYNTHESIS` - True/False define macro that indicates whether a section of code is valid for Synthesis (vs simulation)

## On Attributes

* `VCS coverage exclude_file`

# Versioning Scheme of this Document

This is the versioning scheme that applies to version 1.0.0 and later.

The versioning scheme complies with
[Semantic Versioning 2.0.0](https://semver.org/#semantic-versioning-200).

Specifically,

The PATCH digit is bumped upon release which only includes non-functional changes,
such as grammar edits, further examples, and clarifications.

The MINOR digit is bumped for feature additions to the spec.

The MAJOR digit is bumped for backwards-incompatible changes such as features
being removed from the spec, changing their interpretation, or new required
features being added to the specification.

In other words, any verilog generated that was emitted with `x.y.z` will be
compliant with `x.Y.Z`, where `Y >= y`, `z` and `Z` can be any number.
