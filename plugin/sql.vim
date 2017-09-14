function! SqlNewWindow()
    tabe
    set buftype=nofile
    set filetype=sql
endfunction

command! SqlNewWindow :call SqlNewWindow()
