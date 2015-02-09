App/Transfer
============
Ștefan Suciu
2015-02-04

Version: 0.17

A tool created to transfer and transform data between files and
databases using recipes.


Disclaimer
----------

This is a tool from my toolbox.  It is designed to work with small
datasets and while it is quite flexible it is also quite slow.

See also the `License And Copyright` section at the end of this README
document.


Description
-----------

Transfer is a CLI application written in Perl.

The concept is simple, reads a table data from a source, optionally
make some transformation and transfer it to the destination table.
Currently (for v0.17) the source can be a file in XLS or CSV format or
a database table.  The destination can be a database table.


Concepts
--------

### The Recipe ###

The recipe is a file in Apache format (parsed with the Config::General
Perl module) and describes how to transform the data.  Transformations
are made using plugins.

All recipes contains a few mandatory sections:

- header section
- configuration section
- column transformation section
- row transformation section

This are detailed in other documents...


### Plugins ###

A plugin is a Perl module specialized to make simple transformations.
It receives a hash reference containing info about the field (and some
extra info needed for loging) and the current value.  Transforms the
value using Perl functions and returns the new value.  Plugin
functions can be chained together to make complex transformations.


Installation
------------


Acknowledgements
----------------

Concepts, blocks of code or even entire modules, comments and
documentation are borrowed and/or inspired from the
[Sqitch](https://github.com/theorx/sqitch) project by @theory.  Thank
you!


License And Copyright
---------------------

TODO
