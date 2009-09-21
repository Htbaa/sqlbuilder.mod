SuperStrict

Import htbaapub.sqlbuilder

'Create a TSqlBuilder object
'By default it's a SELECT query
Local query:TSqlBuilder = New TSqlBuilder

'Set table. You can add a second parameter (String)
'to declare what fields should be selected
query.From("some_table")
query.Where("score > ?", TDBInt.Set(10))
query.OrWhere("level = ?", TDBString.Set("Bonus Level 1"))
'Will print: SELECT * FROM some_table WHERE score > ? OR level = ? 
Print query.ToString()

'Change it to a DELETE query
query.SetType(TSqlBuilder.TYPE_DELETE)
'Will print: DELETE FROM some_table WHERE score > ? OR level = ?
Print query.ToString()

'Reset query
query.Reset()
'Change it to a SELEFT query
query.SetType(TSqlBuilder.TYPE_SELECT)
query.Limit(20, 100)
'Will print: SELECT * FROM some_table LIMIT 20 OFFSET 100
Print query.ToString()

'Reset query
query.Reset()
'Change it to a UPDATE query
query.SetType(TSqlBuilder.TYPE_UPDATE)
'Chaining is also possible
query.Set("question", TDBString.Set("What's my name?")).Where("id = ?", TDBInt.Set(1))
'Will print: UPDATE some_table SET question = ? WHERE id = ? 
Print query.ToString()

'Change it to a INSERT query
query.SetType(TSqlBuilder.TYPE_INSERT)
'Remove WHERE clause
query.ResetWhere()
'Will print: INSERT INTO some_table (question)VALUES(?)
Print query.ToString()


Rem
	'To use it with bah.database you can do something like this
	'Keep in mind you need to do proper error checking as well
	Local db:TDBConnection = LoadDatabase("SQLITE", some_database.sqlite")
	Local sth:TDatabaseQuery = TDatabaseQuery.Create(db)
	
	'Assemble the query and prepare it
	sth.prepare(query.ToString())
	'Bind the values to the query
	query.BindValues(sth)
	'And execute query
	sth.execute()	
End Rem