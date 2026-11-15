#let frontmatter = (
  title: "WGSL Const-Eval for User-Defined Functions",
  date: datetime(year: 2026, month: 11, day: 14),
  tags: ("programming", "graphics", "language design"),
  template: "layout.typ",
  description: "WGSL has const-eval. How hard could it be to extend it to userland?",
)

WGSL has const-eval for predeclared functions. It even has const-eval in types, thanks to the array type. `array<T, 2 + x * 7>` is valid WGSL.

This is much more powerful than most people realize. It also has a few unintuitive consequences.
Let's explore those

= Removing WGSL code usually has a side-effect

Const-eval can throw errors. Quite a lot of errors in fact.

Division by zero is an error. So `const x = 3 / 0;` is an error.

An array with a zero length is defined to be an error. So `array<f32, 0>` is an error.

And lots of WGSL functions have rules about when they'll throw an error in the presence of const-eval.
For example #link("https://www.w3.org/TR/WGSL/#u32-builtin")[`u32(e: T)`] will throw when `e` is too big.
#link("https://www.w3.org/TR/WGSL/#clamp")[`clamp(e: T, low: T, high: T) -> T`] will throw when `low > high`.
And so on.

Errors are usually quite observable. They are a very in-your-face kind of deal.
So a correct WGSL implementation cannot just remove code that it never called.
That would remove errors after all, if there were any.

It first has to do const-eval and only then is it allowed to eliminate the dead code!#footnote[Unless of course the WGSL implementation decides to say _we make no guarantees about how we compile incorrect code_. That's dirty, but it might be good enough until const-eval is fully implemented.]

This is similar to how you cannot just remove code that doesn't type check.

Finally, there is one extra challenge. If pipeline-overridable constants are involved in an expression, then one cannot const-eval it beforehand. In that case, it's safest to keep the code preserved as-is. In the following example, removing `foo` would observably change the behaviour of an application, even if `foo` is never called.
```wgsl
override maybe_zero: u32 = 0;
fn foo() {
  let a = 5 / maybe_zero; // division by zero
}
```

= Zero sized types are fine, if the size is const

Runtime arrays in WGSL need to have a nonzero size.
Why? Performance.

If I write `foo[7]`, then the semantics are
#quote(attribution: link("https://www.w3.org/TR/WGSL/#array-access-expr"), block: true)[
  The result is the value of the i'#super[th] element of the array value e.

  If i is outside the range [0, N-1]:
  - It is a shader-creation error if i is a const-expression.
  - It is a pipeline-creation error if i is an override-expression.
  - Otherwise, an indeterminate value for T may be returned.
]

Note the "indeterminate value" case. The way this is implemented in practice is by _clamping_ the array index.
So a WGSL compiler will emit `foo[clamp(7, 0, length)]`. It uses clamping to avoid branching in the shader.

But of course clamping only works if there is something to clamp to. If `foo` had a length of `0`, then this would break down.

So zero sized arrays are impossible?
Well, not quite.
Zero sized _runtime_ arrays are bad. Those `array<T>` arrays that do not have a specified size.
But #link("https://www.w3.org/TR/WGSL/#array-types")[fixed-size arrays] are perfectly fine.
We can
1. Allow `x: array<f32, 0>`. It has a size of 0.
2. All accesses to `x` are going to follow the rules above. Const and override expressions throw, because the index is guaranteed to be outside of the range. Runtime expressions `x[some_value]` get replaced with an indeterminate value. Probably `0` for whatever the type is.

= A demon floats at the bottom of the sea

#link("https://www.w3.org/TR/WGSL/#const-expressions")[const expressions] can include floating point arithmetic.
Where accuracy is implementation defined, within some given bounds.

This means that simplifying a const expression can change its observable value.
So comparing whether two types are equivalent `array<f32, u32(x * y / y)> == array<f32, u32(x)>` may either pass type checking or not.#footnote[The author didn't check whether it is actually possible for them to diverge enough, given the WGSL accuracy requirements. But the general principle holds.]

So, a hypothetical perfect language server would have to do one of the following
- compute floats while keeping track of the upper and lower bounds. And use that to compare types
- keep track of _expressions_. And use those to compare types

Of course in practice, life is much easier. We get to shout at people if they start writing arbitrary floating point expressions and use them as array sizes. If it hurts when you hit yourself, then don't hit yourself.

= User defined `@const` functions #link("https://github.com/webgpu-tools/wesl-spec/issues/219")[\#219]

We want to let users define `@const` functions.


For example, one could imagine this `@const` function

```wgsl
@const fn hsv_color(a: f32, b: f32, c: f32) -> vec3f {
  ...
}
```

This lets one then write colors as constants
```wgsl
const MainColor = hsv_color(0.3, 0.1, 0.3);
const SecondaryColor = hsv_color(0.3, 0.3, 0.3);
```

Or one could want to do some bit-level manipulation.

```wgsl
@const fn bit_twiddler(a: u32) -> u32 {
  ...
}
```

These `@const` functions require const-eval, including flow control (`if`, `for`, `switch`, ...).
These `@const` functions have one rule: Their bodies may only contain code that can be evaluated at compile time.

An example for flow-control in a `@const` function is for choosing an SMAA preset.
```wgsl
@const fn get_smaa_preset(level: u32) -> SmaaPreset {
  if level == LOW { // 0
    return SmaaPreset(
      0.15,
      4u,
      0u,
      0u,
    );
  } else if level == MEDIUM { // 1
    return SmaaPreset(
      0.1,
      8u,
      0u,
      0u,
    );
  } else if level == HIGH { // 2
    return SmaaPreset(
      0.1,
      16u,
      8u,
      25u,
    );
  } else if level == ULTRA { // 3
    return SmaaPreset(
      0.05,
      32u,
      16u,
      25u,
    );
  } else {
    const_assert(level <= ULTRA); 
  }
}

struct SmaaPreset {
  threshold: f32,
  max_search_steps: u32,
  max_search_steps_diagonal: u32,

}
```

This could also very well be written as an array of 4 different presets.
We chose this variant with flow control to demonstrate the general principle.

And a language server needs to evaluate those while evaluating types. For example, `array<f32, bit_twiddler(7)>` requires evaluating the `bit_twiddler` function to get the final type of the array.
This is in contrast to the usual operation of a language server. Usually a language server will only look at the function signatures for the purposes of type checking.

This would finally let users define functions that behave like built-ins. And it would allow users to have proper control flow to compute the values of `const` expressions.

= User defined const-generics #link("https://github.com/webgpu-tools/wesl-spec/issues/180")[\#180]

WGSL's #link("https://www.w3.org/TR/WGSL/#array-builtin")[`array` constructor] can be viewed as being an example of a "const-generic".
The `const` value is in the syntactic position of generics/templates.

This idea can be generalized to arbitrary functions. Let's use the following syntax.

```wgsl
fn foo<const my_value: u32>() {
  ...
}
```

We define a `const` inside of the template. This function can be called with `foo<7>()`.
The way this gets compiled is monomorphization.


This gives us a general mechanism for passing around #emph[const]ant values.
This enables functions that return an array of a _given_ size.

```wgsl
fn my_array<const size: u32>() -> array<size, MyStruct> {
  var values = array<MyStruct, size>(); // zero init

  for(var i = 0; i < size; i+=1) {
    values[i] = MyStruct(...);
  }

  return values;
}
```

And it allows for libraries to expose set-able #emph[const]ant values.
```wgsl
/// Displace pixels
fn displace<DISPLACE_DIRECTIONS: u32 = 9>(texVel: sampler2D, texCol: sampler2D, st: vec2f, pixel: vec2f) -> vec4f {
  var dir = array<vec2f, DISPLACE_DIRECTIONS>();
  let iTotal = DISPLACE_DIRECTIONS;
}
```

#link(
  "https://github.com/patriciogonzalezvivo/lygia/blob/aa7580bec667100068038fbeb36fa37d961035ee/distort/displace.wgsl#L26",
)[`displace` function example from Lygia.]

This feature unlocks something that is needed in practice, but is currently impossible to express in WGSL.

= Definition Checked Const-Eval

So far everything has been easy. Now we meet the final boss!

#link("https://www.youtube.com/watch?v=FKC8WACSMP0")[_Definition checking_].

Definition checking is the idea that you can look at a function in isolation and guarantee that "instantiating" or "monomorphizing" it will be successful. Pretty much every programming language has this guarantee.
C++ is an example of a programming language that does not. When you write a templated function, you will not know if it is valid until you call it.

Another way of phrasing this:
- A function's signature should tell you everything you need to know about how to call it.
- A function's signature should be enough to completely type-check the body of the function.

Now let us get back to WGSL. Lots of WGSL functions have rules about when they will throw an error in the presence of const-eval. We want that information to be present in the function signature. We want to model that in wgsl-analyzer.

For this, let us imagine `where` clauses.
Here are some examples of built-ins, along with their requirements.

```wgsl
fn u32(value: f32) -> u32
  where value < MAX_U32 {
  ...
}

fn clamp(e: T, low: T, high: T) -> T
  where low <= high {
  ...
}

fn smoothstep(edge0: T, edge1: T, x: T) -> T
  where edge0 != edge1 {
  ...
}
```

The syntax is still debatable. The built-ins have the slightly odd semantics of
- they get checked for const and override expressions
- they cause indeterminate values to be returned for runtime expressions

With this syntax in hand, we can now write out the built-in functions and actually check their `const`-eval requirements in wgsl-analyzer! Without having to manually implement each requirement for each function.
This also matches the spec text much better, making it easier to keep wgsl-analyzer up-to-date and correct.

== Multiple `where` clauses

When a function has multiple constraints, then we can write out multiple `where` clauses.

For example
```wgsl
@const fn dummy(foo: u32) {
  const a = 1 / foo;
  const b = foo * 93;

  const c = smoothstep(a, b, x);
}
```

would, mechanically, lead to the following `where` clauses
```wgsl
where foo != 0
where (1 / foo) != (foo * 93)
```

But those clauses look quite complicated. Surely there's a simpler one?
And yes, there is!
```
where foo != 0
```
is entirely sufficient.

But if a compiler or even just a fellow human checks the `where` clauses, then
they would have to figure out the same simplifications. That's hard to review.
And hard to do for a compiler.

But luckily, WGSL already provides us with a tool!
We could use `const_assert` for things that we _know_ to be true.

Thus giving us
```wgsl
@const fn dummy(foo: u32)
  where foo != 0 {
  // Safety: This is true by the laws of arithmetic for any integer foo > 0
  // left: either be 0 or 1
  // right: 93 or greater
  const_assert((1 / foo) != (foo * 93));
  
  const a = 1 / foo;
  const b = foo * 93;

  const c = smoothstep(a, b, x);
}
```

And now, with this in place, we get _both_ parts of definition checking.
The user of the function sees what requirements they have.
And the function itself is type-checked as follows

1. `foo` is not a known `const` value. Instead it is a `const` _variable_.
2. So const-eval accumulates _expressions_ instead of values.
3. At every step, we keep track of the facts. Like `foo != 0` and the expressions from `const_assert`s
4. At every step, when we encounter an expression that may throw, we compare it against the known expressions.

In this case, it would be
1. Facts: `foo != 0`
2. Facts: `foo != 0` and `(1 / foo) != (foo * 93)`
3. `1 / foo` throws iff `foo == 0`. Compare with facts, find `foo != 0`.
4. `foo * 93` is irrelevant
5. `smoothstep(a, b, x)` throws iff `a == b`. Look at the expressions for `a` and `b` and compare with the known facts. We find `(1 / foo) != (foo * 93)`.

Though, I imagine that enforcing fully checked function bodies would be somewhat annoying without an automatic expression reducer (and proof assistant).
So it may be worth to make that part an opt-in feature.

wgsl-analyzer would automatically do that kind of tracking and automatically infer `where` clauses for functions.
And if it detects obvious violations, it reports them.
Later, wgsl-analyzer would get an expression reducer so that it can detect more obvious violations.#footnote[And postconditions? Those would give the language server even more info to work with.] With the eventual goal being that every `const` is fully checked. 🚀

