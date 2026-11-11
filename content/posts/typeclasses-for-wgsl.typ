#let frontmatter = (
  title: "Typeclasses for WGSL",
  date: datetime(year: 2026, month: 11, day: 13),
  tags: ("programming", "graphics", "language design"),
  template: "layout.typ",
  description: "An exploration of how typeclasses work under the hood.",
)

#show link: underline
#show figure: set align(left)
#set figure(gap: 10pt, numbering: none)

== Intro

I was looking at the problem of bringing generic programming to the WGSL programming language.

There are multiple competing approaches for doing so, from adopting ML-modules to typeclasses.
I never really understood what they do and how they work. Until I started working it out from
the ground up, after reading up on the topic and talking to someone smarter than me.

Turns out that most systems are expressions of the same underlying ideas.
To show what I mean, let's start with something that WGSL already has and go from there.

#figure(
  ```wgsl
  @const @must_use fn floor(e: T) -> T
  where
    S is AbstractFloat, f32, or f16
    T is S or vecN<S>
  ```,
  gap: 10pt,
  caption: link("https://www.w3.org/TR/WGSL/#floor-builtin"),
)
and
#figure(
  ```wgsl
  @const @must_use fn array<T, N>(e1 : T, ..., eN : T) -> array<T, N>
  where
    T is concrete and constructible
  ```,
  caption: link("https://www.w3.org/TR/WGSL/#array-builtin"),
)

So WGSL has generics with generic types.

But they are still extremely limited. You cannot express the predeclared functions without
- _some way of doing constraints_
- _some way of choosing the implementation_


== This is interesting (I hope)
And now let's do that in a few different styles!

=== Overloading (sidequest)
```wgsl
fn floor(e: T) -> T
```
could, if all we had was overloading, instead be written as
```wgsl
fn floor(e: AbstractFloat) -> AbstractFloat
fn floor(e: f32) -> f32
// ... //
fn floor(e: vec4<f16>) -> vec4<f16>
```
The `array` function however cannot be expressed.
It actually needs a #link("https://www.w3.org/TR/WGSL/#constructible")[builtin `constructible` constraint].
`constructible` is a bit like the `Send` and `Sync` traits in Rust.
It automatically applies to structs where all fields are `constructible`.
So overloading is not expressive enough.

=== Passing along a constraint

If we start at the very basics, then
```wgsl
fn floor(e: T) -> T
```
can be extended with a "constraint" by just giving it another parameter.
Yes, that changes the signature, but bear with me.
```wgsl
fn floor(e: T, e_constraint: Floorer<T>) -> T
```

But how would we now implement the body? It has nontrivial semantics, where it looks at `e_constraint` and picks the correct implementation among many.
```wgsl
fn floor(e: T, e_constraint: Floorer<T>) -> T {
  // how do we express this? 
  return e_constraint.floor_impl(e);
}
```

#linebreak()

If we had objects (yes, *object oriented*!), then we'd get
```wgsl
fn floor(e: T, e_constraint: Floorer<T>) -> T {
  // this looks up the method table for e_constraint
  // and dispatches the appropriate floor_impl
  return e_constraint.floor_impl(e);
}
```
It does need a method table, because otherwise we'd always be dispatching the same function regardless of what `Floorer<T>` we're passing in.

#linebreak()

If we had *traits*, then we would write code akin to
```wgsl
fn floor<T: Floorer>(e: T) -> T {
  return T::floor_impl(e_constraint, e);
}
```
where the trait solver then selects the applicable `impl Floorer` for our `T`.
So it can be imagined as desugaring to
```wgsl
fn floor<T>(e: T) -> T {
  let e_constraint = ... get the Floorer for T ...;
  return e_constraint::floor_impl(e);
}
```
Here it should be noted that traits have complicated machinery for getting the applicable `Floorer` implementation.

#linebreak()

If we had *modules*, we would make `e_constraint` be a module. And from there, we look at what `floor_impl` the module has.
```wgsl
fn floor(e: T, e_constraint: Floorer<T>) -> T {
  return e_constraint::floor_impl(e);
}
```

#linebreak()

But this all is just hiding a more fundamental idea. The idea that the original typeclasses paper called a #link("https://users.csc.calpoly.edu/~akeen/courses/csc530/references/wadler.pdf")["dictionary"] of methods. Aka a method table in object oriented languages. Or a module with functions in ML languages! Or a concrete implementation of a typeclass/trait.

The idea really is just that a concrete `Floorer<f32>` is shaped like
```rs
{
  floor_impl: |e: f32| -> { return e - frac(e); }
}
```
It is a dictionary, mapping from function names to implementations.

But that seems inefficient? Passing around dictionaries at runtime? In a shading language?

No problem, let's move that to compile time. Let's express it with something else that WGSL already has. A const generic!
```wgsl
fn floor<T, const e_constraint: Floorer<T>>(e: T) -> T
```

So this clearly still maps to the module and the typeclass styles.
But it also maps to something new.

=== Passing a const generic struct

Most languages, including all the cool ones, treat functions as first class citizens. That means you can pass them around, just like data.

So let's imagine if we had that in WGSL

```wgsl
struct Floorer {
  floor_impl: fn(f32) -> f32
}

fn floor<T, const e_constraint: Floorer<T>>(e: T) -> T {
  return e_constraint.floor_impl(e);
}
```
At runtime, this would become an integer ($approx$ function pointer) and we'd always generate a `switch` statement when calling it. Best we can do, given the limitations of graphics APIs.

But at compile time? At compile time, we know exactly which function it is. So we can expand it out into ordinary function calls.

Here's what I mean. We take this piece of WGSL code
```wgsl
fn main() {
  const my_float_floorer = Floorer(
    |a: f32| -> f32 { return ... }
  )

  let b: f32 = floor<f32, my_float_floorer>(random_value);
}
```
and during const eval, we successively expanded it.
First it becomes a function pointer.
```wgsl
fn floor_impl_0001(a: f32) -> f32 { return ... }

fn main() {
  const my_float_floorer = Floorer(floor_impl_0001);

  let b: f32 = floor<f32, my_float_floorer>(random_value);
}
```
Then we need to do const eval for the `floor<f32, my_float_floorer>` function. This is done by monomorphizing. (Alternatively, it can be done by inlining and then const eval.)

So let's run monomorphization. We start with

```wgsl
fn floor<T = f32, const e_constraint = Floorer(floor_impl_0001)>(e: T) -> T {
  return e_constraint.floor_impl(e);
}
```

We have to pick a unique name for it, so that we can refer to the result. And we evaluate the generics.

```wgsl
fn floor_UNIQUE_NAME_0001(e: f32) -> f32 {
  return Floorer(floor_impl_0001).floor_impl(e);
}
```

After that, we still need to finish evaluating `Floorer(floor_impl_0001).floor_impl`.

All that gives us our final code
```wgsl
fn floor_impl_0001(a: f32) -> f32 { return ... }

fn main() {
  let b: f32 = floor_UNIQUE_NAME_0001(random_value);
}

fn floor_UNIQUE_NAME_0001(e: f32) -> f32 {
  return floor_impl_0001(e);
}
```

And what machinery did we need? Const eval and first class functions.
That's neat. WGSL has the first half and it seems very reasonable to demand first class functions.

This idea isn't novel at all, Rust's traits #link("https://nadrieril.github.io/blog/2026/03/20/dictionary-passing-style.html")[can be elaborated to that style]. And Gleam #link("https://mckayla.blog/posts/all-you-need-is-data-and-functions.html")[is doing something relatively close to this (I think)].

=== This is useful!

This abstraction by itself is already very useful. It gives users a way to do generic programming, even without us having more advanced features. I think this is already worth shipping. It does not let you model or extend the WGSL standard library, but it does allow you to build generic libraries.

=== Associated types

In the dictionary passing style, an associated type turns into an actual `Type` type. You end up treating data types as first class citizens. See also #link("https://nadrieril.github.io/blog/2026/03/20/dictionary-passing-style.html#the-tricky-part-associated-types-and-equality").


=== Getting back to `floor`

So we showed that this variant of `floor` can be expressed quite elegantly in a lot of ways. And they all have the same fundamental dictionary of functions idea.
```wgsl
fn floor<T, const e_constraint: Floorer<T>>(e: T) -> T
```

But WGSL's floor doesn't require me to pass along a `const e_constraint`! Let's make it *implicit*. We'll use the ```wgsl using``` keyword for this, since here we are roughly doing what Scala does.

```wgsl
fn floor<T, using e_constraint: Floorer<T>>(e: T) -> T {
  return e_constraint.floor_impl(e);
}
```

So now we need a mechanism to obtain the `e_constraint`.

Which, once again, has been done before us.

- Object oriented languages would say that `e` is an object and you can look up the method table.
- Typeclass languages, such as Rust, would say that `e` is a type and types carry around dictionaries of methods.
- And in ML-style languages, one would use #link("https://arxiv.org/abs/1512.01895")[Modular Implicits] to express this. Before modular implicits, there wasn't really a way of expressing that.

And thus, we finally get to the point where

```wgsl
fn floor<T, using e_constraint: Floorer<T>>(e: T) -> T {
  return e_constraint.floor_impl(e);
}
```

can have nicely defined semantics and actually be implemented in WGSL with minor extensions!

Except now you need to figure out what your rules for *implicits* are.
Global coherence? Local coherence? What about specialization?

_But that's a topic for another day_
