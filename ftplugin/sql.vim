" PLUGIN SETUP {{{
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1
" END PLUGIN SETUP }}}
" TODOS {{{
" TODO: Commands that actually query the database for values.
"       E.g., alternatively, this could be a motion. That is, select a word
"       then type <leader>s (for select) and an SQL select statement is
"       generated.
" TODO: Perhaps an operator for issueing a select call. E.g., viw\s will
"       select the current inner word, inspect information_schema, then
"       write out an SQL statement using the primary key.
" TODO: Perhaps a update operator issueing a delete call. E.g., viw\u will
"       select the current inner word, inspect information_schema, then
"       write out a delete SQL statement using the primary key.
" TODO: Perhaps a delete operator issueing a delete call. E.g., viw\d will
"       select the current inner word, inspect information_schema, then
"       write out a delete SQL statement using the primary key.
" TODO: iff, ife abbreviations for vim!
" TODO: cse abbreviations for case statements
" TODO: cte abbreviation for common table expressions
" TODO: whr abbreviation for where clause
" TODO: The 'join using' and 'join on' operators could query the database for
"       primary keys...
" TODO: The abbreviations should probably be removed - just use the operators
"       instead.
" END TODOS }}}
" GENERAL FUNCTIONS {{{
" SystemExecute() {{{
" The SystemExecute() function takes a string and executes it, returning the
" textual output WITHOUT the last trailing newline.
" TODO: This function could probably be changed to work with a list of
" strings, which would help quoting.
function! s:SystemExecute(command)
    let l:value = system(a:command)
    let l:value = substitute(l:value, '\n\+$', '', '')
    return l:value
endfunction
" END SystemExecute() }}}
" END GENERAL FUNCTIONS }}}
" SQL ABBREVIATIONS {{{
" Query a particular tables
inoreabbrev <buffer> slct 
    \<esc>:set paste<cr>
    \i
	\<cr>select
	\<cr>      t.mycolumns
	\<cr>    , t.*
	\<cr>from mytable t
	\<cr>where 1=1
	\<cr>;
    \<esc>:set nopaste<cr>
    \?select<cr>
    \<esc>:noh<cr>

" Query information_schema.columns
inoreabbrev <buffer> icols 
    \<esc>:set paste<cr>
    \i
    \<cr>select
    \<cr>      c.table_schema
    \<cr>    , c.table_name
    \<cr>    , c.column_name
    \<cr>from information_schema.columns c
    \<cr>where 1=1
    \<cr>;
    \<esc>:set nopaste<cr>
    \?select<cr>
    \<esc>:noh<cr>

" Query information_schema.tables
inoreabbrev <buffer> itbls 
    \<esc>:set paste<cr>
    \i
    \<cr>select
    \<cr>      t.table_schema
    \<cr>    , t.table_name
    \<cr>    , t.table_type
    \<cr>from information_schema.tables t
    \<cr>where 1=1
    \<cr>;
    \<esc>:set nopaste<cr>
    \?select<cr>
    \<esc>:noh<cr>
" END SQL ABBREVIATION }}}
" SQL ESCAPE FUNCTIONS {{{
" SqlEscape() {{{
" This function takes a string and doubles any characters it finds in the
" chars array.
function! s:SqlEscape(str, chars)
    let l:result = ''

    let l:i = 0
    let l:s = len(a:str)

    while l:i < l:s
        let l:c = a:str[l:i]
        if -1 != index(a:chars, l:c)
            let l:result .= l:c . l:c
        else
            let l:result .= l:c
        endif

        let l:i += 1
    endwhile

    return l:result
endfunction
" END SqlEscape() }}}
" SqlEscapeString() {{{
" This function takes a string and escapes any single-quotes and percent
" signs.
function! s:SqlEscapeString(str)
    return "'" . <SID>SqlEscape(a:str, ["'", '%']) . "'"
endfunction
" END SqlEscapeString() }}}
" SqlEscapeIdentifier() {{{
" This function takes a string a returns a string suitable for using as an
" SQL identifier.
function! s:SqlEscapeIdentifier(str)
    return '"' . <SID>SqlEscape(a:str, ['"']) . '"'
endfunction
" End SqlEscapeIdentifier() }}}
" END SQL ESCAPE FUNCTIONS }}}
" SQL TABLE FUNCTIONS {{{
" SqlTableQualified() {{{
" This function takes a string representing a table name
" (with optional schema and alias components) and returns a dictionary.
" This dictionary contains three keys: schema, table and alias
function! s:SqlTableQualified(name)
    let l:schema = ''
    let l:table = ''
    let l:alias = ''

    " Get the optional schema name.
    let l:parts = split(a:name, '\.')
    if len(l:parts) > 1
        let l:schema = l:parts[0]
        let l:table = join(l:parts[1:], '.')
    else
        let l:schema = 'public'
        let l:table = a:name
    endif

    " Get the optional alias name
    let l:parts = split(l:table)
    let l:partlen = len(l:parts)
    if l:partlen > 1
        let l:table = join(l:parts[0:l:partlen-2], ' ')
        let l:alias = l:parts[l:partlen - 1]
    endif

    " TODO: A TableColumns function, which returns a list?
    " TODO: A TablePrimaryKey function, which returns a list?

    let l:result = {'schema':l:schema, 'table':l:table, 'alias':l:alias}
    return l:result
endfunction
" END SqlTableQualified() }}}
" SqlTableDequalified() {{{
function! s:SqlTableDequalified(table)
    let l:result = ''

    if 0 != strlen(a:table.schema)
        " TODO: Finish this!
        let l:result = <SID>SqlEscapeIdentifier(a:table.schema) . '.'
    endif

    let l:result .= <SID>SqlEscapeIdentifier(a:table.table)

    if a:include_alias = 1
        let l:result .= ' ' . <SID>SqlEscapeIdentifier(a:table.alias)
    endif

    return l:result
endfunction
" END SqlTableDequalified() }}}
" END SQL TABLE FUNCTIONS }}}
" CUSTOM OPERATORS {{{
" SqlTableColumns() {{{
" TODO: Change all functions to accept a string for a table name -
" the calling function should always qualify it.
function! s:SqlTableColumns(table)
    let l:table = <SID>SqlTableQualified(a:table)

    let l:does_table_exist = <SID>SqlTableDoesExist(table)


    let l:sql = "select "
    let l:sql.= "    '    ' || "
    let l:sql.= "    case "
    let l:sql.= "        when row_number() over () = 1 then '  ' "
    let l:sql.= "        else ', ' "
    let l:sql.= "    end || "
    let l:sql.= "    case "
    let l:sql.= "        when " . <SID>SqlEscapeString(l:table.alias) . " = '' then ''"
    let l:sql.= "        else " . <SID>SqlEscapeString(l:table.alias) . " || '.'"
    let l:sql.= "    end || "
    let l:sql.= "    column_name "
    let l:sql.= "from information_schema.columns "
    let l:sql.= "where table_schema = " . <SID>SqlEscapeString(l:table.schema) . " "
    let l:sql.= "and table_name = " . <SID>SqlEscapeString(l:table.table) . " "
    let l:sql.= "order by ordinal_position "

    let l:results = "select\n"
    let l:results.= <SID>SystemExecute('psql -tAc ' . shellescape(l:sql)) . "\n"
    let l:results.= "from " . l:selection . "\n"
    let l:results.= "where true\n"
    let l:results.= "order by 1\n"
    let l:results.= ";\n"
endfunction
" END SqlTableColumns() }}}
" SqlTableDoesExist() {{{
function! s:SqlTableDoesExist(name)
    let l:table = <SID>SqlTableQualified(a:name)

    let l:sql = "select count(distinct table_schema || table_name) "
    let l:sql.= "from information_schema.tables "
    let l:sql.= "where table_schema = " . <SID>SqlEscapeString(l:table.schema) . " "
    let l:sql.= "and table_name = " . <SID>SqlEscapeString(l:table.table) . " "

    let l:count = <SID>SystemExecute('psql -tAc ' . shellescape(l:sql))

    if l:count > 1
        throw "There is more than 1 table named " . l:table.name . "!"
    endif

    return l:count
endfunction
" END SqlTableDoesExist() }}}
" SelectOperator() {{{
function! s:SelectOperator(type)
    let l:old_register = @@

    if a:type ==# 'v'
        execute "normal! `<v`>x"   
    elseif a:type ==# 'V'
        execute "normal! `<v`>x"
    elseif a:type ==# 'char'
        execute "normal! `[v`]x"
    else
        return
    endif 

    let l:selection = @@
    let @@ = l:old_register

    let l:table = <SID>SqlTableQualified(l:selection)
    if 0 == <SID>SqlTableDoesExist(l:selection)
        throw "The table " . l:selection . " doesn't exist!"
    endif

    " TODO: quick function call to obtain all the columns for a table, with
    " alias

    " TODO: Wrap into a ExecutePsql call?
    let l:sql = "select "
    let l:sql.= "    '    ' || "
    let l:sql.= "    case "
    let l:sql.= "        when row_number() over () = 1 then '  ' "
    let l:sql.= "        else ', ' "
    let l:sql.= "    end || "
    let l:sql.= "    case "
    let l:sql.= "        when " . <SID>SqlEscapeString(l:table.alias) . " = '' then ''"
    let l:sql.= "        else " . <SID>SqlEscapeString(l:table.alias) . " || '.'"
    let l:sql.= "    end || "
    let l:sql.= "    column_name "
    let l:sql.= "from information_schema.columns "
    let l:sql.= "where table_schema = " . <SID>SqlEscapeString(l:table.schema) . " "
    let l:sql.= "and table_name = " . <SID>SqlEscapeString(l:table.table) . " "
    let l:sql.= "order by ordinal_position "

    let l:results = "select\n"
    let l:results.= <SID>SystemExecute('psql -tAc ' . shellescape(l:sql)) . "\n"
    let l:results.= "from " . l:selection . "\n"
    let l:results.= "where true\n"
    let l:results.= "order by 1\n"
    let l:results.= ";\n"

    put =l:results

    if a:type ==# 'v' || a:type ==# 'V'
        execute "normal! `<"
    elseif a:type ==# 'char'
        execute "normal! `["
    endif 
endfunction
nnoremap <buffer> <leader>s :set operatorfunc=<SID>SelectOperator<cr>g@
vnoremap <buffer> <leader>s :<c-u>call <SID>SelectOperator(visualmode())<cr>
" END SelectOperator() }}}
" InArrayOperator() {{{
function! s:InArrayOperator(type)
    if a:type !=# 'V'
        return
    endif

    " Get the selected text or the text
    " moved over.
    let l:old_register = @@
    execute "normal! `<v`>x"
    let l:selection = @@
    let @@ = l:old_register

    let l:lines = split(@@, "\n")
    let l:result = ''

    let l:i = 0
    let l:s = len(l:lines)
    while l:i < l:s
        let l:line = ''
        let l:x = 0
        let l:z = strlen(l:lines[l:i])
        while l:x < l:z
            let l:c = l:lines[l:i][l:x]
            if l:c ==# "'"
                let l:line .= l:c . l:c
            else
                let l:line .= l:c
            endif

            let l:x += 1
        endwhile

        if l:i == 0
            let l:result .= 'in ( '
        else
            let l:result .= ', '
        endif

        let l:result .= "'" . l:line . "'"    

        if l:i == l:s - 1
            let l:result .= ' )'
        endif 

        let l:i += 1
    endwhile

    put =l:result
endfunction

nnoremap <buffer> <leader>ia :set operatorfunc=<SID>InArrayOperator<cr>g@
vnoremap <buffer> <leader>ia :<c-u>call <SID>InArrayOperator(visualmode())<cr>
" END InArrayOperator() }}}
" JoinUsingOperator() {{{
function! s:JoinUsingOperator(type)
    let l:old_register = @@
    if a:type ==# 'v'
        execute "normal! `<v`>y"   
    elseif a:type ==# 'V'
        execute "normal! `<v`>y"   
    elseif a:type ==# 'char'
        execute "normal! `[v`]y"
    else
        return
    endif 

    let l:s = strlen(@@)
    execute "normal! ijoin \<esc>" . l:s . "la using ()\<esc>"

    let @@ = l:old_register
endfunction

nnoremap <buffer> <leader>ju :set operatorfunc=<SID>JoinUsingOperator<cr>g@
vnoremap <buffer> <leader>ju :<c-u>call <SID>JoinUsingOperator(visualmode())<cr>
" END JoinUsingOperator() }}}
" JoinOnOperator() {{{
function! s:JoinOnOperator(type)
    let l:old_register = @@
    if a:type ==# 'v'
        execute "normal! `<v`>y"   
    elseif a:type ==# 'V'
        execute "normal! `<v`>y"   
    elseif a:type ==# 'char'
        execute "normal! `[v`]y"
    else
        return
    endif 

    let l:s = strlen(@@)
    execute "normal! ijoin \<esc>" . l:s . "la on \<esc>"

    let @@ = l:old_register
endfunction
nnoremap <buffer> <leader>jo :set operatorfunc=<SID>JoinOnOperator<cr>g@
vnoremap <buffer> <leader>jo :<c-u>call <SID>JoinOnOperator(visualmode())<cr>
" END JoinOnOperator() }}}
" END CUSTOM OPERATORS }}}
