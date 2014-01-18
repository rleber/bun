_USING QUERIES_

The bun software provides a powerful general-purpose language for querying the contents and properties of files
in an archive. In general, these query expressions are very flexible. They can contain just about any valid Ruby 
expression, and can reference the values of fields defined for bun file (for example, its MD5 digest, or its 
catalog date), a number of predefined "examinations" (for example, a test of legibility).

Commands which implement this syntax include:
    bun examine
    bun find
    bun map

There are several forms of examinations:
- Testing the value of a field
- Testing the value of an "examination"
- Using general Ruby expression syntax

_FIELD VALUES_

The bun software extracts or calculates a number of different fields concerning the contents, characteristics,
or processing of a file. Available fields include:

#{Bun::File::Descriptor::Base.field_definition_table}

Field values may be referenced in one of three ways:
- Using the field:<field name> syntax (Do not include the "<" and ">", those are for clarity only)
- Using f[<field_name>] within an expression (<field name> must be a string or symbol)
- Simply using the field name within an expression 

_EXAMINATIONS_

Examinations are predefined tests of the content or characteristics of a file. Generally they return some kind
of string value or table. Available pre-defined examinations include:

#{String::Examination.exam_definition_table}

Similarly to fields, examinations may be referenced in three ways:
- Using the exam:<examination name> syntax
- Using the e[<examination name>] syntax within an expression (<examination name> must be a string or symbol)
- Simply using the examination name within an expression

_USING GENERALIZED RUBY EXPRESSIONS_

Generally, any Ruby expression syntax may be combined with reference to fields and examinations. So, for example
the following are all valid expressions:

    legibility > 0.50       # Tests if the legibility examination returns a value over 50%
    shards.size % 3 == 0    # Tests if the number of shards in the file is an even multiple of 3
    e[:run_size] < 3.0      # Tests if the average run size (of legible characters) is less than 3.0

Needless to say, this allows a great deal of flexibility.

Expressions may be referenced in one of two ways:
- Using the form expr:<expression>
- Or, just using the <expression> without the "expr:" prefix

BE CAREFUL: bash shell escaping can do weird, unexpected things to the value of your expression. If strange things
are happening, try using the --inspect option to have the command print back for you the value of the expression
as it was received.

