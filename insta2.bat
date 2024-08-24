@echo off
setlocal enabledelayedexpansion

REM Cloudflare API credentials (replace these with your actual values)
set auth_email=Email Here
set auth_key=Auth Key Here

REM Array of domains and their corresponding zone IDs
set domains[1]=Domain 1
set zone_ids[1]= KEY

set domains[2]=Domain 2
set zone_ids[2]=Key

set domains[3]=Domain 3
set zone_ids[3]= Key

set domains[4]=Domain 4
set zone_ids[4]=Key

REM Constant for the number of domains
set num_domains=4

REM Display available domains and prompt the user to choose
echo Select a domain:
for /L %%i in (1,1,%num_domains%) do (
    echo %%i^) !domains[%%i]!
)

set /p domain_choice=Enter the number corresponding to the domain: 

REM Validate domain_choice
if %domain_choice% lss 1 (
    echo Invalid choice. Operation canceled.
    pause
    exit /b
)
if %domain_choice% gtr %num_domains% (
    echo Invalid choice. Operation canceled.
    pause
    exit /b
)

REM Set the chosen domain and corresponding zone ID
set domain=!domains[%domain_choice%]!
set zone_id=!zone_ids[%domain_choice%]!

REM Prompt for user inputs
echo THIS IS FOR %domain% ONLY!!!
set /p cname=Enter the CNAME to add/update (e.g., test.%domain%): 
set /p pointto=Enter the domain to point to (e.g., spiritual-penguin-e8c28a.instawp.xyz): 

REM Construct the full CNAME record
set full_cname=%cname%.%domain%

REM Confirm the full domain name
echo You are about to create/update the CNAME %full_cname% pointing to %pointto%.
set /p confirm=Is this correct? (y/n): 
if /i not "%confirm%"=="y" (
    echo Operation canceled.
    pause
    exit /b
)

REM Get the record ID if it exists by capturing the entire JSON response
curl -s -X GET "https://api.cloudflare.com/client/v4/zones/%zone_id%/dns_records?type=CNAME&name=%full_cname%" ^
-H "X-Auth-Email: %auth_email%" ^
-H "X-Auth-Key: %auth_key%" ^
-H "Content-Type: application/json" > temp.txt

REM Initialize record_id
set record_id=

REM Extract the "id" value from the JSON response
for /f "tokens=3 delims=,: " %%a in ('findstr /i "\"id\"" temp.txt') do (
    set record_id=%%a
    set record_id=!record_id:"=!
    set record_id=!record_id: }=!
    set record_id=!record_id: =!
    goto :id_found
)

:id_found
REM Delete the temporary file
del temp.txt

REM Validate the record_id before attempting to update
if defined record_id (
    echo Updating existing CNAME record with ID %record_id%...
    curl -X PUT "https://api.cloudflare.com/client/v4/zones/%zone_id%/dns_records/%record_id%" ^
    -H "X-Auth-Email: %auth_email%" ^
    -H "X-Auth-Key: %auth_key%" ^
    -H "Content-Type: application/json" ^
    --data "{\"type\":\"CNAME\",\"name\":\"%full_cname%\",\"content\":\"%pointto%\",\"ttl\":3600,\"proxied\":false}"
) else (
    echo No existing record found. Creating new CNAME record...
    curl -X POST "https://api.cloudflare.com/client/v4/zones/%zone_id%/dns_records" ^
    -H "X-Auth-Email: %auth_email%" ^
    -H "X-Auth-Key: %auth_key%" ^
    -H "Content-Type: application/json" ^
    --data "{\"type\":\"CNAME\",\"name\":\"%full_cname%\",\"content\":\"%pointto%\",\"ttl\":3600,\"proxied\":false}"
)

echo.
echo Operation completed.
pause