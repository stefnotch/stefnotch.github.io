#let frontmatter = (
  title: "Making Open Source Projects Easier to Contribute to",
  date: datetime(year: 2022, month: 12, day: 7),
  tags: ("programming",),
  template: "layout.typ",
  description: (
    "Getting started with an open source project requires setting it up. This can range from easy-as-pie to level-100-bossfight."
  ),
)

== Your project...
_might have a terrible developer experience._

I like helping people. I really like contributing a little fix to a project that I care about. So pretty please don't make this harder than it needs to be.

Here's how it should reasonably go

== 1. Getting the toolchain

The project needs this toolchain. Okay, reasonable.
So I google the toolchain, grab the installer for my platform or do it through my package manager, done.
The default configuration is also correct, so that's lovely.


=== Projects that fail
- Python, with conda. Conda and co aren't the default, yet many projects recommend using them. #footnote[I should note that I think Python is the one that deserves a failing grade. Python does not come with a decent package manager. Conda actually deserves a passing grade here.]
- C with a terrible cross-platform story.
- Java with maven. Maven isn't there by default.
- Any other project that requires me to install multiple toolchains.

== 2. Opening the project

I clone the repository, usually with #link("https://github.com/jj-vcs/jj")[my beloved `jj`].

Then I open project in _my preferred IDE_. #footnote[I am so glad that language servers are the default these days.]

=== Projects that fail
- C\# projects that explicitly want the slightly overweight big brother Visual Studio.
- Windows C++ projects that only work properly with Visual Studio.
- Projects that are tied to one operating system for no discernible reason. Examples are projects that use platform specific utilities in their npm scripts.

== 3. Setting up the project

Many projects will want a bit of setup before I can run them. Ideally I should not need to do any of that. I already installed the toolchain.

If you want me to do some setup, please limit it to "do this one thing" or run this one command in the terminal.

=== Projects that fail
- All those that have multiple dependencies and want an already configured SQL database and whatnot. Pretty please do this for me, or start an in-memory database for development purposes.
- Projects that turn out to actually depend on yet another tool if I am on a nonstandard operating system like Windows.

== 4. Running the project

Now I want to run the project. So I either hit a button in my IDE or type a command into the terminal.

=== Projects that fail
- Anything that takes a metaphorical hour to build.
- Anything that requires multiple manual steps to recompile and rerun.
