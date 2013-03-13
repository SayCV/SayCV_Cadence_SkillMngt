/*
Now this is going to be interesting...
At the moment we've generating the  _DTL_MENUS.il file to handle menu entries
in Allegro but this approach will probably need to be expanded.

The stuff we need in a generic loader

  Structures              -Prevent the warnings caused by load/reload
  function.autoload       -Context Names where functions live
  function.writeprotect   -Prevent GLOBAL function names from being overwritten
  Command Registration    -Commands used for menu items.

*/