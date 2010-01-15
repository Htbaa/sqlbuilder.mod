Rem
	Copyright (c) 2010 Christiaan Kras
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
End Rem

SuperStrict

Rem
	bbdoc: htbaapub.sqlbuilder
End Rem
Module htbaapub.sqlbuilder
ModuleInfo "Name: htbaapub.sqlbuilder"
ModuleInfo "Version: 0.100"
ModuleInfo "License: MIT"
ModuleInfo "Author: Christiaan Kras"
ModuleInfo "Git repository: <a href='http://github.com/Htbaa/sqlbuilder.mod/'>http://github.com/Htbaa/sqlbuilder.mod/</a>"

Import brl.linkedlist
Import brl.map
Import brl.retro
Import brl.reflection
Import bah.database
Import bah.regex

Rem
bbdoc: SqlBuilder type to build SQL queries
End Rem
Type TSqlBuilder
	
	Field _values:TList = New TList
	Field _columns:TMap
	 
	Field sql_from:String[2]
	Field sql_set:TList = New TList
	Field sql_where:TList = New TList
	Field sql_order:TList = New TList
	Field sql_limit:String

	Field sql_type:Int
	Rem
		bbdoc: Define a SELECT query
	End Rem
	Const TYPE_SELECT:Int = 0
	Rem
		bbdoc: Define a UPDATE query
	End Rem
	Const TYPE_UPDATE:Int = 1
	Rem
		bbdoc: Define a DELETE query
	End Rem
	Const TYPE_DELETE:Int = 2
	Rem
		bbdoc: Define a INSERT query
	End Rem
	Const TYPE_INSERT:Int = 3

	Rem
		bbdoc: Quote columns and tables, yes or no
	End Rem
	Global enable_quoting:Int = False
	
	Rem
		bbdoc: Constructor
	End Rem		
	Method New()
		Self.SetType(TYPE_SELECT)
	End Method
	
	Rem
		bbdoc: Set Query type 
		returns: TSqlBuilder object (Self)
		about: Define query type by passing @TYPE_SELECT, @TYPE_UPDATE, @TYPE_DELETE or @TYPE_INSERT to @sql_type
	End Rem
	Method SetType:TSqlBuilder(sql_type:Int)
		Self.sql_type = sql_type
		Return Self
	End Method
	
	Rem
		bbdoc: Assemble query
		returns: Assembled query
	End Rem
	Method ToString:String()
		Return Self._Assemble()
	End Method
	
	Rem
		bbdoc: Bind values to TDatabaseQuery
	End Rem
	Method BindValues(sth:TDatabaseQuery)
		'Bind values with query
		For Local data:TDBType = EachIn Self._values
			sth.addBindValue(data)
		Next
	End Method
	
	Rem
		bbdoc: Pass a TMap with TDBColumns to this method
	End Rem
	Method SetColumnInfo(columnInfo:Tmap)
		Self._columns = columnInfo
	End Method
	
	Rem
		bbdoc: Add FROM clause
		returns: TSqlBuilder object (Self)
	End Rem
	Method From:TSqlBuilder(table:String, what:String = "*")
		Self.sql_from[0] = table
		Self.sql_from[1] = what
		Return Self
	End Method
	
	Rem
		bbdoc: Reset values
	End Rem
	Method ResetValues()
		Self._values.Clear()
	End Method
	
	Rem
		bbdoc: Reset WHERE clause and values
	End Rem
	Method ResetWhere()
		Self.ResetValues()
		Self.sql_where.Clear()
	End Method

	Rem
		bbdoc: Reset SET clause and values
	End Rem
	Method ResetSet()
		Self.ResetValues()
		Self.sql_set.Clear()
	End Method
	
	Rem
		bbdoc: Reset query clauses and values
		about: Reset SET clause, values, WHERE clause and LIMIT clause
	End Rem
	Method Reset()
		Self.ResetLimit()
		Self.ResetValues()
		Self.sql_where.Clear()
		Self.sql_set.Clear()
	End Method
	
	Rem
		bbdoc: Add WHERE (AND) part
		returns: TSqlBuilder object (Self)
	End Rem
	Method Where:TSqlBuilder(part:String, data:TDBType = Null, statement:Int = TQueryPart.stAND)
		Self.sql_where.AddLast(TQueryPart.Create(part, statement))
		Self._values.AddLast(data)
		Return Self
	End Method
	
	Rem
		bbdoc: Add WHERE (OR) part
		returns: TSqlBuilder object (Self)
	End Rem
	Method OrWhere:TSqlBuilder(part:String, data:TDBType = Null)
		Return Self.Where(part, data, TQueryPart.stOR)
	End Method
	
	Rem
		bbdoc: Add SET data
		returns: TSqlBuilder object (Self)
	End Rem
	Method Set:TSqlBuilder(part:String, data:TDBType = Null)
		Self.sql_set.AddLast(TQueryPart.Create(part))
		Self._values.AddLast(data)
		Return Self
	End Method
	
	Rem
		bbdoc: Add ORDER BY clause
		returns: TSqlBuilder object (Self)
	End Rem
	Method Order:TSqlBuilder(part:String)
		Self.sql_order.AddLast(part)
		Return Self
	End Method
	
	Rem
		bbdoc: Set LIMIT clause
		returns: TSqlBuilder object (Self)
	End Rem
	Method Limit:TSqlBuilder(limit:Int, offset:Int)
		If limit > 0
			Self.sql_limit = "LIMIT " + limit + " OFFSET " + offset
		Else
			Self.sql_limit = "LIMIT " + limit
		End If
		Return Self
	End Method
	
	Rem
		bbdoc: Reset LIMIT clause
	End Rem
	Method ResetLimit()
		Self.sql_limit = Null
	End Method
	
	'Private method
	'Assemble query
	Method _Assemble:String()
		Local query:String
		
		'Decide query type
		Select Self.sql_type
			Case TSqlBuilder.TYPE_SELECT
				query = Self._AssembleSELECT()
			Case TSqlBuilder.TYPE_UPDATE
				query = Self._AssembleUPDATE()
			Case TSqlBuilder.TYPE_DELETE
				query = Self._AssembleDELETE()
			Case TSqlBuilder.TYPE_INSERT
				query = Self._AssembleINSERT()
		End Select
		
		'Build WHERE part
		If Not Self.sql_where.IsEmpty()
			query:+"WHERE "
			Local i:Int = 0
			For Local queryPart:TQueryPart = EachIn Self.sql_where
				If i > 0
					Select queryPart.statement
						Case queryPart.stAND
							query:+"AND "
						Case queryPart.stOR
							query:+"OR "
					End Select					
				End If

				Local part:String = queryPart.sql
				query:+Self._QuoteColumns(part) + " "
				i:+1
			Next
		End If
		
		'Build ORDER BY part
		If Not Self.sql_order.IsEmpty() And Self.sql_type = TSqlBuilder.TYPE_SELECT
			query:+"ORDER BY "
			For Local str:String = EachIn Self.sql_order
				query:+Self._QuoteColumns(str) + ", "
			Next
			query = Mid(query, 0, query.length - 1) + " "
		End If
		
		'Build LIMIT part
		If Self.sql_limit
			query:+Self.sql_limit
		End If

		Return query
	End Method
	
	'Private method
	'Return table name, quoted or not
	Method _AssembleTableName:String()
		If TSqlBuilder.QuotingEnabled()
			Return "`" + Self.sql_from[0] + "`"
		End If
		Return Self.sql_from[0]
	End Method
	
	'Private method
	'Build SELECT query
	Method _AssembleSELECT:String()
		Local query:String = "SELECT " + Self.sql_from[1] + " FROM " + Self._AssembleTableName() + " "
		Return query
	End Method

	'Private method
	'Build UPDATE query
	Method _AssembleUPDATE:String()
		Local query:String = "UPDATE " + Self._AssembleTableName() + " "
		
		'Build SET part
		If Not Self.sql_set.IsEmpty()
			query:+"SET "
			For Local queryPart:TQueryPart = EachIn Self.sql_set
				query:+Self._QuoteColumns(queryPart.sql) + " = ?, "
			Next
			
			query = Mid(query, 0, query.Length - 1) + " "
		End If
		
		Return query
	End Method
	
	'Private method
	'Build DELETE query
	Method _AssembleDELETE:String()
		Local query:String = "DELETE FROM " + Self._AssembleTableName() + " "
		Return query
	End Method

	'Private method
	'Build INSERT query
	Method _AssembleINSERT:String()
		Local query:String = "INSERT INTO " + Self._AssembleTableName() + " "
		
		'Our query parts
		Local columnNames:String = "("
		Local columnData:String = "VALUES("
		
		'Build up query parts
		If Not Self.sql_set.IsEmpty()
			For Local queryPart:TQueryPart = EachIn Self.sql_set
				'Add column name
				columnNames:+Self._QuoteColumns(queryPart.sql) + ","
				'Add placeholder
				columnData:+"?,"
			Next
		End If
		
		'Remove final comma from strings
		columnNames = Mid(columnNames, 0, columnNames.Length)
		columnData = Mid(columnData, 0, columnData.Length)
		'Close sequence
		columnNames:+")"
		columnData:+") "
		
		'Finish query
		query:+columnNames + columnData
		
		Return query
	End Method
	
	'Private method
	'Quote column names
	Method _QuoteColumns:String(part:String)
		'Check if quoting can be skipped
		If Not TSqlBuilder.QuotingEnabled()
			Return part
		End If
		
		'Quote all column names
		If Self._columns
			For Local column:TDBColumn = EachIn Self._columns.Values()
'				Try
					Local regex:TRegEx = TRegEx.Create("^" + column.name)
					part = regex.ReplaceAll(part, "`" + column.name + "`")
					regex = Null
'				Catch ex:TRegExException
'					DebugLog ex.toString()
'				Catch ex:Object
'					DebugLog ex.ToString()
'				End Try
			Next
		End If
		Return part
	End Method

	Rem
		bbdoc: Enable or disable column quoting
		about: This is a global setting that can also be accessed through TSqlBuilder.enable_quoting
	End Rem
	Function SetQuoting(val:Int)
		TSqlBuilder.enable_quoting = val
	End Function
	
	Rem
		bbdoc: Check if column quoting is enabled.
		about: This is a global setting
	End Rem
	Function QuotingEnabled:Int()
		Return TSqlBuilder.enable_quoting
	End Function
End Type

'QueryPart
'Internal datastructure used by TSqlBuilder
Type TQueryPart
	Field sql:String
	Field statement:Int
	
	Const stAND:Int = 0
	Const stOR:Int = 1
	
	Function Create:TQueryPart(sql:String, statement:Int = stAND)
		Local obj:TQueryPart = New TQueryPart
		obj.sql = sql
		obj.statement = statement
		Return obj
	End Function
EndType
