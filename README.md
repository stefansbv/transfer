App/Transfer
============
Ștefan Suciu
2016-09-11

Version: 0.30

Transform and transfer data between files and databases using recipes.


Disclaimer
----------

This is a tool from my toolbox.  It is designed to work with small
datasets and while it is quite flexible it is also quite slow.

See also the `License And Copyright` section at the end of this README
document. TODO!


Description
-----------

Transfer is a CLI application written in Perl.

The concept is simple, read a table data from a source, optionally
make some transformation and transfer it to the destination table.
Currently (for v0.18) the source can be a file in XLS or CSV format or
a database table.  The destination can be a database table.

The required configurations for the transformations are hold in files
named `recipes`.


Concepts
--------

### The Recipe ###

The recipe is a file in Apache format (parsed with the Config::General
Perl module) and describes the source and the destination and how to
transform the data.  Transformations are made using plugins.

All recipes contains a few mandatory sections:

- header section
- configuration section
- column transformation section
- row transformation section

TODO: This are detailed in other documents...


### Plugins ###

A plugin is a Perl module specialized to make simple transformations.
It receives a hash reference containing info about the field (and some
extra info needed for logging) and the current value.  Transforms the
value using Perl functions and returns the new value.  Plugin
functions can be chained together to make complex transformations.


Installation
------------


Acknowledgements
----------------

Concepts, blocks of code and even entire modules, comments and
documentation are borrowed and/or inspired from the excellent
[Sqitch](https://github.com/theory/sqitch) project by @theory.  Thank
you!


License And Copyright
---------------------

TODO!
