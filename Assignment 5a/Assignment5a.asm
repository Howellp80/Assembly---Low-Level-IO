TITLE LowLevelIOProcedures     (Assignment5a.asm)

; Author: Parker Howell
; Course / Project ID      CS271 Assignment 5a            
; Date: 8-6-16
; Description: The program will take 10 integers as string input, convert them to decimal values, 
;              display them. Additionally the sum and average will be calculated and displayed 
;              as strings.

INCLUDE Irvine32.inc

MAX = 10       ; amount of strings to process and store as decimal values
LOCHAR = 48    ; ascii equivalent of 0. input should not be lower
HICHAR = 57    ; ascii equivalent of 9. input should not be higher


.data

valArray   DWORD  MAX DUP (?)   ; array to hold validated decimal user input
index      DWORD  0             ; tracks index location of valArray
arrSum     DWORD  ?             ; total sum of valArray values
arrAvg     DWORD  ?             ; average of arrSum

intro      BYTE     "Hello, and welcome to Parker Howell's assignment 5(a),",0dh,0ah
           BYTE     "Designing low-level I/O procedures program!", 0
instruct   BYTE     "Please provide 10 unsigned decimal integers.",0dh,0ah
           BYTE     "Each number needs to be small enough to fit inside a 32 bit register.",0dh,0ah
           BYTE     "After you have finished inputting the raw numbers I will display a list",0dh,0ah
           BYTE     "of the integers, their sum, and their average value.", 0
prompt     BYTE     "Please enter an unsigned number: ", 0
error      BYTE     "ERROR: You did not enter an unsigned number or your number was too big.", 0dh,0ah, 0
display    BYTE     "You entered the following numbers: ", 0
space      BYTE     ", ", 0
sum        BYTE     "The sum of these numbers is: ", 0
avg        BYTE     "The average is: ", 0
bye        BYTE     "Yay for I/O!   Bye!", 0



; * MACROS *

;************************************************************************
getString MACRO array
; Macro to store a atring from standard input into an array
; receives: array argument
; returns: string stored in array with size of string in EAX
; preconditions: none
; registers changed: edx, ecx, eax
;************************************************************************
     push      ecx
     push      edx
     mov       edx, array     ; EDX points to array
     mov       ecx, 50        ; max amount of bytes to store
     call      ReadString     ; store entered string
     pop       edx
     pop       ecx
ENDM




;************************************************************************
displayString MACRO str
; Macro to write a string at the passed in argument location
; receives: str argument pointing to a string address
; returns: prints string at str address
; preconditions: str argument is valid
; registers changed: edx
;************************************************************************
     push      edx
     mov       edx, str       ; EDX = address of str
     call      WriteString    ; prints str string to console
     pop       edx
ENDM


; * END OF MACROS *



;************************************************************************
;  MAIN
;************************************************************************
.code
main PROC

     call   Clrscr             ; clears the screen

     call   introduction       ; introduces program

     push   OFFSET   valArray  ; to store valid strings as decimals
     Push   OFFSET   index     ; to track place in valArray
     call   readVal            ; gets and validates user data
                                        
     push   OFFSET   valArray  ; add array pointer to stack
     push   OFFSET   display   ; add Msg pointer to stack
     push   OFFSET   space     ; for formatting
     call   printArray         ; prints the array

     push   OFFSET   valArray  ; add array pointer to stack
     push   OFFSET   arrSum    ; to store the array sum
     call   sumArr             ; sums the elements in valArray

     push   OFFSET  arrSum     ; pointer to sum of array
     push   OFFSET  sum        ; add Msg pointer to stack
     call   writeVal           ; displays the sum of elements in valArray

     push   OFFSET  arrSum     ; pointer to sum of array
     push   OFFSET  arrAvg     ; pointer to averaage of array
     call   getAvg             ; calculates the average of values in valArray

     push   OFFSET  arrAvg     ; pointer to average of array
     push   OFFSET  avg        ; add Msg pointer to stack
     call   writeVal           ; displays the average of elements in valArray

     call farewell             ; say goodbye

	exit	; exit to operating system
main ENDP




;************************************************************************
;  procedures below 
;************************************************************************

;************************************************************************
introduction PROC
; Procedure to introduce the program and author and display instructions.
; receives: none
; returns: intro and instructions printed to console
; preconditions: none
; registers changed: edx
;************************************************************************
     pushad
     mov       edx, OFFSET intro         ; prints intro to console
     call      WriteString
     call      CrLf
     mov       edx, OFFSET instruct      ; prints instructions to console
     call      WriteString
     call      CrLf
     call      CrLf

     popad
     ret
introduction ENDP




;************************************************************************
readVal PROC
; Procedure to get and validate user entered strings. Store strings in  
; valArr as decimal values.
; receives: arguments for valArray and index variables
; returns: valArray contains 10 decimal values within range
; preconditions: above 2 arguments are valid
; registers changed: ebp, ebx, ecx, esi, eax, edi, edx
;************************************************************************
     LOCAL     tempArr[50]:BYTE,      ; local array to store user string
               total:DWORD            ; for converting char to dec
     pushad
     lea       ebx, tempArr           ; get the address of tempArr
     
     cld                              ; clear direction flag
     mov       ecx, MAX               ; set outer loop counter

input:
     displayString  OFFSET prompt     ; ask user to enter a string value
     getString ebx                    ; put user entered value in tempArr
     mov       esi, ebx               ; esi points to tempArr for validatoin
                      
     push      ecx                    ; save outer loop counter
     
     cmp       eax, MAX               ; check if string is too big
     ja        err 
     mov       ecx, eax               ; inner loop = size of entered string
     mov       total, 0               ; clear accumulator

validate:
     lodsb                            ; load byte of tempArr into al
     cmp       al, LOCHAR             ; make sure entered byte is >= 0
     jb        err
     cmp       al, HICHAR             ; make sure entered byte is <= 9
     ja        err

     jmp       goodByte               ; if byte is within range


err:                                 ; out of range or too large
     displayString  OFFSET error     ; tell user string is not valid
     pop       ecx                   ; restrore outer loop / align stack
     jmp       input                 ; get a new string

     ; the byte is in range 0-9
goodByte:                            ; convert string to decimal
                                     ; using formula from lecture video 23 @ time 2:50
     movzx     edi, al               ; zero extend al into edx
     sub       edi, LOCHAR           ; convert to decimal       char - 48 = dec

     mov       eax, MAX              ; 10 * x from video
     mul       total            
     mov       total, eax            ; save in total
     add       total, edi            ; (10 * x) + (str[k] - 48) from video

     Loop      validate              ; for all bytes in the string


     ; if we're here we have a valid string converted to Dec in total
               
     push      ebx                 ; save registers
     push      eax

     mov       edi, [ebp + 12]     ; edi points to valArray
     mov       eax, [ebp + 8]      ; eax points to index
     mov       ebx, [eax]          ; ebx = index offset
     mov       ecx, total          ; ecx = total
     mov       [edi + ebx], ecx    ; save the valid Decimal
     mov       edx, 4
     add       ebx, edx            ; increment index offset 
     mov       [eax], ebx          ; and save it in index variable

     pop       eax                 ; restore registers
     pop       ebx

     pop       ecx                    ; restore outer loop counter
     Loop      input                  ; repeat MAX amout of times
    
     call      CrLf                   ; formatting

     popad
     ret       8
readVal ENDP





;************************************************************************
printArray PROC
; Procedure to print the values in the array to the console 
; receives: address of array pushed on stack
;           address of userRands pushed on stack
;           address of ArrayMsg1 pushed on stack
; returns: prints contents of array to console 
; preconditions: above 3 valid arguments are pushed on stack
; registers changed: ebp, esi, ecx, edx, eax
;************************************************************************
     push      ebp               ; save old ebp
     mov       ebp, esp
     pushad
     mov       esi, [ebp + 16]   ; esi points to array
     mov       edx, [ebp + 12]   ; edx points to ArrayMsg

     displayString edx           ; prints ArrayMsg to console
     call      CrLf              ; formatting
     
     mov       ecx, MAX         ; set loop counter
printElement:                   ; printing loop
     mov       eax, [esi]       ; get current element of array
     call      WriteDec         ; print it

     cmp       ecx, 1           ; if its the last number dont print a comma
     jbe       noComma

     displayString [ebp + 8]    ; print a comma and a space ", "
    
noComma:

     add       esi, 4         ; go to next element of array
     loop      printElement
     
     call      CrLf           ; formatting
     call      CrLf

     popad
     pop       ebp            ; restore ebp
     ret       12
printArray ENDP




;************************************************************************
sumArr PROC
; Procedure to sum values in valArray
; receives: arguments for valArray and arrSum
; returns: sum of valArray in arrSum
; preconditions: above arguments are valid
; registers changed: ebp, ebx, esi, ecx, eax
;************************************************************************
     LOCAL     total:DWORD         ; for converting char to dec
     pushad
     lea       ebx, total          ; get the address of total
     mov       esi, [ebp + 12]     ; esi points to valArray
     mov       total, 0            ; set the accumulator     
     mov       ecx, MAX            ; set loop counter    

addEle:
     mov       eax, [esi]          ; get array element       
     add       total, eax          ; sum total and array element
     add       esi, 4              ; next element
     Loop      addEle              ; add all the elements of valArray

     mov       eax, [ebp + 8]      ; eax points to arrSum variable
     mov       ecx, total          ; prep to save total
     mov       [eax], ecx          ; save total in arrSum

     popad
     ret       8
sumArr ENDP




;************************************************************************
writeVal PROC
; Procedure to print value passed in as a string to console
; receives: pointer to value to print and pointer to display text
; returns: prints display text to console followed by converted string value
; preconditions: above two valid pointers are on stack
; registers changed: ebp, ebx, edi, eax, ecx, edx
;************************************************************************
     LOCAL     tempArr[50]:BYTE      ; local array to store user string
     lea       ebx, tempArr          ; get the address of tempArr
     pushad
     
     displayString [ebp + 8]         ; output string
     
     mov       edi, ebx              ; edi points to tempArr
     mov       ebx, SIZEOF tempArr   ; move pointer to end of tempArr...
     add       edi, ebx
     dec       edi                   ; esi points to last element of tempArr
     std                             ; set the direction flag

     mov       al, 0                 ; set last element of tempArr with 0
     stosb

     ; convert dec to string
     mov       ecx, [ebp + 12]   ; EAX = number to convert to string
     mov       eax, [ecx]
     mov       ebx, MAX          ; set divisor
divLoop:
     mov       edx, 0         ; prep for div
     div       ebx            ; edx:eax / ebx
     mov       ecx, eax       ; save eax val
     add       edx, LOCHAR    ; convert to string val
     mov       al, dl         ; move remainder in to al
     stosb                    ; move al into next element of tempArr
     mov       eax, ecx       ; restore eax

     cmp       eax, 0         ; check if we need to div again
     ja        divLoop

     inc       edi            ; point edi to first number in tempArr
     displayString  edi       ; print out string value

     call      CrLf           ; formatting
     call      CrLf

     popad
     ret       8
writeVal ENDP




;************************************************************************
getAvg PROC
; Procedure to find the average of the values in valArray
; receives: pointer to sum of values in valArray and pointer to arrAvg variable
; returns: the average is stored in arrAvg variable
; preconditions: above two arguments are valid and on stack
; registers changed: ebp, ecx, eax, edx, ebx
;************************************************************************
     push      ebp               ; save old ebp
     mov       ebp, esp
     pushad

     mov       ecx, [ebp + 12]   ; EAX = number to average  
     mov       eax, [ecx]

     mov       edx, 0            ; prep for div
     mov       ebx, MAX          ; set divisor
     div       ebx               ; EDX:EAX / EBX
     mov       ebx, [ebp + 8]    ; EBX points to arrAvg variable
     mov       [ebx], eax        ; save the average in arrAvg

     popad
     pop       ebp            ; restore ebp
     ret       8
getAvg ENDP




;************************************************************************
farewell PROC
; Procedure to say goodbye
; receives: none
; returns: prints bye message to console
; preconditions: none
; registers changed: edx
;************************************************************************
     mov       edx, OFFSET bye     ; EDX points to bye message
     call      WriteString
     call      CrLf                ; formatting
     call      CrLf

     ret
farewell ENDP



END main
