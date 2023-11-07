# Introduction

FIRRTL defines a language/IR for describing synchronous hardware circuits.
This document specifies the mapping of FIRRTL constructs to Verilog in a manner similar to an application binary interface (ABI) which enables predictability of the output of key constructs necessary for the interoperability between circuits described in FIRRTL and between other languages and FIRRTL output.

This document describes multiple versions of the ABI, specifically calling specific changes in later versions.
It is expected that a conforming FIRRTL compiler can lower to all specified ABIs.
This mechanism exists to allow improved representations when using tools which have better Verilog support and allow incremental migration of existing development flows to the significant representational changes introduced by ABI changes.

# FIRRTL System Verilog Interface

To use a circuit described in FIRRTL in a predictable way, the mapping of certain behaviors and boundary constructs in FIRRTL to System Verilog must be defined.
Where possible this ABI does not impose constraints on implementation, concerning itself primarily with the boundaries of the circuit.

Two ABIs are defined.
ABIv1 describes a system in which no aggregate types appear on circuit boundaries (publicly visible locations).
This ABI captures and formalizes the historic behavior of FIRRTL to verilog lowering.
Specifically, this ABI, by construction, produces no aggregate Verilog types.
ABIv2 defines an ABI in which aggregate types are preserved.
Both these ABIs may evolve as new FIRRTL constructs are added.

## On Modules

### The Circuit

The circuit is a container of public modules.
The circuit, by itself, does not have any ABI.

### External Modules

An external module may be presumed to exist following the lowering constraints for public modules.
The module shall exist with a Verilog name matching the defname value or, lacking that, the FIRRTL module name.
The ports of an external module shall adhere to one of the port lowering ABIs.

No assumption is made of the filename of an implementation of an external module.
It is the user's job to include files in such a way in their tools to resolve the name.

### Public Modules

All public modules shall be implemented in Verilog in a consistent way.
All public modules shall exist as Verilog modules of the same name.
Each public module shall be placed in a file with a format as follows where `module` is the name of the public module:

``` ebnf
filename = module , ".sv" ;
```

Each public module in a circuit shall produce a filelist that contains the filename of the file containing the public module and any necessary files that define all public or private module files instantiated under it.
Files that define external modules are not included. This filelist shall have a name as follows where `module` is the name of the public module:

``` ebnf
filelist_filename = "filelist_" , module , ".f" ;
```

The filelist contents are a newline-delimited list of filenames.

The ports of public modules shall be lowered using one of the Port Lowering ABIs.

No information about the instantiations of a public module may be used to compile a public module---a public module is compiled as if it is never instantiated.
However, it is legal to compile modules which instantiate public modules with full knowledge of the public module internals.

### Private Modules

Private modules have no defined ABI.
If the compilation of private modules produces files, then those files shall be included when necessary in public module filelists.

FIRRTL compilers shall mangle the names of private modules that are not removed by compilation.
The mangling scheme is implementation defined.
This is done to avoid name collisions with the private modules produced by other compilations.

### Port Lowering ABIs

There are two supported port lowering ABIs.
These ABIs are applicable to public modules or external modules only.

#### Port Lowering ABIv1

Ports are generally lowered to netlist types, except where Verilog's type system prevents it.

Ports of integer types shall be lowered to netlist ports (`wire`{.verilog}) as a packed vector of equivalent size.
For example, consider the following FIRRTL:

``` firrtl
circuit :
  public module Top :
    output out: UInt<16>
    input b: UInt<32>
```

This is lowered to the following Verilog:

``` verilog
module Top(
    output wire [15:0] out,
    input wire [31:0] in
);
```

Ports of aggregate type shall be scalarized according to the "Aggregate Type Lowering" description in the FIRRTL spec.

Ports of ref type on public modules shall, for each public module, be lowered to a Verilog macro of the form `` `define ref_<module name>_<portname> <internal path from module> `` in a file with name `ref_<module name>.sv`.
References to aggregates will be lowered to a series of references to ground types.
This ABI does not specify whether the original aggregate referent is scalarized or not.

All other port types shall lower according ot the type lowering in section ["On Types"](#On-Types).

#### Port Lowering ABIv2

Ports are lowered per the v1 ABI above, except for aggregate types.

Vectors shall be lowered to Verilog packed vectors.

Bundles shall be recursively split as per "Aggregate Type Lowering", except instead of recursively converting bundles to ground types, the recursion stops at passive types.

Passive bundles shall be lowered to Verilog packed structs.

Reference types in ports shall be logically split out from aggregates and named as though "Aggregate Type Lowering" was used.

## On Groups

The lowering convention of a declared optional group specifies how an optional group will be lowered.
Currently, the only lowering convention that must be supported is `"bind"`{.firrtl.}.
FIRRTL compilers may implement other non-standard lowering conventions.

### Bind Lowering Convention

The bind lowering convention is indicated by the `"bind"`{.firrtl} string on a declared group.
When using this convention, optional groups are lowered to separate modules that are instantiated via SystemVerilog `bind`{.verilog} statements ("bind instantiation").

Each module that contains group instances will produce one additional module per group that has "internal" module convention.
I.e., the modules are private and have no defined ABI---the name of each module is implementation defined, the instantiation name of a bound instance is implementation defined, and any ports created on the module may have any name and may be optimized away.

Practically speaking, additional ports of each generated module must be created whenever a value defined outside the group is used by the group.
The values captured by the group will create input ports.
Values defined in a group and used by a nested group will create output ports because SystemVerilog disallows the use of a bind instantiation underneath the scope of another bind instantiation.
The names of additional ports are implementation defined.

For each optional group and public module, one binding file will be produced for each group or nested group.
The public module, group name, and any nested groups are used to derive a predictable filename of the binding file.
The file format uses the format below where `module` is the name of the public module, `root` is the name of the root-level group and `nested` is the name of zero or more nested groups:

``` ebnf
filename = "groups_" , module , "_", root , { "_" , nested } , ".sv" ;
```

As an example, consider the following circuit with three optional groups:

``` firrtl
circuit:
  declgroup Group1, bind:
    declgroup Group2, bind:
      declgroup Group3, bind:
  public module Bar:
  public module Baz:
```

When compiled to Verilog, this will produce six bind files:

    groups_Bar_Group1.sv
    groups_Bar_Group1_Group2.sv
    groups_Bar_Group1_Group2_Group3_.sv
    groups_Baz_Group1.sv
    groups_Baz_Group1_Group2.sv
    groups_Baz_Group1_Group2_Group3_.sv

The contents of each binding files must have the effect of including all code defined in a group or its parent groups.

#### Example

The end-to-end below example shows a circuit with two groups that are lowered to Verilog.
This shows example Verilog output which is not part of the ABI, but is included for informative reasons.

Consider the following circuit containing one optional group, `Group1`, and one nested optional group, `Group2`.
Module `Foo` contains one instantiation of module `Bar`.
Both `Foo` and `Bar` contain groups.
To make the example simpler, no constant propagation is done:

``` firrtl
circuit:
  declgroup Group1, bind:
    declgroup Group2, bind:

  module Bar:
    output _notA: Probe<UInt<1>, Group1>
    output _notNotA: Probe<UInt<1>, Group1.Group2>

    wire a: UInt<1>
    connect a, UInt<1>(0)

    group Group1:
      node notA = not(a)
      define _notA = probe(notA)

      group Group2:
        node notNotA = not(notA)
        define _notNotA = probe(notNotA)

  public module Foo:
    inst bar of Bar

    group Group1:
      node x = bar._notA

      group Group2:
        node y = bar._notNotA
```

The following Verilog will be produced for the modules without the groups:

``` verilog
module Foo();
  Bar bar();
endmodule

module Bar();
  wire a = 1'b0;
endmodule
```

The following Verilog associated with `Group1` is produced.
Note that all module names and ports are implementation defined:

``` verilog
module Bar_Group1(
  input a
);
  wire notA = ~a;
endmodule

module Foo_Group1(
  input bar_notA
);
  wire x = bar_notA;
endmodule
```

The following Verilog associated with `Group2` is produced. Note that all module names and ports are implementation defined:

``` verilog
module Bar_Group1_Group2(
  input notA
);
  wire notNotA = ~notA;
endmodule

module Foo_Group1_Group2(
  input bar_notNotA
);
  wire y = bar_notNotA;
endmodule
```

Because there are two groups, two bindings files will be produced.
The first bindings file is associated with `Group1`:

``` verilog
// Inside file "groups_Foo_Group1.sv" :
`ifndef groups_Foo_Group1
`define groups_Foo_Group1
bind Foo Foo_Group1 group1(.bar_notA(Foo.bar.group1.notA));
bind Bar Bar_Group1 group1(.a(Bar.a));
`endif
```

The second bindings file is associated with `Group2`.
This group, because it depends on `Group1` being available, will automatically bind in this dependent group:

``` verilog
// Inside file "groups_Foo_Group1_Group2.sv" :
`ifndef groups_Foo_Group1_Group2
`define groups_Foo_Group1_Group2
`include "groups_Foo_Group1.sv"
bind Foo Foo_Group1_Group2 group1_group2(.bar_notNotA(Foo.bar.group1_group2.notNotA));
bind Bar Bar_Group1_Group2 group1_group2(.notA(Bar.group1.notA));
`endif
```

The `` `ifdef ``{.verilog} guards enable any combination of the bind files to be included while still producing legal SystemVerilog.
I.e., the end user may safely include none, either, or both of the bindings files.

## On Types

Types are only guaranteed to follow this lowering when the Verilog type is on an element which is part of the ABI defined public elements.
These include use in ports and elements exported by reference through a public module.

Ground types are lowered to the `logic`{.verilog} data type (SV.6.3.1), which is the 4-valued type.
It is important to distinguish the `logic`{.verilog} data type from using `logic`{.verilog} as a keyword to declare a variable instead of net-list object.

Both unsigned and signed integers produce an unsigned packed bit vector of the form `[width-1:0]`.
Whether Verilog variable or netlist depends on the construct being used.

Passive bundles, when lowered, are lowered to packed structs with their fields recursively following these lowering rules.

Vectors, when lowered, are lowered to packed vectors with their element type recursively following these rules.

Enums shall have their payloads lowered as per this section.
By construction, enums are passive FIRRTL types, so any valid variant payload will lower to a verilog type.
An enum with empty or 0-bit payloads for all variants will lower to a Verilog enum with tags for each FIRRTL enum tag value.
A FIRRTL enum with at least one payload will lower to a packed struct containing a tag field which is a Verilog enum, as well as a data field containing a packed union of the padded types of the payloads.
A padded payload is a packed struct with the payload as the first field and a packed bit vector as a second field.
The padding for each payload is set to ensure all padded payloads have the same bit width as required by Verilog packed unions.

Property types have no defined ABI, and may not affect any other guarantees of the ABI.

# Versioning Scheme of this Document

This is the versioning scheme that applies to version 1.0.0 and later.

The versioning scheme complies with [Semantic Versioning 2.0.0](https://semver.org/#semantic-versioning-200).

Specifically,

The PATCH digit is bumped upon release which only includes non-functional changes, such as grammar edits, further examples, and clarifications.

The MINOR digit is bumped for feature additions to the spec.

The MAJOR digit is bumped for backwards-incompatible changes such as features being removed from the spec, changing their interpretation, or new required features being added to the specification.

In other words, any verilog generated that was emitted with `x.y.z` will be compliant with `x.Y.Z`, where `Y >= y`, `z` and `Z` can be any number.
