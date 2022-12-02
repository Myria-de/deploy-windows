@echo off
rem $Id: win_postinstall.cmd 153224 2022-08-22 17:43:14Z klaus $
rem rem @file
rem Post installation script template for Windows.
rem
rem This runs after the target system has been booted, typically as
rem part of the first logon.
rem

rem
rem Copyright (C) 2017-2022 Oracle and/or its affiliates.
rem
rem This file is part of VirtualBox base platform packages, as
rem available from https://www.virtualbox.org.
rem
rem This program is free software; you can redistribute it and/or
rem modify it under the terms of the GNU General Public License
rem as published by the Free Software Foundation, in version 3 of the
rem License.
rem
rem This program is distributed in the hope that it will be useful, but
rem WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
rem General Public License for more details.
rem
rem You should have received a copy of the GNU General Public License
rem along with this program; if not, see <https://www.gnu.org/licenses>.
rem
rem SPDX-License-Identifier: GPL-3.0-only
rem

rem Globals.
set MY_LOG_FILE=C:\vboxpostinstall.log

rem Log header.
echo *** started >> %MY_LOG_FILE%
echo *** CD=%CD% >> %MY_LOG_FILE%
echo *** Environment BEGIN >> %MY_LOG_FILE%
set >> %MY_LOG_FILE%
echo *** Environment END >> %MY_LOG_FILE%




rem
rem Install the guest additions.
rem

rem First find the CDROM with the GAs on them.
set MY_VBOX_ADDITIONS=E:\vboxadditions
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=D:\vboxadditions
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=F:\vboxadditions
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=G:\vboxadditions
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=E:
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=F:
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=G:
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=D:
if exist %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe goto found_vbox_additions
set MY_VBOX_ADDITIONS=E:\vboxadditions
:found_vbox_additions
echo *** MY_VBOX_ADDITIONS=%MY_VBOX_ADDITIONS%\ >> %MY_LOG_FILE%

rem Then add signing certificate to trusted publishers
echo *** Running: %MY_VBOX_ADDITIONS%\cert\VBoxCertUtil.exe ... >> %MY_LOG_FILE%
%MY_VBOX_ADDITIONS%\cert\VBoxCertUtil.exe add-trusted-publisher %MY_VBOX_ADDITIONS%\cert\vbox*.cer --root %MY_VBOX_ADDITIONS%\cert\vbox*.cer >> %MY_LOG_FILE% 2>&1
echo *** ERRORLEVEL: %ERRORLEVEL% >> %MY_LOG_FILE%

rem Then do the installation.
echo *** Running: %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe /S >> %MY_LOG_FILE%
%MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe /S
echo *** ERRORLEVEL: %ERRORLEVEL% >> %MY_LOG_FILE%









echo *** done >> %MY_LOG_FILE%

