# wordswindle

##Intro:
WordSwindle is a cheat app for Wordle that is built using Flutter and designed to work on any smartphone or desktop.

##Build instructions:
The project (currently) has only three source files, all in the lib directory - main.dart, starter_words.dart and wordle_list.dart.

You may have to set up a standard Flutter application, then copy these three files to the lib directory before building the app.

Currently, it has only been built and tested on Android phones (specifically Oppo).
In theory, it can be built and deployed on iPhones also, but I don't have a Mac (required for creating an iPhone deployable).
Hopefully it should work just as easily on iPhones.

##User instructions:
WordSwindle's operation is simple and hopefully intuitive.

Just enter the guesses you made on Wordle, tap the squares to set the colour clues that Wordle provided, then ask for suggestions.
WordSwindle will display all 5-letter words that fit the constraints of the colour clues.

All squares are grey by default. Tap once to turn a square yellow, twice to turn it green, and three times to turn it back to grey.

##Extra features:
There are some favourite "starter words" that people use when playing Wordle.
WordSwindle has a selectable dropdown of these starter words, so you don't have to enter them through the keyboard.

There is a button to clear just the colours but not the guessed words.
This feature is useful when playing games like Quordle, where the same guessed words are used, but the colour clues are different for each answer.

Other buttons help to clear the grid of all guessed words, and to clear the set of suggested answers.

Have fun!

Ganesh C Prasad
