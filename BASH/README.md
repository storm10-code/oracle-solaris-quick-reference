BASH Cheat Sheet
=======================

This shows examples for Bash scripting. 

Special Variables
------------------

A quick guide to Bash special inbuilt variables. These are kinda of the building blocks of most shell scripts. Learn them and master them.

Special Variable| Description
---------|----------
$# |	Number of command-line arguments.
$_ |	The underscore variable is set at shell startup and contains the absolute file name of the shell or script being executed as passed in the argument list. Subsequently, it expands to the last argument to the previous command, after expansion. It is also set to the full pathname of each command executed and placed in the environment exported to that command. When checking mail, this parameter holds the name of the mail file.
$- |	A hyphen expands to the current option flags as specified upon invocation, by the set built-in command, or those set by the shell itself (such as the -i).
$? |	Exit value of last executed command.
$	 |Process number of the shell.
$! |	Process number of last background command.
$0 |	First word; that is, the command name. This will have the full pathname if it was found via a PATH search.
$n |	Individual arguments on command line (positional parameters). The Bourne shell allows only nine parameters to be referenced directly (n = 1–9); Bash allows n to be greater than 9 if specified as ${n}.
$*, $@ |	All arguments on command line ($1 $2 …).
“$*” |	All arguments on command line as one string (“$1 $2…”). The values are separated by the first character in $IFS.
“$@” |	All arguments on command line, individually quoted (“$1” “$2” …).

Variables/Parameters
--------------------
```NAME="John"
echo ${NAME}
echo "$NAME"
echo "${NAME}!"

echo "${NAME/J/j}"         #-> Regex substitution
echo "${NAME::2}"          #-> Slicing Jo
echo "${NAME::-1}"         #-> Joh
echo "${NAME:1:2}"         #-> Slicing oh (position 1 print first two chars)
echo "${NAME:0:3}"         #-> Slicing Joh (position 0 print first three chars))
echo ${food:-Cake}         #=> If defined $food or "Cake"

SRC="/path/to/foo.cpp"
BASE=${SRC##*/}   #=> "foo.cpp" (basepath) or basename $SRC
DIR=${SRC%$BASE}  #=> "/path/to/" (dirpath) or DIR="${SRC%foo.cpp}"

```

Brace expansion
```
echo {A,B}.js
{A,B}	Same as A B
{A,B}.js	Same as A.js B.js
{1..5}	Same as 1 2 3 4 5
```

Substitution
```
FOO="Daddy.go"
echo ${FOO%go}	Remove suffix
echo ${FOO#Daddy}	Remove prefix
echo ${FOO%%suffix}	Remove long suffix
echo ${FOO##prefix}	Remove long prefix
echo ${FOO/from/to}	Replace first match
echo ${FOO//from/to}	Replace all
echo ${FOO/%from/to}	Replace suffix
echo ${FOO/#Daddy/Mummy}	Replace prefix
```

#Loops
```
Basic for loop
for i in /etc/rc.*; do
  echo $i
done
C-like for loop
for ((i = 0 ; i < 100 ; i++)); do
  echo $i
done
Ranges
for i in {1..5}; do
    echo "Welcome $i"
done
With step size
for i in {5..50..5}; do
    echo "Welcome $i"
done
Reading lines
< file.txt | while read line; do
  echo $line
done
Forever
while true; do
  ···
done
```


Functions
Defining functions
```
myfunc() {
    echo "hello $1"
}
```
# Same as above (alternate syntax)
```
function myfunc() {
    echo "hello $1"
}
myfunc "John"
```
Returning values
```
myfunc() {
    local myresult='some value'
    echo $myresult
}
result="$(myfunc)"
```
Raising errors
```
myfunc() {
  return 1
}
if myfunc; then
  echo "success"
else
  echo "failure"
fi
```
