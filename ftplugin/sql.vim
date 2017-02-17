" Plugin setup {{{ ============================================================
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1
" ========================================================================= }}}

" TODOS {{{ ===================================================================
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
" ========================================================================= }}}

" Abbreviations {{{ ===========================================================
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
" ========================================================================= }}}

" Custom Operators {{{ ========================================================
" 'join using' operator {{{ ---------------------------------------------------
function! s:JoinUsingOperator(type)
    let l:old_register = @@
    echom a:type
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
" ------------------------------------------------------------------------- }}}

" 'join on' operator {{{ ------------------------------------------------------
function! s:JoinOnOperator(type)
    let l:old_register = @@
    echom a:type
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
" ------------------------------------------------------------------------- }}}
" ========================================================================= }}}

