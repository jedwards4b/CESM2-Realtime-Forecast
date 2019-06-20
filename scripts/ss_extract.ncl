;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function ss_extract
;
;   Date Initiated: 31 July 1998
;    Last Modified: Fri Jul 31 11:14:19 MDT 1998
;
;      Description: Provides a means of extracting a selected segment of a
;                   string with notation analagous to f77/f90 substring
;                   extraction.
;
;        Arguments:
;
;  complete_string: Type string. String from which one wants to extract a
;                   selected substring.
;         beg_char: Type integer. Integer position of first character of
;                   substring.
;         end_char: Type integer. Integer position of last character of
;                   substring.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  undef("ss_extract")

  function ss_extract( complete_string:string,   \
                              beg_char:integer,  \ 
                              end_char:integer   )

  local char_array, ss_type_char

  begin

        char_array = stringtochar(complete_string) ; Convert string to an
                                                     ; equivalent array of
                                                     ; characters.
 
        ss_type_char = char_array( beg_char - 1 : end_char - 1 )
                                                     ; Extract subarray of
                                                     ; characters corresponding
                                                     ; to substring.

      ss_type_string = chartostring(ss_type_char)    ; Convert subarray of
                                                     ; characters to a string.

  delete(char_array)                                 ; No longer needed.

  delete(ss_type_char)                               ; No longer needed.

  return(ss_type_string)                             ; Return substring.

  end
