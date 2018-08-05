App/Transfer
============
Ștefan Suciu
2018-08-02

WARNING: This is (still) work in progres...


Description
-----------

Transform and transfer data between files and databases using recipes.

Transfer is a CLI application written in Perl.

The concept is simple, read a table data from a source, optionally
make some transformation on each record and transfer the record to the
destination.

The required configurations for the transformations are hold in files
named `recipes`.


The Recipe File
---------------

The recipe is a file in Apache format (parsed with the Config::General
Perl module) and configures the source and the destination and how to
transform the data.  Transformations are made using plugin modules.

All recipes contains two mandatory sections:

- a header section
- a configuration section

And two optional sections:

- a column transformation section
- a row transformation section

Each recipe is for the transfer and transformation of a single table
from the source to the destination.


## The Header (recipe) Section ##

    <recipe>
      version               = 1
      syntaxversion         = 1
      name                  = Test recipe
      description           = Does this and that...
    </recipe>


### The recipe attributes ###

version       :: The version of the recipe.  Not managed by the application.
syntaxversion :: The version of the recipe syntax.  The current recipe format value is 2.
name          :: The name of the recipe.
description   :: A description of the recipe.


## The Config Section ##

The config section has two subsections

An example for a complete file =to=> database transfer recipe config
section:

    ``` conf
    <config>
      <source>
        reader        = excel
        file          = siruta.xls
      </source>

      <destination>
        writer        = db
        target        = siruta
        table         = siruta
      </destination>
    </config>
    ```

The file, target and table attributes are optional in the recipe files
but must be provided from the application configuration or from the
CLI options.


### The Config Attributes ###

reader        :: The reader module name.  The implemented modules are: *excel*, *csv* and *db*.
writer        :: The writer module name:  The implemented modules are: *db*.

In the *App::Transfer* recipe file:

The target configuration is like this:

    <target siruta>
      uri           = db:firebird://user:pass@localhost//home/fbdb/siruta.fdb
    </target>


Alternatively, in the *App::Transfer* configuration files (transfer.conf):

    [target "siruta"]
            uri = db:firebird://user:pass@localhost//home/fbdb/siruta.fdb


## The Table Section ##

The main purpose of this section is to configure the mappings between
the source and the destination fields.

There is a specific and required configuration for the *xls* reader:
*worksheet*.

``` conf
<table siruta>
  worksheet                  = Foaie1
  logfield                   = siruta
  <header>
     CodSIRUTA               = siruta
     DenumireLocalitate      = denloc
     CodPostal               = codp
     CodDeJudet              = jud
     CodForTutelar           = sirsup
     CodTipLocalitate        = tip
     CodNivel                = niv
     CodMediu                = med
     FactorSortarePeJudete   = fsj
     FactorDeSortareAlfaLoc  = fsl
     Rang             = rang
  </header>
</table>
```

Order by examples.

``` perl
{ orderby => ["colA", "colB"] }
```

``` conf
orderby = colA
orderby = colB
```

``` perl
{ orderby => { -asc => "colA" } }
```

``` conf
<orderby>
    -asc   colA
</orderby>
```

``` perl
{ orderby => { -desc => "colB" } }
```

``` conf
<orderby>
    -desc   colB
</orderby>
```

``` perl
{ orderby => ["colA", { -asc => "colB" }] }
```

``` conf
orderby   colA
<orderby>
    -asc   colB
</orderby>
```

``` perl
{ orderby => { -asc => ["colA", "colB"] } }
```

``` conf
<orderby>
    -asc   colA
    -asc   colB
</orderby>
```

``` perl
{
  orderby => [
    { -asc => "colA" },
    { -desc => "colB" },
    { -asc => ["colC", "colD"] },
  ],
}
```

``` conf
<orderby>
    -asc   colA
</orderby>
<orderby>
    -desc   colB
</orderby>
<orderby>
    -asc   colC
    -asc   colD
</orderby>
```

The *column_type* plugins can clean-up, transform and validate all
fields of the respective type.

NOTE: This feature is for the DB writer and is work in progress to
      implement it to the file writers.


The Readers
-----------

The readers are Perl modules designed to read the data from the source
tables and store it into an array of hash references (AoH) using the
field names from the header as keys.

The header attribute (array reference) holds the list of the fields in
the desired order.

The reader doesn't (need to) know about the recipe and the header map.

Implemented writers:

- db (PostgreSQL, Firebird)
- csv
- dbf
- xls
- odt (experimental)
 

The Writers
-----------

The writers are Perl modules designed to write the data from an array
of hash references (AoH) using the field names from the header as
keys to the specific output.

Implemented writers:

- db (PostgreSQL, Firebird)
- csv
- dbf

The header attribute (array reference) holds the list of the fields in
the desired order.

The writer doesn't (need to) know about the recipe and the header map.


## Plugins ##

``` conf
<source>
  reader              = csv
  file                = lista-facturi-salubritate.csv
  date_format         = dmy
</source>
```

### TODO ###

Test cases:
  - date field with other data in it (ex: UNDETERMINED)
