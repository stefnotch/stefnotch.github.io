#let frontmatter = (
  title: "Humans Generating Random Numbers",
  date: datetime(year: 2021, month: 10, day: 7),
  template: "layout.typ",
  description: "Humans are weak entropy sources. But we can fix that!",
)

Generating random numbers as a human is fun. But easily exploitable.
We keep doing non-random things. #link("https://www.khanacademy.org/computing/computer-science/cryptography/crypt/v/frequency-stability")[Khanacademy even has a lovely video about this].


In technical terms, a human is a "weak entropy source".
Which means that "randomness extractors" can be used. A simple one is the #link("https://en.wikipedia.org/wiki/Randomness_extractor#Von_Neumann_extractor")[Von Neumann Extractor]. Thank you to #link("https://github.com/eleanor-em")[eleanor] for pointing me at that.

This gives us a simple algorithm, where you think of a number, convert it to binary and use the extractor on the bit streams.

Try it out right here
#html.elem("input", attrs: (type: "text", id: "randomInput"))

In binary that is
#html.elem("pre", attrs: (id: "binaryOutput"))

Your coin tosses are
#html.elem("pre", attrs: (id: "randomOutput"))
#html.elem(
  "script",
  attrs: (type: "text/javascript"),
  "
function printTo(elementId, text) {
  const outputElement = document.getElementById(elementId);
  outputElement.textContent = text;
}

document.getElementById('randomInput').addEventListener('input', function() {
  const output = vonNeumannExtractor(+this.value);
  printTo(`randomOutput`, output.map(v => v ? `👤` : `🐈`).join(``));
});

function vonNeumannExtractor(v) {
  let bits = Iterator.from(v.toString(2)).map(b => +b);
  let groupedBits = bits.chunks(2).filter(c => c.length == 2).toArray();

  printTo(`binaryOutput`, groupedBits.map(c => `${c[0]}${c[1]}`).join(` `));

  let result = [];
  for(const [a, b] of groupedBits) {
    if(a == b) {
      // do nothing
    } else {
      result.push(a);
    }
  }
  return result;
}
",
)
