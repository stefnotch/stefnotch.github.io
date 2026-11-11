#let frontmatter = (
  title: "Co- and Contravariance",
  date: datetime(year: 2022, month: 3, day: 6),
  tags: ("programming", "language design"),
  template: "layout.typ",
  description: "A quick explanation of co- and contravariance.",
)

I saw #link("https://www.youtube.com/watch?v=LoeEstgMXQs")[an excellent video about co- and contravariance] and figured I would note it down in text form. The terms co- and contravariance are not very educational. But luckily there are better terms.

== Covariance
_Output-variance or read-variance_

For example:
Dog is Animal, therefore `IEnumerable<Dog>` is `IEnumerable<Animal>`

`.get()` returns a Dog/Animal

== Contravariance
_Input-variance or write-variance_

For example:
Cat is Animal, therefore `Feeder<Animal>` is `Feeder<Cat>`

`.feed(me: Cat/Animal)` takes an input

