// ignore_for_file: prefer_const_constructors
// Main file for the app

import 'package:flutter/material.dart';
import 'wordle_list.dart';
import 'starter_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORdswinDLE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WordSwindle(
        title: 'WORdswinDLE - The WORDLE Cheat App',
      ),
    );
  }
}

// The data model for each cell of the word grid.
//
class CellModel {
  int row;
  int column;
  String letter;
  Color color;

  // Constructor:
  //
  CellModel(this.row, this.column, this.letter, this.color);
}

// We need a global instance of the top-level stateful class to avoid
// having to bubble callbacks up the hierarchy.
//
_WordSwindleState globalState = _WordSwindleState();

// Main class in the hierarchy.
//
class WordSwindle extends StatefulWidget {
  WordSwindle({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<WordSwindle> createState() {
    // Return a reference to the global instance instead of creating a new one.
    //
    return globalState;
  }
}

// State associated with the WordSwindle class.
// All state that is to be maintained globally, irrespective of objects
// being redrawn, is held here.
//
class _WordSwindleState extends State<WordSwindle> {
  // The WordSwindle grid that mirrors the Wordle grid:
  //
  static const int MAX_ROWS = 9;
  static const int MAX_COLS = 5;
  static const double SUGGESTIONS_HEIGHT_PORTRAIT = 85;
  static const double SUGGESTIONS_HEIGHT_LANDSCAPE = 45;
  static const double SUGGESTIONS_WIDTH_PORTRAIT = 320;
  static const double SUGGESTIONS_WIDTH_LANDSCAPE = 320;
  static const double STARTER_WORDS_WIDTH = 233;
  static const double STARTER_WORDS_HEIGHT = 60;
  static const double STARTER_WORDS_MENU_MAX_HEIGHT = 200;
  static const double GUESSED_WORDS_HEIGHT_PORTRAIT = 256;
  static const double GUESSED_WORDS_HEIGHT_LANDSCAPE = 160;
  static const double GUESSED_ROW_WIDTH = 240;
  static const double GUESSED_CARD_WIDTH = 40;
  static const double GUESSED_CARD_HEIGHT = 40;
  static const double KEYBOARD_CARD_WIDTH = 25;
  static const double KEYBOARD_CARD_HEIGHT = 30;

  final _key1 = GlobalKey();
  final _key2 = GlobalKey();
  final _key3 = GlobalKey();
  final _key4 = GlobalKey();
  final _key5 = GlobalKey();

  bool isPortrait() {
    return (MediaQuery.of(context).orientation == Orientation.portrait);
  }

  // How to display the keyboard:
  //
  final List<String> _keyboardWords = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM<"];

  // Keep track of the index of the next letter to be typed.
  // This is a linear index from 0 to N.
  //
  int nextLetterPosition = 0;

  // This is the set of letters used in Wordle.
  //
  String fullAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  // This will hold the set of candidate letters after removing
  // those that are known not to exist in the word.
  //
  String reducedAlphabet = '';

  // Initialise the set of candidate letters in each position of the answer
  //
  List<String> candidateLetters = ['', '', '', '', ''];

  // This will hold the string used to build up a regular expression.
  //
  String regexpString = '';

  // The default starter word displayed will be the first in the list
  // of starter words held in a separate file.
  //
  //String starterWordDropdownValue = starterWords.keys.first;
  String? starterWordDropdownValue;

  // This will hold the set of suggestions after due processing.
  //
  List<String> _suggestedWords = [];

  // The initial set of starter words, set to blank.
  //
  String selectedStarterWords = '';

  // Create and populate the grid's model that will hold its state.
  //
  late List cells = List<List<CellModel>>.generate(
      MAX_ROWS,
      (i) => List<CellModel>.generate(
          MAX_COLS, (j) => CellModel(i, j, '', Colors.grey)));

  // Derive the row of the next letter to be typed.
  //
  int getNextLetterRow() {
    return (nextLetterPosition / MAX_COLS).floor();
  }

  // Derive the column of the next letter to be typed.
  //
  int getNextLetterColumn() {
    return nextLetterPosition % MAX_COLS;
  }

  // Add a letter to the grid.
  //
  void addLetter(String letter) {
    setState(() {
      globalState.cells[getNextLetterRow()][getNextLetterColumn()].letter =
          letter;
      nextLetterPosition++;
    });
  }

  // Remove the last typed letter from the grid.
  //
  void removeLetter() {
    setState(() {
      nextLetterPosition--;
      globalState.cells[getNextLetterRow()][getNextLetterColumn()].letter = '';
      globalState.cells[getNextLetterRow()][getNextLetterColumn()].color =
          Colors.grey;
    });
  }

  // Apply the selected starter word(s) to the grid.
  //
  void applyStarterWords(String starterWordKey) {
    setState(() {
      clearGrid();
      String letters = starterWords[starterWordKey]!;
      for (int i = 0; i < letters.length; i++) {
        addLetter(letters.substring(i, i + 1));
      }
    });
  }

  // Clear the grid.
  //
  void clearGrid() {
    setState(() {
      for (int i = 0; i < MAX_ROWS; i++) {
        for (int j = 0; j < MAX_COLS; j++) {
          cells[i][j].letter = '';
          cells[i][j].color = Colors.grey;
          nextLetterPosition = 0;
        }
      }
    });
  }

  // Remove colour markups on all squares.
  //
  void allGrey() {
    setState(() {
      for (int i = 0; i < MAX_ROWS; i++) {
        for (int j = 0; j < MAX_COLS; j++) {
          cells[i][j].color = Colors.grey;
        }
      }
    });
  }

  // Clear the box displaying suggestions.
  //
  void clearSuggestions() {
    setState(() {
      _suggestedWords = [];
    });
  }

  // Work out candidate answers.
  //
  void setSuggestedWords() {
    setState(() {
      _suggestedWords.clear();

      String candidateRemovals = '';

      // All letters marked grey are candidates for removal.
      // (There is one exception to this rule which we will cater for later.)
      //
      for (int i = 0; i < MAX_ROWS; i++) {
        for (int j = 0; j < MAX_COLS; j++) {
          if ((globalState.cells[i][j].letter != '') &&
              (globalState.cells[i][j].color == Colors.grey)) {
            if (!candidateRemovals.contains(globalState.cells[i][j].letter)) {
              candidateRemovals += (globalState.cells[i][j].letter);
            }
          }
        }
      }

      // If a letter is used twice in a guess, and neither is in the right spot,
      // one will be marked yellow and the other will be marked grey.
      // So not all letters marked grey will be absent from the answer.
      // If a letter is marked yellow, then it should NOT be a candidate for
      // removal.
      //
      for (int i = 0; i < MAX_ROWS; i++) {
        for (int j = 0; j < MAX_COLS; j++) {
          if (globalState.cells[i][j].letter != '') {
            if (globalState.cells[i][j].color == Colors.yellow) {
              if (candidateRemovals.contains(globalState.cells[i][j].letter)) {
                candidateRemovals = candidateRemovals.replaceAll(
                    globalState.cells[i][j].letter, '');
              }
            }
          }
        }
      }

      // Now we are sure about all the letters that will not be in the answer.
      // Get the set of candidate letters by removing the ones we know won't
      // be present from the full alphabet.
      //
      reducedAlphabet = fullAlphabet;
      for (int i = 0; i < candidateRemovals.length; i++) {
        reducedAlphabet = reducedAlphabet.replaceAll(candidateRemovals[i], '');
      }

      // All five letters in the answer should be from this reduced set.
      // That's the basic constraint.
      //
      for (int j = 0; j < MAX_COLS; j++) {
        candidateLetters[j] = reducedAlphabet;
      }

      // Improve the constraints.
      //
      String mustHave = '';
      for (int i = 0; i < MAX_ROWS; i++) {
        for (int j = 0; j < MAX_COLS; j++) {
          if (globalState.cells[i][j].letter != '') {
            if (globalState.cells[i][j].color == Colors.green) {
              // Letters marked green are definitely in the right position,
              // so they become the only candidate for their position.
              //
              candidateLetters[j] = globalState.cells[i][j].letter;
            } else if (globalState.cells[i][j].color == Colors.yellow) {
              // Letters marked yellow must exist somewhere in the word,
              // but they should not be candidates for the position
              // in which they were marked.
              //
              mustHave += globalState.cells[i][j].letter;
              candidateLetters[j] = candidateLetters[j]
                  .replaceAll(globalState.cells[i][j].letter, '');
            }
          }
        }
      }

      // Build up the basic regular expression with all candidate letters.
      //
      regexpString = '';
      for (int j = 0; j < MAX_COLS; j++) {
        regexpString += '[';
        regexpString += candidateLetters[j];
        regexpString += ']';
      }

      // The above regexp is too loose and will let through a number of
      // invalid words. We need additional regular expressions to ensure
      // that every one of the letters marked yellow is in the candidate word.

      List<RegExp> regexps = [];

      // Add the loose constraint to the set of regular expressions to check.
      //
      regexps.add(RegExp(regexpString));

      // Add the must-have letters to the set.
      //
      for (int i = 0; i < mustHave.length; i++) {
        regexps.add(RegExp('[' + mustHave[i] + ']'));
      }

      // Now check the full wordlist of 12,000+ words against
      // this set of regular expressions. Only if a word matches all of
      // them should it be added to the list of suggestions.
      //
      for (String word in wordlist) {
        bool allMatched = true;
        for (RegExp regexp in regexps) {
          if (!regexp.hasMatch(word)) {
            allMatched = false;
            break;
          }
        }
        if (allMatched) {
          _suggestedWords.add(word);
        }
      }
    });
  }

  // Return the set of suggested words as a single string.
  //
  String getSuggestedWords() {
    String suggestedString = '';

    for (String suggestedWord in _suggestedWords) {
      suggestedString == '' ? suggestedString = '' : suggestedString += ', ';
      suggestedString += suggestedWord;
    }

    return suggestedString;
  }

  // Return the set of dropdown menu items listing commonly used "starter words".
  //
  List<DropdownMenuItem<String>> getStarterWordDropdownMenuItems() {
    List<DropdownMenuItem<String>> menuItems = [];

    for (String starterWord in starterWords.keys) {
      menuItems.add(DropdownMenuItem(
        value: starterWord,
        child: Text(starterWord),
      ));
    }

    return menuItems;
  }

  // The method that builds the main screen.
  //
  @override
  Widget build(BuildContext context) {
    // Build the screen depending on the orientation of the device.
    //
    if (isPortrait()) {
      return getPortraitScaffold();
    } else {
      return getLandscapeScaffold();
    }
  }

  // Return a portrait oriented scaffold.
  //
  Widget getPortraitScaffold() {
    return Scaffold(
      key: _key1,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            // Dropdown of starter words:
            //
            SizedBox(
              width: STARTER_WORDS_WIDTH,
              height: STARTER_WORDS_HEIGHT,
              child: DropdownButtonFormField(
                itemHeight: null,
                hint: Text(
                  'Select starter word(s)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                ),
                menuMaxHeight: STARTER_WORDS_MENU_MAX_HEIGHT,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.blue,
                ),
                validator: (value) =>
                    value == null ? "Select starter word(s)" : null,
                dropdownColor: Colors.blue,
                value: starterWordDropdownValue,
                onChanged: (String? newValue) {
                  setState(() {
                    starterWordDropdownValue = newValue!;
                    applyStarterWords(starterWordDropdownValue!);
                  });
                },
                items: getStarterWordDropdownMenuItems(),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            // Grid of guessed answers with colouring:
            //
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: GUESSED_WORDS_HEIGHT_PORTRAIT,
                  padding: const EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.black)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.symmetric(
                        vertical: 1.0, horizontal: 10.0),
                    child: Column(
                      children: getGuessedRows(_WordSwindleState.MAX_ROWS),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            // Keyboard:
            //
            Column(children: getKeyboardRows(globalState._keyboardWords)),
            SizedBox(
              height: 10,
            ),
            // Suggested answers:
            //
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: SUGGESTIONS_HEIGHT_PORTRAIT,
                  width: SUGGESTIONS_WIDTH_PORTRAIT,
                  padding: const EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.black)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Text(
                        getSuggestedWords(),
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Footer buttons:
      //
      persistentFooterButtons: <Widget>[
        // Display the set of suggested answers:
        //
        ElevatedButton(
          child: Text(
            isPortrait() ? 'Suggest' : 'Suggest',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            MediaQueryData _mediaQueryData = MediaQuery.of(context);
            double screenHeight = _mediaQueryData.size.height;
            double screenWidth = _mediaQueryData.size.width;

            setSuggestedWords();
          },
        ),
        // Reset all colour markup to grey.
        //
        ElevatedButton(
          child: Text(
            'Clear\nColours',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            allGrey();
          },
        ),
        // Clear the word grid and make all cells blank.
        //
        ElevatedButton(
          child: Text(
            'Clear\nGrid',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            clearGrid();
          },
        ),
        // Clear the set of suggested words.
        //
        ElevatedButton(
          child: Text(
            'Clear\nSuggestions',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            clearSuggestions();
          },
        ),
      ],
    );
  }

  // Return a landscape oriented scaffold.
  //
  Widget getLandscapeScaffold() {
    return Scaffold(
      key: _key1,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(5),
        child: Row(
          children: [
            Column(
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                // Dropdown of starter words:
                // (No space for this in landscape mode,
                // hence omit this component.)
                //
                // Keyboard:
                //
                Column(children: getKeyboardRows(globalState._keyboardWords)),
                SizedBox(
                  height: 10,
                ),
                // Suggested answers:
                //
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: SUGGESTIONS_HEIGHT_LANDSCAPE,
                      width: SUGGESTIONS_WIDTH_LANDSCAPE,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black)),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            getSuggestedWords(),
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: 50,
            ),
            Column(
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                // Grid of guessed answers with colouring:
                //
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: GUESSED_WORDS_HEIGHT_LANDSCAPE,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black)),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.symmetric(
                            vertical: 1.0, horizontal: 10.0),
                        child: Column(
                          children: getGuessedRows(_WordSwindleState.MAX_ROWS),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ],
        ),
      ),
      // Footer buttons:
      //
      persistentFooterButtons: <Widget>[
        // Display the set of suggested answers:
        //
        ElevatedButton(
          child: Text(
            'Suggest',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            MediaQueryData _mediaQueryData = MediaQuery.of(context);
            double screenHeight = _mediaQueryData.size.height;
            double screenWidth = _mediaQueryData.size.width;

            /*
            print(
                "Height = ${_key1.currentContext!.size!.height}, width = ${_key1.currentContext!.size!.width}");
            print("Screen height = ${screenHeight}, width = ${screenWidth}");
            */
            setSuggestedWords();
          },
        ),
        // Reset all colour markup to grey.
        //
        ElevatedButton(
          child: Text(
            'Clear Colours',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            allGrey();
          },
        ),
        // Clear the word grid and make all cells blank.
        //
        ElevatedButton(
          child: Text(
            'Clear Grid',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            clearGrid();
          },
        ),
        // Clear the set of suggested words.
        //
        ElevatedButton(
          child: Text(
            'Clear Suggestions',
            style: TextStyle(
              fontSize: 10,
              //fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            clearSuggestions();
          },
        ),
      ],
    );
  }

  // Get all the rows in the word grid.
  //
  List<Widget> getGuessedRows(int rows) {
    List<Widget> widgets = [];

    for (int i = 0; i < rows; i++) {
      widgets.add(getGuessedRow(i));
    }

    return widgets;
  }

  // Get all the rows in the keyboard display.
  //
  List<Widget> getKeyboardRows(List<String> keyboardWords) {
    List<Widget> widgets = [];

    for (int i = 0; i < keyboardWords.length; i++) {
      widgets.add(getKeyboardRow(keyboardWords[i]));
    }

    return widgets;
  }

  // Get one row in the word grid.
  //
  Widget getGuessedRow(int row) {
    //print(guessedWord);
    return SizedBox(
        width: GUESSED_ROW_WIDTH, child: GuessedRowWidget(row: row));
  }

  // Get one row in the keyboard grid.
  //
  Widget getKeyboardRow(String keyboardWord) {
    //print(keyboardWord);
    return SizedBox(child: KeyboardRowWidget(keyboardWord: keyboardWord));
  }
}

// Widget class for a row of the word grid.
//
class GuessedRowWidget extends StatelessWidget {
  final int row;
  const GuessedRowWidget({Key? key, int this.row = 0}) : super(key: key);

  // Get all the card widgets for a given row.
  //
  List<Widget> getGuessedCardWidgets() {
    List<Widget> widgets = [];
    for (int j = 0; j < _WordSwindleState.MAX_COLS; j++) {
      widgets.add(getGuessedCardWidget(row, j));
    }
    return widgets;
  }

  // Get the card widget for a particular row and column.
  //
  Widget getGuessedCardWidget(int row, int column) {
    return Flexible(child: GuessedCardWidget(row: row, column: column));
  }

  // The build method for the widget.
  //
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // ignore: prefer_const_literals_to_create_immutables
      children: getGuessedCardWidgets(),
    );
  }
}

// Widget class for a single card of the word grid.
//
class GuessedCardWidget extends StatefulWidget {
  final int row;
  final int column;
  GuessedCardWidget({Key? key, this.row = 0, this.column = 0})
      : super(key: key);

  @override
  State<GuessedCardWidget> createState() => _GuessedCardWidgetState();
}

// The state associated with a single card of the word grid.
//
class _GuessedCardWidgetState extends State<GuessedCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // When a card is tapped, it chould change colour.
          // Cards are initially grey.
          // One tap => yellow
          // Two taps => green
          // Three taps => back to grey
          //
          setState(() {
            if (globalState.cells[widget.row][widget.column].letter == '') {
              // If there's no letter in the cell, ignore the tap.
              // The cell should be grey, if it isn't already.
              //
              globalState.cells[widget.row][widget.column].color = Colors.grey;
            } else {
              if (globalState.cells[widget.row][widget.column].color ==
                  Colors.grey) {
                globalState.cells[widget.row][widget.column].color =
                    Colors.yellow;
              } else if (globalState.cells[widget.row][widget.column].color ==
                  Colors.yellow) {
                globalState.cells[widget.row][widget.column].color =
                    Colors.green;
              } else if (globalState.cells[widget.row][widget.column].color ==
                  Colors.green) {
                globalState.cells[widget.row][widget.column].color =
                    Colors.grey;
              } else {
                globalState.cells[widget.row][widget.column].color =
                    Colors.grey;
              }
            }
          });
        },
        child: Card(
          color: globalState.cells[widget.row][widget.column].color,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: SizedBox(
            width: _WordSwindleState.GUESSED_CARD_WIDTH,
            height: _WordSwindleState.GUESSED_CARD_HEIGHT,
            child: Center(
              child: Text(
                globalState.cells[widget.row][widget.column].letter,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget class for a row of the displayed keyboard.
//
class KeyboardRowWidget extends StatefulWidget {
  final String keyboardWord;
  const KeyboardRowWidget({Key? key, String this.keyboardWord = ''})
      : super(key: key);

  @override
  State<KeyboardRowWidget> createState() => _KeyboardRowWidgetState();
}

// The state associated with the keyboard row widget.
//
class _KeyboardRowWidgetState extends State<KeyboardRowWidget> {
  // Get all the card widgets for a given row.
  //
  List<Widget> getKeyboardCardWidgets(String keyboardWord) {
    List<Widget> widgets = [];
    for (int i = 0; i < keyboardWord.length; i++) {
      widgets.add(getKeyboardCardWidget(keyboardWord.substring(i, i + 1)));
    }
    return widgets;
  }

  // Get the card widget for a particular row and column.
  //
  Widget getKeyboardCardWidget(String letter) {
    return Flexible(flex: 0, child: KeyboardCardWidget(keyboardLetter: letter));
  }

  // The build method for the widget.
  //
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // ignore: prefer_const_literals_to_create_immutables
      children: getKeyboardCardWidgets(widget.keyboardWord),
    );
  }
}

// Widget class for a single card of the displayed keyboard.
//
class KeyboardCardWidget extends StatefulWidget {
  final String keyboardLetter;
  Color cardColor = Colors.grey;
  KeyboardCardWidget({Key? key, this.keyboardLetter = ''}) : super(key: key);

  @override
  State<KeyboardCardWidget> createState() => _KeyboardCardWidgetState();
}

// The state associated with a single card of the displayed keyboard.
//
class _KeyboardCardWidgetState extends State<KeyboardCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // If a letter is tapped, add it.
          // If the backspace '<' character is tapped, remove the
          // last typed letter.
          //
          if (widget.keyboardLetter == "<") {
            globalState.removeLetter();
          } else {
            globalState.addLetter(widget.keyboardLetter);
          }
        },
        child: Card(
          color: widget.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: SizedBox(
            width: _WordSwindleState.KEYBOARD_CARD_WIDTH,
            height: _WordSwindleState.KEYBOARD_CARD_HEIGHT,
            child: Center(
              child: Text(
                widget.keyboardLetter,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
