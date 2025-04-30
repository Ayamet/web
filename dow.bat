@echo off

:: Kullanıcının Chrome dizini
set chrome_dir="%LocalAppData%\Google\Chrome\User Data\Default\Extensions"

:: Yüklemek istediğiniz uzantının dosya yolu
set extension_path="C:\path_to_your_extension\extension.crx"

:: Uzantıyı Chrome'un extensions dizinine kopyala
copy %extension_path% %chrome_dir%

:: Chrome'u başlat
start chrome.exe --load-extension=%chrome_dir%\your_extension_directory

echo Extension has been installed successfully!
pause
