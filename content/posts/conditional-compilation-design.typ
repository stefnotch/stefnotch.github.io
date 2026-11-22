#let frontmatter = (
  title: "Conditional Compilation From First Principles",
  date: datetime(year: 2026, month: 11, day: 22),
  tags: ("programming", "language design"),
  template: "layout.typ",
  description: "An overview of how to design conditional compilation for WGSL.",
)

Conditional _compilation_ is about the desire to _compile different code_, depending on certain settings.
This is used to abstract over features that may not be available everywhere, or may want to be turned on/off.

For example, in a game engine, a mobile target may want to use a forward rendering pipeline while a desktop platform may want a deferred rendering pipeline.
Or in a inference engine, one may want to use `f16` types and subgroup matrix operations if they are available.

These two examples have very different properties. The game engine case can usually be done without any conditional compilation machinery. For example, by exposing two different entrypoints, or by making it dependent on a pipeline `override`.

The latter however, is a case where conditional compilation is required.
The code depends on #link("https://www.w3.org/TR/WGSL/#enable-extensions-sec")[`enable` extensions], where the code itself may be _impossible to compile_ for a compiler that has no knowledge of the extension.

= Observation

The only time conditional compilation is ever required is when depending on `enable` or `requires` extensions.
Everything else can fundamentally be done without conditional compilation.#footnote[It will sometimes be more verbose, but you can express every `#ifdef` by writing out both variants.]

Now let's switch to a developer's perspective of this.
In languages with conditional compilation, there are two kinds of conditional _compilation_.
They come with different properties.

- target platform: choose one, applies globally.
  - e.g. "desktop" vs "mobile". Can imply a set of `enable`s
- feature flag: additive, may apply globally
  - e.g. "has f16", "firefox version >= 160" or an optional dependency being available

= `enable`s are additive feature flags?

I am assuming that the intent of `enable` extensions is to be additive. They currently feel like opt-in feature flags. But it is important to note that the spec doesn't actually give that guarantee. So let's quickly address that and move on.

The spec seems to allow for a future `enable` extension that changes the semantics of existing code.
```wgsl
// changes how we do math
enable bad_arithmetic;

const a: array<f32, 1 + 1>; // this could now have a size of 3.
```

If breaking changes are fundamentally allowed, then static analysis tooling needs to be designed very differently. It needs to view `enable`s as being more like editions.

Editions allow for breaking changes that change existing code. The way that static analysis works in the presence of editions is as follows:
1. We target a new edition. Let's call it 2026
2. We have some code under edition 2021. The compiler parses it under 2021 rules. Then it transforms the code to the 2026 equivalent.
3. We have some code under edition 2015. Same thing happens, it gets upgraded to the 2026 equivalent.
4. Finally, we statically analyze everything under the 2026 semantics.

This only works if the older code can actually be transformed to the newer code. In the case of enables, it only works of the baseline code can be transformed to the code with the `enable`s enabled.
If an `enable` happens to _add additional restrictions to existing code_ or _fundamentally change a feature such that the old behaviour no longer exists_, then that is impossible.

For the rest of this, I am mostly assuming that `enable`s are additive and don't do surprising things.

= Design axis - defining a condition

Conditional compilation depends on _conditions_.

The big question here is whether the conditions are `enable`s themselves OR if they are defined by the user.

Both worldviews of how conditions are defined are completely viable for building an ecosystem upon.
It does impact how libraries are written, so it is worth spending some time to think it through.

== `enable`s as condition

We could add a way to check if a given `enable` feature is enabled. It would be a `const` boolean, except that its value is supplied at shader creation time. So an IDE would look at `wgsl.f16`, see that it's a boolean with an unknown value and treat it #link("./user-defined-const-eval.typ")[like a const generic].

Here is a simple example of their usage
```wgsl
@if(wgsl.f16)
import lygia::math::f16;

@if(!wgsl.f16)
import lygia::math::f16_emulated;
```

== Abstracting over `enable`s

Having `enable` features be booleans also allows us to abstract over them.

```wgsl
const is_desktop = wgsl.f16 && wgsl.subgroup_matrix; 
```

followed by usages thereof
```wgsl
@if(package::is_desktop)
import package::kernels::fast_matrix_multiply;
@if(!package::is_desktop)
import package::kernels::slow_matrix_multiply;
```

where `./kernels/fast_matrix_multiply.wgsl` would be the module that relies on an `enable`.

```wgsl
// a bit disconnected from the is_desktop condition
enable subgroup_matrix;
...
```

Such booleans can naturally be used in `if` statements.
The Bevy game engine currently has many examples of `@if` statements that should just be normal `if ... { }` statements, #link("https://github.com/tychedelia/bevy/blob/82ed9dccf7cfb25bb9f938b00fcc55b6b71c578a/crates/bevy_anti_alias/src/smaa/smaa.wesl#L978-L988")[like this one in their anti-aliasing shader].

```wgsl
fn get_lighting() -> f32 {
  if package::is_desktop {
    // do more expensive computation
  }
  ...
}
```

One important property of this model is that we never need to pass conditions to libraries.
Libraries will check `wgsl.XYZ` and then automatically enable the corresponding features.

If a library does want to let the user pick and choose which features to use, then there is a simple way of doing so.
A library for matrix multiplication would be written as follows

```wgsl
// always available for the user
public import package::matrix::normal_impl;

// conditional feature
@if(HasFastMatrixMath)
public import package::matrix::fast_impl;

// user can use this to check for the presence of the faster variant
public const HasFastMatrixMath = wgsl.subgroup_matrix;
```

And the user would write
```wgsl
@if(my_library::HasFastMatrixMath)
import my_library::matrix::fast_impl;
```

The syntax should be bikeshedded, for example one oddity is that the type checking of `wgsl.unknown_condition` is iffy.
But that aside, being able to check for `enable` features is one way of having conditions.


== User defined flags

The big alternative approach is to have completely user-defined flags.
Those flags are independent of the `enable`s. This example here uses the module parameters syntax.#footnote[Modules parameters are #link("https://github.com/webgpu-tools/wesl-spec/issues/222")[this draft proposal], but don't get sidetracked.]

An application would write
```wgsl
module<const is_desktop: bool>;

@if(is_desktop)
enable subgroup_matrix, f16;

@if(is_desktop)
import package::kernels::fast_matrix_multiply;
@if(!is_desktop)
import package::kernels::slow_matrix_multiply;
```

This style supports passing flags to libraries, like this

```wgsl
import mylib::matrix<is_desktop>;
```

where the library is defined as

```wgsl
// in mylib::matrix
module<const use_subgroups: bool>;

@if(use_subgroups)
import ...
```

One thing to note is that we do want conditions to be defined in shader code.
That way, #link("https://github.com/wgsl-analyzer/wgsl-analyzer")[the language server] can autocomplete them.

This design has conditions that are disconnected from the implied `enable`s. This is the big alternative approach.


= Design axis - boundary of conditional compilation

Conditional compilation on a module scope is necessitated by the design of WGSL.
Conditional compilation can, however, be done on a much finer grained scope.
For example, individual fields of a struct can be removed or function definitions can be swapped out

One extreme of this is doing it at the scope of individual lines of code. This is what C does with its preprocessor, which we know is a flawed design.

Each construct that can be conditionally compiled _places new requirements on tooling_.
The major tools that deal with it have opposing goals. Our challenge is to find a simple design that sufficiently satisfies all use cases.

- Compiler: Needs to ignore the code that is not compiled. Should be able to compile and type-check everything else.
- Language Server: Needs to analyze all code, always. Should be able to type-check code independent of conditions.
- Reflection API: Return all public APIs, including the conditions. Should have a path towards generating appropriate host code in Rust/Typescript/...

From these perspectives, let's start with the simplest sounding construct

== Modules without shadowing

We allow for conditional compilation, however they are designed as being purely an attribute for the compiler and not for the other tools. Name resolution ignores attributes. This is a very restricted form of conditional compilation.

This is valid

```wgsl
@if(package::is_desktop)
import package::kernels::fast_matrix_multiply;
@if(!package::is_desktop)
import package::kernels::slow_matrix_multiply;

fn foo() {
  if package::is_desktop {
    fast_matrix_multiply::multiply(...);
  } else {
    slow_matrix_multiply::multiply(...);
  }
}
```

and that is not, because the names collide

```wgsl
@if(package::is_desktop)
import package::kernels::fast_matrix_multiply::multiply;
@if(!package::is_desktop)
import package::kernels::slow_matrix_multiply::multiply;

fn bar() {
  multiply(...);
}
```

This variant has the upside of having a very low burden for tooling. Tooling that understands every `enable` can ignore conditional compilation and yield perfect answers.

However, at every usage, it requires more conditional compilation. A compiler would see both branches and find itself unable to do name resolution and type checking for the branches where it does not understand the condition. This is pretty much how our current conditional compilation design works.
```wgsl
fn foo() {
  @if (package::is_desktop) {
    fast_matrix_multiply::multiply(...);
  } @else {
    slow_matrix_multiply::multiply(...);
  }
}
```

=== Conclusion

This variant shows that if one carefully writes code, one can make current WESL perfectly compatible with tooling. One can get zero red squiggles, even in a wgsl-analyzer that does not understand conditional compilation.

In that model, one best views `@if` as being additive. It adds code and all added code must be valid. This is also how #link("https://doc.rust-lang.org/cargo/reference/features.html")[feature flags work in the Rust ecosystem.]#footnote[Another upside thereof is that features can be unified, instead of causing code to be duplicated.]

== Modules with interfaces

The alternative to drawing the boundary at the usage site is to draw it at the module site itself. As in, instead of having to write `@if` every time we use something from a conditional module, we put the conditional logic inside of the module.

How do we do that?

We define an interface for the module with a default implementation. And the rest of the module implements the interface using the specialized `enable` powered code.

To illustrate, let's start with an overly simple example. Just a single constant that uses the `f16` feature.

```wgsl
enable f16; 
// a bit smaller than your usual pi
const SMALL_PI: f16 = 3.14;
```

The fallback code for this can use roughly the same value.
But it cannot use the `f16` type. So it could do the next best thing and use `f32`.

```wgsl
// fallback code
const SMALL_PI: f32 = 3.14;
```

And to unify those two things, we put them behind an interface.#footnote[The syntax is up for bikeshedding, as always.]

```wgsl
module interface {
  alias Float;
  const SMALL_PI: Float;
}
```
We define that a constant exists. And we abstract over its type.

How the type abstraction is done is a whole separate question. Possibilities include
- `alias Float: FloatInterface` - constraining it to another interface, which is how generics work
- `alias Float: f32 | f16` - choose one of those types, although beware of complexity demons
- `alias Float = Conditional<wgsl.f16, f16, f32>` - modelling it as a 'conditional type'. This will be explored in depth in another post. The difference to the above is that it encodes what condition controls the choice of the type.

That matter aside, we now have 'module interfaces'.
The importer would only see the interface and program against that. If the implementation has `f16` support, then the implementation would be powered by f16. Otherwise it would fall back to `f32` with whatever fallback code was defined.

This has the upside that the usage sites would not have any `@if` conditional compilation!
It has the downside of introducing a whole new concept to the language.

Now let's explore a more automated variant of this.

== Polystubbing (as opposed to polyfilling)

The Javascript ecosystem mostly solves missing features by polyfilling or by #link("https://esbuild.github.io/api/#target")[compiling to an older target] for older browsers. We can do a similar thing.

Many WGSL `requires` extensions are language features that we should be able to polyfill. For example, `unrestricted_pointer_parameters` is polyfillable. WESL would do a compiler transform to specialize all the functions and inline their pointer access chains.

But not all WGSL `requires` extensions are easily polyfilled. For example, `immediate_address_space` makes use of a GPU API specific feature that we do not have access to.
And WGSL `enable` extensions are device features. We cannot reasonably polyfill most of them. For example, ray queries are a GPU feature where we certainly need access to the underlying APIs.#footnote[I bet a motivated enough engineer could polyfill ray queries and acceleration structures. It would amount of a whole compute shader implementation of it all.]

So, what do we do with APIs that we cannot polyfill?
We poly-stub them. We provide a dummy implementation that does nothing other than satisfy the type checker. And the user is responsible for writing the appropriate code. For example, a poly-stubbed `rayQuery` API would be used like this.

```wgsl
if wgsl.ray_queries {
  rayQuery(...);
} else {
  do_userland_fallback();
}
```

=== Conclusion

This design is powered by tooling. The WGSL standard doesn't need to change for this to work. In fact, browser-based WGSL implementations cannot do this. It would require them to parse code that they do not yet know how to parse. And it would require them to ship with stubs for features that they do not know about at all.

With tooling, one gets an extremely simple user experience. A user can write arbitrary `enable` statements in their shaders and use all the types they want. When it is time to support older devices, they
1. enable the polystub for a given feature
2. write `if` statements, that get evaluated at compile time, to provide fallback code

Finally, this feature can be implemented in a standard-assisted way. The WGSL standard would have an unchecked mechanism for conditional modules. Then, tools would compile a shader to target that. We can draw a parallel to the JavaScript ecosystem, where an offline bundler will do source transforms ahead of time. And the browser offers, for example, dynamic imports to load the right modules.

== Modules with fallbacks

Now let's explore an option that seems relatively obvious at first glance.
Let's just write two imports for the two variants of a module.

```wgsl
@if(package::is_desktop)
import package::kernels::fast_matrix_multiply as multiplier;
@if(!package::is_desktop)
import package::kernels::slow_matrix_multiply as multiplier;

fn bar() {
  multiplier::multiply(...);
}
```

This gets us a form of conditional compilation that works very well for a compiler.
It however places new requirements on tooling. For example, tooling has to analyze the code while accounting for one name resolving to multiple implementations.

=== Statically Analyzing All Paths

The seemingly simplest way to check this is to check both paths.
However, this results in exponential time complexity. Here's a pathological construction

```wgsl
@if(package::cond_1)
import package::bit_1;
@if(!package::cond_1)
import package::bit_1_fallback as bit_1;

@if(package::cond_2)
import package::bit_2;
@if(!package::cond_2)
import package::bit_2_fallback as bit_2;

@if(package::cond_3)
import package::bit_3;
@if(!package::cond_3)
import package::bit_3_fallback as bit_3;

...

const_assert(7 < bit_1::VALUE + bit_2::VALUE + bit_3::VALUE + ...);
```

I suspect that in practice the time complexity of checking all variants blows up to become intractable as well. WGSL's const eval can create a lot of extra 'dependencies' between code. A similar problem has been observed in the C programming language when attempting to check all variants of conditional compilation.

So this is not the ideal path for tooling. The other challenge for tooling is _unifying_ the results after checking every path. One has to unify
- the error messages - including deduplicating. But if error messages slightly diverge due to different types or constants, then the same error gets repeated many times
- the data types when showing inlay hints - thus introducing algebraic data types in the user interface
- documentation comments in autocompletions - applies to functions, structs, constants, etc
- function signatures in autocompletions
- the set of methods of a module that are autocompleted - this likely means deduplicating and annotating methods with `@if(XYZ)` in the autocompletion

The overarching effect is that the complexities of conditional compilation are visible in every part of the language server. This is not a great trade-off, given how few developers are working on wgsl-analyzer. Conditional compilation was originally designed to just affect the syntax tree, but implementing it reveals that its blast radius is much bigger.

But there is an alternative! Keep reading :)

=== Generating Interfaces for Static Analysis

To avoid complexity, a static analysis tool, such as a language server or a linter, would generate an interface for type checking. That keeps complexity scoped to a small part that deals with the "interface generation" part. The interface would then make use of WGSL's existing language features.

So a tool would read our example of
```wgsl
@if(package::is_desktop)
import package::kernels::fast_matrix_multiply as multiplier;
@if(!package::is_desktop)
import package::kernels::slow_matrix_multiply as multiplier;

fn bar() {
  multiplier::multiply(...);
}
```

and behind the scenes turn it into

```wgsl
module interface multiplier {
  fn multiply(...) -> ...
}

fn bar() {
  multiplier::multiply(...);
}
```

What happened here were 3 steps
1. we identified a module and its fallback
2. we generated an interface
3. we use the interface for type checking

Now, how could a language server be able to automatically generate such an interface?
The fundamental rule is: both modules need to have the same _identifier_ and have it be the _same kind of item_.

In our case, both modules have a function called `multiply`.

For types, the strategy is:
- if they are the same type, use that
- if they are different types, introduce an associated type and constrain it.

Constraining a type is either done by constraining it to an interface or by modelling it as a 'conditional type'. Remember the explicit interfaces variant? This is just like it was back then. Just with tooling authored interfaces instead of human authored interfaces.

=== Conclusion

Modules with fallbacks are easy to implement for the compiler. The compiler simply chooses to not look at a module.

Meanwhile the language server gets a principled implementation strategy by doing a lot more heavy lifting. It defines rules for how to automatically generate an interface from a module and its fallback. Then, it type-checks against the interface.

The nice thing is that this doesn't leak into the language itself, it stays as an implementation detail of the language server. The downside is that users will feel where the limits of the "automatic interface inference" are.


= Design note: `@if(...) import` is repetitive

When one has a conditional module, then every import site has to include a `@if(...)` _every time you import it_.

This is inconvenient for developers, as they have to remember to manually add the `@if` statements every time that module is imported. Worse yet, the language server will likely find itself unable to help. When working with tooling, most imports are added automatically when triggering an auto-import via an autocompletion. But the import will be missing the `@if`, because nothing in the code says that an `@if` is needed.
The same problem applies to inline usage (`foo::bar_with_f16::some_fn()`).

As for solutions, there are two major approaches that you've seen.

The first one is writing "interface-y" modules that encapsulate the conditional imports.
Then, crucially, the rest of the codebase would always import from that "interface-y" module.
This is the path taken by explicit interfaces. As a concrete example, the `f16` math example would result in 2+ files, and users would be expected to always import from `kernels::matrix_multiply`.
```
./kernels/fast_matrix_multiply.wgsl
./kernels/matrix_multiply.wgsl
```

The alternative solution is adopting the polystub approach, which does not suffer from this challenge in the first place. Being able to rely on tools makes life very convenient.

```wgsl
enable f16;

fn mat_mul_8x8(a: array<f16, 64>, b: array<f16, 64>) -> array<f16, 64> {
  // ...
  // the f16 polystub upgrades f16 to f32 
  // and smooths over the API differences
  // ...
}
```

= Design note: Placing conditions on `enable`s

This section exists to highlight something that wasn't obvious to me before.

When one has conditional compilation, one instinct is to put it above statements that may fail to compile. And this works fine for global declaration.

However, the same does not hold true for all directives. Why?

Let's start with what directives do. Directives modify how a WGSL program is processed. Directives come in 3 flavors, which are quite different

- `requires`: Hints. Naga parses them and then throws them away, if they specify a known extension. Otherwise it throws an error.
- `diagnostic`: May affect semantics. For example disabling or enabling a diagnostic will change whether code after it throws an error or warning or is silent.
- `enable`: Can and will affect both syntax and semantics.


`enable` extensions, such as `f16`, will modify the parser state and affect semantics. In the concrete case of `f16`, the parser will now #link("https://github.com/gfx-rs/wgpu/blob/0432ab7fb70b28cfbfbd77e0d4b2b0c43bc49f70/naga/src/front/wgsl/parse/mod.rs#L452-L454")[allow for literals with a `h` suffix] like `0.23h`. The semantic analysis is also affected, since it now permits for #link("https://github.com/gfx-rs/wgpu/blob/0432ab7fb70b28cfbfbd77e0d4b2b0c43bc49f70/naga/src/front/wgsl/parse/conv.rs#L579-L581")[`f16`] to be used as a type name.

Let us, for a moment, imagine using `f16` before enabling it. We'll do it by placing an `@if` condition on the `enable`.
```wgsl
@if(8h / 2 == 4h)
enable f16;
```
That would fail to parse, because the `h` suffix is not allowed at the time of parsing.

And the following snippet has the interesting property that it would successfully parse.
```wgsl
@if(f16(8) / 2 == f16(4))
enable f16;
```
However, semantic analysis is ambiguous. There is, conceptually, a cyclic dependency between `enable f16` and its usage.

This reveals a, in hindsight, relatively obvious fact about WGSL's structure. WGSL is order independent at the top level. All global declarations can be put in any order and the program will yield the same result.
However, directives affect everything _after_ them. Therefore the only place where they can be, while preserving order independence, is at the top of the program.

And this constraint right here is why the approach of _conditional modules_ is the correct way of dealing with `enable`s.#footnote[As in, `enable`s are at the very top of a module. You can't put anything before them, you can only choose whether you want to import the module or not.]

It does also have one more implication. Module parameters have to be placed after directives. If WGSL gains a module parameters feature, then the following snippet of code would be perfectly reasonable to write

```wgsl
requires module_parameters;
enable f16;
module<const a: bool>;
```

But changing their order would not be valid.

```wgsl
module<const a: bool>;
requires module_parameters;
enable f16;
```

The previous sections already use module parameters in exactly that way. Making modules ($approx$ imports) the level of granularity is the correct choice for directives.

// = Design note: Distinguishing between infectious `enable`s and `enables` with fallbacks

// When a module says
// ```
// enable f16;
// ```
// then it may have public items that use `f16`. Those are only valid to use if the consumer has `enable f16;`
// Thus, the importer of a module with an `enable` also needs to have that `enable`.
// The language server would check for this!
// THOUGH! Putting an `enable` in every darn file would get very old quickly. hmmmm

// _However_ a conditionally imported module does not behave the same way.
// Because it might not always be imported. How does the language server best check for that?
// HMMMM
// If every file that uses f16 needs to have an `enable f16`, then how do we ever draw the boundary?
// Like "foo.wesl" uses f16. So it has a enable f16.
// Then "bar.wesl" conditionally imports it. It has a fallback path.
// But "bar.wesl" also has a f16 path. So it needs to have `enable f16`, but conditionally?
// But we cannot put anything above the `enable` statements without running into a very dubious and cyclic world.
//
// So I think the correct worldview is to see `enable`s as being a global thing?
// `enable`s are specified in the `package.wesl`. They then apply to the whole project.
// But how do we achieve conditional `enable`s?



// Bonus TODOs?
// investigate what Babylon.js would need
// investigate those huggingface kernels
// maybe explain refactor-rename challenges? https://github.com/webgpu-tools/wesl-spec/issues/244
// maybe explain more implementation challenges with the current conditional compilation system? https://github.com/wgsl-analyzer/wgsl-analyzer/pull/1586

= Summary

I hope you learned something. I definitely did :)
And do ask questions, they lead to new insights!

For designing a conditional compilation feature, my recommendation is to keep both the compiler, the tooling and the end users in mind. We should pick a simple design, both in terms of implementation complexity and in what is exposed to the user.

As a historical example, that we should strive to improve upon:
C's `#ifdef` is great in 2 out of 3 counts. It is simple for the compiler and simple to explain to the user. It is, however, not simple for tooling.

Let's get that perfect 3/3 grade!
