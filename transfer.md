App/Transfer
============
Ștefan Suciu
2015-03-02

WARNING: This is work in progres...


Description
-----------

Transfer is a CLI application written in Perl.

The concept is simple, read a table data from a source, optionally
make some transformation and transfer it to the destination table.
Currently (for v0.18) the source can be a file in XLS or CSV format or
a database table.  The destination can be a database table.

The required configurations for the transformations are hold in files
named `recipes`.


The Readers
-----------

The readers are Perl modules designed to read the data from the source
and store it to a array of hash references data-structure.


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


## The Header (recipe) Section ##

```
<recipe>
  version               = 1
  syntaxversion         = 1
  name                  = Test recipe
  description           = Does this and that...
</recipe>
```

### The recipe attributes ###

version       :: The version of the recipe.  Not managed by the application.
syntaxversion :: The version of the recipe syntax.  The current recipe format value is 1.
name          :: The name of the recipe.
description   :: A description of the recipe.
table         :: The destination table name.


## The Config Section ##

An example for a complete file =to=> database transfer recipe config
section:

```
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

```
<target siruta>
  uri           = db:firebird://user:pass@localhost//home/fbdb/siruta.fdb
</target>
```

Alternatively, in the *App::Transfer* configuration files (transfer.conf):

```
[target "siruta"]
        uri = db:firebird://user:pass@localhost//home/fbdb/siruta.fdb
```

## The Tables Section ##

The main purpose of this section is to configure the mappings between
the source and the destination fields.


```
<tables>
  worksheet             = Foaie1
  <table siruta>
    description         = SIRUTA
    skiprows            = 1
    logfield            = siruta
    <headermap>
       CodSIRUTA        = siruta
       DenumireLocalitate = denloc
       CodPostal        = codp
       CodDeJudet       = jud
       CodForTutelar(unitateaadminierarhicsuperioara) = sirsup
       CodTipLocalitate = tip
       CodNivel         = niv
       CodMediu(1URBAN3RURAL) = med
       FactorDeSortarePeJudete = fsj
       FactorDeSortareInOrdineAlfabeticaALocalitatilor = fsl
       Rang             = rang
    </headermap>
  </table>
  <table judete>
    ...
  </table>
</tables>
```