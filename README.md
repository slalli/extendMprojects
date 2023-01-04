# extendMprojects

This small routine extends short M notation routines into long M notation.
It works only for routines written in GT.M / YottaDB.

So:
`F  S X=$O(A(X)) Q:X=""  D`
will be translated into:
`for  set X=$order(A(x)) quit:X=""  do`


It will, additionally:
- format the extended notation as upper case or lower case
- indent the code (not the labels or comments as 1st char) as follows:
  - 1 char
  - 4 chars
  - TAB
  - as it is
- save the new files with three options:
  - replace the current routine files
  - replace and rename the old files
  - create new files and leave the original intact

Simply copy the M routine anywhere in your system mapped to $zroutines and run it by executing (from the M prompt):

`do start^extendMprojects`

You can, optionally, pass a path as string parameter. If omitted, the routine will ask for it and validate it.

The interface will first collect all the options, then it will start converting the file, dumping a report when completed.

Feel free to create issue to address problems or fork / MR eventual fixes.
