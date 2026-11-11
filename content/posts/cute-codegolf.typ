#let frontmatter = (
  title: "Simplifying code - the codegolf edition",
  date: datetime(year: 2023, month: 7, day: 9),
  tags: ("programming", "web"),
  template: "layout.typ",
  description: "Simplifying code, as measured by the character count.",
)
Someone sent me this piece of code#footnote[Almost. I reformatted the code with Prettier for your reading convenience.], and rightfully complained about Javascript's string handling functions.

```js
export function generateDisplayName(currentName) {
  if (!currentName) {
    return "";
  }
  if (/.*[a-y]/.test(currentName)) {
    return (
      currentName.slice(0, -1) +
      String.fromCharCode(currentName.charCodeAt(currentName.length - 1) + 1)
    );
  } else {
    return currentName + "a";
  }
}
```

The idea is to take a current name, and generate a "next name". For example, if I input "a", it outputs "b".


== Chapter 1.

Depending on the use-case, something like directly generating an available name from a number might be more reasonable, but I digress.
```js
/** Directly generate a name from a number */
function gen(i) {
  let alphabet = "abcdefghijklmnopqrstuvwxyz".split("");
  if (i < alphabet.length) {
    return alphabet[i];
  } else {
    return gen(Math.floor(i / alphabet.length)) + gen(i % alphabet.length);
  }
}
```

After a bit of joking around, I went ahead and golfed it. I mean, I simplified the above code.
```js
const gen = (i, abc = "abcdefghijklmnopqrstuvwxyz") =>
  (i < abc.length ? "" : gen(Math.floor(i / abc.length), abc)) +
  abc[i % abc.length];
```
It's shorter, therefore it's simpler. /j

The author of the original code didn't seem to be too impressed by this though.

== Chapter 2.

Maybe directly generating a name from a number didn't fit their use case. Well, time to write an even simpler version of their code.
Their code checks if the last character is a letter. If yes, replace it with the next letter. If not, just append a letter.

After a bit of thinking about the problem at hand, I figured I'd take a stab at it.
The original first does a regex test and then some convoluted branching logic. Might as well combine that for simplicity.
```js
const gen = (name) =>
  name.replace(/[^](?<=([a-y]?))$/, (v, v1) =>
    v1 ? String.fromCharCode(v.charCodeAt(0) + 1) : v + "a"
  );
```

But this still has the somewhat ugly and verbose `String.fromCharCode`. I am no mind reader, but I am pretty sure that is why they didn't want to use my solution.
So back to the drawing board.

Using a map and regex replacements seemed like it was on the right track. And yes, it was indeed!
Look at this beauty!
```js
gen = (
  name,
  abc = new Map(
    "abcdefghijklmnopqrstuvwxyz".split("").map((v, i, arr) => [v, arr[i + 1]])
  )
) => name.replace(/[^]$/, (matched) => abc.get(matched) ?? matched + "a");
```
It sadly did end up becoming larger again. So it is not simpler, by our objective metric.

So the problem remained unsolved.

== Chapter 3.

Until today. Today I came up with a near-optimal solution! I am sure that you, dear reader, will agree that 'tis truly elegant!

```js
gen = (name) =>
  (name + name + "abcdefghijklmnopqrstuvwxyz").replace(
    /^([^]*)([^])\1(?:\2[a-z]*?\2([a-z])[a-z]*?|(\2a)[a-z]*)$/,
    "$1$3$4"
  );

```

Yes, it works. For most cases at least.

How? Good question.

In fact, that is a really good question.

I think you, dear reader, pose good questions.

...

Shooo

Go read another post.

Don't look at the explanation.

...

Alright.

You win.

#html.elem("details")[
  #html.elem("summary")[Explanation]

  For something that barely resembles an explanation, look at #link("https://regex101.com/r/nqUnO9/1")

  The idea is as follows
  1. Duplicate the string, and then append the alphabet. `catto` turns into `cattocattoabcdefghijklmnopqrstuvwxyz`
  2. `([^]*)([^])` matches the string, and the last character of the string
  3. ```re \1``` matches most of the duplicate
  4. ```re (?:\2[a-z]*?\2([a-z])[a-z]*?|(\2a)[a-z]*)``` encodes the logic for `if letter { select next character of the alphabet } else { select an a }`#footnote[And how does this work? That's another good question. This one is a homework problem.]

]

