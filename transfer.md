App/Transfer
============
Ștefan Suciu
2015-03-02

WARNING: This is (still) work in progres...


Description
-----------

Transfer is a CLI application written in Perl.

The concept is simple, read a table data from a source, optionally
make some transformation on each record and transfer the record to the
destination.

Currently XXX (v0.18) the source can be a file in XLS or CSV format or
a database table.  The destination can be a database table.

The required configurations for the transformations are hold in files
named `recipes`.


The Readers
-----------

The readers are Perl modules designed to read the data from the source
tables and store it into an array of hash references (AoH) using the
destination table's field names as keys.

Note: This is not elegant and probably not as eficient as posible.
Maybe a more elegant solution would be if the reader doesn't need to
know about the recipe and the headermap and would pass the data as AoH
using the source table field names as keys.

A headermap example:

``` conf
<headermap>
  Codjudeţ                = cod_jud
  Denumirejudeț           = denj
  FactorDeSortarePeJudețe = fsj
  MNEMONIC                = mnemonic
  ZONA                    = zona
</headermap>
```

A resulting data structure example:

``` perl
[
  {
    cod_jud  => 1,
    denj     => 'ALBA',
    fsj      => 1,
    mnemonic => 'AB',
    zona     => '7',
  },
  ...
  {
    cod_jud  => 42,
    denj     => 'GIURGIU',
    fsj      => 19,
    mnemonic => 'GR',
    zona     => '3',
  },
]
```

Note: This would be nice to be a lazy reading of the data structure...


The Writers
-----------

The Recipe File
---------------

The recipe is a file in Apache format (parsed with the Config::General
Perl module) and describes the source and the destination and how to
transform the data.  Transformations are made using plugins.

All recipes contains a few mandatory sections:

- header section
- configuration section
- column transformation section
- row transformation section

Each recipe is for the transfer and transformation of a single table
from the source to the destination.

NOTE: A recipe with the C<excel> source reader can have more than one
table configured in the C<tables> section but it is used only for
separating the required data along with its header.


## The Header (recipe) Section ##

    <recipe>
      version               = 1
      syntaxversion         = 1
      name                  = Test recipe
      description           = Does this and that...
    </recipe>


### The recipe attributes ###

version       :: The version of the recipe.  Not managed by the application.
syntaxversion :: The version of the recipe syntax.  The current recipe format value is 1.
name          :: The name of the recipe.
description   :: A description of the recipe.
table         :: The destination table name.


## The Config Section ##

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

    { orderby => { -asc => "colA" } }

    <orderby>
        -asc   colA
    </orderby>

    { orderby => { -desc => "colB" } }

    <orderby>
        -desc   colB
    </orderby>

    { orderby => ["colA", { -asc => "colB" }] }

    orderby   colA
    <orderby>
        -asc   colB
    </orderby>

    { orderby => { -asc => ["colA", "colB"] } }

    <orderby>
        -asc   colA
        -asc   colB
    </orderby>

    {
      orderby => [
        { -asc => "colA" },
        { -desc => "colB" },
        { -asc => ["colC", "colD"] },
      ],
    }
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


The *column_type* plugins can clean-up, transform and validate all
fields of the respective type.

NOTE: This feature is for the DB writer and is work in progress to
      implement it to the file writers.


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
