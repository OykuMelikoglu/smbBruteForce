# smbBruteForce v1.0
### Project for "Penetration Testing and Security Audits", A Brute Force Algorithm for SMB, written with Windows Powershell 

## What is smbBruteForce?
SmbBruteForce is a program that can be used to gather username and passwords of servers that are using SMB ( Samba ) by performing brute force attack. 
> I am not responsible for the out of context usage of this program. Use only for pentesting. I am not going to visit you in jail.

## What is brute force attack?
Brute force attack is a type of attack that tries all of the strings by one by one till she finds a password, username or both.
###### Ex: We know that the user's name is ABC, the brute force attacker tries all of the possible passwords one by one till she gains access. 
> Is it 1? Nope. Is it 2 then? Nope. 3? Still No. 

## How to use smbBruteForce?
Just go and run the script for the IP adress that you want to perform brute force.
```
.\smbBrute.ps1 127.0.0.1
```
> Of course not to your localhost. Well depends actually if you want you are free to.

Parameters:
    
    -IPAddr: [String, Mandatory] , throws Need IP Address Exception
        IP Address of the to be brute forced client

    -lb: [int, DEFAULT = 33]
        Lower bound. The first character to be searched in the Unicode table, as the lower bound. 
        The search does not check character's with lower decimal numbers than lower bound. 
        
    -ub: [int, DEFAULT = 126]
        Upper bound. The last character to be searched in the Unicode table, as the upper bound. 
        The search does not check character's with higher decimal numbers than upper bound.

    -ml: [int, DEFAULT = 1]
        The password and username's length is increased level by level in order not to be in infinite loop 
        with 1 char password and infinite char password. This is the first level to be reached.
        Ex: If 2 is selected, first the 1 char usernames and 0,1,2 char passwords will be matched then 2 char 
        usernames and 0,1,2 char passwords. Then the level will be increased.
        Ex: If 100 is selected, first the 1 char usernames and 0,1,2..,100 char passwords will be matched... 
        Then the 100 char usernames and 0,1,2..,100 char passwords will be matched. 
        Then the level will be increased.
                
    -mli: [int, DEFAULT = 1]
        When the lengths of the password and username is reached, the maximum length is increased with this value.

    -uc: [int[], DEFAULT = (34, 47, 92, 91, 93, 58, 59, 124, 61, 44, 43, 42, 63, 60, 62, 37)]
        List of characters that are forbidden in the username. 
        ( Usernames can not contain   / \ [ ] : ; | = , + * ? < > % )

    -pc: [int[], DEFAULT = 1 .. 31 ]
        List of characters that are forbidden in the password.

Looking for more examples?
```
    .\smbBrute.ps1 127.0.0.1 -lb 10 -ub 200 -ml 5 -mli 2
    .\smbBrute.ps1 127.0.0.1 -uc 1,2,3,6,7,8,9
```

The parameters can also be reached by:
```
Get-help .\smbBrute.ps1 127.0.0.1
```
The program creates a log that can be checked for information of the process. At the end if the program finds a username and password pair it can also be found in the log file, whose name consists of "smbBrute" and the timestamp.

    
## How is smbBruteForce working?
> Pure magic.

If there is no info on the username or the password then all of the < username , password > tuples are send as credentials while doing smbmapping. If an smb connection is achieved, it means that the pair that is send is valid.
For gathering the < username, password > pairs, we are first starting with a one char username, which the char is selected from the Unicode table and all of the passwords are paired and send to the smbconnection client. However since there is no limit on the password length, we need to put a limit for the character size. If not we will check one char usernames with one hundred char password prior than two char username with four char passwords. Therefore there is a limit which exceeds over time. For further info check parameter "-ml".

Also there can be a black list of chars which can not be used while choosing a username or a password, constraints, if these constraints are given as parameters the pairing process skips the <username, password> pairs which includes the forbidden characters. 


## Any future work that can be done?
Multi thread usage maybe? Since the brute force algorithms takes too much time, maybe decrease it a little. 
> Still large domain, large key size usage can lead to couple of thousand years. So at the very worst, just for fun ^^

