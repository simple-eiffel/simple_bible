simple_bible 0.4.1 - PERSONAL EDITION - not for distribution
=============================================================

This installs the simple_bible concordance on your own machine, with
everything it needs. Nothing else has to be installed first.

What is in it
-------------
  bible_gui.exe      the window ("simple_bible" in the Start menu)
  bible.exe          the command line
  bible_build.exe    rebuilds content.db from a bible.db
  data\content.db    the book list the program opens first
  data\conc.db       the personal concordance (about 1.2 GB)

The personal concordance includes research-only layers (the Rahlfs
Septuagint from CATSS, the BSB word tables). Keep this installer and the
installed files on your own machines; never publish them.

The window
----------
Open "simple_bible" from the Start menu. It follows the GUI guide's
Simple layout: the Bible text in the middle, the commentary panel on the
right (its Cross-refs tab: OpenBible links with votes), the dictionary
and lexicon below, search results on the left while there are any.

  Reference box (top left)   John 3:16, Ps 23, Gen 1 1     Ctrl+L
  Search box                 bara, logos, love, G25, H1254 Ctrl+F
  Back and Forward           Alt+Left, Alt+Right
  Text size                  A- A+, Ctrl + and Ctrl -
  Dark                       the switch at the top right

Click a verse: the commentary follows it and its original words open on
the left; click a word there and the lexicon follows. View > Show design
pills (Ctrl+Shift+P) labels each part with its code from the GUI guide.

The command line
----------------
Open "simple_bible prompt" from the Start menu (a console already set to
UTF-8, so Hebrew and Greek print correctly), or any console if you let the
installer add bible to your PATH. In another console, run "chcp 65001"
first if Hebrew shows as boxes or question marks.

  bible word 3                    a word study (here bara, "create")
  bible word 9380 --corpus LXX-RAHLFS
  bible english create            the original words behind an English word
  bible verse 1 1 1               every word of Genesis 1:1
  bible verse 40 5 3 --corpus NT-MACULA
  bible strongs H1254             the headwords behind a Strong's number

Book numbers follow the vault's bible.db (Genesis 1 ... Malachi 39,
Matthew 40 ... Revelation 66).

bible finds its data in the data folder beside it. --content and --conc
name other files.

Installing on another machine without questions
-----------------------------------------------
From cmd or PowerShell (not Git Bash, which rewrites /FLAGS):

  simple_bible-personal-0.4.1-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /TASKS="addtopath"

Uninstalling removes the programs, both databases and the PATH entry.
