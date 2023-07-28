# Your project...
*might have a terrible developer experience.*

I like helping people. I really like contributing a little fix to a project that I care about. So pretty please don't make this harder than it needs to be.

Here's how it should reasonably go

**1.** Project needs this toolchain. Okay, reasonable.  
**2.** Google the toolchain, grab the installer for my platform or do it through my package manager, done. The default configuration is also correct, so that's lovely.


**Projects that fail**
- Python, with conda. Conda and co aren't the default, yet many projects recommend using them. Note that Python is the one getting a failing grade, not conda.
- C with a terrible cross-platform story.
- Java with maven. Maven isn't there by default.
- Any project that requires multiple toolchains.  



**3.** Clone the repository  
**4.** Open project in an IDE. Bonus points when the toolchain supports multiple IDEs and doesn't require me to install one specific, flawed IDE

**Projects that fail**
- C# projects that explicitly require the very overweight Visual Studio.
- Windows C++ projects that only work properly with Visual Studio.

**5.** Run the project. Either by pressing a single button in the IDE or by entering one or maybe two commands in the terminal.

**Projects that fail**
- All those that have multiple dependencies and want an already configured SQL database and whatnot. Pretty please do this for me, or start an in-memory database for development purposes.

**6.** Shortly after, the project is running and I can edit the code.

**Projects that fail**
- Anything that takes a metaphorical hour to build. Or requires multiple manual steps whenever you want to apply a code change.
