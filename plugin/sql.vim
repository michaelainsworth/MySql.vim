function s:SqlNewWindow(where)
    if a:where ==? 'h'
        vnew
    elseif a:where ==? 'l'
        vnew
        normal r
    elseif a:where ==? 'k'
        new
    elseif a:where ==? 'j'
        new
        normal r
    elseif a:where ==? 't'
        tabe
    else
        echoe "Invalid split argument."
    endif
endfunction

function! SqlTemp()
    call <SID>SqlNewWindow(a:where)

    set buftype=nofile
    set filetype=sql
endfunction

function! SqlNew(where)
    call <SID>SqlNewWindow(a:where)

    set filetype=sql
endfunction

command! -nargs=? SqlTemp :call SqlTemp(<q-args>)
command! -nargs=? SqlNew :call SqlNew(<q-args>)
