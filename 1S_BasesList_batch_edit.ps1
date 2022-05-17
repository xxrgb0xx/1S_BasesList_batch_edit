Import-Module activedirectory

$IbasesPath = "C:\ibases\ibases.v8i"
$CurrentDate = Get-Date -f dd_MM_yyyy-HH_mm_ss

function GetADUserNames { ### Запрашиваем список активных юзеров AD.
	$ADUsers = Get-ADUser -Filter 'enabled -eq $true' | select -expand SamAccountName
	$ADUserNames = @()
	foreach ($ADUser in $ADUsers) {
		$ADUserNames += $ADUser
	}
	return	$ADUserNames | Sort-Object
}

function Get1SUserNames { ### Формируем массив с юзерами АД, хотя бы раз запускавшими 1С.
	$ADUserNames = GetADUserNames
	$1SUserNames = @()
	foreach ($ADUserName in $ADUserNames) {
		if (Test-Path -Path "C:\Users\$ADUserName\AppData\Roaming\1C\1CEStart\") {			
				$1SUserNames += $ADUserName
		}
	}
	return $1SUserNames
}

function EditInfoBases { ### Удаляет ibases.v8i у всех пользователей 1С + вписывает $IbasesPath в 1CEStart.cfg 
	$1SUserNames = Get1SUserNames
	$CurrentUserCounter = 1
	$TotalUserCounter = $1SUserNames.count
	foreach ($1SUserName in $1SUserNames) {
		$CompletePercent = [int](($CurrentUserCounter / $TotalUserCounter) * 100)		
		Write-Progress -Activity "Работа со списком баз..." -Status "$CompletePercent%" -PercentComplete $CompletePercent
    	Start-Sleep -Milliseconds 175
		$CurrentUserCounter++
		$CurrentWorkDir = "C:\Users\$1SUserName\AppData\Roaming\1C\1CEStart"
		"Имя пользователя:"
		$1SUserName
		"Рабочая директория:"
		$CurrentWorkDir
		$CurrentBasesFile = "$CurrentWorkDir\ibases.v8i"
		$CurrentCfgFile = "$CurrentWorkDir\1CEStart.cfg"
		$CfgFileBackup = $CurrentWorkDir + '\1CEStart.cfg_' + $CurrentDate + '_BAK' 
		if (Test-Path -Path $CurrentBasesFile) {
            Remove-Item $CurrentBasesFile #-Force
        }
		"Очистка персонального списка баз ........... [ OK ]"
		if (Test-Path -Path $CurrentCfgFile) { ### Если существует, то бекапим.
            Get-Content $CurrentCfgFile | Set-Content $CfgFileBackup
			Remove-Item $CurrentCfgFile #-Force
			"CommonInfoBases=$IbasesPath"| Set-Content $CurrentCfgFile
		}
		else {
			"CommonInfoBases=$IbasesPath"| Set-Content $CurrentCfgFile
		}
		"Добавление общего списка баз................ [ OK ]"
		"***************************************************"
	}
}

function RemoveCfgBackups { ### Удаляем у всех юзеров бекапы 1CEStart.cfg
	$1SUserNames = Get1SUserNames
	$CurrentUserCounter = 1
	$TotalUserCounter = $1SUserNames.count
	foreach ($1SUserName in $1SUserNames) {
		$CompletePercent = [int](($CurrentUserCounter / $TotalUserCounter) * 100)		
		Write-Progress -Activity "Работа с бекапами 1CEStart.cfg..." -Status "$CompletePercent%" -PercentComplete $CompletePercent
    	Start-Sleep -Milliseconds 175
		$CurrentUserCounter++
		$CurrentWorkDir = "C:\Users\$1SUserName\AppData\Roaming\1C\1CEStart"
		"Имя пользователя:"
		$1SUserName
		"Рабочая директория:"
		$CurrentWorkDir
        $CfgFileBackupMask = $CurrentWorkDir + '\1CEStart.cfg_*BAK'
		if (Test-Path -Path $CfgFileBackupMask) {
            Remove-Item $CfgFileBackupMask #-Force
        }     
        "Удаление бекапов 1CEStart.cfg............... [ OK ]"
		"***************************************************"
	}
}

function Menu {
    Write-Host "`n"
    Write-Host "Общий список баз: $IbasesPath`n" -BackgroundColor DarkGray
    Write-Host "Выберите нужное действие:`n"
    Write-Host "1 - Удалить у всех юзеров 1С список баз + прописать им общий." -ForegroundColor Gray
    Write-Host "2 - Удалить у всех юзеров 1С бекапы 1CEStart.cfg." -ForegroundColor Yellow
    Write-Host "3 - Выход`n" -ForegroundColor Green
    $Choise = Read-Host "Ввод"
    if ( ($Choise -eq 1) -or ($Choise -eq 2) -or ($Choise -eq 3) ) {
        switch ($Choise)
        {
            1 { EditInfoBases }
            2 { RemoveCfgBackups }
            3 { exit }
        }
    }
    else {
        Write-Host "Введите правильное значение!" -ForegroundColor Red
        Menu
    }
}
 
Menu
pause