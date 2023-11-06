  program matin
                version 13.1
                gettoken mname 0 : 0
                syntax using/

                tempname hdl
                file open `hdl' using `"`using'"', read binary

                file read `hdl' %14s signature
  /* changed */ if "`signature'" != "mymatout 1.0.1" {
  /* changed */         disp as err "file not mymatout 1.0.1"
                        exit 610
                }

                tempname val
                file read `hdl' %1b `val'
                local border = `val'
                file set `hdl' byteorder `border'

                file read `hdl' %2b `val'
                local r = `val'
                file read `hdl' %2b `val'
                local c = `val'

                matrix `mname' = J(`r', `c', 0)

  /* new */     file read `hdl' %4b `val'
  /* new */     local len = `val'
  /* new */     file read `hdl' %`len's names
  /* new */     matrix rownames `mname' = `names'

  /* new */     file read `hdl' %4b `val'
  /* new */     local len = `val'
  /* new */     file read `hdl' %`len's names
  /* new */     matrix colnames `mname' = `names'

                forvalues i=1(1)`r' {
                        forvalues j=1(1)`c' {
                                file read `hdl' %8z `val'
                                matrix `mname'[`i',`j'] = `val'
                        }
                }
                file close `hdl'
        end
