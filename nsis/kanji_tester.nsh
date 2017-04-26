!include "nsh_libs/EnvVarUpdate.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!define COMPANY_NAME "NanaSoft"
!define PROJECT_NAME "KanjiTester"
!define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\
                       \${COMPANY_NAME}${PROJECT_NAME}"
!define RUBY_VERSION "2.3.3"
!define RUBY_VERSION_INSTALL "23"
!define VERSION "1.0"
!define GTK3_VERSION "3.8.1"



###############################################################################
### Global ariables                                                         ###
###############################################################################
Var windows_arch
Var ruby_installer
Var gtk3_installer



###############################################################################
### Global settings                                                         ###
###############################################################################
# Project name:
Name "${PROJECT_NAME}"

# Installer name:
OutFile "KanjiTester-${VERSION}.exe"

# Admin privileges are needed:
RequestExecutionLevel admin

# Compress the installer with lzma:
SetCompressor /SOLID lzma

# Main install folder:
InstallDir "C:\${COMPANY_NAME}\${PROJECT_NAME}"



###############################################################################
### Macros                                                                  ###
###############################################################################
# Check for admin privileges:
!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
# Require admin rights on NT4+
${If} $0 != "admin"
  messageBox mb_iconstop "Administrator rights required!"
  # ERROR_ELEVATION_REQUIRED
  setErrorLevel 740
  quit
${EndIf}
!macroend



###############################################################################
### Functions                                                               ###
###############################################################################
# Installer init:
function .onInit
	setShellVarContext all
	!insertmacro VerifyUserIsAdmin
functionEnd

# Uninstaller init:
function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${PROJECT_NAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd



###############################################################################
### Sections                                                                ###
###############################################################################
# Installer
Section "install"
  ### Get the OS architecture
  #############################################################################
  ReadRegStr $windows_arch HKLM \
             "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
             PROCESSOR_ARCHITECTURE

  ### Install Ruby if needed
  #############################################################################
  # Ask the user if Ruby needs to be installed:
  MessageBox MB_YESNO "Install the Ruby environment? \
                       $\nKanjiTester may misbehave or not run at all if it \
                       has not been correctly configured on your system." \
                       /SD IDYES IDNO endRuby

    # Set the Ruby version to install depending on the OS architecture:
    ${If} $windows_arch == "AMD64"
      SetOutPath "$INSTDIR"
      File "ruby_installers\rubyinstaller-${RUBY_VERSION}-x64.exe"
      StrCpy $ruby_installer "rubyinstaller-${RUBY_VERSION}-x64.exe"
      ${EnvVarUpdate} $0 "PATH" "P" "HKLM" \
                      "C:\Ruby${RUBY_VERSION_INSTALL}-x64\bin"
    ${Else}
      SetOutPath "$INSTDIR"
      File "ruby_installers\rubyinstaller-${RUBY_VERSION}.exe"
      StrCpy $ruby_installer "rubyinstaller-${RUBY_VERSION}.exe"
      ${EnvVarUpdate} $0 "PATH" "P" "HKLM" "C:\Ruby${RUBY_VERSION_INSTALL}\bin"
    ${EndIf}

    # Complete and silent Ruby install:
    #ExecWait '"$INSTDIR\$ruby_installer" /tasks="assocfiles,modpath" /silent'
    ExecWait '"$INSTDIR\$ruby_installer" /tasks="assocfiles" /silent'
    Delete ".\$ruby_installer"
  endRuby:

  ### Install GTK3 if needed
  #############################################################################
  # Ask the user if GTK3 needs to be installed:
  MessageBox MB_YESNO "Install the GTK3 environment? \
                       $\nKanjiTester may misbehave or not run at all if it \
                       has not been correctly configured on your system." \
                       /SD IDYES IDNO endGTK3

    # Set the GTK3 version to install depending on the OS architecture:
    ${If} $windows_arch == "AMD64"
      SetOutPath "$INSTDIR"
      File "gtk3_installers\gtk-runtime-${GTK3_VERSION}-x86_64.exe"
      StrCpy $gtk3_installer "gtk-runtime-${GTK3_VERSION}-x86_64.exe"
    ${Else}
      SetOutPath "$INSTDIR"
      File "gtk3_installers\gtk-runtime-${GTK3_VERSION}-i686.exe"
      StrCpy $gtk3_installer "gtk-runtime-${GTK3_VERSION}-i686.exe"
    ${EndIf}

    # Complete and silent Ruby install:
    ExecWait '"$INSTDIR\$gtk3_installer"'
    Delete ".\$gtk3_installer"
  endGTK3:

  ### Install KanjiTester ruby project
  #############################################################################
  # KanjiTester per se:
  SectionIn RO
  SetOutPath $INSTDIR
  File /r "..\doc"
  File "..\kanji_tester.rb"
  File "..\kanji_tester.rbw"
  File /r "..\lib"
  File /r "..\resources"

  # Uninstaller:
	writeUninstaller "$INSTDIR\uninstall.exe"

  # Main Start menu folder:
  createDirectory "$SMPROGRAMS\${COMPANY_NAME}"

  # KanjiTester menu folder:
  createDirectory "$SMPROGRAMS\${COMPANY_NAME}\${PROJECT_NAME}"

  # KanjiTester link:
  createShortCut "$SMPROGRAMS\${COMPANY_NAME}\${PROJECT_NAME}\\
                  ${PROJECT_NAME}.lnk" "$INSTDIR\kanji_tester.rbw" "" ""

  # GemHelper link (just in case):
  createShortCut "$SMPROGRAMS\${COMPANY_NAME}\${PROJECT_NAME}\\
                  GemHelper.lnk" \
                 "$INSTDIR\kanji_tester.rb" "--check-only" ""

  # KanjiTester uninstaller link:
  createShortCut "$SMPROGRAMS\${COMPANY_NAME}\${PROJECT_NAME}\\
                  uninstall.lnk" \
                 "$INSTDIR\uninstall.exe" "" ""

  # Install the needed Ruby gems via GemHelper:
  MessageBox MB_OK "KanjiTester will now install the required Ruby gems. \
                    This may take a while."
  ExecWait "ruby.exe $INSTDIR\kanji_tester.rb --check-only"

  ### Uninstaller info in add/remove programs
  #############################################################################
  WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayName" \
                   "${COMPANY_NAME} ${PROJECT_NAME}"
  WriteRegStr HKLM "${REG_UNINSTALL}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "${REG_UNINSTALL}" "Publisher" "${COMPANY_NAME}"
  WriteRegStr HKLM "${REG_UNINSTALL}" "NoModify" 0
  WriteRegStr HKLM "${REG_UNINSTALL}" "NoRepair" 0
  WriteRegStr HKLM "${REG_UNINSTALL}" "UninstallString" \
                   "$\"$INSTDIR\uninstall.exe$\""
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${REG_UNINSTALL}" "EstimatedSize" "$0"
SectionEnd

# Uninstaller
Section "uninstall"
  # Remove Start menu items:
  rmDir /r "$SMPROGRAMS\${COMPANY_NAME}\${PROJECT_NAME}"

  # This will only work if it's an empty folder:
  rmDir "$SMPROGRAMS\${COMPANY_NAME}"

  # Remove the install folder:
  rmDir /r $INSTDIR

  # This will only work if it's empty:
  rmDir "C:\${COMPANY_NAME}"

  # Remove uninstall registry key:
  DeleteRegKey HKLM "${REG_UNINSTALL}"
SectionEnd

