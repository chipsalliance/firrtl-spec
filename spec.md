---
author:
- The FIRRTL Specification Contributors
title: Specification for the FIRRTL Language
date: \today
# Options passed to the document class
classoption:
- 12pt
# Link options
colorlinks: true
linkcolor: blue
filecolor: magenta
urlcolor: cyan
toccolor: blue
# General pandoc configuration
toc: true
numbersections: true
# Header Setup
pagestyle:
  fancy: true
# Margins
geometry: margin=1in
# pandoc-crossref
autoSectionLabels: true
figPrefix:
  - Figure
  - Figures
eqnPrefix:
  - Equation
  - Equations
tblPrefix:
  - Table
  - Tables
lstPrefix:
  - Listing
  - Listings
secPrefix:
  - Section
  - Sections
# This 'lastDelim' option does not work...
lastDelim: ", and"
---

# Introduction

## Background

The ideas for FIRRTL (Flexible Intermediate Representation for RTL) originated
from work on Chisel, a hardware description language (HDL) embedded in Scala
used for writing highly-parameterized circuit design generators. Chisel
designers manipulate circuit components using Scala functions, encode their
interfaces in Scala types, and use Scala's object-orientation features to write
their own circuit libraries. This form of meta-programming enables expressive,
reliable and type-safe generators that improve RTL design productivity and
robustness.

The computer architecture research group at U.C. Berkeley relies critically on
Chisel to allow small teams of graduate students to design sophisticated RTL
circuits. Over a three year period with under twelve graduate students, the
architecture group has taped-out over ten different designs.

Internally, the investment in developing and learning Chisel was rewarded with
huge gains in productivity. However, Chisel's external rate of adoption was slow
for the following reasons.

1.  Writing custom circuit transformers requires intimate knowledge about the
    internals of the Chisel compiler.

2.  Chisel semantics are under-specified and thus impossible to target from
    other languages.

3.  Error checking is unprincipled due to under-specified semantics resulting in
    incomprehensible error messages.

4.  Learning a functional programming language (Scala) is difficult for RTL
    designers with limited programming language experience.

5.  Confounding the previous point, conceptually separating the embedded Chisel
    HDL from the host language is difficult for new users.

6.  The output of Chisel (Verilog) is unreadable and slow to simulate.

As a consequence, Chisel needed to be redesigned from the ground up to
standardize its semantics, modularize its compilation process, and cleanly
separate its front-end, intermediate representation, and backends. A well
defined intermediate representation (IR) allows the system to be targeted by
other HDLs embedded in other host programming languages, making it possible for
RTL designers to work within a language they are already comfortable with. A
clearly defined IR with a concrete syntax also allows for inspection of the
output of circuit generators and transformers thus making clear the distinction
between the host language and the constructed circuit. Clearly defined semantics
allows users without knowledge of the compiler implementation to write circuit
transformers; examples include optimization of circuits for simulation speed,
and automatic insertion of signal activity counters.  An additional benefit of a
well defined IR is the structural invariants that can be enforced before and
after each compilation stage, resulting in a more robust compiler and structured
mechanism for error checking.

## Design Philosophy

FIRRTL represents the standardized elaborated circuit that the Chisel HDL
produces. FIRRTL represents the circuit immediately after Chisel's
elaboration. It is designed to resemble the Chisel HDL after all
meta-programming has executed. Thus, a user program that makes little use of
meta-programming facilities should look almost identical to the generated
FIRRTL.

For this reason, FIRRTL has first-class support for high-level constructs such
as vector types, bundle types, conditional statements, and modules. A FIRRTL
compiler may choose to convert high-level constructs into low-level constructs
before generating Verilog.

Because the host language is now used solely for its meta-programming
facilities, the frontend can be very light-weight, and additional HDLs written
in other languages can target FIRRTL and reuse the majority of the compiler
toolchain.

# Acknowledgments

The FIRRTL specification was originally published as a UC Berkeley Tech Report
([UCB/EECS-2016-9](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-9.html))
authored by Adam Izraelevitz ([`@azidar`](https://github.com/azidar)), Patrick
Li ([`@CuppoJava`](https://github.com/CuppoJava)), and Jonathan Bachrach
([`@jackbackrack`](https://github.com/jackbackrack)).  The vision for FIRRTL was
then expanded in an [ICCAD
paper](https://ieeexplore.ieee.org/abstract/document/8203780) and in [Adam's
thesis](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2019/EECS-2019-168.html).

During that time and since, there have been a number of contributions and
improvements to the specification.  To better reflect the work of contributors
after the original tech report, the FIRRTL specification was changed to be
authored by _The FIRRTL Specification Contributors_.  A list of these
contributors is below:

<!-- This can be generated using ./scripts/get-authors.sh -->
- [`@albert-magyar`](https://github.com/albert-magyar)
- [`@azidar`](https://github.com/azidar)
- [`@ben-marshall`](https://github.com/ben-marshall)
- [`@boqwxp`](https://github.com/boqwxp)
- [`@chick`](https://github.com/chick)
- [`@dansvo`](https://github.com/dansvo)
- [`@darthscsi`](https://github.com/darthscsi)
- [`@debs-sifive`](https://github.com/debs-sifive)
- [`@donggyukim`](https://github.com/donggyukim)
- [`@dtzSiFive`](https://github.com/dtzSiFive)
- [`@ekiwi`](https://github.com/ekiwi)
- [`@ekiwi-sifive`](https://github.com/ekiwi-sifive)
- [`@felixonmars`](https://github.com/felixonmars)
- [`@grebe`](https://github.com/grebe)
- [`@jackkoenig`](https://github.com/jackkoenig)
- [`@jared-barocsi`](https://github.com/jared-barocsi)
- [`@keszocze`](https://github.com/keszocze)
- [`@mwachs5`](https://github.com/mwachs5)
- [`@prithayan`](https://github.com/prithayan)
- [`@richardxia`](https://github.com/richardxia)
- [`@seldridge`](https://github.com/seldridge)
- [`@sequencer`](https://github.com/sequencer)
- [`@shunshou`](https://github.com/shunshou)
- [`@tdb-alcorn`](https://github.com/tdb-alcorn)
- [`@tymcauley`](https://github.com/tymcauley)
- [`@youngar`](https://github.com/youngar)

# File Preamble

A FIRRTL file begins with a magic string and version identifier indicating the
version of this standard the file conforms to
(see [@sec:versioning-scheme-of-this-document]).  This will not be present on
files generated according to versions of this standard prior to the first
versioned release of this standard to include this preamble.

``` firrtl
FIRRTL version 1.1.0
circuit MyTop...
```

# Circuits and Modules

## Circuits

All FIRRTL circuits consist of a list of modules, each representing a hardware
block that can be instantiated. The circuit must specify the name of the
top-level module.

``` firrtl
circuit MyTop :
  module MyTop :
    ; ...
  module MyModule :
    ; ...
```

## Modules

Each module has a given name, a list of ports, and a list of statements
representing the circuit connections within the module. A module port is
specified by its direction, which may be input or output, a name, and the data
type of the port.

The following example declares a module with one input port, one output port,
and one statement connecting the input port to the output port.  See
[@sec:connects] for details on the connect statement.

``` firrtl
module MyModule :
  input foo: UInt
  output bar: UInt
  bar <= foo
```

Note that a module definition does *not* indicate that the module will be
physically present in the final circuit. Refer to the description of the
instance statement for details on how to instantiate a module
([@sec:instances]).

## Externally Defined Modules

Externally defined modules are modules whose implementation is not provided in
the current circuit.  Only the ports and name of the externally defined module
are specified in the circuit.  An externally defined module may include, in
order, an optional _defname_ which sets the name of the external module in the
resulting Verilog and zero or more name--value _parameter_ statements.  Each
name--value parameter statement will result in a value being passed to the named
parameter in the resulting Verilog.

An example of an externally defined module is:

``` firrtl
extmodule MyExternalModule :
  input foo: UInt<2>
  output bar: UInt<4>
  output baz: SInt<8>
  defname = VerilogName
  parameter x = "hello"
  parameter y = 42
```

The widths of all externally defined module ports must be specified.  Width
inference, described in [@sec:width-inference], is not supported for module
ports.

A common use of an externally defined module is to represent a Verilog module
that will be written separately and provided together with FIRRTL-generated
Verilog to downstream tools.

# Types

FIRRTL has two classes of types: _ground_ types and _aggregate_ types.  Ground
types are fundamental and are not composed of other types.  Aggregate types are
composed of one or more aggregate or ground types.

## Ground Types

There are five classes of ground types in FIRRTL: unsigned integer types, signed
integer types, a clock type, reset types, and analog types.

### Integer Types

Both unsigned and signed integer types may optionally be given a known
non-negative integer bit width.

``` firrtl
UInt ; unsigned int type with inferred width
SInt ; signed int type with inferred width
UInt<10> ; unsigned int type with 10 bits
SInt<32> ; signed int type with 32 bits
```

Alternatively, if the bit width is omitted, it will be automatically inferred by
FIRRTL's width inferencer, as detailed in [@sec:width-inference].

#### Zero Bit Width Integers

Integers of width zero are permissible. They are always zero extended.
Thus, when used in an operation that extends to a positive bit width, they
behave like a zero. While zero bit width integers carry no information, we
allow 0-bit integer constant zeros for convenience:
`UInt<0>(0)` and `SInt<0>(0)`.

``` firrtl
wire zero_u : UInt<0>
zero_u is invalid
wire zero_s : SInt<0>
zero_s is invalid

wire one_u : UInt<1>
one_u <= zero_u
wire one_s : SInt<1>
one_s <= zero_s
```

Is equivalent to:

```
wire one_u : UInt<1>
one_u <= UInt<1>(0)
wire one_s : SInt<1>
one_s <= SInt<1>(0)
```

### Clock Type

The clock type is used to describe wires and ports meant for carrying clock
signals. The usage of components with clock types are restricted.  Clock signals
cannot be used in most primitive operations, and clock signals can only be
connected to components that have been declared with the clock type.

The clock type is specified as follows:

``` firrtl
Clock
```

### Reset Type

The uninferred `Reset`{.firrtl} type is either inferred to `UInt<1>`{.firrtl}
(synchronous reset) or `AsyncReset`{.firrtl} (asynchronous reset) during
compilation.

``` firrtl
Reset ; inferred type
AsyncReset
```

Synchronous resets used in registers will be mapped to a hardware description
language representation for synchronous resets.

The following example shows an uninferred reset that will get inferred to a
synchronous reset.

``` firrtl
input a : UInt<1>
wire reset : Reset
reset <= a
```

After reset inference, `reset` is inferred to the synchronous
`UInt<1>`{.firrtl} type:

``` firrtl
input a : UInt<1>
wire reset : UInt<1>
reset <= a
```

Asynchronous resets used in registers will be mapped to a hardware description
language representation for asynchronous resets.

The following example demonstrates usage of an asynchronous reset.

``` firrtl
input clock : Clock
input reset : AsyncReset
input x : UInt<8>
reg y : UInt<8>, clock with : (reset => (reset, UInt(123)))
; ...
```

Inference rules are as follows:

1. An uninferred reset driven by and/or driving only asynchronous resets will be
inferred as asynchronous reset.
1. An uninferred reset driven by and/or driving both asynchronous and synchronous
resets is an error.
1. Otherwise, the reset is inferred as synchronous (i.e. the uninferred reset is
only invalidated or is driven by or drives only synchronous resets).

`Reset`{.firrtl}s, whether synchronous or asynchronous, can be cast to other
types. Casting between reset types is also legal:

``` firrtl
input a : UInt<1>
output y : AsyncReset
output z : Reset
wire r : Reset
r <= a
y <= asAsyncReset(r)
z <= asUInt(y)
```

See [@sec:primitive-operations] for more details on casting.

### Analog Type

The analog type specifies that a wire or port can be attached to multiple
drivers. `Analog`{.firrtl} cannot be used as part of the type of a node or
register, nor can it be used as part of the datatype of a memory. In this
respect, it is similar to how `inout`{.firrtl} ports are used in Verilog, and
FIRRTL analog signals are often used to interface with external Verilog or VHDL
IP.

In contrast with all other ground types, analog signals cannot appear on either
side of a connection statement. Instead, analog signals are attached to each
other with the commutative `attach`{.firrtl} statement. An analog signal may
appear in any number of attach statements, and a legal circuit may also contain
analog signals that are never attached. The only primitive operations that may
be applied to analog signals are casts to other signal types.

When an analog signal appears as a field of an aggregate type, the aggregate
cannot appear in a standard connection statement.

As with integer types, an analog type can represent a multi-bit signal.  When
analog signals are not given a concrete width, their widths are inferred
according to a highly restrictive width inference rule, which requires that the
widths of all arguments to a given attach operation be identical.

``` firrtl
Analog<1>  ; 1-bit analog type
Analog<32> ; 32-bit analog type
Analog     ; analog type with inferred width
```

## Aggregate Types

FIRRTL supports two aggregate types: vectors and bundles.  Aggregate types are
composed of ground types or other aggregate types.

### Vector Types

A vector type is used to express an ordered sequence of elements of a given
type. The length of the sequence must be non-negative and known.

The following example specifies a ten element vector of 16-bit unsigned
integers.

``` firrtl
UInt<16>[10]
```

The next example specifies a ten element vector of unsigned integers of omitted
but identical bit widths.

``` firrtl
UInt[10]
```

Note that any type, including other aggregate types, may be used as the element
type of the vector. The following example specifies a twenty element vector,
each of which is a ten element vector of 16-bit unsigned integers.

``` firrtl
UInt<16>[10][20]
```

### Bundle Types

A bundle type is used to express a collection of nested and named types.  All
fields in a bundle type must have a given name, and type.

The following is an example of a possible type for representing a complex
number. It has two fields, `real`{.firrtl}, and `imag`{.firrtl}, both 10-bit
signed integers.

``` firrtl
{real: SInt<10>, imag: SInt<10>}
```

Additionally, a field may optionally be declared with a *flipped* orientation.

``` firrtl
{word: UInt<32>, valid: UInt<1>, flip ready: UInt<1>}
```

In a connection between circuit components with bundle types, the data carried
by the flipped fields flow in the opposite direction as the data carried by the
non-flipped fields.

As an example, consider a module output port declared with the following type:

``` firrtl
output a: {word: UInt<32>, valid: UInt<1>, flip ready: UInt<1>}
```

In a connection to the `a`{.firrtl} port, the data carried by the
`word`{.firrtl} and `valid`{.firrtl} sub-fields will flow out of the module,
while data carried by the `ready`{.firrtl} sub-field will flow into the
module. More details about how the bundle field orientation affects connections
are explained in [@sec:connects].

As in the case of vector types, a bundle field may be declared with any type,
including other aggregate types.

``` firrtl
{real: {word: UInt<32>, valid: UInt<1>, flip ready: UInt<1>},
 imag: {word: UInt<32>, valid: UInt<1>, flip ready: UInt<1>}}

```

When calculating the final direction of data flow, the orientation of a field is
applied recursively to all nested types in the field. As an example, consider
the following module port declared with a bundle type containing a nested bundle
type.

``` firrtl
output myport: {a: UInt, flip b: {c: UInt, flip d: UInt}}
```

In a connection to `myport`{.firrtl}, the `a`{.firrtl} sub-field flows out of
the module.  The `c`{.firrtl} sub-field contained in the `b`{.firrtl} sub-field
flows into the module, and the `d`{.firrtl} sub-field contained in the
`b`{.firrtl} sub-field flows out of the module.

## Passive Types

It is inappropriate for some circuit components to be declared with a type that
allows for data to flow in both directions. For example, all sub-elements in a
memory should flow in the same direction. These components are restricted to
only have a passive type.

Intuitively, a passive type is a type where all data flows in the same
direction, and is defined to be a type that recursively contains no fields with
flipped orientations. Thus all ground types are passive types. Vector types are
passive if their element type is passive. And bundle types are passive if no
fields are flipped and if all field types are passive.

## Type Equivalence

The type equivalence relation is used to determine whether a connection between
two components is legal. See [@sec:connects] for further details about connect
statements.

An unsigned integer type is always equivalent to another unsigned integer type
regardless of bit width, and is not equivalent to any other type. Similarly, a
signed integer type is always equivalent to another signed integer type
regardless of bit width, and is not equivalent to any other type.

Clock types are equivalent to clock types, and are not equivalent to any other
type.

An uninferred `Reset`{.firrtl} can be connected to another `Reset`{.firrtl},
`UInt`{.firrtl} of unknown width, `UInt<1>`{.firrtl}, or `AsyncReset`{.firrtl}.
It cannot be connected to both a `UInt`{.firrtl} and an `AsyncReset`{.firrtl}.

The `AsyncReset`{.firrtl} type can be connected to another
`AsyncReset`{.firrtl} or to a `Reset`{.firrtl}.

Two vector types are equivalent if they have the same length, and if their
element types are equivalent.

Two bundle types are equivalent if they have the same number of fields, and both
the bundles' i'th fields have matching names and orientations, as well as
equivalent types. Consequently, `{a:UInt, b:UInt}`{.firrtl} is not equivalent to
`{b:UInt, a:UInt}`{.firrtl}, and `{a: {flip b:UInt}}`{.firrtl} is not equivalent
to `{flip a: {b: UInt}}`{.firrtl}.

# Statements

Statements are used to describe the components within a module and how they
interact.

## Connects

The connect statement is used to specify a physically wired connection between
two circuit components.

The following example demonstrates connecting a module's input port to its
output port, where port `myinput`{.firrtl} is connected to port
`myoutput`{.firrtl}.

``` firrtl
module MyModule :
  input myinput: UInt
  output myoutput: UInt
  myoutput <= myinput
```

In order for a connection to be legal the following conditions must hold:

1.  The types of the left-hand and right-hand side expressions must be
    equivalent (see [@sec:type-equivalence] for details).

2.  The flow of the left-hand side expression must be sink or duplex (see
    [@sec:flows] for an explanation of flow).

3.  Either the flow of the right-hand side expression is source or duplex, or
    the right-hand side expression has a passive type.

Connect statements from a narrower ground type component to a wider ground type
component will have its value automatically sign-extended or zero-extended to
the larger bit width. Connect statements from a wider ground type component to a
narrower ground type component will have its value automatically truncated to
fit the smaller bit width. The behavior of connect statements between two
circuit components with aggregate types is defined by the connection algorithm
in [@sec:the-connection-algorithm].

### The Connection Algorithm

Connect statements between ground types cannot be expanded further.

Connect statements between two vector typed components recursively connects each
sub-element in the right-hand side expression to the corresponding sub-element
in the left-hand side expression.

Connect statements between two bundle typed components connects the i'th field
of the right-hand side expression and the i'th field of the left-hand side
expression. If the i'th field is not flipped, then the right-hand side field is
connected to the left-hand side field.  Conversely, if the i'th field is
flipped, then the left-hand side field is connected to the right-hand side
field.

## Statement Groups

An ordered sequence of one or more statements can be grouped into a single
statement, called a statement group. The following example demonstrates a
statement group composed of three connect statements.

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  output myport1: UInt
  output myport2: UInt
  myport1 <= a
  myport1 <= b
  myport2 <= a
```

### Last Connect Semantics

Ordering of statements is significant in a statement group. Intuitively, during
elaboration, statements execute in order, and the effects of later statements
take precedence over earlier ones. In the previous example, in the resultant
circuit, port `b`{.firrtl} will be connected to `myport1`{.firrtl}, and port
`a`{.firrtl} will be connected to `myport2`{.firrtl}.

Conditional statements are also affected by last connect semantics, and for
details see [@sec:conditional-last-connect-semantics].

In the case where a connection to a circuit component with an aggregate type is
followed by a connection to a sub-element of that component, only the connection
to the sub-element is overwritten. Connections to the other sub-elements remain
unaffected. In the following example, in the resultant circuit, the `c`{.firrtl}
sub-element of port `portx`{.firrtl} will be connected to the `c`{.firrtl}
sub-element of `myport`{.firrtl}, and port `porty`{.firrtl} will be connected to
the `b`{.firrtl} sub-element of `myport`{.firrtl}.

``` firrtl
module MyModule :
  input portx: {b: UInt, c: UInt}
  input porty: UInt
  output myport: {b: UInt, c: UInt}
  myport <= portx
  myport.b <= porty
```

The above circuit can be rewritten equivalently as follows.

``` firrtl
module MyModule :
  input portx: {b: UInt, c: UInt}
  input porty: UInt
  output myport: {b: UInt, c: UInt}
  myport.b <= porty
  myport.c <= portx.c
```

In the case where a connection to a sub-element of an aggregate circuit
component is followed by a connection to the entire circuit component, the later
connection overwrites the earlier connections completely.

``` firrtl
module MyModule :
  input portx: {b: UInt, c: UInt}
  input porty: UInt
  output myport: {b: UInt, c: UInt}
  myport.b <= porty
  myport <= portx
```

The above circuit can be rewritten equivalently as follows.

``` firrtl
module MyModule :
  input portx: {b: UInt, c: UInt}
  input porty: UInt
  output myport: {b: UInt, c: UInt}
  myport <= portx
```

See [@sec:sub-fields] for more details about sub-field expressions.

## Empty

The empty statement does nothing and is used simply as a placeholder where a
statement is expected. It is specified using the `skip`{.firrtl} keyword.

The following example:

``` firrtl
a <= b
skip
c <= d
```

can be equivalently expressed as:

``` firrtl
a <= b
c <= d
```

The empty statement is most often used as the `else`{.firrtl} branch in a
conditional statement, or as a convenient placeholder for removed components
during transformational passes. See [@sec:conditionals] for details on the
conditional statement.

## Wires

A wire is a named combinational circuit component that can be connected to and
from using connect statements.

The following example demonstrates instantiating a wire with the given name
`mywire`{.firrtl} and type `UInt`{.firrtl}.

``` firrtl
wire mywire: UInt
```

## Registers

A register is a named stateful circuit component.  Reads from a register return
the current value of the element, writes are not visible until after a positive
edges of the register's clock port.

The clock signal for a register must be of type `Clock`{.firrtl}.  The type of a
register must be a passive type (see [@sec:passive-types]).

The following example demonstrates instantiating a register with the given name
`myreg`{.firrtl}, type `SInt`{.firrtl}, and is driven by the clock signal
`myclock`{.firrtl}.

``` firrtl
wire myclock: Clock
reg myreg: SInt, myclock
; ...
```

A register may be declared with a reset signal and value.  The register's value
is updated with the reset value when the reset is asserted.  The reset signal
must be a `Reset`{.firrtl}, `UInt<1>`{.firrtl}, or `AsyncReset`{.firrtl}, and
the type of initialization value must be equivalent to the declared type of the
register (see [@sec:type-equivalence] for details).  The behavior of the
register depends on the type of the reset signal.  `AsyncReset`.{firrtl} will
immediately change the value of the register.  `UInt<1>`{.firrtl} will not change
the value of the register until the next positive edge of the clock signal (see
[@sec:reset-type]).  `Reset`{.firrtl} is an abstract reset whose behavior
depends on reset inference.  In the following example, `myreg`{.firrtl} is
assigned the value `myinit`{.firrtl} when the signal `myreset`{.firrtl} is high.

``` firrtl
wire myclock: Clock
wire myreset: UInt<1>
wire myinit: SInt
reg myreg: SInt, myclock with: (reset => (myreset, myinit))
; ...
```

A register is initialized with an indeterminate value (see
[@sec:indeterminate-values]).

## Invalidates

An invalidate statement is used to indicate that a circuit component contains
indeterminate values (see [@sec:indeterminate-values]). It is specified as
follows:

``` firrtl
wire w: UInt
w is invalid
```

Invalidate statements can be applied to any circuit component of any
type. However, if the circuit component cannot be connected to, then the
statement has no effect on the component. This allows the invalidate statement
to be applied to any component, to explicitly ignore initialization coverage
errors.

The following example demonstrates the effect of invalidating a variety of
circuit components with aggregate types. See [@sec:the-invalidate-algorithm] for
details on the algorithm for determining what is invalidated.

``` firrtl
module MyModule :
  input in: {flip a: UInt, b: UInt}
  output out: {flip a: UInt, b: UInt}
  wire w: {flip a: UInt, b: UInt}
  in is invalid
  out is invalid
  w is invalid
```

is equivalent to the following:

``` firrtl
module MyModule :
  input in: {flip a: UInt, b: UInt}
  output out: {flip a: UInt, b: UInt}
  wire w: {flip a: UInt, b: UInt}
  in.a is invalid
  out.b is invalid
  w.a is invalid
  w.b is invalid
```

The handing of invalidated components is covered in [@sec:indeterminate-values].

### The Invalidate Algorithm

Invalidating a component with a ground type indicates that the component's value
is undetermined if the component has sink or duplex flow (see [@sec:flows]).
Otherwise, the component is unaffected.

Invalidating a component with a vector type recursively invalidates each
sub-element in the vector.

Invalidating a component with a bundle type recursively invalidates each
sub-element in the bundle.

## Attaches

The `attach`{.firrtl} statement is used to attach two or more analog signals,
defining that their values be the same in a commutative fashion that lacks the
directionality of a regular connection. It can only be applied to signals with
analog type, and each analog signal may be attached zero or more times.

``` firrtl
wire x: Analog<2>
wire y: Analog<2>
wire z: Analog<2>
attach(x, y)      ; binary attach
attach(z, y, x)   ; attach all three signals
```

## Nodes

A node is simply a named intermediate value in a circuit. The node must be
initialized to a value with a passive type and cannot be connected to. Nodes are
often used to split a complicated compound expression into named
sub-expressions.

The following example demonstrates instantiating a node with the given name
`mynode`{.firrtl} initialized with the output of a multiplexer (see
[@sec:multiplexers]).

``` firrtl
wire pred: UInt<1>
wire a: SInt
wire b: SInt
node mynode = mux(pred, a, b)
```

## Conditionals

Connections within a conditional statement that connect to previously declared
components hold only when the given condition is high. The condition must have a
1-bit unsigned integer type.

In the following example, the wire `x`{.firrtl} is connected to the input
`a`{.firrtl} only when the `en`{.firrtl} signal is high. Otherwise, the wire
`x`{.firrtl} is connected to the input `b`{.firrtl}.

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input en: UInt<1>
  wire x: UInt
  when en :
    x <= a
  else :
    x <= b
```

### Syntactic Shorthands

The `else`{.firrtl} branch of a conditional statement may be omitted, in which
case a default `else`{.firrtl} branch is supplied consisting of the empty
statement.

Thus the following example:

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input en: UInt<1>
  wire x: UInt
  when en :
    x <= a
```

can be equivalently expressed as:

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input en: UInt<1>
  wire x: UInt
  when en :
    x <= a
  else :
    skip
```

To aid readability of long chains of conditional statements, the colon following
the `else`{.firrtl} keyword may be omitted if the `else`{.firrtl} branch
consists of a single conditional statement.

Thus the following example:

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input c: UInt
  input d: UInt
  input c1: UInt<1>
  input c2: UInt<1>
  input c3: UInt<1>
  wire x: UInt
  when c1 :
    x <= a
  else :
    when c2 :
      x <= b
    else :
      when c3 :
        x <= c
      else :
        x <= d
```

can be equivalently written as:

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input c: UInt
  input d: UInt
  input c1: UInt<1>
  input c2: UInt<1>
  input c3: UInt<1>
  wire x: UInt
  when c1 :
    x <= a
  else when c2 :
    x <= b
  else when c3 :
    x <= c
  else :
    x <= d
```

To additionally aid readability, a conditional statement where the contents of
the `when`{.firrtl} branch consist of a single line may be combined into a
single line. If an `else`{.firrtl} branch exists, then the `else`{.firrtl}
keyword must be included on the same line.

The following statement:

``` firrtl
when c :
  a <= b
else :
  e <= f
```

can have the `when`{.firrtl} keyword, the `when`{.firrtl} branch, and the
`else`{.firrtl} keyword expressed as a single line:

``` firrtl
when c : a <= b else :
  e <= f
```

The `else`{.firrtl} branch may also be added to the single line:

``` firrtl
when c : a <= b else : e <= f
```

### Nested Declarations

If a component is declared within a conditional statement, connections to the
component are unaffected by the condition. In the following example, register
`myreg1`{.firrtl} is always connected to `a`{.firrtl}, and register
`myreg2`{.firrtl} is always connected to `b`{.firrtl}.

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input en: UInt<1>
  input clk : Clock
  when en :
    reg myreg1 : UInt, clk
    myreg1 <= a
  else :
    reg myreg2 : UInt, clk
    myreg2 <= b
```

Intuitively, a line can be drawn between a connection to a component and that
component's declaration. All conditional statements that are crossed by the line
apply to that connection.

### Initialization Coverage

Because of the conditional statement, it is possible to syntactically express
circuits containing wires that have not been connected to under all conditions.

In the following example, the wire `a`{.firrtl} is connected to the wire
`w`{.firrtl} when `en`{.firrtl} is high, but it is not specified what is
connected to `w`{.firrtl} when `en`{.firrtl} is low.

``` firrtl
module MyModule :
  input en: UInt<1>
  input a: UInt
  wire w: UInt
  when en :
    w <= a
```

This is an illegal FIRRTL circuit and an error will be thrown during
compilation. All wires, memory ports, instance ports, and module ports that can
be connected to must be connected to under all conditions.  Registers do not
need to be connected to under all conditions, as it will keep its previous value
if unconnected.

### Scoping

The conditional statement creates a new *scope* within each of its
`when`{.firrtl} and `else`{.firrtl} branches. It is an error to refer to any
component declared within a branch after the branch has ended. As mention in
[@sec:namespaces], circuit component declarations in a module must be unique
within the module's flat namespace; this means that shadowing a component in an
enclosing scope with a component of the same name inside a conditional statement
is not allowed.

### Conditional Last Connect Semantics

In the case where a connection to a circuit component is followed by a
conditional statement containing a connection to the same component, the
connection is overwritten only when the condition holds. Intuitively, a
multiplexer is generated such that when the condition is low, the multiplexer
returns the old value, and otherwise returns the new value.  For details about
the multiplexer, see [@sec:multiplexers].

The following example:

``` firrtl
wire a: UInt
wire b: UInt
wire c: UInt<1>
wire w: UInt
w <= a
when c :
  w <= b
```

can be rewritten equivalently using a multiplexer as follows:

``` firrtl
wire a: UInt
wire b: UInt
wire c: UInt<1>
wire w: UInt
w <= mux(c, b, a)
```

Because invalid statements assign indeterminate values to components, a FIRRTL
Compiler is free to choose any specific value for an indeterminate value when
resolving last connect semantics.  E.g., in the following circuit `w`{.firrtl}
has an indeterminate value when `c`{.firrtl} is false.

``` firrtl
wire a: UInt
wire c: UInt<1>
wire w: UInt
w is invalid
when c :
  w <= a
```

A FIRRTL compiler is free to optimize this to the following circuit by assuming
that `w`{.firrtl} takes on the value of `a`{.firrtl} when `c`{.firrtl} is false.

``` firrtl
wire a: UInt
wire c: UInt<1>
wire w: UInt
w <= a
```

See [@sec:indeterminate-values] for more information on indeterminate values.

The behavior of conditional connections to circuit components with aggregate
types can be modeled by first expanding each connect into individual connect
statements on its ground elements (see [@sec:the-connection-algorithm;
@sec:the-partial-connection-algorithm] for the connection algorithm) and then
applying the conditional last connect semantics.

For example, the following snippet:

``` firrtl
wire x: {a: UInt, b: UInt}
wire y: {a: UInt, b: UInt}
wire c: UInt<1>
wire w: {a: UInt, b: UInt}
w <= x
when c :
  w <= y
```

can be rewritten equivalently as follows:

``` firrtl
wire x: {a:UInt, b:UInt}
wire y: {a:UInt, b:UInt}
wire c: UInt<1>
wire w: {a:UInt, b:UInt}
w.a <= mux(c, y.a, x.a)
w.b <= mux(c, y.b, x.b)
```

Similar to the behavior of aggregate types under last connect semantics (see
[@sec:last-connect-semantics]), the conditional connects to a sub-element of an
aggregate component only generates a multiplexer for the sub-element that is
overwritten.

For example, the following snippet:

``` firrtl
wire x: {a: UInt, b: UInt}
wire y: UInt
wire c: UInt<1>
wire w: {a: UInt, b: UInt}
w <= x
when c :
  w.a <= y
```

can be rewritten equivalently as follows:

``` firrtl
wire x: {a: UInt, b: UInt}
wire y: UInt
wire c: UInt<1>
wire w: {a: UInt, b: UInt}
w.a <= mux(c, y, x.a)
w.b <= x.b
```

## Memories

A memory is an abstract representation of a hardware memory. It is characterized
by the following parameters.

1.  A passive type representing the type of each element in the memory.

2.  A positive integer representing the number of elements in the memory.

3.  A variable number of named ports, each being a read port, a write port, or
    readwrite port.

4.  A non-negative integer indicating the read latency, which is the number of
    cycles after setting the port's read address before the corresponding
    element's value can be read from the port's data field.

5.  A positive integer indicating the write latency, which is the number of
    cycles after setting the port's write address and data before the
    corresponding element within the memory holds the new value.

6.  A read-under-write flag indicating the behavior when a memory location is
    written to while a read to that location is in progress.

The following example demonstrates instantiating a memory containing 256 complex
numbers, each with 16-bit signed integer fields for its real and imaginary
components. It has two read ports, `r1`{.firrtl} and `r2`{.firrtl}, and one
write port, `w`{.firrtl}. It is combinationally read (read latency is zero
cycles) and has a write latency of one cycle. Finally, its read-under-write
behavior is undefined.

``` firrtl
mem mymem :
  data-type => {real:SInt<16>, imag:SInt<16>}
  depth => 256
  reader => r1
  reader => r2
  writer => w
  read-latency => 0
  write-latency => 1
  read-under-write => undefined
```

In the example above, the type of `mymem`{.firrtl} is:

``` firrtl
{flip r1: {addr: UInt<8>,
           en: UInt<1>,
           clk: Clock,
           flip data: {real: SInt<16>, imag: SInt<16>}},
 flip r2: {addr: UInt<8>,
           en: UInt<1>,
           clk: Clock,
           flip data: {real: SInt<16>, imag: SInt<16>}},
 flip w: {addr: UInt<8>,
          en: UInt<1>,
          clk: Clock,
          data: {real: SInt<16>, imag: SInt<16>},
          mask: {real: UInt<1>, imag: UInt<1>}}}
```

The following sections describe how a memory's field types are calculated and
the behavior of each type of memory port.

### Read Ports

If a memory is declared with element type `T`{.firrtl}, has a size less than or
equal to $2^N$, then its read ports have type:

``` firrtl
{addr: UInt<N>, en: UInt<1>, clk: Clock, flip data: T}
```

If the `en`{.firrtl} field is high, then the element value associated with the
address in the `addr`{.firrtl} field can be retrieved by reading from the
`data`{.firrtl} field after the appropriate read latency. If the `en`{.firrtl}
field is low, then the value in the `data`{.firrtl} field, after the appropriate
read latency, is undefined. The port is driven by the clock signal in the
`clk`{.firrtl} field.

### Write Ports

If a memory is declared with element type `T`{.firrtl}, has a size less than or
equal to $2^N$, then its write ports have type:

``` firrtl
{addr: UInt<N>, en: UInt<1>, clk: Clock, data: T, mask: M}
```

where `M`{.firrtl} is the mask type calculated from the element type
`T`{.firrtl}.  Intuitively, the mask type mirrors the aggregate structure of the
element type except with all ground types replaced with a single bit unsigned
integer type. The *non-masked portion* of the data value is defined as the set
of data value leaf sub-elements where the corresponding mask leaf sub-element is
high.

If the `en`{.firrtl} field is high, then the non-masked portion of the
`data`{.firrtl} field value is written, after the appropriate write latency, to
the location indicated by the `addr`{.firrtl} field. If the `en`{.firrtl} field
is low, then no value is written after the appropriate write latency. The port
is driven by the clock signal in the `clk`{.firrtl} field.

### Readwrite Ports

Finally, the readwrite ports have type:

``` firrtl
{addr: UInt<N>, en: UInt<1>, clk: Clock, flip rdata: T, wmode: UInt<1>,
 wdata: T, wmask: M}
```

A readwrite port is a single port that, on a given cycle, can be used either as
a read or a write port. If the readwrite port is not in write mode (the
`wmode`{.firrtl} field is low), then the `rdata`{.firrtl}, `addr`{.firrtl},
`en`{.firrtl}, and `clk`{.firrtl} fields constitute its read port fields, and
should be used accordingly. If the readwrite port is in write mode (the
`wmode`{.firrtl} field is high), then the `wdata`{.firrtl}, `wmask`{.firrtl},
`addr`{.firrtl}, `en`{.firrtl}, and `clk`{.firrtl} fields constitute its write
port fields, and should be used accordingly.

### Read Under Write Behavior

The read-under-write flag indicates the value held on a read port's
`data`{.firrtl} field if its memory location is written to while it is reading.
The flag may take on three settings: `old`{.firrtl}, `new`{.firrtl}, and
`undefined`{.firrtl}.

If the read-under-write flag is set to `old`{.firrtl}, then a read port always
returns the value existing in the memory on the same cycle that the read was
requested.

Assuming that a combinational read always returns the value stored in the memory
(no write forwarding), then intuitively, this is modeled as a combinational read
from the memory that is then delayed by the appropriate read latency.

If the read-under-write flag is set to `new`{.firrtl}, then a read port always
returns the value existing in the memory on the same cycle that the read was
made available. Intuitively, this is modeled as a combinational read from the
memory after delaying the read address by the appropriate read latency.

If the read-under-write flag is set to `undefined`{.firrtl}, then the value held
by the read port after the appropriate read latency is undefined.

For the purpose of defining such collisions, an "active write port" is a write
port or a readwrite port that is used to initiate a write operation on a given
clock edge, where `en`{.firrtl} is set and, for a readwriter, `wmode`{.firrtl}
is set. An "active read port" is a read port or a readwrite port that is used to
initiate a read operation on a given clock edge, where `en`{.firrtl} is set and,
for a readwriter, `wmode`{.firrtl} is not set.  Each operation is defined to be
"active" for the number of cycles set by its corresponding latency, starting
from the cycle where its inputs were provided to its associated port. Note that
this excludes combinational reads, which are simply modeled as combinationally
selecting from stored values

For memories with independently clocked ports, a collision between a read
operation and a write operation with independent clocks is defined to occur when
the address of an active write port and the address of an active read port are
the same for overlapping clock periods, or when any portion of a read operation
overlaps part of a write operation with a matching addresses. In such cases, the
data that is read out of the read port is undefined.

### Write Under Write Behavior

In all cases, if a memory location is written to by more than one port on the
same cycle, the stored value is undefined.

## Instances

FIRRTL modules are instantiated with the instance statement. The following
example demonstrates creating an instance named `myinstance`{.firrtl} of the
`MyModule`{.firrtl} module within the top level module `Top`{.firrtl}.

``` firrtl
circuit Top :
  module MyModule :
    input a: UInt
    output b: UInt
    b <= a
  module Top :
    inst myinstance of MyModule
```

The resulting instance has a bundle type. Each port of the instantiated module
is represented by a field in the bundle with the same name and type as the
port. The fields corresponding to input ports are flipped to indicate their data
flows in the opposite direction as the output ports.  The `myinstance`{.firrtl}
instance in the example above has type `{flip a:UInt, b:UInt}`.

Modules have the property that instances can always be *inlined* into the parent
module without affecting the semantics of the circuit.

To disallow infinitely recursive hardware, modules cannot contain instances of
itself, either directly, or indirectly through instances of other modules it
instantiates.

## Stops

The stop statement is used to halt simulations of the circuit. Backends are free
to generate hardware to stop a running circuit for the purpose of debugging, but
this is not required by the FIRRTL specification.

A stop statement requires a clock signal, a halt condition signal that has a
single bit unsigned integer type, and an integer exit code.

For clocked statements that have side effects in the environment (stop, print,
and verification statements), the order of execution of any such statements that
are triggered on the same clock edge is determined by their syntactic order in
the enclosing module. The order of execution of clocked, side-effect-having
statements in different modules or with different clocks that trigger
concurrently is undefined.

The stop statement has an optional name attribute which can be used to attach
metadata to the statement. The name is part of the module level
namespace. However it can never be used in a reference since it is not of any
valid type.

``` firrtl
wire clk: Clock
wire halt: UInt<1>
stop(clk, halt, 42) : optional_name
```

## Formatted Prints

The formatted print statement is used to print a formatted string during
simulations of the circuit. Backends are free to generate hardware that relays
this information to a hardware test harness, but this is not required by the
FIRRTL specification.

A `printf`{.firrtl} statement requires a clock signal, a print condition signal, a format
string, and a variable list of argument signals. The condition signal must be a
single bit unsigned integer type, and the argument signals must each have a
ground type.

For information about execution ordering of clocked statements with observable
environmental side effects, see [@sec:stops].

The `printf`{.firrtl} statement has an optional name attribute which can be used to attach
metadata to the statement. The name is part of the module level
namespace. However it can never be used in a reference since it is not of any
valid type.

``` firrtl
wire clk: Clock
wire cond: UInt<1>
wire a: UInt
wire b: UInt
printf(clk, cond, "a in hex: %x, b in decimal:%d.\n", a, b) : optional_name
```

On each positive clock edge, when the condition signal is high, the `printf`{.firrtl}
statement prints out the format string where its argument placeholders are
substituted with the value of the corresponding argument.

### Format Strings

Format strings support the following argument placeholders:

- `%b` : Prints the argument in binary

- `%d` : Prints the argument in decimal

- `%x` : Prints the argument in hexadecimal

- `%%` : Prints a single `%` character

Format strings support the following escape characters:

- `\n` : New line

- `\t` : Tab

- `\\` : Back slash

- `\"` : Double quote

- `\'` : Single quote

## Verification

To facilitate simulation, model checking and formal methods, there are three
non-synthesizable verification statements available: assert, assume and
cover. Each type of verification statement requires a clock signal, a predicate
signal, an enable signal and an explanatory message string literal. The
predicate and enable signals must have single bit unsigned integer type. When an
assert is violated the explanatory message may be issued as guidance. The
explanatory message may be phrased as if prefixed by the words "Verifies
that\...".

Backends are free to generate the corresponding model checking constructs in the
target language, but this is not required by the FIRRTL specification. Backends
that do not generate such constructs should issue a warning. For example, the
SystemVerilog emitter produces SystemVerilog assert, assume and cover
statements, but the Verilog emitter does not and instead warns the user if any
verification statements are encountered.

For information about execution ordering of clocked statements with observable
environmental side effects, see [@sec:stops].

Any verification statement has an optional name attribute which can be used to
attach metadata to the statement. The name is part of the module level
namespace. However it can never be used in a reference since it is not of any
valid type.

### Assert

The assert statement verifies that the predicate is true on the rising edge of
any clock cycle when the enable is true. In other words, it verifies that enable
implies predicate.

``` firrtl
wire clk: Clock
wire pred: UInt<1>
wire en: UInt<1>
pred <= eq(X, Y)
en <= Z_valid
assert(clk, pred, en, "X equals Y when Z is valid") : optional_name
```

### Assume

The assume statement directs the model checker to disregard any states where the
enable is true and the predicate is not true at the rising edge of the clock
cycle. In other words, it reduces the states to be checked to only those where
enable implies predicate is true by definition. In simulation, assume is treated
as an assert.

``` firrtl
wire clk: Clock
wire pred: UInt<1>
wire en: UInt<1>
pred <= eq(X, Y)
en <= Z_valid
assume(clk, pred, en, "X equals Y when Z is valid") : optional_name
```

### Cover

The cover statement verifies that the predicate is true on the rising edge of
some clock cycle when the enable is true. In other words, it directs the model
checker to find some way to make both enable and predicate true at some time
step.

``` firrtl
wire clk: Clock
wire pred: UInt<1>
wire en: UInt<1>
pred <= eq(X, Y)
en <= Z_valid
cover(clk, pred, en, "X equals Y when Z is valid") : optional_name
```

# Expressions

FIRRTL expressions are used for creating literal unsigned and signed integers,
for referring to a declared circuit component, for statically and dynamically
accessing a nested element within a component, for creating multiplexers, and
for performing primitive operations.

## Unsigned Integers

A literal unsigned integer can be created given a non-negative integer value and
an optional positive bit width. The following example creates a 10-bit unsigned
integer representing the number 42.

``` firrtl
UInt<10>(42)
```

Note that it is an error to supply a bit width that is not large enough to fit
the given value. If the bit width is omitted, then the minimum number of bits
necessary to fit the given value will be inferred.

``` firrtl
UInt(42)
```

## Unsigned Integers from Literal Bits

A literal unsigned integer can alternatively be created given a string
representing its bit representation and an optional bit width.

The following radices are supported:

1.`b`{.firrtl} : For representing binary numbers.

2.`o`{.firrtl} : For representing octal numbers.

3.`h`{.firrtl} : For representing hexadecimal numbers.

If a bit width is not given, the number of bits in the bit representation is
directly represented by the string. The following examples create a 8-bit
integer representing the number 13.

``` firrtl
UInt("b00001101")
UInt("h0D")
```

If the provided bit width is larger than the number of bits required to
represent the string's value, then the resulting value is equivalent to the
string zero-extended up to the provided bit width. If the provided bit width is
smaller than the number of bits represented by the string, then the resulting
value is equivalent to the string truncated down to the provided bit width. All
truncated bits must be zero.

The following examples create a 7-bit integer representing the number 13.

``` firrtl
UInt<7>("b00001101")
UInt<7>("o015")
UInt<7>("hD")
```

## Signed Integers

Similar to unsigned integers, a literal signed integer can be created given an
integer value and an optional positive bit width. The following example creates
a 10-bit unsigned integer representing the number -42.

``` firrtl
SInt<10>(-42)
```

Note that it is an error to supply a bit width that is not large enough to fit
the given value using two's complement representation. If the bit width is
omitted, then the minimum number of bits necessary to fit the given value will
be inferred.

``` firrtl
SInt(-42)
```

## Signed Integers from Literal Bits

Similar to unsigned integers, a literal signed integer can alternatively be
created given a string representing its bit representation and an optional bit
width.

The bit representation contains a binary, octal or hex indicator, followed by an
optional sign, followed by the value.

If a bit width is not given, the number of bits in the bit representation is the
minimal bit width to represent the value represented by the string. The following
examples create a 8-bit integer representing the number -13. For all bases, a
negative sign acts as if it were a unary negation; in other words, a negative
literal produces the additive inverse of the unsigned interpretation of the
digit pattern.

``` firrtl
SInt("b-1101")
SInt("h-d")
```

If the provided bit width is larger than the number of bits represented by the
string, then the resulting value is unchanged. It is an error to provide a bit
width smaller than the number of bits required to represent the string's value.

## References

A reference is simply a name that refers to a previously declared circuit
component. It may refer to a module port, node, wire, register, instance, or
memory.

The following example connects a reference expression `in`{.firrtl}, referring
to the previously declared port `in`{.firrtl}, to the reference expression
`out`{.firrtl}, referring to the previously declared port `out`{.firrtl}.

``` firrtl
module MyModule :
  input in: UInt
  output out: UInt
  out <= in
```

In the rest of the document, for brevity, the names of components will be used
to refer to a reference expression to that component. Thus, the above example
will be rewritten as "the port `in`{.firrtl} is connected to the port
`out`{.firrtl}".

## Sub-fields

The sub-field expression refers to a sub-element of an expression with a bundle
type.

The following example connects the `in`{.firrtl} port to the `a`{.firrtl}
sub-element of the `out`{.firrtl} port.

``` firrtl
module MyModule :
  input in: UInt
  output out: {a: UInt, b: UInt}
  out.a <= in
```

## Sub-indices

The sub-index expression statically refers, by index, to a sub-element of an
expression with a vector type. The index must be a non-negative integer and
cannot be equal to or exceed the length of the vector it indexes.

The following example connects the `in`{.firrtl} port to the fifth sub-element
of the `out`{.firrtl} port.

``` firrtl
module MyModule :
  input in: UInt
  output out: UInt[10]
  out[4] <= in
```

## Sub-accesses

The sub-access expression dynamically refers to a sub-element of a vector-typed
expression using a calculated index. The index must be an expression with an
unsigned integer type.  An access to an out-of-bounds element results in an 
indeterminate value (see [@sec:indeterminate-values]).  Each out-of-bounds 
element is a different indeterminate value.  Sub-access operations with constant
index may be convereted to sub-index operations even though it converts
indeterminate-value-on-out-of-bounds behavior to a compile-time error.

The following example connects the n'th sub-element of the `in`{.firrtl} port to
the `out`{.firrtl} port.

``` firrtl
module MyModule :
  input in: UInt[3]
  input n: UInt<2>
  output out: UInt
  out <= in[n]
```

A connection from a sub-access expression can be modeled by conditionally
connecting from every sub-element in the vector, where the condition holds when
the dynamic index is equal to the sub-element's static index.

``` firrtl
module MyModule :
  input in: UInt[3]
  input n: UInt<2>
  output out: UInt
  when eq(n, UInt(0)) :
    out <= in[0]
  else when eq(n, UInt(1)) :
    out <= in[1]
  else when eq(n, UInt(2)) :
    out <= in[2]
  else :
    out is invalid
```

The following example connects the `in`{.firrtl} port to the n'th sub-element of
the `out`{.firrtl} port. All other sub-elements of the `out`{.firrtl} port are
connected from the corresponding sub-elements of the `default`{.firrtl} port.

``` firrtl
module MyModule :
  input in: UInt
  input default: UInt[3]
  input n: UInt<2>
  output out: UInt[3]
  out <= default
  out[n] <= in
```

A connection to a sub-access expression can be modeled by conditionally
connecting to every sub-element in the vector, where the condition holds when
the dynamic index is equal to the sub-element's static index.

``` firrtl
module MyModule :
  input in: UInt
  input default: UInt[3]
  input n: UInt<2>
  output out: UInt[3]
  out <= default
  when eq(n, UInt(0)) :
    out[0] <= in
  else when eq(n, UInt(1)) :
    out[1] <= in
  else when eq(n, UInt(2)) :
    out[2] <= in
```

The following example connects the `in`{.firrtl} port to the m'th
`UInt`{.firrtl} sub-element of the n'th vector-typed sub-element of the
`out`{.firrtl} port. All other sub-elements of the `out`{.firrtl} port are
connected from the corresponding sub-elements of the `default`{.firrtl} port.

``` firrtl
module MyModule :
  input in: UInt
  input default: UInt[2][2]
  input n: UInt<1>
  input m: UInt<1>
  output out: UInt[2][2]
  out <= default
  out[n][m] <= in
```

A connection to an expression containing multiple nested sub-access expressions
can also be modeled by conditionally connecting to every sub-element in the
expression. However the condition holds only when all dynamic indices are equal
to all of the sub-element's static indices.

``` firrtl
module MyModule :
  input in: UInt
  input default: UInt[2][2]
  input n: UInt<1>
  input m: UInt<1>
  output out: UInt[2][2]
  out <= default
  when and(eq(n, UInt(0)), eq(m, UInt(0))) :
    out[0][0] <= in
  else when and(eq(n, UInt(0)), eq(m, UInt(1))) :
    out[0][1] <= in
  else when and(eq(n, UInt(1)), eq(m, UInt(0))) :
    out[1][0] <= in
  else when and(eq(n, UInt(1)), eq(m, UInt(1))) :
    out[1][1] <= in
```

## Multiplexers

A multiplexer outputs one of two input expressions depending on the value of an
unsigned selection signal.

The following example connects to the `c`{.firrtl} port the result of selecting
between the `a`{.firrtl} and `b`{.firrtl} ports. The `a`{.firrtl} port is
selected when the `sel`{.firrtl} signal is high, otherwise the `b`{.firrtl} port
is selected.

``` firrtl
module MyModule :
  input a: UInt
  input b: UInt
  input sel: UInt<1>
  output c: UInt
  c <= mux(sel, a, b)
```

A multiplexer expression is legal only if the following holds.

1. The type of the selection signal is an unsigned integer.

1. The width of the selection signal is any of:

    1. One-bit

    1. Unspecified, but will infer to one-bit

1. The types of the two input expressions are equivalent.

1. The types of the two input expressions are passive (see
   [@sec:passive-types]).

## Primitive Operations

All fundamental operations on ground types are expressed as a FIRRTL primitive
operation. In general, each operation takes some number of argument expressions,
along with some number of static integer literal parameters.

The general form of a primitive operation is expressed as follows:

``` firrtl
op(arg0, arg1, ..., argn, int0, int1, ..., intm)
```

The following examples of primitive operations demonstrate adding two
expressions, `a`{.firrtl} and `b`{.firrtl}, shifting expression `a`{.firrtl}
left by 3 bits, selecting the fourth bit through and including the seventh bit
in the `a`{.firrtl} expression, and interpreting the expression `x`{.firrtl} as
a Clock typed signal.

``` firrtl
add(a, b)
shl(a, 3)
bits(a, 7, 4)
asClock(x)
```

[@sec:primitive-operations] will describe the format and semantics of each
primitive operation.

# Primitive Operations {#sec:primitive-operations}

The arguments of all primitive operations must be expressions with ground types,
while their parameters are static integer literals. Each specific operation can
place additional restrictions on the number and types of their arguments and
parameters.

Notationally, the width of an argument e is represented as w~e~.

## Add Operation

| Name | Arguments | Parameters | Arg Types     | Result Type | Result Width                |
|------|-----------|------------|---------------|-------------|-----------------------------|
| add  | (e1,e2)   | ()         | (UInt,UInt)   | UInt        | max(w~e1~,w~e2~)+1          |
|      |           |            | (SInt,SInt)   | SInt        | max(w~e1~,w~e2~)+1          |

The add operation result is the sum of e1 and e2 without loss of precision.

## Subtract Operation


| Name | Arguments | Parameters | Arg Types     | Result Type | Result Width                |
|------|-----------|------------|---------------|-------------|-----------------------------|
| sub  | (e1,e2)   | ()         | (UInt,UInt)   | UInt        | max(w~e1~,w~e2~)+1          |
|      |           |            | (SInt,SInt)   | SInt        | max(w~e1~,w~e2~)+1          |

The subtract operation result is e2 subtracted from e1, without loss of
precision.

## Multiply Operation

| Name | Arguments | Parameters | Arg Types     | Result Type | Result Width                |
|------|-----------|------------|---------------|-------------|-----------------------------|
| mul  | (e1,e2)   | ()         | (UInt,UInt)   | UInt        | w~e1~+w~e2~                 |
|      |           |            | (SInt,SInt)   | SInt        | w~e1~+w~e2~                 |

The multiply operation result is the product of e1 and e2, without loss of
precision.

## Divide Operation


| Name | Arguments | Parameters | Arg Types   | Result Type | Result Width |
|------|-----------|------------|-------------|-------------|--------------|
| div  | (num,den) | ()         | (UInt,UInt) | UInt        | w~num~       |
|      |           |            | (SInt,SInt) | SInt        | w~num~+1     |

The divide operation divides num by den, truncating the fractional portion of
the result. This is equivalent to rounding the result towards zero. The result
of a division where den is zero is undefined.

## Modulus Operation

| Name | Arguments | Parameters | Arg Types   | Result Type | Result Width       |
|------|-----------|------------|-------------|-------------|--------------------|
| rem  | (num,den) | ()         | (UInt,UInt) | UInt        | min(w~num~,w~den~) |
|      |           |            | (SInt,SInt) | SInt        | min(w~num~,w~den~) |

The modulus operation yields the remainder from dividing num by den, keeping the
sign of the numerator. Together with the divide operator, the modulus operator
satisfies the relationship below:

    num = add(mul(den,div(num,den)),rem(num,den))}

## Comparison Operations

| Name   | Arguments | Parameters | Arg Types     | Result Type | Result Width |
|--------|-----------|------------|---------------|-------------|--------------|
| lt,leq |           |            | (UInt,UInt)   | UInt        | 1            |
| gt,geq | (e1,e2)   | ()         | (SInt,SInt)   | UInt        | 1            |

The comparison operations return an unsigned 1 bit signal with value one if e1
is less than (lt), less than or equal to (leq), greater than (gt), greater than
or equal to (geq), equal to (eq), or not equal to (neq) e2.  The operation
returns a value of zero otherwise.

## Padding Operations

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width                |
|------|-----------|------------|-----------|-------------|-----------------------------|
| pad  | \(e\)     | \(n\)      | (UInt)    | UInt        | max(w~e~,n)                 |
|      |           |            | (SInt)    | SInt        | max(w~e~,n)                 |


If e's bit width is smaller than n, then the pad operation zero-extends or
sign-extends e up to the given width n. Otherwise, the result is simply e. n
must be non-negative.

## Interpret As UInt

| Name   | Arguments | Parameters | Arg Types    | Result Type | Result Width |
|--------|-----------|------------|--------------|-------------|--------------|
| asUInt | \(e\)     | ()         | (UInt)       | UInt        | w~e~         |
|        |           |            | (SInt)       | UInt        | w~e~         |
|        |           |            | (Clock)      | UInt        | 1            |
|        |           |            | (Reset)      | UInt        | 1            |
|        |           |            | (AsyncReset) | UInt        | 1            |

The interpret as UInt operation reinterprets e's bits as an unsigned integer.

## Interpret As SInt

| Name   | Arguments | Parameters | Arg Types    | Result Type | Result Width |
|--------|-----------|------------|--------------|-------------|--------------|
| asSInt | \(e\)     | ()         | (UInt)       | SInt        | w~e~         |
|        |           |            | (SInt)       | SInt        | w~e~         |
|        |           |            | (Clock)      | SInt        | 1            |
|        |           |            | (Reset)      | SInt        | 1            |
|        |           |            | (AsyncReset) | SInt        | 1            |

The interpret as SInt operation reinterprets e's bits as a signed integer
according to two's complement representation.

## Interpret as Clock

| Name    | Arguments | Parameters | Arg Types    | Result Type | Result Width |
|---------|-----------|------------|--------------|-------------|--------------|
| asClock | \(e\)     | ()         | (UInt)       | Clock       | n/a          |
|         |           |            | (SInt)       | Clock       | n/a          |
|         |           |            | (Clock)      | Clock       | n/a          |
|         |           |            | (Reset)      | Clock       | n/a          |
|         |           |            | (AsyncReset) | Clock       | n/a          |

The result of the interpret as clock operation is the Clock typed signal
obtained from interpreting a single bit integer as a clock signal.

## Interpret as AsyncReset

| Name         | Arguments | Parameters | Arg Types    | Result Type | Result Width |
|--------------|-----------|------------|--------------|-------------|--------------|
| asAsyncReset | \(e\)     | ()         | (AsyncReset) | AsyncReset  | n/a          |
|              |           |            | (UInt)       | AsyncReset  | n/a          |
|              |           |            | (SInt)       | AsyncReset  | n/a          |
|              |           |            | (Interval)   | AsyncReset  | n/a          |
|              |           |            | (Clock)      | AsyncReset  | n/a          |
|              |           |            | (Reset)      | AsyncReset  | n/a          |

The result of the interpret as asynchronous reset operation is an AsyncReset typed
signal.

## Shift Left Operation

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width                |
|------|-----------|------------|-----------|-------------|-----------------------------|
| shl  | \(e\)     | \(n\)      | (UInt)    | UInt        | w~e~+n                      |
|      |           |            | (SInt)    | SInt        | w~e~+n                      |

The shift left operation concatenates n zero bits to the least significant end
of e. n must be non-negative.

## Shift Right Operation

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width                |
|------|-----------|------------|-----------|-------------|-----------------------------|
| shr  | \(e\)     | \(n\)      | (UInt)    | UInt        | max(w~e~-n, 1)              |
|      |           |            | (SInt)    | SInt        | max(w~e~-n, 1)              |

The shift right operation truncates the least significant n bits from e.  If n
is greater than or equal to the bit-width of e, the resulting value will be zero
for unsigned types and the sign bit for signed types. n must be non-negative.

## Dynamic Shift Left Operation

| Name | Arguments | Parameters | Arg Types     | Result Type | Result Width                |
|------|-----------|------------|---------------|-------------|-----------------------------|
| dshl | (e1, e2)  | ()         | (UInt, UInt)  | UInt        | w~e1~ + 2`^`w~e2~ - 1       |
|      |           |            | (SInt, UInt)  | SInt        | w~e1~ + 2`^`w~e2~ - 1       |

The dynamic shift left operation shifts the bits in e1 e2 places towards the
most significant bit. e2 zeroes are shifted in to the least significant bits.

## Dynamic Shift Right Operation

| Name | Arguments | Parameters | Arg Types     | Result Type | Result Width                |
|------|-----------|------------|---------------|-------------|-----------------------------|
| dshr | (e1, e2)  | ()         | (UInt, UInt)  | UInt        | w~e1~                       |
|      |           |            | (SInt, UInt)  | SInt        | w~e1~                       |

The dynamic shift right operation shifts the bits in e1 e2 places towards the
least significant bit. e2 signed or zeroed bits are shifted in to the most
significant bits, and the e2 least significant bits are truncated.

## Arithmetic Convert to Signed Operation

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width |
|------|-----------|------------|-----------|-------------|--------------|
| cvt  | \(e\)     | ()         | (UInt)    | SInt        | w~e~+1       |
|      |           |            | (SInt)    | SInt        | w~e~         |

The result of the arithmetic convert to signed operation is a signed integer
representing the same numerical value as e.

## Negate Operation

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width |
|------|-----------|------------|-----------|-------------|--------------|
| neg  | \(e\)     | ()         | (UInt)    | SInt        | w~e~+1       |
|      |           |            | (SInt)    | SInt        | w~e~+1       |

The result of the negate operation is a signed integer representing the negated
numerical value of e.

## Bitwise Complement Operation

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width |
|------|-----------|------------|-----------|-------------|--------------|
| not  | \(e\)     | ()         | (UInt)    | UInt        | w~e~         |
|      |           |            | (SInt)    | UInt        | w~e~         |

The bitwise complement operation performs a logical not on each bit in e.

## Binary Bitwise Operations

| Name       | Arguments | Parameters | Arg Types   | Result Type | Result Width     |
|------------|-----------|------------|-------------|-------------|------------------|
| and,or,xor | (e1, e2)  | ()         | (UInt,UInt) | UInt        | max(w~e1~,w~e2~) |
|            |           |            | (SInt,SInt) | UInt        | max(w~e1~,w~e2~) |

The above bitwise operations perform a bitwise and, or, or exclusive or on e1
and e2. The result has the same width as its widest argument, and any narrower
arguments are automatically zero-extended or sign-extended to match the width of
the result before performing the operation.

## Bitwise Reduction Operations


| Name          | Arguments | Parameters | Arg Types | Result Type | Result Width |
|---------------|-----------|------------|-----------|-------------|--------------|
| andr,orr,xorr | \(e\)     | ()         | (UInt)    | UInt        | 1            |
|               |           |            | (SInt)    | UInt        | 1            |

The bitwise reduction operations correspond to a bitwise and, or, and exclusive
or operation, reduced over every bit in e.

In all cases, the reduction incorporates as an inductive base case the "identity
value" associated with each operator. This is defined as the value that
preserves the value of the other argument: one for and (as $x \wedge 1 = x$),
zero for or (as $x \vee 0 = x$), and zero for xor (as $x \oplus 0 = x$). Note
that the logical consequence is that the and-reduction of a zero-width
expression returns a one, while the or- and xor-reductions of a zero-width
expression both return zero.

## Concatenate Operation

| Name | Arguments | Parameters | Arg Types      | Result Type | Result Width |
|------|-----------|------------|----------------|-------------|--------------|
| cat  | (e1,e2)   | ()         | (UInt, UInt)   | UInt        | w~e1~+w~e2~  |
|      |           |            | (SInt, SInt)   | UInt        | w~e1~+w~e2~  |

The result of the concatenate operation is the bits of e1 concatenated to the
most significant end of the bits of e2.

## Bit Extraction Operation

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width |
|------|-----------|------------|-----------|-------------|--------------|
| bits | \(e\)     | (hi,lo)    | (UInt)    | UInt        | hi-lo+1      |
|      |           |            | (SInt)    | UInt        | hi-lo+1      |

The result of the bit extraction operation are the bits of e between lo
(inclusive) and hi (inclusive). hi must be greater than or equal to lo.  Both hi
and lo must be non-negative and strictly less than the bit width of e.

## Head

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width |
|------|-----------|------------|-----------|-------------|--------------|
| head | \(e\)     | \(n\)      | (UInt)    | UInt        | n            |
|      |           |            | (SInt)    | UInt        | n            |

The result of the head operation are the n most significant bits of e. n must be
non-negative and less than or equal to the bit width of e.

## Tail

| Name | Arguments | Parameters | Arg Types | Result Type | Result Width |
|------|-----------|------------|-----------|-------------|--------------|
| tail | \(e\)     | \(n\)      | (UInt)    | UInt        | w~e~-n       |
|      |           |            | (SInt)    | UInt        | w~e~-n       |

The tail operation truncates the n most significant bits from e. n must be
non-negative and less than or equal to the bit width of e.

# Flows

An expression's flow partially determines the legality of connecting to and from
the expression. Every expression is classified as either *source*, *sink*, or
*duplex*. For details on connection rules refer back to [@sec:connects;
@sec:partial-connects].

The flow of a reference to a declared circuit component depends on the kind of
circuit component. A reference to an input port, an instance, a memory, and a
node, is a source. A reference to an output port is a sink. A reference to a
wire or register is duplex.

The flow of a sub-index or sub-access expression is the flow of the vector-typed
expression it indexes or accesses.

The flow of a sub-field expression depends upon the orientation of the field. If
the field is not flipped, its flow is the same flow as the bundle-typed
expression it selects its field from. If the field is flipped, then its flow is
the reverse of the flow of the bundle-typed expression it selects its field
from. The reverse of source is sink, and vice-versa. The reverse of duplex
remains duplex.

The flow of all other expressions are source.

# Width Inference

For all circuit components declared with unspecified widths, the FIRRTL compiler
will infer the minimum possible width that maintains the legality of all its
incoming connections. If a component has no incoming connections, and the width
is unspecified, then an error is thrown to indicate that the width could not be
inferred.

For module input ports with unspecified widths, the inferred width is the
minimum possible width that maintains the legality of all incoming connections
to all instantiations of the module.

The width of a ground-typed multiplexer expression is the maximum of its two
corresponding input widths. For multiplexing aggregate-typed expressions, the
resulting widths of each leaf sub-element is the maximum of its corresponding
two input leaf sub-element widths.

The width of a conditionally valid expression is the width of its input
expression.

The width of each primitive operation is detailed in [@sec:primitive-operations].

The width of the integer literal expressions is detailed in their respective
sections.

# Combinational Loops

Combinational logic is a section of logic with no registers between gates.
A combinational loop exists when the output of some combinational logic
is fed back into the input of that combinational logic with no intervening
register. FIRRTL does not support combinational loops even if it is possible
to show that the loop does not exist under actual mux select values.
Combinational loops are not allowed and designs should not depend on any FIRRTL
transformation to remove or break such combinational loops.

The module `Foo` has a combinational loop and is not legal,
even though the loop will be removed by last connect semantics.
``` firrtl
  module Foo:
    input a: UInt<1>
    output b: UInt<1>
    b <= b
    b <= a
 ```

The following module `Foo2` has a combinational loop, even if it can be proved
that `n1` and `n2` never overlap.
``` firrtl
module Foo2 :
  input n1: UInt<2>
  input n2: UInt<2>
  wire tmp: UInt<1>
  wire vec: UInt<1>[3]
  tmp <= vec[n1]
  vec[n2] <= tmp
```

Module `Foo3` is another example of an illegal combinational loop, even if it
only exists at the word level and not at the bit-level.

```firrtl
module Foo3
  wire a : UInt<2>
  wire b : UInt<1>

  a <= cat(b, c)
  b <= bits(a, 0, 0)

```


# Namespaces

All modules in a circuit exist in the same module namespace, and thus must all
have a unique name.

Each module has an identifier namespace containing the names of all port and
circuit component declarations. Thus, all declarations within a module must have
unique names.

Within a bundle type declaration, all field names must be unique.

Within a memory declaration, all port names must be unique.

Any modifications to names must preserve the uniqueness of names within a
namespace.

# Annotations

Annotations encode arbitrary metadata and associate it with zero or more
targets ([@sec:targets]) in a FIRRTL circuit.

Annotations are represented as a dictionary, with a "class" field which
describes which annotation it is, and a "target" field which represents the IR
object it is attached to. Annotations may have arbitrary additional fields
attached. Some annotation classes extend other annotations, which effectively
means that the subclass annotation implies to effect of the parent annotation.

Annotations are serializable to JSON.

Below is an example annotation used to mark some module `foo`:

```json
{
  "class":"myannotationpackage.FooAnnotation",
  "target":"~MyCircuit|MyModule>foo"
}
```

## Targets

A circuit is described, stored, and optimized in a folded representation. For
example, there may be multiple instances of a module which will eventually
become multiple physical copies of that module on the die.

Targets are a mechanism to identify specific hardware in specific instances of
modules in a FIRRTL circuit.  A target consists of a circuit, a root module, an
optional instance hierarchy, and an optional reference. A target can only
identify hardware with a name, e.g., a circuit, module, instance, register,
wire, or node. References may further refer to specific fields or subindices in
aggregates. A target with no instance hierarchy is local. A target with an
instance hierarchy is non-local.

Targets use a shorthand syntax of the form:

```ebnf
target = “~” , circuit ,
         [ “|” , module , { “/” (instance) “:” (module) } , [ “>” , ref ] ]
```

A reference is a name inside a module and one or more qualifying tokens that
encode subfields (of a bundle) or subindices (of a vector):

```ebnf
ref = name , { ( "[" , index , "]" ) | ( "." , field ) }
```

Targets are specific enough to refer to any specific module in a folded,
unfolded, or partially folded representation.

To show some examples of what these look like, consider the following example
circuit. This consists of four instances of module `Baz`, two instances of
module `Bar`, and one instance of module `Foo`:

```firrtl
circuit Foo:
  module Foo:
    inst a of Bar
    inst b of Bar
  module Bar:
    inst c of Baz
    inst d of Baz
  module Baz:
    skip
```

This circuit can be represented in a _folded_, completely _unfolded_, or in some
_partially folded_ state.  Figure [@fig:foo-folded] shows the folded
representation.  Figure [@fig:foo-unfolded] shows the completely unfolded
representation where each instance is broken out into its own module.

![A folded representation of circuit Foo](build/img/firrtl-folded-module.eps){#fig:foo-folded width=15%}

![A completely unfolded representation of circuit Foo](build/img/firrtl-unfolded-module.eps){#fig:foo-unfolded}

Using targets (or multiple targets), any specific module, instance, or
combination of instances can be expressed. Some examples include:

Target                   Description
-----------------------  -------------
`~Foo`                   refers to the whole circuit
`~Foo|Foo`               refers to the top module
`~Foo|Bar`               refers to module `Bar` (or both instances of module `Bar`)
`~Foo|Foo/a:Bar`         refers just to one instance of module `Bar`
`~Foo|Foo/b:Bar/c:Baz`   refers to one instance of module `Baz`
`~Foo|Bar/d:Baz`         refers to two instances of module `Baz`

If a target does not contain an instance path, it is a _local_ target.  A local
target points to all instances of a module.  If a target contains an instance
path, it is a _non-local_ target.  A non-local target _may_ not point to all
instances of a module.  Additionally, a non-local target may have an equivalent
local target representation.

## Annotation Storage

Annotations may be stored in one or more JSON files using an
array-of-dictionaries format.  The following shows a valid annotation file
containing two annotations:

``` json
[
  {
    "class":"hello",
    "target":"~Foo|Bar"
  },
  {
    "class":"world",
    "target":"~Foo|Baz"
  }
]
```

Annotations may also be stored in-line along with the FIRRTL circuit by wrapping
Annotation JSON in `%[ ... ]`.  The following shows the above annotation file
stored in-line:

``` firrtl
circuit Foo: %[[
  {
    "class":"hello",
    "target":"~Foo|Bar"
  },
  {
    "class":"world",
    "target":"~Foo|Baz"
  }
]]
  module : Foo
  ; ...
```

Any legal JSON is allowed, meaning that the above JSON may be stored "minimized"
all on one line.

# Semantics of Values

FIRRTL is defined for 2-state boolean logic.  The behavior of a generated
circuit in a language, such as Verilog or VHDL, which have multi-state logic, is
undefined in the presence of values which are not 2-state.  A FIRRTL compiler
need only respect the 2-state behavior of a circuit.  This is a limitation on
the scope of what behavior is observable (i.e., a relaxation of the
["as-if"](https://en.wikipedia.org/wiki/As-if_rule) rule).

## Indeterminate Values

An indeterminate value represents a value which is unknown or unspecified.
Indeterminate values are generally implementation defined, with constraints
specified below.  An indeterminate value may be assumed to be any specific
value (not necessarily literal), at an implementation's discretion, if, in doing
so, all observable behavior is as if the indeterminate value always took the
specific value.

This allows transformations such as the following, where when `a` has an
indeterminate value, the implementation chooses to consistently give it a value
of 'v'.  An alternate, legal mapping, lets the implementation give it the value
`42`.  In both cases, there is no visibility of `a` when it has an indeterminate
value which is not mapped to the value the implementation chooses.

``` firrtl
module IValue :
  output o : UInt<8>
  input c : UInt<1>
  input v : UInt<8>

  wire a : UInt<8>
  a is invalid
  when c :
    a <= v
  o <= a
```
is transformed to:
``` firrtl
module IValue :
  output o : UInt<8>
  input c : UInt<1>

  o <= v
```
Note that it is equally correct to produce:
``` firrtl
module IValue :
  output o : UInt<8>
  input c : UInt<1>

  wire a : UInt<8>
  when c :
    a <= v
  else :
    a <= UInt<3>("h42")
  o <= a
```

The behavior of constructs which cause indeterminate values is implementation
defined with the following constraints.
- Register initialization is done in a consistent way for all registers.  If
code is generated to randomly initialize some registers (or 0 fill them, etc),
it should be generated for all registers.
- All observations of a unique instance of an expression with indeterminate
value must see the same value at runtime.  Multiple readers of a value will see
the same runtime value.
- Indeterminate values captured in stateful elements are not time-varying.
Time-aware constructs, such as registers, which hold an indeterminate value will
return the same runtime value unless something changes the value in a normal
way.  For example, an uninitialized register will return the same value over
multiple clock cycles until it is written (or reset).
- The value produced at runtime for an expression which produced an intermediate
value shall only be a function of the inputs of the expression.  For example, an
out-of-bounds vector access shall produce the same value for a
given out-of-bounds index and vector contents.
- Two constructs with indeterminate values place no constraint on the identity
of their values.  For example, two uninitialized registers, which therefore
contain indeterminate values, do not need to be equal under comparison.

# Details about Syntax

FIRRTL's syntax is designed to be human-readable but easily algorithmically
parsed.

The following characters are allowed in identifiers: upper and lower case
letters, digits, and `_`{.firrtl}. Identifiers cannot begin with a digit.

An integer literal in FIRRTL begins with one of the following, where '\#'
represents a digit between 0 and 9.

- 'h' : For indicating a hexadecimal number, followed by an optional sign. The
  rest of the literal must consist of either digits or a letter between 'A' and
  'F'.

- 'o' : For indicating an octal number, followed by an optional sign.  The rest
  of the literal must consist of digits between 0 and 7.

- 'b' : For indicating a binary number, followed by an optional sign.  The rest
  of the literal must consist of digits that are either 0 or 1.

- '-\#' : For indicating a negative decimal number. The rest of the literal must
  consist of digits between 0 and 9.

- '\#' : For indicating a positive decimal number. The rest of the literal must
  consist of digits between 0 and 9.

Comments begin with a semicolon and extend until the end of the line.  Commas
are treated as whitespace, and may be used by the user for clarity if desired.

In FIRRTL, indentation is significant. Indentation must consist of spaces
only---tabs are illegal characters. The number of spaces appearing before a
FIRRTL IR statement is used to establish its *indent level*. Statements with the
same indent level have the same context. The indent level of the
`circuit`{.firrtl} declaration must be zero.

Certain constructs (`circuit`{.firrtl}, `module`{.firrtl}, `when`{.firrtl}, and
`else`{.firrtl}) create a new sub-context. The indent used on the first line of
the sub-context establishes the indent level. The indent level of a sub-context
is one higher than the parent. All statements in the sub-context must be
indented by the same number of spaces. To end the sub-context, a line must
return to the indent level of the parent.

Since conditional statements (`when`{.firrtl} and `else`{.firrtl}) may be
nested, it is possible to create a hierarchy of indent levels, each with its own
number of preceding spaces that must be larger than its parent's and consistent
among all direct child statements (those that are not children of an even deeper
conditional statement).

As a concrete guide, a few consequences of these rules are summarized below:

- The `circuit`{.firrtl} keyword must not be indented.

- All `module`{.firrtl} keywords must be indented by the same number of spaces.

- In a module, all port declarations and all statements (that are not children
  of other statements) must be indented by the same number of spaces.

- The number of spaces comprising the indent level of a module is specific to
  each module.

- The statements comprising a conditional statement's branch must be indented by
  the same number of spaces.

- The statements of nested conditional statements establish their own, deeper
  indent level.

- Each `when`{.firrtl} and each `else`{.firrtl} context may have a different
  number of non-zero spaces in its indent level.

As an example illustrating some of these points, the following is a legal FIRRTL
circuit:

``` firrtl
circuit Foo :
    module Foo :
      skip
    module Bar :
     input a: UInt<1>
     output b: UInt<1>
     when a:
         b <= a
     else:
       b <= not(a)
```

All circuits, modules, ports and statements can optionally be followed with the
info token `@[fileinfo]` where fileinfo is a string containing the source file
information from where it was generated. The following characters need to be
escaped with a leading '`\`': '`\n`' (new line), '`\t`' (tab), '`]`' and '`\`'
itself.

The following example shows the info tokens included:

``` firrtl
circuit Top : @[myfile.txt 14:8]
  module Top : @[myfile.txt 15:2]
    output out: UInt @[myfile.txt 16:3]
    input b: UInt<32> @[myfile.txt 17:3]
    input c: UInt<1> @[myfile.txt 18:3]
    input d: UInt<16> @[myfile.txt 19:3]
    wire a: UInt @[myfile.txt 21:8]
    when c : @[myfile.txt 24:8]
      a <= b @[myfile.txt 27:16]
    else :
      a <= d @[myfile.txt 29:17]
    out <= add(a,a) @[myfile.txt 34:4]
```

# FIRRTL Compiler Implementation Details

This section provides auxiliary information necessary for developers of a FIRRTL
Compiler _implementation_.  A FIRRTL Compiler is a program that converts FIRRTL
text to another representation, e.g., Verilog, VHDL, a programming language, or
a binary program.

## Aggregate Type Lowering (Lower Types)

A FIRRTL Compiler should provide a "Lower Types" pass that converts aggregate
types to ground types.

A FIRRTL Compiler must apply such a pass to the ports of all "public" modules in
a Verilog/VHDL representation.  Public modules are defined as (1) the top-level
module and (2) any external modules.

A FIRRTL Compiler may apply such a pass to other types in a FIRRTL circuit.

The Lower Types algorithm operates as follows:

1. Ground type names are unmodified.

2. Vector types are converted to ground types by appending a suffix, `_<i>`, to
   the i^th^ element of the vector.  (`<` and `>` are not included in the
   suffix.)

3. Bundle types are converted to ground types by appending a suffix, `_<name>`,
   to the field called `name`.  (`<` and `>` are not included in the suffix.)

New names generated by Lower Types must be unique with respect to the current
namespace (see [@sec:namespaces]).

E.g., consider the following wire:

``` firrtl
wire a : { b: UInt<1>, c: UInt<2> }[2]
```

The result of a Lower Types pass applied to this wire is:

``` firrtl
wire a_0_b : UInt<1>
wire a_0_c : UInt<2>
wire a_1_b : UInt<1>
wire a_1_c : UInt<2>
```

\clearpage

# FIRRTL Language Definition

``` ebnf
(* Whitespace definitions *)
indent = " " , { " " } ;
dedent = ? remove one level of indentation ? ;
newline = ? a newline character ? ;

(* Integer literal definitions  *)
digit_bin = "0" | "1" ;
digit_oct = digit_bin | "2" | "3" | "4" | "5" | "6" | "7" ;
digit_dec = digit_oct | "8" | "9" ;
digit_hex = digit_dec
          | "A" | "B" | "C" | "D" | "E" | "F"
          | "a" | "b" | "c" | "d" | "e" | "f" ;

(* An integer *)
int = '"' , "b" , [ "-" ] , { digit_bin } , '"'
    | '"' , "o" , [ "-" ] , { digit_oct } , '"'
    | '"' , "h" , [ "-" ] , { digit_hex } , '"'
    |             [ "-" ] , { digit_bin } ;

(* Identifiers define legal FIRRTL or Verilog names *)
letter = "A" | "B" | "C" | "D" | "E" | "F" | "G"
       | "H" | "I" | "J" | "K" | "L" | "M" | "N"
       | "O" | "P" | "Q" | "R" | "S" | "T" | "U"
       | "V" | "W" | "X" | "Y" | "Z"
       | "a" | "b" | "c" | "d" | "e" | "f" | "g"
       | "h" | "i" | "j" | "k" | "l" | "m" | "n"
       | "o" | "p" | "q" | "r" | "s" | "t" | "u"
       | "v" | "w" | "x" | "y" | "z" ;
id = ( "_" | letter ) , { "_" | letter | digit_dec } ;

(* Fileinfo communicates Chisel source file and line/column info *)
linecol = digit_dec , { digit_dec } , ":" , digit_dec , { digit_dec } ;
info = "@" , "[" , { string , " " , linecol } , "]" ;

(* Type definitions *)
width = "<" , int , ">" ;
type_ground = "Clock" | "Reset" | "AsyncReset"
            | ( "UInt" | "SInt" | "Analog" ) , [ width ] ;
type_aggregate = "{" , field , { field } , "}"
               | type , "[" , int , "]" ;
field = [ "flip" ] , id , ":" , type ;
type = type_ground | type_aggregate ;

(* Primitive operations *)
primop_2expr_keyword =
    "add"  | "sub" | "mul" | "div" | "mod"
  | "lt"   | "leq" | "gt"  | "geq" | "eq" | "neq"
  | "dshl" | "dshr"
  | "and"  | "or"  | "xor" | "cat" ;
primop_2expr =
    primop_2expr_keyword , "(" , expr , "," , expr ")" ;
primop_1expr_keyword =
    "asUInt" | "asSInt" | "asClock" | "cvt"
  | "neg"    | "not"
  | "andr"   | "orr"    | "xorr" ;
primop_1expr =
    primop_1expr_keyword , "(" , expr , ")" ;
primop_1expr1int_keyword =
    "pad" | "shl" | "shr" | "head" | "tail" ;
primop_1expr1int =
    primop_1exrp1int_keyword , "(", expr , "," , int , ")" ;
primop_1expr2int_keyword =
    "bits" ;
primop_1expr2int =
    primop_1expr2int_keyword , "(" , expr , "," , int , "," , int , ")" ;
primop = primop_2expr | primop_1expr | primop_1expr1int | primop_1expr2int ;

(* Expression definitions *)
expr =
    ( "UInt" | "SInt" ) , [ width ] , "(" , ( int ) , ")"
  | reference
  | "mux" , "(" , expr , "," , expr , "," , expr , ")"
  | primop ;
reference = id
          | reference , "." , id
          | reference , "[" , int , "]"
          | reference , "[" , expr , "]" ;

(* Memory *)
ruw = ( "old" | "new" | "undefined" ) ;
memory = "mem" , id , ":" , [ info ] , newline , indent ,
           "data-type" , "=>" , type , newline ,
           "depth" , "=>" , int , newline ,
           "read-latency" , "=>" , int , newline ,
           "write-latency" , "=>" , int , newline ,
           "read-under-write" , "=>" , ruw , newline ,
           { "reader" , "=>" , id , newline } ,
           { "writer" , "=>" , id , newline } ,
           { "readwriter" , "=>" , id , newline } ,
         dedent ;

(* Statements *)
statement = "wire" , id , ":" , type , [ info ]
          | "reg" , id , ":" , type , expr ,
            [ "(with: {reset => (" , expr , "," , expr ")})" ] , [ info ]
          | memory
          | "inst" , id , "of" , id , [ info ]
          | "node" , id , "=" , expr , [ info ]
          | reference , "<=" , expr , [ info ]
          | reference , "is invalid" , [ info ]
          | "attach(" , { reference } , ")" , [ info ]
          | "when" , expr , ":" [ info ] , newline , indent ,
              { statement } ,
            dedent , [ "else" , ":" , indent , { statement } , dedent ]
          | "stop(" , expr , "," , expr , "," , int , ")" , [ info ]
          | "printf(" , expr , "," , expr , "," , string ,
            { expr } , ")" , [ ":" , id ] , [ info ]
          | "skip" , [ info ] ;

(* Module definitions *)
port = ( "input" | "output" ) , id , ":": , type , [ info ] ;
module = "module" , id , ":" , [ info ] , newline , indent ,
           { port , newline } ,
           { statement , newline } ,
         dedent ;
extmodule = "extmodule" , id , ":" , [ info ] , newline , indent ,
              { port , newline } ,
              [ "defname" , "=" , id , newline ] ,
              { "parameter" , "=" , ( string | int ) , newline } ,
            dedent ;

(* In-line Annotations *)
annotations = "%" , "[" , json_array , "]" ;

(* Version definition *)
sem_ver = { digit_dec } , "."  , { digit_dec } , "." , { digit_dec }
version = "FIRRTL" , "version" , sem_ver ;

(* Circuit definition *)
circuit =
  version , newline ,
  "circuit" , id , ":" , [ annotations ] , [ info ] , newline , indent ,
    { module | extmodule } ,
  dedent ;
```


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

In other words, any `.fir` file that was compliant with `x.y.z` will be compliant
with `x.Y.Z`, where `Y >= y`, `z` and `Z` can be any number.
