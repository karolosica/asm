;Aplikacja korzystaj�ca z otwartego okna konsoli
.586
.MODEL flat, STDCALL
                                                            ;--- stale ---
                                                            ;--- z pliku windows.inc ---
STD_INPUT_HANDLE equ -10
STD_OUTPUT_HANDLE equ -11
                                                            ;--- funkcje API Win32 ---
                                                            ;--- z pliku user32.inc ---
CharToOemA PROTO :DWORD,:DWORD
                                                            ;--- z pliku kernel32.inc ---
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ExitProcess PROTO :DWORD
wsprintfA PROTO C :VARARG
lstrlenA PROTO :DWORD
ScanInt PROTO C adres:DWORD
;-------------
includelib .\lib\user32.lib
includelib .\lib\kernel32.lib
;-------------
_DATA SEGMENT
hout DD ?
hinp DD ?
naglow DB "Autor aplikacji Grzegorz Makowski.",0                ; nag��wek
zaprX DB 0Dh,0Ah,"Prosz� wprowadzi� argument X [+Enter]: ",0    ; zaproszenie
wzor DB 0Dh,0Ah,"Funkcja f(X) = X/X-X*X = %ld ",0               ; tekst formatuj�cy
ALIGN 4                                                         ; wyr�wnanie do granicy 4-bajtowej
rozmN DD 0                                                      ; ilo�� znak�w w nag��wku
rozmX DD 0                                                      ; ilo�� znak�w w zaproszeniu X
zmX DD 1                                                        ; argument X
rout DD 0                                                       ; faktyczna ilo�� wyprowadzonych znak�w
rinp DD 0                                                       ; faktyczna ilo�� wprowadzonych znak�w
bufor DB 128 dup(0)                                             ; rezerwacja miejsca na bufor i inicjalizacja 0
rbuf DD 128                                                     ; rozmiar bufora
_DATA ENDS
_TEXT SEGMENT
start:
                                                                ; wywo�anie funkcji GetStdHandle
push STD_OUTPUT_HANDLE                                          ; odk�adanie na stos
call GetStdHandle                                               ; funkcja GetStdHandle = podaj deskryptor ekranu
mov hout, EAX                                                   ; deskryptor wyj�ciowego bufora konsoli
push STD_INPUT_HANDLE                                           ; odk�adania na stos
call GetStdHandle                                               ; funkcja GetStdHandle = podaj deskryptor klawiatury
mov hinp, EAX                                                   ; deskryptor wej�ciowego bufora konsoli

;--- nag��wek ---------
push OFFSET naglow                                              ; odk�adanie na stos
push OFFSET naglow                                              ; odk�adanie na stos
call CharToOemA                                                 ; wywo�anie funkcji konwersji polskich znak�w

;--- wy�wietlenie ---------
push OFFSET naglow
call lstrlenA                                                   ; wywo�anie funkcji
mov rozmN, EAX                                                  ; ilo�� znak�w
push 0                                                          ; odk�adanie na stos: rezerwa, musi by� zero
push OFFSET rout                                                ; odk�adanie na stos: wska�nik na faktyczn� ilo�� wyprowadzonych znak�w
push rozmN                                                      ; odk�adanie na stos: ilo�� znak�w
push OFFSET naglow                                              ; odk�adanie na stos: wska�nik na tekst
push hout                                                       ; odk�adanie na stos: deskryptor wyj�ciowego buforu konsoli
call WriteConsoleA                                              ; wywo�anie funkcji WriteConsoleA

;--- zaproszenie A ---------
push OFFSET zaprX                                               ; odk�adanie na stos
push OFFSET zaprX                                               ; odk�adanie na stos
call CharToOemA                                                 ; wywo�anie funkcji konwersji polskich znak�w

;--- wy�wietlenie zaproszenia A ---
push OFFSET zaprX                                               ; odk�adanie na stos
call lstrlenA
mov rozmX, EAX                                                  ; ilo�� znak�w z akumulatora do pami�ci
push 0                                                          ; rezerwa, musi by� zero
push OFFSET rout                                                ; wska�nik na faktyczn� ilo�� wyprowadzonych znak�w
push rozmX                                                      ; ilo�� znak�w
push OFFSET zaprX                                               ; wska�nik na tekst
push hout                                                       ; deskryptor buforu konsoli
call WriteConsoleA                                              ; funkcja WriteConsoleA = wy�wietlenie na ekranie

;--- czekanie na wprowadzenie znak�w, koniec przez Enter ---
push 0                                                          ; rezerwa, musi by� zero
push OFFSET rinp                                                ; wska�nik na faktyczn� ilo�� wprowadzonych znak�w
push rbuf                                                       ; rozmiar bufora
push OFFSET bufor                                               ; wska�nik na bufor
push hinp                                                       ; deskryptor buforu konsoli
call ReadConsoleA                                               ; wywo�anie funkcji ReadConsoleA = odczyt z k�awiatury
lea EBX,bufor
mov EDI,rinp
mov BYTE PTR [EBX+EDI-1],0                                      ; zero na ko�cu tekstu

;--- przekszta�cenie A
push OFFSET bufor                                               ; odk�adanie na stos
call ScanInt                                                    ; wywo�anie funkcji przekszta�cenie tekstu do postaci binarnej
add ESP, 8
mov zmX, EAX

;--- obliczenia ---
mov EAX, zmX                                                    ; przeniesienei doeax zmiennej
mul zmX                                                         ; mnozenie zmiennej
mov ECX, EAX                                                    ; przeniesienie 
mov EAX, zmX
mov EDX, 0                                                      ; zerujemt edx
div zmX                                                         ; dzieli zmeinna
sub EAX, ECX                                                    ; odejmowanie i wynik w eax

;;;; ................
;--- wyprowadzenie wyniku oblicze� ---
push EAX                                                        ; odk�adanie na stos
push OFFSET wzor                                                ; odk�adanie na stos
push OFFSET bufor                                               ; odk�adanie na stos
call wsprintfA                                                  ; funkcja przekszta�cenia liczby; zwraca ilo�� znak�w
add ESP, 12                                                     ; czyszczenie stosu
mov rinp, EAX                                                   ; zapami�tywanie ilo�ci znak�w

;--- wy�wietlenie wynika ---------
push 0                                                          ; rezerwa, musi by� zero
push OFFSET rout                                                ; wska�nik na faktyczn� ilo�� wyprowadzonych znak�w
push rinp                                                       ; ilo�� znak�w
push OFFSET bufor                                               ; wska�nik na tekst w buforze
push hout                                                       ; deskryptor buforu konsoli
call WriteConsoleA                                              ; wywo�anie funkcji WriteConsoleA

;--- zako�czenie procesu ---------
push 0
call ExitProcess                                                ; wywo�anie funkcji ExitProcess

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ScanInt PROC C adres
;; funkcja ScanInt przekszta�ca ci�g cyfr do liczby, kt�r� b�dzie w EAX
;; argument - zako�czony zerem wiersz z cyframi
;; rejestry: EBX - adres wiersza, EDX - znak liczby, ESI - indeks cyfry w wierszu, EDI - tymczasowy
;--- pocz�tek funkcji
LOCAL number, znacz

;--- odk�adanie na stos
push EBX
push ECX
push EDX
push ESI
push EDI

;--- przygotowywanie cyklu
INVOKE lstrlenA, adres
mov EDI, EAX                                                    ; ilo�� znak�w
mov ECX, EAX                                                    ; ilo�� powt�rze� = ilo�� znak�w
xor ESI, ESI                                                    ; wyzerowanie ESI
xor EDX, EDX                                                    ; wyzerowanie EDX
xor EAX, EAX                                                    ; wyzerowanie EAX
mov EBX, adres

;-----------
mov znacz,0
mov number,0

;--- cykl --------------------------
pocz:
cmp BYTE PTR [EBX+ESI], 0h                                              ; por�wnanie z kodem \0
jne @F
jmp et4
@@:
cmp BYTE PTR [EBX+ESI], 0Dh                                             ; por�wnanie z kodem CR
jne @F
jmp et4
@@:
cmp BYTE PTR [EBX+ESI], 0Ah                                             ; por�wnanie z kodem LF
jne @F
jmp et4
@@:
cmp BYTE PTR [EBX+ESI], 02Dh                                            ; por�wnanie z kodem '-'
jne @F
mov znacz, 1
jmp nast
@@: cmp BYTE PTR [EBX+ESI], '0'                                         ; por�wnanie z kodem '0'
jae @F
jmp nast
@@: cmp BYTE PTR [EBX+ESI], '9'                                         ; por�wnanie z kodem '9'
jbe @F
jmp nast

;----
@@: push EDX                                                            ; do EDX procesor mo�e zapisa� wynik mno�enia
mov EAX, number
mov EDI, 10
mul EDI                                                                 ; mno�enie EAX * (EDI=10)
mov number, EAX                                                         ; tymczasowo z EAX do EDI
xor EAX, EAX                                                            ; zerowanie EAX
mov AL, BYTE PTR [EBX+ESI]
sub AL, '0'                                                             ; korekta: cyfra = kod znaku - kod '0'
add number, EAX                                                         ; dodanie cyfry
pop EDX
nast: inc ESI
dec ECX
jz @F
jmp pocz
    
;--- wynik
@@:
et4:
cmp znacz, 1                                                            ; analiza znacznika
jne @F
neg number
@@:
mov EAX, number

;--- zdejmowanie ze stosu
pop EDI
pop ESI
pop EDX
pop ECX
pop EBX

;--- powr�t
ret
ScanInt ENDP
_TEXT ENDS
END start