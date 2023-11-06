program matout
                version 13.1
                gettoken mname 0 : 0
                syntax using/ [, replace]

                local r = rowsof(`mname')
                local c = colsof(`mname')

                tempname hdl
                file open `hdl' using `"`using'"', `replace' write binary

  /* changed */ file write `hdl' %14s "mymatout 1.0.1"
                file write `hdl' %1b (byteorder())
                file write `hdl' %2b (`r') %2b (`c')

  /* new */     local names : rownames `mname'
  /* new */     local len : length local names
  /* new */     file write `hdl' %4b (`len') %`len's `"`names'"'

  /* new */     local names : colnames `mname'
  /* new */     local len : length local names
  /* new */     file write `hdl' %4b (`len') %`len's `"`names'"'

                forvalues i=1(1)`r' {
                        forvalues j=1(1)`c' {
                                file write `hdl' %8z (`mname'[`i',`j'])
                        }
                }
                file close `hdl'
        end
